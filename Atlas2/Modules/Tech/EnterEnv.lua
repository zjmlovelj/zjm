-- ! @file
-------------------------------------------------------------------
----***************************************************************
----EnterEnv functions
----Created at: 09/29/2022
----Author: Bin Zhao (zhao_bin@apple.com)
----***************************************************************
-------------------------------------------------------------------
local EnterEnv = {}
local log = require("Tech/logging")
local record = require("Tech/record")
local commonFunc = require("Tech/CommonFunc")
local dutCommChannelMux
local helper = require("Tech/SMTLoggingHelper")
local variableTable
local timeUtility
local utilities
local fixture
local channel
local shouldRunPreEnterEnv = true
local shouldRunPostEnterEnv = true
local shouldRunAfterResetEnterEnv = true
local shouldRunPowerCycleEnterEnv = true

-------------------------------------------------------------------
----***************************************************************
---- Constants
----***************************************************************
-------------------------------------------------------------------
local NO_RETRY_ERROR = "No Retry Error"
local ENV_UNKNOWN = "unknown"
local AUTO_BOOT_PROMPT = "Hit enter to break into the command prompt"
local ENV_TABLE = {"diags", "rtos", "rbm", "phleet", "ios", "iboot", "ibootPrompt", "fixture", ENV_UNKNOWN}
local ENV_PROMPT_TABLE = {
    ["diags"] = "] :-) ",
    ["rtos"] = "SEGPE>",
    ["rbm"] = " <- Empty ok",
    ["phleet"] = "CPU0_: ( Empty ) ok",
    ["ios"] = "Darwin/BSD (localhost) (console)",
    ["iboot"] = "[m]",
    ["ibootPrompt"] = "] ",
    ["fixture"] = "fixture_done",
    [ENV_UNKNOWN] = ""
}
local ENV_PROMPT_REGEX_TABLE = {
    ["diags"] = "%] :%-%)",
    ["rtos"] = "SEGPE>",
    ["rbm"] = "%->[%w%s]<%- Empty ok",
    ["phleet"] = "CPU[%d]+_?: %( Empty %) ok",
    ["fsboot"] = "Darwin/BSD %(localhost%) %(console%)",
    ["iboot"] = "%[m%]",
    ["ibootPrompt"] = "\n%] $",
    ["fixture"] = "fixture_done",
    [ENV_UNKNOWN] = ""
}
local ENV_ENTER_COMMAND_TABLE = {
    ["diags"] = "diags",
    ["rtos"] = "rtos",
    ["rbm"] = "rbm",
    ["phleet"] = "phleet",
    ["ios"] = "fsboot"
}
local ENV_RESET_COMMAND_TABLE = {
    ["diags"] = "reset",
    ["rtos"] = "pmgr reset",
    ["rbm"] = "reset",
    ["phleet"] = "reset",
    ["iboot"] = "reset",
    ["ios"] = "reboot",
    [ENV_UNKNOWN] = nil
}

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0051:, Version: v0.1, Type:Inner]
Name: loadPluginsAndModules
Function description: [v0.1] brief Load plugin and module dependencies for this module
Input :
Output : N/A
-----------------------------------------------------------------------------------]]
local function loadPluginsAndModules()
    local status, ret
    status, ret = xpcall(require, debug.traceback, 'Tech/DutCommMux')
    if status then
        dutCommChannelMux = ret
    end

    status, ret = xpcall(require, debug.traceback, 'Tech/SMTLoggingHelper')
    if status then
        helper = ret
    end

    status, ret = xpcall(require, debug.traceback, 'Fixture')
    if status then
        fixture = ret
    else
        status, ret = xpcall(require, debug.traceback, 'Tech/Fixture')
        if status then
            fixture = ret
        else
            -- For station requiring no fixture operations
            fixture = {}
        end
    end

    status, ret = xpcall(Device.getPlugin, debug.traceback, 'VariableTable')
    if status then
        variableTable = ret
    end

    status, ret = xpcall(Device.getPlugin, debug.traceback, 'Utilities')
    if status then
        utilities = ret
    else
        utilities = Atlas.loadPlugin('Utilities')
    end

    status, ret = xpcall(Device.getPlugin, debug.traceback, 'TimeUtility')
    if status then
        timeUtility = ret
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0052:, Version: v0.1, Type:Inner]
Name: checkExpect
Function description: [v0.1]Check if expected pattern is in source string. 
                             Support Lua regex, "&&", "||" and "!"
