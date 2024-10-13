local Ace3FW = {}

local Log = require("Tech/logging")
local helper = require("Tech/SMTLoggingHelper")
local comFunc = require("Tech/CommonFunc")
local crc32 = require("Tech/Ace3CRC32")
local Ace3OTP = require("Tech/Ace3OTP")
local securityUtils = require("ALE/SecurityUtils")
local fileUtils = require "ALE/FileUtils"
local Ace3LogPath
local defaultFailResult = "FAIL"
local groupID, slotNumber = string.match(Device.identifier, "G%=([0-9]+):S%=slot([0-9]+)")
slotNumber = tonumber(slotNumber)
local buildImageFolder = fileUtils.joinPaths("/tmp", "Fixture" .. tostring(groupID), "ch" .. tostring(slotNumber))

-- ! @brief Read Ace3 FW version
-- ! @details Read Ace3 FW version from I2C
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns Ace3FWVersion(string)
function Ace3FW.readAce3FWVersion(paraTab)
    helper.flowLogStart(paraTab)
    local fixturePluginName = paraTab.fixturePluginName
    local i2cAddress = paraTab.deviceAddress
    local reportStatus, serialNumber = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
    if not reportStatus then
        local failureMessage = "Get serial number error"
        helper.flowLogFinish(false, paraTab, "Get_serial_number", failureMsg)
        helper.reportFailure(failureMessage)
    end
    local Ace3LogFile = serialNumber .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log"
    Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log", Ace3LogFile)

    local timeUtility
    if Device then
        timeUtility = Device.getPlugin("TimeUtility")
    else
        timeUtility = Atlas.loadPlugin("SMTCommonPlugin").createTimeUtility()
    end

    local readNAK
    local patternNAK = paraTab.patternNAK
    Log.LogInfo('patternNAK', patternNAK)
    local hexVersion
    for i = 1, 50 do
        hexVersion = Ace3OTP.readAce3I2C(fixturePluginName, i2cAddress, "0x0f", 7)

        readNAK = false
        if patternNAK then
            if string.match(hexVersion, patternNAK) then
                readNAK = true
            end
        end
        if hexVersion:sub(1, 4) == "0x04" or readNAK then
            timeUtility.delay(0.1)
            Ace3OTP.writeAce3Log(Ace3LogPath, "Read 0x0f times: ", tostring(i))
        else
            break
        end
    end
    local readVersion = string.gsub(hexVersion or "", '0x', '')
    local data = comFunc.splitString(readVersion, ",")

    local Ace3FWVersion
    if data and #data == 7 and hexVersion:sub(1, 4) == "0x08" then
        local appConfigVersion = tonumber(data[6], 16) 
        local customerVersion = tonumber(data[7], 16)
        local major = tonumber(data[5] .. string.sub(data[4], 1, 1))
        local minor = tonumber(string.sub(data[4], 2, 2) .. data[3])
        local revision = tonumber(data[2])
        Ace3FWVersion = string.format("%s.%s.%s.%s.%s", major, minor, revision, appConfigVersion, customerVersion)
    end
    
    Ace3OTP.writeAce3Log(Ace3LogPath, "Read Ace3 FW Version: ", Ace3FWVersion)
    if Ace3FWVersion then
        helper.flowLogFinish(true, paraTab)
    else
        local failureMsg = "error result: " .. (Ace3FWVersion or "")
        helper.flowLogFinish(false, paraTab, Ace3FWVersion, failureMsg)
        Ace3OTP.writeAce3Log(Ace3LogPath, failureMsg)
        helper.reportFailure(failureMsg)
    end
    return Ace3FWVersion
end

-- ! @brief Compare Ace3 FW version
-- ! @details Compare Ace3 FW version with expect, create record if it is expected or not
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A
function Ace3FW.compareAce3FWVersion(paraTab)
    helper.flowLogStart(paraTab)
    local expect = paraTab.expect
    assert(expect ~= nil and expect ~= "", "expect is invalid")

    local reportStatus, serialNumber = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
    if not reportStatus then
        local failureMessage = "Get serial number error"
        helper.flowLogFinish(false, paraTab, "Get_serial_number", failureMessage)
        helper.reportFailure(failureMessage)
    end
    local Ace3LogFile = serialNumber .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log"
    Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log", Ace3LogFile)

    local Ace3FWVersion = paraTab["Ace3FWVersion"]
    if expect == Ace3FWVersion then
        helper.flowLogFinish(true, paraTab)
        if paraTab.attribute then
            DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, Ace3FWVersion))
        end
        return true
    else
        local failureMsg = "error result: " .. (Ace3FWVersion or "")
        helper.flowLogFinish(false, paraTab, Ace3FWVersion, failureMsg)
        Ace3OTP.writeAce3Log(Ace3LogPath, failureMsg)
        helper.reportFailure(failureMsg)
    end
end

-- ! @brief Reset Ace3 via I2C
-- ! @details Reset Ace3 via I2C, create record if it is expected
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A
function Ace3FW.resetAce3(paraTab)
    helper.flowLogStart(paraTab)
    local fixturePluginName = paraTab.fixturePluginName
    local i2cAddress = paraTab.deviceAddress
    local expect = paraTab.expect
    local reportStatus, serialNumber = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
    if not reportStatus then
        local failureMessage = "Get serial number error"
        helper.flowLogFinish(false, paraTab, "Check_DUT_Mode_Get_serial_number", failureMessage)
        helper.reportFailure(failureMessage)
    end
    local Ace3LogFile = serialNumber .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log"
    Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log", Ace3LogFile)

    local timeUtility
    if Device then
        timeUtility = Device.getPlugin("TimeUtility")
    else
        timeUtility = Atlas.loadPlugin("SMTCommonPlugin").createTimeUtility()
    end

    -- reset ACE3
    Ace3OTP.writeAce3Log(Ace3LogPath, "Reset Ace3 via I2C:")
    Ace3OTP.writeAce3I2C(fixturePluginName, i2cAddress, '0x08', '0x04,0x47,0x41,0x49,0x44')

    -- Wait 1 second for Ace to receive the reset command
    timeUtility.delay(1) -- use inner delay
    return Ace3FW.checkDUTMode(paraTab)
end

