-------------------------------------------------------------------
----***************************************************************
----InteractiveView Commands
----Created at: 10/21/2020
----Author: Bin Zhao (zhao_bin@apple.com)
----***************************************************************
-------------------------------------------------------------------
local InteractiveView = {}
local comFunc = require("Tech/CommonFunc")
local helper = require("Tech/SMTLoggingHelper")

-- Read back SN from previous InteractiveView
-- @param paraTab: parameters from tech csv line(table)
-- @return: SN

function InteractiveView.readSN(paraTab)
    local sendCommand__inner = function()
        local InteractiveViewPlugin = Device.getPlugin("InteractiveView")

        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end

        helper.LogInfo(
            "Running readSN for: " .. tostring(paraTab.Technology) .. ", " .. tostring(paraTab.TestName) .. ", " ..
                tostring(paraTab["subsubtestname"]) .. "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                                  tostring(paraTab["subsubtestname"]))

        local dataReturn = InteractiveViewPlugin.getData(Device.systemIndex)

        helper.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end

        DataReporting.primaryIdentity(dataReturn)

        helper.LogInfo("Got resp:" .. paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                        tostring(paraTab["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end
    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("readSN failed: " .. tostring(ret))
    end
    -- Check if matches expect string
    local expect = paraTab["expect"]
    if expect ~= nil and string.match(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil then
        status = false
        helper.LogError("expected string '" .. tostring(expect) .. "' not found in response: " .. tostring(ret))
    end
    if status then
        helper.createRecord(status, paraTab, "",
                                       paraTab["subsubtestname"] .. paraTab.testNameSuffix)
    else
        helper.createRecord(status, paraTab, "",
                            paraTab["subsubtestname"] .. paraTab.testNameSuffix, nil,
                            DFULoggingHelper.DEFAULT_FAIL_RESULT)
    end
    return ret
end

function InteractiveView.showScan(paraTab)
    local sendCommand__inner = function()
        local InteractiveViewPlugin = Device.getPlugin("InteractiveView")

        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end
        local viewIdentifier = tostring(Device.identifier)

        helper.LogInfo("Running showScan: " .. viewIdentifier .. ". " .. paraTab.Technology .. ", " .. paraTab.TestName ..
                        ", " .. tostring(paraTab["subsubtestname"]) .. "', timeout: '" ..
                        tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                                  tostring(paraTab["subsubtestname"]))

        local viewConfig = {
            ["length"] = paraTab["length"],
            ["title"] = paraTab["title"],
            ["input"] = comFunc.parseParameter(string.gsub(paraTab["input"] or "", "'", "\""))
        }

        local dataReturn = InteractiveViewPlugin.showView(Device.systemIndex, viewConfig)

        helper.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end

        helper.LogInfo("Got resp:" .. paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                        tostring(paraTab["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end

    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("scanConfig failed: " .. tostring(ret))
    end

    -- Check if matches expect string
    local expect = paraTab["expect"]
    local nonMatch = string.match(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil
    if expect ~= nil and nonMatch or ret == nil then
        status = false
        helper.LogError("Invalid input or expected string '" .. tostring(expect) .. "' not found in response: " ..
                         tostring(ret))
    end
    if status then
        helper.createRecord(status, paraTab, "",
                                       paraTab["subsubtestname"] .. paraTab.testNameSuffix)
    else
        helper.createRecord(status, paraTab, "",
                            paraTab["subsubtestname"] .. paraTab.testNameSuffix, nil,
                            DFULoggingHelper.DEFAULT_FAIL_RESULT)
    end
    return ret
end

function InteractiveView.showSwitch(paraTab)
    local sendCommand__inner = function()
        local InteractiveViewPlugin = Device.getPlugin("InteractiveView")

        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end
        local viewIdentifier = tostring(Device.identifier)

        helper.LogInfo("Running showSwitch:     " .. viewIdentifier .. ". " .. paraTab.Technology .. ", " ..
                        paraTab.TestName .. ", " .. tostring(paraTab["subsubtestname"]) ..
                        "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                                  tostring(paraTab["subsubtestname"]))

        local viewConfig = {
            ["length"] = paraTab["length"],
            ["title"] = paraTab["title"],
            ["switch"] = comFunc.parseParameter(string.gsub(paraTab["switch"] or "", "'", "\""))
        }

        local dataReturn = InteractiveViewPlugin.showView(Device.systemIndex, viewConfig)

        helper.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end

        helper.LogInfo("Got resp:" .. paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                        tostring(paraTab["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end

    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("scanConfig failed: " .. tostring(ret))
    end

    -- Check if matches expect string
    local expect = paraTab["expect"]
    if expect ~= nil and string.match(ret or "", string.gsub(expect, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")) == nil then
        status = false
        helper.LogError("expected string '" .. tostring(expect) .. "' not found in response: " .. tostring(ret))
    end
    if status then
        helper.createRecord(status, paraTab, "",
                                       paraTab["subsubtestname"] .. paraTab.testNameSuffix)
    else
        helper.createRecord(status, paraTab, "",
                            paraTab["subsubtestname"] .. paraTab.testNameSuffix, nil,
                            DFULoggingHelper.DEFAULT_FAIL_RESULT)
    end
    return ret
end

-- Show Prompt with buttons for user to click matching button
-- @param paraTab: parameters from tech csv line(table)
-- @return: TRUE/FALSE (determined by button clicked by user)

function InteractiveView.showPassFailPrompt(paraTab)

    local sendCommand__inner = function()
        local InteractiveViewPlugin = Device.getPlugin("InteractiveView")

        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end
        local viewIdentifier = tostring(Device.identifier)

        helper.LogInfo("Running showPassFailPrompt: " .. tostring(viewIdentifier) .. ". " .. paraTab.Technology .. ", " ..
                        paraTab.TestName .. ", " .. tostring(paraTab["subsubtestname"]) ..
                        "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                                  tostring(paraTab["subsubtestname"]))

        local viewConfig = {
            ["title"] = paraTab["title"],
            ["message"] = paraTab["message"],
            ["button"] = comFunc.parseParameter(string.gsub(paraTab["button"] or "", "'", "\""))
        }

        local dataReturn = InteractiveViewPlugin.showView(Device.systemIndex, viewConfig)

        helper.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end

        helper.LogInfo("Got resp:" .. paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                        tostring(paraTab["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end

    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("passFailPrompt failed: " .. tostring(ret))
    end

    if ret == nil or ret == false then
        status = false
        helper.LogError("User clicked FAIL. Return code: " .. tostring(ret))
    end
    if status then
        helper.createRecord(status, paraTab, "",
                                       paraTab["subsubtestname"] .. paraTab.testNameSuffix)
    else
        helper.createRecord(status, paraTab, "",
                            paraTab["subsubtestname"] .. paraTab.testNameSuffix, nil,
                            DFULoggingHelper.DEFAULT_FAIL_RESULT)
    end
    return ret
end

-- Show Alert for user attention
-- @param paraTab: parameters from tech csv line(table)
-- @return: TRUE.

function InteractiveView.showAlert(paraTab)
    local sendCommand__inner = function()
        local InteractiveViewPlugin = Device.getPlugin("InteractiveView")

        local timeout = paraTab.Timeout
        if timeout ~= nil then
            timeout = tonumber(timeout)
        end
        local viewIdentifier = tostring(Device.identifier)

        helper.LogInfo("Running showAlert: " .. tostring(viewIdentifier) .. ". " .. paraTab.Technology .. ", " ..
                        paraTab.TestName .. ", " .. tostring(paraTab["subsubtestname"]) ..
                        "', timeout: '" .. tostring(timeout) .. "'")
        Device.updateProgress(paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                                  tostring(paraTab["subsubtestname"]))

        local viewConfig = {
            ["title"] = paraTab["title"],
            ["message"] = paraTab["message"],
            ["button"] = {"OK"}
        }

        local dataReturn = InteractiveViewPlugin.showView(Device.systemIndex, viewConfig)

        helper.LogInfo("SystemIndex: ", Device.systemIndex, " dataReturn: ", dataReturn)

        if dataReturn == nil then
            error("No data available: " .. tostring(dataReturn))
        end

        helper.LogInfo("Got resp:" .. paraTab.Technology .. ", " .. paraTab.TestName .. ", " ..
                        tostring(paraTab["subsubtestname"]) .. ": ", dataReturn)
        return dataReturn
    end

    -- sendCommand__inner()
    local status, ret = xpcall(sendCommand__inner, debug.traceback)
    if not status then
        error("alert failed: " .. tostring(ret))
    end

    if ret == nil or ret == false then
        status = false
        helper.LogError("User clicked FAIL. Return code: " .. tostring(ret))
    end
    if status then
        helper.createRecord(status, paraTab, "",
                                       paraTab["subsubtestname"] .. paraTab.testNameSuffix)
    else
        helper.createRecord(status, paraTab, "",
                            paraTab["subsubtestname"] .. paraTab.testNameSuffix, nil,
                            DFULoggingHelper.DEFAULT_FAIL_RESULT)
    end

    return ret
end

function InteractiveView.sleep(paraTab)
    os.execute("sleep " .. tostring(paraTab["delay"]))
    helper.createRecord(true, paraTab, "",
                                   paraTab["subsubtestname"] .. paraTab.testNameSuffix)
end

return InteractiveView
