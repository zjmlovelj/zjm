local deviceFunctions = {}

local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local utils = require("Tech/utils")
local pListSerialization = require "Serialization.PListSerialization"
local STATION_TOPOLOGY = pListSerialization.LoadFromFile(string.gsub(Atlas.assetsPath, 'Assets',
                                                                    "Config/StationTopology.plist"))

local PARSE_DEFINITIONS_PATH = string.gsub(Atlas.assetsPath, 'Assets', "Assets/parseDefinitions")
local KIS_PORT_INFO = utils.loadPlist("/Users/gdlocal/Library/Atlas2/supportFiles/KisPort_Info.plist")

local MLBSNTable = {}

function loadVirtualPortPlugin( group_id, slot_id, topology, workingDirectory )
    local group_identifier = STATION_TOPOLOGY["groups"][group_id]["identifier"]
    local unit_identifier = STATION_TOPOLOGY["groups"][group_id]["units"][slot_id]["identifier"]
    Log.LogInfo("$$$$ topology " .. comFunc.dump(topology))
    local virtualPort = Atlas.loadPlugin("VirtualPort")
    virtualPort.setup({
        group_id = group_identifier,
        unit_id = unit_identifier,
        topology = topology,
        loggingfolder = workingDirectory
    })
    return virtualPort
end

local pluginDCSDLogger = function(uart_url, workingDirectory)
    local CommBuilder = Atlas.loadPlugin('CommBuilder')
    CommBuilder.setDelimiter('\n')
    CommBuilder.setLogFilePath(workingDirectory .. '/restore_uart.log', workingDirectory .. '/restore_uart_raw.log')
    local logger = CommBuilder.createCommLoggerPlugin(uart_url)
    return logger
end

local function pluginLoaderCreateDutCommunication(url, logFilePath, isCreateDataChannel, isCreateDataLogger, isTrimNonAscii,
                                             isActiveChannel)
    local CommBuilder = Atlas.loadPlugin("CommBuilder")

    local filterCharacters = {}
    table.insert(filterCharacters, string.format("%02x", 0))
    for i = 128, 255 do
        table.insert(filterCharacters, string.format("%02x", i))
    end
    CommBuilder.setReadFiltersHex(filterCharacters)

    if isActiveChannel then
        CommBuilder.setActiveChannelOnOff(1)
    end
    local baseChannel = CommBuilder.createBaseChannel(url)
    if string.match(logFilePath, "(.*/)[^/]*") then
        local rawLogFilePath = string.match(logFilePath, "(.*/)[^/]*") .. "raw_" ..
                                   string.match(logFilePath, ".*/([^/]*)")
        CommBuilder.setLogFilePath(logFilePath, rawLogFilePath)
    end

    local commLogger = nil
    if isCreateDataLogger then
        commLogger = CommBuilder.createCommLoggerPlugin(url)
    end

    local channel = nil
    if isCreateDataChannel then
        local channelBuilder = Atlas.loadPlugin("SMTDataChannel")
        local channelPlugin = channelBuilder.createChannelPlugin()
        local channelLogFilePath = string.match(logFilePath, "(.*/)[^/]*") .. "base_" ..
                                       string.match(logFilePath, ".*/([^/]*)")
        channelPlugin.setLogFilePath(channelLogFilePath)
        channelPlugin.setLegacyLogMode(1)
        channel = channelPlugin.createDataChannel(baseChannel)
        local EFIdut = CommBuilder.createEFIPlugin(channel)
        return EFIdut, channelPlugin, commLogger
    end

    local EFIdut = CommBuilder.createEFIPlugin(baseChannel)
    return EFIdut, channel, commLogger
end

