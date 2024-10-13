-------------------------------------------------------------------
----***************************************************************
----Station Common Functions
----***************************************************************
-------------------------------------------------------------------
local Common = {}
local helper = require("Tech/SMTLoggingHelper")
local Log = require("Tech/logging")
local GeneratorLogFile = require("Tech/GeneratorLogFile")
local comFunc = require("Tech/CommonFunc")
local utils = require("Tech/utils")
local defaultFailResult = "FAIL"

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0001, Version: v0.1, Type:Common]
Name: Common.getSlotNum(paraTab)
Function description: [v0.1]Function to get the slot_num(~/Library/Atlas2/Modules/Tech) slot from number:1~4
Input : Table(paraTab)
Output : string(slot_num)
-----------------------------------------------------------------------------------]]
function Common.getSlotNum(paraTab)
    helper.flowLogStart(paraTab)
    local slot_num = Device.identifier:sub(-1)

    if slot_num == nil then
        slot_num = ""
        helper.flowLogFinish(false, paraTab)
    else
        if paraTab.attribute then
            DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, slot_num))
        end
        helper.flowLogFinish(true, paraTab, tonumber(slot_num))
    end

    return slot_num
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0002, Version: v0.1, Type:Common]
Name: Common.getSite(paraTab)
Function description: [v0.1] get CM site(~/Library/Atlas2/Modules/Tech) 
                        from /vault/data_collection/test_station_config/gh_station_info.json keys SITE
Input : gh_station_info.json file
Output : string(SITE)
-----------------------------------------------------------------------------------]]
function Common.getSite(paraTab)
    helper.flowLogStart(paraTab)
    local StationInfo = Device.getPlugin("StationInfo")
    local site = StationInfo.site()
    if site == nil then
        helper.flowLogFinish(false, paraTab)
    else
        helper.flowLogFinish(true, paraTab, site)
    end

    return site
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0003, Version: v0.1, Type:Common]
Name: Common.getScannedSN(paraTab)
Function description: [v0.1] get Scanned Serial Number for MLB(~/Library/Atlas2/Tech)
Input :
Output : string(MLB serial number)
-----------------------------------------------------------------------------------]]
function Common.getScannedSN(paraTab)
    helper.flowLogStart(paraTab)
    local sn = ""
    local interactiveView = Device.getPlugin("InteractiveView")
    local status, data = xpcall(interactiveView.getData, debug.traceback, Device.systemIndex)
    if (not status) or (data == nil) then
        helper.flowLogFinish(false, paraTab)
    else
        sn = data
        helper.flowLogFinish(status, paraTab, data)
    end

    return sn
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0004, Version: v0.1, Type:Common]
Name: Common.delay(paraTab)
Function description: [v0.1] Function run shell cmd to do some delay(~/Library/Atlas2/Modules/Tech)
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function Common.delay(paraTab)
    helper.flowLogStart(paraTab)
    local msg = ""
    local result = true
    if paraTab.unit == "ms" then
        local time = tonumber(paraTab.delay)
        local runShellCommand = Device.getPlugin('RunShellCommand')
        runShellCommand.run("sleep " .. tostring(time / 1000.0))
    else
        msg = "delay time unit setting incorrect."
        result = false
    end
    helper.flowLogFinish(result, paraTab, nil, msg)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0005, Version: v0.1, Type:InnerCommon]
Name: Common.ShowMsgUI(paraTab, msg)
Function description: [v0.1] Function Show message UI (~/Library/Atlas2/Modules/Tech)
                        no judge only show message for debug.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function Common.ShowMsgUI(paraTab, msg)
    local msg = paraTab.message or msg
    local interactiveView = Device.getPlugin("InteractiveView")
    local viewConfig = {
        ["title"] = paraTab.subsubtestname,
        ["message"] = msg,
        ["button"] = {"OK"}
    }

    interactiveView.showView(Device.systemIndex, viewConfig)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0006, Version: v0.1, Type:Common]
Name: Common.UOPCheck(paraTab)
Function description: [v0.1]Function to check DUT UOP(~/Library/Atlas2/Modules/Tech)
Input :Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function Common.UOPCheck(paraTab)
    helper.flowLogStart(paraTab)
    local result = true
    local _, res = xpcall(ProcessControl.amIOK, debug.traceback)
    helper.LogInfo("-- res:", res)
    local failMsg =''
    if res then
        failMsg = string.match(res, "unit_process_check=(.*)\";")  -- check unit_process_check content
        if failMsg then
            result = false
            Common.ShowMsgUI(paraTab,failMsg)
        end
    end
    helper.flowLogFinish(result, paraTab, nil, failMsg)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0007, Version: v0.1, Type:Common]
