-------------------------------------------------------------------
----***************************************************************
----Parser Functions
----Created at: 07/21/2020
----Author: Bin Zhao (zhao_bin@apple.com)
----***************************************************************
-------------------------------------------------------------------
-- require("plist")
local Parser = {}
local comFunc = require("Tech/CommonFunc")
local Log = require("Tech/logging")
local Record = require("Tech/record")
local utils = require("Tech/utils")
local helper = require("Tech/SMTLoggingHelper")
local DFUCommon = require("Tech/DFUCommon")

local AttributePath = "/Users/gdlocal/Library/Atlas2/supportFiles/Attributes.plist"
local AttributeTable = utils.loadPlist(AttributePath)

Parser.AttributeRecord = 0
Parser.ParametricRecord = 1
Parser.BinaryRecord = 2

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0063:, Version: v0.1, Type:Inner]
Name: Parser.regexParseString
Function description: [v0.1]  Match the expected value from log and compare md5
Input :Table(paraTab)
Output : ret(string)
Mark: (Unused) need clear action function,Have been updated.
-----------------------------------------------------------------------------------]]
function Parser.regexParseString(paraTab)
    local ret = paraTab.Input
    if ret == nil then
        local log_device = paraTab.log_device or nil
        local log_path = Device.userDirectory .. "/../system/device.log"
        local Restore = require("Tech/Restore")
        if log_device == "restore_device" then
            log_path = Restore.getRestoreDeviceLogPath()
        elseif log_device == "restore_host" then
            log_path = Restore.getRestoreHostLogPath()
        elseif log_device == "uart" then
            log_path = Device.userDirectory .. "/uart.log"
        elseif log_device == "kis_usb" then
            log_path = Device.userDirectory .. "/kis_usb.log"
        elseif log_device == "base_kis_usb" then
            log_path = Device.userDirectory .. "/base_kis_usb.log"
        end
        ret = string.format("%q", comFunc.fileRead(log_path))
        ret = string.gsub(ret, "\\\n", "\n")
        Log.LogInfo("$$$$ parseFromLog log_path " .. tostring(log_path))
    end
    local subsubtestname = paraTab.subsubtestname
    local result = true
    local failureMsg = ""
    local pattern = paraTab.pattern
    local luaPattern = paraTab.luaPattern
    if ret and #ret > 0 then
        if pattern then
            local matchs = string.gmatch(ret, pattern)
            if matchs and #matchs > 0 and #matchs[1] > 0 then
                ret = comFunc.trim(matchs[1][1])
            else
                result = false
            end
        end
        if ret and #ret > 0 and result then
            local removeAllSpaces = paraTab.removeAllSpaces or "NO"
            if removeAllSpaces == "YES" then
                ret = string.gsub(ret, "\r", "")
                ret = string.gsub(ret, "\n", "")
                ret = string.gsub(ret, " ", "")
            end

            local isCombine = paraTab.isCombine or "NO"
            if isCombine == "YES" then
                local startString = paraTab.startString or ""
                local endString = paraTab.endString or ""
                local connectString = paraTab.connectString or ""
                for _, v in pairs(paraTab.InputValues) do
                    if v then
                        if #startString == 0 then
                            startString = tostring(v)
                        else
                            startString = startString .. connectString .. tostring(v)
                        end
                    end
                end
                ret = startString .. endString
            end

            if paraTab.attribute then
                DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, ret))
            end

            if paraTab.comparekey ~= nil and result then
                local vc = require("Tech/Compare")
                local key = paraTab.comparekey
                if key == "ChipRev" then
                    local StationInfo = Atlas.loadPlugin("StationInfo")
                    local Product = string.gsub(StationInfo.product(), "J", "")
                    local Product_number = tonumber(Product)
                    local rtos_md5 = vc.getVersions()[ret .. "_RTOS_MD5"]
                    local rbm_md5 = vc.getVersions()[ret .. "_RBM_MD5"]
                    local rtos_path_A = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore/FactoryTests/j" ..
                                            tostring(Product_number) .. "/console.j" .. tostring(Product_number) ..
                                            ".im4p"
                    local rbm_path_A = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore/FactoryTests/j" ..
                                           tostring(Product_number) .. "/rbm.j" .. tostring(Product_number) .. ".im4p"
                    local rtos_path_B =
                        "/Users/gdlocal/" .. "RestorePackage/" .. "CurrentBundle/Restore/FactoryTests/j" ..
                            tostring(Product_number + 1) .. "/console.j" .. tostring(Product_number + 1) .. ".im4p"
                    local rbm_path_B = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore/FactoryTests/j" ..
                                           tostring(Product_number + 1) .. "/rbm.j" .. tostring(Product_number + 1) ..
                                           ".im4p"
                    local rtos_md5_A =
                        string.match(DFUCommon.runShellCmd("/sbin/md5 " .. rtos_path_A).output, "MD5.-=%s(%w+)")
                    local rbm_md5_A =
                        string.match(DFUCommon.runShellCmd("/sbin/md5 " .. rbm_path_A).output, "MD5.-=%s(%w+)")
                    local rtos_md5_B =
                        string.match(DFUCommon.runShellCmd("/sbin/md5 " .. rtos_path_B).output, "MD5.-=%s(%w+)")
                    local rbm_md5_B =
                        string.match(DFUCommon.runShellCmd("/sbin/md5 " .. rbm_path_B).output, "MD5.-=%s(%w+)")

                    if string.match(rtos_md5, ";") ~= nil then
                        local rtos_md5_list = comFunc.splitString(rtos_md5, ";")
                        if rtos_md5_list[1] ~= rtos_md5_A or rtos_md5_list[2] ~= rtos_md5_B then
                            result = false
                            failureMsg =
                                "compare failed; expect [" .. rtos_md5 .. "] got [" .. rtos_md5_A .. "] and [" ..rtos_md5_B .. "]"
                        end
                    else
                        if rtos_md5 ~= rtos_md5_A or rtos_md5 ~= rtos_md5_B then
                            result = false
                            failureMsg =
                                "compare failed; expect [" .. rtos_md5 .. "] got [" .. rtos_md5_A .. "] and [" ..rtos_md5_B .. "]"
                        end
                    end
                    if result then
                        if string.match(rbm_md5, ";") ~= nil then
                            local rbm_md5_list = comFunc.splitString(rbm_md5, ";")
                            if rbm_md5_list[1] ~= rbm_md5_A or rbm_md5_list[2] ~= rbm_md5_B then
                                result = false
                                failureMsg = "compare failed; expect [" .. rbm_md5 .. "] got [" .. rbm_md5_A .."] and [" .. rbm_md5_B .. "]"
                            end
                        else
                            if rbm_md5 ~= rbm_md5_A or rbm_md5 ~= rbm_md5_B then
                                result = false
                                failureMsg = "compare failed; expect [" .. rbm_md5 .. "] got [" .. rbm_md5_A .."] and [" .. rbm_md5_B .. "]"
                            end
                        end
                    end
                else
                    local compareValue = vc.getVersions()[key]
                    if compareValue and #compareValue > 0 then
                        if ret ~= compareValue then
                            result = false
                            failureMsg = "compare failed; expect [" .. compareValue .. "]" .. "got [" .. ret .. "]"
                        end
                    else
                        result = false
                        failureMsg = "get compareValue failed"
                    end
                end
            end

            local target = paraTab.target
            if target ~= nil and ret ~= target then
                result = false
                failureMsg = "target value failed; expect [" .. tostring(target) .. "]" .. " matched value: " .. "[" ..
                                 tostring(ret) .. "]"
            end
        else
            result = false
            failureMsg = "misse pattern or parse failed"
        end
    else
        result = false
        failureMsg = "missed input or log path"
    end

    local expectedValue = paraTab.target
    -- local limit = nil
    -- if expectedValue then
    --     -- limit = { ["lowerLimit"] = expectedValue, ["upperLimit"] = expectedValue }
    -- end
    if result then
        helper.logTestAction(ret, paraTab, failureMsg, subsubtestname, limit)
    else
        helper.createRecord(result, paraTab, failureMsg, subsubtestname, limit, ret)
    end
    return ret
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0064:, Version: v0.1, Type:Inner]
Name: Parser.mdParse
Function description: [v0.1]  Parse response with MD Parser
Input :Table(paraTab)
Output : retData(string)
Mark: (Unused)
-----------------------------------------------------------------------------------]]
function Parser.mdParse(paraTab, resp)
    Log.LogInfo("--------- Running MD parser --------")
    Log.LogInfo("$$$$ Running MD parser resp" .. tostring(resp))

    local result = resp and true or false

    -- Parse DUT response
    local retData = nil
    if result then
        local mdParser = Device.getPlugin("MDParser")
        result, retData = xpcall(mdParser.parse, debug.traceback, paraTab.Commands, resp)
    end

    if not result then
        error("PARSE COMMAND FAIL: " .. tostring(retData))
    end
    return retData
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0065:, Version: v0.1, Type:Inner]
Name: Parser.createRecordWithDataTable
Function description: [v0.1] Create records based on paraTab, data table, 
                             attribute list and limit file
