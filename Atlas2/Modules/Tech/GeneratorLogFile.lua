-------------------------------------------------------------------
----***************************************************************
----   LogFormatGenerator for convert device.log to flow.log and pivot.csv
----   Author: Apple & USISX ATESW Callon, Katherine
----***************************************************************
-------------------------------------------------------------------
local Helper = require("Tech/SMTLoggingHelper")
local CommonFunc = require("Tech/CommonFunc")

local generatorLogFile = {}

-- @ Content Prefix/Suffix
local TEST_NAME_PREFIX = "\n==Test: "
local TEST_RESULT_PREFIX = ""
local RECORD_PREFIX = ""
local FIXTURE_CMD_PREFIX = "[rpc_client]"
local FIXTURE_RESP_PREFIX = "[result]"
local DUT_CMD_PREFIX = "cmd-send: "
local DUT_RESP_PREFIX = ""
local FLOW_DEBUG_PREFIX = ""

local RECORD_SUFFIX = ""
local FIXTURE_CMD_SUFFIX = ""
local FIXTURE_RESP_SUFFIX = ""
local DUT_CMD_SUFFIX = ""
local DUT_RESP_SUFFIX = ""
local FLOW_DEBUG_SUFFIX = ""

local TEST_SEPARATOR = "\n"

-- @ Data Format

local SUBTEST_NAME_CONNECTOR = string.format("\n==SubTest: ", "")
local SUBSUBTEST_NAME_CONNECTOR = string.format("\n==SubSubTest: ", "")

-- @ Content Indentation
local TEST_START_INDENTATION = 4
local TEST_RESULT_INDENTATION = 4
local RECORD_INDENTATION = 2
local FIXTURE_CMD_INDENTATION = 4
local FIXTURE_RESP_INDENTATION = 4
local DUT_CMD_INDENTATION = 2
local DUT_RESP_INDENTATION = 2
local FLOW_DEBUG_INDENTATION = 2

local PREFIX_LEN = 1

-- @ Pattern
local __record_pattern =
    "([%w%/:%.%s]+) category.*%[%%record%%%]%s+%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]%s+lower:%s+([%S%s]+)%s+higher:%s+([%S%s]+)%s+value:%s+([%S%s]+)%s+unit:%s+([%S%s]+)%s+result:%s+([%S%s]+)%s+failMsg:%s([%S%s]+)"
local __record_pattern_abnormal =
    "([%w%/:%.%s]+) category.*%[%%record%%%]%s+%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]%s+lower:%s+([%S%s]+)%s+higher:%s+([%S%s]+)%s+value:%s+([%S%s]+)%s+..."
local __test_start_pattern = "([%w%/:%.%s]+) category.*%[TEST START%]%s?%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]"
local __test_pass_pattern = "([%w%/:%.%s]+) category.*%[TEST PASSED%]%s?%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]"
local __test_fail_pattern = "([%w%/:%.%s]+) category.*%[TEST FAILED%]%s?%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]"
local __fixture_start_pattern =
    "([%w%/:%.%s]+) category.*%[%%fixture cmd%%%]%s+method:%s+([%S%s]+)%s+args:%s+([%S%s]+)%s+timeout:%s+([%S%s]+)"
local __fixture_start_pattern_abnormal =
    "([%w%/:%.%s]+) category.*%[%%fixture cmd%%%]%s+method:%s+([%S%s]+)%s+args:%s+([%S%s]+)"
local __fixture_finish_pattern = "([%w%/:%.%s]+) category.*%[%%fixture response%%%]%s+([%S%s]+)"
local __dut_cmd_start_pattern = "([%w%/:%.%s]+) category.*%[%%%%dut cmd%%%%%]([%S%s]+)"
local __dut_cmd_finish_pattern = "([%w%/:%.%s]+) category.*%[%%%%dut response%%%%%]([%S%s]+)"
local __dut_cmd_finish_more_pattern = "([%w%/:%.%s]+) category.*%<default%>%s+([%S%s]+)"
local __flow_debug_pattern = "([%w%/:%.%s]+) category.*%[%%%%flow debug%%%%%]%s+([%S%s]+)"
local __flow_debug_more_pattern = "([%w%/:%.%s]+) category.*%<default%>%s+([%S%s]+)"

