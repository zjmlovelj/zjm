local groupFunctions = {}

local Log = require("Tech/logging")
local utils = require("Tech/utils")
local comFunc = require("Tech/CommonFunc")
local ftcsv = require ("Tech/ftcsv")
local pListSerialization = require "Serialization.PListSerialization"
local STATION_TOPOLOGY = pListSerialization.LoadFromFile(string.gsub(Atlas.assetsPath, 'Assets',
                                                                    "Config/StationTopology.plist"))
local XAVIER_IP = STATION_TOPOLOGY["groups"][Group.index]["xavier_ip"]
local DEVICES_NUM = 4

local automationMode = false
local MLBSN_Test = {}

-- ! @brief Execute Shell Command
-- ! @details Execute command in shell
-- ! @param command(string) Execute Command statement
-- ! @return N/A
function executeShellCommand( command )
    local status = os.execute(command)
    Log.LogInfo("Run command : " .. command .. "\n status: " .. tostring(status))
end

-- ! @brief Ping xavier IP
-- ! @details Do ping xavier IP in shell
-- ! @param xavierIP(string) IP address
-- ! @return N/A
function pingIP( xavierIP )
    local pingCmd = "ping " .. xavierIP .. " -c 1 -t 1"
    executeShellCommand(pingCmd)
end

-- ! @brief Load FixturePlugin and init Fixture
-- ! @details Reset the fixture through FixturePlugin and open it
-- ! @return N/A
function loadFixturePluginAndInitFixture( )
    local fixtureBuilder = Atlas.loadPlugin("FixturePlugin")
    local fixturePlugin = fixtureBuilder.createFixtureBuilder(Group.index-1)
    for i = 1, 4 do
        local status, cmdReturn = xpcall(fixturePlugin.relay_switch, debug.traceback, "discharge_connect", "on", i)
        local value = fixturePlugin.read_voltage("PPVBAT", i)
        Log.LogInfo("PPVBAT:--> "..value)
        if value > 2400 then
            -- fixturePlugin.relay_switch("vbatt_reset", "on", i)
            local status, cmdReturn = xpcall(fixturePlugin.relay_switch, debug.traceback, "vbatt_reset", "on", i)
            Log.LogInfo("cmdReturn:--> "..tostring(cmdReturn))
        end
        local status, cmdReturn = xpcall(fixturePlugin.relay_switch, debug.traceback, "discharge_connect", "off", i)
    end
    fixturePlugin.reset()
    return fixturePlugin
end

-- ! @brief Show group view message
-- ! @details If AutomationMode is false, then show group view message, otherwise log message
-- ! @param InteractiveView(table) InteractiveView handle
-- ! @param message(string) Defined string
-- ! @param messageColor(string) Defined color value
-- ! @return N/A
function showGroupViewMessage( InteractiveView, message, messageColor)
    local groupIndex = Group.index - 1
    InteractiveView.showGroupView(groupIndex, { ["message"] = message, ["messageColor"]= messageColor, ["messageFont"]=18, ["messageAlignment"]=0} )
end

-- ! @brief Clear group view message
-- ! @details If AutomationMode is false, then clear group view message
-- ! @param InteractiveView(table) InteractiveView handle
-- ! @return N/A
function clearGroupViewMessage( InteractiveView )
    local groupIndex = Group.index - 1
    InteractiveView.showGroupView(groupIndex, { ["message"] = " ", ["messageColor"]= "blue", ["messageFont"]=18, ["messageAlignment"]=0} )
end

