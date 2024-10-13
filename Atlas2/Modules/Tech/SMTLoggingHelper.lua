local Log = require("Tech/logging")
local coverage = require("/coverage/coverage")
local record = require("Tech/record")

-- ! @brief logging helper for Hawkeye parsing
-- ! @brief 3 categories helper interfaces:
-- !     - LogFlowStart & LogFlowPass/Fail for marking test item start/finish
-- !     - LogFixtureControlStart & LogFixtureControlFinish for marking fixture actions
-- !     - LogDutCommStart & LogDutCommFinish for marking DutComm content
local helper = {}

helper.FLOW_START = "[TEST START][<%s> <%s> <%s>]"
helper.FLOW_PASS = "[TEST PASSED][<%s> <%s> <%s>]"
helper.FLOW_FAIL = "[TEST FAILED][<%s> <%s> <%s>]"
helper.FIXTURE_START = "[%%fixture cmd%%] method: %s    args: %s    timeout: %s"
helper.FIXTURE_STOP = "[%%fixture response%%] %s"
helper.DUT_COMMAND_START = "[%%dut cmd%%]"
helper.DUT_COMMAND_STOP = "[%%dut response%%]"
helper.RECORD =
    "[%%record%%]   [<%s> <%s> <%s>]   lower: %s   higher: %s  value: %s   unit: %s    result: %s   failMsg: %s"
helper.FLOW_DEBUG = "[%%flow debug%%]"

-- ! @brief get the limit value of ongoing test item
-- ! @details traverse 'coverage.lua' to obtain the limit value
-- ! @return v(table) traverse 'coverage.lua' to return the 'limits' table for the ongoing test item
local getLimits = function(subsubtestname)
    local limits = coverage.Production.limits
    for _, v in ipairs(limits) do
        if v.testname == Device.test and v.subtestname == Device.subtest and v.subsubtestname == subsubtestname then
            return v
        end
    end
end

-- ! @brief Lua Script API, logging technology item start
-- ! @brief logging format [Test Start][<TestName> <SubTestName> <SubSubTestName>]
-- ! @param params csv parameter table, will look for params.Technology, params.TestName, params.AdditionalParameters.subsubtestname
function helper.flowLogStart(params)
    Device.updateProgress(Device.test .. ", " .. Device.subtest .. ", " .. (params.subsubtestname or ""))
    Log.LogInfo(string.format(helper.FLOW_START, Device.test, Device.subtest, params.subsubtestname or ""))
end

-- ! @brief Lua Script API, logging technology item finish with pass result
-- ! @brief logging format [Test Pass][<TestName> <SubTestName> <SubSubTestName>]
-- ! @param params csv parameter table, will look for params.Technology, params.TestName, params.AdditionalParameters.subsubtestname
function helper.flowLogPass(subsubtestname)
    Log.LogInfo(string.format(helper.FLOW_PASS, Device.test, Device.subtest, subsubtestname))
end

-- ! @brief Lua Script API, logging technology item finish with fail result
-- ! @brief logging format [Test Fail][<TestName> <SubTestName> <SubSubTestName>]
-- ! @param params csv parameter table, will look for params.Technology, params.TestName, params.AdditionalParameters.subsubtestname
function helper.flowLogFail(subsubtestname)
    Log.LogInfo(string.format(helper.FLOW_FAIL, Device.test, Device.subtest, subsubtestname))
end

function helper.flowLogWrite(testResult, subsubtestname, lowerLimit, upperLimit, value, unit, msg)
    Log.LogInfo(string.format(helper.RECORD, Device.test, Device.subtest,
                          subsubtestname, tostring(lowerLimit), tostring(upperLimit),
                          value and tostring(value) or "", unit or "", (testResult == 2 or testResult == true) and "PASS" or "FAIL", msg or ""))
    if testResult == 2 or testResult == true then
        helper.flowLogPass(subsubtestname)
    else
        helper.flowLogFail(subsubtestname)
    end
end

