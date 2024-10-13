local DUTCmd = {}

local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local helper = require("Tech/SMTLoggingHelper")
local fileUtils = require("ALE/FileUtils")
local DiagsTriage = require("DiagsTriage/DiagsTriage")
local pListSerialization = require ("Serialization.PListSerialization")
local configTable = pListSerialization.LoadFromFile(string.gsub(Atlas.assetsPath, 'Assets', "Config/project_config.plist"))
local isDiagsTriageCheck = configTable["isDiagsTriageCheck"]

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0058:, Version: v0.1, Type:Inner]
Name: DUTCmd.dutRead
Function description: [v0.1] Function to read dut uart string
Input : Table(paraTab)
Output : content(string)
-----------------------------------------------------------------------------------]]
function DUTCmd.dutRead(paraTab)
    local dutPluginName = paraTab.dutPluginName
    local dut = Device.getPlugin(dutPluginName)
    local default_delimiter = paraTab.default_delimiter or "] :-)"
    local timeout = paraTab.Timeout or 1

    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    dut.setDelimiter("")
    local cmd = paraTab.Commands
    local mark = paraTab.mark
    if cmd ~= nil then
        if mark == nil then
            helper.LogDutCommStart(command)
        end
        dut.write(cmd)
    end
    local content = ""
    local maxLoopTime = math.ceil(tonumber(timeout) / 0.2)
    local index = 0
    repeat
        local status, ret = xpcall(dut.read, debug.traceback, 0.2)
        if status and ret and #ret > 0 then
            if mark == nil then
                helper.LogDutCommFinish(ret)
            end
            content = content .. ret
            index = 0
        else
            index = index + 1
        end
    until index >= maxLoopTime

    dut.setDelimiter(default_delimiter)
    return content
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0059:, Version: v0.1, Type:Inner]
Name: DUTCmd.sendCmd
Function description: [v0.1] Function to send command to DUT
Input : Table(paraTab)
Output : cmdReturn(string)
-----------------------------------------------------------------------------------]]
function DUTCmd.sendCmd(paraTab)
    local dutPluginName = paraTab.dutPluginName
    local dut = Device.getPlugin(dutPluginName)
    local cmds = {}
    local cmd = paraTab.Commands
    local combinationStatus = paraTab.CombinationStatus
    local cmdReturn = ""
    local hangTimeout = paraTab.hangTimeout
    local timeout = paraTab.Timeout
    local date = paraTab.Date

    if cmd == nil then
        return cmdReturn
    end

    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 5
    end

    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    if hangTimeout ~= nil then
        local hangDetector = Device.getPlugin(paraTab.channelPluginName)
        hangDetector.setHangTimeout(tonumber(hangTimeout))
    end

    if cmd and date then
        cmd = string.format("%s %s", cmd, os.date("%Y%m%d%H%M%S"))
    end

    if combinationStatus == "YES" then
        table.insert(cmds,cmd)
    else
        cmds = comFunc.splitString(cmd, ';')
    end

    if paraTab.delimiter ~= nil then
        dut.setDelimiter(paraTab.delimiter)
    else
        dut.setDelimiter("] :-) ")
    end

    for i = 1, #cmds do
        helper.LogDutCommStart(cmds[i])
        dut.write(cmds[i])

        local status, temp = xpcall(dut.read, debug.traceback, timeout)
        helper.LogDutCommFinish(temp)
        if status and temp ~= nil then
            cmdReturn = cmdReturn .. temp
        else
            helper.reportFailure("DUT read Fail !!!")
        end
    end

    if string.match(cmdReturn, "HangDetected") ~= nil then
        helper.reportFailure("Hang Detected")
    end

    return cmdReturn
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0088:, Version: v0.1, Type:Inner]
Name: DUTCmd.GetCMDFromTable(cmd)
Function description: [v0.1] Function to Parse Diags Command
Input : Table(paraTab)
Output : cmdReturn(string)
-----------------------------------------------------------------------------------]]
function DUTCmd.GetCMDFromTable(cmd)
    local cmdTable = require("CommandTable")
    local cmdValue = ""
    local cmdParse = ""
    for key, value in pairs(cmdTable.list) do
        if cmd == key then
            cmdValue = value.cmd
            cmdParse = value.parse_str or ""
            break
        end
    end
    if cmdParse == "" then
        cmdParse = nil
    end
    return cmdValue, cmdParse
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0089, Version: v0.1, Type:Inner]
Name: DUTCmd.enableUSB(paraTab)
Function description: [v0.1]Function to enable USB for usbfs capture and transfer to host.
Input : Table
Output : Number
-----------------------------------------------------------------------------------]]
function DUTCmd.enableUSB(paraTab)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local StationInfo = Atlas.loadPlugin("StationInfo")  
    local fixtureBuilder = Atlas.loadPlugin("FixturePlugin")
    local fixturePlugin = fixtureBuilder.createFixtureBuilder(0)
    local timeout = 10
    local ret = nil
    local station_type = StationInfo.station_type()
    local EnableUSBCMD = configTable["EnableUSBCMD"]
    helper.LogFixtureControlStart("fixture_command", EnableUSBCMD, timeout)
    if string.find(station_type, "DFU") then -- fix dfu dylib
        __, ret = xpcall(fixturePlugin.fixture_command, debug.traceback, EnableUSBCMD, "", timeout, slot_num)
    else
        __, ret = xpcall(fixturePlugin.fixture_command, debug.traceback, EnableUSBCMD, timeout, slot_num)
    end
    helper.LogFixtureControlFinish(ret and tostring(ret) or "done")
    return ret
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0090, Version: v0.1, Type:Inner]
Name: DUTCmd.disableUSB(paraTab)
Function description: [v0.1]Function to disable USB.
Input : Table
Output : N/A
-----------------------------------------------------------------------------------]]
function DUTCmd.disableUSB(paraTab)
    local slot_num = tonumber(Device.identifier:sub(-1))
    local StationInfo = Atlas.loadPlugin("StationInfo") 
    local fixtureBuilder = Atlas.loadPlugin("FixturePlugin")
    local fixturePlugin = fixtureBuilder.createFixtureBuilder(0)
    local timeout = 10
    local ret = nil
    local station_type = StationInfo.station_type()
    local DisableUSBCMD = configTable["DisableUSBCMD"]
    if paraTab.flag then
        DisableUSBCMD = configTable["DisableUSBCMD"] .. tostring(flag) .. ")"
    end
    helper.LogFixtureControlStart("fixture_command", DisableUSBCMD, timeout)
    if string.find(station_type, "DFU") then -- fix dfu dylib
        __, ret = xpcall(fixturePlugin.fixture_command, debug.traceback, DisableUSBCMD, "", timeout, slot_num)
    else
        __, ret = xpcall(fixturePlugin.fixture_command, debug.traceback, DisableUSBCMD, timeout, slot_num)
    end
    helper.LogFixtureControlFinish(ret and tostring(ret) or "done")
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0091, Version: v0.1, Type:Inner]
Name: DUTCmd.DiagsTriage(paraTab)
Function description: [v0.1]Function to Diags Triage.
Input : Table
Output : N/A
-----------------------------------------------------------------------------------]]
function DUTCmd.DiagsTriage(paraTab)
    local testName = paraTab.subsubtestname
    local slot_num = tonumber(Device.identifier:sub(-1))    
    local usbfs = Atlas.loadPlugin("USBFS")
    local dutPluginName = paraTab.dutPluginName or "dut"
    local dut = Device.getPlugin(dutPluginName)
    local usbfstool = configTable["USBFSTool"]
    usbfs.setHostToolPath(usbfstool)
    usbfs.setDebugFlag(true)
    usbfs.setDefaultTimeout(30)
    local __, hostPath = xpcall(DiagsTriage.captureAndTransferToHost, debug.traceback, dut, usbfs, Device.userDirectory, testName)
    helper.flowLogDebug("DiagsTriage hostPath-->", hostPath)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0092, Version: v0.1, Type:Common]
