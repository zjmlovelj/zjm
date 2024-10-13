-------------------------------------------------------------------
----***************************************************************
----DFU Restore Functions
----***************************************************************
-------------------------------------------------------------------
local Restore = {}
local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local helper = require("Tech/SMTLoggingHelper")
local DFUCommon = require("Tech/DFUCommon")

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0020, Version: v0.1, Type:DFU]
Name: Restore.checkHangAndKernelPanic(paraTab)
Function description: [v0.1]Function to Check the panic message or detect hang issue during the restore process, will power off the UUT if hang detected.
Input : Table(paraTab) 
Output : string
-----------------------------------------------------------------------------------]]
function Restore.checkHangAndKernelPanic(paraTab)
    helper.flowLogStart(paraTab)
    local variableTable = Device.getPlugin("VariableTable")
    local timeout = tonumber(paraTab.Timeout)
    if timeout == nil then
        helper.reportFailure("miss timeout")
    end

    local hangTimeout = tonumber(paraTab.hangTimeout)
    if hangTimeout == nil then
        helper.reportFailure("miss hangTimeout in AdditionalParameters")
    end

    local dut = Device.getPlugin(paraTab.dutPluginName)
    if dut.isOpened() ~= 1 then
        dut.open(2)
    end
    dut.setDelimiter("")

    local panic_msg = "Debugger message: panic;" .. "Please go to https://panic.apple.com to report this panic;" ..
                          "Nested panic detected;%[iBoot Panic%]" .. ";iBoot Panic:"
    local panicKeys = comFunc.splitString(panic_msg, ';')


    local content = ""
    Log.LogInfo("$$$$ kernel_panic check starting")
    local startTime = os.time()
    local lastRetTime = os.time()

    repeat
        local status, ret = xpcall(dut.read, debug.traceback, 1, '')
        if status and ret and #ret > 0 then
            lastRetTime = os.time()
            content = content .. ret
            if Restore.checkKernelPanic(paraTab, content, panicKeys) then
                variableTable.setVar("Poison","TRUE")
                return content
            end
        end

        if os.difftime(os.time(), lastRetTime) >= hangTimeout then
            Restore.restoreHangDetectedHandle(paraTab)
            variableTable.setVar("isRestoreFinished", true)
            variableTable.setVar("Poison","TRUE")
            helper.flowLogFinish(false, paraTab, "Hang_detected", "Hang_detected")
            return content
        end
    until (os.difftime(os.time(), startTime) >= timeout or variableTable.getVar("isRestoreFinished"))

    helper.flowLogFinish(true, paraTab)
    helper.LogInfo("$$$$ kernel_panic check done")
    return content
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0030, Version: v0.1, Type:InnerCommon]
Name: Restore.checkKernelPanic(paraTab)
Function description: [v0.1]
Input :
Output : true/false
-----------------------------------------------------------------------------------]]
function Restore.checkKernelPanic(paraTab, content, panicKeys)
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local InteractiveView = Device.getPlugin("InteractiveView")
    local statusVar, variableTable = xpcall(Device.getPlugin, debug.traceback, 'VariableTable')

    for _, v in ipairs(panicKeys) do
        if #v > 0 and string.find(content, v) then
            local viewConfig = {["message"] = "Kernel panic detected: " .. v}
            InteractiveView.showView(Device.systemIndex, viewConfig)

            helper.LogFixtureControlStart("dut_power_off", Device.identifier:sub(-1), 'nil')
            local status, cmdReturn = xpcall(fixturePlugin.dut_power_off, debug.traceback,
                                             tonumber(Device.identifier:sub(-1)))
            if status and #cmdReturn == 0  then
                helper.LogFixtureControlFinish('done')
            else
                helper.LogFixtureControlFinish(tostring(cmdReturn))
            end

            if statusVar then
                variableTable.setVar("Poison","TRUE")
            end

            if v == "%[iBoot Panic%]" then
                helper.reportFailure("Get Iboot_Panic failed")
            else
                helper.reportFailure("Get Kernel_Panic failed")
            end
            return true
        end
    end

    return false
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0031, Version: v0.1, Type:InnerCommon]
Name: Restore.restoreHangDetectedHandle(paraTab)
Function description: [v0.1]
Input : 
Output : 
-----------------------------------------------------------------------------------]]
function Restore.restoreHangDetectedHandle(paraTab)
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local InteractiveView = Device.getPlugin("InteractiveView")

    helper.LogFixtureControlStart("dut_power_off", Device.identifier:sub(-1), 'nil')

    local status, cmdReturn = xpcall(fixturePlugin.dut_power_off, debug.traceback, tonumber(Device.identifier:sub(-1)))

    if (not status) or (cmdReturn and #tostring(cmdReturn) > 0) then
        helper.LogFixtureControlFinish(tostring(cmdReturn))
    else
        helper.LogFixtureControlFinish('done')
    end

    local viewConfig = {["message"] = "uart hang detected"}
    InteractiveView.showView(Device.systemIndex, viewConfig)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0021, Version: v0.1, Type:DFU]