Input :expect(string) source(string)
Output : N/A
-----------------------------------------------------------------------------------]]
local function checkExpect(expect, source)
    local conditions = commonFunc.splitBySeveralDelimiter(expect, "&|")
    local relations = commonFunc.gainDelimiterSequence(expect, "&|")
    local conditionResult = nil

    for i, str in ipairs(conditions) do
        local condition = commonFunc.trim(str)
        local conditionVal = commonFunc.splitBySeveralDelimiter(condition, "!=")[1]
        local operator = commonFunc.gainDelimiterSequence(condition, "!=")[1]
        local relationToLeft = relations[i - 1]

        local currentResult = string.match(source or "", conditionVal) ~= nil

        if operator == '!' then
            currentResult = not currentResult
        elseif operator ~= nil and operator ~= "" then
            error(string.format('Invalid operator : %s', operator))
        end

        log.LogInfo(string.format("'%s(%s, %s)' matched: %s", condition, operator, conditionVal, currentResult))

        if relationToLeft == nil then
            conditionResult = currentResult
        elseif relationToLeft == '&&' then
            conditionResult = conditionResult and currentResult
        elseif relationToLeft == '||' then
            conditionResult = conditionResult or currentResult
        else
            error(string.format('Invalid relationship between expect condition: %s', relationToLeft))
        end
    end

    if conditionResult ~= true then
        error(string.format("Expect '%s' not matched in '%s'", expect, source))
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0053:, Version: v0.1, Type:Inner]
Name: EnterEnv.detectEnv
Function description: [v0.1] Detect current environment of DUT by keep reading 
                             if data available or send '\n' if no data.
Input :dut(ATKLuaPlugin), plugin for communication
       targetEnv(string), expected environment, breaks out when it's detected
       timeout(number),  time to stop detection when env is unknown
Output : env(string), detected env, could be "unknown"
-----------------------------------------------------------------------------------]]
function EnterEnv.detectEnv(dut, targetEnv, timeout)
    local getResponse = function(cmd)
        -- Use dut.send() will remove the command "\n" in response string,
        -- which causes ibootPrompt detect fail
        if cmd then
            dut.write(cmd)
        end
        local resp = dut.read(0.5)
        log.LogDebug("detectEnv cmd: '" .. tostring(cmd) .. "', resp: '" .. resp .. "'")
        return resp
    end

    local bufferedLength = 128
    local envDetected = ENV_UNKNOWN
    local startTime = os.time()
    local command
    local respBuffer = ""
    local enterSent = false

    -- Do not append any suffix to command
    dut.setLineTerminator("")
    dut.setDelimiter("")

    repeat
        local status, resp = xpcall(getResponse, debug.traceback, command)
        if status then
            -- Keep reading and no writing if data read successfully
            command = nil

            -- Append resp to last 128 chars of buffer
            respBuffer = string.sub(respBuffer, -bufferedLength) .. resp

            -- only need to send one time for breaking autoboot
            if string.find(respBuffer, AUTO_BOOT_PROMPT) and not enterSent then
                dut.write("\n")
                log.LogInfo("Detected iboot autoboot prompt, hit to break autoboot")
                enterSent = true
            else
                for _, e in ipairs(ENV_TABLE) do
                    local promptRegex = ENV_PROMPT_REGEX_TABLE[e]
                    if promptRegex ~= nil and string.find(respBuffer, promptRegex) ~= nil then
                        envDetected = e
                        break
                    end
                end
            end
        else
            -- No response indicates DUT is in booted environment, sending "\n"
            command = "\n"
        end
        -- rdar://89008694 ([EnterEnv] EnterEnv keep typing multiple "\n" after booting to iBoot.)
        if targetEnv ~= nil and string.find(targetEnv, "^iboot") ~= nil and envDetected ~= nil and
            string.find(envDetected, "^iboot") ~= nil then
            envDetected = targetEnv
        end
    until (targetEnv ~= nil and envDetected == targetEnv or targetEnv == nil and envDetected ~= ENV_UNKNOWN or
        os.difftime(os.time(), startTime) >= timeout)

    -- Restore default suffix to command
    dut.setLineTerminator("\n")

    return envDetected
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0054:, Version: v0.1, Type:Inner]
Name: enterEnvSingleRun
Function description: [v0.1] Put DUT into desired environment
Input :dut(ATKLuaPlugin), plugin for communication
       targetEnv(string), expected environment, breaks out when it's detected
       timeout(number),  time to stop detection when env is unknown
       expect(string), the expected pattern in boot output
