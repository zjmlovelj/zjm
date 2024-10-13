local COF = {}
local InteractiveView = require("Tech/InteractiveView")
local Record = require("Tech/record")
local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local fixture = require("Tech/Fixture")

-- local runTest = Device.getPlugin("runtest")
-- local dut = Device.getPlugin("dut")

function COF.checkUSBDisconnect(paraTab)
    Log.LogInfo("-----------Enter checkUSBDisconnect-----------")
    local paraDict = {
        expect = "--- Device DETACHED --- : locationID=0x[0-9A-Za-z]{8}",
        logPath = "/Users/gdlocal/Library/Logs/Atlas/active/atlas.log",
        omit = "0",
        byPASS = 0
    }

    local _, errorCount = xpcall(COF.checkError, debug.traceback, paraTab, paraDict)

    Log.LogInfo("$$$$ UART USB Disconnection Check - errorCount: " .. tostring(errorCount))
end

function COF.checkError(paraTab, paraDict)
    local log = paraDict["logPath"]
    Log.LogInfo("$$$$ Enter log:" .. tostring(log))

    local _, retTable = xpcall(runTest.checkError, debug.traceback, paraDict)

    Log.LogInfo("$$$$ check error(retTable):", comFunc.dump(retTable))
    local checkErrorCount = retTable.Count["value"]
    Record.createParametricRecord(tonumber(checkErrorCount), paraTab.Technology,
                                  paraTab["errorname"],
                                  paraTab.failSubSubTestName .. "_" .. paraTab["subsubtestname"])

    Log.LogInfo("$$$$ checkErrorCount" .. tostring(checkErrorCount))
    return checkErrorCount
end

--------------- hang detect ----------------------------------
function COF.checkHang(paraTab)
    Log.LogInfo("$$$$ checkHang paraTab", comFunc.dump(paraTab))
    local hang = "FALSE"
    local errorMsg = paraTab.failureMessage

    if errorMsg and string.find(errorMsg, "Hang Detected") then
        hang = "TRUE"
    end

    if hang == "TRUE" then
        Record.createBinaryRecord(false, paraTab.Technology, paraTab["errorname"],
                                  paraTab.failSubSubTestName .. "_" .. paraTab["subsubtestname"],
                                  "Dut is hang!!!")
    else
        Record.createBinaryRecord(true, paraTab.Technology, paraTab["errorname"],
                                  paraTab.failSubSubTestName .. "_" .. paraTab["subsubtestname"])
    end

    return hang
end

function COF.fixtureRepower(paraTab)
    local status = xpcall(fixture.dut_power_on, debug.traceback, paraTab)
    Log.LogInfo("$$$$ fixture recycle status" .. tostring(status))
    if not status then
        error("Fixture recycle fail!!!")
    end
end

function COF.EnterEnvFail(paraTab)
    COF.fixtureRepower(paraTab)
    return "TRUE"
end

function COF.showAlert(paraTab)
    local automation = paraTab.Automation
    if automation == "NO" or automation == nil then
        InteractiveView.showAlert(paraTab)
    end
end

function COF.checkDutHang(paraTab)
    local hangtype = paraTab["HangType"]
    local isHang = "FALSE"
    Log.LogInfo("$$$$ Enter check " .. hangtype .. "Hang: " .. paraTab.Input)
    if paraTab.Input == "FALSE" then
        local status
        status, isHang = xpcall(COF.checkHang, debug.traceback, paraTab)
        Log.LogInfo("call COF.CheckHang successfully? " .. tostring(status))
        Log.LogInfo("$$$$ Is" .. hangtype .. "Hang? " .. isHang)

        if isHang == "TRUE" then
            if hangtype == "RBM" then
                local hangStatus, _ = xpcall(dut.send, debug.traceback, "cpu 0 cfe echo \"RBM: Are you hang?\"", 10)
                if not hangStatus then
                    paraTab["message"] =
                        "Suspected RBM Hang on Slot_" .. Device.identifier:sub(-1) ..
                            "!!! Call EE engineer to collect data before clicking OK!!! (" .. paraTab.TestName ..
                            ") HANG/PANIC"
                    paraTab["subsubtestname"] = "RBM Hang ShowAlert"
                    COF.showAlert(paraTab)
                    COF.fixtureRepower(paraTab)
                end
            elseif hangtype == "RTOS" then
                local hangStatus, _ = xpcall(dut.send, debug.traceback, "echo RTOS: Are you hang?", 10)
                if not hangStatus then
                    paraTab["message"] =
                        "Suspected PERTOS Hang on Slot_" .. Device.identifier:sub(-1) ..
                            "!!! Call EE engineer to collect data before clicking OK, " ..
                            "and click OK to start RTOS Stack Dump through Ctrl+Z!!! (" .. paraTab.TestName ..
                            ") HANG/PANIC"
                    paraTab["subsubtestname"] = "RTOS Hang ShowAlert"
                    COF.showAlert(paraTab)

                    local sendCtrlZ = xpcall(dut.send, debug.traceback, string.format("%c", 26), 10)
                    Log.LogInfo("$$$$ sendCtrlZ>>" .. tostring(sendCtrlZ))

                    if not sendCtrlZ then
                        paraTab["message"] =
                            "Suspected RTOS Hang on Slot_" .. Device.identifier:sub(-1) ..
                                " and CTRL+Z no response!!! Click OK to continue!!!"
                        paraTab["subsubtestname"] = "Send Ctrl + Z"
                        COF.showAlert(paraTab)
                    end
                    COF.fixtureRepower(paraTab)
                end
            end
        end
    end
    if string.find(paraTab.failSubSubTestName, "RESET%-MLB") ~= nil then
        COF.fixtureRepower(paraTab)
        isHang = "TRUE"
    end
    return isHang
end

return COF
