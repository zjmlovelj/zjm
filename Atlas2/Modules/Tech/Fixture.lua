-------------------------------------------------------------------
----***************************************************************
----Dimension Action Functions
----Created at:
----Author: 
----***************************************************************
-------------------------------------------------------------------
local Fixture = {}
local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local helper = require("Tech/SMTLoggingHelper")

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0049, Version: v0.1, Type:innerCall]
Name: parseFuncArgs(paraTab)
Function description: [v0.1] parse function args.
Input : args string
Output : args table
-----------------------------------------------------------------------------------]]
function Fixture.parseFuncArgs(argsStr)
    local args = {}
    if argsStr then
        local splitlist = comFunc.splitString(argsStr, ";")
        if splitlist then
            for _, v in ipairs(splitlist) do
                if tonumber(v) ~= nil then
                    table.insert(args, tonumber(v))
                else
                    table.insert(args, v)
                end
            end
        end
    end
    return args
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0017, Version: v0.1, Type:Common]
Name: Fixture.uploadFixtureInfo(paraTab)
Function description: [v0.1] Function to query and upload the fixture info to PDCA.
Input : Table(paraTab) 
Output : string
-----------------------------------------------------------------------------------]]
function Fixture.uploadFixtureInfo(paraTab)
    helper.flowLogStart(paraTab)
    local slot_num = Device.identifier:sub(-1)
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local actionFunc = paraTab.actionFunc  -- get_serial_number
    local reportFunc = paraTab.reportFunc -- fixtureID
    local funcArgs = paraTab.args
    local args = Fixture.parseFuncArgs(funcArgs)
    local result, reportStatus, status = false, false, false
    local failureMsg, response, fixtureInfo = "", "", ""

    if paraTab.slotNum then
        local slotNum = tonumber(paraTab.slotNum)
        table.insert(args, tonumber(slotNum))
        if funcArgs then
            funcArgs = funcArgs..";"..tostring(slotNum)
        else
            funcArgs = tostring(slotNum)
        end
    end
    
    helper.LogFixtureControlStart(actionFunc, funcArgs or "nil", "nil")

    if #args > 0 then
        status, fixtureInfo = xpcall(fixturePlugin[actionFunc], debug.traceback, table.unpack(args))
    else
        status, fixtureInfo = xpcall(fixturePlugin[actionFunc], debug.traceback)
    end

    if fixtureInfo then
        helper.LogFixtureControlFinish(tostring(fixtureInfo))
    else
        helper.LogFixtureControlFinish('done')
    end

    if status and fixtureInfo and #fixtureInfo > 0 then
        --add trim judge
        fixtureInfo = comFunc.trim(fixtureInfo)
        reportStatus, response = xpcall(DataReporting[reportFunc], debug.traceback, fixtureInfo, slot_num) -- validate Insight UI not
        if reportStatus then -- finish result
            result = true
        else
            failureMsg = "upload insight fail, " .. response
        end
    else
        failureMsg = "fixturn command fail, " .. fixtureInfo
    end

    helper.flowLogFinish(result, paraTab, fixtureInfo .. (response or ""), failureMsg)
    
    return fixtureInfo
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0018, Version: v0.1, Type:Common]
Name: Fixture.sendFixtureCommand(paraTab)
Function description: [v0.1] Function to Call the fixture plugin function according to the function name and args which define in the tech csv.
Input : Table(paraTab) 
Output : string or number
-----------------------------------------------------------------------------------]]
function Fixture.sendFixtureCommand(paraTab)
    helper.flowLogStart(paraTab)
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local actionFunc = paraTab.Commands
    local funcArgs = paraTab.args
    local args = Fixture.parseFuncArgs(funcArgs)
    local status, testResult = false, false
    local response = ""
    local conditionsRequired = paraTab.conditionsRequired
    if paraTab.slotNum then
        local slotNum = tonumber(paraTab.slotNum)
        table.insert(args, tonumber(slotNum))
        if funcArgs then
            funcArgs = funcArgs..";"..tostring(slotNum)
        else
            funcArgs = tostring(slotNum)
        end
    end
    helper.LogInfo("-------args------", #args)
    helper.LogFixtureControlStart(actionFunc, funcArgs or "nil", "nil")
    if #args > 0 then
        status, response = xpcall(fixturePlugin[actionFunc], debug.traceback, table.unpack(args))
    else
        status, response = xpcall(fixturePlugin[actionFunc], debug.traceback)
    end

    if response then
        helper.LogFixtureControlFinish(tostring(response))
    else
        helper.LogFixtureControlFinish('done')
    end

    if paraTab.attribute and status then -- judge have attribute and status is ture
        response = comFunc.trim(response)
        if response == nil or response == "" then -- fixture command return is nil or empty
            response = "fixture command return is nil or empty"
            status = false
        else
            DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, response))
        end
    end

    testResult = helper.flowLogFinish(status, paraTab, response)

    --base on response to define condition require
    if conditionsRequired then -- if conditions required, return is condition args
        conditionsRequired = Fixture.parseFuncArgs(conditionsRequired)
        if testResult == 2 or testResult == true then
            Log.LogInfo("conditionsRequired", conditionsRequired[1])
            return conditionsRequired[1]
        else
            Log.LogInfo("conditionsRequired", conditionsRequired[2])
            return conditionsRequired[2]
        end
    end
    
    return response
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0019, Version: v0.1, Type:Common]
Name: Fixture.getRpcServerLog(paraTab)
Function description: [v0.1] Function to get server.log for xavier borad and save to log folder.
Input : Table(paraTab) 
Output : N/A
-----------------------------------------------------------------------------------]]

function Fixture.getRpcServerLog(paraTab)
    helper.flowLogStart(paraTab)
    local runShellCmd = Device.getPlugin("RunShellCommand")
    local subsubtestname = paraTab.subsubtestname
    local slot_num = tonumber(Device.identifier:sub(-1))
    local rpcLogFile = "/vault/Atlas/FixtureLog/RPC_CH" .. tostring(slot_num) .. "/server.log"
    local fixturePlugin = Device.getPlugin("FixturePlugin")
    local status, resp = xpcall(fixturePlugin.get_and_write_xavier_log, debug.traceback, rpcLogFile, slot_num)
    if status then
        runShellCmd.run("cp -r /vault/Atlas/FixtureLog/RPC_CH" .. tostring(slot_num) .. " " .. Device.userDirectory)
        helper.flowLogFinish(true, paraTab)
    else
        Log.LogError(tostring(resp))
        helper.flowLogFinish(false, paraTab, resp, "getRpcServerLog error")
    end
    return
end

return Fixture