local _dut_resp_start = false
local _dut_flow_debug = false

local pivotDict = {}
local flowLog = {}
local pivotHeader = {
    "slot", "testname", "subtestname", "subsubtestname", "unit", "lower", "higher", "timestamp", "duration", "result",
    "value", "failMsg"
}

-- ! @brief calculate the different value with to time string
-- ! @details change the time string format and get the differnt value.
-- ! @param preTimeStr, postTimeStr
-- ! @return different time value
local function timeStrDiff(preTimeStr, postTimeStr)
    assert(preTimeStr ~= nil, string.format("parameter1 %s is Null!", preTimeStr))
    assert(postTimeStr ~= nil, string.format("parameter2 %s is Null!", postTimeStr))

    local _, _, Y, M, D, h, m, s, ms = string.find(preTimeStr, "(%d+)/(%d+)/(%d+)%s*(%d+):(%d+):(%d+)%.(%d+)")
    local time1, ms1 = os.time({year = Y, month = M, day = D, hour = h, min = m, sec = s}), tonumber(ms)
    local _, _, Y2, M2, D2, h2, m2, s2, mse2 = string.find(postTimeStr, "(%d+)/(%d+)/(%d+)%s*(%d+):(%d+):(%d+)%.(%d+)")
    local time2, ms2 = os.time({year = Y2, month = M2, day = D2, hour = h2, min = m2, sec = s2}), tonumber(mse2)

    return (time2 - time1 + (ms2 - ms1) / 1000000)
end

local function trim(str)
    if not str then
        return ("=====>debug=========")
    else
        return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
    end
end

-- ! @brief change "," or ";" with " "
-- ! @param valueStr
-- ! @return trimed string
local function pivotTrim(valueStr)

    return string.gsub(valueStr, '[,;]', ' ')

end

