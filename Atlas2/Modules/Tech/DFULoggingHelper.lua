-------------------------------------------------------------------
----***************************************************************
----DFULoggingHelper Action Functions
----Created at: 11/01/2021
----Author: Jayson.Ye @Microtest
----***************************************************************
-------------------------------------------------------------------
local SMTLoggingHelper = require("Tech/SMTLoggingHelper")

local helper = {}
helper.DEFAULT_FAIL_RESULT = "--FAIL--"

function helper.logTestStartInfo(params, subsubtestname)
    local testname = params.Technology
    local subtestname = params.TestName
    local subsubtestnameToHornor = subsubtestname and subsubtestname or params.AdditionalParameters.subsubtestname
    SMTLoggingHelper.LogFlowDebug(string.format("==Test: %s", testname))
    SMTLoggingHelper.LogFlowDebug(string.format("==SubTest: %s", subtestname))
    SMTLoggingHelper.LogFlowDebug(string.format("==SubSubTest: %s", subsubtestnameToHornor))
end

function helper.logTestAction(value, params, msg, subsubtestname, limit)
    if type(value) == "boolean" then
        if value then
            value = "--PASS--NOPDCA"
        else
            local failureMsg = "logTestAction function can not use to creat fail record."
            SMTLoggingHelper.createRecord(false, params, msg, subsubtestname, limit, value)
            SMTLoggingHelper.LogError(failureMsg)
        end
    end
    if msg and subsubtestname and limit then
        SMTLoggingHelper.logTestAction(true, params, msg, subsubtestname, limit, value)
    else
        SMTLoggingHelper.logTestAction(true, params, nil, nil, nil, value)
    end
end

return helper
