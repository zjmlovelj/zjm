local Process = {}
local comFunc = require("Tech/CommonFunc")
local Log = require("Tech/logging")
local helper = require("Tech/SMTLoggingHelper")
local utils = require("Tech/utils")
local COF = require("Tech/COF")
local dutCmd = require("Tech/DUTCmd")
local stationPath = "/Users/gdlocal/Library/Atlas2/Config/station.plist"

local fileUtils = require("ALE/FileUtils")
local defaultFailResult = "FAIL"
local Ace3LogPath
local groupID, slotNumber = string.match(Device.identifier, "G%=([0-9]+):S%=slot([0-9]+)")
slotNumber = tonumber(slotNumber)

local myOverrideTable = {}
local Utilities

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0083:, Version: v0.1, Type:Inner]
Name: myOverrideTableDUT.getSN
Function description: [v0.1]  Function to get the serialNumber of MLB
Input : N/A
Output : mlbSerialNumber(string)
-----------------------------------------------------------------------------------]]

myOverrideTable.getSN = function()
    local VariableTable = Device.getPlugin("VariableTable")
    local dut = Device.getPlugin(VariableTable.getVar("dutPluginName"))
    local mlbSerialNumber = dut.mlbSerialNumber(3)
    Log.LogInfo("mlbSerialNumber>>>" .. comFunc.dump(mlbSerialNumber))
    return mlbSerialNumber
end

--[[---------------------------------------------------------------------------------
-- myOverrideTableDUT.getNonce = function()
-- Function to read the nonce of MLB
-- Created By :
-- Initial Creation Date : 20/09/2022
-- Modified By : Bryan
-- Modification Date : 31/01/2024
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Primary Usage : DFU/SoC
-- Input Arguments :
-- Output Arguments : NSData
-----------------------------------------------------------------------------------]]
myOverrideTable.getNonce = function()
    local VariableTable = Device.getPlugin("VariableTable")
    local parameters = {}
    parameters.Timeout = 3
    parameters.Commands = "getnonce --hex"
    parameters.AdditionalParameters = {}
    parameters.TestName = "myGetNOnce"
    parameters.Technology = "myCBAction"
    parameters.dutPluginName = VariableTable.getVar("dutPluginName")
    parameters.subsubtestname = ""
    parameters.expect = ":-)"
    local status, ret = xpcall(Device.getPlugin, debug.traceback, 'Utilities')
    if status then
        Utilities = ret
    else
        Utilities = Atlas.loadPlugin('Utilities')
    end
    local bRet, ret = xpcall(dutCmd.sendCmd, debug.traceback, parameters)
    Log.LogInfo("get cb nonce result:" .. ret)
    if not bRet or not ret then
        error('Error: get cb nonce Fail! ' .. "Return value is:" .. tostring(ret))
    end
    local cbNonceVal = string.match(ret, "Nonce: (.*)\r\n")
    if cbNonceVal == nil then
        error('Error: get cb Nonce Value Fail! ' .. "Return value is:" .. tostring(cbNonceVal))
    end
    Log.LogInfo("get cb nonce result:" .. cbNonceVal)
    return Utilities.dataFromHexString(cbNonceVal)
end

--[[---------------------------------------------------------------------------------
-- myOverrideTableDUT.readCBStatus = function(offset)
-- Function to get the control bit status
-- Created By : Wilson/SkyWang
-- Initial Creation Date : 20/09/2022
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Primary Usage : DFU/SoC
-- Input Arguments : offset number
-- Output Arguments : number
-----------------------------------------------------------------------------------]]
myOverrideTable.readCBStatus = function(offset)
    local VariableTable = Device.getPlugin("VariableTable")
    local parameters = {}
    parameters.Timeout = 3
    parameters.Commands = "cbread " .. string.format("0x%02x", offset)
    parameters.AdditionalParameters = {}
    parameters.TestName = "myReadCBStatus"
    parameters.Technology = "myCBAction"
    parameters.dutPluginName = VariableTable.getVar("dutPluginName")
    parameters.subsubtestname = ""
    parameters.expect = ":-)"

    local bRet, ret = xpcall(dutCmd.sendCmd, debug.traceback, parameters)
    if not bRet or not ret then
        error('Error: read cb status Fail! ' .. "Return value is:" .. tostring(ret))
    end

    local status = {Passed = 0, Incomplete = 1, Failed = 2, Untested = 3}
    local CBStatus = string.match(ret, "0x%S+%s+0x%S+%s+(%w+)%s+%S+.*")
    if CBStatus == nil then
        error('Error: parser cb result status Fail! ' .. "Return value is:" .. tostring(CBStatus))
    end
    Log.LogInfo("get cb reslut status:" .. CBStatus)

    return tonumber(status[tostring(CBStatus)])
