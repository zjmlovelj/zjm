local schoonerStationInfo = {}

------------------- Internal APIs
local registeredStationInfo = {}
function schoonerStationInfo.getRegisteredStationInfo()
    local localCopy = registeredStationInfo
    registeredStationInfo = nil
    return localCopy
end

local function assertSystemStillEditable()
    if not registeredStationInfo then
        local msg = "System has already started up. "
        msg = msg .. "Cannot register new station attributes."
        error(msg)
    end
end

------------------- Group APIs
function schoonerStationInfo.registerGroupFunctions(groupFunctionTable)
    assertSystemStillEditable()
    registeredStationInfo["groupFT"] = groupFunctionTable
end

function schoonerStationInfo.registerDeviceFunctions(deviceFunctionTable)
    assertSystemStillEditable()
    registeredStationInfo["deviceFT"] = deviceFunctionTable
end

-- allow user to control dag exit early for error/failure record
function schoonerStationInfo.endTestingOnFailureRecord()
    assertSystemStillEditable()
    registeredStationInfo["endTestingOnFailureRecord"] = true
end

function schoonerStationInfo.disableGroupScriptDebugPrint()
    assertSystemStillEditable()
    registeredStationInfo["disableGroupScriptDebugPrint"] = true
end

function schoonerStationInfo.setDetectionInterarrivalTimeout(interarrival)
    assertSystemStillEditable()
    schoonerStationInfo.setDetectionTimeout(interarrival, -1)
end

function schoonerStationInfo.setDetectionTimeout(interarrival, global)
    assertSystemStillEditable()
    if interarrival == nil or global == nil then
        error("Cannot set detection timeouts to nil")
    end
    registeredStationInfo["detectionTimeout"] = { interarrival, global }
end

--- Set number of times to loop for each unit detected
function schoonerStationInfo.setLoopCountPerDetection(loopsPerDetection)
    assertSystemStillEditable()
    registeredStationInfo["loopCountPerDetection"] = loopsPerDetection
end

--- Set a function to decide if the Group should exit
function schoonerStationInfo.setGroupShouldExitFunction(shouldExitFunction)
    assertSystemStillEditable()
    assert(type(shouldExitFunction) == 'function',
           'Group shouldExitFunction should be a function while got ' ..
           type(shouldExitFunction))
    registeredStationInfo["shouldExitFunction"] = shouldExitFunction
end

-- Set test scheduler thread pool limit.
function schoonerStationInfo.setThreadPoolLimit(limit)
    assertSystemStillEditable()
    if type(limit) ~= "number" or limit <= 0 then
        error("Pass a positive integer to set the thread limit.")
    end
    registeredStationInfo["schedulerThreads"] = limit
end

function schoonerStationInfo.readyForAutomatedHandling(
readyForAutomatedHandlingCallback)
    assertSystemStillEditable()
    registeredStationInfo["readyForAutomatedHandling"] =
    readyForAutomatedHandlingCallback
end

function schoonerStationInfo.automationFixtureControlCallbacks(
automationFixtureControlCallbacks)
    assertSystemStillEditable()
    registeredStationInfo["automationFixtureControlCallbacks"] =
    automationFixtureControlCallbacks
end

function schoonerStationInfo.saveDAG()
    assertSystemStillEditable()
    registeredStationInfo["saveDAG"] = true
end

-- This is an internal API only for testing.
-- Calling this API will fail the DUT test.
-- Do not use it on station.
function schoonerStationInfo.registerSamplingPlugin(plugin)
    assertSystemStillEditable()
    registeredStationInfo["samplingPluginFromUser"] = plugin
end

-- Set limit version string by callback
function schoonerStationInfo.overrideLimitVersion(setLimitVersionCallback)
    assertSystemStillEditable()
    assert(type(setLimitVersionCallback) == 'function',
           'Group setLimitVersionCallback should be a function while got ' ..
           type(setLimitVersionCallback))
    registeredStationInfo["limitVersionFunction"] = setLimitVersionCallback
end

return schoonerStationInfo
