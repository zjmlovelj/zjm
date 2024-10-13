local SBin = {}
local ftcsv = require "Tech/ftcsv"
local dutCmd = require("Tech/DUTCmd")
local helper = require("Tech/SMTLoggingHelper")
local comFunc = require("Tech/CommonFunc")
local DFUCommon = require("Tech/DFUCommon")
local utils = require("Tech/utils")
local Log = require("Tech/logging")

--[[---------------------------------------------------------------------------------
-- loadFuseConfig(sbinKey, operation)
-- Function to load fuse config csv file
-- Created By : JW
-- Initial Creation Date : 14/12/2023
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : PRM
-- Primary Usage : DFU
-----------------------------------------------------------------------------------]]
local function loadFuseConfig(paraTab)
    local binFuseConfigFiles = paraTab.binFuseConfigFiles
    local csvTable = ''
    if comFunc.fileExists(binFuseConfigFiles) then
        csvTable = ftcsv.parse(binFuseConfigFiles,",",{["headers"] = true,})
    end
    return csvTable
end

--[[---------------------------------------------------------------------------------
-- compareTimesWithPattern(result, pattern)
-- Function to get times of compare pattern from result
-- Created By : JW
-- Initial Creation Date : 14/12/2023
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : PRM
-- Primary Usage : DFU
-----------------------------------------------------------------------------------]]

local function compareTimesWithPattern(result, pattern)
    local matchs = string.gmatch(result, pattern)
    local times = 0
    for i in matchs do
        if i and #i > 0 then
            times = times +1
        end
    end
    return times
end

--[[---------------------------------------------------------------------------------
-- SBin.getPcore(paraTab)
-- Function to get Pcore
-- Created By : JW
-- Initial Creation Date : 14/12/2023
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : PRM
-- Primary Usage : DFU
-- Input Arguments : table
-- Output Arguments : string
-----------------------------------------------------------------------------------]]
function SBin.getPcore(paraTab)
    helper.flowLogStart(paraTab)
    local Pcore = '0'
    local failureMsg = ""
    local acc0Value = paraTab.acc0Value or ''
    local acc1Value = paraTab.acc1Value or ''
    local resultFlag = false
    helper.LogInfo("acc0Value >>>>>: ",acc0Value)
    helper.LogInfo("acc1Value >>>>>: ",acc1Value)
    if #acc1Value > 0 and #acc1Value > 0 then
        local ret = tonumber(tonumber(acc0Value,2) | tonumber(acc1Value,2))
        helper.LogInfo("ret1 >>>>>: ",tostring(ret))
        ret = comFunc.byteToBin(ret)
        helper.LogInfo("ret2 >>>>>: ",tostring(ret))
        local times = compareTimesWithPattern(ret, "1")
        if times == 1 then
            Pcore = "3"
        elseif times == 0 then
            Pcore = "4"
        end
        resultFlag = true
    else
        failureMsg = 'acc0Value or acc1Value is null'
    end
    if (paraTab.attribute) then
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, Pcore))
    end
    helper.flowLogFinish(resultFlag, paraTab, tonumber(Pcore), failureMsg)
    return Pcore
end

--[[---------------------------------------------------------------------------------
-- SBin.getSbinKey( paraTab )
-- Function to get SbinValue with binFuse and memorySize
-- Created By : JW
-- Initial Creation Date : 14/12/2023
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : PRM
-- Primary Usage : DFU
-- Input Arguments : table
-- Output Arguments : number
-----------------------------------------------------------------------------------]]

function SBin.getSbinKey(paraTab)
    helper.flowLogStart(paraTab)
    local resultFlag = false
    local failureMsg = ''
    local SbinKey = '-999'
    local FuseRev = paraTab.InputValues1
    local dramSize = paraTab.InputValues2
    helper.LogInfo("FuseRev >>>>>: ",FuseRev)
    helper.LogInfo("dramSize >>>>>: ",dramSize)
    if FuseRev ~= nil and dramSize ~= nil then
        local fuseConfigTable = loadFuseConfig(paraTab)
        if fuseConfigTable then
            for _,v in ipairs(fuseConfigTable) do
                if v["Fuse_Rev"] == FuseRev and v["DRAM_Size"] == dramSize then
                    SbinKey = v["SBIN_Value"]
                    resultFlag = true
                    break
                end
            end
        else
            failureMsg = 'load csv error'
        end
    else
        failureMsg = 'FuseRev or dramSize is empty'
    end

    if (paraTab.attribute) then
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, SbinKey))
    end

    if resultFlag then
        helper.flowLogFinish(resultFlag, paraTab,tonumber(SbinKey))
    else
        helper.flowLogFinish(resultFlag, paraTab, tonumber(SbinKey), failureMsg)
        helper.reportFailure(failureMsg)
    end
    return tonumber(SbinKey)
end