-- ! @brief check DUT mode via I2C
-- ! @details Read DUT status via I2C and then verify, create record if it is expected
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns true/false(boolean)
function Ace3FW.checkDUTMode(paraTab)
    local fixturePluginName = paraTab.fixturePluginName
    local i2cAddress = paraTab.deviceAddress
    local expect = paraTab.expect
    local reportStatus, serialNumber = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
    if not reportStatus then
        local failureMessage = "Get serial number error"
        helper.flowLogFinish(false, paraTab, "Check_DUT_Mode_Get_serial_number", failureMessage)
        helper.reportFailure(failureMessage)
    end
    local Ace3LogFile = serialNumber .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log"
    Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log", Ace3LogFile)

    local timeUtility
    if Device then
        timeUtility = Device.getPlugin("TimeUtility")
    else
        timeUtility = Atlas.loadPlugin("SMTCommonPlugin").createTimeUtility()
    end

    local modeNormal = "0x04,0x41,0x50,0x50,0x20"
    local modeDFU = "0x04,0x44,0x46,0x55,0x66"
    local resetResult = false
    local readData
    -- the only error condition being if Ace never returns a valid mode response over these 5 seconds
    for i = 1, 28 do
        readData = Ace3OTP.readAce3I2C(fixturePluginName, i2cAddress, "0x03", 5)

        if readData == modeNormal or readData == modeDFU or readData == expect then
            if readData == modeNormal then
                Ace3OTP.writeAce3Log(Ace3LogPath, "BOOT Success with SOC in Normal mode")
            elseif readData == modeDFU then
                Ace3OTP.writeAce3Log(Ace3LogPath, "BOOT Success with SOC in DFU mode")
            end
            resetResult = true
            break
        else
            Ace3OTP.writeAce3Log(Ace3LogPath, "Read 0x03 times: ", tostring(i))
        end
        -- begin polling I2C subaddress 0x3 every 145ms to see when it has booted
        timeUtility.delay(0.145)
    end

    if resetResult then
        helper.flowLogFinish(true, paraTab, readData)
        return true
    else
        local failureMsg = "error result: " .. (readData or "")
        helper.flowLogFinish(false, paraTab, readData, failureMsg)
        Ace3OTP.writeAce3Log(Ace3LogPath, failureMsg)
        helper.reportFailure(failureMsg)
    end
end

-- ! @brief Get Ace3 build file path
-- ! @details Decide which Patch and AppConfig files to use
-- ! @param Ace3BoardID(string) Board ID
-- ! @param Ace3PREV(string) Ace3 PREV value
-- ! @param AcePlistFilePath(string) SuperBinary.plist file path
-- ! @returns file path(string) raise error if file is not exit or did not find keyword in Plist File
function Ace3FW.getAce3BuildFilePath(Ace3BoardID, Ace3PREV, AcePlistFilePath)
    if comFunc.fileExists(AcePlistFilePath) then
        Log.LogInfo("SuperBinary File:", AcePlistFilePath)
    else
        error("SuperBinary File is not exist")
    end

    local pListSerialization = Atlas.loadPlugin("PListSerializationPlugin")
    local customContent = pListSerialization.decodeFile(AcePlistFilePath)
    local superBinaryPayloads = customContent["SuperBinary Payloads"]

    local keyPayloadMetaData = "Payload MetaData"
    local keyPersonalizationBoardID = "Personalization Board ID (64 bits)"
    local keyPersonalizationMatchingData = "Personalization Matching Data"
    local keyProductRevisionMax = "Personalization Matching Data Product Revision Maximum"
    local keyProductRevisionMin = "Personalization Matching Data Product Revision Minimum"
    local keyProductMatchingDataPayloadTags = "Personalization Matching Data Payload Tags"

    local matchingDataPayloadTags
    local flagProductRevision = false
    for _, v in pairs(superBinaryPayloads) do
        if flagProductRevision then
            break
        end
        local payloadMetaData = v[keyPayloadMetaData]
        if payloadMetaData and tonumber(payloadMetaData[keyPersonalizationBoardID]) == tonumber(Ace3BoardID) then
            Log.LogInfo("Personalization Board ID (64 bits):", payloadMetaData[keyPersonalizationBoardID])
            local personalizationMatchingData = payloadMetaData[keyPersonalizationMatchingData]
            for _, matchingData in pairs(personalizationMatchingData) do
                local RevisionMax = matchingData[keyProductRevisionMax]
                local RevisionMin = matchingData[keyProductRevisionMin]
                if tonumber(Ace3PREV) <= tonumber(RevisionMax) and tonumber(Ace3PREV) >= tonumber(RevisionMin) then
                    flagProductRevision = true
                    matchingDataPayloadTags = matchingData[keyProductMatchingDataPayloadTags]
                    Log.LogInfo("Personalization Matching Data Payload Tags:", matchingDataPayloadTags)
                    break
                end
            end
        else
            flagProductRevision = false
        end
    end

    if not flagProductRevision or matchingDataPayloadTags == nil then
        error("Personalization Matching Data Payload Tags error")
    end

    local patchPayload, appConfigPayload = string.match(matchingDataPayloadTags, "(PT%d+)%,(AC%d+)")
    Log.LogInfo(patchPayload, appConfigPayload)
    if patchPayload == nil then
        error("Patch Payload not found")
    end
    if appConfigPayload == nil then
        error("AppConfig Payload not found")
    end

    local flagPatchPayload, flagAppConfigPayload
    local patchPayloadFilepath, appConfigPayloadFilepath
    for _, v in pairs(superBinaryPayloads) do
        local payload4CC = v["Payload 4CC"]
        if payload4CC == patchPayload then
            flagPatchPayload = true
            patchPayloadFilepath = v["Payload Filepath"]
            break
        else
            flagPatchPayload = false
        end
    end
    Log.LogInfo("Patch Payload Filepath:", patchPayloadFilepath)
    if not flagPatchPayload then
        error("Patch Payload not match Payload 4CC")
    end

    for _, v in pairs(superBinaryPayloads) do
        local payload4CC = v["Payload 4CC"]
        if payload4CC == appConfigPayload then
            flagAppConfigPayload = true
            appConfigPayloadFilepath = v["Payload Filepath"]
            break
        else
            flagAppConfigPayload = false
        end
    end
    Log.LogInfo("AppConfig Payload Filepath:", appConfigPayloadFilepath)
    if not flagAppConfigPayload then
        error("AppConfig Payload not match Payload 4CC")
    end

    return patchPayloadFilepath, appConfigPayloadFilepath
end

-- ! @brief Convert bin to number table
-- ! @param binVal(string) bin string, e.g. ACE3OTP
-- ! @returns data(table) number table, e.g. {65, 67, 69, 51, 79, 84, 80}
local function bin2NumberTable(binVal)
    local data = {}
    local i = 0
    for v in (string.gmatch(binVal, "(.)")) do
        data[i] = string.byte(v)
        i = i + 1
    end
    return data
end

