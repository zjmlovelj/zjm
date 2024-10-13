-------------------------------------------------------------------
----***************************************************************
----Dimension Action Functions
----Created at: 03/01/2021
----Author: Jayson.Ye/Roy.Fang @Microtest
----***************************************************************
-------------------------------------------------------------------
local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local helper = require("Tech/SMTLoggingHelper")
local pListSerialization = require("Serialization/PListSerialization")
local fileUtils = require("ALE/FileUtils")
local versionTab
local VersionCompare = {}

local VersionFiles = {
    "/Users/gdlocal/Library/Atlas2/Assets/VersionCompare.txt", "/Users/gdlocal/Library/Atlas2/Assets/EEEE_Code.txt"
}

local StationInfo = Atlas.loadPlugin("StationInfo")
local Product = StationInfo.product()
local VersionComparePath = "/Users/gdlocal/Library/Atlas2/Assets/VersionCompare_" .. Product .. ".txt"
local EEEE_CodePath = "/Users/gdlocal/Library/Atlas2/Assets/EEEE_Code_" .. Product .. ".txt"
if comFunc.fileExists(VersionComparePath) and comFunc.fileExists(EEEE_CodePath) then
    VersionFiles = {VersionComparePath, EEEE_CodePath}
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0069:, Version: v0.1, Type:Inner]
Name: VersionCompare.getVersions
Function description: [v0.1]  Function to parse the VersionCompare file.
Input : N/A
Output : versionTab(table)
-----------------------------------------------------------------------------------]]

function VersionCompare.getVersions()
    if versionTab == nil then
        versionTab = {}
        for _, path in ipairs(VersionFiles) do
            local content = comFunc.fileRead(path)
            local rows = comFunc.splitString(content, '\n')
            local key
            local index = 1
            for _, row in ipairs(rows) do
                local linearr = comFunc.splitString(row, ':')
                if #linearr == 2 then
                    key = linearr[1]
                    if linearr[2] ~= "" then
                        versionTab[key] = comFunc.trim(linearr[2])
                    else
                        versionTab[key] = {}
                        index = 1
                    end
                elseif row ~= "" then
                    versionTab[key][index] = comFunc.trim(row)
                    index = index + 1
                end
            end
        end
        -- Log.LogInfo("VersionCompare:  " .. comFunc.dump(VersionFiles) .. '\n')
        Log.LogInfo("VersionCompare:  " .. comFunc.dump(versionTab) .. '\n')
    end
    return versionTab
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0046, Version: v0.1, Type:DFU]
Name: VersionCompare.CompareTiCCMD5(paraTab)
Function description: [v0.1]Function to Compare the GrapeFW/BT_FW/WIFI_FW/RTOS_Version/RBM_Version/WSKU/RFEM/EEEE_CODE 
                            with the VersionCompare file.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function VersionCompare.versionCompare(paraTab)
    helper.flowLogStart(paraTab)
    local input = paraTab.Input
    local key = paraTab.comparekey
    local compareFunc = paraTab.compareFunc
    local result = false
    local retMsg = nil

    if input ~= nil then
        if key then
            local versions = VersionCompare.getVersions()[key]
            if not versions then
                retMsg = 'compare value not found'
                helper.flowLogFinish(false, paraTab, versions, retMsg)
                helper.reportFailure(retMsg)
            end
            helper.LogInfo(key .. ": " .. comFunc.dump(versions) .. '\n')

            local func = VersionCompare[compareFunc]
            if func then
                result, retMsg = func(paraTab, versions)
            else
                retMsg = 'compareFunc[' .. compareFunc .. '] error'
            end
        else
            retMsg = 'miss comparekey'
        end
    else
        retMsg = 'miss input value'
    end
    if result then
        helper.flowLogFinish(true, paraTab)
    else
        helper.flowLogFinish(false, paraTab, nil, retMsg)
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0070:, Version: v0.1, Type:Inner]
Name: VersionCompare.grapeFWCompare
Function description: [v0.1]  Function to compare the GrapeFW with the VersionCompare file.
Input :Table(paraTab), table
Output : bool, string
-----------------------------------------------------------------------------------]]