Name: DUTCmd.DiagsTriageTest(paraTab)
Function description: [v0.1]Function to Diags Triage.
Input : Table
Output : N/A
-----------------------------------------------------------------------------------]]
function DUTCmd.DiagsTriageTest(paraTab)
    helper.flowLogStart(paraTab)
    local VariableTable = Device.getPlugin("VariableTable")
    local DiagsTriageFlag = VariableTable.getVar("DiagsTriageFlag")
    helper.LogInfo("$$$$$ DiagsTriageFlag =====> :" .. tostring(DiagsTriageFlag))
    if DiagsTriageFlag then
        local flag = DUTCmd.enableUSB(paraTab)
        if flag and tonumber(flag) then
            paraTab.flag = tonumber(flag)
        end
        xpcall(DUTCmd.DiagsTriage, debug.traceback, paraTab)
        DUTCmd.disableUSB(paraTab)
    end
    helper.flowLogFinish(true, paraTab)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0092, Version: v0.1, Type:Common]
Name: DUTCmd.copyToHost(paraTab)
Function description: 
Input : Table
Output : N/A
-----------------------------------------------------------------------------------]]
function DUTCmd.copyToHost(paraTab)
    helper.flowLogStart(paraTab)
    DUTCmd.enableUSB(paraTab)
    local slot_num = tonumber(Device.identifier:sub(-1))    
    local usbfs = Atlas.loadPlugin("USBFS")
    local dutPluginName = paraTab.dutPluginName or "dut"
    local dut = Device.getPlugin(dutPluginName)
    local filePath = paraTab.filePath
    local usbfstool = configTable["USBFSTool"]
    usbfs.setHostToolPath(usbfstool)
    usbfs.setDebugFlag(true)
    usbfs.setDefaultTimeout(30)
    xpcall(usbfs.copyToHost, debug.traceback, dut, Device.userDirectory, {[filePath] = ""})
    DUTCmd.disableUSB(paraTab)
    helper.flowLogFinish(true, paraTab)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0037, Version: v0.1, Type:Common]
