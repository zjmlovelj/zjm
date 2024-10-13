-------------------------------------------------------------------
----***************************************************************
----common station functions
----***************************************************************
-------------------------------------------------------------------
local helper = require("Tech/SMTLoggingHelper")
local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local utils = require("Tech/utils")
local Common = require("Tech/Common")
local pListSerialization = require("Serialization/PListSerialization")

local DFUCommon = {}


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0002:, Version: v0.1, Type:Inner]
Name: checkValueInTable
Function description: [v0.1]  check data for table
Input :TableA, TableB, mark, Data, pattern
Output : string
-----------------------------------------------------------------------------------]]
function DFUCommon.checkValueInTable(TableA, TableB, mark, data, pattern)
    local mlbTable = {}
    mlbTable["MLB_A"] = comFunc.splitString(TableA, ';') 
    mlbTable["MLB_B"] = comFunc.splitString(TableB, ';') 
    local expect = mark or "0x" ..string.match(data, pattern) 
    if #expect > 2 then
        for key,subTable in pairs(mlbTable) do
            for _,value in pairs(subTable) do
                if string.match(expect, value) ~= nil  then
                   return key
                end
            end   
        end
        return "Unset"
    else
        return "Unset"
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0014:, Version: v0.1, Type:DFU]
Name: DFUCommon.getLocationID(paraTab)
Function description: [v0.1] Function to get locationID and compare slot is match
Input :  Table(paraTab) 
Output : string(locationID)
-----------------------------------------------------------------------------------]]
function DFUCommon.getLocationID(paraTab)
    if not paraTab.InnerCall then
        helper.flowLogStart(paraTab)
    end
    local slot_num = Device.identifier:sub(-1)
    local Regex = Device.getPlugin("Regex")
    local runShellCmd = Device.getPlugin("RunShellCommand")
    local flagIndex = paraTab.flagIndex
    local pattern = paraTab.pattern
    local command = paraTab.Commands -- "system_profiler SPUSBDataType"
    local startTime = os.time()
    local locationID = ""
    local data_end = ""
    local timeout = 10
    local result = true
    if paraTab.Timeout then
        timeout = tonumber(paraTab.Timeout)
    end
    -- pattern = "Apple Mobile Device \(DFU Mode\):[\s\S]+?Location ID: 0x(\S+) /"
    --           "Debug USB:[\s\S]+?Location ID: 0x0?(\S+) /""
    -- flagIndex = -1
    if pattern == nil or flagIndex == nil or command == nil then 
        error("no pattern or flagIndex or command Input.")
    end
    
    repeat
        local data = runShellCmd.run(command)['output']
        local matchs = Regex.groups(data, pattern, 1)
        data_end = data
        -- compare slot_num and locationID, if match break, else repeat 
        if matchs and #matchs > 0 and #matchs[1] > 0 then
            for _, v in pairs(matchs) do
                if v and #v > 0 then
                    local result = v[1]
                    result = string.gsub(result, '0', '')
                    local chr = string.sub(result, tonumber(flagIndex), tonumber(flagIndex))
                    if tonumber(slot_num) == tonumber(chr) then
                        locationID = "0x" .. v[1]
                    end
                end
            end
        end
        -- if locationID == nil or empty delay 100ms.
        if #locationID == 0 then
            comFunc.sleep(0.1)
        end
    -- if locationID is not nil or empaty or is timeout break.
    until (#locationID > 0 or os.difftime(os.time(), startTime) >= timeout)
    -- if not find locationID print last run shell command system info 
    if #locationID == 0 then
        result = false
        helper.flowLogDebug("data_end: " .. data_end)
    end

    local VariableTable = Device.getPlugin("VariableTable")
    VariableTable.setVar("isRestoreFinished", false)
    if not paraTab.InnerCall then
        helper.flowLogFinish(result, paraTab, locationID)
    end
    return locationID
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0015, Version: v0.1, Type:DFU]
Name: DFUCommon.getMLBType(paraTab)
Function description: [v0.1]Function to Check MLB Type with the input string or restore device log(~/Library/Atlas2/Modules/Tech)
Input :  Table(paraTab) 
Output : string(mlb_type)
-----------------------------------------------------------------------------------]]
function DFUCommon.getMLBType(paraTab)
    helper.flowLogStart(paraTab)
    local runShellCmd = Device.getPlugin("RunShellCommand")
    local usb_location = paraTab.Location_ID
    local USBTool = paraTab.USBTool
    local pattern = paraTab.pattern
    local ToolType = paraTab.ToolType
    local mlb_a = paraTab.mlb_a  --0x08 
    local mlb_b = paraTab.mlb_b  --0x0A;0x16;0x12
    local mlb_type = "Unset"

    local data = runShellCmd.run(USBTool).output
    if #data == 0 then
        for i=1,3 do
            data = runShellCmd.run(USBTool).output
            if #data > 0 then
                break
            end
        end
    end
    Log.LogInfo("USBTool--->", USBTool, "output--->"..data)
    
    if ToolType == "ioreg" then
        local dataTab = string.gmatch(data, "%{(.-)%}")
        for v in dataTab do -- dataTab sizes info
            if string.find(v, tostring(tonumber(usb_location))) ~= nil then
               mlb_type = DFUCommon.checkValueInTable(mlb_a, mlb_b, nil, v, pattern) --check value in mlb_a or mlb_b
            end
        end
    else
        --BDID:0A
        pattern = usb_location .. pattern -- use usblocationId match 4 slots
        mlb_type = DFUCommon.checkValueInTable(mlb_a, mlb_b, nil, data, pattern) --check value in mlb_a or mlb_b
    end

    if mlb_type == "Unset" then
        helper.flowLogFinish(false, paraTab, mlb_type, "mlb type miss match")
        helper.reportFailure("mlb type miss match")
    else
        if paraTab.attribute then
            DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, mlb_type))
        end
        helper.flowLogFinish(true, paraTab, mlb_type)
    end
    
    return mlb_type
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0016, Version: v0.1, Type:DFU]
Name: DFUCommon.getCFGType(paraTab)
Function description: [v0.1] Function to get the CFG type and boardRev for CFG_list_path.
Input :  Table(paraTab) 
Output : string(CFG_type, dut_stage, boardRev, dut_cfg)
-----------------------------------------------------------------------------------]]
function DFUCommon.getCFGType(paraTab)
    helper.flowLogStart(paraTab)
    paraTab.InnerCall = true
    local dut_cfg = Common.getSFCQuery(paraTab)  
    local StationInfo = Device.getPlugin("StationInfo")
    local Product = StationInfo.product()
    local dut_stage = "UnSet"
    local CFG_type = "UnSet"
    local plistData = {}
    local failMessge = ""
    local boardRev = ""
    local result = true
    local isSpecial = false
    local CFG_list_path = paraTab.CFG_list_path
    local cfg_type_key = paraTab.cfg_type_key   --ACE_VERSION
    local stageFlag = paraTab.stagebuild -- need add csv param(NPI or MP)
    local stage_pattern = paraTab.stage_pattern

    --get board Rev must use SFC cfg value use stage build flag need use hardcode
    if paraTab.boardRev_pattern and stageFlag == "NPI" then
        local boardRevStr = string.match(dut_cfg, paraTab.boardRev_pattern)
        if #boardRevStr ~= nil then
            boardRev = "0x0" .. boardRevStr:sub(-1)
        else
            failMessge = "boardRev not found"
        end 
    elseif stageFlag == "MP" then
        boardRev = paraTab.boardRev
    end

    -- get dut stage
    if stage_pattern then
        local cfg_info = comFunc.splitString(dut_cfg, "_")  --examplelog : { ["mlb_cfg"] = J410_EVTBU_E0DHU-BU7_0419,} 
        dut_stage = string.match(cfg_info[tonumber(paraTab.cfg_split)], stage_pattern) --EVT
    else
        dut_stage = paraTab.dut_stage 
    end

    local ace3Path = Atlas.assetsPath .. "/Ace3Parameters.plist"

    if comFunc.fileExists(ace3Path) then
        plistData = utils.loadPlist(ace3Path)
    else
        failMessge = "Not found Ace3Parameters.plist"
        helper.flowLogFinish(false, paraTab, nil, failMessge)
        helper.reportFailure(failMessge)
    end

    if dut_cfg and #dut_cfg > 0 and comFunc.fileExists(CFG_list_path) then -- get mlb special ace version make for different mlb cfg in sfc query
        local CFG_list = utils.loadPlist(CFG_list_path)
        for _, cfg in ipairs(CFG_list[cfg_type_key]) do
            cfg = string.gsub(cfg, "-", "%%-")
            if string.find(dut_cfg, cfg) then
                isSpecial = true
                break
            end
        end
    end

    if paraTab.mlb_type and paraTab.mlb_type == "MLB_A" then
            if not isSpecial then
                CFG_type = cfg_type_key .. "_1"
            else
                CFG_type = cfg_type_key .. "_2"
            end
    elseif paraTab.mlb_type and paraTab.mlb_type == "MLB_B" then
            if not isSpecial then
                CFG_type = cfg_type_key .. "_3"
            else
                CFG_type = cfg_type_key .. "_4"
            end
    end

    Log.LogDebug('boardRev$$$$: ' .. boardRev)
    Log.LogDebug('dut_stage$$$$: ' .. dut_stage)
    Log.LogDebug('cfg_type$$$$: ' .. CFG_type)

    if CFG_type == "UnSet" then
        failMessge = "no input sn or get mlb cfg failed"
        result =false
    else
        failMessge = "boardRev not find in Ace3Parameters.plist"
        result =false
        for _,v in ipairs(plistData[Product][dut_stage][CFG_type]) do
            if isSpecial then
                result =true
                boardRev = v["SYS_BREV"]
                break
            elseif v["SYS_BREV"] == boardRev then
                result =true
                break
            end
        end
    end

    if not result then
        helper.flowLogFinish(result, paraTab, CFG_type..", "..dut_stage..", "..boardRev, failMessge)
        helper.reportFailure(failMessge)
    else
        helper.flowLogFinish(result, paraTab, CFG_type..", "..dut_stage..", "..boardRev)
    end

    return CFG_type, dut_stage, boardRev, dut_cfg
end


return DFUCommon