Output : N/A
-----------------------------------------------------------------------------------]]
local function enterEnvSingleRun(dut, dataChannel, targetEnv, timeout, hangTimeout, expect, paraTab)
    -- Set channel hangTimeout. Need to use SMTDataChannel 0.0.6+ to enable hang only when hangTimeout < timeout.
    if dataChannel and tonumber(hangTimeout) ~= nil then
        dataChannel.setHangTimeout(tonumber(hangTimeout))
    end

    local envDetected = ENV_UNKNOWN
    local prompt = ENV_PROMPT_TABLE[targetEnv]
    local status, env = xpcall(EnterEnv.detectEnv, debug.traceback, dut, nil, timeout)
    if status then
        envDetected = env
    end

    if targetEnv ~= "diags" or (targetEnv == "diags" and envDetected ~= targetEnv) then

        -- reset DUT if detected env is not iboot
        if string.find(envDetected, "^iboot") == nil then
            local resetCMD = ENV_RESET_COMMAND_TABLE[envDetected]
            if resetCMD == nil then
                error("reset command is nil")
            end

            -- TODO add NonUI Commonunication step to reboot device
            if envDetected == "ios" then
                error("Reset NonUI device is not supported")
            end

            -- rdar://86566112 (EnterEnv: correct delimiter for reset command)
            dut.setDelimiter(ENV_PROMPT_TABLE[ENV_UNKNOWN])
            log.LogDebug("Sending reset command: " .. tostring(resetCMD))
            dut.write(resetCMD)

            -- rdar://86993622 (EnterEnv: Add AfterResetEnterEnv sequence support for FATP-SOC)
            if shouldRunAfterResetEnterEnv == true and type(fixture.AfterResetEnterEnv) == "function" then
                log.LogInfo("Running Fixture.AfterResetEnterEnv")
                fixture.AfterResetEnterEnv(paraTab)
            end

            local statusAfterReset, envAfterReset = xpcall(EnterEnv.detectEnv, debug.traceback, dut, "ibootPrompt",
                                                           timeout)
            if statusAfterReset then
                envDetected = envAfterReset
            end

            -- not in iboot after reset
            if string.find(envDetected, "^iboot") == nil then
                error("Failed to reset DUT to iboot, but " .. envDetected .. " detected.")
            end
        end

        -- Send cmd to enter target env which is not iboot
        if string.find(targetEnv, "^iboot") == nil then
            local cmd = ENV_ENTER_COMMAND_TABLE[targetEnv]
            log.LogInfo("Start to send command: " .. cmd)
            dut.setDelimiter(ENV_PROMPT_TABLE[ENV_UNKNOWN])

            -- Add sleep to fix command no response. rdar://81728566
            if timeUtility then
                timeUtility.delay(0.5) -- rdar://81728566
            else
                os.execute("sleep 0.5")
            end

            local cmdData = utilities.dataFromHexString(EnterEnv.str2hex(cmd))
            -- rdar://86566112 (EnterEnv: Separate write and read of boot command)
            dut.writeData(cmdData)

            if string.find(targetEnv, "ios") == nil then
                dut.setDelimiter(prompt)
                log.LogInfo("Set prompt to " .. prompt)
                local bootData = dut.readData(timeout)

                if expect ~= nil then
                    local sourceHex = utilities.dataToHexString(bootData)
                    local source = EnterEnv.hex2str(sourceHex)
                    local checkStatus, checkRet = xpcall(checkExpect, debug.traceback, expect, source)
                    if not checkStatus then
                        error(NO_RETRY_ERROR .. ": " .. tostring(checkRet))
                    end
                else
                    log.LogInfo("No expect is set.")
                end
            end
        end
    else
        log.LogInfo("DUT is already in " .. targetEnv .. "! Auto-passing enterENV...")
    end

    if string.find(targetEnv, "ios") == nil then
        dut.setDelimiter(prompt)
        log.LogInfo("EnterEnv OK. Set prompt to '" .. prompt .. "'")
    else
        -- Waiting for NonUI
        xpcall(dut.close, debug.traceback)
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0025:, Version: v0.1, Type:Common]
Name: EnterEnv.enterEnv(paraTab)
Function description: [v0.1] Function to enter test mode for dut and powercycle when enter fail.
Input : Table(paraTab)
Output : true/false (bool)
-----------------------------------------------------------------------------------]]
function EnterEnv.enterEnv(paraTab)
    helper.flowLogStart(paraTab)
    local enterEnvOK = false
    local envDetected = ENV_UNKNOWN
    local currentEnv = nil
    local errMsg = nil
    local dut = nil
    local timeout = tonumber(paraTab.Timeout)
    local hangTimeout = paraTab['hangTimeout']
    local targetEnv =
        (paraTab.Commands ~= nil and paraTab.Commands ~= '' and {paraTab.Commands} or {paraTab.getInput()})[1]
    local prompt = nil
    local expect = paraTab.expect
    local dutPluginName = paraTab.dutPlugin
    local channelPluginName = paraTab.channelPlugin

    local parameterCheck = function()
        if targetEnv == nil then
            errMsg = "Invalid parameter! Target Env not defined in Commands or Input"
            helper.reportFailure(errMsg)
        end

        if commonFunc.hasVal(ENV_TABLE, targetEnv) == nil then
            errMsg = "Invalid parameter! Env '" .. targetEnv .. "' is not supported"
            helper.reportFailure(errMsg)
        end

        if timeout == nil then
            errMsg = "Invalid parameter! Timeout not defined or invalid"
            helper.reportFailure(errMsg)
        end

        prompt = ENV_PROMPT_TABLE[targetEnv]
        if prompt == nil then
            errMsg = "Invalid parameter! Prompt not available for '" .. targetEnv .. "'"
            helper.reportFailure(errMsg)
        end
    end

    loadPluginsAndModules()

    local status = xpcall(parameterCheck, debug.traceback)
    if not status then
        helper.flowLogFinish(false, paraTab, "Result", errMsg)
        helper.reportFailure(errMsg)
    end

    if paraTab.RunPreEnterEnv == false then
        shouldRunPreEnterEnv = false
    end

    if paraTab.RunPostEnterEnv == false then
        shouldRunPostEnterEnv = false
    end

    if paraTab.shouldRunPowerCycleEnterEnv == false then
        shouldRunPowerCycleEnterEnv = false
    end

    if paraTab.shouldRunAfterResetEnterEnv == false then
        shouldRunAfterResetEnterEnv = false
    end

    local currentEnvVar = "currentEnv"
    local currentDelimiterVar = "currentDelimiter"

    -- Get DUT Plugin
    if dutPluginName ~= nil then
        dut = Device.getPlugin(dutPluginName)
        currentEnvVar = dutPluginName .. "#" .. currentEnvVar
        currentDelimiterVar = dutPluginName .. "#" .. currentDelimiterVar
    elseif dutCommChannelMux ~= nil then
        dut = dutCommChannelMux.getCurrentDataChannel()
    else
        -- Lazy retrieving of DUT plugin instance
        for _, name in ipairs {"dut", "Dut", "DUT"} do
            local dutStatus, dutRet = xpcall(Device.getPlugin, debug.traceback, name)
            if dutStatus then
                dut = dutRet
                break
            end
        end
    end

    -- Get Data Channel Plugin
    -- channelPluginName = 'channelPlugin'
    if channelPluginName == nil then
        helper.reportFailure()  
    end
    local channelStatus, channelRet = xpcall(Device.getPlugin, debug.traceback, channelPluginName)
    if channelStatus then
        channel = channelRet
    end

    if variableTable ~= nil then
        currentEnv = variableTable.getVar(currentEnvVar)
    end

    -- Try to open dut UART if not
    if dut.isOpened() ~= 1 then
        dut.setDelimiter("")
        xpcall(dut.open, debug.traceback, 2)
    end
    if shouldRunPreEnterEnv then
        if currentEnv then
            envDetected = currentEnv
        end

        log.LogInfo("Current env = " .. envDetected)

        -- Run PreEnterEnv.
        if targetEnv ~= "diags" or (targetEnv == "diags" and
            (envDetected ~= targetEnv and string.find(envDetected, "^iboot") == nil)) then
            if fixture ~= nil and type(fixture.PreEnterEnv) == "function" then
                log.LogInfo("Running Fixture.PreEnterEnv")
                fixture.PreEnterEnv(paraTab, envDetected)
            end
        end
    end

    -- Try to Enter Env
    enterEnvOK, errMsg = xpcall(enterEnvSingleRun, debug.traceback, dut, channel, targetEnv, timeout, hangTimeout,
                                expect, paraTab)
    if enterEnvOK == false and shouldRunPowerCycleEnterEnv then
        local shouldRetry = (string.find(errMsg or "", "^" .. NO_RETRY_ERROR) == nil)

        -- Run PowerCycleEnterEnv.
        if shouldRetry and fixture ~= nil and type(fixture.PowerCycleEnterEnv) == "function" then
            log.LogInfo("Running Fixture.PowerCycleEnterEnv")
            fixture.PowerCycleEnterEnv(paraTab)
            enterEnvOK, errMsg = xpcall(enterEnvSingleRun, debug.traceback, dut, channel, targetEnv, timeout,
                                        hangTimeout, expect, paraTab)
        end
    end

    -- Run PostEnterEnv
    if shouldRunPostEnterEnv then
        if fixture ~= nil and type(fixture.PostEnterEnv) == "function" then
            log.LogInfo("Running Fixture.PostEnterEnv")
            fixture.PostEnterEnv(paraTab)
        end
    end

    -- Save delimiter and env.
    if enterEnvOK and variableTable ~= nil then
        variableTable.setVar(currentDelimiterVar, prompt)
        local currentDelimiter = variableTable.getVar(currentDelimiterVar)
        log.LogInfo("currentDelimiter changed to: '" .. tostring(currentDelimiter) .. "'")

        variableTable.setVar(currentEnvVar, targetEnv)
        currentEnv = variableTable.getVar(currentEnvVar)
        log.LogInfo("CurrentEnv changed to: '" .. tostring(currentEnv) .. "'")
    end

    -- rdar://86517469 Suppress errMsg for record
    if not enterEnvOK and errMsg ~= nil then
        log.LogInfo("EnterEnv failed: " .. tostring(errMsg))
        errMsg = EnterEnv.suppressErrorMsg(errMsg)
    end

    -- Create record.
    helper.flowLogFinish(enterEnvOK, paraTab, nil, errMsg)

    -- Report error if failed to enter env
    if not enterEnvOK then
        helper.reportFailure(errMsg)
    end

    return enterEnvOK
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0055:, Version: v0.1, Type:Inner]
Name: EnterEnv.suppressErrorMsg
Function description: [v0.1] Suppress error message by returning NSLocalizedDescription, 
                             message before stack traceback or original one