end

--[[---------------------------------------------------------------------------------
-- myOverrideTableDUT.readCBFailCount = function(offset)
-- Function to read the relative fail count for the control bit offset
-- Created By : Wilson/SkyWang
-- Initial Creation Date : 20/09/2022
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Primary Usage : DFU/SoC
-- Input Arguments : number  : offset
-- Output Arguments : number :relative fail count for the control bit offset
-----------------------------------------------------------------------------------]]
myOverrideTable.readCBFailCount = function(offset)
    local VariableTable = Device.getPlugin("VariableTable")
    local parameters = {}
    parameters.Timeout = 3
    parameters.Commands = "cbread " .. string.format("0x%02x", offset)
    parameters.AdditionalParameters = {}
    parameters.TestName = "myReadCBFailCount"
    parameters.Technology = "myCBAction"
    parameters.dutPluginName = VariableTable.getVar("dutPluginName")
    parameters.subsubtestname = ""
    parameters.expect = ":-)"

    local bRet, ret = xpcall(dutCmd.sendCmd, debug.traceback, parameters)
    if not bRet or not ret then
        error('Error: Read cb status fail! ' .. "Return value is:" .. tostring(ret))
    end
    local failCount = string.match(ret, "0x%S+%s+0x%S+%s+%w+%s+(%d+).*")
    if failCount == nil then
        error('Error: Parser cb failcount fail! ' .. "Return value is:" .. tostring(failCount))
    end
    Log.LogInfo("read cb failcount:" .. failCount)
    return tonumber(failCount)
end

