local helper = require("Tech/SMTLoggingHelper")

local module = {}

local function getPlugin()
    if Device then
        local status, plugin = xpcall(Device.getPlugin, debug.traceback, "TimeUtility")
        if status then
            return plugin
        else
            return Atlas.loadPlugin("SMTCommonPlugin").createTimeUtility()
        end
    else
        return Atlas.loadPlugin("SMTCommonPlugin").createTimeUtility()
    end
end

module.__plugin = getPlugin()
function module.__delay(time_in_ms)
    --[[
        Sleep specified time duration, unit is millisecond
        :Input: duration in ms
        :AdditionalParameters: -
        :Commands: -
    ]]
    module.__plugin.delay(time_in_ms / 1000)
end

function module.delay(params)
    local duration = params.duration and tonumber(params.duration) or
                         params.getInput()
    if duration then
        module.__delay(duration)
        helper.createRecord(true, params)
    else
        local errMsg = "No valid duration set, should be either a number in Input \
                or a key-value pair (\"duration\": \"xxx\") in AdditionalParameters"
        helper.createRecord(false, params, errMsg)
        helper.reportFailure(errMsg)
    end
end

function module.__staggerDelay(time_in_ms)
    --[[
        Sleep specified time duration, unit is millisecond. Only one thread is allowed to sleep at one time
        :Input: duration in ms
        :AdditionalParameters: -
        :Commands: -
    ]]
    local mutex = require("mutex")
    local _mutex_plugin = Device.getPlugin("MutexPlugin")
    local id = "identifier-for-stagger-delay"
    mutex.runWithLock(_mutex_plugin, id, module.__delay, time_in_ms)
end

function module.staggerDelay(params)
    local duration = params.AdditionalParameters.duration and tonumber(params.AdditionalParameters.duration) or
                         params.getInput()
    if duration then
        module.__staggerDelay(duration)
        helper.createRecord(true, params)
    else
        local errMsg = "No valid duration set, should be either a number in Input \
                or a key-value pair (\"duration\": \"xxx\") in AdditionalParameters"
        helper.createRecord(false, params, errMsg)
        helper.reportFailure(errMsg)
    end
end

return module