Input :msg(string), orignal failure message.
Output : result(string) suppressed message
-----------------------------------------------------------------------------------]]
function EnterEnv.suppressErrorMsg(msg)
    if type(msg) ~= "string" then
        return msg
    end

    local pluginMsg = string.match(msg, 'NSLocalizedDescription%s?=%s?"(.*)"')
    if pluginMsg ~= nil then
        return pluginMsg
    else
        local luaMsg = string.match(commonFunc.splitString(msg, '\nstack traceback')[1], ':[0-9]+:%s?(.*)')
        if luaMsg ~= nil then
            return luaMsg
        end
    end
    return msg
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0056:, Version: v0.1, Type:Inner]
Name: EnterEnv.hex2str
Function description: [v0.1] Convert hex to string
Input : hex(string) hex represention of source string
Output : str(string) source string
-----------------------------------------------------------------------------------]]
function EnterEnv.hex2str(hex)
    local str, _ = hex:gsub("(%x%x)[ ]?", function(word)
        return string.char(tonumber(word, 16))
    end)
    return str
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0057:, Version: v0.1, Type:Inner]
Name: EnterEnv.str2hex
Function description: [v0.1] Convert string to hex
Input : source (string)
Output : str(string) hex(string) hex represention of source string
-----------------------------------------------------------------------------------]]
function EnterEnv.str2hex(str)
    local fullHex = ""
    for i = 1, string.len(str) do
        local charCode = tonumber(string.byte(str, i, i));
        local hexStr = string.format("%02X", charCode);
        if i == 1 then
            fullHex = hexStr
        else
            fullHex = fullHex .. hexStr
        end
    end
    return fullHex
end


return EnterEnv
