-------------------------------------------------------------------
----***************************************************************
----Kis USB Functions
----Created at: 06/07/2023
----Author: JW @PRM
----***************************************************************
-------------------------------------------------------------------

local KisUSB = {}
local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local DFUCommon = require("Tech/DFUCommon")
local Record = require("Tech/record")
local helper = require("Tech/SMTLoggingHelper")
local defaultFailResult = "FAIL"

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0062, Version: v0.1, Type:Inner]
Name: KisUSB.getKisUSBLocationID
Function description: [v0.1]Function to get KIS USB locationID
Input : string
Output : locationID(string)
Mark: (Unused)
-----------------------------------------------------------------------------------]]
function KisUSB.getKisUSBLocationID(slot_num, flagIndex, pattern, timeout)
    local Regex = Device.getPlugin("Regex")
    local locationID = ''
    local startTime = os.time()
    if #pattern == 0 then
        pattern = "Debug USB:[\\s\\S]+?Location ID: 0x(\\S+) /"
    end
    repeat
        local data = DFUCommon.runShellCmd("system_profiler SPUSBDataType")['output']

        Log.LogInfo('$$$$ data --> ' .. data)
        Log.LogInfo('$$$$ pattern --> ' .. pattern)

        local matchs = Regex.groups(data, pattern, 1)
        Log.LogInfo('$$$$ getLocationID matchs')
        Log.LogInfo(comFunc.dump(matchs))
        if matchs and #matchs > 0 and #matchs[1] > 0 then
            for _, v in pairs(matchs) do
                if v and #v > 0 then
                    local result = v[1]
                    result = string.gsub(result, '0', '')
                    local chr = string.sub(result, flagIndex, flagIndex)
                    if tonumber(slot_num) == tonumber(chr) then
                        locationID = v[1]
                    end
                end
            end
        end
        if #locationID == 0 then
            comFunc.sleep(0.1)
        end
    until (#locationID > 0 or os.difftime(os.time(), startTime) >= timeout)
    return locationID
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0042, Version: v0.1, Type:Common]
Name: KisUSB.readPortData(paraTab)
Function description: [v0.1]Function to read KIS USB or uart data
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function  KisUSB.readPortData(paraTab)
    helper.flowLogStart(paraTab)
    local timeout = tonumber(paraTab.Timeout)
    local dut = Device.getPlugin(paraTab.dutPluginName)
    local flag = false
    local failureMessage = nil
    local timeUtility = Device.getPlugin("TimeUtility")

    -- confirm kis port is open
    if dut.isOpened() ~= 1 then
        local status, ret = xpcall(dut.open, debug.traceback, 3)
        if status then
            flag = true
            Log.LogInfo("$$$$ Open OK")
        else
            Log.LogInfo("$$$$ Open Fail")
            failureMessage = "Port Open failed"
        end
    else
        flag = true
    end

    -- clear buffer
    if flag then
        local startTime = os.time()
        local readNulldataTimes = 0
        repeat
            timeUtility.delay(0.03)
            local status, ret = xpcall(dut.read, debug.traceback, 1, '')
            if status and ret and #ret > 0 then
                Log.LogInfo("$$$$ read ret!!!")
            elseif status then
                Log.LogInfo("$$$$ read unkown data")
            else
                Log.LogInfo("$$$$ read null data")
                readNulldataTimes = readNulldataTimes +1
            end
        until (os.difftime(os.time(), startTime) >= timeout or readNulldataTimes >= 3)
        helper.flowLogFinish(true, paraTab)
    else
        helper.flowLogFinish(false, paraTab, "readPortData", failureMessage)
        helper.reportFailure(failureMessage)
    end
end

return KisUSB