--[[---------------------------------------------------------------------------------
-- myOverrideTableDUT.readCBFailCount = function(offset)
-- Function to read the relative fail count for the control bit offset
-- Created By : Wilson/SkyWang
-- Initial Creation Date : 20/09/2022
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Primary Usage : DFU/SoC
-- Input Arguments :ffset   number  -   control bit offset
                    status  number  -   ATKCBStatus same as in readCBStatus
                    response    NSData  -   response to send during cb write. nil can be passed
                    version string  -   software overlay version as string
-- Output Arguments : nothing
-----------------------------------------------------------------------------------]]
myOverrideTable.writeCB = function(offset, status, response, version)
    local VariableTable = Device.getPlugin("VariableTable")
    local parameters = {}
    parameters.Timeout = 3
    parameters.AdditionalParameters = {}
    parameters.TestName = "myWriteCB"
    parameters.Technology = "myCBAction"
    parameters.dutPluginName =VariableTable.getVar("dutPluginName")
    parameters.subsubtestname = ""
    parameters.expect = ":-)"

    local CBStatus = {"pass", "incomplete", "fail", "untested"}
    if status == 0 then
        if tostring(response) == nil then
            error('Error: response fail! ' .. "Return value is:" .. tostring(response))
        end
        local passKeyBeginIndex = 25
        local passKeyEndIndex = 64
        local passKey = string.sub(tostring(response), passKeyBeginIndex, passKeyEndIndex)
        if passKey == nil then
            error('Error: parser password key value fail! ' .. "Return value is:" .. tostring(passKey))
        end
        Log.LogInfo("get cb keyVal result:" .. tostring(passKey))
        local dut = Device.getPlugin(parameters.dutPluginName)
        parameters.delimiter = "Response"
        parameters.Commands = "cbwrite " .. string.format("0x%02x", offset) .. " " .. CBStatus[status + 1] .. " " ..
                                  version .. " --hex"
        local bRet, ret = xpcall(dutCmd.sendCmd, debug.traceback, parameters)
        if not bRet or not ret then
            error('Error: Write cb status fail! ' .. "Return value is:" .. tostring(ret))
        end
        parameters.Commands = passKey
        parameters.delimiter = ":-)"
        dut.setLineTerminator("")
        bRet, ret = xpcall(dutCmd.sendCmd, debug.traceback, parameters)
        if not bRet or not ret then
            error('Error: Write passKey fail! ' .. "Return value is:" .. tostring(ret))
        end
        dut.setLineTerminator("\n")

    else
        parameters.Commands = "cbwrite " .. string.format("0x%02x", offset) .. " " .. CBStatus[status + 1] .. " " ..
                                  version .. " --hex"
        local bRet, ret = xpcall(dutCmd.sendCmd, debug.traceback, parameters)
        if not bRet or not ret then
            error('Error: Write cb status fail! ' .. "Return value is:" .. tostring(ret))
        end
    end

    return
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0035, Version: v0.1, Type:DFU]
Name: Process.startCB(paraTab)
Function description: [v0.1]Function to start process control ,read SN, write and read the "imcomplete" to cb.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function Process.startCB(paraTab)
    helper.flowLogStart(paraTab)
    local dutPluginName = paraTab.dutPluginName
    if dutPluginName == nil then
        helper.reportFailure("dutPluginName miss")
    end
    local dut = Device.getPlugin(dutPluginName)
    if dut == nil then
        helper.reportFailure("DUT plugin " .. tostring(dutPluginName) .. " not found.")
    end

    local VariableTable = Device.getPlugin("VariableTable")
    VariableTable.setVar("dutPluginName", dutPluginName)

    local category = paraTab.category
    Log.LogInfo("$$$$ Starting process control.")
    if category == nil or category == "" then
        category = myOverrideTable
    end

    if paraTab.mark~= nil then
        local timeout = tonumber(paraTab.timeout) or 0.05
        xpcall(dutCmd.dutRead, debug.traceback, { Timeout=timeout,mark =paraTab.mark })
    end
    dut.setDelimiter("] :-)")

    local status, resp = xpcall(ProcessControl.start, debug.traceback, dut, category)
    if not status then
        Log.LogError(tostring(resp))
        local failureMessage = "startCB error"
        helper.flowLogFinish(false, paraTab, resp, failureMsg)
        --helper.reportFailure(failureMessage)
    else
        helper.flowLogFinish(true, paraTab)
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0036, Version: v0.1, Type:DFU]
Name: Process.finishCB(paraTab)
Function description: [v0.1]Function to finish process control, write and check the result cb of current station.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function Process.finishCB(paraTab)
    helper.flowLogStart(paraTab)
    local inProgress = ProcessControl.inProgress()
    -- 1: started; 0: not started or finished.
    if inProgress == 0 then
        Log.LogInfo("$$$$ Process control finished or not started; skip finishCB.")
        return
    end

    local dutPluginName = paraTab.dutPluginName
    if dutPluginName == nil then
        helper.reportFailure("dutPluginName missing in AdditionalParameters")
    end

    local VariableTable = Device.getPlugin("VariableTable")
    VariableTable.setVar("dutPluginName",dutPluginName)

    local dut = Device.getPlugin(dutPluginName)
    dut.setDelimiter("] :-) ")
    Log.LogInfo('$$$$ Finishing process control')

    local status, resp = xpcall(ProcessControl.finish, debug.traceback, dut, myOverrideTable)
    if not status then
        Log.LogError(tostring(resp))
        local failureMessage = "finishCB error"
        helper.flowLogFinish(false, paraTab, resp, failureMsg)
    else
        helper.flowLogFinish(true, paraTab)
    end
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0037:, Version: v0.1, Type:DFU]
Name: Process.writeICTCB(paraTab)
Function description: [v0.1] Function to Query the ICT result from SFC according to the SN, and then write ICT CB.
Input : Table(paraTab)
Output : Bool
-----------------------------------------------------------------------------------]]
function Process.writeICTCB(paraTab)
    helper.flowLogStart(paraTab)
    local sfc = Device.getPlugin("SFC")
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local dut = Device.getPlugin(paraTab.dutPluginName)
    local vendor = fixturePlugin.getVendor()
     local sn = tostring(paraTab.MLB_Num)
    Log.LogInfo("$$$$ vendor:" .. vendor)
    Log.LogInfo("$$$$ sn" .. sn)

    local failureMsg = nil 
    local result = nil
    local resultFlag = true
    local offset = 0x0a

    if sn == nil or sn == "" then
        failureMsg = "no input sn"
        helper.flowLogFinish(false, paraTab, sn, failureMsg)
        helper.reportFailure(failureMsg)
    end

    local sfc_result = sfc.getAttributesByStationType(sn, "ICT", { "result" })
    Log.LogInfo("$$$$ sfc_result")
    Log.LogInfo(comFunc.dump(sfc_result))
    local ict_result = sfc_result["result"]

    if ict_result and #ict_result > 0 then
        if ict_result == "PASS" then
            local status, nonce = xpcall(dut.getNonce, debug.traceback, offset)
            if status and nonce then

                local signStatus, password = xpcall(Security.signChallenge, debug.traceback, tostring(offset), nonce)
                if signStatus and password then
                    result, failureMsg = xpcall(dut.writeCB, debug.traceback, offset, 0, password, vendor)
                else
                    Log.LogError(password)
                    resultFlag = false
                    failureMsg = "get password failed"
                end

            else
                Log.LogError(nonce)
                resultFlag = false
                failureMsg = "get nonce failed"
            end
        else
            local ict_flag = 2
            if string.lower(ict_result) == "incomplete" then
                ict_flag = 1
            elseif string.lower(ict_result) == "untested" then
                ict_flag = 3
            end
            -- 1 incomplete
            -- 2 fail
            -- 3 untested
            result, failureMsg = xpcall(dut.writeCB, debug.traceback, offset, ict_flag, nil, vendor)
        end
    else
        resultFlag = false
        failureMsg = "query result failed"
    end

    if failureMsg and #failureMsg > 0 then
        Log.LogError(failureMsg)
    end

    if result and resultFlag then
        helper.flowLogFinish(true, paraTab)
    else
        helper.flowLogFinish(false, paraTab, nil, failureMsg)
    end

    return result
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0084:, Version: v0.1, Type:Inner]
Name: Process.dataReportSetup_SAF
Function description: [v0.1]  Function to setup the dataReport for SAF
Input : Table(paraTab)
Output : N/A
Mark: (Unused) SAF station
-----------------------------------------------------------------------------------]]