Name: DUTCmd.sendCmdAndParse(paraTab)
Function description: [v0.1]Function to send command to DUT and parse DUT return value.
Input : Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]
function DUTCmd.sendCmdAndParse(paraTab)
    if not paraTab.InnerCall then
        helper.flowLogStart(paraTab)
    end    

    if paraTab.CMDTableFlag == "true" then
        paraTab.Commands, paraTab.pattern =  DUTCmd.GetCMDFromTable(paraTab.Commands)
    end

    local pattern = paraTab.pattern
    local timeout_sub = tonumber(paraTab.timeout_sub or 1)
    local msg, resultFlag, rawData = "", nil, nil

    if paraTab.mark ~= nil then
        xpcall(DUTCmd.dutRead, debug.traceback, {dutPluginName = paraTab.dutPluginName, Commands = "\r\n", Timeout = timeout_sub, mark = paraTab.mark})
    end

    resultFlag, rawData = xpcall(DUTCmd.sendCmd, debug.traceback, paraTab, 1)
    if (not paraTab.NotDiagsTriage) and isDiagsTriageCheck == "YES"  then
        if (not resultFlag) or ((paraTab.errorCheck ~= "NO") and string.find(string.lower(rawData),"error")) then
            local VariableTable = Device.getPlugin("VariableTable")
            VariableTable.setVar("DiagsTriageFlag",true)              
            xpcall(DUTCmd.dutRead, debug.traceback, {dutPluginName = paraTab.dutPluginName, Commands = "", Timeout = 5})
            local DiagsTriageFlag = VariableTable.getVar("DiagsTriageFlag")
            helper.LogInfo("$$$$$ DiagsTriageFlag =====> :" .. tostring(DiagsTriageFlag))
            helper.flowLogFinish(false, paraTab, nil, string.format("send diags command [%s]  is error or received timeout", paraTab.Commands))
            return rawData
        end
    end
    local response = rawData
    if string.find(response, "Hang Detected") ~= nil then
        if not paraTab.InnerCall then
           helper.flowLogFinish(false, paraTab, nil, "Hang Detected")
        end   
        helper.reportFailure(failureMsg)
    end

    if string.find(string.lower(rawData), "error") then
        resultFlag = false
        msg ="command error"
        if paraTab.errorCheck == "NO" then
            resultFlag = true
            msg = ""
        end
    end

    if pattern ~= nil then
        if paraTab.escape ~= nil then
            response = string.gsub(rawData, "\r", "")
            response = string.gsub(response, "\n", "")
        end

        response = string.match(response, pattern)

        if response == nil or string.gsub(response, " ", "") == "" then
            resultFlag = false
            msg = msg .. " pattern not match"
        end
    end

    if not pattern  and paraTab.patterns then
        local patternsResponse = string.gmatch(response, paraTab.patterns)
        if string.find(paraTab.patterns, "dfu results") then
            -- smokeytest_wdfu_match_record
            local WDFUTable = {}
            for name,vaule,units,lowerLimit,upperLimit,status in patternsResponse do
                local limit = {
                        ["lowerLimit"] = tonumber(lowerLimit),
                        ["upperLimit"] = tonumber(upperLimit),
                        ["units"] = units
                    }
                if status and status ~= "pass" then
                    resultFlag = false
                end
                if tonumber(vaule) and (not WDFUTable[name]) then
                   helper.createParametricRecord(tonumber(vaule), Device.test, Device.subtest, name, limit)   
                   WDFUTable[name] = true          --remove duplicate values
                end  
            end
        end
        for value1,value2,value3,value4,value5,value6 in patternsResponse do
            if value1 == nil or string.gsub(value1, " ", "") == "" then
                resultFlag = false
            end
            if value1 and value2 and value3 and value4 and value5 and value6 then
                response = value1 .. " " .. value2 .." " .. value3 .." " ..
                           value4 .. " " .. value5 .. " " .. value6
            elseif value1 and value2 and value3 and value4 and value5 then
                response = value1 .." " .. value2 .." " .. value3 .." " ..
                           value4 .." " .. value5                 
            else 
                response = value1
            end    
        end 
        if not resultFlag then msg = msg .. " have fail value or pattern not match" end   
    end
    
    if paraTab.comparekey ~= nil and response then
        local compare = require("Tech/Compare")
        local compareValue = compare.getVersions()[paraTab.comparekey]
        if response ~= compareValue then
            resultFlag = false
            msg = msg .. " compare failed"
        end
    end
    
    if paraTab.attribute and (not paraTab.InnerCall) then
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, response))
    end

    if paraTab.expect ~= nil then
        local expect = paraTab.expect
        local expectReuslt = string.match(rawData, expect)
        if expectReuslt == nil or string.gsub(expectReuslt, " ", "") == "" then
            resultFlag = false
            msg = msg .. " expect not match"
        end
    end
    if not paraTab.InnerCall then
        local result = nil
        if paraTab.isparametric then
            result = response
        end    
        if resultFlag then
            helper.flowLogFinish(true, paraTab, result)
        else
            helper.flowLogFinish(false, paraTab, nil, msg)
        end
    end   

    return response, rawData, msg
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0029, Version: v0.1, Type:DFU]
Name: DUTCmd.getFileFromDUT(paraTab)
Function description: [v0.1]Function to send commonds to read smokey.log then creat smokey.log.
Input : Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]
function DUTCmd.getFileFromDUT(paraTab)
    helper.flowLogStart(paraTab)
    local folderName = paraTab.folderName
    local dutCommand = paraTab.Commands
    local fileName = dutCommand:match("^.+\\(.+)$")
    local filePath = ""
    local response = ""
    local result = false
    local failMessage = "get file error."

    if folderName then
        local folderPath = fileUtils.joinPaths(Device.userDirectory, folderName)
        if not fileUtils.FileExists(folderPath) then
            fileUtils.CreateDirectoryPath(folderPath)
        end
        filePath = fileUtils.joinPaths(folderPath, fileName)
    else
        filePath = fileUtils.joinPaths(Device.userDirectory, fileName)
    end

    Log.LogInfo("filePath: " .. filePath)
    if dutCommand then
        local status, ret = xpcall(DUTCmd.sendCmd, debug.traceback, paraTab, dutCommand)
        if status  and #ret > 0 then
            fileUtils.WriteStringToFile(filePath, tostring(ret), "w")
            response = ret
            result = true
            failMessage = ""
        end
    end

    helper.flowLogFinish(result, paraTab, response, failMessage)
    return response
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0028, Version: v0.1, Type:Common]
Name: DUTCmd.getInputValue(paraTab)
Function description: [v0.1]Function to return input value and record.
Input : Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]
function DUTCmd.getInputValue(paraTab)
    helper.flowLogStart(paraTab)
    local result = paraTab.Input
    if paraTab.attribute then
            DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, result))
    end
    if result then
        helper.flowLogFinish(true, paraTab, result)
    else
        helper.flowLogFinish(false, paraTab, nil, "input nil value")
    end
    return result
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0027, Version: v0.1, Type:DFU]
Name: DUTCmd.ACE3ScreenFunction(paraTab)
Function description: [v0.1]Function to repeat send commonds then catch error string.
Input : Table(paraTab)
Output : number/bool
-----------------------------------------------------------------------------------]]
function DUTCmd.ACE3ScreenFunction(paraTab)
    helper.flowLogStart(paraTab)
    local startValue = tonumber(paraTab.Start)
    local endValue = tonumber(paraTab.End)
    local stepValue = tonumber(paraTab.Step) 
    local dut = Device.getPlugin(paraTab.dutPluginName)
    local expect = paraTab.expect
    local errorInfo = paraTab.errorInfo
    local waitDiags = paraTab.Wait_Diags
    local timeout = paraTab.Timeout
    local hangTimeout = paraTab.hangTimeout
    local delayTime = 0
    local loopC = 0
    local CB_Status = "TRUE"
    local result = true
    local failureMessage = nil
    local targetindex = paraTab.targetindex
    if targetindex then
        targetindex = tonumber(targetindex)
    else
        targetindex = "null"
    end

    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        timeout = 5
    end

    if dut.isOpened() ~= 1 then
        dut.open(2)
    end

    if paraTab.delimiter ~= nil then
        dut.setDelimiter(paraTab.delimiter)
    else
        dut.setDelimiter("] :-) ")
    end

    if hangTimeout ~= nil then
        local hangDetector = Device.getPlugin(paraTab.channelPluginName)
        hangDetector.setHangTimeout(tonumber(hangTimeout))
    end

    for time = startValue, endValue, stepValue do
        local targetResp = ""
        loopC = loopC + 1
        delayTime = time
        local cmd = paraTab.Commands
        if string.find(cmd, "xxx") ~= nil then
            cmd = string.gsub(cmd, "xxx", tostring(time))
        end

        helper.LogDutCommStart(cmd)
        dut.write(cmd)
        local status, ret = xpcall(dut.read, debug.traceback, timeout)
        helper.LogDutCommFinish(ret)

        if not status and string.find(ret, "Hang Detected") then
            failureMessage = "Hang Detected"
            helper.flowLogFinish(false, paraTab, "repeatSendCommandCheckError", failureMessage)
            helper.reportFailure(failureMessage)
            return
        end
        if status then
            if targetindex == i then
                targetResp = ret
            end

            if targetindex == "null" then
                targetResp = targetResp .. ret
            end
        end
        if waitDiags then
            helper.LogDutCommStart(tostring(waitDiags))
            dut.write(tostring(waitDiags))
            local status, waitRet = xpcall(dut.read, debug.traceback, timeout)
            helper.LogDutCommFinish(waitRet)
        end

        if errorInfo and string.find(targetResp, string.gsub(errorInfo, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) then
            failureMessage = "found errorInfo"
            result = false
            break
        else
            if expect and (not string.find(targetResp, string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1"))) then
                failureMessage = "response not match"
                result = false
                break
            end
        end
    end
    Log.LogInfo("******delayTime********" .. tostring(delayTime))
    Log.LogInfo("******loopCount********" .. tostring(loopC))
    if result == false then
        CB_Status = "FALSE"
    end

    helper.flowLogFinish(result, paraTab, nil, failureMessage)

    return delayTime, loopC, CB_Status
end

return DUTCmd