Name: Process.getStionInfo(paraTab)
Function description: [v0.1] Function to get station info. 
Input :Table(paraTab)
Output : string(user, product)
-----------------------------------------------------------------------------------]]
function Common.getSationInfo(paraTab)
    helper.flowLogStart(paraTab)
    local config_file = paraTab.Config_file
    local file = io.open(config_file, "r")
    local StationInfo = Device.getPlugin("StationInfo")
    local product = StationInfo.product()
    local user = nil -- this user is condition for DOE, undefined, mainline.

    if file ~= nil then
        local context = file:read("*all")
        if context ~= nil then
            local config = comFunc.parseParameter(context)
            if comFunc.hasKey(config, "user") then
                user = config["user"]
            end
        end
    end

    if user == nil or product == nil then
        helper.flowLogFinish(false, paraTab, nil, "get Station Info is empty")
    else
        helper.flowLogFinish(true, paraTab)
    end

    return user, product
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0008, Version: v0.1, Type:Common]
Name: Common.generateFlowLog(paraTab)
Function description: [v0.1] Function to generate flow log and pivot csv.
                              specific log transfor from coverage csv 
Input : Table(paraTab) 
Output : N/A
-----------------------------------------------------------------------------------]]
function Common.generateFlowLog(paraTab)
    Device.updateProgress(Device.test .. ", " .. Device.subtest .. ", " .. paraTab.subsubtestname)
    local StationInfo = Device.getPlugin("StationInfo")
    local product = StationInfo.product()
    local station_type = StationInfo.station_type()
    local slot_num = Device.identifier:sub(-1)
    local slot_id = "UUT" .. slot_num
    local timestamp = tostring(os.date("%m-%d-%H-%M-%S", os.time()))
    local runShellCmd = Device.getPlugin("RunShellCommand")
    local serialNumber = paraTab.MLB_Num or ""
    local logFile = paraTab.logFile or ""

   
    GeneratorLogFile.generateFlowLog(Device.userDirectory, tostring(slot_num))

    -- use array use spec keys 
    local flow_log_path = string.format("%s/%s_%s_%s_%s__%s_flow.log", Device.userDirectory, serialNumber, product,
                                        station_type, slot_id, timestamp)
    local pivot_csv_path = string.format("%s/%s_%s_%s_%s__%s_pivot.csv", Device.userDirectory, serialNumber, product,
                                         station_type, slot_id, timestamp)

    runShellCmd.run("mv " .. Device.userDirectory .. "/flow.log " .. flow_log_path)
    runShellCmd.run("mv " .. Device.userDirectory .. "/pivot.csv " .. pivot_csv_path)

    -- use for different station add log
    if logFile ~= "" then
        local logFileTable = comFunc.splitString(logFile, ",")
        -- foreach logFileTable need universe
        local status = comFunc.hasDuplicates(logFileTable)
        if status then 
            helper.reportFailure("logFile has duplicates") 
        end

        for _,value in pairs(logFileTable) do
            local defaultFormat = "%s/%s_%s_%s_%s__%s_" .. value

            if not string.find(value,"%.") then
                helper.reportFailure("logFile need has \".\"") 
            elseif string.find(value,"/") then  
                defaultFormat = "%s" .. string.gsub(value,"%.","_") .. "/%s_%s_%s_%s__%s_" .. string.gsub(value,"/","")
                value = string.gsub(string.gsub(value,"/",""),"%.","_").."/"..string.gsub(value,"/","")
                -- such as (/Smokey.log) --> (Smokey_log/Smokey.log)
            end
            
            local path = string.format(defaultFormat, Device.userDirectory, serialNumber, product,
                                       station_type, slot_id, timestamp)
            runShellCmd.run("mv " .. Device.userDirectory .. "/".. value .. " " .. path)
        end
    end 
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0050:, Version: v0.1, Type:Inner]
Name: QuerySFC
Function description: [v0.1]  get data from SFC Query
Input :snInput, attributeKey
Output : response(string)
-----------------------------------------------------------------------------------]]
local function  QuerySFC(snInput, attributeKey)
    local sfc = Device.getPlugin("SFC")
    local response = sfc.getAttributes(snInput, {attributeKey})
    return response
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0009:, Version: v0.1, Type:Common]
Name: Common.getSFCQuery(paraTab)
Function description: [v0.1]  get data from SFC Query
Input :
Output : string
-----------------------------------------------------------------------------------]]