function Process.dataReportSetup_SAF(paraTab)
    -- local interactiveView = Device.getPlugin("InteractiveView")
    -- local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    local subsubtestname = paraTab.subsubtestname
    local sn = tostring(paraTab.Input)
    local failureMsg = ""
    local result = false
    Log.LogInfo("$$$$$ dataReportSetup sn " .. tostring(sn))
    if sn and #sn > 0 then
        Log.LogInfo("Unit serial number: " .. sn)
        local status, resp = xpcall(DataReporting.primaryIdentity, debug.traceback, sn)
        if not status then
            failureMsg = tostring(resp)
            Log.LogError(failureMsg)
        else
            result = true
            Log.LogInfo("Station reporter is ready.")
        end

        if paraTab..limitsVersion then
            local limitsVersion = paraTab..limitsVersion
            Log.LogInfo("Unit Limits Version: " .. limitsVersion)
            DataReporting.limitsVersion(limitsVersion)
            result = true
        end
    else
        failureMsg = "Fail to get SN"
    end

    if not result then
        helper.createRecord(false, paraTab, failureMsg, nil)
    elseif subsubtestname then
        helper.createRecord(true, paraTab)
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0085, Version: v0.1, Type:Inner]
Name: Process.dataReportSetup
Function description: [v0.1] Function to setup the dataReport(~/Library/Atlas2/Modules/Tech)
Input : Table(paraTab)
Output : N/A
Mark: (Unused)
-----------------------------------------------------------------------------------]]