function helper.flowLogFinish(result, params, value, msg, subsubtestname, limit)
    local lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, allowedList, unit
    local subsubtestnameToHornor = subsubtestname and subsubtestname or params.subsubtestname
    local record = params.record
    local testResult = true

    if type(result) ~= 'boolean' then
        error("result for should be boolean type, got ", type(result))
        return
    end

    if not subsubtestnameToHornor or not record then
        error("not result or subsubtestname or record for test item!!!")
        return
    end

    local limit = getLimits(subsubtestnameToHornor) or limit
    if limit ~= nil then
        lowerLimit = limit.lowerLimit
        upperLimit = limit.upperLimit
        relaxedLowerLimit = limit.relaxedLowerLimit
        relaxedUpperLimit = limit.relaxedUpperLimit
        unit = limit.units
        allowedList = limit.allowedList
        if allowedList then
            lowerLimit = ""
            upperLimit = ""
            for __,v in pairs(allowedList) do
                lowerLimit = lowerLimit .. v.."  "
                upperLimit = upperLimit .. v.."  "
            end
        end
        if value == nil then -- if limit not is nil and value is nil then value must is "No_Value"(string) or -9.999E+20(number)
            if allowedList then
                value = "No_Value"
            else
                value = -9.999E+20
            end
        end
    else
        lowerLimit = ""
        upperLimit = ""
        relaxedLowerLimit = ""
        relaxedUpperLimit = ""
        unit = ""
        allowedList = nil
    end

    if result == false then -- result is false, must be fail create record
        if limit ~= nil then
            testResult = DataReporting.submitRecord(value, Device.test, Device.subtest, subsubtestnameToHornor)
        else
            testResult = DataReporting.submitRecord(result, Device.test, Device.subtest, subsubtestnameToHornor)
        end
        helper.flowLogWrite(testResult, subsubtestnameToHornor, lowerLimit, upperLimit, unit, value, msg)
    elseif record == "true" then
        if allowedList ~= nil then -- value type is string, create record
            testResult = DataReporting.submitRecord(value, Device.test, Device.subtest, subsubtestnameToHornor)
        elseif allowedList == nil and value ~= nil and tonumber(value) ~= nil then -- value type is nubmer, create record
            testResult = DataReporting.submitRecord(tonumber(value), Device.test, Device.subtest, subsubtestnameToHornor)
        else -- vaule is nil, result is true, must be pass create record
            testResult = DataReporting.submitRecord(result, Device.test, Device.subtest, subsubtestnameToHornor)
        end
        helper.flowLogWrite(testResult, subsubtestnameToHornor, lowerLimit, upperLimit, value, unit, msg)
    else
        testResult = result
        if  value == nil or value == "" or string.gsub(value, " ", "") == "" then
            value = "--PASS--NOPDCA"
        end
        helper.flowLogWrite(testResult, subsubtestnameToHornor, lowerLimit, upperLimit, value, unit, msg)   
    end

    return testResult    
end

-- ! @brief Lua Script API, logging arbitrary content to be captured in flow log
-- ! @brief logging format[%%flow debug%%]
-- ! @param params csv parameter table, will look for params.Technology, params.TestName, params.AdditionalParameters.subsubtestname
function helper.flowLogDebug(...)
    Log.LogInfo(helper.FLOW_DEBUG, ...)
end

-- ! @brief Lua Script API, logging fixture action start
-- ! @brief logging format [%%fixture cmd%%]
function helper.LogFixtureControlStart(...)
    Log.LogInfo(string.format(helper.FIXTURE_START, table.unpack({...})))
end

-- ! @brief Lua Script API, logging fixture action done
-- ! @brief logging format [%%fixture response%%]
function helper.LogFixtureControlFinish(...)
    Log.LogInfo(string.format(helper.FIXTURE_STOP, table.unpack({...})))
end

-- ! @brief Lua Script API, logging dut command start
-- ! @brief logging format [%%dut cmd%%]
function helper.LogDutCommStart(...)
    Log.LogInfo(helper.DUT_COMMAND_START, ...)
end

-- ! @brief Lua Script API, logging dut command finish
-- ! @brief logging format [%%dut response%%]
function helper.LogDutCommFinish(...)
    Log.LogInfo(helper.DUT_COMMAND_STOP, ...)