--getAttributes(sn, names)
function Common.getSFCQuery(paraTab)
    local InnerCall = paraTab.InnerCall
    if not InnerCall then
        helper.flowLogStart(paraTab)
    end
    local sfc_key = paraTab.sfc_key
    local sn = tostring(paraTab.MLB_Num)
    local result = false
    local failureMsg = ""
    local ret = ""
    local status = false
    local sfc_table = {}
    local retry = 1

    if sn and #sn > 0 then
        if sfc_key then
            repeat
                status, sfc_table = xpcall(QuerySFC, debug.traceback, sn, sfc_key)
                if not status then
                    retry = retry + 1
                end
                Log.LogInfo(tostring(retry) .. " $$$$ sfc query [" .. sfc_key .. '] sfc_table: ' ..
                                comFunc.dump(sfc_table))
            until (retry > 3 or status)

            local sfc_value = sfc_table[sfc_key]
            if sfc_value and sfc_value ~= "" then
                result = true
                ret = sfc_value
            else
                failureMsg = "sfc_table[" .. sfc_key .. "] query failed"
            end
        else
            failureMsg = "miss sfc_key in parameters"
        end
    else
        failureMsg = "no input sn"
    end
    
    if not result then
        if not InnerCall then
            helper.flowLogFinish(result, paraTab, ret, failMsg)
        end
        helper.reportFailure(failureMsg)
    else
        if not InnerCall then
            helper.flowLogFinish(result, paraTab, ret, failMsg)
        end
        return ret
    end

end


local function inputVauleReplace( paraTab, replaceString, stringTable )
    local ret = nil

    if #replaceString > 0 then
        Log.LogInfo("replaceString>>>>> ".. replaceString)
        local replaceList = comFunc.splitString(replaceString, ";")
        Log.LogInfo("replaceList>>>>> ".. comFunc.dump(replaceList))
        for _,v in pairs(replaceList) do
            if string.find(v, stringTable[1]) ~= nil then
                local values = comFunc.splitString(v, "=")
                ret = values[2]
                Log.LogInfo("ret1>>>>> ".. ret)
                break
            end
        end
    end

    return ret
end