function Process.dataReportSetup(paraTab)
    -- local interactiveView = Device.getPlugin("InteractiveView")
    -- local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    -- Log.LogInfo("[TEST START][<"..paraTab.Technology.."> <"..paraTab.TestName.."> <"..paraTab.subsubtestname..">]")
    helper.flowLogStart(paraTab)
    local subsubtestname = paraTab.subsubtestname
    local sn = tostring(paraTab.SN)
    local failureMsg = ""
    local result = false
    Log.LogInfo("$$$$$ dataReportSetup sn " .. tostring(sn))
    if sn and #sn > 0 then
        helper.LogInfo("Unit serial number: " .. sn)
        local status, resp = xpcall(DataReporting.primaryIdentity, debug.traceback, sn)
        if not status then
            failureMsg = tostring(resp)
            Log.LogError(failureMsg)
        else
            result = true
            Log.LogInfo("Station reporter is ready.")
        end
    else
        failureMsg = "Fail to get SN"
    end

    if not result then
        helper.flowLogFinish(false, paraTab, nil,  failureMsg)
    elseif subsubtestname then
        helper.flowLogFinish(true, paraTab)
    end
    -- Log.LogInfo("[TEST END][<"..paraTab.Technology.."> <"..paraTab.TestName.."> <"..paraTab.subsubtestname..">]")
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0086:, Version: v0.1, Type:Inner]
Name: Process.writeFailCB
Function description: [v0.1]  Function to write Fail CB
Input : Table(paraTab)
Output : N/A
Mark: (Unused)
-----------------------------------------------------------------------------------]]
function Process.writeFailCB(paraTab)
    local offset = paraTab.offset or 0x00
    local count = paraTab.count or 3
    local status, resp
    local dutPluginName = paraTab.dutPluginName or "Kis_dut"
    local dut = Device.getPlugin(dutPluginName)
    dut.setDelimiter("] :-) ")
    local i = 0
    repeat
        i = i + 1
        status, resp = xpcall(dut.writeCB, debug.traceback, tonumber(offset), 2, nil, nil)
    until i == tonumber(count)
    if not status then
        Log.LogInfo(tostring(resp))
        helper.createRecord(false, paraTab, resp, nil, nil, "FAIL")
    else
        helper.createRecord(true, paraTab)
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0086:, Version: v0.1, Type:Inner]
Name: Process.UOPPoison
Function description: [v0.1]  Function to upload 3 times fail records to insight
Input : Table(paraTab)
Output : N/A
Mark: (Unused)
-----------------------------------------------------------------------------------]]

function Process.UOPPoison(paraTab)
    local flag = true
    if flag then
        Log.LogInfo("-------Start UOPPoison--------")
        local mlbNum = paraTab.InputDict["MLB_Num"]
        local stationTable = utils.loadPlist(stationPath)
        local fixtureID = paraTab.InputDict["fixtureID"]
        Log.LogInfo("$$$$$fixtureID: ", fixtureID)
        local slot_num = tonumber(Device.identifier:sub(-1))
        if not mlbNum then
            paraTab.Input = "[FALSE]"
            paraTab["failMsg"] = "MLB_Num is Nil."
            return
        end

        local limitVersion = tostring(paraTab.InputDict["TPVersion"])
        local stationVersion
        for k, v in pairs(stationTable) do
            if k == "StationVersion" then
                stationVersion = tostring(v) .. "-" .. tostring(limitVersion)
            end
        end

        local socProcessPoison = Atlas.loadPlugin("SoCProcessPoison")
        local times = 0

        repeat
            times = times + 1
            local status
            local failMsg
            local testName = "UOP Poison " .. tostring(times)
            local initStatus, initResult = xpcall(
                socProcessPoison.initPuddingWithSWVersion,
                debug.traceback,
                tostring(stationVersion),
                "Atlas2",
                tostring(mlbNum),
                tostring(testName),
                tostring(limitVersion)
            )
            for k, v in pairs(initResult) do
                if k == "status" then
                    status = v
                end
                if k == "failMsg" then
                    failMsg = v
                end
            end

            if not initStatus or not status then
                paraTab["message"] = failMsg
                paraTab["subsubtestname"] = "UOPPoison"
                -- COF.showAlert(paraTab)
            else
                Log.LogInfo("$$$$$socProcessPoison.initPuddingWithSWVersion PASS")
            end

            socProcessPoison.setupFixtureID(tostring(fixtureID), tostring(slot_num))

            local commitStatus, commitResult = xpcall(socProcessPoison.puddingCommit, debug.traceback, tostring(mlbNum))
            for k, v in pairs(commitResult) do
                if k == "status" then
                    status = v
                end
                if k == "failMsg" then
                    failMsg = v
                end
            end

            if not commitStatus or not status then
                paraTab["message"] = failMsg
                paraTab["subsubtestname"] = "UOPPoison"
                -- COF.showAlert(paraTab)
            else
                Log.LogInfo("$$$$$socProcessPoison.puddingCommit  PASS")
            end
            os.execute("sleep 1")
        until times == 3
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0087:, Version: v0.1, Type:Inner]
Name: Process.SoCUOPPoison
Function description: [v0.1]  Function to upload 3 times fail records to insight
Input : Table(paraTab)
Output : N/A
Mark: (Unused) SOC station
-----------------------------------------------------------------------------------]]