function checkLimits()
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    local TechCSVPath = string.gsub(Atlas.assetsPath, 'Assets', "Actions/Tech")
    local techCSVTab = {}
    local techCSVPathResponse = RunShellCommand.run("ls " .. TechCSVPath)
    local techCSVPathOutput = techCSVPathResponse.output
    local techCSVPathList = comFunc.splitBySeveralDelimiter(techCSVPathOutput, '\n\r')

    for i, technology in ipairs(techCSVPathList) do
        techCSVTab[technology] = {}
        local technologyPath = TechCSVPath .. "/" .. technology
        local coverageResponse = RunShellCommand.run("ls " .. technologyPath)
        local coverageOutput = coverageResponse.output
        local coverageList = comFunc.splitBySeveralDelimiter(coverageOutput, '\n\r')
        for j, coverage in ipairs(coverageList) do
            if coverage:match(".+%.([cC][sS][vV])$") then
                local coverageCSVFilePath = technologyPath .. "/" .. coverage
                local coverageName = string.gsub(coverage, ".csv", "")
                techCSVTab[technology][coverageName] = {}
                Log.LogInfo(string.format("coverageCSVFilePath: %s", coverageCSVFilePath))
                local csvTable = ftcsv.parse(coverageCSVFilePath, ",", { ["headers"] = false, })
                table.remove(csvTable, 1)
                for row, item in ipairs(csvTable) do
                    if string.find(item[2], "subsubtestname") then
                        local subsubtestname = string.gsub(item[2], "{subsubtestname=\"", "")
                        subsubtestname = string.gsub(subsubtestname, "\"}", "")
                        table.insert(techCSVTab[technology][coverageName], subsubtestname)
                    end
                end
            end
        end
    end
    local limitIsValid = true
    local limitCSV = Atlas.assetsPath .. "/InputTables/LimitsTable.csv"
    local limitTbl = ftcsv.parse(limitCSV, ",", { ["headers"] = false, })
    table.remove(limitTbl, 1)
    for row, limitItem in ipairs(limitTbl) do
        local testname = limitItem[2]
        local subtestname = limitItem[3]
        if limitItem[4] and #limitItem[4] > 0 then
            subtestname = limitItem[3].."_"..limitItem[4]
        end
        local subsubtestname = limitItem[5]
        if testname ~= "" and subtestname ~= "" and subsubtestname ~= "" then
            if techCSVTab[testname] == nil or type(techCSVTab[testname]) ~= "table" then
                Log.LogInfo(string.format("Invalid testname in LimitsTable.csv row  %d : %s",row + 1, testname))
                limitIsValid = false
            else
                if techCSVTab[testname][subtestname] == nil or type(techCSVTab[testname][subtestname]) ~= "table" then
                    Log.LogInfo(string.format("Invalid subtestname in LimitsTable.csv row  %d : %s,%s",row + 1, testname, subtestname))
                    limitIsValid = false
                else
                    local notFound = true
                    for __, subsubitem in ipairs(techCSVTab[testname][subtestname]) do
                        if subsubtestname == subsubitem then
                            notFound = false
                            break
                        end
                    end
                    if notFound then
                        Log.LogInfo(string.format("Invalid subsubtestname in LimitsTable.csv row  %d : %s,%s,%s ",row + 1, testname, subtestname, subsubtestname))
                        limitIsValid = false
                    end
                end
            end
        end
    end
    return limitIsValid
end

function createDirs( directories )
    for _,dir in ipairs(directories) do
        local createDirCmd = "mkdir -p " .. dir
        executeShellCommand(createDirCmd)
    end
end

-- ! @brief Load group plugins
-- ! @details Judge InteractiveAuto is true or false, then load the corresponding plugin, load usbMonitor plugin
-- ! @details Call loadFixturePluginAndInitFixture function, if status is false to show fail message and error message
-- ! @param resources(table) Plugin resources
-- ! @return Plugins(table) Return usbMonitor, InteractiveView, InteractiveAuto, FixturePlugin
function groupFunctions.setup(resources)
    Log.LogInfo("--------loading group plugins-------")
    local InteractiveView = Remote.loadRemotePlugin(resources["SMTInteractiveUI"])
    pingIP(XAVIER_IP)
    Log.LogInfo("--------checkLimits-------")
    local limitIsValid = checkLimits()
    if limitIsValid == false then
        showGroupViewMessage(InteractiveView, "LimitsTable.csv is invalid!", "red")
        error("LimitsTable.csv is invalid!")
    end
    Log.LogInfo("--------checkLimits PASS-------")
    local fixturePlugin = nil
    local status,ret = xpcall(loadFixturePluginAndInitFixture,debug.traceback)
    if not status then
        showGroupViewMessage(InteractiveView, "init fixture failed ...\r\n治具初始化失败 ...", "red")
        error(ret)
    else
        fixturePlugin = ret
        clearGroupViewMessage(InteractiveView)
    end

    return {
        InteractiveView = InteractiveView,
        FixturePlugin = fixturePlugin,
    }
end

-- ! @brief Automatically close the fixture
-- ! @details Init Fixture for start, clear xavier log, off led
-- ! @details If AutomationMode is ture, Automatically close the fixture
-- ! @param groupPlugins(table) Group plugins
-- ! @return N/A
function groupFunctions.start(groupPlugins)
    Log.LogInfo("============================groupStart=========================")
    local fixturePlugin = groupPlugins['FixturePlugin']
    for i=1,DEVICES_NUM do
        fixturePlugin.reset_xavier_log(i)
        fixturePlugin.led_off(i)
        if automationMode then
            fixturePlugin.fixture_close()
        end
    end
end

-- ! @brief Stop group test, reboot the fixture and initialization
-- ! @details Call fixturePlugin.reset function, if resetStatus is false, then show view message and error message
-- ! @param groupPlugins(table) Group plugins
-- ! @return N/A If reset status or open status is false raise error message
function groupFunctions.stop(groupPlugins)
    -- clearAndBackupFixtureLog()
    Log.LogInfo("--------Group Stop--------")
    local fixturePlugin = groupPlugins['FixturePlugin']
    local InteractiveView = groupPlugins.InteractiveView
    local status,ret = xpcall(fixturePlugin.reset,debug.traceback)
    if not status then 
        showGroupViewMessage(InteractiveView, "reset fixture failed ...\r\n治具初始化失败 ...", "red")
        error(ret)
    end
    local status,ret = xpcall(fixturePlugin.fixture_open,debug.traceback)
    if not status then 
        showGroupViewMessage(InteractiveView, "open fixture failed ...\r\n治具打开失败 ...", "red")
        error(ret)
    end
end