local function inputValueCombine( paraTab, stringTable, isCombine, ret )
    if isCombine == "YES" then
        Log.LogInfo(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ")
        local startString = paraTab.startString
        local endString = paraTab.endString or ""
        local connectString = paraTab.connectString

        if connectString then 
            for _, v in pairs(stringTable) do
                if v then
                    Log.LogInfo("v in stringTable>>>>> ".. v)
                    if #startString == 0 then
                        startString = tostring(v)
                        Log.LogInfo("startString v>>>>> ".. v)
                    else
                        startString = startString .. connectString .. tostring(v)
                        Log.LogInfo("startString with connectString>>>>> ".. startString)
                    end
                end
            end
            ret = startString .. endString
            Log.LogInfo("ret to connect>>>>> ".. ret)
        else
             ret = startString .. ret
        end 
    end

    return ret
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0010:, Version: v0.1, Type:Common]
Name: Common.parseWithRegexString(paraTab)
Function description: [v0.1]Function to parse string with pattern. 
Input : Table(paraTab) 
Output : string
-----------------------------------------------------------------------------------]]
function Common.parseWithRegexString(paraTab)
    helper.flowLogStart(paraTab)
    local LOG_DEVICE_PATH_TABLE = {
        ["restore_device"]=comFunc.getRestoreDeviceLogPath(),
        ["restore_host"]=comFunc.getRestoreHostLogPath(),
        ["uart"]=Device.userDirectory .. '/uart.log',
        ["kis_usb"]=Device.userDirectory .. '/kis_usb.log',
        ["base_kis_usb"]=Device.userDirectory .. '/base_kis_usb.log',
        ["system_device"]=Device.userDirectory .. '/../system/device.log'
    }
    local pattern = paraTab.pattern
    local log_device = tostring(paraTab.log_device)
    local log_path = LOG_DEVICE_PATH_TABLE[log_device]
    local ret = ""
    local failureMsg = ""
    local resultFlag = true
    local InputValue2 = paraTab.InputValue2
    local replaceString = paraTab.replaceString
    local isCombine = paraTab.isCombine
    local stringTable = {}
    local result = "TRUE"

    if paraTab.Input then
        ret = paraTab.Input
        table.insert(stringTable, ret)

        if InputValue2 ~= nil then
            if #stringTable > 0 then
                table.insert(stringTable, InputValue2)
                -- Log.LogInfo("stringTable2 ====>>>: ".. comFunc.dump(stringTable))
            end

            if replaceString ~= nil then
                local inputVauleReplaceRet = inputVauleReplace(paraTab, replaceString, stringTable)
                Log.LogInfo("inputVauleReplaceRet inputVauleReplace ====>>>: " .. inputVauleReplaceRet)
                ret = inputVauleReplaceRet
            end

            local inputValueCombineRet = inputValueCombine( paraTab, stringTable, isCombine, ret )
            Log.LogInfo("isCombine ret inputValueCombine ====>>>: " .. inputValueCombineRet)

            ret = inputValueCombineRet
            Log.LogInfo("ret<><><><><><><><><><><><> " .. ret)
        end
    elseif log_path then
        ret = string.format("%q",comFunc.fileRead(log_path))
        ret = string.gsub(ret, "\\\n", "\n")
    else
        helper.reportFailure("no input match string from test item!!! ")
    end
    
    if paraTab.pattern ~= nil or paraTab.patterns ~= nil or paraTab.gmatch_pattern ~= nil then
        if paraTab.removeAllSpaces ~= nil then
            ret = string.gsub(ret, "\r", "")
            ret = string.gsub(ret, "\n", "")
            ret = string.gsub(ret, ' ', '')
        end

        ret = string.match(ret, pattern)
        Log.LogInfo("parseWithRegexString pattern====>>>: "..pattern)

        if paraTab.Check_Storage == "YES" then
            if ret == nil or string.gsub(ret," ","") == "" then
                ret = "No_match"
                resultFlag = true
                result = "FALSE"
                helper.flowLogFinish(resultFlag, paraTab, ret, failureMsg)
                return result
            end
        end

        if paraTab.offect ~= nil then
            local offect = paraTab.offect
            ret = ret * offect
        end

        if paraTab.isFailStop then
            helper.reportFailure("restore failed.")
        end
        
        if paraTab.bit ~= nil then
            local bit_num = tonumber(paraTab.bit)
            if paraTab.suffix ~= nil then
                ret = "0x" .. tostring(ret)
            end
            ret = comFunc.hexToBinary(ret, bit_num, nil) -- ret len must is 8 bit.
        end

        if paraTab.removeAllQuot and ret then
            ret = string.gsub(ret,"\"","")
        end

        if paraTab.comparekey ~= nil and ret then
            local compare = require("Tech/Compare")
            if paraTab.compareFunc then 
               resultFlag, failureMsg = compare[paraTab.compareFunc]({ Input = ret }) 
            else    
                local compareValue = compare.getVersions()[paraTab.comparekey]
                if ret ~= compareValue then
                    resultFlag = false
                    failureMsg = failureMsg .. "compare failed"
                end
            end    
        end

        if paraTab.target and ret ~= paraTab.target then
            resultFlag = false
            failureMsg = "target value failed; expect [" .. tostring(paraTab.target) .. "]" .. " matched value: " .. "[" ..
                             tostring(ret) .. "]"
        end

        if ret == nil or string.gsub(ret," ","") == "" then
            ret = "No_match"
            resultFlag = false
            result = "FALSE"
            helper.flowLogFinish(resultFlag, paraTab, ret, failureMsg)
            return ret
        end

        if paraTab.isHexValue then
            ret = tostring(tonumber("0x" .. string.gsub(ret," ","")))
        end

        if paraTab.factor then
            ret = tostring(tonumber(ret) * tonumber(paraTab.factor))
        end

        if ret and paraTab.attribute then
            DataReporting.submit(DataReporting.createAttribute(paraTab.attribute,ret))
        end
    end

    helper.flowLogFinish(resultFlag, paraTab, ret, failureMsg)
    return ret, result
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0011:, Version: v0.1, Type:Common]
Name: Common.uploadAttributeToSFC(paraTab)
Function description: [v0.1] Function to upload attribute value to SFC and download SFC value
Input : Table(paraTab) 
Output : string(sfc_url)
-----------------------------------------------------------------------------------]]
function Common.uploadAttributeToSFC(paraTab)
    helper.flowLogStart(paraTab)
    local StationInfo = Device.getPlugin("StationInfo")
    local shellCommand = Device.getPlugin("RunShellCommand")
    local product = StationInfo.product()
    local station_Type = StationInfo.station_type()
    local station_ID = StationInfo.station_id()

    local sfc_path = paraTab.sfc_path
    local sfc_key = paraTab.sfc_key
    local sfc_value = paraTab.sfc_value
    local mlbSerialNumber = paraTab.MLB_Num
    local ADD_Type = paraTab.ADD_Type
    local sfc_url = ""

    if ADD_Type ~= "ADD_ATTR" then
        helper.reportFailure("ADD_Type must ADD_ATTR")
    end

    local context = comFunc.fileRead(sfc_path)
    if context ~= nil then
        local config = comFunc.parseParameter(context)
        sfc_url = config["ghinfo"]["SFC_URL"]
        if string.find(sfc_url,"?") then 
            sfc_url = string.gsub(sfc_url,"?","")   --remove all "?"
        end
        sfc_url = sfc_url .. "?"
    end

    if paraTab.BoardRev then
        -- local start_time = '2023-05-01 00:00:00'
        local start_time = string.format(os.date("%Y-%m-%d %H:%M:%S", os.time()))
        Log.LogInfo("$$$SFC_start_time: ", start_time)
        local os_times = os.difftime(os.time(), -60)
        Log.LogInfo("$$$SFC_os_times: ", os_times)
        local stop_time = string.format(os.date("%Y-%m-%d %H:%M:%S", os_times))
        Log.LogInfo("$$$SFC_stop_time: ", stop_time)
     
        local boardrev = paraTab.BoardRev
        local sfc_value = paraTab.sfc_value
        local sfc_param = sfc_key .. "=" .. sfc_value
                command = "\"result=PASS&c="..ADD_Type.."&product="..product.."&test_station_name="..station_Type.."&station_id="..station_ID
                .."&mac_address= &sw_version=&audit_mode=0&start_time="..start_time.."&stop_time="..stop_time.."&sn="..mlbSerialNumber..
                "&board_revision="..boardrev.."&"..sfc_param.."\" "..sfc_url
        --"result=PASS&c=ADD_ATTR&product=J410&test_station_name=DFU-NAND-INIT&station_id=BYLG_B4-3FAP-01_11_DFU-NAND-INIT&mac_address= &sw_version=&audit_mode=0&start_time=2024-04-12 22:24:43&
        --stop_time=2024-04-12 22:25:43&sn=H9HH4C0000U0000R50&board_revision=0x07&ticc_ver=00 01" http://10.12.5.34:80/peach/exi/me/bobcat?        
        Log.LogInfo("send post command: " .. command)
        local status, sfc_resp = xpcall(shellCommand.run, debug.traceback, "curl -X POST --data " .. command)
        if not status then
            helper.flowLogFinish(false, paraTab, sfc_resp.output, "from sfc to POST data is failed")
        else
            helper.flowLogFinish(true, paraTab, sfc_resp.output)
        end
        return sfc_url, sfc_resp
    end    
   
    -- example log: ACE3L_CRC1_I2C=0x980x2F0x860xBF
    local sfc_param = sfc_key .. "=" .. string.gsub(sfc_value, " ", "")
    --local upload_command = "curl \""..sfc_url.."&c="..ADD_Type.."&product="..product.."&test_station_name="..station_Type.."&station_id="..station_ID.."&start_time="..start_time.."&stop_time="..stop_time.."&sn="..mlbSerialNumber.."&"..sfc_param.."\""
    local upload_command = "curl \""..sfc_url.."&c="..ADD_Type.."&sn="..mlbSerialNumber.."&"..sfc_param.."\""
    Log.LogDebug("send upload command: "..upload_command)
    --curl "http://10.12.5.34:80/peach/exi/me/bobcat?&c=ADD_ATTR&sn=H9HH4C0000U0000R50&ACE3L_CRC1_I2C=0x980x2F0x860xBF"
    local status, sfc_resp = xpcall(shellCommand.run, debug.traceback, upload_command)
    Log.LogDebug("send upload sfc_resp: ".. sfc_resp.output)
    --send upload sfc_resp: 0 SFC_OK  
    if status and string.find(sfc_resp.output,'SFC_OK') then --add attribute result 
        -- download
        local download_command = "curl \""..sfc_url.."c=QUERY_RECORD".."&sn="..mlbSerialNumber.."&p="..sfc_key.."\""  -- query SFC attribute
        Log.LogDebug("send download command: "..download_command)
        --curl "http://10.12.5.34:80/peach/exi/me/bobcat?c=QUERY_RECORD&sn=H9HH4C0000U0000R50&p=ACE3L_CRC1_I2C"
        status, sfc_resp = xpcall(shellCommand.run, debug.traceback, download_command)
        Log.LogDebug("send download sfc_resp: ".. sfc_resp.output)
        --send download sfc_resp: 0 SFC_OK
        if status and string.find(sfc_resp.output,'SFC_OK') and string.find(sfc_resp.output, string.gsub(sfc_value, " ", "")) then  -- query SFC attribute result
            helper.flowLogFinish(true, paraTab)
        else
            helper.flowLogFinish(false, paraTab, sfc_resp.output, "from sfc to download data is failed")
        end
    else
        helper.flowLogFinish(false, paraTab, sfc_resp.output, "upload data to sfc is failed")
    end

    return sfc_url, sfc_resp.output