function VersionCompare.grapeFWCompare(paraTab, versions)
    local result
    local failureMsg
    local touch_firmware = paraTab.Input
    if touch_firmware ~= nil then
        failureMsg = touch_firmware
        helper.LogInfo("TOUCH_FIRMWARE=" .. touch_firmware .. '\n')
        helper.LogInfo("GrapeFW: " .. comFunc.dump(versions) .. '\n')
        result = versions == touch_firmware
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result, failureMsg
end
--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0071:, Version: v0.1, Type:Inner]
Name: VersionCompare.grapeFWCompare
Function description: [v0.1]  Function to compare the BT FW with the VersionCompare file.
Input :Table(paraTab), table
Output : bool, string
-----------------------------------------------------------------------------------]]

function VersionCompare.btFWCompare(paraTab, versions)
    local result = false
    local failureMsg
    local wifi_module_version = paraTab.Input
    local bt_firmware = paraTab.BT_FIRMWARE
    if wifi_module_version ~= nil and bt_firmware ~= nil then
        helper.LogInfo("WIFI_Module_Version=" .. wifi_module_version .. '\n')
        helper.LogInfo("BT_FIRMWARE=" .. bt_firmware .. '\n')
        failureMsg = "wifi[" .. wifi_module_version .. "] bt[" .. bt_firmware .. "]"
        helper.LogInfo("BT FW: " .. comFunc.dump(versions) .. '\n')
        for _, version in ipairs(versions) do
            local arr = comFunc.splitString(version, '\t')
            if string.find(arr[1], wifi_module_version) ~= nil and string.find(arr[2], bt_firmware) ~= nil then
                helper.LogInfo("Match: " .. version .. '\n')
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result, failureMsg
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0072:, Version: v0.1, Type:Inner]
Name: VersionCompare.wifiFWCompare
Function description: [v0.1] Function to compare the WIFI FW with the VersionCompare file.
Input :Table(paraTab), table
Output : bool, string
-----------------------------------------------------------------------------------]]

function VersionCompare.wifiFWCompare(paraTab, versions)
    local result = false
    local failureMsg
    local wifi_module_version = paraTab.Input
    local wifi_firmware = paraTab.WIFI_FIRMWARE
    local wifi_nvram = paraTab.WIFI_NVRAM
    if wifi_module_version ~= nil and wifi_firmware ~= nil and wifi_nvram ~= nil then
        helper.LogInfo("WIFI_Module_Version=" .. wifi_module_version .. '\n')
        helper.LogInfo("WIFI_FIRMWARE=" .. wifi_firmware .. '\n')
        helper.LogInfo("WIFI_NVRAM=" .. wifi_nvram .. '\n')
        helper.LogInfo("WIFI FW: " .. comFunc.dump(versions) .. '\n')
        failureMsg = "WIFI_Module_Version[" .. wifi_module_version .. "] WIFI_FIRMWARE[" .. wifi_firmware .. "] WIFI_NVRAM[" ..
                         wifi_nvram .. "]"
        for _, version in ipairs(versions) do
            local arr = comFunc.splitString(version, '\t')
            if string.find(arr[1], wifi_module_version) ~= nil and string.find(arr[2], wifi_firmware) ~= nil and
                string.find(arr[3], wifi_nvram) ~= nil then
                    helper.LogInfo("Match: " .. version .. '\n')
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result, failureMsg
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0073:, Version: v0.1, Type:Inner]
Name: VersionCompare.rtosVersionCompare
Function description: [v0.1] Function to compare the RTOS Version with the VersionCompare file.
Input :Table(paraTab), table
Output : bool, string
-----------------------------------------------------------------------------------]]

