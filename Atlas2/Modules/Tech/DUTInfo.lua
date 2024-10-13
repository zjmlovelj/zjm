-------------------------------------------------------------------
----***************************************************************
----Dimension Action Functions
----Created at: 03/01/2021
----Author: Jayson.Ye/Roy.Fang @Microtest
----***************************************************************
-------------------------------------------------------------------
local DUTInfo = {}
local defaultFailResult = "FAIL"

local Log = require("Tech/logging")
local helper = require("Tech/SMTLoggingHelper")
local comFunc = require("Tech/CommonFunc")
local DFUCommon = require("Tech/DFUCommon")
local Common = require("Tech/Common")
local USBC = require("Tech/USBC")
local fileUtils = require("ALE/FileUtils")

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0030, Version: v0.1, Type:DFU]
Name: DUTInfo.CheckMLBType(paraTab)
Function description: [v0.1]Function to Check MLB Type with the input string or restore device log.
Input :  Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]
function DUTInfo.CheckMLBType(paraTab)
    helper.flowLogStart(paraTab)
    
    local ret = paraTab.Input
    if ret == nil then
        local device_log_path = comFunc.getRestoreDeviceLogPath()
        ret = comFunc.fileRead(device_log_path)
    end

    if #ret == 0 then
        helper.flowLogFinish(false, paraTab, ret, "miss inputValue or restore device log")
        helper.reportFailure("miss inputValue or restore device log")
    end

    local mlb_type = DFUCommon.checkValueInTable(paraTab.mlb_a, paraTab.mlb_b, ret) --check value in mlb_a or mlb_b

    if mlb_type == "Unset" then
        helper.flowLogFinish(false, paraTab, mlb_type, "mlb type miss match")
        helper.reportFailure("mlb type miss match")
    else
        helper.flowLogFinish(true, paraTab, mlb_type)    
    end    

    return mlb_type
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0032, Version: v0.1, Type:DFU]
Name: Common.UOPCheck(paraTab)
Function description: [v0.1]Function to get the memory size from the Input string and regex.
                            Return "0GB" if did not match any values with the Regex.
Input : Table(paraTab)
Output : string(xxGB)
-----------------------------------------------------------------------------------]]
function DUTInfo.getStorageSize(paraTab)
    helper.flowLogStart(paraTab)
    local logFile = Device.userDirectory .. "/" .. paraTab.logFile
    local inputValue = paraTab.Input
    local ret = ""

    if inputValue then
        Log.LogInfo("$$$$ getStorageSize from inputValue")
        ret = inputValue
    else
        Log.LogInfo("$$$$ getStorageSize from log")
        ret = string.format("%q",comFunc.fileRead(logFile))
    end
    local failureMsg = ""
    local divisor = 1
    local result = true
    local storageSize = '0GB'

    if paraTab.pattern then
        local pattern = paraTab.pattern
        ret = string.match(ret, pattern)
        if not ret then
            result = false
            failureMsg = 'match failed'
        end
    end

    if result and paraTab.attribute then

        local status, size = xpcall(Common.calValue, debug.traceback, { value = tonumber(ret), 
        scale = paraTab.scale, formula = paraTab.formula, calmode = paraTab.calmode, InnerCall = paraTab.InnerCall })
        Log.LogInfo("$$$getStorageSize$$$"..tostring(size))
        storageSize = string.format("%dGB", size)
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, storageSize))
        helper.flowLogFinish(true, paraTab, storageSize)
    else
        helper.flowLogFinish(false, paraTab, storageSize, 'storageSize Not match')
    end

    return storageSize
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0031, Version: v0.1, Type:DFU]
Name: EnterEnv.getByteLen(paraTab)
Function description: [v0.1]Function to get the Byte len with the Input value and compare.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function DUTInfo.getByteLen(paraTab)
    helper.flowLogStart(paraTab)
    local ret = paraTab.Input
    local byteLen = paraTab.ByteLen

    if ret == nil and byteLen == nil then
        helper.reportFailure("no input string")
    end

    ret = string.gsub(ret, '0x', '')
    ret = string.gsub(ret, ' ', '')
    Log.LogInfo("Byte: " .. ret .. '\n')

    local retLen = math.floor(#ret / 2)

    if tostring(retLen) == byteLen then
        helper.flowLogFinish(true, paraTab, retLen)
    else
        helper.flowLogFinish(false, paraTab, retLen, "Get Byte len fail")    
    end
    return retLen
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0093, Version: v0.1, Type:Common]
Name: DUTInfo.compareValueOfBinFileAtAddress(paraTab)
Function description: Function to compare the value of a binary file at an address 
Input : Table
Output : N/A
-----------------------------------------------------------------------------------]]

function DUTInfo.compareValueOfBinFileAtAddress(paraTab)
    helper.flowLogStart(paraTab)
    local compareValue = paraTab.Input
    local fileName = paraTab.fileName
    local address = paraTab.address
    local length = paraTab.length
    local byteFormat = paraTab.byteFormat
    local binFilePath = fileUtils.joinPaths(Device.userDirectory, fileName)
    local failureMsg = ""
    
    if address then
        address = tonumber(address)
    else
        address = 0
    end

    if length then
        length = tonumber(length)
    else
        length = #content
    end

    local value = USBC.bytesToHexStr(binFilePath, address, length, byteFormat)
    value = comFunc.trim(value)

    if string.upper(value) == compareValue then
        helper.flowLogFinish(true, paraTab)
    else
        failureMsg = "match error, [" .. value .. "] not compare [" .. compareValue .. "]"
        helper.flowLogFinish(false, paraTab, value, failureMsg)
    end
end



return DUTInfo
