-- local variables
local Ace3OTP = {}
local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local helper = require("Tech/SMTLoggingHelper")
local fileUtils = require "ALE/FileUtils"
local crc32 = require("Tech/Ace3CRC32")

local SoC_CPFM
local SoC_CHIP = ''
local SYS_BORD = ''
local SoC_SDOM = ''
local SoC_CSEC = ''
local SoC_CPRO = ''
local SYS_BREV = ''
local matchDataPayLoadTag = ''
local dataI2CAddress = ''

local payloadFilepath = ''
local Ace3_PORT
local Ace3_RREV
local Ace3_PART
local Ace3_PREV
local Ace3_TYPE

local computedOTPBinCRC1 = ''
local computedOTPBinCRC2 = ''
local computedOTPBinCRC3 = ''

local Ace3_CRC1_I2C
local Ace3_CRC2_I2C
local Ace3_CRC3_I2C

local Ace3LogPath
local Ace3OTPContent = {}
local power
local Ace3Type

-- local ForceOTP = true

local errorCode = {
    [110] = "error message: unable to determine OTP MetaData record",
    [111] = "error message: unable to compute Product Revision",
    [112] = "error message: unable to determine OTP payload 4cc",
    [113] = "error message: unable to locate OTP payload 4cc",
    [114] = "error message: Ace3 OTP.bin file size error",
    [115] = "error message: Ace3 OTP.bin file header error",
    [116] = "error message: Ace3_PART mismatch",
    [117] = "error message: Ace3_RREV mismatch",
    [118] = "error message: failed to complete force-DFU command",
    [119] = "error message: failed to enter Ace DFU",
    [120] = "error message: failed to read OTP region,unexpected error",
    [121] = "error message: CRC1 value mismatch",
    [122] = "error message: part failed to program OTP,unexpected error",
    [123] = "error message: Customer Word OTP programming command failed",
    [124] = "error message: OTP programming CRC failed",
    [125] = "error message: Ace3 OTP.bin file Pre CRC error",
    [126] = "error message: OTP bin file not found",
    [127] = "error message: CPFM not found",
    [128] = "error message: Ace3_PORT not found",
    [129] = "error message: Ace3Parameters.plist does not exist",
    [130] = "error message: SuperBinary.plist does not exist",
    [131] = "error message: Program OTP Data invalid",
    [132] = "error message: USBTool not supoort",
    [133] = "error message: SYS_BREV invalid",
    [134] = "error message: Related SPI/UART Ace not match",
    [135] = "error message: failed to get Ace ECID"
}

local groupID, slotNumber = string.match(Device.identifier, "G%=([0-9]+):S%=slot([0-9]+)")
slotNumber = tonumber(slotNumber)
local sn
local reportStatus, resp = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
if reportStatus then
    sn = resp
else
    sn = "null"
end
Ace3LogPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log",
                                  sn .. "_Ace3_G" .. tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".log")

-- local Functions

-- ! @brief get RunShellCommand plugin
-- ! @details N/A
-- ! @param N/A
-- ! @returns RunShellCommand from Device or Atlas.
local function getRunShellCommandPlugin()
    local status, ret = xpcall(Device.getPlugin, debug.traceback, 'RunShellCommand')
    if status then
        return ret
    else
        return Atlas.loadPlugin('RunShellCommand')
    end
end

-- ! @brief create time utility
-- ! @details N/A
-- ! @param N/A
-- ! @returns time utilities from Device. or Atlas.
local function getTimeUtilityPlugin()
    if Device then
        return Device.getPlugin("TimeUtility")
    else
        return Atlas.loadPlugin("SMTCommonPlugin").createTimeUtility()
    end
end

-- ! @brief Prompt error information and report an error
-- ! @details Report an error message based on the error ID
-- ! @param errorID(number) error ID
-- ! @returns N/A
local function raiseError(errorID)
    local errorMsg = errorCode[errorID]
    Ace3OTP.writeAce3Log(Ace3LogPath, errorMsg)
    helper.reportFailure(errorMsg)
end

-- ! @brief create Ace3 OTP Log file
-- ! @details Create Ace OTP log at path Device.userDirectory for reference
-- ! @param N/A
-- ! @returns N/A
function Ace3OTP.createAceLog()
    local fileOperation
    if Device then
        fileOperation = Device.getPlugin("FileOperation")
    else
        fileOperation = Atlas.loadPlugin("SMTCommonPlugin").createFileManipulationUtility()
    end
    fileOperation.createDirectory(fileUtils.joinPaths(Device.userDirectory, "Ace3_Log/"))
    getTimeUtilityPlugin().delay(0.1)

    Log.LogInfo("Ace3LogPath:", Ace3LogPath)
    if comFunc.fileExists(Ace3LogPath) then
        Log.LogInfo(Ace3LogPath .. " existed")
    else
        io.open(Ace3LogPath, "w+")
    end
end

-- ! @brief create Program OTP data bin file
-- ! @details Create Ace OTP data bin file at path Device.userDirectory for reference
-- ! @param dataForWrite(table) Program OTP data
-- ! @param keyName(string) Which content will be saved
-- ! @returns true/false(boolean)
local function saveDataProgramOTP(dataForWrite, keyName)
    local binString
    if type(dataForWrite) == "table" then
        if dataForWrite[0] then
            binString = string.pack('B', dataForWrite[0])
        else
            binString = ''
        end
        for i = 1, #dataForWrite do
            binString = binString .. string.pack('B', dataForWrite[i])
        end
    else
        raiseError(131)
    end

    local timestamp = string.format(os.date("%Y-%m-%d_%H-%M-%S", os.time()))
    local portNum = tostring(tonumber(Ace3_PORT))
    local Ace3DataPath = fileUtils.joinPaths(Device.userDirectory, "Ace3_Log",
                                             sn .. keyName .. timestamp .. "_Port" .. portNum .. "_G" ..
                                                 tostring(groupID) .. "_Slot" .. tostring(slotNumber) .. ".bin")

    local fileHandle = io.open(Ace3DataPath, "wb")
    fileHandle:write(binString)
    fileHandle:close()
    return true
end

-- ! @brief write Ace3 Log
-- ! @details Write Ace OTP Log to path of Device.userDirectory
-- ! @param flag(sting) log header
-- ! @param data(sting) log content
-- ! @returns N/A
function Ace3OTP.writeAce3Log(logPath, header, data)
    local timestamp = getTimeUtilityPlugin().getTimeStampString()

    local f = assert(io.open(logPath, "a"))

    if data == nil then
        helper.flowLogDebug(header)
        f:write(timestamp .. "\t" .. header .. "\t" .. "\r\n")
    else
        helper.flowLogDebug(header .. tostring(data))
        f:write(timestamp .. "\t" .. header .. "\t" .. tostring(data) .. "\r\n")
    end

    f:close()
end

