local SOC = {}
local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local helper = require("Tech/SMTLoggingHelper")
local runShellCommand = Device.getPlugin("RunShellCommand")
local DFUCommon = require("Tech/DFUCommon")
local defaultFailResult = "FAIL"

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0041, Version: v0.1, Type:Common]
Name: SOC.addLogToInsight(paraTab)
Function description: [v0.1] Function to send test data package to insight.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function SOC.addLogToInsight(paraTab)
    helper.flowLogStart(paraTab)
    Log.LogInfo('adding user/ log folder to insight')
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local vendor = fixturePlugin.getVendor()
    local StationInfo = Device.getPlugin("StationInfo")
    local station_type = StationInfo.station_type()
    -- local site = StationInfo.site()
    local systemPath = string.gsub(Device.userDirectory, "user", 'system')
    local recordsPath = systemPath .. '/records.csv'
    local timePath = systemPath .. '/time.csv'
    local vpPath = Device.userDirectory .. '/vp.DUT1' .. tostring(Device.systemIndex + 1) .. '.log'
    local product = paraTab.productstage or "NPI"
    if product == "MP" then
        runShellCommand.run("rm -rf " .. timePath .. ' ' .. vpPath)
        if station_type == "DFU-NAND-INIT" then
            runShellCommand.run("rm -rf " .. recordsPath)
            runShellCommand.run("ditto -c -k --sequesterRsrc --keepParent /vault/Atlas/FixtureLog/" .. vendor .. " " ..
                                    Device.userDirectory .. "/FixtureLog.zip")
        end
    end
    if product == "NPI" then
        -- runShellCommand.run("ditto -c -k --sequesterRsrc --keepParent /vault/Atlas/FixtureLog/" .. vendor .. " " ..
        --                         Device.userDirectory .. "/FixtureLog.zip")
        runShellCommand.run("cp -r ~/Library/Atlas2/Assets " .. Device.userDirectory)
        runShellCommand.run("cp -r ~/Library/Atlas2/Modules/Tech " .. Device.userDirectory)
        runShellCommand.run("rm -r " .. Device.userDirectory .. "/Assets/InteractiveView.bundle " ..
                                Device.userDirectory .. "/Assets/PopupBundle.bundle " .. Device.userDirectory ..
                                "/Assets/" .. "StatusCollection.bundle " .. Device.userDirectory ..
                                "/Assets/parseDefinitions")
        runShellCommand.run("cp -r /vault/data_collection/" .. "test_station_config/gh_station_info.json " ..
                                Device.userDirectory)
        runShellCommand.run("cp -r ~/Library/Logs/Atlas/active/fixtureCommon.log " .. Device.userDirectory)
        runShellCommand.run("cp -r ~/Library/Atlas2/Actions " .. Device.userDirectory)
        runShellCommand.run("rm -r " .. Device.userDirectory .. "/Assets/VendorSupportFiles " ..
                                Device.userDirectory .."/Actions/Schooner")

    end
    local serialNumber = paraTab.Input
    if serialNumber ~= nil and #serialNumber > 0 then
        DFUCommon.runShellCmd(
            "mv " .. Device.userDirectory .. "/uart.log " .. Device.userDirectory .. "/" .. serialNumber .. ".log")
    end
    local endOfDevice
    if (Atlas.compareVersionTo("2.33") ~= Atlas.versionComparisonResult.lessThan) then
        endOfDevice = Archive.when.deviceFinish
    else
        endOfDevice = Archive.when.endOfTest
    end
    Archive.addPathName(Device.userDirectory, endOfDevice)
    if paraTab.subsubtestname then
        helper.flowLogFinish(true, paraTab)
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0060:, Version: v0.1, Type:Inner]
Name: SOC.setLimitsVersion
Function description: [v0.1]  set limit version to UI
Input :Table(paraTab)
Output : N/A
Mark: (Unused)
-----------------------------------------------------------------------------------]]
function SOC.setLimitsVersion(paraTab)
    local prefix, suffix = string.match(paraTab.InputDict["TPVersion"], "(TP)(.+)")
    DataReporting.limitsVersion(tostring(prefix .. "_" .. paraTab.InputDict["CPRV"] .. "_" .. suffix ..
                                             paraTab.InputDict["NonRetestable"]))
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0040, Version: v0.1, Type:DFU]
Name: SOC.getEnvVersion(paraTab)
Function description: [v0.1] Function to get RBM/RTOS version for log.
Input : Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]
function SOC.getEnvVersion(paraTab)
    helper.flowLogStart(paraTab)
    local env = paraTab.env
    local logPath = Device.userDirectory .. "/" .. paraTab.log_device
    local timeUtility = Device.getPlugin("TimeUtility")
    timeUtility.delay(2) -- use inner delay
    local runTest = Device.getPlugin("Runtest")
    local ret = runTest.getEnvVersion(env, logPath)
    local failureMessage = ""
    local result = ""
    local resultFlag = false

    if comFunc.hasKey(ret, "version") then
        Log.LogInfo("$$$$$expect", expect)
        Log.LogInfo("$$$$$ret[version]", ret["version"])
        resultFlag = true
        result = ret["version"]
        DataReporting.submit(DataReporting.createAttribute(string.upper(env) .. "_Version", result))
    else
        failureMessage = "Get Env Version fail!!!"
        resultFlag = false
    end

    if comFunc.hasKey(ret, "date") then
        DataReporting.submit(DataReporting.createAttribute(string.upper(env) .. "_BUILD_TIME", ret["date"]))
    end

    if resultFlag then
        helper.flowLogFinish(resultFlag, paraTab, result)
    else
        helper.flowLogFinish(resultFlag, paraTab, result, failureMessage)
        helper.reportFailure(failureMessage)
    end

    return result
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0061:, Version: v0.1, Type:Inner]
Name: SOC.setHangStatus
Function description: [v0.1]  Set the default state
Input :N/A
Output : N/A
Mark: (Unused)
-----------------------------------------------------------------------------------]]
function SOC.setHangStatus()
    return "FALSE"
end

return SOC