-- ! @brief Parser info from device.log
-- ! @details parser info by pattern
-- ! @param filePath, source data file
-- ! @returns true/false
local function parserDeviceLog(filePath)
    assert(filePath ~= nil, "Error: file path is null!")

    local fileHandle = io.open(filePath)
    for line in fileHandle:lines() do
        if _dut_resp_start == true then
            if (string.find(line, "%[INFO%]") == nil) and (string.find(line, "%[DEBUG%]") == nil) then
                if string.find(line, "channel was stalled due to overlogging") == nil then
                    local timestamp, command = string.match(line, __dut_cmd_finish_more_pattern)
                    if command == nil then
                        goto continue
                    end
                    local dutMoreFormatStr = "%s%-" .. tostring(DUT_RESP_INDENTATION + PREFIX_LEN) .. "s %s"
                    local dutMoreStr = string.format(dutMoreFormatStr, CommonFunc.trim(timestamp), "",
                                                     CommonFunc.trim(command))
                    flowLog[#flowLog + 1] = dutMoreStr
                    goto continue
                end
            else
                _dut_resp_start = false
            end
        end

        if _dut_flow_debug == true then
            if (string.find(line, "%[INFO%]") == nil) and (string.find(line, "%[DEBUG%]") == nil) and
                (string.find(line, "DataChannel write:error:") == nil) then
                if string.find(line, "channel was stalled due to overlogging") == nil then
                    local timestamp, command = string.match(line, __flow_debug_more_pattern)
                    local flowDebugMoreFormatStr = "%s%-" .. tostring(FLOW_DEBUG_INDENTATION + PREFIX_LEN) .. "s %s"
                    local flowDebugMoreStr = string.format(flowDebugMoreFormatStr, CommonFunc.trim(timestamp), "",
                                                           CommonFunc.trim(command))
                    flowLog[#flowLog + 1] = flowDebugMoreStr
                    goto continue
                end
            else
                _dut_flow_debug = false
            end
        end

        if _dut_resp_start == false and _dut_flow_debug == false and string.find(line, "SMTLoggingHelper.lua") then
            if string.find(line, "%[%%record%%%]") then
                local timestamp, testname, subtestname, subsubtestname, lower, higher, value, unit, result, message =
                    string.match(line, __record_pattern)
                if timestamp ~= nil then -- cause of some IMU([<IMU> <SensorData_Sovereign> <sensorACCELOutput>]) return super dictionary lead match fail and return nil
                    local oneLineTable = {
                        timestamp = timestamp,
                        testname = testname,
                        subtestname = subtestname,
                        subsubtestname = subsubtestname,
                        lower = lower,
                        higher = higher,
                        value = pivotTrim(value),
                        unit = unit,
                        result = result,
                        message = pivotTrim(message)
                    }
                    pivotDict[#pivotDict + 1] = oneLineTable

                    local recordFormatStr = "%s%-" .. tostring(RECORD_INDENTATION) .. "s%-" .. tostring(PREFIX_LEN) ..
                                                "s %-36s lower: %-5s higher: %-5s value: %-10s unit: %-5s msg: %s%s"
                    local recordStr = string.format(recordFormatStr, CommonFunc.trim(timestamp), "", RECORD_PREFIX,
                                                    subsubtestname, CommonFunc.trim(lower), CommonFunc.trim(higher),
                                                    CommonFunc.trim(value), CommonFunc.trim(unit),
                                                    CommonFunc.trim(message), RECORD_SUFFIX)
                    flowLog[#flowLog + 1] = recordStr
                else
                    local _
                    timestamp, _, _, subsubtestname, lower, higher, value =
                        string.match(line, __record_pattern_abnormal)
                    if timestamp ~= nil then
                        local recordFormatStr =
                            "%s%-" .. tostring(RECORD_INDENTATION) .. "s%-" .. tostring(PREFIX_LEN) ..
                                "s %-36s lower: %-5s higher: %-5s value: %-10s"
                        local recordStr = string.format(recordFormatStr, CommonFunc.trim(timestamp), "", RECORD_PREFIX,
                                                        subsubtestname, CommonFunc.trim(lower), CommonFunc.trim(higher),
                                                        CommonFunc.trim(value), RECORD_SUFFIX)
                        flowLog[#flowLog + 1] = recordStr
                    else
                        Helper.LogInfo("record abnormal Line:", line) -- Pattern can't match
                    end
                end

            elseif string.find(line, "%[TEST START%]") then
                local timestamp, testname, subtestname, subsubtestname = string.match(line, __test_start_pattern)
                if timestamp ~= nil then
                    local startFormatStr = "\n%s%s%-" ..tostring(TEST_START_INDENTATION) .. "s%s%s%s%s%s%s"
                    local startStr = string.format(startFormatStr, TEST_SEPARATOR, timestamp, "", TEST_NAME_PREFIX,
                                                   testname, SUBTEST_NAME_CONNECTOR, subtestname,
                                                   SUBSUBTEST_NAME_CONNECTOR, subsubtestname)
                    flowLog[#flowLog + 1] = startStr
                else
                    Helper.LogInfo("TEST START abnormal Line:", line)
                end

            elseif string.find(line, "%[TEST PASSED%]") then
                local timestamp, _, _, _ = string.match(line, __test_pass_pattern)
                if timestamp ~= nil then
                    local passFormatStr = "%s%-" .. tostring(TEST_RESULT_INDENTATION) .. "s%sPASS"
                    local passStr = string.format(passFormatStr, timestamp, "", TEST_RESULT_PREFIX)
                    flowLog[#flowLog + 1] = passStr
                else
                    Helper.LogInfo("TEST PASSED abnormal Line:", line)
                end

            elseif string.find(line, "%[TEST FAILED%]") then
                local timestamp, _, _, _ = string.match(line, __test_fail_pattern)
                if timestamp ~= nil then
                    local failFormatStr = "%s%-" .. tostring(TEST_RESULT_INDENTATION) .. "s%sFAIL"
                    local failStr = string.format(failFormatStr, timestamp, "", TEST_RESULT_PREFIX)
                    flowLog[#flowLog + 1] = failStr
                else
                    Helper.LogInfo("TEST FAILED abnormal Line:", line)
                end

            elseif string.find(line, "%[%%fixture cmd%%%]") then
                local timestamp, method, args, timeout = string.match(line, __fixture_start_pattern)
                if timestamp ~= nil then
                    local fixStartFormatStr = "%s%-" .. tostring(FIXTURE_CMD_INDENTATION) .. "s%-" ..
                                                  tostring(PREFIX_LEN) .. "s method: %s, args: %s, timeout: %s%s"
                    local fixStartStr = string.format(fixStartFormatStr, CommonFunc.trim(timestamp), "",
                                                      FIXTURE_CMD_PREFIX, CommonFunc.trim(method),
                                                      CommonFunc.trim(args), CommonFunc.trim(timeout),
                                                      FIXTURE_CMD_SUFFIX)
                    flowLog[#flowLog + 1] = fixStartStr
                else
                    timestamp = string.match(line, __fixture_start_pattern_abnormal)
                    if timestamp ~= nil then
                        local fixStartFormatStr = "%s%-" .. tostring(FIXTURE_CMD_INDENTATION) .. "s%-" ..
                                                      tostring(PREFIX_LEN) .. "s method: %s, args: %s, %s"
                        local fixStartStr = string.format(fixStartFormatStr, CommonFunc.trim(timestamp), "",
                                                          FIXTURE_CMD_PREFIX, CommonFunc.trim(method),
                                                          CommonFunc.trim(args), FIXTURE_CMD_SUFFIX)
                        flowLog[#flowLog + 1] = fixStartStr
                    else
                        Helper.LogInfo("fixture cmd abnormal Line:", line)
                    end
                end

            elseif string.find(line, "%[%%fixture response%%%]") then
                local timestamp, response = string.match(line, __fixture_finish_pattern)
                if timestamp ~= nil then
                    local fixFinishFormatStr = "%s%-" .. tostring(FIXTURE_RESP_INDENTATION) .. "s%-" ..
                                                   tostring(PREFIX_LEN) .. "s %s%s"
                    local fixFinishStr = string.format(fixFinishFormatStr, CommonFunc.trim(timestamp), "",
                                                       FIXTURE_RESP_PREFIX, CommonFunc.trim(response),
                                                       FIXTURE_RESP_SUFFIX)
                    flowLog[#flowLog + 1] = fixFinishStr
                else
                    Helper.LogInfo("fixture response abnormal Line:", line)
                end

            elseif string.find(line, "%[%%%%dut cmd%%%%%]") then
                local timestamp, command = string.match(line, __dut_cmd_start_pattern)
                if timestamp ~= nil then
                    local dutStartFormatStr =
                        "%s%-" .. tostring(DUT_CMD_INDENTATION) .. "s%-" .. tostring(PREFIX_LEN) .. "s %s%s"
                    local dutStartStr = string.format(dutStartFormatStr, CommonFunc.trim(timestamp), "", DUT_CMD_PREFIX,
                                                      trim(command), DUT_CMD_SUFFIX)
                    flowLog[#flowLog + 1] = dutStartStr
                else
                    Helper.LogInfo("dut cmd abnormal Line:", line)
                end

            elseif string.find(line, "%[%%%%dut response%%%%%]") then
                _dut_resp_start = true
                local timestamp, response = string.match(line, __dut_cmd_finish_pattern)
                if timestamp ~= nil then
                    local dutFinishFormatStr =
                        "%s%-" .. tostring(DUT_RESP_INDENTATION) .. "s%-" .. tostring(PREFIX_LEN) .. "s %s%s"
                    local dutFinishStr = string.format(dutFinishFormatStr, CommonFunc.trim(timestamp), "",
                                                       DUT_RESP_PREFIX, trim(response), DUT_RESP_SUFFIX)
                    flowLog[#flowLog + 1] = dutFinishStr
                else
                    Helper.LogInfo("dut response abnormal Line:", line)
                end

            elseif string.find(line, "%s+%[%%%%flow debug%%%%%]%s+") then
                _dut_flow_debug = true
                local timestamp, response = string.match(line, __flow_debug_pattern)
                if timestamp ~= nil then
                    local flowDebugFormatStr = "%s%-" .. tostring(FLOW_DEBUG_INDENTATION) .. "s%-" ..
                                                   tostring(PREFIX_LEN) .. "s %s%s"
                    local flowDebugStr = string.format(flowDebugFormatStr, CommonFunc.trim(timestamp), "",
                                                       FLOW_DEBUG_PREFIX, CommonFunc.trim(response), FLOW_DEBUG_SUFFIX)
                    flowLog[#flowLog + 1] = flowDebugStr
                else
                    Helper.LogInfo("flow debug abnormal Line:", line)
                end
            end
        end
        ::continue::
    end
    fileHandle:close()

    if flowLog ~= nil and pivotDict ~= nil then
        return true
    else
        return false
    end

end

-- ! @brief Generate pivot log by slot
-- ! @details write record message into pivot.csv
-- ! @param pivotFilePath
-- ! @returns N/A
local function pivotExport(pivotFilePath, slotID)
    assert(pivotFilePath ~= nil, "Error: pivot.csv Path is null!")
    local csvFile = io.open(pivotFilePath, "a+")
    if csvFile ~= nil then
        csvFile:write(table.concat(pivotHeader, ", ") .. "\n")
        -- local deviceName = "slot" .. slotID
        for i = 1, #pivotDict do
            local presentLine = pivotDict[i]
            local duration = "N/A"
            if i > 1 then
                local lastLine = pivotDict[i - 1]
                duration = tostring(timeStrDiff(lastLine.timestamp, presentLine.timestamp))
            end
            csvFile:write(slotID .. "," .. presentLine.testname .. "," .. presentLine.subtestname .. "," ..
                              presentLine.subsubtestname .. "," .. presentLine.unit .. "," .. presentLine.lower .. "," ..
                              presentLine.higher .. "," .. presentLine.timestamp .. "," .. duration .. "," ..
                              presentLine.result .. "," .. presentLine.value .. "," .. presentLine.message .. "\n")
        end
        csvFile:close()
    else
        Helper.LogInfo("Error: open pivot file fail!")
        csvFile:close()
    end
end

-- ! @brief Generate flow log by slot
-- ! @details write the content into flow.log
-- ! @param flowLogFilePath
-- ! @returns N/A
local function flowLogExport(flowLogFilePath)
    assert(flowLogFilePath ~= nil, "Error: flow.log Path is null!")

    local logFile = io.open(flowLogFilePath, "a+")
    if logFile ~= nil then
        for i = 1, #flowLog do
            logFile:write(flowLog[i] .. "\n")
        end
        logFile:close()
    else
        Helper.LogInfo("Error: open pivot file fail!")
        logFile:close()
    end
end

-- ! @brief generate a flow.log and pivot.csv, and this function call by CSV
-- ! @details get decice.log file path and generate the flow.log, pivot.csv
-- ! @param N/A
-- ! @returns pass: pass or fail
function generatorLogFile.generateFlowLog(userLogPath, slot)
    -- @ get file path
    local systemLogPath = string.gsub(userLogPath, "user", "system")
    assert(systemLogPath ~= nil, "Error: system logpath is null!")
    local deviceLogPath = systemLogPath .. "/device.log"
    local flowLogPath = userLogPath .. "/flow.log"
    local pivotPath = userLogPath .. "/pivot.csv"
    flowLog = {}
    pivotDict = {}

    local result = true
    local bRet, ret = xpcall(parserDeviceLog, debug.traceback, deviceLogPath)
    if bRet and ret then
        flowLogExport(flowLogPath)
        pivotExport(pivotPath, slot)
    else
        result = false
        error("Error: parser device.log fail, need to check!")
    end

    return result
end

return generatorLogFile