-- ! @brief Write word data to number table
-- ! @details Write word data to number table as little Endian format
-- ! @param content(table) Orignal number table, e.g. {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}
-- ! @param word(string) word data, e.g. 0xace00003
-- ! @param start(table) location for replace, e.g. 0
-- ! @returns N/A raise error if word lenth is wrong
-- ! e.g. content => {0x03, 0x00, 0xe0, 0xac, 0xff, 0xff, 0xff, 0xff}
local function writeWord2Table(content, word, start)
    if (#word) ~= 10 then
        error("word length is not 10")
    end
    word = string.gsub(word, "0x", "")
    for idx = 1, #word, 2 do
        local value = tonumber(string.sub(word, idx, idx + 1), 16)
        content[start + 4 - (idx + 1) / 2] = value
    end
end

-- ! @brief Convert number table to bin
-- ! @param data(table) number table, e.g. {65, 67, 69, 51, 79, 84, 80}
-- ! @returns binString(string) raise error if data has nil value, e.g. ACE3OTP
local function table2BinString(data)
    local binString
    if data[0] then
        binString = string.char(data[0])
    else
        binString = ''
    end
    for i = 1, #data do
        if data[i] == nil then
            error("Data is nil")
        end
        binString = binString .. string.char(data[i])
    end
    return binString
end

-- ! @brief Build Ace3 SPI image
-- ! @details Complete unpersonalized Ace3Image by concatenating the header, patch, and appconfig together
-- ! @param AcePatchFilePath(string) Patch Payload file path
-- ! @param AceAppConfigFilePath(string) AppConfig Payload file path
-- ! @param AceImageSPIPath(string) Ace Image file path
-- ! @returns N/A
function Ace3FW.buildAce3Image(AcePatchFilePath, AceAppConfigFilePath, AceImageSPIPath)
    if comFunc.fileExists(AcePatchFilePath) then
        Log.LogInfo("Patch Payload File:", AcePatchFilePath)
    else
        error("Patch Payload File is not exist")
    end

    local fileHandle = io.open(AcePatchFilePath, "rb")
    local AcePatchvalue = fileHandle:read("*all")
    fileHandle:close()
    local AcePatchContent = bin2NumberTable(AcePatchvalue)
    local patchSize = #AcePatchvalue
    Log.LogInfo("patchSize", patchSize)

    if comFunc.fileExists(AceAppConfigFilePath) then
        Log.LogInfo("AppConfig Payload File:", AceAppConfigFilePath)
    else
        error("AppConfig Payload File is not exist")
    end

    local fileHandleConfig = io.open(AceAppConfigFilePath, "rb")
    local AceAppConfigValue = fileHandleConfig:read("*all")
    fileHandleConfig:close()
    local AceAppConfigContent = bin2NumberTable(AceAppConfigValue)
    local appConfigSize = #AceAppConfigValue
    Log.LogInfo("patchSize", appConfigSize)

    local AceSPIContent = {}
    for i = 0, #AcePatchContent do
        table.insert(AceSPIContent, AcePatchContent[i])
    end

    for i = 0, #AceAppConfigContent do
        table.insert(AceSPIContent, AceAppConfigContent[i])
    end

    -- This is a CRC of the Patch and App Config concatenated together, using the standard Ace CRC algorithm.
    local dataCRC = string.format("0x%08X", crc32.doPDCRC32(AceSPIContent))
    Log.LogInfo("Data CRC32:", dataCRC)

    -- Step 3: Construct the Ace3 Region header
    local Ace3ImageHeader = {}
    for i = 0, 63 do
        Ace3ImageHeader[i] = 0xFF
    end

    local HeaderID = "0xace00003"
    writeWord2Table(Ace3ImageHeader, HeaderID, 0)

    -- Firmware Version. This value should be copied in from the patch file
    Ace3ImageHeader[0x4] = AcePatchContent[0x24]
    Ace3ImageHeader[0x5] = AcePatchContent[0x25]
    Ace3ImageHeader[0x6] = AcePatchContent[0x26]
    Ace3ImageHeader[0x7] = AcePatchContent[0x27]

    writeWord2Table(Ace3ImageHeader, "0x00000000", 0x8)
    writeWord2Table(Ace3ImageHeader, "0x00000040", 0xC)

    writeWord2Table(Ace3ImageHeader, string.format("0x%08X", patchSize), 0x10)
    writeWord2Table(Ace3ImageHeader, string.format("0x%08X", appConfigSize), 0x14)

    local manifestSize = (0x40 + patchSize + appConfigSize)
    Log.LogInfo(manifestSize, string.format("0x%08X", manifestSize), "Manifest Size")
    writeWord2Table(Ace3ImageHeader, string.format("0x%08X", manifestSize), 0x18)

    writeWord2Table(Ace3ImageHeader, "0x00000000", 0x1C)

    local dataSize = (patchSize + appConfigSize + 0x0)
    Log.LogInfo(dataSize, string.format("0x%08X", dataSize), "Data Size")
    writeWord2Table(Ace3ImageHeader, string.format("0x%08X", dataSize), 0x20)

    writeWord2Table(Ace3ImageHeader, dataCRC, 0x24)

    -- Step 4: Add the SPI Flash Offsets
    local AceImageSPIContent = {}
    for i = 0, 0x3FFF do
        AceImageSPIContent[i] = 0xFF
    end
    writeWord2Table(AceImageSPIContent, "0x00004000", 0)
    writeWord2Table(AceImageSPIContent, "0x00000000", 0xFFC)

    local binStr = table2BinString(AceImageSPIContent)
    local binHeaderStr = table2BinString(Ace3ImageHeader)

    Log.LogInfo("SPI Image Path:", AceImageSPIPath)
    local fileHandleImage = io.open(AceImageSPIPath, "wb")
    fileHandleImage:write(binStr)
    fileHandleImage:write(binHeaderStr)
    fileHandleImage:write(AcePatchvalue)
    fileHandleImage:write(AceAppConfigValue)
    fileHandleImage:close()

    return true
end

-- ! @brief Generate MD5 value
-- ! @details Use md5 tool to generate MD5 value
-- ! @param AceImageSPIPath(string) Ace SPI Image path
-- ! @returns ret(string) the MD5 as a hex string
local function generateMD5(AceImageSPIPath)
    local status, utilities = xpcall(Device.getPlugin, debug.traceback, 'Utilities')
    if not status then
        utilities = Atlas.loadPlugin('Utilities')
    end
    local ret = securityUtils.generateDigestFromFile(utilities, AceImageSPIPath, Security.Digests.MD5)
    Log.LogInfo("MD5==>:", ret)
    return ret
end

-- ! @brief create Ace3 SPI image
-- ! @details Complete unpersonalized Ace3Image by concatenating the header, patch, and appconfig together
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns hostMD5(string), binFileName(string)
function Ace3FW.createAce3FWBinary(paraTab)
    helper.flowLogStart(paraTab)
    local fixturePluginName = paraTab.fixturePluginName
    local superBinaryPath = paraTab["superBinaryFolder"]
    local i2cAddress = paraTab["deviceAddress"]
    local Ace3PREV = paraTab["Ace3_PREV"]
    local project = paraTab.Product
    local buildStage = paraTab.Build_Stage

    local reportStatus, serialNumber = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
    if not reportStatus then
        local failureMessage = "Get serial number error"
        helper.flowLogFinish(false, paraTab, "Get_serial_number", failureMessage)
        helper.reportFailure(failureMessage)
    end
    local Ace3LogFile = serialNumber .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log"
    Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log", Ace3LogFile)
    Ace3OTP.writeAce3Log(Ace3LogPath, "----------------------- Start Ace3 FWDL... -----------------------")
    Ace3OTP.writeAce3Log(Ace3LogPath, "Read Ace3 Board ID")

    local readAce3EEBDID = Ace3OTP.readAce3I2C(fixturePluginName, i2cAddress, "0x2C", 49)
    local data = comFunc.splitString(readAce3EEBDID, ",")
    if #data < 49 then
        error("Read Ace3 Board ID error")
    end
    local boardID = ''
    -- The first byte will be the length of the register, which should either be 47 (ROM0) or 48 (ROM1 or later)
    if tonumber(data[1]) == 0x2F then
        -- if the length byte was 47, Board ID (BORD): byte offset 3, 4 bytes long
        for i = 5, 8 do
            boardID = string.format("%02X", tonumber(data[i])) .. boardID
        end
    elseif tonumber(data[1]) == 0x30 then
        -- if the length byte was 48, Board ID (BORD): byte offset 4, 8 bytes long
        for i = 6, 13 do
            boardID = string.format("%02X", tonumber(data[i])) .. boardID
        end
    else
        helper.flowLogFinish(false, paraTab, data, "Unknown length(1st byte) of reading from address '0x2C'")
        helper.reportFailure("Unknown length(1st byte) of reading from address '0x2C'")
    end
    Log.LogInfo("Ace3 Board ID", boardID)
    local Ace3BoardID = "0x" .. boardID
    Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 Board ID: " .. Ace3BoardID)

    local AcePlistFilePath = fileUtils.joinPaths(superBinaryPath, "SuperBinary.plist")
    local status, patchFilepath, appConfigFilepath = xpcall(Ace3FW.getAce3BuildFilePath, debug.traceback, Ace3BoardID,
                                                            Ace3PREV, AcePlistFilePath)
    if not status then
        helper.flowLogFinish(false, paraTab, patchFilepath, "Ace3FW.getAce3BuildFilePath fail")
        helper.reportFailure(patchFilepath)
    end

    local fileOperation
    if Device then
        fileOperation = Device.getPlugin("FileOperation")
    else
        fileOperation = Atlas.loadPlugin("SMTCommonPlugin").createFileManipulationUtility()
    end
    fileOperation.createDirectory(buildImageFolder)

    local binFileName = project .. "_" .. buildStage .. "_ACE3_FW.bin"
    local AceImagePath = fileUtils.joinPaths(buildImageFolder, binFileName)
    local AcePatchPath = fileUtils.joinPaths(superBinaryPath, patchFilepath)
    local AceAppConfigPath = fileUtils.joinPaths(superBinaryPath, appConfigFilepath)

    local result, ret = xpcall(Ace3FW.buildAce3Image, debug.traceback, AcePatchPath, AceAppConfigPath, AceImagePath)
    if not result then
        helper.flowLogFinish(false, paraTab, ret, result)
        helper.reportFailure(ret)
    end
    Ace3OTP.writeAce3Log(Ace3LogPath, "Create Ace3 FW Binary: " .. binFileName)

    local hostMD5 = generateMD5(AceImagePath)
    if hostMD5 then
        Ace3OTP.writeAce3Log(Ace3LogPath, "Create Ace3 FW MD5: " .. hostMD5)
        local hostMD5Data = hostMD5 .. "  " .. binFileName .. "\n"
        local hostMD5Path = fileUtils.joinPaths(buildImageFolder, "firmware.md5")
        local fileHandle = io.open(hostMD5Path, "a")
        fileHandle:write(hostMD5Data)
        fileHandle:close()
        helper.flowLogFinish(true, paraTab)
    else
        helper.flowLogFinish(false, paraTab, AceImagePath, "Generate MD5 error")
        helper.reportFailure('Generate MD5 error')
    end
    return hostMD5, binFileName
end

-- ! @brief Delete Ace3 FW bin folder
-- ! @details Delete Ace3 FW bin folder in /tmp/chx
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A
function Ace3FW.clearFixtureAndHostAceFW(paraTab)
    if not paraTab.InnerCall then
        helper.flowLogStart(paraTab)
    end
    local timeout = paraTab.Timeout
    assert(timeout ~= nil, "miss timeout")
    timeout = tonumber(timeout) --Pad use ms unit
    local fixturePluginName = paraTab.fixturePluginName 
    local fixture = Device.getPlugin(fixturePluginName)
    if fixture == nil or type(fixture.deleteFiles) ~= "function" then
        helper.reportFailure("fixture plugin or function is not exist")
    end

    local folder = fileUtils.joinPaths("Fixture" .. tostring(groupID), "ch" .. tostring(slotNumber))
    local reportStatus, serialNumber = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)

    if not reportStatus then
        local failureMessage = "Get serial number error"
        helper.flowLogFinish(false, paraTab, serialNumber, failureMessage)
        helper.reportFailure(failureMessage)
    end

    local Ace3LogFile = serialNumber .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log"
    Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log", Ace3LogFile)

    helper.LogFixtureControlStart("removeBinFolder folder:" .. folder, "nil", tostring(timeout))
    local status, result = xpcall(fixture.deleteFiles, debug.traceback, folder, timeout, slotNumber)
    Log.LogInfo('remove FW folder in fixture result: ' .. result)

    if status and string.find(result, "done") then
        helper.LogFixtureControlFinish("done")
    else
        helper.flowLogFinish(false, paraTab, "Delete_fixture_AceFW", "can not delete fixture AceFW")
        helper.reportFailure("can not delete fixture AceFW")
    end

    fileUtils.RemovePath(buildImageFolder)

    if comFunc.fileExists(buildImageFolder) then
        helper.flowLogFinish(false, paraTab, "Delete_Host_AceFW", "can not delete host AceFW")
        helper.reportFailure("can not delete host AceFW")
    end

    Ace3OTP.writeAce3Log(Ace3LogPath, "Clear Fixture And Host AceFW: " .. buildImageFolder)

    if not paraTab.InnerCall then
        helper.flowLogFinish(true, paraTab)
    end