Input :Table(paraTab)
Output : result(bool)
Mark: (Unused)
-----------------------------------------------------------------------------------]]
function Parser.createRecordWithDataTable(paraTab, dataTable)
    Log.LogInfo("$$$$ subSubTestName>> dataTable>>", comFunc.dump(dataTable))
    local result = true

    if dataTable == nil then
        Log.LogError(
            "$$$$ empty data table: "
                .. tostring(paraTab.Technology)
                .. ", "
                .. tostring(paraTab.TestName)
                .. ", "
                .. tostring(paraTab["subsubtestname"])
        )
        return false
    end

    for pKey, pValue in pairs(dataTable) do
        local testName = tostring(paraTab.Technology)
        local subTestName = tostring(paraTab.TestName)
        local subSubTestName = paraTab["subsubtestname"]
        local testNameSuffix = paraTab.testNameSuffix and tostring(paraTab.testNameSuffix) or ""
        local recordType = Parser.ParametricRecord
        -- Fetch limit
        local limit = Parser.fetchLimit(paraTab, pKey)
        subTestName = subSubTestName and tostring(subSubTestName) .. testNameSuffix or subTestName
        subSubTestName = tostring(pKey)

        if
            limit ~= nil
            and limit.upperLimit ~= nil
            and limit.lowerLimit ~= nil
            and type(limit.upperLimit) ~= type(limit.lowerLimit)
        then
            error("INVALID LIMIT DEFINITION")
        end

        if comFunc.hasKey(AttributeTable["Attributes"]["SOC"], pKey) then
            print("pKey:" .. pKey)
            if paraTab.Input ~= nil and pKey == "CFG" then
                subSubTestName = "serialNumber"
                pValue = paraTab.Input .. "_" .. pValue
            end
            recordType = Parser.AttributeRecord
        end

        if recordType == Parser.AttributeRecord then
            DataReporting.submit(DataReporting.createAttribute(subSubTestName, tostring(pValue)))
        elseif recordType == Parser.ParametricRecord then
            Record.createParametricRecord(tonumber(pValue), testName, subTestName, subSubTestName, limit)
        else
            error("invalid record type, should be a number:" .. tostring(recordType))
        end
    end
    return result
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0066:, Version: v0.1, Type:Inner]
Name: Parser.fetchLimit
Function description: [v0.1] fetch limits for specific test names
Input :Table(paraTab)
Output : table(limit table for specified test names)
Mark: (Unused) 
-----------------------------------------------------------------------------------]]
function Parser.fetchLimit(paraTab, parseKey)
    local rtosTempArray = { "_tMAX", "_tMIN", "Dtemp", "Stemp" }
    if string.sub(paraTab.Commands, 0, 6) == "sc run" then
        if comFunc.hasVal(rtosTempArray, string.sub(parseKey, -5, -1)) then
            return paraTab.limit["rtosTempLimit"]
        end
    end

    if parseKey == "SOC_MAX_TEMPERATURE" then
        return paraTab.limit["rbmTempLimit"]
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0043:, Version: v0.1, Type:Common]
Name: Parser.parseNumberWithIndex(paraTab)
Function description: [v0.1] Function to change vaule to hex and sub hex data. 
Input :  Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]
function Parser.parseNumberWithIndex(paraTab)
    helper.flowLogStart(paraTab)
    local inputValue = paraTab.Input -- 0x84
    local index = paraTab.Index -- 7
    local endindex = paraTab.endIndex
    local ret = ""
    local failureMsg = ""
    local resultFlag = false
    if paraTab.pattern then
        inputValue = string.match(inputValue, paraTab.pattern)
        Log.LogInfo("inputValue >>>>>: ", inputValue)
    end    
    -- use inner function
    if endindex then
        ret = comFunc.hexToBinary(inputValue, index, endindex)
        Log.LogInfo("ret1 >>>>>: ", ret)
    else
        ret = comFunc.hexToBinary(inputValue, index)
        Log.LogInfo("ret2 >>>>>: ", ret)
    end

    if #ret == 0 then 
        failureMsg = "sub ret error" 
    else
        resultFlag = true
    end

    if paraTab.tointeger and ret then
        ret = tonumber(ret)
    end

    if paraTab.attribute then
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, tostring(ret)))
    end

    helper.flowLogFinish(resultFlag, paraTab, ret, failureMsg)
    return ret
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0067:, Version: v0.1, Type:Inner]
Name: Parser.compareValueWithOpreation
Function description: [v0.1] compare value with opreation
Input :Table(paraTab)
Output : N/A
Mark: (Unused) 
-----------------------------------------------------------------------------------]]
function Parser.compareValueWithOpreation(paraTab)
    helper.flowLogStart(paraTab)
    local value1 = paraTab.value1 or "0"
    local value2 = paraTab.value2 or "0"
    local value3 = paraTab.value3 or "0"
    local value4 = paraTab.value4 or "0"
    Log.LogInfo("value1 >>>>>: ", value1)
    Log.LogInfo("value2 >>>>>: ", value2)
    Log.LogInfo("value3 >>>>>: ", value3)
    Log.LogInfo("value4 >>>>>: ", value4)
    local opreationType = paraTab.opreationType
    local result = false
    local failureMsg = ""
    if opreationType == "ACC" then
        local ret = tonumber(tonumber(value1, 2) | tonumber(value2, 2))
        local memSize = value3
        Log.LogInfo("ret1 >>>>>: ", tostring(ret))
        ret = comFunc.byteToBin(ret)
        Log.LogInfo("ret2 >>>>>: ", tostring(ret))
        local times = Parser.compareTimesWithPattern(ret, "1")
        if memSize == "12GB" then
            if times == 1 then
                result = true
            else
                failureMsg = "ACC compare error"
            end
        elseif memSize == "16GB" then
            if times == 0 then
                result = true
            else
                failureMsg = "ACC compare error"
            end
        else
            failureMsg = "memory Size error"
        end
    elseif opreationType == "DISP" then
        if value1 == "0" and value2 == "0" then
            result = true
        else
            failureMsg = "DISP value1 and value2 must be 0"
        end
    elseif opreationType == "ATC" then
        if value1 == "1" then
            local values = value2 .. value3 .. value4
            local times1 = Parser.compareTimesWithPattern(values, "0")
            local times2 = Parser.compareTimesWithPattern(values, "1")
            if times1 == 1 and times2 == 2 then
                result = true
            else
                failureMsg = "ATC compare error"
            end
        elseif value1 == "0" then
            if value2 == "1" and value3 == "1" and value4 == "1" then
                result = true
            else
                failureMsg = "ATC compare error"
            end
        else
            failureMsg = "value1 not is 1 or 0"
        end
    end
    if result then
        helper.flowLogFinish(result, paraTab)
    else
        helper.flowLogFinish(result, paraTab, nil, failureMsg)
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0068:, Version: v0.1, Type:Inner]
Name: Parser.compareTimesWithPattern
Function description: [v0.1] Calculate how many matching values there are
Input :string
Output : number
Mark: (Unused) 
-----------------------------------------------------------------------------------]]
function Parser.compareTimesWithPattern(result, pattern)
    local matchs = string.gmatch(result, pattern)
    local times = 0
    for i in matchs do
        if i and #i > 0 then
            times = times + 1
        end
    end
    return times
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0044:, Version: v0.1, Type:DFU]
Name: Parser.parseInfo(paraTab)
Function description: [v0.1] Function to gmatch hex data and upload to attribute. 
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function Parser.parseInfo(paraTab)
    helper.flowLogStart(paraTab)
    local value = paraTab.Input
    local itemName = paraTab.Name
    local pattern = paraTab.pattern
    local attributepattern = paraTab.attributePattern
    local attributecontrollername = paraTab.attributeControllerName
    local attributediename = paraTab.attributeDieName
    local bittable = comFunc.splitString(paraTab.bit,";")
    Log.LogInfo("bittable >>>>>: ", comFunc.dump(bittable))
    local iterator = string.gmatch(value, pattern)
    local failureMsg = "Get info fail"
    local attributeName = nil
    local attributeValue = nil 
    local result = nil
    local resultFlag = false
    local count = 0
    local isFCEKey = paraTab.isFCEKey
   
    -- MSP 0 CH 0 Die 0: AD 0E 04 0A 33 17 12 22 12 09 17 34 51 51 4A 38 
    -- MSP 0 CH 0 Die 1: AD 0E 04 0A 33 19 12 22 12 09 17 34 51 51 4A 38 
    -- MSP 0 CH 0 Die 2: AD 0E 04 0A 33 1B 12 22 12 09 17 34 51 51 4A 38 
    -- MSP 0 CH 0 Die 3: AD 0E 04 0A 33 1E 12 22 12 09 17 34 51 51 4A 38 
    -- MSP 0 CH 1 Die 0: AD 0E 04 14 41 12 12 1C 12 09 17 34 51 51 4A 38 
    -- MSP 0 CH 1 Die 1: AD 0E 04 0D 20 0F 12 28 12 09 17 34 51 51 4A 38 
    -- MSP 0 CH 1 Die 2: AD 0E 04 0D 20 10 12 28 12 09 17 34 51 51 4A 38 
    -- MSP 0 CH 1 Die 3: AD 0E 04 0D 20 11 12 28 12 09 17 34 51 51 4A 38 

    -- FCE0 = 0x0000C2000B287EAD
    -- FCE1 = 0x0000C2000B287EAD

    if #bittable <= 1 then
        helper.reportFailure("bittable miss error")
    end

    for key in iterator do
        resultFlag = true
        failureMsg = nil
        key = itemName .. key
        Log.LogInfo("key >>>>>: ", key)
        local attributeName = string.sub(string.gsub(key," ","_"), 1, bittable[1]) --NANDUID_MSP0_CH0_Die0 / NAND_UID_MSP0_CH0_Die_0
        Log.LogInfo("bittable >>>>>: ", bittable[1])
        if isFCEKey == "YES" then
            attributeName = string.sub(attributeName, 1, -2) .. "_".. string.sub(attributeName, -1)
        end
        Log.LogInfo("attributeName >>>>>: ", attributeName)
        local attributeValue = string.sub(key, bittable[1] + bittable[2], #key)
        Log.LogInfo("attributeValue >>>>>: ", attributeValue)
        DataReporting.submit(DataReporting.createAttribute(attributeName, attributeValue))
        count = count + 1 
        result = key 
    end

    if attributecontrollername and attributediename and attributepattern then
        -- local controller_count = tostring(string.match(result, attributepattern)+1)
        Log.LogInfo("count >>>>>: ", count)
        DataReporting.submit(DataReporting.createAttribute(attributecontrollername,
                            tostring(string.match(result, attributepattern)+1)))
        DataReporting.submit(DataReporting.createAttribute(attributediename, tostring(count)))
    end

    helper.flowLogFinish(resultFlag, paraTab, nil, failureMsg)
    return count
end


function Parser.parseFCE(paraTab)
    helper.flowLogStart(paraTab)
    local ret = paraTab.Input
    local parseKey = paraTab.parseKey
    local attribute = paraTab.attribute
    local pattern = paraTab.pattern
    local matchs = string.gmatch(ret, pattern)
    local resultFlag = false
    local failureMsg = "Get info fail"
    for nand_num, nand_value in matchs do
        if nand_num and nand_value then
            resultFlag = true
            failureMsg = nil
            local attributeName = attribute .."_".. tostring(nand_num)
            DataReporting.submit(DataReporting.createAttribute(attributeName, tostring(nand_value)))
        end
    end
    helper.flowLogFinish(resultFlag, paraTab, nil, failureMsg)
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0045:, Version: v0.1, Type:DFU]
Name: Parser.nandParse(paraTab)
Function description: [v0.1] Function to Match one or more values with the input string, and then return the sum of those values.
Input : Table(paraTab)
Output : string(sfc_url)
-----------------------------------------------------------------------------------]]
function Parser.nandParse(paraTab)
    helper.flowLogStart(paraTab)
    local input = paraTab.Input
    local pattern = paraTab.pattern
    local offset = paraTab.offset
    local tableValues = {}
    local segmentation1 = paraTab.segmentation1 or "+"
    local segmentation2 = paraTab.segmentation2 or "&"
    local nand_pattern = paraTab.nand_pattern

    if pattern then
        value = string.match(input, pattern)
        Log.LogInfo("value input >>>>>: ", value)
        if value then
            if offset then
                value = string.sub(value, (tonumber(offset) - 1) * 8 + 1, tonumber(offset) * 8)
                Log.LogInfo("value startString >>>>>: ", value)
            end
            value = tonumber("0x" .. value)
            Log.LogInfo("value >>>>>: ", value)
        end
    elseif not pattern then
        sum = 0
        local values = comFunc.splitString(paraTab.values, segmentation1)  --2063&31 + 2063&30 + 2063&25

        for _, v in ipairs(values) do
            local arr = comFunc.splitString(v, segmentation2)   --2063 & 32
            local id = arr[1]
            local offset = tonumber(arr[2])

            local handle_pattern = string.gsub(nand_pattern, "798", id)
            local matchs = string.match(input, handle_pattern)  --"\\s+" .. id .. "\\s+[0-9]+\\s+([0-9A-F]+)"
            table.insert(tableValues,matchs)

            if #tableValues > 0 and #tableValues[1] > 0 then
                local value = tableValues[1]
                if (tonumber(offset) ~= nil) then
                    value = string.sub(value, (offset - 1) * 8 + 1, offset * 8)
                end
                value = tonumber("0x" .. value)
                sum = sum + value
                Log.LogInfo("sum >>>>>: ", sum)
            end
        end
        
        return helper.flowLogFinish(true, paraTab, sum)
    end


    if pattern and string.find(paraTab.pattern, "1008") then --- if 1005 value=<2, print 1008 value pass,if 1005 value >2, set 1008 limit to [0, 800]
        local value_1005 = string.match(input, string.gsub(pattern, "1008", "1005"))
        Log.LogInfo("value_1005 >>>>>: ", value_1005)
        if value_1005 then
           value_1005 = tonumber("0x" .. value_1005)
        else
           helper.reportFailure("nandparse miss match")  
        end

        local limit = nil
        if value_1005 > 2 then
            limit = {
                ["relaxedLowerLimit"] = nil,
                ["lowerLimit"] = 0,
                ["upperLimit"] = 800,
                ["relaxedUpperLimit"] = nil,
                ["units"] = nil,
            }
        end
        
        helper.flowLogFinish(true, paraTab, value, nil, paraTab.subsubtestname, limit)
        return value
    end

    Log.LogInfo("value after >>>>>: ", value)

    if value then
        helper.flowLogFinish(true, paraTab, value)
    else    
        helper.flowLogFinish(false, paraTab, nil, "nand Parse info fail")   
    end

    return value
end

return Parser