--[[---------------------------------------------------------------------------------
-- SBin.checkBinFuseWithCFG(paraTab)
-- Function to check bin fuse with CFG
-- Created By : JW
-- Initial Creation Date : 04/12/2023
-- Modified By : JW
-- Modification Date : 14/12/2023
-- Current_Version : 1.1
-- Changes from Previous version : Initial Version
-- Vendor_Name : PRM
-- Primary Usage : DFU
-----------------------------------------------------------------------------------]]

function SBin.checkBinFuseWithCFG(paraTab)
    helper.flowLogStart(paraTab)
    local failureMsg = ""
    local resultFlag = false
    local check_list_path = paraTab.cfgListPath or "/Users/gdlocal/Library/Atlas2/supportFiles/Bin_cfg.plist"
    local dut_cfg = paraTab.dut_cfg
    local bin_fuse = paraTab.bin_fuse
    local dut_cfg_pattern = paraTab.cfg_pattern
    local Bin_cfg = string.match(dut_cfg,dut_cfg_pattern)
    if bin_fuse then
        if comFunc.fileExists(check_list_path) then
            local bin_fuse_plist_data = utils.loadPlist(check_list_path)
            helper.LogInfo("bin_fuse_plist_data:>>" .. comFunc.dump(bin_fuse_plist_data))
            if bin_fuse_plist_data[tostring(bin_fuse)] ~= nil then
                local data = bin_fuse_plist_data[tostring(bin_fuse)]
                helper.LogInfo("data:>>" .. comFunc.dump(data))
                if #data > 0 then
                    for _,cfg in ipairs(data) do
                        cfg = string.gsub(cfg, "-", "%%-")
                        if string.find(Bin_cfg,cfg) ~= nil then
                            resultFlag = true
                            break
                        end
                    end
                else
                    resultFlag = true
                end
            else
                failureMsg = 'compare failed, not found bin key'
            end
        else
            failureMsg = check_list_path .. " not found"
        end
    else
        failureMsg = 'bin_fuse is empty'
    end

    if resultFlag then
        helper.flowLogFinish(resultFlag, paraTab)
    else
        helper.flowLogFinish(resultFlag, paraTab, bin_fuse, failureMsg)
        helper.reportFailure(failureMsg)
    end
end

--[[---------------------------------------------------------------------------------
-- SBin.compareBinFuseConfig(paraTab)
-- Function to compare the bin fuse config with the csv file.
-- Created By : JW
-- Initial Creation Date : 22/11/2023
-- Modified By : JW
-- Modification Date : 14/12/2023
-- Current_Version : 1.1
-- Changes from Previous version : Initial Version
-- Vendor_Name : PRM
-- Primary Usage : DFU
-----------------------------------------------------------------------------------]]

function SBin.compareBinFuseConfig(paraTab)
    helper.flowLogStart(paraTab)
    local resultFlag = false
    local failureMsg = ''
    local binValue = paraTab.binValue
    binValue = tostring(binValue)
    local fuseRev = paraTab.fuseRev
    local dramSize = paraTab.dramSize
    local Pcore = paraTab.Pcore
    local nandSize = paraTab.nandSize

    Log.LogInfo("binValue >>>>>: ",binValue)
    Log.LogInfo("fuseRev >>>>>: ",fuseRev)
    Log.LogInfo("dramSize >>>>>: ",dramSize)
    Log.LogInfo("Pcore >>>>>: ",Pcore)
    Log.LogInfo("nandSize >>>>>: ",nandSize)

    if binValue ~= nil and fuseRev ~= nil and dramSize ~= nil and Pcore ~= nil and nandSize ~= nil then
        local fuseConfigTable = loadFuseConfig(paraTab)
        if fuseConfigTable then
            for _,v in ipairs(fuseConfigTable) do
                if v["SBIN_Value"] == binValue and v["Fuse_Rev"] == fuseRev and v["DRAM_Size"] == dramSize and 
                    v["Pcore_Status"] == Pcore and v["NAND_Size"] == nandSize then
                    resultFlag = true
                    break
                end
            end
        else
            failureMsg = 'load csv error'
        end
    else
        failureMsg = 'binValue or fuseRev or dramSize or Pcore or nandSize is empty'
    end

    if resultFlag then
        helper.flowLogFinish(resultFlag, paraTab)
    else
        helper.flowLogFinish(resultFlag, paraTab, nil, failureMsg)
        helper.reportFailure(failureMsg)
    end
end

--[[---------------------------------------------------------------------------------
-- genSbinStream(sbinKey, operation)
-- Function to compare or write sbin key
-- Created By : JW
-- Initial Creation Date : 05/12/2023
-- Modified By : N/A
-- Modification Date : N/A
-- Current_Version : 1.0
-- Changes from Previous version : Initial Version
-- Vendor_Name : PRM
-- Primary Usage : DFU
-----------------------------------------------------------------------------------]]
local function genSbinStream(sbinKey, operation)
    helper.LogInfo('Generate Sbin value For operation[0:compare, 1:write]: ' .. tostring(operation))
    local SystemTool = Device.getPlugin("SystemTool")
    local forOperation = {}

    if (sbinKey ~= nil) then
        forOperation['sbinKey'] = sbinKey
    else
        error("Not Found Valid Sbin Key")
    end

    if operation == 0 then
        forOperation['type'] = 0
    elseif operation == 1 then
        forOperation['type'] = 1
    else
        error("Unknown operation " .. tostring(operation))
    end
    helper.LogInfo('pcall generateSbinStream, params=' .. tostring(forOperation))
    local _, result = pcall(SystemTool["generateSbinStream"], forOperation)
    helper.LogInfo('pcall generateSbinStream, result = ' .. result)
    return result