-- ! @brief Shut down group plugins
-- ! @details Teardown plugins through the functions in groupPlugins
-- ! @param groupPlugins(table) Group plugins
-- ! @return N/A
function groupFunctions.teardown(groupPlugins)
    Log.LogInfo("--------shutdown Group Plugins--------")
    local fixture_plugin = groupPlugins.FixturePlugin
    fixture_plugin.teardown()
    return {}
end

-- ! @brief Get the slots from InteractiveView
-- ! @details Log isLoopFinished result, get the slots information from InteractiveView with viewConfig
-- ! @param groupPlugins(table) The table that stores the group plugin
-- ! @param viewConfig(table) SN and slot information
-- ! @return ret(table) Selected slot information
function groupFunctions.getSlotsByInteractiveView(groupPlugins, viewConfig)
    local ret = {}
    local slot = {}
    local InteractiveView = groupPlugins.InteractiveView
    local isLoopFinished = InteractiveView.isLoopFinished(Group.index - 1)
    --InteractiveView.splitView(1)
    Log.LogInfo("isLoopFinished " .. tostring(isLoopFinished))
    local output = InteractiveView.showGroupView(Group.index - 1, viewConfig)
    Log.LogInfo("$$$output", output)
    for i, v in pairs(output) do
        Log.LogInfo("########output i = " .. tostring(i) .. " v =" .. tostring(v))
    end

    local units = Group.getSlots()
    -- units = {"slot0", "slot1", "slot2", "slot3"}

    local fixture_plugin = groupPlugins.FixturePlugin
    for i, v in ipairs(units) do
        fixture_plugin.led_off(i)
        Log.LogInfo("########units i = " .. tostring(i) .. " v =" .. tostring(v))
        if output[v] ~= nil then table.insert(ret, v) end
    end
    Log.LogInfo("$$$ret", ret)
    return ret
end

-- ! @brief Get slot information
-- ! @details Get the slots information from getSlotsByInteractiveView function
-- ! @details Call fixture_close function, if status is false, show fail message and error, otherwish clear message
-- ! @param groupPlugins(table) Group plugins
-- ! @return output(table) Group slots information, if status is false raise error message
function groupFunctions.getSlots(groupPlugins)
    -- add code here if want to wait for start button before testing.
    -- demo code to not test slot1
    MLB_Start = STATION_TOPOLOGY["groups"][Group.index]["prefixSN"]
    local InteractiveView = groupPlugins.InteractiveView
    --InteractiveView.splitView(1)
    local viewConfigInput = { ["length"] = 18, ["drawShadow"] = 0, ["backgroundAlpha"] = 0.3,
                         ["column"]=4, ["input"] = {"slot1", "slot2", "slot3", "slot4"} }
    local viewConfigSwitch = { ["length"] = 18, ["switch"] = {"slot1", "slot2", "slot3", "slot4"} }
    local slots = groupFunctions.getSlotsByInteractiveView(groupPlugins, viewConfigInput)
    Log.LogInfo("=========================slots==================", slots)
    executeShellCommand("pkill -9 virtualport")
    local fixturePlugin = groupPlugins['FixturePlugin']
    Log.LogInfo"(=========================SNCHECK==================)"
    for i, v in pairs(slots) do
        Log.LogInfo("########slots i = " .. tostring(i) .. " v =" .. tostring(v))
        -- local slot_id = tonumber(tostring(i):sub(-1))
        local slot_id = tonumber(string.match(v,"slot(%d)"))
        local deviceName = "G=1:S="..tostring(slot_id)
        -- G=1:S=slot2`
        Log.LogInfo("$$$deviceName"..deviceName)
        local status, data = xpcall(InteractiveView.getData, debug.traceback, slot_id-1)
        Log.LogInfo("$$$slot_id-1 ->" .. slot_id-1 .."$$$data ->" .. data)
        MLBSN_Test[deviceName] = data
        if MLBSN_Test[deviceName] then
            -- local primartIdentityState = xpcall(Group.setDevicePrimaryIdentity, debug.traceback, deviceName, MLBSNTable[deviceName])
            -- Log.LogInfo("########primartIdentityState  " .. comFunc.dump(primartIdentityState))
            if #data ~= 18 or not string.find(string.sub(data,0,1),MLB_Start) or string.match(data,"%p") then
            -- if not primartIdentityState then                
                local viewConfig = {
                    ["title"] = "SN 错误!!!!",
                    ["message"] = "Slot: " .. slot_id .. " SN: " .. MLBSN_Test[deviceName] .. "is illegal" .. "Please Click OK.",
                    ["button"] = {"OK"}
                }
                InteractiveView.showView(slot_id-1, viewConfig)
                error("SN: " .. MLBSN_Test[deviceName] .. " is illegal!")
            end
        end
    end
    local status,ret = xpcall(fixturePlugin.fixture_close,debug.traceback)
    if not status then 
        showGroupViewMessage(InteractiveView, "close fixture failed ...\r\n治具关闭失败 ...", "red")
        error(ret)
    else
        clearGroupViewMessage(InteractiveView)
    end

    return slots
end

return groupFunctions