function loadEFIPluginAndChannelPlugin( url, logFilePath )
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    local filterCharacters = {}
    table.insert(filterCharacters, string.format("%02x", 0))
    for i = 128, 255 do
        table.insert(filterCharacters, string.format("%02x", i))
    end
    CommBuilder.setReadFiltersHex(filterCharacters)
    local channelBuilder = Atlas.loadPlugin("SMTDataChannel")
    local baseChannel = CommBuilder.createBaseChannel(url)
    local channelPlugin = channelBuilder.createChannelPlugin()
    channelPlugin.setLogFilePath(logFilePath)
    channelPlugin.setLegacyLogMode(1)
    local dataChannel = channelPlugin.createDataChannel(baseChannel)
    local dut = CommBuilder.createEFIPlugin(dataChannel)
    return dut, channelPlugin
end

local getBaseLoctionID = function (pid, vid, vendor)
    local LocaltionPlist = utils.loadPlist("/Users/gdlocal/Library/Atlas2/supportFiles/LocaltionPlist.plist")
    local product = Atlas.loadPlugin("StationInfo").product()
    Log.LogInfo("product---->", product)
    local pattern = string.format("Product ID:%%s*0x%04x%%s*Vendor ID:%%s*0x%x%%s*.-Version:%%s*.-%%s*Speed:%%s*Up to 480 Mb/s%%s*Location ID:%%s*(0x%%d+)%%s*/", pid,vid)
    local response = Atlas.loadPlugin("RunShellCommand").run("system_profiler SPUSBDataType").output
    local BaseLoctionIDTable = {}
    for v in string.gmatch(response, pattern) do
        table.insert(BaseLoctionIDTable, v)
    end
    for i,v in ipairs(BaseLoctionIDTable) do
        Log.LogInfo("BaseLoctionIDTable---->", i, v)
    end
    local id = tonumber(LocaltionPlist[product][vendor]) 
    local baselocationid = tostring(BaseLoctionIDTable[id])
    Log.LogInfo("baselocationid---->"..baselocationid)
    return baselocationid
end

local function stationUtilsGetKISDeviceURL(args, isSkipDetectKisPort, vendor)
    -- TODO: need a API for ActionsBox.
    local USBUtilityName = "USBUtility"
    if helper ~= nil and type(helper.getPluginIdentifier) == "function" then
        USBUtilityName = helper.getPluginIdentifier("USBUtility")
    end

    local USBUtility = nil
    if Device ~= nil and Device.getPlugin ~= nil then
        local status, MyUSBUtility = xpcall(Device.getPlugin, debug.traceback, USBUtilityName)
        if status then
            USBUtility = MyUSBUtility
        end
    end

    if not USBUtility then
        local status, SMTCommonPlugin = xpcall(Atlas.loadPlugin, debug.traceback, "SMTCommonPlugin")
        if not status then
            ErrorFunction(ErrorCode.PluginGetErr, "Can not find 'SMTCommonPlugin' plugin")
        end
        USBUtility = SMTCommonPlugin.createUSBUtility()
    end

    if type(USBUtility) ~= "table" or type(USBUtility.usbLocationIDFromProperty) ~= "function" then
        ErrorFunction(ErrorCode.FunctionNotSupportErr, "Can not find function 'usbLocationIDFromProperty' in USBUtility")
    end

    if type(USBUtility) ~= "table" or type(USBUtility.usbLocationRelativeFromLocation) ~= "function" then
        ErrorFunction(ErrorCode.FunctionNotSupportErr,
                      "Can not find function 'usbLocationRelativeFromLocation' in USBUtility")
    end

    if type(USBUtility) ~= "table" or type(USBUtility.usbLocationRelativeFromLocation) ~= "function" then
        ErrorFunction(ErrorCode.FunctionNotSupportErr,
                      "Can not find function 'usbLocationRelativeFromLocation' in USBUtility")
    end

    local property = {}
    if args.PID then
        property[USBUtility.USB_PRODUCT_ID] = tonumber(args.PID)
    end
    if args.VID then
        property[USBUtility.USB_VENDOR_ID] = tonumber(args.VID)
    end
    if args.ProductName then
        property[USBUtility.USB_PRODUCT_NAME] = tostring(args.ProductName)
    end
    if args.SN then
        property[USBUtility.USB_SERIAL_NUMBER] = tostring(args.SN)
    end
    -- local baseLocation = USBUtility.usbLocationIDFromProperty(property)
    local baseLocation = getBaseLoctionID(args.PID, args.VID, vendor)
    Log.LogInfo('baseLocation is:', baseLocation)
    local upLevel = args.Up and tonumber(args.Up) or 0
    local offset = (args.Slot and tostring(args.Slot)) or
                       (Device and string.match(Device.identifier, "G=%d*:S=%a*(%d*)"))
    local RelativeLocation = USBUtility.usbLocationRelativeFromLocation(baseLocation, upLevel, offset)
    local RestoreLocation = USBUtility.usbLocationRelativeFromLocation(RelativeLocation, 0, "1")

    Log.LogInfo("baseLocation is:" .. baseLocation)
    Log.LogInfo("upLevel is:" .. upLevel)
    Log.LogInfo("offset is:" .. offset)

    Log.LogInfo('RelativeLocation is:', RelativeLocation)
    local deviceUSBUrl = 'usb://' .. tostring(RestoreLocation)
    Log.LogInfo("deviceUSBUrl is:" .. deviceUSBUrl)
    local deviceSerialNumber = 'NA'
    local kisUartUrl = ''
    local deviceType = 'kis'
    if isSkipDetectKisPort then
        kisUartUrl = 'uart:///dev/cu.' .. deviceType .. '-' .. string.match(RelativeLocation, "0x(%x*)") .. '-ch-0'
        return deviceUSBUrl, kisUartUrl
    end
    local response = Atlas.loadPlugin("RunShellCommand").run("ls /dev/cu.*").output
    Log.LogInfo("ls /dev/cu.* response is:", response)
    local array = response:gmatch(deviceType .. '%-(%w+)%-ch%-0')
    for sn, _ in array do
        if string.match(RelativeLocation, sn) then
            deviceSerialNumber = sn
            break
        end
    end
    kisUartUrl = 'uart:///dev/cu.' .. deviceType .. '-' .. deviceSerialNumber .. '-ch-0'
    return deviceUSBUrl, kisUartUrl