Name: Restore.supplyAceProvisioningPower(paraTab)
Function description: [v0.1] Function to check the supply Ace Provisioning Power flag during the restore process.
Input : Table(paraTab) 
Output : N/A
-----------------------------------------------------------------------------------]]
function Restore.supplyAceProvisioningPower(paraTab)
    helper.flowLogStart(paraTab)
    local variableTable = Device.getPlugin("VariableTable")
    local runShellCmd = Device.getPlugin("RunShellCommand")
    local timeout = tonumber(paraTab.Timeout)
    local startTime = os.time()
    if timeout == nil then
        helper.reportFailure("miss timeout")
    end

    local ppvbus_14v_on_flag = false
    -- local ppvbus_14v_off_flag = false

    local files = runShellCmd.run("ls " .. Device.userDirectory .. "/DCSD")['output']
    local device_log_path = string.match(files, "restore_device_[0-9_-]+%.log")
    
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    -- "CHECKPOINT END: FIRMWARE:[0x130A] install_fud"
    local ppvbus_14v_on_signal = paraTab.OnSignal
    -- "CHECKPOINT END: (null):[0x067F] provision_ace2"
    local ppvbus_14v_off_signal = paraTab.OffSignal
    ppvbus_14v_on_signal = string.gsub(ppvbus_14v_on_signal, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
    ppvbus_14v_off_signal = string.gsub(ppvbus_14v_off_signal, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")

    --
    repeat
        -- Supply_ace_provisioning_power
        if device_log_path ~= nil then
            local device_log = comFunc.fileRead(device_log_path)
            if not ppvbus_14v_on_flag then
                if string.find(device_log, ppvbus_14v_on_signal) then
                    helper.LogFixtureControlStart("ace_provisioning_power_on", Device.identifier:sub(-1), "nil")
                    local _, cmdReturn = xpcall(fixturePlugin.ace_provisioning_power_on, debug.traceback,
                                                tonumber(Device.identifier:sub(-1)))

                    helper.LogFixtureControlFinish(tostring(cmdReturn))

                    Log.LogInfo("$$$$ ace_provisioning_power_on")
                    ppvbus_14v_on_flag = true
                end
            end
            -- if not ppvbus_14v_off_flag then
            if string.find(device_log, ppvbus_14v_off_signal) then
                helper.LogFixtureControlStart("ace_provisioning_power_off", Device.identifier:sub(-1), "nil")
                local _, cmdReturn = xpcall(fixturePlugin.ace_provisioning_power_off, debug.traceback,
                                             tonumber(Device.identifier:sub(-1)))

                helper.LogFixtureControlFinish(tostring(cmdReturn))

                Log.LogInfo("$$$$ ace_provisioning_power_off")
                -- ppvbus_14v_off_flag = true
                break
            end
        else
            local files = runShellCmd.run("ls " .. Device.userDirectory .. "/DCSD")['output']
            device_log_path = string.match(files, "restore_device_[0-9_-]+%.log")
        end
        comFunc.sleep(0.1)
    until (os.difftime(os.time(), startTime) >= timeout or variableTable.getVar("isRestoreFinished"))

    helper.flowLogFinish(true, paraTab)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0022, Version: v0.1, Type:DFU]
Name: Restore.supplyFixtureAction(paraTab)
Function description: [v0.1] Function to check the supply fixture action flag during the restore process.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function Restore.supplyFixtureAction(paraTab)
    helper.flowLogStart(paraTab)
    local variableTable = Device.getPlugin("VariableTable")
    local timeout = tonumber(paraTab.Timeout)
    local startTime = os.time()
    local slot_num = tonumber(Device.identifier:sub(-1))
    local device_log_path = Device.userDirectory .. '/../system/device.log'
    if timeout == nil then
        helper.reportFailure("miss timeout")
    end

    local net_switch_flag = false
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local net_switch_signal = paraTab.Signal
    net_switch_signal = string.gsub(net_switch_signal, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
    repeat
        if device_log_path ~= nil then
            local device_log = comFunc.fileRead(device_log_path)
            if #device_log > 0 then
                if net_switch_signal and (not net_switch_flag) and (string.find(device_log, net_switch_signal)) then
                    Log.LogInfo("$$$$ found net_switch_signal")
                    local netname = paraTab.netname
                    local status = paraTab.status
                    if netname then
                        Log.LogInfo("$$$$ fixture send command ".. netname)
                        xpcall(fixturePlugin.relay_switch, debug.traceback, netname, status, slot_num)
                        net_switch_flag = true
                    else
                        Log.LogInfo("$$$$ netname not define")
                        break
                    end
                else
                    Log.LogInfo("$$$$ Signal not define")
                    break
                end
            end
        else
            Log.LogInfo("$$$$ device.log is empty")
        end
        os.execute("sleep 0.1")
    until (os.difftime(os.time(), startTime) >= timeout or variableTable.getVar("isRestoreFinished"))

    helper.flowLogFinish(true, paraTab)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0023, Version: v0.1, Type:DFU]
Name: Restore.restore(paraTab)
Function description: [v0.1] Function to restore device
Input : Table(paraTab) 
Output : N/A
-----------------------------------------------------------------------------------]]
function Restore.restore(paraTab)
    helper.flowLogStart(paraTab)
    local prName = paraTab.PrName
    local timeout = paraTab.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        helper.reportFailure("miss timeout")
    end

    local locationId = paraTab.Location_ID
    if locationId == nil or #locationId < 1 then
        helper.flowLogFinish(false, paraTab, locationId, "miss locationId")
        helper.reportFailure("miss locationId")
        return
    end

    local usb_url = "lockdown://" .. tostring(locationId)
    Log.LogInfo("usb_url>>", usb_url)

    local dcsd_plugin = Device.getPlugin("DCSD")
    local variableTable = Device.getPlugin("VariableTable")

    Log.LogInfo("lockdown URL for SWDLRestore: ", usb_url)
    Log.LogInfo("Device.userDirectory: ", Device.userDirectory)
    local workspace = Device.userDirectory .. "/DCSD"
    local startTime = os.time()
    local restoreErrorMsg = ""
    local dcsd_dut = dcsd_plugin.get_dcsd_dut_plugin(usb_url, workspace)

    local pr_doc_path = "/Users/gdlocal/Library/Application Support/PurpleRestore/"..prName
    Log.LogInfo("PrName and path: ",pr_doc_path)

    -- DCSD start
    local unit_start_time_string = tostring(os.date("%Y-%m-%d_%H-%M-%S"))
    local progress = dcsd_plugin.get_progress_plugin()
    dcsd_dut.restore_device(pr_doc_path, -- PR_DOC_PATH
    unit_start_time_string, -- start date in yyyy-MM-dd_HH-mm-ss"
    "sw_name", -- SWName
    "sw_version", -- SWVersion
    false, -- Whether to write SFC record
    false, -- Whether to use MPNRC from SFC
    progress -- For progress update
    )
    repeat
        local msg = progress.getMessage()
        if msg ~= nil then
            Device.updateProgress(msg)
            Log.LogInfo(msg)
            if string.find(msg, "restore failed") then
                restoreErrorMsg = restoreErrorMsg == "" and msg or restoreErrorMsg .. "," .. "msg"
            end
        end
    until (os.difftime(os.time(), startTime) >= timeout or not progress.isRunning() or
        variableTable.getVar("isRestoreFinished"))
        
    variableTable.setVar("isRestoreFinished", true)

    local result = true
    if progress.isRunning() then
        result = false
        helper.flowLogFinish(result, paraTab, "--FAIL--", "Restore timeout error")
        return
    end
    if restoreErrorMsg ~= "" then
        result = false
        helper.flowLogFinish(result, paraTab, "--FAIL--", restoreErrorMsg)
        return
    end

    helper.flowLogFinish(result, paraTab)
    Log.LogInfo("$$$$ restore done")
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0024, Version: v0.1, Type:DFU]
Name: Restore.restoreDFUModeCheck(paraTab)
Function description: [v0.1] Function to check restore dfu mode for dut.
Input : Table(paraTab) 
Output : string
-----------------------------------------------------------------------------------]]

function Restore.restoreDFUModeCheck(paraTab)
    helper.flowLogStart(paraTab)
    local timeout = paraTab.Timeout
    local flagIndex = paraTab.flagIndex
    local pattern = paraTab.pattern
    if timeout ~= nil then
        timeout = tonumber(timeout)
    else
        helper.reportFailure("miss timeout")
    end
    paraTab.InnerCall = true
    local locationId = DFUCommon.getLocationID(paraTab)
    if #locationId == 0 then
        helper.flowLogFinish(false, paraTab, locationId, "Get LocationID failed")
        helper.reportFailure("Get LocationID failed")
    end
    local VariableTable = Device.getPlugin("VariableTable")
    VariableTable.setVar("isRestoreFinished", false)
    helper.flowLogFinish(true, paraTab, locationId)
    return locationId
end

return Restore