function Process.SoCUOPPoison(paraTab)
    local variableTable = Device.getPlugin("VariableTable")
    if variableTable.getVar("statusPoison") == false then
        Log.LogInfo("-------Start UOPPoison--------")
        local mlbNum = paraTab.InputDict["MLB_Num"]
        local stationTable = utils.loadPlist(stationPath)
        local fixtureID = paraTab.InputDict["fixtureID"]
        local headID = tonumber(Device.identifier:sub(-1))

        if not mlbNum then
            paraTab.Input = "[FALSE]"
            paraTab["failMsg"] = "MLB_Num is Nil."
            return
        end

        local prefix, suffix = string.match(paraTab.InputDict["TPVersion"], "(TP)(.+)")
        local limitVersion =
            tostring(prefix .. "_" .. paraTab.InputDict["CPRV"] .. "_" .. suffix .. paraTab.InputDict["NonRetestable"])
        local stationVersion
        for k, v in pairs(stationTable) do
            if k == "StationVersion" then
                stationVersion = tostring(v) .. "_" .. tostring(limitVersion)
            end
        end

        local socProcessPoison = Atlas.loadPlugin("SoCProcessPoison")
        local testName = "UOP Poison "
        local initStatus, initResult = xpcall(
            socProcessPoison.UOPPoison,
            debug.traceback,
            tostring(mlbNum),
            tostring(fixtureID),
            tostring(headID),
            tostring(stationVersion),
            "Atlas2",
            tostring(testName),
            tostring(limitVersion)
        )

        if not initStatus then
            paraTab["message"] = "Please contact Station DRI！！！！"
                .. "socProcessPoison.UOPPoison FAIL"
                .. tostring(initResult)
            paraTab["subsubtestname"] = "UOPPoison"
            COF.showAlert(paraTab)
        else
            Log.LogInfo("$$$$$socProcessPoison.UOPPoison PASS")
        end
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0088:, Version: v0.1, Type:Inner]
Name: Process.compareSfcEcidCode
Function description: [v0.1]  Function to get sfc vaule campare local vaule
Input : Table(paraTab)
Output : string
Mark: (Unused)
-----------------------------------------------------------------------------------]]