-- ! @brief Get SoC Parameters
-- ! @details Get OTP program information from usb tree
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A raise error if SoC_CPFM is not "00", "01" or "03"
local function getSoCParameters(paraTab)
    local USBTool = paraTab.USBTool or "/usr/local/bin/usbterm -list"
    local runShellCommand = getRunShellCommandPlugin()
    local data = runShellCommand.run(USBTool).output
    local dataUSB = ""
    local pattern
    local usbLocation = paraTab.usbLocation or ""
    Ace3OTP.writeAce3Log(Ace3LogPath, "USB Location ID: ", usbLocation)

    if string.find(USBTool, "usbterm") then
        pattern = usbLocation .. ",%s*SDOM:(%w+)%s*CPID:(%w+)%s*CPRV:%w+%sCPFM:(%w+)%s*SCEP:%w+%s*BDID:(%w+)%s*"
        local usbTree = comFunc.splitString(data, "\n")
        for _, v in pairs(usbTree) do
            if string.find(v, usbLocation) then
                dataUSB = v
                break
            end
        end
    elseif string.find(USBTool, "ioreg") then
        pattern = "%s*SDOM:(%w+)%s*CPID:(%w+)%s*CPRV:%w+%sCPFM:(%w+)%s*SCEP:%w+%s*BDID:(%w+)%s*"
        local usbTree = comFunc.splitString(data, "}")
        local patternLoc = "kUSBSerialNumberString" .. ".-\"locationID\" = " .. tostring(tonumber(usbLocation))
        Log.LogInfo("Pattern base on Location ID: " .. patternLoc)
        for _, v in pairs(usbTree) do
            local position = string.find(v, patternLoc)
            if position then
                dataUSB = string.sub(v, position)
                break
            end
        end
    elseif string.find(USBTool, "kistool") then
        pattern = "%s*SDOM:(%w+)%s*CPID:(%w+)%s*CPRV:%w+%sCPFM:(%w+)%s*SCEP:%w+%s*BDID:(%w+)%s*"
        local patternLoc = "Location ID: " .. usbLocation .. ".-iBoot"
        Log.LogInfo("Pattern base on Location ID: " .. patternLoc)
        dataUSB = string.sub(data, string.find(data, patternLoc))
        Log.LogInfo("String contain SDOM CPID CPFM BDID is: " .. dataUSB)
    elseif string.find(USBTool, "None") then
        local boardRevSFC = paraTab["SYS_BREV"] or ""
        boardRevSFC = boardRevSFC:sub(1, 2) == "0b" and tonumber(boardRevSFC:sub(3), 2) or tonumber(boardRevSFC)
        SYS_BREV = SYS_BREV:sub(1, 2) == "0b" and tonumber(SYS_BREV:sub(3), 2) or tonumber(SYS_BREV)
        if boardRevSFC ~= SYS_BREV then
            raiseError(133)
        end

        SoC_SDOM = paraTab["SoC_SDOM"]
        SoC_CHIP = paraTab["SoC_CHIP"]
        SYS_BORD = paraTab["SYS_BORD"]
        SoC_CSEC = paraTab["SoC_CSEC"]
        SoC_CPRO = paraTab["SoC_CPRO"]

        local maskSDOM = 0x07
        SoC_SDOM = tonumber(string.gsub(SoC_SDOM, "^0b", ""), 2) & maskSDOM
        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 1.1 ----------------------------")
        Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SoC_SDOM: " .. string.format("0x%02X", SoC_SDOM))
        SoC_CHIP = tonumber(SoC_CHIP)
        Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SoC_CHIP: " .. SoC_CHIP)
        SYS_BORD = tonumber(SYS_BORD)
        Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SYS_BORD: " .. SYS_BORD)

        SoC_CSEC = tonumber(string.gsub(SoC_CSEC, "^0b", ""), 2)
        SoC_CPRO = tonumber(string.gsub(SoC_CPRO, "^0b", ""), 2)
        if SoC_CSEC < 0 or SoC_CSEC > 1 or SoC_CPRO < 0 or SoC_CPRO > 1 then
            raiseError(127)
        end
        Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SoC_CSEC: " .. SoC_CSEC)
        Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SoC_CPRO: " .. SoC_CPRO)
        return true
    else
        raiseError(132)
    end

    if #dataUSB == 0 then
        Log.LogInfo("USB tree data: ", data)
    end
    Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 1.0 ----------------------------")
    Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--" .. USBTool .. ": ", dataUSB)

    SoC_SDOM, SoC_CHIP, SoC_CPFM, SYS_BORD = string.match(dataUSB, pattern)

    local mask3Bits = 0x07
    SoC_SDOM = tonumber("0x" .. SoC_SDOM) & mask3Bits
    Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 1.1 ----------------------------")
    Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SoC_SDOM: " .. string.format("0x%02X", SoC_SDOM))
    SoC_CHIP = tonumber("0x" .. SoC_CHIP)
    Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SoC_CHIP: " .. SoC_CHIP)
    SYS_BORD = tonumber("0x" .. SYS_BORD)
    Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SYS_BORD: " .. SYS_BORD)

    if SoC_CPFM == "00" then
        SoC_CSEC = 0
        SoC_CPRO = 0
    elseif SoC_CPFM == "01" then
        SoC_CSEC = 1
        SoC_CPRO = 0
    elseif SoC_CPFM == "03" then
        SoC_CSEC = 1
        SoC_CPRO = 1
    else
        raiseError(127)
    end

    Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SoC_CSEC: " .. SoC_CSEC)
    Ace3OTP.writeAce3Log(Ace3LogPath, "getSoCParameters--SoC_CPRO: " .. SoC_CPRO)
end