function VersionCompare.rtosVersionCompare(paraTab, versions)
    local result
    local failureMsg
    local rtos_version = paraTab.Input
    if rtos_version ~= nil then
        failureMsg = rtos_version
        helper.LogInfo("rtos_version=" .. rtos_version .. '\n')
        helper.LogInfo("RTOS: " .. comFunc.dump(versions) .. '\n')
        result = rtos_version == versions
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result, failureMsg
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0074:, Version: v0.1, Type:Inner]
Name: VersionCompare.rbmVersionCompare
Function description: [v0.1] Function to compare the RBM Version with the VersionCompare file.
Input :Table(paraTab), table
Output : bool, string
-----------------------------------------------------------------------------------]]

function VersionCompare.rbmVersionCompare(paraTab, versions)
    local result = false
    local failureMsg
    local rbm_version = paraTab.Input
    local ret = ""
    ret = string.gsub(rbm_version, "%:", "_")
    ret = string.gsub(ret, "%|", "_")
    ret = string.gsub(ret, "%/", "_")
    Log.LogInfo("$$$$$ret11222", ret)

    if ret ~= nil then
        failureMsg = ret
        helper.LogInfo("ret=" .. ret .. '\n')
        helper.LogInfo("RBMVersionList: " .. comFunc.dump(versions) .. '\n')
        ret = string.gsub(ret, "([%^%$%(%)%%%[%]%+%-%?])", "%%%1")
        helper.LogInfo("rbm_version try=" .. ret .. '\n')
        for _, version in ipairs(versions) do
            if string.find(version, ret) then
                helper.LogInfo("Match: " .. version .. '\n')
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result, failureMsg
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0075:, Version: v0.1, Type:Inner]
Name: VersionCompare.wskuVersionCompare
Function description: [v0.1] Function to compare the WSKU Version with the VersionCompare file.
Input :Table(paraTab), table
Output : bool, string
-----------------------------------------------------------------------------------]]

function VersionCompare.wskuVersionCompare(paraTab, versions)
    local Regex = Device.getPlugin("Regex")
    local result = false
    local failureMsg = nil
    local wsku_value = paraTab.Input
    local sn = paraTab.MLB_Num
    local smokey_wdfu_resp = tostring(paraTab.smokey_WDFU_resp)
    local pattern = paraTab.pattern
    local sku = ""
    if sn and #sn > 0 then
        local eeeecode = string.sub(sn, 12, 18)
        local eeeecode_versions = VersionCompare.getVersions()["EEEE_CODE"]
        for _, versionValue in ipairs(eeeecode_versions) do
            if string.find(versionValue, eeeecode) then
                local eeeecode_info = comFunc.splitString(versionValue, " ")
                if eeeecode_info[7] then
                    sku = eeeecode_info[7] .. " "
                end
                break
            end
        end

        if pattern then
            local matchs = Regex.groups(smokey_wdfu_resp, pattern, 1)
            if #(matchs[1]) > 0 then
                sku = sku .. matchs[1][1]
            end
        end

        wsku_value = string.match(wsku_value, "(.*) ")
        helper.LogInfo("target: " .. sku .. "    " .. wsku_value .. '\n')

        failureMsg = sku .. "    " .. wsku_value
        for _, version in ipairs(versions) do
            if string.find(version, sku) ~= nil and string.find(version, wsku_value) ~= nil then
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result, failureMsg
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0076:, Version: v0.1, Type:Inner]
Name: VersionCompare.rfemVersionCompare
Function description: [v0.1] Function to compare the RFEM Version with the VersionCompare file.
Input :Table(paraTab), table
Output : bool, string
-----------------------------------------------------------------------------------]]

function VersionCompare.rfemVersionCompare(paraTab, versions)
    local result = false
    local failureMsg
    local rfem_val = paraTab.Input
    if rfem_val ~= nil then
        helper.LogInfo("target: " .. rfem_val .. '\n')
        failureMsg = rfem_val
        for _, version in ipairs(versions) do
            if version == rfem_val then
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result, failureMsg
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0077:, Version: v0.1, Type:Inner]
Name: VersionCompare.eeeecodeCompare
Function description: [v0.1] Function to compare the BOARD_ID/NAND_SIZE/MEMORY_SIZE with eeeecode 
                             and the VersionCompare file and SFC compare.