end

-- ! @brief Erase Ace3 SPI Flash
-- ! @details Get the SPI chip name through the chip ID and chip list, erase this SPI Flash by chip name
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns AceChipName(string)
function Ace3FW.eraseAceSPIFlash(paraTab)
    helper.flowLogStart(paraTab)
    local timeout = paraTab.Timeout
    local expect = paraTab.expect
    assert(expect ~= nil and expect ~= "", "expect is invalid")
    assert(timeout ~= nil, "miss timeout")
    timeout = tonumber(timeout) -- iPad use ms unit
    local fixturePluginName = paraTab.fixturePluginName or "FixturePlugin"
    local fixture = Device.getPlugin(fixturePluginName)
    if fixture == nil or type(fixture.eraseAce3SPIFlash) ~= "function" then
        helper.reportFailure("fixture plugin or function is not exist")
    end

    local spiChipName

    helper.LogFixtureControlStart("ace_programmer_erase", nil, tostring(timeout))
    local eraseStatus, result = xpcall(fixture.eraseAce3SPIFlash, debug.traceback, timeout, slotNumber)
    helper.LogFixtureControlFinish(result)
    local attribute = paraTab.attribute
    if attribute then
        if eraseStatus and result then
            spiChipName = string.match(result, "chipName:(%w+).")
        end
        Log.LogInfo("spiChipName;" .. spiChipName)
        if spiChipName and spiChipName ~= 'None' and spiChipName ~= '' then
            DataReporting.submit(DataReporting.createAttribute(attribute, spiChipName))
        else
            helper.flowLogFinish(false, paraTab, attribute, "not define in fwdl_chip_config")
            helper.reportFailure('ace_programmer_id chip_name is Not define')
        end
        Ace3OTP.writeAce3Log(Ace3LogPath, "Erase Ace3 SPI Flash: " .. spiChipName)
    end

    if eraseStatus and string.find(result, expect) then
        helper.flowLogFinish(true, paraTab)
    else
        helper.flowLogFinish(false, paraTab, spiChipName)
        helper.reportFailure('ace_programmer_erase Error')
    end