-- ! @brief read OTP Bin file
-- ! @details Read OTP bin file with file path
-- ! @param filePath(sting) OTP file path
-- ! @returns content(string)
local function readBinFile(filePath)
    local f = assert(io.open(filePath, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

-- ! @brief Big Endian format
-- ! @details convert hex string as Big Endian format
-- ! @param str(string) to be converted string, e.g. '0x7F 0x28 0x09 0x15'
-- ! @returns hex(string) e.g. '0x7F280915'
local function bigEndianFormat(str)
    local stringData = ""
    for i in string.gmatch(str, "0x(%x%x)") do
        stringData = stringData .. i
    end
    return "0x" .. stringData
end

-- ! @brief Toggle endian format
-- ! @details Toggle endian format between Little Endian and Big Endian
-- ! @param str(string) to be converted string, e.g. '0x7F280915'
-- ! @returns hex(string) e.g. '0x1509287F'
local function toggleEndian(str)
    local stringData = ""
    for i in string.gmatch(str, "(%x%x)") do
        stringData = i .. stringData
    end
    return "0x" .. stringData
end

-- ! @brief Get Ace data from AdditionalParameters
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns true or false
local function getAceDataFromAdditionalParameters(paraTab)
    SYS_BREV = paraTab.SYS_BREV
    Ace3_RREV = paraTab.Ace3_RREV
    Ace3_PART = paraTab.Ace3_PART
    Ace3_TYPE = paraTab.Ace3_TYPE
    if SYS_BREV and Ace3_RREV and Ace3_PART and Ace3_TYPE then
        return true
    else
        return false
    end
end

-- ! @brief Get Ace data from Ace3Parameters.plist
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns true or false
local function getAceDataFromAce3ParametersPlist(paraTab)
    local cfgType = paraTab.CFG_type
    local buildStage = paraTab.Build_Stage
    Ace3_PORT = paraTab.Ace3_PORT

    local pListSerialization = Atlas.loadPlugin("PListSerializationPlugin")
    local plistData
    local assetsPath = Atlas.assetsPath
    if comFunc.fileExists(assetsPath .. "/Ace3Parameters.plist") then
        plistData = pListSerialization.decodeFile(assetsPath .. "/Ace3Parameters.plist")
    else
        raiseError(129)
    end

    local product = paraTab.Product
    local productData = plistData[product]
    Log.LogInfo("buildStageData: ", comFunc.dump(productData))
    Ace3OTP.writeAce3Log(Ace3LogPath, "Product: ", product)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Build_Stage: ", buildStage)

    for _, v in pairs(productData[buildStage][cfgType]) do
        if Ace3_PORT == v["Ace3_PORT"] then
            return v
        end
    end
    return false
end

-- ! @brief Check Ace3 type
-- ! @param matchingRelationship(string) OTP Matching Data Relationship value in the superbinary.plist
-- ! @param Ace3TypeValueFromPlist(string) The Ace3 Type value of current Ace3 port
-- ! @param matchingRecord4CC(string) The "Record 4CC" value of the corresponding OTP record
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns flagAce3UART(string) Ace3 flag of UART type
local function checkAce3Type(Ace3TypeValueFromPlist, matchingRelationship, matchingRecord4CC, paraTab)
    local record4CCSPI = paraTab["record4CCSPI"]
    local relationshipSPI = paraTab["relationshipSPI"]
    if Ace3TypeValueFromPlist == "UART" then
        if matchingRelationship:sub(1, 4) ~= "UART" then
            raiseError(134)
        end
        Ace3Type = "UART"
    elseif Ace3TypeValueFromPlist == "SPI" then
        if matchingRelationship and matchingRelationship:sub(1, 3) ~= "SPI" then
            raiseError(134)
        end
        Ace3Type = "SPI"
    else
        raiseError(134)
    end

    local flagAce3UART = false
    if matchingRelationship and matchingRelationship:sub(1, 4) == "UART" then
        Ace3OTP.writeAce3Log(Ace3LogPath, "relationshipSPI: ", relationshipSPI)
        if relationshipSPI and relationshipSPI:sub(1, 3) == "SPI" then
            Ace3OTP.writeAce3Log(Ace3LogPath, "matchingRecord4CC: ", matchingRecord4CC)
            if string.match(relationshipSPI, matchingRecord4CC) then
                Ace3OTP.writeAce3Log(Ace3LogPath, "matchingRelationship: ", matchingRelationship)
                Ace3OTP.writeAce3Log(Ace3LogPath, "record4CCSPI: ", record4CCSPI)
                if string.match(matchingRelationship, record4CCSPI) then
                    flagAce3UART = true
                end
            end
        end
        if flagAce3UART == false then
            raiseError(134)
        end
    end
    return flagAce3UART
end

-- ! @brief Find correct OTP Record in SuperBinary.plist
-- ! @details Calculate Ace3_PREV and get bin file path form SuperBinary.plist with parameters
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns payloadFilepath, dataI2CAddress, Ace3LogPath, Ace3_PREV, SoC_CSEC(string), raise error code if fail
function Ace3OTP.findCorrectOTPRecordinSuperBinary(paraTab)
    helper.flowLogStart(paraTab)
    local matchingRelationship = ''
    local matchingRecord4CC = ''
    local dataI2CBus = ''
    local Ace3_LUN
    Ace3Type = ''
    local findCorrectOTPRecordinSuperBinaryInner = function()
        local superBinaryFolder = paraTab["superBinaryFolder"]
        Log.LogInfo("superBinaryFolder: ", superBinaryFolder)

        Ace3OTP.createAceLog()

        local pListSerialization = Atlas.loadPlugin("PListSerializationPlugin")
        Ace3_TYPE = ""

        local resultBuildStage = false
        local result = getAceDataFromAdditionalParameters(paraTab)
        if result then
            resultBuildStage = true
        else
            local Ace3Parameters = getAceDataFromAce3ParametersPlist(paraTab)
            if Ace3Parameters and type(Ace3Parameters) == 'table' then
                Ace3_PORT = Ace3Parameters["Ace3_PORT"]
                SYS_BREV = Ace3Parameters["SYS_BREV"]
                Ace3_RREV = Ace3Parameters["Ace3_RREV"]
                Ace3_PART = Ace3Parameters["Ace3_PART"]
                Ace3_TYPE = Ace3Parameters["Ace3_TYPE"]
                Ace3_LUN = Ace3Parameters["Ace3_LUN"]
                if Ace3Parameters["SoC_SDOM"] then
                    paraTab["SoC_SDOM"] = Ace3Parameters["SoC_SDOM"]
                end
                if Ace3Parameters["SoC_CHIP"] then
                    paraTab["SoC_CHIP"] = Ace3Parameters["SoC_CHIP"]
                end
                if Ace3Parameters["SYS_BORD"] then
                    paraTab["SYS_BORD"] = Ace3Parameters["SYS_BORD"]
                end
                if Ace3Parameters["SoC_CSEC"] then
                    paraTab["SoC_CSEC"] = Ace3Parameters["SoC_CSEC"]
                end
                if Ace3Parameters["SoC_CPRO"] then
                    paraTab["SoC_CPRO"] = Ace3Parameters["SoC_CPRO"]
                end
                if Ace3Parameters["SYS_BREV"] then
                    paraTab["SYS_BREV"] = Ace3Parameters["SYS_BREV"]
                end
                resultBuildStage = true
            end
        end
        if resultBuildStage == false then
            raiseError(128)
        end

        Ace3_PART = "0x" .. string.sub(Ace3_PART, -2)

        Ace3OTP.writeAce3Log(Ace3LogPath, "SYS_BREV: ", SYS_BREV)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_PART: ", Ace3_PART)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_RREV: ", Ace3_RREV)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_PORT: ", Ace3_PORT)

        getSoCParameters(paraTab)

        local superBinaryData
        if comFunc.fileExists(superBinaryFolder .. "SuperBinary.plist") then
            superBinaryData = pListSerialization.decodeFile(superBinaryFolder .. "SuperBinary.plist")
        else
            raiseError(130)
        end
        local superBinaryMetaData = superBinaryData["SuperBinary MetaData"]
        local deviceSpecificData = superBinaryMetaData["Device Specific Data"]
        local Ace3OTPMetaData = deviceSpecificData["Ace3 OTP MetaData"]

        local flagOTPMetaData = false
        local flagProductRevision = false
        local flagPayload4cc = false
        local flagLocatePayload = false

        for _, v in pairs(Ace3OTPMetaData) do
            local recordPortNumber = v["Record Port Number"]
            local recordSoCBDID = v["Record SoC Board ID"]
            local recordSoCChipID = v["Record SoC Chip ID"]
            Ace3OTP.writeAce3Log(Ace3LogPath, "Record Port Number: ", recordPortNumber)
            Ace3OTP.writeAce3Log(Ace3LogPath, "Record SoC Board ID: ", recordSoCBDID)
            Ace3OTP.writeAce3Log(Ace3LogPath, "Record SoC Chip ID: ", recordSoCChipID)

            if tonumber(recordPortNumber) == tonumber(Ace3_PORT) and tonumber(recordSoCBDID) == tonumber(SYS_BORD) and
                tonumber(recordSoCChipID) == tonumber(SoC_CHIP) then
                Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 OTP MetaData contains the data appropriate for this instance")

                flagOTPMetaData = true

                local leftShiftLength = 5
                -- get the hex mask of replace value from high bits with length, e.g. (mask = 3)11100000
                local maskLengthRevisionData = 3
                local maskRevisionData = (2 ^ maskLengthRevisionData - 1)
                maskRevisionData = maskRevisionData << leftShiftLength
                -- get the hex mask of replace value from low bits with length, e.g. (mask = 5)00011111
                local maskLengthBREV = 5
                local maskBREV = (2 ^ maskLengthBREV - 1)
                local productRevisionData = v["Product Revision Data"]
                Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 1.2 ----------------------------")

                for _, matchingDataRevision in pairs(productRevisionData) do
                    local productRevisionDataOffset = matchingDataRevision["Product Revision Data Offset"]
                    local plistPartNumber = matchingDataRevision["Product Revision Data Part Number"]
                    local revisionDataROMVersion = matchingDataRevision["Product Revision Data ROM Version"]

                    plistPartNumber = "0x" .. plistPartNumber:sub(-2)
                    if tonumber(Ace3_RREV) == tonumber(revisionDataROMVersion) and plistPartNumber == Ace3_PART then
                        flagProductRevision = true

                        Ace3_PREV = tonumber((tonumber(productRevisionDataOffset) & maskRevisionData) |
                                                 (tonumber(SYS_BREV) & maskBREV))
                        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_PREV: ", Ace3_PREV)
                        Ace3OTP.writeAce3Log(Ace3LogPath,
                                             "---------------------------- Step 1.3 ----------------------------")
                        local matchingDataOTP = v["OTP Matching Data"]
                        for _, matchingData in pairs(matchingDataOTP) do
                            local matchingDataMax = matchingData["OTP Matching Data Product Revision Maximum"]
                            local matchingDataMin = matchingData["OTP Matching Data Product Revision Minimum"]
                            if Ace3_PREV <= tonumber(matchingDataMax) and Ace3_PREV >= tonumber(matchingDataMin) then
                                flagPayload4cc = true
                                matchDataPayLoadTag = matchingData["OTP Matching Data Payload Tag"]
                                dataI2CAddress = tostring(matchingData["OTP Matching Data I2C Address"])
                                Ace3OTP.writeAce3Log(Ace3LogPath,
                                                     "OTP Matching Data Payload Tag: " .. matchDataPayLoadTag)
                                Ace3OTP.writeAce3Log(Ace3LogPath, "OTP Matching Data I2C Address: " ..
                                                         string.format("0x%02X", tonumber(dataI2CAddress)))
                                dataI2CBus = matchingData["OTP Matching Data I2C Bus"]
                                matchingRelationship = matchingData["OTP Matching Data Relationship"]
                                matchingRecord4CC = v["Record 4CC"]
                                break
                            end
                        end

                        if flagPayload4cc then
                            break
                        end
                    end
                end

                if flagPayload4cc then
                    break
                end
            end
        end
        if flagOTPMetaData == false then
            raiseError(110)
        elseif flagProductRevision == false then
            raiseError(111)
        elseif flagPayload4cc == false then
            raiseError(112)
        end

        local superBinaryPayloads = superBinaryData["SuperBinary Payloads"]
        for _, v in pairs(superBinaryPayloads) do
            local payload4CC = v["Payload 4CC"]
            if payload4CC == matchDataPayLoadTag then
                Ace3OTP.writeAce3Log(Ace3LogPath, "Payload 4CC: ", comFunc.dump(payload4CC))
                if string.find(v["Payload Filepath"], "/") then
                    payloadFilepath = v["Payload Filepath"]

                end
                Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 1.4 ----------------------------")
                Ace3OTP.writeAce3Log(Ace3LogPath, "Payload Filepath: ", comFunc.dump(payloadFilepath))
                flagLocatePayload = true
                break
            end
        end
        if flagLocatePayload == false then
            raiseError(113)
        end

        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 1.5 ----------------------------")
        if dataI2CBus then
            Ace3OTP.writeAce3Log(Ace3LogPath, "OTP Matching Data I2C Bus: " .. dataI2CBus)
        end
        if matchingRelationship then
            Ace3OTP.writeAce3Log(Ace3LogPath, "OTP Matching Data Relationship: " .. matchingRelationship)
        end
        Ace3OTP.writeAce3Log(Ace3LogPath, "Record 4CC: " .. matchingRecord4CC)

        checkAce3Type(Ace3_TYPE, matchingRelationship, matchingRecord4CC, paraTab)
        return true
    end

    local status, ret = xpcall(findCorrectOTPRecordinSuperBinaryInner, debug.traceback)
    if status then
        helper.flowLogFinish(true, paraTab)
        return payloadFilepath, dataI2CAddress, Ace3LogPath, tostring(Ace3_PREV), tostring(SoC_CSEC),
               matchingRelationship, matchingRecord4CC, dataI2CBus, Ace3_LUN, tostring(SoC_CPRO)
    else
        helper.flowLogFinish(false, paraTab)
        helper.reportFailure(ret)
        return false
    end
end

-- ! @brief get OTP Words with length
-- ! @details get part of table from start location to length
-- ! @param dataTable(table) OTP content data, e.g. {"0x41 ", "0x43 ", "0x45 ", "0x33 ", "0x4F ", "0x54 ", "0x50 "}
-- ! @param start(number) start index, e.g. 1
-- ! @param byteLength(number) byte length, e.g. 2
-- ! @returns result(string) OTP Words, e.g. '0x41 0x43 0x45 0x33 0x4F 0x54 0x50'
local function getOTPWordsWithLength(dataTable, start, byteLength)
    local result = ""
    for i = tonumber(start), tonumber(start) + byteLength - 1 do
        result = result .. dataTable[i]
    end
    return comFunc.trim(result)
end

-- ! @brief Set OTP table Data
-- ! @details convert bin read string ro string table from index 0
-- ! @param dataStr(string) OTP string, e.g. 'ACE3OTP'
-- ! @returns N/A
-- ! e.g. Ace3OTPContent => {"0x41", "0x43", "0x45", "0x33", "0x4F", "0x54", "0x50"}
local function OTPTableData(dataStr)
    for i = 1, #dataStr do
        local charCode = string.byte(dataStr, i, i)
        local hexstr = string.format("0x%02X" .. " ", charCode)
        Ace3OTPContent[i - 1] = hexstr
    end
end

-- ! @brief Get CRC32 value from read data
-- ! @details Get ACE CRC data from data table
-- ! @param value(table) Read from ACE register
-- ! @param crc1Start(number) CRC1 start index
-- ! @param crc1End(number) CRC1 end index
-- ! @param crc2Start(number) CRC2 start index
-- ! @param crc2End(number) CRC2 end index
-- ! @param crc3Start(number) CRC3 start inde
-- ! @param crc3End(number) CRC3 end index
-- ! @returns CRC1, CRC2 and CRC3(string)
local function getCRCFromReadAce3(value, crc1Start, crc1End, crc2Start, crc2End, crc3Start, crc3End)
    local readCRC1 = ''
    for i = tonumber(crc1Start), tonumber(crc1End) do
        readCRC1 = readCRC1 .. string.format("0x%02X", tonumber(value[i]))
    end

    local readCRC2 = ''
    for i = tonumber(crc2Start), tonumber(crc2End) do
        readCRC2 = readCRC2 .. string.format("0x%02X", tonumber(value[i]))
    end

    local readCRC3 = ''
    for i = tonumber(crc3Start), tonumber(crc3End) do
        readCRC3 = readCRC3 .. string.format("0x%02X", tonumber(value[i]))
    end

    readCRC1 = bigEndianFormat(readCRC1)
    readCRC2 = bigEndianFormat(readCRC2)
    readCRC3 = bigEndianFormat(readCRC3)

    return readCRC1, readCRC2, readCRC3
end

-- ! @brief Get CRC32 value from read data
-- ! @details Get ACE CRC data from data table
-- ! @param value(table) Read from ACE register
-- ! @param crc1Start(number) CRC1 start index
-- ! @param crc1End(number) CRC1 end index
-- ! @param crc2Start(number) CRC2 start index
-- ! @param crc2End(number) CRC2 end index
-- ! @param crc3Start(number) CRC3 start inde
-- ! @param crc3End(number) CRC3 end index
-- ! @returns CRC1, CRC2 and CRC3(string)
local function getCRCFromI2CForAttribute(value, crc1Start, crc1End, crc2Start, crc2End, crc3Start, crc3End)
    local readCRC1 = ''
    for i = tonumber(crc1Start), tonumber(crc1End) do
        if i == tonumber(crc1End) then
            readCRC1 = readCRC1 .. string.format("0x%02X", tonumber(value[i]))
        else
            readCRC1 = readCRC1 .. string.format("0x%02X", tonumber(value[i])) .. " "
        end
    end

    local readCRC2 = ''
    for i = tonumber(crc2Start), tonumber(crc2End) do
        if i == tonumber(crc2End) then
            readCRC2 = readCRC2 .. string.format("0x%02X", tonumber(value[i]))
        else
            readCRC2 = readCRC2 .. string.format("0x%02X", tonumber(value[i])) .. " "
        end
    end

    local readCRC3 = ''
    for i = tonumber(crc3Start), tonumber(crc3End) do
        if i == tonumber(crc3End) then
            readCRC3 = readCRC3 .. string.format("0x%02X", tonumber(value[i]))
        else
            readCRC3 = readCRC3 .. string.format("0x%02X", tonumber(value[i])) .. " "
        end
    end

    return readCRC1, readCRC2, readCRC3
end

-- ! @brief Computed OTP Bin CRC
-- ! @details Compute CRC from bin file table
-- ! @param Ace3Content(table) bin file table
-- ! @param start(number) Start index
-- ! @param length(number) Byte length
-- ! @returns crc(string) CRC32 value
local function computedBinCRC(Ace3Content, start, length)
    local binData
    local crc
    binData = getOTPWordsWithLength(Ace3Content, tonumber(start), tonumber(length))
    binData = string.gsub(binData, "0x", "")
    binData = string.gsub(binData, " ", "")
    crc = string.format("0x%08X", crc32.calculateCRC32(binData))
    crc = toggleEndian(crc)

    return crc
end

-- ! @brief Replace Bits
-- ! @details Replace Bits from orignal to new value
-- ! @param orignalValue(number) orignal value
-- ! @param replaceValue(number) replace value
-- ! @param mask(number) Bits size to be replaced
-- ! @param shift(number) Left shift
-- ! @returns replaced value(number) raise error if Input value is not number
local function replaceBits(orignalValue, replaceValue, mask, shift)
    if type(orignalValue) ~= "number" or type(replaceValue) ~= "number" then
        error("Input value is not number")
    end
    -- get the hex mask of replace value from low bits with length, e.g. (mask = 1)00000001, (mask = 2)00000011
    local replaceMask = (2 ^ mask - 1)
    -- get the hex mask of orignal value, move the bits location as left shift, hit bits will be changed to zero
    -- e.g. (mask = 3, shift = 0)11111000, (mask = 1, shift = 2)11111011, (mask = 2, shift = 2)11110011
    local orignalMask = 0xFF - (replaceMask << shift)

    -- clear the orignal value to zero as orignal mask, change them to replace value which from low bits with mask
    -- e.g. orignalValue = 0x31(00110001), replaceValue = 0x03(00000011), mask = 1, shift = 1
    -- e.g. 'orignalValue & orignalMask' is 00110001, '(replaceValue & replaceMask) << shift' is 00000010
    -- e.g. return result is 0x33(00110011) = 00110001 | 00000010
    return (orignalValue & orignalMask) | ((replaceValue & replaceMask) << shift)
end

-- ! @brief Replace bin string data
-- ! @details Replace Bits from orignal to new value
-- ! @param Ace3Content(table) orignal value from table
-- ! @param binDataLocation(number) orignal value location
-- ! @param replacevalue(number) replace value
-- ! @param mask(number) Bits size to be replaced
-- ! @param shift(number) Left shift  00001001
-- ! @returns N/A
local function replaceBinData(Ace3Content, binDataLocation, replacevalue, mask, shift)
    local dataBin
    dataBin = getOTPWordsWithLength(Ace3Content, tonumber(binDataLocation), 1)
    Ace3OTP.writeAce3Log(Ace3LogPath,
                         "Replace OTP Byte Before: " .. string.format("0x%03X", tonumber(binDataLocation)) .. ": " ..
                             string.format("0x%02X", dataBin))
    dataBin = replaceBits(tonumber(dataBin), tonumber(replacevalue), mask, shift)
    Ace3Content[binDataLocation] = string.format("0x%02X" .. " ", dataBin)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Replace OTP Byte After: " .. string.format("0x%03X", binDataLocation) .. ": " ..
                             getOTPWordsWithLength(Ace3Content, tonumber(binDataLocation), 1))