Input :Table(paraTab), table
Output : bool, string
-----------------------------------------------------------------------------------]]

function VersionCompare.eeeecodeCompare(paraTab, versions)
    local result = false
    local failureMsg = ""
    local sn = tostring(paraTab.MLB_Num)
    local boardid = paraTab.BOARD_ID
    local memorysize = paraTab.MEMORY_SIZE
    local mlb_type = paraTab.mlb_type
    local nandsize = paraTab.NAND_Capacity
    local sfc_url = paraTab.sfc_url
    local pattern = paraTab.pattern
    local eeee_code
    
    if #sn > 0 then
        eeee_code = string.sub(sn, 12, 18)
    end

    if sfc_url ~= nil then
        local command = "curl \'" .. sfc_url .. "c=QUERY_RECORD" .. "&sn=".. sn .. "&p=eee_model&bios_sn=" .. eeee_code .. "\'"
        helper.LogInfo("7E code command : " .. command)
        local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
        local status, sfc_resp = xpcall(RunShellCommand.run, debug.traceback, command)
        if not status then
            helper.reportFailure(sfc_resp)
        end
        local mlb_type_sfc = ""
        local Nand_Size_sfc = ""
        local sfc_data = comFunc.dump(sfc_resp)
        helper.LogInfo("7E code sfc_data : " .. tostring(sfc_data))
        local Nand_Size_sfc_data = string.match(sfc_data,"eee_model=(%w+)")
        if string.find(Nand_Size_sfc_data,'TB') then
            Nand_Size_sfc = Nand_Size_sfc_data
        else
            Nand_Size_sfc = Nand_Size_sfc_data .. "B"
        end
        if string.find(sfc_data,'CH') then
            mlb_type_sfc = mlb_type
        else
            mlb_type_sfc = "MLB_" .. string.match(tostring(sfc_data),pattern)
        end
        if mlb_type ~= nil then
            if Nand_Size_sfc ~= nandsize or mlb_type_sfc ~= mlb_type then
                failureMsg = "error result: Nand_Size_sfc or mlb_type_sfc is mismatch to sfc"
                helper.reportFailure(failureMsg)
            end
        end
    end

    if sn ~= nil and boardid ~= nil and nandsize ~= nil and memorysize ~= nil and eeee_code ~= nil then
        local value = eeee_code .. ' ' .. boardid .. ' ' .. nandsize .. ' ' .. memorysize
        failureMsg = value
        helper.LogInfo("current: " .. value .. '\n')
        for _, versionValue in ipairs(versions) do
            if string.find(versionValue, value) then
                result = true
                break
            end
        end
    else
        result = false
        failureMsg = 'input value missing'
    end
    return result, failureMsg
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0078:, Version: v0.1, Type:Inner]
Name: VersionCompare.getNandSizeFromUartLog
Function description: [v0.1] Function to get the nand size from uart log
Input :Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function VersionCompare.getNandSizeFromUartLog(paraTab)
    helper.flowLogStart(paraTab)
    local logFile = Device.userDirectory .. "/" .. paraTab.logFile
    local ret = string.format("%q",comFunc.fileRead(logFile))
    local nandsize = "0GB"
    local nandsize0 = string.match(ret, 'Identified Storage Device 0[%S%s]-(%d+)GB')
    if nandsize0 and #nandsize0 > 0 then
        -- nandsize = nandsize0 .. 'GB'
        -- helper.LogInfo("getNandSize nand0 " .. nandsize)
        -- -- else
        -- --     result = false
        -- --     failureMsg = "nand0 match failed"
        local nandsizes = tonumber(nandsize0)
        if nandsizes >= 1024 then 
            nandsize = tostring(nandsizes / 1024) ..'TB'
            helper.LogInfo("getNandSize0 nand " .. nandsize)
            if string.find(nandsize,".0TB") then
                nandsize = string.gsub(nandsize, '.0TB', 'TB')
            end
        else
            nandsize = tostring(nandsizes) .. 'GB'
            helper.LogInfo("getNandSize0 nand2 " .. nandsize)
        end
    end

    if string.find(ret, 'number of storage devices 2') then
        local nandsize1 = string.match(ret, 'Identified Storage Device 1[%S%s]-(%d+)GB')
        if nandsize1 and #nandsize1 > 0 then
            helper.LogInfo("getNandSize1 nand " .. nandsize1 .. "GB")
            
            local nandsizes = tonumber(nandsize0) + tonumber(nandsize1)     
            if nandsizes >= 1024 then 
                nandsize = tostring(nandsizes / 1024) ..'TB'
                helper.LogInfo("getNandSize1 nand " .. nandsize)
                if string.find(nandsize,".0TB") then
                    nandsize = string.gsub(nandsize, '.0TB', 'TB')
                end
            else
                nandsize = tostring(nandsizes) .. 'GB'
                helper.LogInfo("getNandSize nand2 " .. nandsize)
            end
        end
    end
    helper.LogInfo("getNandSize total " .. nandsize)
    if paraTab.isCreateRecord == "YES" then
        if #nandsize > 0 then
            if (paraTab.attribute) then
                DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, nandsize))
            end
        else
            helper.reportFailure("nandsize is null")
        end
    end
    if nandsize0 then
        helper.flowLogFinish(true, paraTab, nandsize)
    else
        helper.flowLogFinish(false, paraTab, nandsize, "Not Found NAND Size")
    end        
    return nandsize
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0080:, Version: v0.1, Type:Inner]
Name: VersionCompare.getExpectedVersionWithKey
Function description: [v0.1] Function to get expected version with key.
Input :Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function VersionCompare.getExpectedVersionWithKey(paraTab)
    local key = paraTab.key
    local version = ""
    local result = false
    local failureMsg = ""
    if key then
        version = VersionCompare.getVersions()[key]
        if version and #version > 0 then
            result = true
        else
            failureMsg = "value not found"
        end
    else
        failureMsg = "key missing"
    end

    if not result then
        helper.createRecord(result, paraTab, failureMsg, nil, nil, false)
        helper.reportFailure(failureMsg)
    else
        helper.logTestAction(version, paraTab)
    end
    return version
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0081:, Version: v0.1, Type:Inner]
Name: VersionCompare.boardRevsionCompare
Function description: [v0.1] Function to compare the boardRev Version in the uart log file.
Input :Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function VersionCompare.boardRevsionCompare(paraTab)
    local log_device = tostring(paraTab.log_device) or 'uart'
    local log_path = ''
    local dutBoardRev
    if log_device == 'restore_device' then
        log_path = Restore.getRestoreDeviceLogPath()
    elseif log_device == 'restore_host' then
        log_path = Restore.getRestoreHostLogPath()
    else
        log_path = Device.userDirectory .. '/'..log_device ..'.log'
    end
    helper.LogInfo("log_path: ", log_path)
    local host_log = string.format("%q",comFunc.fileRead(log_path))
    host_log = string.gsub(host_log, "\\\n", "\n")
    if paraTab.pattern ~= nil then
        local Regex = Device.getPlugin("Regex")
        local pattern = paraTab.pattern
        local matchs = Regex.groups(host_log, pattern, 1)
        if matchs and #matchs > 0 and #matchs[1] > 0 then
            dutBoardRev = matchs[1][1]
        else
            dutBoardRev = 'match failed'
        end
    elseif paraTab.luapattern ~= nil then
        local luaPattern = paraTab.luapattern
        dutBoardRev = string.match(host_log, luaPattern)
        if not dutBoardRev then
            dutBoardRev = 'match failed'
        end
    end
    helper.LogInfo("dutBoardRev$$$$: ", dutBoardRev)
    helper.LogInfo("paraTab.InputDict$$$$: ", comFunc.dump(paraTab.InputDict))
    local cfgType = paraTab.InputDict["CFG_type"]
    local buildStage = paraTab.InputDict["DUT_stage"]
    local product = paraTab.InputDict["Product"]
    local configPath = Atlas.assetsPath
    local plistData
    if comFunc.fileExists(configPath .. "/Ace3Parameters.plist") then
        plistData = pListSerialization.LoadFromFile(configPath .. "/Ace3Parameters.plist")
    end
    local localInfo = plistData[product][buildStage][cfgType]
    helper.LogInfo("localInfo$$$$: ", comFunc.dump(localInfo))
    local flag = false
    for _,v in ipairs(localInfo) do
        if v["SYS_BREV"] == dutBoardRev then
            flag = true
            break
        end
    end
    if paraTab.attribute ~= nil and dutBoardRev then
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, dutBoardRev))
    end
    if flag then
        helper.logTestAction(dutBoardRev, paraTab)
    else
        helper.createRecord(flag, paraTab, "compare error", nil, nil, false)
        helper.reportFailure("compare error")
    end

    return dutBoardRev
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0082:, Version: v0.1, Type:Inner]
Name: VersionCompare.RevMD5Compare
Function description: [v0.1] Function to compare the Rev MD5 in the RestorePackage file.
Input :Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function VersionCompare.RevMD5Compare(paraTab)
    local runShellCmd = Device.getPlugin("RunShellCommand")
    local ChipRev = paraTab.Input
    local product_A = string.lower(Product)
    local Product_B = "j"..tostring(tonumber((string.gsub(Product, "J", ""))) + 1 )
    local rtos_md5 = VersionCompare.getVersions()[ChipRev .. "_RTOS_MD5"]
    local rbm_md5 = VersionCompare.getVersions()[ChipRev .. "_RBM_MD5"]
    local rtos_md5_list = comFunc.splitString(rtos_md5, ";")
    local rbm_md5_list = comFunc.splitString(rbm_md5, ";")
    local path = "/Users/gdlocal/RestorePackage/CurrentBundle/Restore/FactoryTests/"
    local resultFlag = true
    local failureMsg = nil
    local pathTable, md5Table = {}, {}

    pathTable[1] = path .. product_A .. "/console." .. product_A .. ".im4p"    --rtos
    pathTable[2] = path .. Product_B .. "/console." .. Product_B .. ".im4p"
    pathTable[3] = path .. product_A .. "/rbm." .. product_A .. ".im4p"       --rbm
    pathTable[4] = path .. Product_B .. "/rbm." .. Product_B .. ".im4p"

    helper.LogInfo("rtos_md5$$$$: ", rtos_md5)
    helper.LogInfo("rbm_md5$$$$: ", rbm_md5)

    for i=1,#pathTable do
        md5Table[i] = string.match(runShellCmd.run("/sbin/md5 " .. pathTable[i]).output, "MD5.-=%s(%w+)")
    end

    if string.match(rtos_md5, ";") ~= nil then
        if rtos_md5_list[1] ~= md5Table[1] or rtos_md5_list[2] ~= md5Table[2] then
            resultFlag = false
            failureMsg = "compare failed; expect [" .. rtos_md5 .. "] got [" .. md5Table[1] .. "] and [" .. md5Table[2] .. "]"
        end
    else
        if rtos_md5 ~= md5Table[1] or rtos_md5 ~= md5Table[2] then
            resultFlag = false
            failureMsg = "compare failed; expect [" .. rtos_md5 .. "] got [" .. md5Table[1] .. "] and [" .. md5Table[2] .. "]"
        end
    end

    if string.match(rbm_md5, ";") ~= nil then
        if rbm_md5_list[1] ~= md5Table[3] or rbm_md5_list[2] ~= md5Table[4] then
            resultFlag = false
            failureMsg = "compare failed; expect [" .. rbm_md5 .. "] got [" .. md5Table[3] .. "] and [" .. md5Table[4] .. "]"
        end
    else
        if rbm_md5 ~= md5Table[3] or rbm_md5 ~= md5Table[4] then
            resultFlag = false
            failureMsg = "compare failed; expect [" .. rbm_md5 .. "] got [" .. md5Table[3] .. "] and [" .. md5Table[4] .. "]"
        end
    end

    return resultFlag, failureMsg