function Process.compareSfcEcidCode(paraTab)
    helper.flowLogStart(paraTab)
    local sfc_url = paraTab.sfc_Url
    local sn = paraTab.sn
    local resultFlag = false
    local reportStatus, serialNumber = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
    local Ace3LogFile = serialNumber .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log"
    Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log", Ace3LogFile)

    local read_ace3LogPath = fileUtils.ReadFileAsString(Ace3LogPath)
    local Ace3_ECID = string.match(read_ace3LogPath, "Ace3_ECID:%s+(%w+)")
    Log.LogInfo("local ace ecid : " .. Ace3_ECID)
    local sfc_key = paraTab.sfc_key

    if sfc_url ~= nil then
        local command = "curl '" .. sfc_url .. "c=QUERY_RECORD" .. "&sn=" .. sn .. "&p=" .. sfc_key .. "'"
        Log.LogInfo("ace_ecid code command : " .. command)
        local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
        local status, sfc_resp = xpcall(RunShellCommand.run, debug.traceback, command)
        local sfc_data = comFunc.dump(sfc_resp)
        local get_ecid_sfc_data = string.match(sfc_data, "ace_ecid=(%w+)")
        Log.LogInfo("get_ecid_sfc_data : " .. tostring(get_ecid_sfc_data))

        if get_ecid_sfc_data == Ace3_ECID then
             resultFlag = true
             helper.flowLogFinish(resultFlag, paraTab)
        else
            failureMsg = "error result: get ecid sfc data is mismatch or fail, check local ecid "
            helper.flowLogFinish(resultFlag, paraTab, failureMsg)
        end
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0038:, Version: v0.1, Type:DFU]
Name: Process.DFUNandUOPPoison(paraTab)
Function description: [v0.1] Function to upload 3 times fail records to insight.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function Process.DFUNandUOPPoison(paraTab)
    helper.flowLogStart(paraTab)
    local mlbSerialNumber = paraTab.MLB_Num
    local fixtureID = paraTab.fixtureID
    local slotID = tonumber(Device.identifier:sub(-1))
    local message = paraTab.message  -- "DFU_Do_not_apply_AAB_retest_policy__FA_procedure_and_check_in_instantly"
    local socProcessPoison = Atlas.loadPlugin("SoCProcessPoison")
    local InteractiveView = Device.getPlugin("InteractiveView")
    local StationInfo = Atlas.loadPlugin("StationInfo")
    local stationName = StationInfo.product()
    local station_Type = StationInfo.station_type()
    local testName = "UOP Poison "
    local result = true
    local failMsg = ""

    Log.LogInfo("mlbSerialNumber "..mlbSerialNumber)
    Log.LogInfo("fixtureID "..fixtureID)
    Log.LogInfo("slotID "..slotID)
    Log.LogInfo("station_Type "..station_Type)
    Log.LogInfo("testName "..testName)
    Log.LogInfo("message "..message)

    local initStatus, initResult = xpcall(socProcessPoison.UOPPoison, debug.traceback, tostring(mlbSerialNumber),
                                          tostring(fixtureID), tostring(slotID), tostring(station_Type), "Atlas2",
                                          tostring(testName), tostring(message))
    Log.LogInfo("$$$$$ ",initStatus, initResult)
    if not initStatus then
        result = false
        failMsg = "Please contact Station DRI！！！！socProcessPoison.UOPPoison FAIL : " .. tostring(initResult)
        Log.LogInfo("$$$$$ "..failMsg)
        if paraTab.showView == "YES" then
            local viewConfig = {
                ["title"] = paraTab.subsubtestname,
                ["message"] = failMsg,
                ["button"] = { "OK" }
            }
            InteractiveView.showView(Device.systemIndex, viewConfig)
        end
        helper.flowLogFinish(false, paraTab, initResult, failMsg)
    else
        Log.LogInfo("$$$$$ DFU-ProcessPoison.UOPPoison PASS")
        helper.flowLogFinish(true, paraTab)
    end

    if result == false and paraTab.fa_sof == "YES" then
        helper.reportFailure(failMsg)
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0039:, Version: v0.1, Type:Common]
Name: Process.getDeviceOverallResult(paraTab)
Function description: [v0.1] Function to get csv overall test result and poison.
Input : Table(paraTab)
Output : Bool
-----------------------------------------------------------------------------------]]
function Process.getDeviceOverallResult(paraTab)
    local testFail = "FALSE"
    local overallStatus = paraTab.overallStatus
    Log.LogInfo("**********overallStatus", overallStatus)
    local localResultPass = 2
    if overallStatus == localResultPass then
        Log.LogInfo("$$$$$overallStatus", overallStatus)
    else
        testFail = "TRUE"
    end

    local variableTable
    local poison = "FALSE"
    local status, ret = xpcall(Device.getPlugin, debug.traceback, 'VariableTable')
    if status then
        variableTable = ret
        poison = variableTable.getVar("Poison") or "FALSE"
    end
    Log.LogInfo("###### Poison ###### ", poison)

    return testFail, poison
end



return Process