end

-- ! @brief Read Ace3 data
-- ! @details Read data from ace register with length
-- ! @param address(string) Device address
-- ! @param register(string) Ace register to read
-- ! @param length(string) Length to read
-- ! @returns ret(string) Ace register read value
function Ace3OTP.readAce3I2C(fixturePluginName, address, register, length)
    local fixture = Device.getPlugin(fixturePluginName)
    if fixture == nil or type(fixture.readI2C) ~= "function" then
        error("fixture plugin or function is not exist")
    end

    helper.LogFixtureControlStart("ReadI2C('" .. address .. "', " .. register .. ", " .. length .. ")", "nil", "nil")
    local ret = fixture.readI2C(tostring(address), register, length, slotNumber, 3000)
    if string.find(ret, "RPCError") ~= nil then
        for i = 1, 10 do
            getTimeUtilityPlugin().delay(0.5)
            ret = fixture.readI2C(tostring(address), register, length, slotNumber, 3000)
            Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3OTP.readAce3I2C loop times: " .. i)
            if string.find(ret, "RPCError") == nil then
                break
            end
        end
    end
    helper.LogFixtureControlFinish(ret)
    Ace3OTP.writeAce3Log(Ace3LogPath, string.format("Read %d bytes from register %02X: ", length, register) .. ret)
    return ret
end