end

local getHubVidByPid = function (pid)

    local pattern = string.format("Product ID:%%s*0x%x%%s*Vendor ID:%%s*(0x%%w+)", pid)
    local response = Atlas.loadPlugin("RunShellCommand").run("system_profiler SPUSBDataType").output
    Log.LogInfo("system_profiler SPUSBDataType response is:", response)
    Log.LogInfo("pattern is:", pattern)
    local vid = string.match(response, pattern)
    Log.LogInfo("$$$vid$$$"..vid)
    vid = tonumber(vid)

    return vid
end

-- local loadKISPlugin = function (deviceName)
--     local slot = string.match(deviceName, "slot(%d+)")
--     local workingDirectory = Group.getDeviceUserDirectory(deviceName)
--     local fixtureBuilder = Atlas.loadPlugin("FixturePlugin")
--     local fixturePlugin = fixtureBuilder.createFixtureBuilder(Group.index-1)
--     -- local fixturePlugin = groupPlugins['FixturePlugin']
--     Log.LogInfo("workingDirectory", workingDirectory)

--     local vendor = fixturePlugin.getVendor()
--     Log.LogInfo("$$$get_vendor$$$"..vendor)
--     local pid = ""
--     if vendor == "Suncode" then
--         pid = 0x1004
--         Log.LogInfo("SC_pid is:", pid)
--     elseif vendor == "PRM" then
--         pid = 0x1004
--         Log.LogInfo("PRM_pid is:", pid)
--     elseif vendor == "HYC" then
--         pid = 0x1004
--         Log.LogInfo("HYC_pid is:", pid)
--     end

--     local vid = getHubVidByPid(pid)
--     Log.LogInfo("vid is:", vid)