end



--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0012:, Version: v0.1, Type:Common]
Name: Common.detectKisUSBPort(paraTab)
Function description: [v0.1] Function to detect and find the KisUSB Serialport
Input : Table(paraTab) 
Output : N/A
-----------------------------------------------------------------------------------]]
function Common.detectKisUSBPort(paraTab)
    helper.flowLogStart(paraTab)
    local runShellCmd = Device.getPlugin("RunShellCommand")
    local dut = Device.getPlugin(paraTab.dutPluginName)
    local commands = paraTab.Commands
    local failureMsg = ""
    local result = false
    local timeout = tonumber(paraTab.Timeout)
    local startTime = os.time()
    local Location_ID = tostring(paraTab.Location_ID)
    local devPath = string.gsub(Location_ID,"0x","") .. "%-ch%-0"
    Log.LogInfo("devPath---->", devPath)    --2134000%-ch%-0  
    
    repeat
        local devContent = runShellCmd.run(commands)['output']  --/dev/cu.kis-02134000-ch-0
        Log.LogInfo("devContent---->", devContent)
        if string.find(tostring(devContent), devPath) then
            if dut.isOpened() ~= 1 then
                local status, ret = xpcall(dut.open, debug.traceback, 3)
                if status then
                    result = true
                    break
                else
                    failureMsg = "KisUSBSerialport open failed"
                end
            else
                result = true
                break
            end
        else
            comFunc.sleep(0.1)
        end
    until(os.difftime(os.time(), startTime) >= timeout)
    
    if result then
        helper.flowLogFinish(true, paraTab)
    else
        helper.flowLogFinish(result, paraTab, nil, failureMsg)
        helper.reportFailure(failureMsg)
    end
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0013, Version: v0.1, Type:Common]
Name: Common.calValue(paraTab)
Function description: [v0.1]Function to cal value for bash command.
Input :  Table(paraTab) 
Output : Number
-----------------------------------------------------------------------------------]]
function Common.calValue(paraTab)
    if not paraTab.InnerCall then
        helper.flowLogStart(paraTab)
    end
    local mutex = Device.getPlugin("Mutex")
    local runShellCmd = Device.getPlugin("RunShellCommand")
    local value = paraTab.value
    local scale = paraTab.scale
    local formula = paraTab.formula
    local calmode = paraTab.calmode
    local id = "calValue" .. Device.identifier:sub(-1)

    -- use echo 'scale=3;-6479.000000/32'|bc 
    mutex.acquire(id)
    local cmd = string.gsub("printf '%.1f'","1", scale)
    local sumFormula = value .. calmode .. formula
    local commands = string.format("`echo 'scale=%d;%s'|bc`", scale, sumFormula)
    local result = runShellCmd.run(cmd .. " " .. commands)['output'] 
    mutex.release(id)

    if not paraTab.InnerCall then
        if result then
            helper.flowLogFinish(true, paraTab, result)
        else
            helper.flowLogFinish(false, paraTab, nil, "input nil value")
        end
    end
    return tonumber(result)
end 

return Common