end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0038, Version: v0.1, Type:DFU]
Name: VersionCompare.writeAndCompareInfo(paraTab)
Function description: [v0.1]Function to write and compare info for dut.
Input : 
Output : string
-----------------------------------------------------------------------------------]]
function VersionCompare.writeAndCompareInfo(paraTab)
    helper.flowLogStart(paraTab)

    local dutPluginName = paraTab.dutPluginName
    local dut = Device.getPlugin(dutPluginName)
    local value = paraTab.Input
    local type = paraTab.type    --MLB or CFG
    local attribute = paraTab.attribute
    local expect = paraTab.expect    -- Finish!
    local resultFlag = true
    local failureMsg = nil
    local status = nil
    local result = nil

    if not paraTab.Input then
        local common = require("Tech/Common")
        value = common.getSFCQuery(paraTab)
    end 

    if not value then
        helper.flowLogFinish(false, paraTab, value, 'miss Input Vaule')
        helper.reportFailure("miss Input Vaule")
    end    

    if value and paraTab.attribute then
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, value))
    end
    
    if type and dutPluginName then 
       helper.LogDutCommStart("syscfg add ".. type .. "# " .. value)
       status, result = xpcall(dut.send, debug.traceback, "syscfg add ".. type .. "# " .. value, 3)
       helper.LogDutCommFinish(result)
       
       if (not status) and (not result) and (not string.find(result, expect)) then 
            resultFlag = false
            failureMsg = "cannot find 'Finish!' in response"
       end

       helper.LogDutCommStart("syscfg print ".. type .. "#")
       status, result = xpcall(dut.send, debug.traceback, "syscfg print ".. type .. "#", 3)
       helper.LogDutCommFinish(result)
       
       if (not status) and (not result) then 
            resultFlag = false
            failureMsg = "Read CMD fail."
       end
       
       if type == "CFG" then value = string.gsub(value, "-", "%%-") end


       if string.match(result, value) == nil then
           resultFlag = false
           failureMsg = "Value Not Same"
       end

       if result and value and resultFlag then
           helper.flowLogFinish(true, paraTab, value)
       else
           helper.flowLogFinish(false, paraTab, value, failureMsg)
       end

    end   

    return value
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0047, Version: v0.1, Type:Common]
Name: VersionCompare.CompareInfo(paraTab)
Function description: [v0.1]Function to compare info for dut.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function VersionCompare.CompareInfo(paraTab)
    helper.flowLogStart(paraTab)
    local luaName = paraTab.luaName
    local firstValue = paraTab.firstValue
    local secondValue = paraTab.secondValue
    local type = paraTab.type
    local attribute = paraTab.attribute
    local status = false
    local functions = nil

    assert(secondValue ~= nil, "Error: secondValue is null!")

    if luaName == "dutCmd" then 
        local dutCmd = require("Tech/DUTCmd")
        functions = dutCmd[paraTab.functions]
    end    

    if firstValue == nil and functions then
        status, firstValue = xpcall(functions, debug.traceback, paraTab)
        helper.LogInfo("firstValue$$$$: ", tostring(firstValue))

        if not status or firstValue == nil then
            helper.flowLogFinish(false, paraTab, firstValue, 'functions miss firstValue')
            helper.reportFailure("functions miss firstValue")
        end
    end

    if type == "Upper" then
        firstValue = string.upper(firstValue)
        secondValue = string.upper(secondValue)
    elseif type == "Reverse" then
        local str = ""
        if firstValue then
            local firstValueTable = comFunc.splitString(firstValue," ")
            for i=0, #firstValueTable-1 do
                str = str .. firstValueTable[#firstValueTable-i]
            end
            firstValue = "0x" .. str
        end   
    end    
    
    helper.LogInfo("firstValue$$$$: ", tostring(firstValue))
    helper.LogInfo("secondValue$$$$: ", tostring(secondValue))

    if tostring(firstValue) == tostring(secondValue) then
        if paraTab.attribute then
            DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, tostring(firstValue)))
        end
        helper.flowLogFinish(true, paraTab, firstValue)
    else
        helper.flowLogFinish(false, paraTab, firstValue, 'Value Not Same')
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0048, Version: v0.1, Type:DFU]
Name: VersionCompare.CompareTiCCMD5(paraTab)
Function description: [v0.1]Function to compare dut ticc bin file and file from sfc.
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function VersionCompare.CompareTiCCMD5(paraTab)
    helper.flowLogStart(paraTab)
    local dut = Device.getPlugin(paraTab.dutPlugin)
    local fdr = Device.getPlugin("FDR")
    local usbfs = Device.getPlugin('USBFS')
    local utilities =  Device.getPlugin("Utilities")
    local runShellCmd = Device.getPlugin("RunShellCommand")
    local slot_num = tostring(Device.systemIndex + 1)
    local toolPath = paraTab.toolPath .. slot_num
    local filePath = paraTab.filePath
    local timeout = tonumber(paraTab.Timeout)
    local ticc_sn = paraTab.TiCC_SN
    local chip_id = paraTab.Chip_ID
    local ecid = paraTab.ECID
    local fileName = paraTab.fileName
    local ticcFilePath = fileUtils.joinPaths(Device.userDirectory, fileName)
    local getFilePath = fileUtils.joinPaths(Device.userDirectory, "get.bin")
    local resultFlag = true
    local failureMsg = nil
    local status = ""
    local result = ""

    assert(ticc_sn ~= nil, "ticc_sn is null")

    dut.setDelimiter("] :-) ")
    usbfs.setHostToolPath(toolPath)
    usbfs.setDebugFlag(true)
    usbfs.setDefaultTimeout(timeout)

    status, result = xpcall(usbfs.copyToHost, debug.traceback, dut, Device.userDirectory, {[filePath] = fileName})

    if not status then
        resultFlag = false
        failureMsg = "usbfs copyToHost error"
    end    

    local uniqueID = "0000" .. string.gsub(chip_id .. "-" .. ecid, "0x", "")   --00008130-0018318A2680011C

    local uploadData = utilities.readDataFromFile(ticcFilePath)

    local localFileMD5 = string.match(runShellCmd.run("/sbin/md5 " .. ticcFilePath)['output'],"MD5.-=%s(%w+)")

    status, result = xpcall(fdr.putIntoFDR, debug.traceback, "0grp", uniqueID, uploadData)

    if not status then
        resultFlag = false
        failureMsg = failureMsg .. " usbfs putIntoFDR error"
    end    

    status, result = xpcall(fdr.copyFromFDR, debug.traceback, "0grp", uniqueID)

    if not status then
        resultFlag = false
        failureMsg = failureMsg .. " usbfs copyFromFDR error"
    end    

    utilities.writeDataToFile(getFilePath, result)

    local getFileMD5 = string.match(runShellCmd.run("/sbin/md5 " .. getFilePath)['output'],"MD5.-=%s(%w+)")

    if tostring(localFileMD5) ~= tostring(getFileMD5) then
        resultFlag = false
        failureMsg = "compare error, get md5 [" .. getFileMD5 .. "] not compare md5 [" .. localFileMD5 .. "]"
    end

    helper.flowLogFinish(resultFlag, paraTab, getFileMD5, failureMsg)
end

return VersionCompare