end

-- ! @brief Lua Script API, logging info message function mapped to sequencer function Log.LogInfo()
-- ! @param args acceptable by Log.LogInfo()
function helper.LogInfo(...)
    Log.LogInfo(...)
end

-- ! @brief Lua Script API, logging debug message function mapped to sequencer function Log.LogDebug()
-- ! @param args acceptable by Log.LogDebug()
function helper.LogDebug(...)
    Log.LogDebug(...)
end

-- ! @brief Lua Script API, logging error message function mapped to sequencer function Log.LogError()
-- ! @param args acceptable by Log.LogError()
function helper.LogError(...)
    Log.LogError(...)
end

function helper.reportFailure(...)
    error(...)
end

-- ! @brief Lua Script API, a wrap function to helper logging record creation. It leverages record creation API
-- ! @param result test result value, can be numeric data/binary data/string type data
-- ! @param params  parameter table, params.Technology, params.testNameSuffix & params.TestName are required keys, params.AdditionalParameters.subsubtestname & params.limit are optional keys
-- ! @param msg failure message for the record, optional key
-- ! @param subsubtestname a string to be used to override the subsubtestname for the record, optional key
-- ! @param limit an optional key dictionary to override limit, contains keys: lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, units
-- ! @param value test result value, optional key, applicable when the insight result is binary type, but user wants to have string type value recorded in pivot log
function helper.createRecord(result, params, msg, subsubtestname, limit, value)
    local subsubtestnameToHornor = subsubtestname and subsubtestname or params.subsubtestname
    local lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, unit
    local testResult
    local limit = getLimits(subsubtestname) or limit
    if limit ~= nil then
        lowerLimit = limit.lowerLimit
        upperLimit = limit.upperLimit
        relaxedLowerLimit = limit.relaxedLowerLimit
        relaxedUpperLimit = limit.relaxedUpperLimit
        unit = limit.units
    else
        lowerLimit = ""
        upperLimit = ""
        relaxedLowerLimit = ""
        relaxedUpperLimit = ""
        unit = ""
    end

    if  value ~= nil and tonumber(value) ~= nil then
        testResult = DataReporting.submitRecord(tonumber(value), Device.test, Device.subtest, subsubtestnameToHornor)
    else
        testResult = DataReporting.submitRecord(result, Device.test, Device.subtest, subsubtestnameToHornor)
    end
    
    Log.LogInfo(string.format(helper.RECORD, Device.test, Device.subtest,
                              subsubtestnameToHornor, tostring(lowerLimit), tostring(upperLimit),
                              value and tostring(value) or "", unit or "", (testResult == 2 or testResult == true) and "PASS" or "FAIL", msg or ""))
    return testResult
end

-- ! @brief Lua Script API, a wrap function to helper logging parametric record creation. It leverages Matchbox createParametric API
-- ! @param value test result number, expect number type
-- ! @param testname string, testname for insight record
-- ! @param subtestname string, subtestname for insight record
-- ! @param subsubtestname string, subsubtestname for insight record
-- ! @param limit a dictionary to declair limits for insight record, should contains keys: lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, units
-- ! @param msg failure message for the record, optional key
function helper.createParametricRecord(result, testname, subtestname, subsubtestname, limit, msg)
    local testResult = record.createParametricRecord(result, testname, subtestname, subsubtestname, limit, msg)
    local lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, unit
    if not testResult then
        helper.__testResult = false
    end
    if limit ~= nil then
        lowerLimit = limit.lowerLimit
        upperLimit = limit.upperLimit
        relaxedLowerLimit = limit.relaxedLowerLimit
        relaxedUpperLimit = limit.relaxedUpperLimit
        unit = limit.units
    else
        lowerLimit = ""
        upperLimit = ""
        relaxedLowerLimit = ""
        relaxedUpperLimit = ""
        unit = ""
    end
    Log.LogInfo(string.format(helper.RECORD, testname, subtestname, subsubtestname, tostring(lowerLimit),
                              tostring(upperLimit), tostring(result), unit or "", testResult and "PASS" or "FAIL",
                              msg or ""))
    return testResult
end

return helper