-- ! @brief Write Ace3 data
-- ! @details Write data from ace register
-- ! @param address(string) Device address
-- ! @param register(string) Ace register
-- ! @param data(string) data write to ace register
-- ! @returns N/A
function Ace3OTP.writeAce3I2C(fixturePluginName, address, register, data)
    local fixture = Device.getPlugin(fixturePluginName)
    if fixture == nil or type(fixture.writeI2C) ~= "function" then
        error("fixture plugin or function is not exist")
    end

    helper.LogFixtureControlStart("writeI2C('" .. address .. "', " .. register .. ", " .. data .. ")", "nil", "nil")
    local ret = fixture.writeI2C(tostring(address), register, data, slotNumber, 3000)
    local lengthOfWrite = #comFunc.splitString(data, ",")
    helper.LogFixtureControlFinish(ret)
    Ace3OTP.writeAce3Log(Ace3LogPath,
                         string.format("Write %d bytes to register %02X: ", lengthOfWrite, register) .. data)
end

-- ! @brief transition VBUS
-- ! @details transition fixture OTP VPP from 5V to ≥12V
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A
function Ace3OTP.transitionVBUS(paraTab)
    local timeout = paraTab.Timeout
    assert(timeout ~= nil, "miss timeout")
    timeout = tonumber(timeout) * 1000
    local actionFunc = paraTab.ActionFunc
    local actionCommand = paraTab.ActionCommand
    local fixturePluginName = paraTab.fixturePluginName or "FixturePlugin"

    local fixture = Device.getPlugin(fixturePluginName)
    if fixture == nil or type(fixture[actionFunc]) ~= "function" then
        error("fixture plugin or function is not exist")
    end

    helper.LogFixtureControlStart(actionFunc, "nil", "nil")
    local status, ret = xpcall(fixture[actionFunc], debug.traceback, actionCommand, "null", timeout, slotNumber)
    helper.LogFixtureControlFinish(ret)
    if not status then
        error("transition VBUS failed")
    end
end

-- ! @brief Abort and read Ace3 data
-- ! @details Ace3 OTP program get error and read ace registers
-- ! @param address(string) I2C device address
-- ! @returns N/A
local function abortReadAce3(fixturePluginName, address)
    Ace3OTP.writeAce3Log(Ace3LogPath, "Abort, Failure reporting:")
    Ace3OTP.readAce3I2C(fixturePluginName, address, '0x00', 65)
    Ace3OTP.readAce3I2C(fixturePluginName, address, '0x01', 65)
    Ace3OTP.readAce3I2C(fixturePluginName, address, '0x0F', 65)
    Ace3OTP.readAce3I2C(fixturePluginName, address, '0x2C', 65)
    Ace3OTP.readAce3I2C(fixturePluginName, address, '0x2D', 65)
end

-- ! @brief Get ECID and replace OTP content
-- ! @details Read ECID of ace and replace to bin table
-- ! @param address(string) Device address
-- ! @param Ace3Addr(string) Data write to ace register
-- ! @param length(number) Length read from ace register
-- ! @param binTable(table) Data to replace
-- ! @param rrevAce3(string) Ace3 rom version
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @param maxTry(number) Max retry times for reading Ace3 ECID
-- ! @returns ecidFromAce3(string) ECID of Ace, raise error if ECID table size not match length
-- !          raise error if compare 2x reading ECID not match, raise error if the Ace3_ECID value is all 0's or 1's
-- !          raise error if the Ace3_BNCH value is all 0's abort (part failed BNCH test)
local function getEcidAndReplaceBin(fixturePluginName, address, Ace3Addr, length, binTable, rrevAce3, paraTab, maxTry)
    local firstByte = tonumber(rrevAce3) > 0 and "0x30" or "0x2F"
    local retAceECID
    local retAceECIDSecond
    local AceECIDTable = {}
    local tryNumber = 1

    for i = 1, tonumber(maxTry) do
        tryNumber = i
        retAceECID = Ace3OTP.readAce3I2C(fixturePluginName, address, Ace3Addr, length)
        AceECIDTable = comFunc.splitString(retAceECID, ",")
        if AceECIDTable[1] == firstByte and AceECIDTable[2] == '0x22' and AceECIDTable[3] == '0x00' then
            break
        end
        Ace3OTP.writeAce3Log(Ace3LogPath, "Read times: ", tostring(i))
        if i == tonumber(maxTry) then
            raiseError(135)
        end
    end
    for i = 1, tonumber(maxTry) do
        if i > tryNumber then
            tryNumber = i
        end
        retAceECIDSecond = Ace3OTP.readAce3I2C(fixturePluginName, address, Ace3Addr, length)
        AceECIDTable = comFunc.splitString(retAceECIDSecond, ",")
        if AceECIDTable[1] == firstByte and AceECIDTable[2] == '0x22' and AceECIDTable[3] == '0x00' then
            break
        end
        Ace3OTP.writeAce3Log(Ace3LogPath, "Read times: ", tostring(i))
        if i == tonumber(maxTry) then
            raiseError(135)
        end
    end
    helper.createRecord(tryNumber, paraTab, nil, "max_try", nil)

    if retAceECID ~= retAceECIDSecond then
        raiseError(135)
    end

    local ecidFromAce3 = ""
    local Ace3BNCH = ""

    if #AceECIDTable ~= tonumber(length) then
        raiseError(135)
    end
    Ace3OTP.writeAce3Log(Ace3LogPath, "AceECIDTable: ", comFunc.dump(AceECIDTable))

    local isValidECID = false
    local isValidBNCH = false
    if tonumber(rrevAce3) > 0 then
        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.5 ----------------------------")
        if AceECIDTable[1] == '0x30' then
            for i = 26, 33 do
                if tonumber(AceECIDTable[i]) > 0 and tonumber(AceECIDTable[i]) < 255 then
                    isValidECID = true
                end
                ecidFromAce3 = string.format("%02X", tonumber(AceECIDTable[i])) .. ecidFromAce3
            end
            ecidFromAce3 = "0x" .. ecidFromAce3
            Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_ECID: ", ecidFromAce3)

            local n = 26
            for i = 0x498, 0x49F do
                table.remove(binTable, i)
                table.insert(binTable, i, string.format("0x%02X" .. " ", tonumber(AceECIDTable[n])))
                n = n + 1
            end

            for i = 34, 49 do
                if tonumber(AceECIDTable[i]) > 0 then
                    isValidBNCH = true
                end
                Ace3BNCH = string.format("%02X%s", tonumber(AceECIDTable[i]), Ace3BNCH)
            end
        end
    end

    if tonumber(rrevAce3) == 0 then
        if AceECIDTable[1] == '0x2F' then
            for i = 25, 32 do
                if tonumber(AceECIDTable[i]) > 0 and tonumber(AceECIDTable[i]) < 255 then
                    isValidECID = true
                end
                ecidFromAce3 = string.format("%02X", tonumber(AceECIDTable[i])) .. ecidFromAce3
            end
            ecidFromAce3 = "0x" .. ecidFromAce3
            Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_ECID from DUT: ", ecidFromAce3)

            local ecidFromBin = ""
            for i = 0x498, 0x49F do
                ecidFromBin = binTable[i] .. ecidFromBin
            end
            ecidFromBin = string.gsub(ecidFromBin, "0x", "")
            ecidFromBin = string.gsub(ecidFromBin, " ", "")
            ecidFromBin = "0x" .. ecidFromBin
            Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_ECID from Bin: ", ecidFromBin)

            for i = 34, 49 do
                if tonumber(AceECIDTable[i]) > 0 then
                    isValidBNCH = true
                end
                Ace3BNCH = string.format("%02X%s", tonumber(AceECIDTable[i]), Ace3BNCH)
            end
        end
    end

    if not isValidECID then
        Ace3OTP.writeAce3Log(Ace3LogPath, "Invalid Ace3_ECID")
        raiseError(135)
    end

    if not isValidBNCH then
        helper.createRecord(false, paraTab, nil, "Ace3_BNCH_Test", nil, 'FAIL')
        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_BNCH:", Ace3BNCH)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Invalid Ace3_BNCH, part failed BNCH test")
        raiseError(135)
    else
        helper.createRecord(true, paraTab, nil, "Ace3_BNCH_Test", nil, 'PASS')
    end

    return ecidFromAce3
end

-- ! @brief Get UUID
-- ! @details Read UUID from 0x05 sub address
-- ! @param address(string) Device address
-- ! @param Ace3Addr(string) Data write to ace register
-- ! @param length(string) Length read from ace register
-- ! @returns AceUUID(string) UUID of Ace, raise error if UUID table size not match length
local function getUUID(fixturePluginName, address, Ace3Addr, length, indexStart, indexEnd, UUIDEnd)
    local retUUID = Ace3OTP.readAce3I2C(fixturePluginName, address, Ace3Addr, length)
    local AceUUIDTable = comFunc.splitString(retUUID, ",")
    if #AceUUIDTable ~= tonumber(length) then
        raiseError(135)
    end

    local AceECIDCheck = ""
    local AceUUID = ""
    for i = indexStart, indexEnd do
        AceECIDCheck = string.format("%02X", tonumber(AceUUIDTable[i])) .. AceECIDCheck
    end
    AceECIDCheck = "0x" .. AceECIDCheck

    for i = indexStart, UUIDEnd do
        AceUUID = string.format("%02X", tonumber(AceUUIDTable[i])) .. AceUUID
    end
    AceUUID = "0x" .. AceUUID

    return AceECIDCheck, AceUUID