--     local usbUrl, kisUartUrl = stationUtilsGetKISDeviceURL({PID = pid, VID = vid, Slot = slot}, true, vendor)
--     -- local kisUartUrl = 'uart:///dev/cu.kis-14310000-ch-0'
--     Log.LogInfo("$$$$$kisUartUrl",kisUartUrl)
--     local dutPlugin, dataChannelPlugin = pluginLoaderCreateDutCommunication(kisUartUrl,
--                                                                              workingDirectory .. "/kis_usb.log", true)
--     local logger = pluginDCSDLogger(kisUartUrl, workingDirectory)

--     return dutPlugin, dataChannelPlugin, logger
-- end

function loadKISPlugin(deviceName)
    local slot = string.match(deviceName, "slot(%d+)")
    local usb_info = Atlas.loadPlugin("RunShellCommand").run("system_profiler SPUSBDataType").output
    Log.LogInfo("system_profiler SPUSBDataType response is:", usb_info)
    local regex = Atlas.loadPlugin("Regex")
    local pattern = "Product ID: 0x1004\\s+([\\s\\S]+?Location ID: 0x\\S+) /"
    local matchs = regex.groups(usb_info, pattern, 1)
    Log.LogInfo("$$$$$matchs: ",comFunc.dump(matchs))
    local kis_hub_locationID = ''
    local slot_index = ''
    local flag = false
    if matchs and #matchs > 0 and #matchs[1] > 0 then
        for _, v in pairs(matchs) do
            if v and #v > 0 then
                local hub_info = v[1]
                local vid = string.match(hub_info, "Vendor ID: (0x[0-9a-z]+)")
                local lid = string.match(hub_info, "Location ID: (0x[0-9a-z]+)")
                Log.LogInfo("$$$$vid: ",vid)
                Log.LogInfo("$$$$lid: ",lid)
                for _,v1 in pairs(KIS_PORT_INFO) do
                    if v1["VendorID"] == vid and v1["LoctionID"] == lid and v1["Slot"] == slot then
                        kis_hub_locationID = v1["LoctionID"]
                        slot_index = v1["SlotIndex"]
                        flag = true
                        break
                    end
                end
                if flag then
                    break
                end
            end
        end
    end
    if not flag then
        error("KIS USB Hub LoctionID is invalid!")
    end

    local workingDirectory = Group.getDeviceUserDirectory(deviceName)
    Log.LogInfo("$$$$kis_hub_locationID: ",kis_hub_locationID)
    Log.LogInfo("$$$$slot_index: ",slot_index)
    local locationID = ''
    for i=1,#kis_hub_locationID do
        local char = string.sub(kis_hub_locationID, i, i)
        if i == tonumber(slot_index) then
            char = 2
        end
        locationID = locationID .. tostring(char)
    end
    locationID = string.gsub(locationID, "0x","")
    Log.LogInfo("$$$$locationID: ",locationID)

    local url_kis = "uart:///dev/cu.kis-"..locationID.."-ch-0"
    Log.LogInfo("$$$$url_kis: ",url_kis)
    local logFilePath_kis = workingDirectory .. "/kis_usb.log"
    local kis_dut, kis_channelPlugin = loadEFIPluginAndChannelPlugin(url_kis, logFilePath_kis)
    return kis_dut, kis_channelPlugin
end