end

-- ! @brief Transfer folder from host to fixture
-- ! @details Transfer Ace3 FW Bin and MD5 folder to fixture /tmp
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A
function Ace3FW.transferFilesFromHost2Fixture(paraTab)
    helper.flowLogStart(paraTab)
    local timeout = paraTab.Timeout
    assert(timeout ~= nil, "miss timeout")
    timeout = tonumber(timeout)
    local sendOrGet = paraTab.sendOrGet
    local fixturePath = paraTab.fixturePath
    local hostPath = paraTab.hostPath
    local fixturePluginName = paraTab.fixturePluginName or "FixturePlugin"
    local fixture = Device.getPlugin(fixturePluginName)
    if fixture == nil or type(fixture.transferFiles) ~= "function" then
        helper.reportFailure("fixture plugin or function is not exist")
    end

    fixturePath = fileUtils.joinPaths(fixturePath, "Fixture" .. tostring(groupID), "ch" .. tostring(slotNumber))
    hostPath = fileUtils.joinPaths(hostPath, "Fixture" .. tostring(groupID), "ch" .. tostring(slotNumber))
    helper.LogFixtureControlStart("transferFiles sendOrGet: " .. sendOrGet .. " fixturePath: " .. fixturePath ..
                                      " hostPath: " .. hostPath, "nil", tostring(timeout))
    local status, result = xpcall(fixture.transferFiles, debug.traceback, sendOrGet, hostPath, fixturePath, timeout,
                                  slotNumber)
    Log.LogInfo('transferFiles result: ' .. result)
    if status and string.find(result, "done") then
        helper.LogFixtureControlFinish("done")
        helper.flowLogFinish(true, paraTab, result)
    else
        helper.flowLogFinish(false, paraTab, defaultFailResult)
    end
    Ace3OTP.writeAce3Log(Ace3LogPath, "Transfer Files, from Host path: " .. hostPath)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Transfer Files, to Fixture path: " .. fixturePath)
end

-- ! @brief Program Ace3 SPI FW and Verify
-- ! @details Program Ace3 SPI FW, if program and verify ok record pass, otherwise report failure
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A
function Ace3FW.programAce3SPIFWAndVerify(paraTab)
    helper.flowLogStart(paraTab)
    local timeout = paraTab.Timeout
    local AceFwBinFile = paraTab.binFileName
    paraTab.InnerCall = true
    assert(timeout ~= nil, "miss timeout")
    assert(AceFwBinFile ~= nil, "parameters AceFwBinFile is nil")
    timeout = tonumber(timeout) * 1000
    local fixturePluginName = paraTab.fixturePluginName
    local fixture = Device.getPlugin(fixturePluginName)
    if fixture == nil or type(fixture.programAce3SPIFWAndVerify) ~= "function" then
        helper.reportFailure("fixture plugin or function is not exist")
    end

    helper.LogFixtureControlStart("programAce3SPIFWAndVerify", "nil", tostring(timeout))
    local status, result = xpcall(fixture.programAce3SPIFWAndVerify, debug.traceback, AceFwBinFile, timeout, slotNumber)
    helper.LogFixtureControlFinish(result)
    if status and string.find(result, "program ok") and string.find(result, "road target done") then
        Log.LogInfo("road target done", result)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Program Ace3 SPI FW And Verify: " .. AceFwBinFile)
        local skipCompareAce3FW = paraTab.skipCompareAce3FW
        if skipCompareAce3FW == "True" then
            Ace3OTP.writeAce3Log(Ace3LogPath, "Skip Dump Ace3 FW and compare md5 verification on host")
            Ace3FW.clearFixtureAndHostAceFW(paraTab)
        else
            Ace3FW.dumpAndCompareDUTAce3FW(paraTab) 
        end
        helper.flowLogFinish(true, paraTab)
    else
        Ace3FW.clearFixtureAndHostAceFW(paraTab)
        local subsubtestname = paraTab.subsubtestname .. "_Program"
        helper.flowLogFinish(false, paraTab, defaultFailResult, 'binSize match failed or program not ok', subsubtestname)
        helper.reportFailure('ace_programmer_only Error or binSize match failed')
    end
end