end

-- ! @brief Insert Ace3_ECID into OTP data
-- ! @details The Ace3_ECID shall be written over OTP.bin bytes 0x498-0x49F. If Ace3_RREV == 0 skip this step
-- ! @param littleEndianECID(string)
-- ! @returns ecidFromAce3(string) ECID of Ace, raise error if ECID table size not match length
local function insertAce3ECID(binTable, littleEndianECID)
    local bigEndianECID
    if littleEndianECID:sub(1, 2) == "0x" and #littleEndianECID == 18 then
        bigEndianECID = toggleEndian(littleEndianECID)
    else
        raiseError(135)
    end
    local i = 0x498
    for stringData in string.gmatch(bigEndianECID, "(%x%x)") do
        table.remove(binTable, i)
        table.insert(binTable, i, "0x" .. stringData .. " ")
        i = i + 1
    end
end

-- ! @brief Get 40 Bytes OTP words and CheckSum
-- ! @details Get 40 bytes from bin and calculate checksum
-- ! @param Ace3CRC1(string) CRC1 data from ace
-- ! @param binCRC1(string) CRC1 data from ace bin file
-- ! @returns bin40Byte(table) 40 bytes OTP data
local function get40ByteBinAndCheckSum(Ace3CRC1, binCRC1)
    local firstByte
    local secByte
    if tonumber(Ace3_RREV) > 0 then
        firstByte = "0xF5"
    elseif tonumber(Ace3_RREV) == 0 then
        firstByte = "0xFD"
    end
    if power == "VBUS" then
        secByte = "0xA0"
    else
        secByte = "0x00"
    end
    if tonumber(Ace3_RREV) < 2 and Ace3CRC1 == binCRC1 then
        local maskClearBit0 = 0xFE -- clear bit 0 in the first byte 11111110
        firstByte = string.format("0x%02X", tonumber(firstByte) & maskClearBit0)
    end

    Ace3OTP.writeAce3Log(Ace3LogPath, "First 2 Bytes: ", firstByte .. " " .. secByte)
    Ace3OTP.writeAce3Log(Ace3LogPath, "8 Bytes 0x000: ", getOTPWordsWithLength(Ace3OTPContent, 0x000, 8))
    Ace3OTP.writeAce3Log(Ace3LogPath, "8 Bytes 0x484: ", getOTPWordsWithLength(Ace3OTPContent, 0x484, 8))
    Ace3OTP.writeAce3Log(Ace3LogPath, "8 Bytes 0x48C: ", getOTPWordsWithLength(Ace3OTPContent, 0x48C, 8))
    Ace3OTP.writeAce3Log(Ace3LogPath, "4 Bytes 0x494: ", getOTPWordsWithLength(Ace3OTPContent, 0x494, 4))
    Ace3OTP.writeAce3Log(Ace3LogPath, "8 Bytes 0x498: ", getOTPWordsWithLength(Ace3OTPContent, 0x498, 8))
    local OTP38Byte = firstByte .. " " .. secByte .. " " .. getOTPWordsWithLength(Ace3OTPContent, 0x000, 8) .. " " ..
                          getOTPWordsWithLength(Ace3OTPContent, 0x484, 8) .. " " ..
                          getOTPWordsWithLength(Ace3OTPContent, 0x48C, 8) .. " " ..
                          getOTPWordsWithLength(Ace3OTPContent, 0x494, 4) .. " " ..
                          getOTPWordsWithLength(Ace3OTPContent, 0x498, 8)

    Ace3OTP.writeAce3Log(Ace3LogPath, "OTP38Byte: ", OTP38Byte)
    local arrayOTP38Byte = comFunc.splitString(OTP38Byte, "0x")

    local checkSum = 0
    for k, _ in pairs(arrayOTP38Byte) do
        if k > 1 then
            local value = "0x" .. arrayOTP38Byte[k]
            checkSum = checkSum + tonumber(value)
        end
    end

    local maskCheckSum = 0xFF
    local checkSumStr = string.format("0x%02X", (0xFF - checkSum & maskCheckSum))

    Ace3OTP.writeAce3Log(Ace3LogPath, "OTPchecksum: ", checkSumStr)
    table.remove(arrayOTP38Byte, 1)
    table.insert(arrayOTP38Byte, 1, "0x27")
    table.insert(arrayOTP38Byte, 40, checkSumStr)
    Ace3OTP.writeAce3Log(Ace3LogPath, "40 Bytes OTP: " .. comFunc.dump(arrayOTP38Byte))

    local bin40Byte = ""
    for k, _ in pairs(arrayOTP38Byte) do
        if string.find(arrayOTP38Byte[k], "0x") then
            if k == 1 then
                bin40Byte = bin40Byte .. arrayOTP38Byte[k]
            else
                bin40Byte = bin40Byte .. "," .. arrayOTP38Byte[k]
            end
        else
            arrayOTP38Byte[k] = "0x" .. arrayOTP38Byte[k]
            if k == 1 then
                bin40Byte = bin40Byte .. arrayOTP38Byte[k]
            else
                bin40Byte = bin40Byte .. "," .. arrayOTP38Byte[k]
            end
        end

    end
    return bin40Byte
end

