schooner = require "Schooner"

-- Initialize with user overrides
schooner.registerGroupFunctions(require "GroupFunctions")
schooner.registerDeviceFunctions(require "DeviceFunctions")

schooner.setGroupShouldExitFunction(function()
    return true
end)

schooner.overrideLimitVersion(function(...)
    -- local args = {...}
    -- local conditions = args[3]

    -- local stationInfo = Atlas.loadPlugin("StationInfo")
    -- local stationOverlayName = stationInfo.station_overlay()
    -- local testPlanVersion = string.match(stationOverlayName, "%ss%S[^_]+_([0-9.]+)")

    -- if not testPlanVersion then
    --     return nil
    -- else
    --     testPlanVersion = "TPv" .. string.gsub(testPlanVersion, "%.", "_")
    -- end

    -- local prefix_, suffix = string.match(testPlanVersion, "(TP)(.+)")
    -- local limitVersion = tostring(prefix_ .. "_" .. conditions["CPRV"] .. "_" .. suffix)

    -- return limitVersion
    return "0.0.1"
end)