-- ! @brief Dump DUT Ace3 FW and compare with orignal
-- ! @details Readback the Ace3 FW from DUT and compare the MD5 value with primary data
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A
function Ace3FW.dumpAndCompareDUTAce3FW(paraTab)
    local timeout = paraTab.Timeout
    assert(timeout ~= nil, "miss timeout")
    timeout = tonumber(timeout) * 1000
    local fixturePluginName = paraTab.fixturePluginName
    local fixture = Device.getPlugin(fixturePluginName)
    if fixture == nil or type(fixture.transferFiles) ~= "function" then
        helper.reportFailure("fixture plugin or function is not exist")
    end

    local readBackFileName = paraTab.fileName
    local sendOrGet = paraTab.sendOrGet
    local fixturePath = paraTab.fixturePath
    local hostPath = paraTab.hostPath
    fixturePath = fileUtils.joinPaths(fixturePath, "Fixture" .. tostring(groupID), "ch" .. tostring(slotNumber),
                                      readBackFileName)
    hostPath = fileUtils.joinPaths(hostPath, "Fixture" .. tostring(groupID), "ch" .. tostring(slotNumber))

    local MD5Hard = paraTab.hostMD5
    Log.LogInfo('MD5Hard: ' .. MD5Hard)
    local AceFWPath = fileUtils.joinPaths(hostPath, "ACE_FW.readback")
    fileUtils.RemovePath(AceFWPath)

    local status, result = xpcall(fixture.transferFiles, debug.traceback, sendOrGet, hostPath, fixturePath, timeout,
                                  slotNumber)
    if status and string.find(result, "done") then
        helper.LogFixtureControlFinish("done")
    else
        helper.flowLogFinish(false, paraTab, result, "transferFiles")
        helper.reportFailure('transferFiles Error')
    end

    local MD5ComputedDUT = generateMD5(AceFWPath)
    Log.LogInfo('MD5Hard:' .. MD5Hard .. " " .. type(MD5Hard))
    Log.LogInfo('MD5ComputedDUT:' .. MD5ComputedDUT .. " " .. type(MD5ComputedDUT))
    Ace3OTP.writeAce3Log(Ace3LogPath, "Dump And Compare DUT Ace3 FW MD5Hard:        " .. MD5Hard)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Dump And Compare DUT Ace3 FW MD5ComputedDUT: " .. MD5ComputedDUT)
    Ace3FW.clearFixtureAndHostAceFW(paraTab)
    if MD5Hard ~= MD5ComputedDUT then
        local subsubtestname = paraTab.subsubtestname .. "_MD5"
        helper.flowLogFinish(false, paraTab, MD5Hard, "MD5 match failed")
        helper.reportFailure('checkUUTACEFW Error')
    end
end