-- ! @brief Program OTP
-- ! @details Write 40 bytes to Ace
-- ! @details add boardID compare
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns Ace3_CRC1_I2C, Ace3_CRC2_I2C, Ace3_CRC3_I2C(string), Ace3_ECID, Ace3_UUID return CRC32 attributes otherwise raise error code
function Ace3OTP.programOTP(paraTab)
    helper.flowLogStart(paraTab)
    local timeUtility = getTimeUtilityPlugin()
    local Ace3_ECID = ''
    local Ace3_UUID = ''
    local isProgramming = "FALSE"
    local attrAce3ECID = paraTab.attribute
    local attrAce3UUID = paraTab.attrAce3UUID
    local fixturePluginName = paraTab.fixturePluginName or "FixturePlugin"
    dataI2CAddress = paraTab.dataI2CAddress
    Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 2.0 ----------------------------")
    Ace3OTP.writeAce3Log(Ace3LogPath, "I2C Device Address: ", string.format("0x%02X", tonumber(dataI2CAddress)))

    local programOTPInner = function()
        local superBinaryFolder = paraTab["superBinaryFolder"]
        Log.LogInfo("superBinaryFolder: ", superBinaryFolder)
        power = paraTab.power
        local OTPName = payloadFilepath
        local OTPPath = superBinaryFolder .. OTPName
        Ace3OTP.writeAce3Log(Ace3LogPath, "Get OTP bin from path: ", OTPPath)
        if comFunc.fileExists(OTPPath) then
            local OTPData = readBinFile(OTPPath)
            -- step 2.1 If Ace3 OTP.bin file size > 1288 bytes
            if #OTPData <= 1288 then
                raiseError(114)
            end
            OTPTableData(OTPData)
        else
            raiseError(126)
        end

        --compare borad id from binfile with dut 
        local dutBoardID = getOTPWordsWithLength(Ace3OTPContent, 0x487, 1)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Get boardid from bin file: ", dutBoardID)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Get SYS_BORD from dut: ", SYS_BORD)
        if tonumber(dutBoardID) ~= tonumber(SYS_BORD) then
            raiseError(112)
        end

        local binHeader = getOTPWordsWithLength(Ace3OTPContent, 0x500, 8)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3 OTP Header: ", binHeader)
        if binHeader ~= '0x41 0x43 0x45 0x33 0x4F 0x54 0x50 0x01' then
            raiseError(115)
        end

        computedOTPBinCRC1 = computedBinCRC(Ace3OTPContent, 0x000, 1156)
        Ace3OTP.writeAce3Log(Ace3LogPath, "computedOTPBinCRC1: " .. computedOTPBinCRC1)
        local computedOTPBinCRC2Pre = computedBinCRC(Ace3OTPContent, 0x000, 1175)
        Ace3OTP.writeAce3Log(Ace3LogPath, "computedOTPBinCRC2Pre: " .. computedOTPBinCRC2Pre)
        if computedOTPBinCRC1 ~= bigEndianFormat(getOTPWordsWithLength(Ace3OTPContent, 0x508, 4)) and
            computedOTPBinCRC2Pre ~= bigEndianFormat(getOTPWordsWithLength(Ace3OTPContent, 0x50C, 4)) then
            raiseError(125)
        end

        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 3.0 ----------------------------")
        replaceBinData(Ace3OTPContent, 0x48E, SoC_SDOM, 3, 0) -- replace 0x48E bit2~0
        if Ace3Type ~= "SPI" and Ace3Type ~= "UART" then
            raiseError(134)
        end
        if Ace3Type == "UART" and tonumber(Ace3_RREV) == 0 then
            Ace3OTP.writeAce3Log(Ace3LogPath, "this is a UART Ace3 and Ace3_RREV == 0, skip this step.")
        else
            replaceBinData(Ace3OTPContent, 0x494, SoC_CSEC, 1, 1) -- replace 0x494 bit1
            replaceBinData(Ace3OTPContent, 0x494, SoC_CPRO, 1, 2) -- replace 0x494 bit2
            if tonumber(SoC_CPRO) == 1 then
                replaceBinData(Ace3OTPContent, 0x494, SoC_CPRO, 1, 3) -- because SoC_CPRO == 1 so replace 0x494 bit3
            end
        end

        computedOTPBinCRC2 = computedBinCRC(Ace3OTPContent, 0x000, 1175)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Computed OTP Bin CRC2: " .. computedOTPBinCRC2)

        replaceBinData(Ace3OTPContent, 0x497, Ace3_PREV, 8, 0) -- replace 0x497

        local partNumber = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x01", 5)
        if partNumber ~= "0x04," .. Ace3_PART .. ",0x20,0x01,0x02" then
            for i = 1, 5 do
                timeUtility.delay(0.5)
                partNumber = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x01", 5)
                if partNumber == "0x04," .. Ace3_PART .. ",0x20,0x01,0x02" then
                    break
                end
                Ace3OTP.writeAce3Log(Ace3LogPath, "Read 0x01 times:", tostring(i))
            end
        end

        local partNumberTable = comFunc.splitString(partNumber, ",")
        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.2 ----------------------------")
        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_PART: " .. Ace3_PART)

        if #partNumberTable ~= 5 then
            raiseError(116)
        end

        if partNumberTable[1] == "0x04" and partNumberTable[2] == Ace3_PART and partNumberTable[3] == "0x20" and
            partNumberTable[4] == "0x01" and partNumberTable[5] == "0x02" then
            Ace3OTP.writeAce3Log(Ace3LogPath, "Read Ace3_PART: " .. partNumberTable[2])
        else
            raiseError(116)
        end

        local romVersion = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x0F", 4)
        local romVersionTable = comFunc.splitString(romVersion, ",")
        if #romVersionTable ~= 4 then
            raiseError(117)
        end

        local rightShiftLength = 4
        if (tonumber(romVersionTable[4]) >> rightShiftLength) ~= tonumber(Ace3_RREV) or
            (romVersionTable[1] ~= "0x04" and romVersionTable[1] ~= "0x08") then
            for i = 1, 5 do
                timeUtility.delay(0.5)
                romVersion = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x0F", 4)
                romVersionTable = comFunc.splitString(romVersion, ",")
                local readVersionROM = romVersionTable[4]
                if readVersionROM and (tonumber(readVersionROM) >> rightShiftLength) == tonumber(Ace3_RREV) and
                    (romVersionTable[1] == "0x04" or romVersionTable[1] == "0x08") then
                    break
                end
                Ace3OTP.writeAce3Log(Ace3LogPath, "Read 0x0F times:", tostring(i))
            end
        end

        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_RREV: ", Ace3_RREV)
        if romVersionTable[1] == "0x04" or romVersionTable[1] == "0x08" then
            if (tonumber(romVersionTable[4]) >> rightShiftLength) == tonumber(Ace3_RREV) then
                Ace3OTP.writeAce3Log(Ace3LogPath, "Read Ace3_RREV ROM: ", romVersionTable[4])
            else
                raiseError(117)
            end
        else
            raiseError(117)
        end
        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.3 ----------------------------")
        Ace3OTP.writeAce3I2C(fixturePluginName, dataI2CAddress, '0x09', '0x01,0x01')

        timeUtility.delay(0.01)

        Ace3OTP.writeAce3I2C(fixturePluginName, dataI2CAddress, '0x08', '0x04,0x41,0x44,0x46,0x55')
        local forceAceDFU
        for i = 1, 10 do
            timeUtility.delay(0.5)
            forceAceDFU = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x08", 5)
            if forceAceDFU == "0x08,0x00,0x00,0x00,0x00" then
                break
            end
            Ace3OTP.writeAce3Log(Ace3LogPath, "Read 0x08 times:", tostring(i))
            if i == 10 then
                raiseError(118)
            end
        end

        local enterAceDFUModeState = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x03", 5)

        if enterAceDFUModeState ~= "0x04,0x41,0x44,0x46,0x55" then
            for i = 1, 10 do
                Ace3OTP.writeAce3Log(Ace3LogPath, "Retry times:", tostring(i))
                Ace3OTP.writeAce3I2C(fixturePluginName, dataI2CAddress, '0x09', '0x01,0x01')
                timeUtility.delay(0.1)
                Ace3OTP.writeAce3I2C(fixturePluginName, dataI2CAddress, '0x08', '0x04,0x41,0x44,0x46,0x55')
                for j = 1, 10 do
                    timeUtility.delay(0.5)
                    forceAceDFU = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x08", 5)
                    if forceAceDFU == "0x08,0x00,0x00,0x00,0x00" then
                        break
                    end
                    Ace3OTP.writeAce3Log(Ace3LogPath, "Read 0x08 times:", tostring(j))
                    if j == 10 then
                        raiseError(118)
                    end
                end
                enterAceDFUModeState = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x03", 5)
                if enterAceDFUModeState == "0x04,0x41,0x44,0x46,0x55" then
                    break
                end
            end
            if enterAceDFUModeState ~= "0x04,0x41,0x44,0x46,0x55" then
                raiseError(119)
            end
        end

        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.4 ----------------------------")
        if Ace3Type == "UART" then
            Ace3_ECID = paraTab["Ace3_ECID"]
            Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.5 ----------------------------")
            Ace3OTP.writeAce3Log(Ace3LogPath, "UART Ace3_ECID: ", Ace3_ECID)
            if tonumber(Ace3_RREV) > 0 then
                insertAce3ECID(Ace3OTPContent, Ace3_ECID)
            else
                Ace3OTP.writeAce3Log(Ace3LogPath, "skip this step, ECID cannot be programmed due to ROM0 bug")
            end
        else
            local maxTry = paraTab.max_try or 1
            if tonumber(maxTry) < 1 then
                helper.reportFailure("invalid max_try parameter")
            end
            Ace3_ECID = getEcidAndReplaceBin(fixturePluginName, dataI2CAddress, "0x2C", 49, Ace3OTPContent, Ace3_RREV,
                                             paraTab, maxTry)
            local indexStart = 2
            local indexEnd = 9
            local UUIDEnd = 17
            local Ace3_ECIDCheck = ''
            Ace3_ECIDCheck, Ace3_UUID = getUUID(fixturePluginName, dataI2CAddress, "0x05", 64, indexStart,
                                                      indexEnd, UUIDEnd)
            if Ace3_ECID ~= Ace3_ECIDCheck then
                raiseError(135)
            end
            if attrAce3UUID and Ace3_UUID then
                DataReporting.submit(DataReporting.createAttribute(attrAce3UUID, Ace3_UUID))
            end
            Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_UUID:", Ace3_UUID)
        end
        if string.len(Ace3_ECID) ~= 18 then
            raiseError(135)
        end
        computedOTPBinCRC3 = computedBinCRC(Ace3OTPContent, 0x000, 1184)
        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.6 ----------------------------")
        Ace3OTP.writeAce3Log(Ace3LogPath, "Computed OTP Bin CRC3: ", computedOTPBinCRC3)

        saveDataProgramOTP(Ace3OTPContent, "_ReplaceBytes_")
        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.7a ---------------------------")
        Ace3OTP.writeAce3I2C(fixturePluginName, dataI2CAddress, '0x09', '0x01,0x80')
        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.7b ---------------------------")
        Ace3OTP.writeAce3I2C(fixturePluginName, dataI2CAddress, '0x08', '0x04,0x4F,0x54,0x50,0x72')
        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.7c ---------------------------")
        local verifyAceCRC
        for i = 1, 5 do
            verifyAceCRC = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x08", 5)
            if verifyAceCRC == "0x08,0x00,0x00,0x00,0x00" then
                break
            elseif verifyAceCRC == "0x08,0x4F,0x54,0x50,0x72" then
                Ace3OTP.writeAce3Log(Ace3LogPath, "Read 0x08 times:", tostring(i))
            else
                raiseError(120)
            end
            if i == 5 then
                raiseError(120)
            end
            timeUtility.delay(0.05)

        end

        Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.7d ---------------------------")
        local verifyDataAceCRC = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x09", 13)
        local verifyDataTableCRC = comFunc.splitString(verifyDataAceCRC, ",")
        if #verifyDataTableCRC ~= 13 then
            raiseError(121)
        end
        Ace3OTP.writeAce3Log(Ace3LogPath, "Verify Ace3 CRC Data: ", comFunc.dump(verifyDataTableCRC))
        local readCRC1, readCRC2, readCRC3 = getCRCFromReadAce3(verifyDataTableCRC, 2, 5, 6, 9, 10, 13)
        Ace3_CRC1_I2C, Ace3_CRC2_I2C, Ace3_CRC3_I2C = getCRCFromI2CForAttribute(verifyDataTableCRC, 2, 5, 6, 9, 10, 13)
        Ace3OTP.writeAce3Log(Ace3LogPath,
                             "readCRC1: " .. readCRC1 .. " readCRC2: " .. readCRC2 .. " readCRC3: " .. readCRC3)

        if verifyDataTableCRC[1] == "0x40" and readCRC1 == computedOTPBinCRC1 and readCRC2 == computedOTPBinCRC2 and
            readCRC3 == computedOTPBinCRC3 then

            Ace3OTP.writeAce3Log(Ace3LogPath, "This Ace3 has already been programmed with provided, " ..
                                     "Skip the remaining CRC check and proceed to the next Ace3")
            -- end  --For Force OTP Programming
        else
            -- if ForceOTP == true then  --For Force OTP Programming
            local unprogrammedCRC1 = '0xDF076436'
            -- if readCRC1 ~= unprogrammedCRC1 and ForceOTP ~= true then  --For Force OTP Programming
            if readCRC1 ~= unprogrammedCRC1 then
                raiseError(121)
            end

            Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.8a ---------------------------")
            local bytes40ForWrite = get40ByteBinAndCheckSum(readCRC1, computedOTPBinCRC1)
            local dataForWrite = string.gsub(bytes40ForWrite, " ", "")

            ---Program OTP
            Ace3OTP.writeAce3I2C(fixturePluginName, dataI2CAddress, '0x09', dataForWrite)
            dataForWrite = comFunc.splitString(dataForWrite, ',')
            saveDataProgramOTP(dataForWrite, "_40BytesOTP_")

            Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.8b ---------------------------")
            local preLockOTP = ''
            local lockOTP = ''
            if tonumber(Ace3_RREV) > 0 then
                preLockOTP = '0x04,0x4F,0x54,0x50,0x63'
                lockOTP = '0x08,0x4F,0x54,0x50,0x63'
            elseif tonumber(Ace3_RREV) == 0 then
                preLockOTP = '0x04,0x4F,0x54,0x50,0x77'
                lockOTP = '0x08,0x4F,0x54,0x50,0x77'
            end
            Ace3OTP.writeAce3I2C(fixturePluginName, dataI2CAddress, "0x08", preLockOTP)

            Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.8c ---------------------------")
            Ace3OTP.writeAce3Log(Ace3LogPath, "OTP VPP: " .. power)
            if power == "VBUS" then
                -- If OTP VPP is provided via VBUS, transition VBUS to ≥12V now.
                Ace3OTP.transitionVBUS(paraTab)
                Ace3OTP.writeAce3Log(Ace3LogPath, "transition VBUS to ≥12V")
            end

            Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.8d ---------------------------")

            local finalWriteOTP
            for i = 1, 5 do
                finalWriteOTP = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x08", 5)
                if finalWriteOTP == "0x08,0x00,0x00,0x00,0x00" then
                    break
                elseif finalWriteOTP == lockOTP then
                    Ace3OTP.writeAce3Log(Ace3LogPath, "Read 0x08 times:", tostring(i))
                else
                    raiseError(122)
                end
                if i == 5 then
                    raiseError(122)
                end
                timeUtility.delay(0.05)
            end

            Ace3OTP.writeAce3Log(Ace3LogPath, "---------------------------- Step 4.8e ---------------------------")
            local verifyOTPCRC = Ace3OTP.readAce3I2C(fixturePluginName, dataI2CAddress, "0x09", 15)

            local verifyOTPCRCTable = comFunc.splitString(verifyOTPCRC, ",")
            if #verifyOTPCRCTable ~= 15 then
                raiseError(123)
            end
            Ace3OTP.writeAce3Log(Ace3LogPath, "verify OTP CRC Table: ", comFunc.dump(verifyOTPCRCTable))

            if verifyOTPCRCTable[2] ~= "0x00" then
                raiseError(123)
            end
            local retCRC1, retCRC2, retCRC3 = getCRCFromReadAce3(verifyOTPCRCTable, 4, 7, 8, 11, 12, 15)
            Ace3_CRC1_I2C, Ace3_CRC2_I2C, Ace3_CRC3_I2C = getCRCFromI2CForAttribute(verifyOTPCRCTable, 4, 7, 8, 11, 12,
                                                                                    15)
            Ace3OTP.writeAce3Log(Ace3LogPath,
                                 "finalCRC1: " .. retCRC1 .. " finalCRC2: " .. retCRC2 .. " finalCRC3: " .. retCRC3)

            if retCRC1 == computedOTPBinCRC1 and retCRC2 == computedOTPBinCRC2 and retCRC3 == computedOTPBinCRC3 then
                Ace3OTP.writeAce3Log(Ace3LogPath, "Final CRC PASS")
            else
                Ace3OTP.writeAce3Log(Ace3LogPath, "expectCRC1:" .. computedOTPBinCRC1 .. " expectCRC2:" ..
                                         computedOTPBinCRC2 .. " expectCRC3:" .. computedOTPBinCRC3)
                raiseError(124)
            end

            isProgramming = "TRUE"
        end
        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_CRC1_I2C: " .. Ace3_CRC1_I2C)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_CRC2_I2C: " .. Ace3_CRC2_I2C)
        Ace3OTP.writeAce3Log(Ace3LogPath, "Ace3_CRC3_I2C: " .. Ace3_CRC3_I2C)
        return true
    end

    local status, ret = xpcall(programOTPInner, debug.traceback)

    if status then
        Ace3OTP.writeAce3Log(Ace3LogPath, "Message: PASS\n")
        if attrAce3ECID then
            DataReporting.submit(DataReporting.createAttribute(attrAce3ECID, Ace3_ECID))
        end
        helper.flowLogFinish(true, paraTab)
    else
        abortReadAce3(fixturePluginName, dataI2CAddress)
        helper.flowLogFinish(false, paraTab)
        helper.reportFailure(ret)
    end

    return Ace3_CRC1_I2C, Ace3_CRC2_I2C, Ace3_CRC3_I2C, Ace3_ECID, isProgramming, Ace3_UUID