end

--[[---------------------------------------------------------------------------------
-- SBin.SBinPreCheck(paraTab)
-- Function to check sbin value
-- Created By : JW
-- Initial Creation Date : 05/12/2023
-- Modified By : JW
-- Modification Date : 19/12/2023
-- Current_Version : 1.2
-- Changes from Previous version : Initial Version
-- Vendor_Name : PRM
-- Primary Usage : DFU
-----------------------------------------------------------------------------------]]
function SBin.SBinPreCheck(paraTab)
    helper.flowLogStart(paraTab)
    local sbinKey = paraTab.Input
    local isWriteSbin = paraTab.isWriteSbin or "NO"
    local failureMsg = ''
    local result = 'UnSet'
    local resultFlag = false
    local sbinValue = ''
    local isUploadAttribute = false
    if (paraTab.Commands == nil) then
        paraTab.Commands = 'syscfg printbyte SBin'
    end
    local status, sbin_read = xpcall(dutCmd.sendCmd, debug.traceback, paraTab)
    if status then
        if string.find(sbin_read, 'Not Found') == nil then
            helper.LogInfo('SBin is not empty')
            local sbin_cal = genSbinStream(sbinKey, 1)
            sbin_cal = string.gsub(sbin_cal, '0x', '')
            sbin_cal = string.upper(sbin_cal)
            helper.LogInfo('sbin_cal = ' .. tostring(sbin_cal))

            sbin_read = string.match(sbin_read, "Hex:([0-9A-F%s]+)")
            sbin_read = string.gsub(sbin_read, '\r', '')
            sbin_read = string.gsub(sbin_read, '\n', '')
            sbin_read = string.gsub(sbin_read, ' ', '')
            sbin_read = string.upper(sbin_read)
            helper.LogInfo('sbin_read = ' .. tostring(sbin_read))

            sbinValue = '0x' .. sbin_read
            if string.find(sbin_read, sbin_cal) ~= nil then
                isUploadAttribute = true
                resultFlag = true
            else
                if isWriteSbin == "NO" then
                    result = "sbin_need_write"
                    resultFlag = true
                else
                    failureMsg = 'write SBin error'
                end
            end
        else
            helper.LogInfo('SBin is empty')
            if isWriteSbin == "NO" then
                result = "sbin_need_write"
                resultFlag = true
            else
                failureMsg = 'write SBin error'
            end
        end
    else
        failureMsg = 'execute command error'
    end

    if (paraTab.attribute) and isUploadAttribute then
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, sbinValue))
    end

    if resultFlag then
        helper.flowLogFinish(resultFlag, paraTab)
    else
        helper.flowLogFinish(resultFlag, paraTab, nil, failureMsg)
        helper.reportFailure(failureMsg)
    end
    
    return result
end

--[[---------------------------------------------------------------------------------
-- SBin.SBinWrite(paraTab)
-- Function to write sbin value
-- Created By :JW
-- Initial Creation Date : 05/12/2023
-- Modified By : JW
-- Modification Date : 14/12/2023
-- Current_Version : 1.1
-- Changes from Previous version : Initial Version
-- Vendor_Name : PRM
-- Primary Usage : DFU
-----------------------------------------------------------------------------------]]
function SBin.SBinWrite(paraTab)
    helper.flowLogStart(paraTab)
    local sbinKey = paraTab.Input
    -- Step 4. Write Sbin value using  “syscfg addbyte SBin <byte_stream>”;
    -- programming Sbin
    local SbinValueRT = genSbinStream(sbinKey, 1)
    local resultFlag = false
    local failureMsg = ""
    helper.LogInfo('Write Sbin value to DUT: ' .. SbinValueRT)
    if (paraTab.Commands == nil) then
        paraTab.Commands = 'syscfg addbyte SBin'
    end
    paraTab.Commands =  paraTab.Commands .. ' ' .. SbinValueRT
    helper.LogInfo('Write Sbin value to DUT, Command = ' .. paraTab.Commands)
    local status, response = xpcall(dutCmd.sendCmd, debug.traceback, paraTab)
    if status then
        resultFlag = true
    else
        failureMsg = "execute command error"
    end

    if resultFlag then
        helper.flowLogFinish(resultFlag, paraTab)
    else
        helper.flowLogFinish(resultFlag, paraTab, nil, failureMsg)
    end
end

return SBin