-- ! @brief Write word data to number table
-- ! @details Write 4 Bytes word data to number table as little Endian format
-- ! @param content(table) Orignal number table, e.g. {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}
-- ! @param word(string) word data, e.g. 0xace00003
-- ! @param start(table) location for replace, e.g. 0
-- ! @returns N/A raise error if word lenth is wrong
-- ! e.g. content => {0x03, 0x00, 0xe0, 0xac, 0xff, 0xff, 0xff, 0xff}
local function write4BytesWordToTable(content, word, start)
    if (#word) ~= 10 then
        error("word length is not 10")
    end
    word = string.gsub(word, "0x", "")
    for idx = 1, #word, 2 do
        local value = tonumber(string.sub(word, idx, idx + 1), 16)
        content[start + 4 - (idx + 1) / 2] = value
    end
end

-- ! @brief Get nonce with length
-- ! @details Get a Nonce by random data of 16 bytes
-- ! @returns temp(string) 16 bytes nonce, e.g. 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA55'
local function getNonce()
    local template = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    local d = io.open("/dev/urandom", "r"):read(4)
    math.randomseed(os.time() + d:byte(1) + (d:byte(2) * 256) + (d:byte(3) * 65536) + (d:byte(4) * 4294967296))
    return string.gsub(template, "x", function(c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end

-- ! @brief Convert hex string to Binary string
-- ! @param hex(string) Hex string, e.g. 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA55'
-- ! @returns str(string) Binary string
local function hex2str(hex)
    local str, _ = hex:gsub("(%x%x)[ ]?", function(word)
        return string.char(tonumber(word, 16))
    end)
    return str
end

-- ! @brief Get BNCH of nonce
-- ! @details The first 16 bytes of the SHA-256 hash of that Nonce
-- ! @param nonce(string) Hex string, e.g. 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA55'
-- ! @returns BNCH(string) 16 bytes of SHA-256 hash e.g. '7978fa22f27a9c498382db39920d2155'
local function getBNCH(nonce)
    local binString = hex2str(nonce)
    local tempPath = fileUtils.joinPaths(buildImageFolder, "sha256.txt")
    fileUtils.WriteStringToFile(tempPath, binString, "w")

    local status, utilities = xpcall(Device.getPlugin, debug.traceback, 'Utilities')
    if not status then
        utilities = Atlas.loadPlugin('Utilities')
    end

    local sha256 = securityUtils.generateDigestFromFile(utilities, tempPath, Security.Digests.SHA256)
    if not sha256 or sha256 == "" then
        error("invalid BNCH value")
    end

    local BNCH = string.sub(sha256, 1, 32)
    return BNCH
end

-- ! @brief Save data to bin file
-- ! @details Save the data table to Binary file
-- ! @param data(table) Number table, e.g. {65, 67, 69, 51, 79, 84, 80}
-- ! @param filePath(string) File path
-- ! @returns N/A
local function saveBinaryFile(data, filePath)
    local binString
    if data[0] then
        binString = string.char(data[0])
    else
        binString = ''
    end

    local packFormat = "<" .. string.rep("B", #data)
    binString = binString .. string.pack(packFormat, table.unpack(data))

    fileUtils.WriteStringToFile(filePath, binString, "w")
end

-- ! @brief construct Command
-- ! @details command arguments construction from input as array.
-- ! @param args(table) command arguments
-- ! @returns shellCmd(string) shell Command
local function constructCommand(args)
    local shellCmd = ""
    for keyWord, value in pairs(args) do
        shellCmd = shellCmd .. " " .. keyWord .. "=" .. value
    end
    return shellCmd
end

-- ! @brief get data with length
-- ! @details get resver data that from start location to byte length in the table
-- ! @param dataString(string) pack sting data, e.g. ACE3OTP
-- ! @param start(number) start index, e.g. 1
-- ! @param byteLength(number) byte length, e.g. 2
-- ! @returns result(string) hex string, e.g. '0x50544F33454341'
local function getDataFromString(dataString, start, byteLength)
    local result = ""
    for i = tonumber(start), tonumber(start) + byteLength - 1 do
        result = string.format("%02X", string.unpack('<B', dataString, i)) .. result
    end
    return "0x" .. result
end

-- ! @brief Get Ace3 parameters
-- ! @details Get Ace3 parameters from I2C data
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns Ace3(table) Ace3 parameters table, raise error if I2C data invalid
function Ace3FW.getAce3Parameters(paraTab)
    local fixturePluginName = paraTab.fixturePluginName
    local i2cAddress = paraTab["deviceAddress"]
    local reportStatus, serialNumber = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
    if not reportStatus then
        local failureMessage = "Get serial number error"
        helper.reportFailure(failureMessage)
    end
    local Ace3LogFile = serialNumber .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log"
    Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log", Ace3LogFile)

    local readAce3Parameters = Ace3OTP.readAce3I2C(fixturePluginName, i2cAddress, "0x2C", 49)
    local data = comFunc.splitString(readAce3Parameters, ",")
    if #data < 49 then
        Log.LogInfo("Read Ace3 Board ID error", data)
        helper.reportFailure("Read Ace3 Board ID error")
    end

    local offsetValue
    local lengthBORD
    local length0x2CROM0 = 0x2F
    local length0x2CROM1 = 0x30
    -- The first byte will be the length of the register, which should either be 47 (ROM0) or 48 (ROM1 or later)
    if tonumber(data[1]) == length0x2CROM0 then
        lengthBORD = 4
        offsetValue = {0, 3, 19, 21, 22, 23}
    elseif tonumber(data[1]) == length0x2CROM1 then
        lengthBORD = 8
        offsetValue = {0, 4, 20, 22, 23, 24}
    else
        Log.LogInfo("Unknown length(1st byte) of reading from address ‘0x2C’", data)
        helper.reportFailure("Unknown length(1st byte) of reading from address ‘0x2C’")
    end

    local shift = 2
    local offsetCHIP = shift + offsetValue[1]
    local offsetBORD = shift + offsetValue[2]
    local offsetCPFM = shift + offsetValue[3]
    local offsetSDOM = shift + offsetValue[4]
    local offsetPREV = shift + offsetValue[5]
    local offsetECID = shift + offsetValue[6]

    local packFormat = "<" .. string.rep("B", 49)
    local dataString = string.pack(packFormat, table.unpack(data))

    local Ace3 = {}
    -- ROM0 byte offset 0, 2 bytes long
    Ace3.chipID = getDataFromString(dataString, offsetCHIP, 2)
    -- ROM0 byte offset 3, 4 bytes long
    Ace3.boardID = getDataFromString(dataString, offsetBORD, lengthBORD)
    -- ROM0 byte offset 19, bit offset 1
    Ace3.CPFM = getDataFromString(dataString, offsetCPFM, 1)
    -- ROM0 byte offset 21, 3 bits long
    Ace3.SDOM = getDataFromString(dataString, offsetSDOM, 1)
    -- ROM0 Byte offset 22, 1 byte long
    Ace3.PREV = getDataFromString(dataString, offsetPREV, 1)
    -- ROM0 byte offset 23, 8 bytes long
    Ace3.ECID = getDataFromString(dataString, offsetECID, 8)

    local shiftCSEC = 1
    local shiftCPRO = 2
    local maskCSEC = 0x02
    local maskCPRO = 0x04
    -- ROM0 byte offset 19, bit offset 1 (use the mask 0x02 on byte offset 19)
    Ace3.CSEC = tostring((tonumber(Ace3.CPFM) & maskCSEC) >> shiftCSEC)
    -- ROM0 byte offset 19, bit offset 2 (use the mask 0x04 on byte offset 19)
    Ace3.CPRO = tostring((tonumber(Ace3.CPFM) & maskCPRO) >> shiftCPRO)

    -- ROM0 byte offset 21, 3 bits long (mask off the higher order 5 bits from the byte at offset 21)
    local maskSDOM = 0x07
    Ace3.SDOM = tostring(tonumber(Ace3.SDOM) & maskSDOM)
    Ace3.PREV = tostring(tonumber(Ace3.PREV))
    Ace3.boardID = string.format("0x%08X", tonumber(Ace3.boardID))

    Log.LogInfo("Ace3 Board ID", Ace3.boardID)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 Board ID: " .. Ace3.boardID)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 Chip ID: " .. Ace3.chipID)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 CSEC: " .. Ace3.CSEC)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 CPRO: " .. Ace3.CPRO)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 SDOM: " .. Ace3.SDOM)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 PREV: " .. Ace3.PREV)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 ECID: " .. Ace3.ECID)

    return Ace3
end

-- ! @brief create Ace3 FW binary from bundle
-- ! @details Get the Ace3 parameters, Use goldrestore2 to creating personalized Ace3Image from a UARP superbinary
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns nonce(string)
function Ace3FW.buildAce3ImageWithGR2(paraTab)
    local timeout = paraTab.Timeout
    assert(timeout ~= nil, "miss timeout")
    timeout = tonumber(timeout) * 1000
    local inputUARP = paraTab.inputUARP
    local expectedKeyWord = paraTab.expectedKeyWord
    local SoCCSEC = paraTab["SoC_CSEC"]

    local outputFirmware = fileUtils.joinPaths(buildImageFolder, "outputFirmware.bin")
    if comFunc.fileExists(inputUARP) then
        Log.LogInfo("InputUARP File:", inputUARP)
    else
        Log.LogInfo("InputUARP File does not exist:", inputUARP)
        helper.reportFailure("InputUARP File does not exist")
    end

    local status, Ace3 = xpcall(Ace3FW.getAce3Parameters, debug.traceback, paraTab)
    if not status then
        Log.LogInfo("Read Ace3 parameters error")
        helper.reportFailure("Read Ace3 parameters error")
    end

    local expectID = 0x0022
    if tonumber(Ace3.chipID) ~= expectID then
        Log.LogInfo("For all Ace3's, ChipID value should be `0x0022`, ChipID value:" .. tostring(Ace3.chipID))
        helper.reportFailure("ChipID value invalid")
    end

    if tonumber(Ace3.CSEC) ~= tonumber(SoCCSEC) then
        Log.LogInfo("Ace3_CSEC match failed with SoC_CSEC:" .. tostring(SoCCSEC))
        helper.reportFailure("Ace3_CSEC match failed with SoC_CSEC")
    end

    local nonce = getNonce()
    local BNCH = getBNCH(nonce)

    local Ace3LUN = paraTab["Ace3LUN"]
    if not Ace3LUN then
        Log.LogInfo("Ace3_LUN does not exist")
        helper.reportFailure("Ace3_LUN does not exist")
    end

    local serverURL = "http://spidercab:8080"
    local goldrestoreTool = paraTab.goldrestoreTool
    local args = {}
    local securityMode
    local unpersonalization = 0
    if tonumber(SoCCSEC) == unpersonalization then
        securityMode = false
        args["boardID"] = Ace3.boardID
        args["platformRevision"] = Ace3.PREV
        args["inputUARP"] = inputUARP
        args["outputFirmware"] = outputFirmware
    else
        securityMode = true
        args["boardID"] = Ace3.boardID
        args["chipID"] = Ace3.chipID
        args["ecid"] = Ace3.ECID
        args["nonce"] = BNCH
        args["platformRevision"] = Ace3.PREV
        args["productionStatus"] = Ace3.CPRO
        args["securityDomain"] = Ace3.SDOM
        args["securityMode"] = Ace3.CSEC
        args["inputUARP"] = inputUARP
        args["outputFirmware"] = outputFirmware
        args["LogicalUnitNumber"] = Ace3LUN
        args["serverURL"] = serverURL
    end
    local shellCmd = goldrestoreTool .. " " .. "ace3 personalize" .. constructCommand(args)
    if securityMode then
        shellCmd = "cd /tmp/Fixture" .. tostring(groupID) .. "/ch" .. tostring(slotNumber) .. " && " .. shellCmd
    end
    local runShellCommand
    local statusPlugin, ret = xpcall(Device.getPlugin, debug.traceback, 'RunShellCommand')
    if statusPlugin then
        runShellCommand = ret
    else
        runShellCommand = Atlas.loadPlugin('RunShellCommand')
    end
    local shellComRes = runShellCommand.run(shellCmd, timeout)

    -- some response will put in error info, so need combine output info and error info as shell cmd response
    if not shellComRes.error then
        shellComRes.error = ""
    end
    local shellResp = shellComRes.error .. "\n" .. shellComRes.output

    local result = false
    if expectedKeyWord and expectedKeyWord ~= "" then
        if string.find(shellResp, expectedKeyWord) then
            result = true
        end
    elseif shellComRes.returnCode == 0 then
        result = true
    end
    Log.LogInfo("RunShellCommand returnCode and shellResp:", shellComRes.returnCode, shellResp)

    if result == false then
        Log.LogInfo("Generating personalized firmware file error")
        helper.reportFailure("Generating personalized firmware file error")
    end

    return nonce, securityMode
end

-- ! @brief create Ace3 SPI Image from a SuperBinary bundle
-- ! @details Complete Ace3 SPI image by Ace3Image, Offsets and boot nonce together, and then generate MD5
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns hostMD5(string), binFileName(string)
function Ace3FW.createAce3SPIImage(paraTab)
    helper.flowLogStart(paraTab)
    local project = paraTab.Product
    local buildStage = paraTab.Build_Stage

    local reportStatus, serialNumber = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
    if not reportStatus then
        local failureMessage = "Get serial number error"
        helper.flowLogFinish(false, paraTab, "Get_serial_number", failureMessage)
        helper.reportFailure(failureMessage)
    end
    local Ace3LogFile = serialNumber .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log"
    Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log", Ace3LogFile)
    Ace3OTP.writeAce3Log(Ace3LogPath, "----------------------- Start Ace3 FWDL... -----------------------")
    Ace3OTP.writeAce3Log(Ace3LogPath, "Read Ace3 parameters")

    local fileOperation
    if Device then
        fileOperation = Device.getPlugin("FileOperation")
    else
        fileOperation = Atlas.loadPlugin("SMTCommonPlugin").createFileManipulationUtility()
    end
    fileOperation.createDirectory(buildImageFolder)

    local status, nonce, securityMode = xpcall(Ace3FW.buildAce3ImageWithGR2, debug.traceback, paraTab)
    if not status then
        helper.flowLogFinish(false, paraTab, "Build_Ace3Image_With_GR2", "Build Ace3Image With GR2 error")
        helper.reportFailure("Build Ace3Image With GR2 error")
    end

    local outputFirmware = fileUtils.joinPaths(buildImageFolder, "outputFirmware.bin")
    local fileHandleConfig = io.open(outputFirmware, "rb")
    local generateFWData = fileHandleConfig:read("*all")
    fileHandleConfig:close()
    local generateFWContent = bin2NumberTable(generateFWData)
    local generateFWSize = #generateFWData
    Log.LogInfo("Ace3Image Size:", generateFWSize)

    fileUtils.RemovePath(outputFirmware)

    local AceImageSPIContent = {}
    for i = 0, 0x3FFF do
        AceImageSPIContent[i] = 0xFF
    end
    write4BytesWordToTable(AceImageSPIContent, "0x00004000", 0)
    write4BytesWordToTable(AceImageSPIContent, "0x00000000", 0xFFC)

    local Ace3RegionHeaderOffset = 0x4000
    local Ace3ImageSize = Ace3RegionHeaderOffset + generateFWSize
    if Ace3ImageSize > 0x81000 then
        helper.reportFailure("The image after leaving Step 5 is more than 0x81000 bytes long")
    end

    local index = 0
    for i = Ace3RegionHeaderOffset, Ace3ImageSize - 1 do
        AceImageSPIContent[i] = generateFWContent[index]
        index = index + 1
    end

    if securityMode then
        -- Pad the image out to `0x82000` bytes long. The pad bytes should all be `0xFF`
        local Ace3ImageSPISize = 0x82000
        for i = Ace3ImageSize, Ace3ImageSPISize - 1 do
            AceImageSPIContent[i] = 0xFF
        end

        -- Write the 16-byte Nonce used in Step 3 to offset `0x81000` in the image
        local idx = 1
        for i = 0x81000, 0x81000 + 15 do
            AceImageSPIContent[i] = tonumber(string.sub(nonce, idx, idx + 1), 16)
            idx = idx + 2
        end
        -- Write 4 bytes of `0x00` to offset `0x81010` in the image.
        write4BytesWordToTable(AceImageSPIContent, "0x00000000", 0x81010)
    end

    local binFileName = project .. "_" .. buildStage .. "_ACE3_FW.bin"
    local AceImageSPIPath = fileUtils.joinPaths(buildImageFolder, binFileName)

    Log.LogInfo("SPI Image Path:", AceImageSPIPath)

    local saveStatus = xpcall(saveBinaryFile, debug.traceback, AceImageSPIContent, AceImageSPIPath)
    if not saveStatus then
        helper.flowLogFinish(false, paraTab, "Save_Bin_File", "Save bin file error")
        helper.reportFailure("Save bin file error")
    end
    Ace3OTP.writeAce3Log(Ace3LogPath, "Create Ace3 FW Binary: " .. binFileName)

    local hostMD5 = generateMD5(AceImageSPIPath)
    if hostMD5 then
        Ace3OTP.writeAce3Log(Ace3LogPath, "Create Ace3 FW MD5: " .. hostMD5)
        local hostMD5Data = hostMD5 .. "  " .. binFileName .. "\n"
        local hostMD5Path = fileUtils.joinPaths(buildImageFolder, "firmware.md5")
        local fileHandle = io.open(hostMD5Path, "a")
        fileHandle:write(hostMD5Data)
        fileHandle:close()
        helper.flowLogFinish(true, paraTab)
    else
        helper.flowLogFinish(false, paraTab, defaultFailResult)
        helper.reportFailure('Generate MD5 error')
    end

    return hostMD5, binFileName
end

return Ace3FW