end

-- ! @brief Check final CRC with expect value
-- ! @details Check final CRC with expect value and upload Attribute
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A
function Ace3OTP.checkFinalCRC(paraTab)
    helper.flowLogStart(paraTab)
    local expect = paraTab.expect
    local attribute = paraTab.attribute
    local crcValue = paraTab.crcValue
    local isValidCRC = false

    if attribute then
        if expect and crcValue ~= expect then
            helper.flowLogFinish(false, paraTab)
        else
            helper.flowLogFinish(true, paraTab)
            isValidCRC = true
        end
        DataReporting.submit(DataReporting.createAttribute(attribute, crcValue))
    end

    return isValidCRC
end

-- ! @brief Decompose the UARP superbinary from the OS image into its component files
-- ! @details Create a directory for the contents, and then run the goldrestore2 command to decompose SuperBinary
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns superBinaryFolder(string)
function Ace3OTP.decomposeSuperBinary(paraTab)
    helper.flowLogStart(paraTab)
    local outputDir = paraTab.OutputDir
    local uarpFilePath = paraTab.inputUARP

    if comFunc.fileExists(uarpFilePath) then
        Log.LogInfo("Uarp File:", uarpFilePath)
    else
        helper.reportFailure("Uarp file is not exist")
    end

    local superBinaryFolder = fileUtils.joinPaths(outputDir, "OutputDir", groupID,
                                                  "SuperBinary_ch" .. tostring(slotNumber) .. "/")
    fileUtils.RemovePath(superBinaryFolder)

    local fileOperation = Device.getPlugin("FileOperation")
    fileOperation.createDirectory(superBinaryFolder)

    local GR2 = paraTab.goldrestoreTool
    local command = GR2 .. " superbinary decompose outputFolder=" .. superBinaryFolder .. " superBinaryFilepath=" ..
                        uarpFilePath

    local runShellCommand = getRunShellCommandPlugin()
    local shellComRes = runShellCommand.run(command)

    Log.LogInfo("RunShellCommand returnCode and shellResp:", shellComRes.returnCode, shellComRes.output)

    if string.find(shellComRes.output, "Error") or shellComRes.returnCode ~= 0 then
        helper.flowLogFinish(false, paraTab, shellComRes.output, "RunshellComRes error")
        helper.reportFailure('goldrestore2 superbinary decompose error')
    end

    helper.flowLogFinish(true, paraTab)

    return superBinaryFolder
end

-- ! @brief Read Ace Register
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns N/A
function Ace3OTP.readAceRegister(paraTab)
    local fixturePluginName = paraTab.fixturePluginName or "FixturePlugin"
    local deviceAddress = paraTab["deviceAddress"]
    abortReadAce3(fixturePluginName, deviceAddress)
end

-- ! @brief Write Ace3 Register
-- ! @details Write data from ace register
-- ! @param paraTab(table) Containing all values defined one tech csv line
-- ! @returns true/false(boolean)
function Ace3OTP.writeAceRegister(paraTab)
    local fixturePluginName = paraTab.fixturePluginName or "FixturePlugin"
    local i2cAddress = paraTab.Input
    local register = paraTab.register
    local data = paraTab.data
    assert(i2cAddress ~= nil, "miss i2cAddress")
    assert(register ~= nil, "miss register")
    assert(data ~= nil, "miss data")

    Ace3OTP.writeAce3I2C(fixturePluginName, i2cAddress, register, data)

    helper.createRecord(true, paraTab)
    return true
end

return Ace3OTP