function deviceFunctions.setup(deviceName, groupPluginTable)
    -- deviceName = Device_slot#
    Log.LogInfo("--------load Plugins--------")
    Log.LogInfo("groupPluginTable", groupPluginTable)

    local group_id = Group.index
    local slot_id = tonumber(tostring(deviceName):sub(-1))
    local workingDirectory = Group.getDeviceUserDirectory(deviceName)

    -- load MDParser Plugin
    local mdParser = Atlas.loadPlugin("MDParser")
    mdParser.init(PARSE_DEFINITIONS_PATH)

    -- load VirtualPort Plugin
    local vp_url = STATION_TOPOLOGY["groups"][group_id]["units"][slot_id]["unit_transports"][1]["url"]
    local virtualPort = loadVirtualPortPlugin(group_id, slot_id, STATION_TOPOLOGY, workingDirectory)

    -- load dut plugin and channelPlugin
    local logFilePath = workingDirectory .. "/uart.log"
    local dut, channelPlugin = loadEFIPluginAndChannelPlugin(vp_url, logFilePath)

    -- Init Kis port
    local kis, kischannelPlugin, logger = loadKISPlugin(deviceName)

    -- load dimension dut plugin
    local url_dmns = "uart:///dev/cu.usbmodemefidmns" .. string.char((string.byte('A') + slot_id - 1)) .. "11"
    local logFilePath_dmns = workingDirectory .. "/uart_dmns.log"
    local dimension_dut = loadEFIPluginAndChannelPlugin(url_dmns, logFilePath_dmns)
    
    -- load variableTable
    local variableTable = Atlas.loadPlugin("VariableTable")
    variableTable.init()
    
    return {
        Mutex = Atlas.loadPlugin("MutexPlugin"),
        ChannelPlugin = channelPlugin,
        Kis_channelPlugin = kischannelPlugin,
        Kis_dut = kis,
        Dut = dut,
        Dimension_dut = dimension_dut,
        VirtualPort = virtualPort,
        MDParser = mdParser,
        SFC = Atlas.loadPlugin("SFC"),
        Runtest = Atlas.loadPlugin("RunTest"),
        Utilities = Atlas.loadPlugin("Utilities"),
        VariableTable = variableTable,
        FileOperation = Atlas.loadPlugin("SMTCommonPlugin").createFileManipulationUtility(),
        TimeUtility = Atlas.loadPlugin("SMTCommonPlugin").createTimeUtility(),
        DCSD = Atlas.loadPlugin("DCSD"),
        RunShellCommand = Atlas.loadPlugin('RunShellCommand'),
        USBFS = Atlas.loadPlugin("USBFS"),
        FDR = Atlas.loadPlugin('FDR'),
        Regex = Atlas.loadPlugin("Regex"),
        PListSerializationPlugin = Atlas.loadPlugin("PListSerializationPlugin"),
        SMTCommonPlugin = Atlas.loadPlugin("SMTCommonPlugin"),
        StationInfo = Atlas.loadPlugin("StationInfo"),
        SystemTool = Atlas.loadPlugin("SystemToolPluginAtlas2")
    }, {"VariableTable", "FixturePlugin"}
end

function deviceFunctions.teardown(deviceName, devicePluginTable)
    Log.LogInfo("--------shutdown Plugins-------")
    os.execute('pkill -9 virtualport')
    local workingDirectory = Group.getDeviceUserDirectory(deviceName)
    local deviceLogPath = string.gsub(workingDirectory, "user", "system").."/device.log"
    local slot_id = tonumber(tostring(deviceName):sub(-1))
    Log.LogInfo(deviceName .. "--------deviceName-------")
    local InteractiveView = devicePluginTable['InteractiveView']
    local kis_dut = devicePluginTable['Kis_dut']
    local dut = devicePluginTable['Dut']
    local mutex = devicePluginTable['Mutex']
    if dut.isOpened() == 1 then
        local status,ret = xpcall(dut.close,debug.traceback)
        Log.LogInfo("$$$$ dut.close status .." .. tostring(status).. "ret " .. tostring(ret))
        if not status then
            error("DUT CLOSE ERROR!!")
        end
    end
    if kis_dut.isOpened() == 1 then
        local status,ret = xpcall(kis_dut.close,debug.traceback)
        Log.LogInfo("$$$$ kis_dut.close status .." .. tostring(status).. "ret " .. tostring(ret))
        if not status then
            error("kis_dut CLOSE ERROR!!")
        end
    end
    local status,ret = xpcall(mutex.reset,debug.traceback)
    Log.LogInfo("$$$$ mutex.reset status .." .. tostring(status).. "ret " .. tostring(ret))


end

return deviceFunctions
