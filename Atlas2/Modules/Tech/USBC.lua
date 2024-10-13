local USBC = {}
local Log = require("Tech/logging")
local comFunc = require("Tech/CommonFunc")
local common = require("Tech/Common")
local dutCmd = require("Tech/DUTCmd")
local DFUCommon = require("Tech/DFUCommon")
local helper = require("Tech/SMTLoggingHelper")
local utils = require("Tech/utils")
local compare = require("Tech/Compare")
local pListSerialization = require("Serialization/PListSerialization")

local OTP_NEED_PROGRAM = false

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0089:, Version: v0.1, Type:Inner]
Name: USBC.bytesToHexStr
Function description: [v0.1]  Function to get OTP_FW bin file Words with lua code
Input : string,number,number
Output : result(number)
-----------------------------------------------------------------------------------]]

function USBC.bytesToHexStr(filePath, start_bit, bit_length)

    local function __readbinFile(path)
        local f = assert(io.open(path, "rb"))
        local content = f:read("*all")
        f:close()
        return content
    end

    local mutexRead_identifier = "mutex_readOTP"
    local mutexPlugin = Device.getPlugin("Mutex")
    local content = mutex.runWithLock(mutexPlugin, mutexRead_identifier, __readbinFile, filePath)

    local result = ""
    local len = string.len(content)
    if start_bit == -1 then
        start_bit = 0
    end
    if bit_length == -1 then
        bit_length = #len
    end
    for i = start_bit + 1, start_bit + bit_length do
        local charcode = tonumber(string.byte(content, i, i))
        local hexstr = string.format("0x%02X ", charcode)
        result = result .. hexstr
    end
    if #result > 0 then
        result = string.sub(result, 0, #result - 1)
    end

    return result
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0090:, Version: v0.1, Type:Inner]
Name: USBC.get_keydata_start
Function description: [v0.1]  Function to get OTP_FW bin file Words with lua code
Input : string
Output : number
-----------------------------------------------------------------------------------]]

function USBC.get_keydata_start(otp_bin_file)
    local KeyDataStart_1 = USBC.getOTPWords(tonumber(0x50C), 1, otp_bin_file) -- 0x4c
    KeyDataStart_1 = string.gsub(KeyDataStart_1, "0X", "")
    local KeyDataStart_2 = USBC.getOTPWords(tonumber(0x50D), 1, otp_bin_file) -- 0x04
    KeyDataStart_2 = string.gsub(KeyDataStart_2, "0X", "")
    local KeyDataStart_3 = USBC.getOTPWords(tonumber(0x50E), 1, otp_bin_file) -- 0x00
    KeyDataStart_3 = string.gsub(KeyDataStart_3, "0X", "")
    local KeyDataStart_4 = USBC.getOTPWords(tonumber(0x50F), 1, otp_bin_file) -- 0x00
    KeyDataStart_4 = string.gsub(KeyDataStart_4, "0X", "")
    return "0x" .. KeyDataStart_4 .. KeyDataStart_3 .. KeyDataStart_2 .. KeyDataStart_1
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0090:, Version: v0.1, Type:Inner]
Name: USBC.getOTPWords
Function description: [v0.1]  Function to get OTP_FW bin file Words with lua code
Input : string,number,number
Output : result(number)
-----------------------------------------------------------------------------------]]

function USBC.getOTPWords(start_bit, bit_length, file_name)
    local OTP_PATH = "/Users/gdlocal/Library/Atlas2/supportFiles/customer/OTP_FW/"
    local path = OTP_PATH .. file_name

    if not tonumber(start_bit) and not tonumber(bit_length) then
        return USBC.bytesToHexStr(path, -1, -1)
    end
    if not tonumber(start_bit) then
        start_bit = 0
    end
    if not tonumber(bit_length) then
        bit_length = 4
    end

    local result = USBC.bytesToHexStr(path, tonumber(start_bit), tonumber(bit_length))
    -- return result
    return string.upper(result)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0092:, Version: v0.1, Type:Inner]
Name: USBC.getProductionMode
Function description: [v0.1] Function to send diags command to judge dev_fuse_mode or prod_fuse_mode.
Input : table(paraTab)
Output : result(string)
-----------------------------------------------------------------------------------]]

function USBC.getProductionMode(paraTab)
    local otp_name_non_prod = paraTab.otp_name_non_prod
    local otp_name_prod = paraTab.otp_name_prod

    local production_mode = dutCmd.sendCmdAndParse(paraTab)
    Log.LogInfo("$$$$ production_mode: " .. production_mode)

    local otp_name = ""
    local result
    local b_result = true

    if production_mode == "0" then
        otp_name = otp_name_non_prod
        result = "dev_fuse_mode"
    elseif production_mode == "1" then
        otp_name = otp_name_prod
        result = "prod_fuse_mode"
    else
        result = "UnSet"
        b_result = false
        helper.createRecord(b_result, paraTab,
                            'Error: Fail to get otp_name[production_mode == ' .. production_mode .. ']')
        helper.reportFailure('Error: Fail to get otp_name[production_mode = ' .. production_mode .. ']')
    end

    if b_result then
        helper.createRecord(result, paraTab)
    else
        helper.createRecord(b_result, paraTab, nil, nil, nil, result)
    end
    return result, otp_name
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0093:, Version: v0.1, Type:Inner]
Name: USBC.getProductionMode
Function description: [v0.1] Function to disconnect cc PPVBUS;set PPVBUS_PORT to 14v
Input : table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]

function USBC.setOTPPower(paraTab)
    local fixture = Device.getPlugin("FixturePlugin")
    -- local slot_num = tonumber(Device.identifier:sub(-1))

    helper.LogFixtureControlStart("ace_provisioning_power_on", Device.identifier:sub(-1), "1000")
    fixture.ace_provisioning_power_on(tonumber(Device.identifier:sub(-1)))
    helper.LogFixtureControlFinish('done')

    os.execute("sleep 0.005")
    helper.createRecord(true, paraTab)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0094:, Version: v0.1, Type:Inner]
Name: USBC.verifyOperatingMode
Function description: [v0.1] Function to disconnect cc PPVBUS;set PPVBUS_PORT to 14v
Input : table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]

function USBC.verifyOperatingMode(paraTab)
    -- local cmd = paraTab.Commands
    -- local pattern = paraTab.pattern

    local ret = dutCmd.sendCmdAndParse(paraTab)
    -- Log.LogInfo(ret)
    local result = "Verify_False"
    if ret == "41 50 50 20" or ret == "44 46 55 66" or ret == "42 4F 4F 54" then
        result = "Verify_Ace2_operating_state"
        helper.createRecord(result, paraTab)
    else
        helper.createRecord(false, paraTab, nil, nil, nil, result)
    end

    Log.LogInfo('verifyOperatingMode_otp_check_crc_flag = ' .. result)

    return result

end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0095:, Version: v0.1, Type:Inner]
Name: USBC.checkOTPCRC
Function description: [v0.1] Function to Verify region state(CRC)
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.checkOTPCRC(paraTab)
    local otp_name = paraTab.Input
    local otp_name_non_prod = paraTab.otp_name_non_prod
    local otp_name_prod = paraTab.otp_name_prod
    -- Log.LogInfo(">>OTP_File_name=",otp_name)
    Log.LogInfo(">>checkOTPCRC_otp_name = " .. otp_name)

    OTP_NEED_PROGRAM = false
    local pattern = "RxData%s*%(4.%).-%:.-0x0000%s*%:%s*(0x%w+%s+0x%w+%s+0x%w+%s+0x%w+)"
    paraTab.Commands = "ace --4cc OTPr --txdata \"0x80\" --rxdata 4"
    paraTab.pattern = pattern
    local ret_crc = dutCmd.sendCmdAndParse(paraTab)
    Log.LogInfo('checkOTPCRC_ret_crc = ' .. ret_crc)
    local Final_CRC = USBC.getOTPWords(tonumber(0x514), 4, otp_name)
    Final_CRC = string.gsub(string.upper(Final_CRC), ",", " ")
    Log.LogInfo('Final_CRC = ' .. Final_CRC)
    local PREVIOUS_CRC = USBC.getOTPWords(tonumber(0x500), 4, otp_name)
    PREVIOUS_CRC = string.gsub(string.upper(PREVIOUS_CRC), ",", " ")
    Log.LogInfo('PREVIOUS_CRC = ' .. PREVIOUS_CRC)

    local result = ""
    local b_result = true
    if otp_name == otp_name_non_prod then
        if ret_crc == "0x06 0x0C 0x2C 0xD4" then -- 0x06 0x0C 0x2C 0xD4
            OTP_NEED_PROGRAM = "OTP_Need_Check_Key_Data_Size"
            result = "OTP_NEED_PROGRAM_CUSTOMER_WORDS"

        elseif string.upper(ret_crc) == Final_CRC then -- 0xB2 0x1B 0xA7 0x1D;
            OTP_NEED_PROGRAM = "OTP_DONTNEED_PROGRAM"
            result = "OTP_Already_PROGRAMMED"

        elseif string.upper(ret_crc) == PREVIOUS_CRC then -- 0xF5 0x43 0x2C 0xDA
            OTP_NEED_PROGRAM = "OTP_Need_Check_Key_Data_Size"
            result = "OTP_DONTNEED_PROGRAM"

        else
            OTP_NEED_PROGRAM = "OTP_DONTNEED_PROGRAM"
            result = "FAIL"
            b_result = false
        end

    elseif otp_name == otp_name_prod then -- Only follow prod-fuse,need charge the opt_name to prod-fuse bin file
        -- if ret_crc=="0xC9 0xD9 0x5B 0x4D" then   --only checking
        if ret_crc == "0x06 0x0C 0x2C 0xD4" then -- 0x06 0x0C 0x2C 0xD4
            OTP_NEED_PROGRAM = "OTP_Need_Check_Key_Data_Size_prod_fuse"
            result = "OTP_NEED_PROGRAM_CUSTOMER_WORDS"

        elseif string.upper(ret_crc) == Final_CRC then -- 0xB2 0x1B 0xA7 0x1D
            OTP_NEED_PROGRAM = "OTP_DONTNEED_PROGRAM"
            result = "OTP_Already_PROGRAMMED"

        elseif string.upper(ret_crc) == PREVIOUS_CRC then -- 0xF5 0x43 0x2C 0xDA
            OTP_NEED_PROGRAM = "OTP_Need_Check_Key_Data_Size_prod_fuse"
            result = "OTP_DONTNEED_PROGRAM"

        else
            OTP_NEED_PROGRAM = "OTP_DONTNEED_PROGRAM"
            result = "FAIL"
            b_result = false
        end
    end
    Log.LogInfo('check otp_need_program = ' .. OTP_NEED_PROGRAM)

    if b_result then
        helper.createRecord(result, paraTab)
    else
        helper.createRecord(b_result, paraTab, nil, nil, nil, result)
        helper.reportFailure('CRC Check FAIL')

    end
    Log.LogInfo('checkOTPCRC_otp_program_words_flag = ' .. result)

    return result

end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0096:, Version: v0.1, Type:Inner]
Name: USBC.getOTPProgramCustomerWords
Function description: [v0.1] Function to ace OTP write customer words
Input : table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]

function USBC.getOTPProgramCustomerWords(paraTab)
    local otp_name = paraTab.Input
    Log.LogInfo(">>getOTPProgramCustomerWords_otp_name = " .. otp_name)

    local write_words = USBC.getOTPWords(0, 8, otp_name) ----0xaa,0x02,0x9f,0x66,0xb6,0x98,0x00,0x00
    write_words = string.gsub(string.upper(write_words), ",", " ")
    write_words = string.gsub(write_words, "0X", "0x")

    local cmd = "ace --4cc OTPw --txdata \"0x01 " .. write_words .. "\" --rxdata 64"
    paraTab.Commands = cmd
    local ret = dutCmd.sendCmdAndParse(paraTab)
    -- Log.LogInfo(ret)

    if string.find(ret, "Error") then
        OTP_NEED_PROGRAM = ""
        helper.createRecord(false, paraTab, nil, nil, nil, DFULoggingHelper.DEFAULT_FAIL_RESULT)
        helper.reportFailure('write OTP Customer Words FAIL')
    else
        helper.createRecord(true, paraTab)
    end

end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0097:, Version: v0.1, Type:Inner]
Name: USBC.getOTPProgramFlag
Function description: [v0.1] Function to flags to Key_Data_Size condition
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.getOTPProgramFlag(paraTab)

    local result
    if OTP_NEED_PROGRAM ~= nil then
        Log.LogInfo("otp_need_program = " .. OTP_NEED_PROGRAM)
        result = OTP_NEED_PROGRAM
        OTP_NEED_PROGRAM = ""

    else
        result = "OTP_DONTNEED_PROGRAM"
    end

   helper.createRecord(result, paraTab)
    Log.LogInfo('getOTPProgramFlag_otp_program_flag = ' .. result)

    return result

end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0098:, Version: v0.1, Type:Inner]
Name: USBC.getCustomerDataSize
Function description: [v0.1] Function to Read Application_Customization_Data_Size from bin file
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.getCustomerDataSize(paraTab)
    local otp_name = paraTab.Input

    Log.LogInfo(">>getCustomerDataSize_otp_name = " .. otp_name)
    local respone = USBC.getOTPWords(tonumber(0x508), 4, otp_name)
    Log.LogInfo('getCustomerDataSize = ' .. respone)
    respone = string.gsub(string.upper(respone), "0X", "")
    respone = tostring(string.gsub(string.upper(respone), " ", ""))

    local result
    if respone == "00000000" then
        result = "PASS_0"
        helper.createRecord(result, paraTab)
    else
        result = "FAIL_Size_Not_0"
        helper.createRecord(false, paraTab, nil, nil, nil, result)
        helper.reportFailure('Customer DataSize not Zero, size:' .. respone)
    end

    Log.LogInfo('>> customer_Data_size 1 = ' .. result)

    return result
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0099:, Version: v0.1, Type:Inner]
Name: USBC.getKeySize
Function description: [v0.1] Function to Key data size check
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.getKeySize(paraTab)
    local otp_name = paraTab.Input

    Log.LogInfo(">>getKeySize_otp_name = " .. otp_name)
    local respone = USBC.getOTPWords(tonumber(0x510), 1, otp_name) -- 0x40

    local result
    if respone == "0X00" then
        result = "OTP_Key_SIZE_0"
    else
        result = "OTP_Key_SIZE_NOT_0"
    end

    helper.createRecord(result, paraTab)
    Log.LogInfo('getKeySize_otp_program_keydata_Size = ' .. result)

    return result

end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0100:, Version: v0.1, Type:Inner]
Name: USBC.getKeySize
Function description: [v0.1] Function to ace OTP write key data crc
Input : table(paraTab)
Output : bool
-----------------------------------------------------------------------------------]]

function USBC.writeOTP(paraTab)
    local otp_name = paraTab.Input
    Log.LogInfo(">>writeOTP_otp_name = " .. otp_name)
    local param1 = paraTab.param1
    local b_result
    local result = "FALSE"

    if param1 == "otp_key_Data_flag" then
        -- key data flag
        local keydata_flag = USBC.getOTPWords(tonumber(0x513), 1, otp_name) -- 0x03
        local cmd = "ace --4cc OTPi --txdata \"" .. keydata_flag .. "\" --rxdata 4"
        paraTab.Commands = cmd
        local ret = dutCmd.sendCmdAndParse(paraTab)
        if string.find(ret, "Error") then
            b_result = false
        else
            b_result = true
            result = "TRUE"
        end

    elseif param1 == "otp_key_Data_value" then
        local keydata_value
        local Key_Data_Size = USBC.getOTPWords(tonumber(0x510), 1, otp_name)
        if (string.upper(Key_Data_Size) == "0X20") then
            keydata_value = USBC.getOTPWords(tonumber(USBC.get_keydata_start(otp_name)), 32, otp_name)
            --[[
            0x17,0xe0,0x8a,0x82,0x5c,0x0f,0x90,0x5c,0x82,0xdc,0xf3,0xce,0xac,0xe5,0x54,0x8c,
            0x57,0x96,0x8d,0x56,0xce,0xf9,0x9d,0xfd,0x65,0x89,0x0e,0x1a,0x00,0x2a,0xf2,0xf8
            --]]
            for _ = 1, 32 do
                keydata_value = keydata_value .. ",0x00"
            end
        else
            keydata_value = USBC.getOTPWords(tonumber(USBC.get_keydata_start(otp_name)), 64, otp_name)
            --[[
            0x17,0xe0,0x8a,0x82,0x5c,0x0f,0x90,0x5c,0x82,0xdc,0xf3,0xce,0xac,0xe5,0x54,0x8c,
            0x57,0x96,0x8d,0x56,0xce,0xf9,0x9d,0xfd,0x65,0x89,0x0e,0x1a,0x00,0x2a,0xf2,0xf8,
            0xea,0xbc,0xe0,0x4d,0xf1,0x4e,0x5d,0x81,0x22,0x4b,0x4f,0xc4,0x6a,0x25,0x4c,0x13,
            0x82,0x4e,0x8d,0x4c,0x2a,0xc7,0x1c,0xc8,0x5b,0x87,0xd1,0xa3,0x34,0x2d,0xc2,0x6a
            --]]
        end
        keydata_value = string.gsub(string.upper(keydata_value), ",", " ")
        keydata_value = string.gsub(keydata_value, "0X", "0x")

        --[[
        key data value
        0x85 0x1a 0x04 0x06 0xed 0x4f 0x7f 0xa4 0x1c 0x39 0x4b 0x75 0x87 0xab 0x3c 0x74
        0x85 0x22 0x27 0x47 0x38 0x55 0x37 0x97 0x50 0x24 0x93 0x97 0x5a 0xef 0xa6 0x6d
        0x3b 0xad 0xea 0x44 0xc5 0x9f 0xd0 0x52 0x44 0x32 0xbf 0x4c 0x14 0x3a 0x16 0x29
        0xa0 0x66 0xc3 0x92 0xca 0x2e 0xc8 0x06 0xcb 0x39 0x39 0xb0 0x92 0xb8 0xb7 0x61    63
        --]]
        paraTab.Commands = "ace --4cc OTPd --txdata \"" .. keydata_value .. "\" --rxdata 64"
        local ret = dutCmd.sendCmdAndParse(paraTab)
        if string.find(ret, "Error") then
            b_result = false
        else
            b_result = true
            result = "TRUE"
        end

    elseif param1 == "key_Data_crc" then
        -- local Keydata_crc=global.getWord6()
        local Keydata_crc = USBC.getOTPWords(tonumber(0x518), 4, otp_name) -- 0xC4 0xB0 0x76 0x1E
        Keydata_crc = string.gsub(string.upper(Keydata_crc), ",", " ")
        Keydata_crc = string.gsub(Keydata_crc, "0X", "0x")
        -- key data CRC  0xEC 0x06 0x28 0xFB
        paraTab.Commands = "ace --4cc OTPw --txdata \"0x04 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 " .. Keydata_crc ..
                               "\" --rxdata 64"
        local ret = dutCmd.sendCmdAndParse(paraTab)
        if string.find(ret, "Error") then
            b_result = false
        else
            b_result = true
            result = "TRUE"
        end
    else
        b_result = true
    end

    if b_result then
        helper.createRecord(result, paraTab)
    else
        helper.createRecord(b_result, paraTab, nil, nil, nil, result)
        helper.reportFailure(param1 .. 'Error')
    end
    Log.LogInfo('writeOTP_result = ' .. result)

    return result
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0101:, Version: v0.1, Type:Inner]
Name: USBC.setOTPPowerBack
Function description: [v0.1] Function to split string according to input split_char and save into one table
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.setOTPPowerBack(paraTab)
    local fixture = Device.getPlugin("FixturePlugin")
    -- local slot_num = tonumber(Device.identifier:sub(-1))
    helper.LogFixtureControlStart("ace_provisioning_power_off", Device.identifier:sub(-1), "1000")
    fixture.ace_provisioning_power_off(tonumber(Device.identifier:sub(-1)))
    helper.LogFixtureControlFinish('done')
    paraTab.Commands = "ace --pick usbc --4cc SRDY --txdata \"0x00\" --rxdata 0"
    -- local ret = dutCmd.sendCmdAndParse(paraTab)
    -- Log.LogInfo(ret)
    helper.createRecord(true, paraTab)

    return "done"
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0102:, Version: v0.1, Type:Inner]
Name: USBC.eraseFW
Function description: [v0.1] Function to erase ace fw
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.eraseFW(paraTab)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))

    local timeout = paraTab.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout) * 1000
    else
        error("miss timeout")
    end

    helper.LogFixtureControlStart("ace_programmer_id", "nil", tostring(timeout))
    local read_chipid = fixture.fixture_command("ace_programmer_id", "", timeout, slot_num)
    helper.LogFixtureControlFinish(read_chipid)
    local chipid = string.match(string.upper(read_chipid), "ID:(%w+,%w+,%w+)")
    local spi_chipname = string.match(read_chipid, "chip_name:(%w+)")
    
    if spi_chipname and spi_chipname ~= '' and  spi_chipname ~= 'None' then
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, spi_chipname))
    else
        helper.createRecord(false, paraTab, nil, paraTab.attribute, nil,
                            'not define in fwdl_chip_config')
        helper.reportFailure('ace_programmer_id chip_name is Not define')
        return "None"
    end

    local SPI_CHIPS_PATH = paraTab.SPI_CHIPS
    local SPI_CHIPS = {}
    Log.LogInfo('SPI_CHIPS_PATH: ' .. SPI_CHIPS_PATH)
    if comFunc.fileExists(SPI_CHIPS_PATH) then
        SPI_CHIPS = utils.loadPlist(SPI_CHIPS_PATH)
        if SPI_CHIPS then
            Log.LogInfo('SPI_CHIPS: ' .. comFunc.dump(SPI_CHIPS))
        end
    end
    local ACE_ChipName = SPI_CHIPS[chipid]
    if ACE_ChipName == nil then
        helper.createRecord(false, paraTab, 'ACE_ChipName not defined')
        helper.reportFailure('ACE_ChipName not defined')
        return "None"
    end

    local erase_cmd = "ace_programmer_erase"
    helper.LogFixtureControlStart("ace_programmer_erase", ACE_ChipName, tostring(timeout))
    local response = fixture.fixture_command(erase_cmd, ACE_ChipName, timeout, slot_num)
    helper.LogFixtureControlFinish(response)

    if string.find(response, "erasing target successfully") then
        helper.createRecord(ACE_ChipName, paraTab)
    else
        helper.createRecord(false, paraTab, nil, nil, nil, ACE_ChipName)
        helper.reportFailure('ace_programmer_erase Error')
    end

    return ACE_ChipName

end
--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0103:, Version: v0.1, Type:Inner]
Name: USBC.programFW
Function description: [v0.1] Function to program ace fw
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.programFW(paraTab)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local acefw_bin_file = paraTab.ACE_BIN_FILE_NAME

    local timeout = paraTab.Timeout
    if timeout ~= nil and acefw_bin_file ~= nil then
        timeout = tonumber(timeout) * 1000
    else
        error("miss timeout or parameters acefw_bin_file is nil")
    end

    local ACE_ChipName = paraTab.Input
    Log.LogInfo('programFW ACE_ChipName ' .. ACE_ChipName)
    local cmd = "ace_programmer_only"
    Log.LogInfo(cmd .. " " .. ACE_ChipName)

    helper.LogFixtureControlStart(cmd, "nil", tostring(timeout))
    local response = fixture.fixture_command(cmd, ACE_ChipName .. '___' .. acefw_bin_file, timeout, slot_num)
    helper.LogFixtureControlFinish(response)
    local binSizePattern = paraTab.binSizePattern
    local binSize = string.match(response, binSizePattern)

    if string.find(response, "program ok") and binSize then
        helper.createRecord(true, paraTab)
    else
        helper.createRecord(false, paraTab, 'binSize match failed or program not ok', nil, nil,
                            DFULoggingHelper.DEFAULT_FAIL_RESULT)
        helper.reportFailure('ace_programmer_only Error or binSize match failed')
    end

    return binSize
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0104:, Version: v0.1, Type:Inner]
Name: USBC.checkUUTACEFW
Function description: [v0.1] Function to check uut fw for md5 and sha1
Input : table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]

function USBC.checkUUTACEFW(paraTab)
    local fixture = Device.getPlugin("FixturePlugin")
    local slot_num = tonumber(Device.identifier:sub(-1))
    local MD5_HARD = paraTab.MD5_HARD
    local SHA1_HARD = paraTab.SHA1_HARD
    local binSize = paraTab.InputDict.binSize

    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    local Local_FW = "/tmp/FixtureLog_CH" .. tostring(slot_num) .. "/ACE_FW.readback"
    RunShellCommand.run("rm " .. Local_FW)

    local timeout = paraTab.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout) * 1000
    else
        error("miss timeout")
    end

    -- local addr = "0x00000000"
    local ACE_FW_Name = "/mix/addon/dut_firmware/ch" .. tostring(slot_num) .. "/ACE_FW.readback"
    local cmd = "ace_program_readverify"
    local ACE_ChipName = paraTab.InputDict.ACE_ChipName
    helper.LogFixtureControlStart(cmd, ACE_ChipName, tostring(timeout))
    local ret = fixture.fixture_command(cmd, ACE_ChipName .. '___' .. binSize, timeout, slot_num)
    helper.LogFixtureControlFinish(ret)

    fixture.get_and_write_file(ACE_FW_Name, Local_FW, slot_num, timeout)
    local MD5_COMPUTED_XV = string.match(RunShellCommand.run("/sbin/md5 " .. Local_FW).output, "MD5.-=%s(%w+)")
    local SHA1_COMPUTED_XV = string.match(RunShellCommand.run("/usr/bin/openssl sha1 " .. Local_FW).output,
                                          "SHA1.-=%s(%w+)")
    Log.LogInfo('MD5_HARD:' .. MD5_HARD .. ' SHA1_HARD:' .. SHA1_HARD)
    Log.LogInfo('MD5_COMPUTED_XV:' .. MD5_COMPUTED_XV .. ' SHA1_COMPUTED_XV:' .. SHA1_COMPUTED_XV)

    if MD5_HARD == MD5_COMPUTED_XV and SHA1_HARD == SHA1_COMPUTED_XV then
        helper.createRecord(true, paraTab)
    else
        helper.createRecord(false, paraTab, nil, nil, nil, DFULoggingHelper.DEFAULT_FAIL_RESULT)
        helper.reportFailure('checkUUTACEFW Error')
    end

end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0105:, Version: v0.1, Type:Inner]
Name: USBC.checkLocalACEFW
Function description: [v0.1] Function to compare ACE fw md5 and hash code from Mac mini
Input : table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]

function USBC.checkLocalACEFW(paraTab)
    local MD5_HARD = paraTab.MD5_HARD
    local SHA1_HARD = paraTab.SHA1_HARD
    local ACE_BIN_FILE_NAME = paraTab.ACE_BIN_FILE_NAME

    local local_fw_path = "/Users/gdlocal/Library/Atlas2/Config/ACE_FW/"
    local local_fw_fullpath = tostring(local_fw_path .. "/" .. ACE_BIN_FILE_NAME)
    Log.LogInfo('$$$$ local_fw_fullpath: ' .. local_fw_fullpath)
    local MD5_COMPUTED_MM = string.match(DFUCommon.runShellCmd("/sbin/md5 " .. local_fw_fullpath).output, "MD5.-=%s(%w+)")
    local SHA1_COMPUTED_MM = string.match(DFUCommon.runShellCmd("/usr/bin/openssl sha1 " .. local_fw_fullpath).output,
                                          "SHA1.-=%s(%w+)")

    Log.LogInfo('$$$$ MD5_COMPUTED_MM: ' .. MD5_COMPUTED_MM)
    Log.LogInfo('$$$$ SHA1_COMPUTED_MM: ' .. SHA1_COMPUTED_MM)

    -- local result = false
    if MD5_HARD == MD5_COMPUTED_MM and SHA1_HARD == SHA1_COMPUTED_MM then
        helper.createRecord(true, paraTab)
    else
        helper.createRecord(false, paraTab, nil, nil, nil, DFULoggingHelper.DEFAULT_FAIL_RESULT)
        helper.reportFailure('checkLocalACEFW Error')
    end

end


--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0106:, Version: v0.1, Type:Inner]
Name: USBC.checkLocalACEFW
Function description: [v0.1] Function to compare RT13 fw version
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.checkRT13FWVersion(paraTab)
    local expect = paraTab.expect
    local data = paraTab.Input
    local flag = false
    local failureMsg = ""
    local t = {}

    local data1 = string.gsub(data, "0x00", "")
    Log.LogInfo("$$$$$data1:  ",data1)

    for v in string.gmatch(data1,"(0x%w+)") do
        table.insert(t, v)
    end

    local result = string.char(table.unpack(t))
    Log.LogInfo("$$$$$result:  ",result)
    if result ~= "" then
        if result == expect then
            flag = true
            if paraTab.attribute then
                DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, result))
            end
        else
            failureMsg = "match error, target value [" .. expect .. "] got value [" .. result .. "]"
        end
    else
        failureMsg = "result is null"
    end

    if flag then
        helper.createRecord(flag, paraTab)
    else
        helper.createRecord(flag, paraTab, failureMsg, nil, nil, flag)
        if paraTab.fa_sof == "YES" then
            helper.reportFailure(failureMsg)
        end
    end
    return result
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0107:, Version: v0.1, Type:Inner]
Name: USBC.checkXavierACEFW
Function description: [v0.1] Function to compare ACE fw md5 and hash code from Xavier
Input : table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]

function USBC.checkXavierACEFW(paraTab)
    local MD5_HARD = paraTab.MD5_HARD
    local SHA1_HARD = paraTab.SHA1_HARD
    local ACE_BIN_FILE_NAME = paraTab.ACE_BIN_FILE_NAME

    local slot_num = tonumber(Device.identifier:sub(-1))
    local Save_path = "/tmp/FixtureLog_CH" .. tostring(slot_num)
    local Local_FW = Save_path .. "/" .. ACE_BIN_FILE_NAME
    DFUCommon.runShellCmd("mkdir " .. Save_path)
    DFUCommon.runShellCmd("rm " .. Local_FW)

    local fixture = Device.getPlugin("FixturePlugin")
    -- local slot_num = tonumber(Device.identifier:sub(-1))
    local timeout = paraTab.Timeout
    if timeout ~= nil then
        timeout = tonumber(timeout) * 1000
    else
        error("miss timeout")
    end
    local ACE_FW_Name = "/mix/addon/dut_firmware/ch" .. tostring(slot_num) .. "/" .. ACE_BIN_FILE_NAME
    fixture.get_and_write_file(ACE_FW_Name, Local_FW, slot_num, timeout)
    local MD5_COMPUTED_XV = string.match(DFUCommon.runShellCmd("/sbin/md5 " .. Local_FW).output, "MD5.-=%s(%w+)")
    local SHA1_COMPUTED_XV = string.match(DFUCommon.runShellCmd("/usr/bin/openssl sha1 " .. Local_FW).output,
                                          "SHA1.-=%s(%w+)")

    if MD5_HARD == MD5_COMPUTED_XV and SHA1_HARD == SHA1_COMPUTED_XV then
        helper.createRecord(true, paraTab)
    else
        helper.createRecord(false, paraTab, nil, nil, nil, DFULoggingHelper.DEFAULT_FAIL_RESULT)
        helper.reportFailure('checkXavierACEFW Error')
    end

end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0033, Version: v0.1, Type:DFU]
Name: USBC.checkAceFWVersion(paraTab)
Function description: [v0.1] Function to check diags ACEFWVersion to attribute
Input : Table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]
function USBC.checkAceFWVersion(paraTab)
    helper.flowLogStart(paraTab)
    local expect = paraTab.expect
    local hexVersion = paraTab.Input
    local readVersion = string.gsub(hexVersion, '0x', '')
    local data = comFunc.splitString(readVersion, " ")
    local AceFWVersion = ""
     
    --00 06 30 00 0A 00 0A 00
    if data and #data == 8 then
        local appConfigVersion = tonumber(data[5], 16)
        local customerVersion = tonumber(data[6], 16)

        AceFWVersion = data[4] .. string.sub(data[3], 1, 1) .. "." .. string.sub(data[3], 2, 2) .. data[2] .. "." ..
                            data[1] .. "." .. string.format("%02X", appConfigVersion) .. "." ..
                            string.format("%02X", customerVersion)
    end

    if paraTab.attribute then
        DataReporting.submit(DataReporting.createAttribute(paraTab.attribute, AceFWVersion))
    end
    
    local status, result = xpcall(compare.CompareInfo, debug.traceback, { firstValue = AceFWVersion, 
        secondValue = expect })

    if expect and result then
        helper.flowLogFinish(true, paraTab, AceFWVersion)
    else
        local failureMsg = "error result: " .. AceFWVersion
        helper.flowLogFinish(false, paraTab, AceFWVersion, failureMsg)
        if raiseErrorWhenFailed and raiseErrorWhenFailed == "YES" then
            helper.reportFailure(failureMsg)
        end
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0108:, Version: v0.1, Type:Inner]
Name: USBC.readPMUadcValue
Function description: [v0.1] Function to add retries to read PMU adc value since it may be OV
Input : table(paraTab)
Output : N/A
-----------------------------------------------------------------------------------]]

function USBC.readPMUadcValue(paraTab)
    local Retries = paraTab.Retries
    local ret = -999999
    local limitTab = paraTab.limit
    local limits = limitTab[paraTab.subsubtestname]

    for i = 1, tonumber(Retries) do
        ret = dutCmd.sendCmdAndParse(paraTab)
        Log.LogInfo('read PMU adc times: ' .. i)
        if limits and tonumber(ret) < tonumber(limits.upperLimit) and tonumber(ret) > tonumber(limits.lowerLimit) then
            break
        end
    end

    helper.createRecord(tonumber(ret), paraTab)
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0109:, Version: v0.1, Type:Inner]
Name: USBC.checkStationInfo
Function description: [v0.1] Function to query CFG from sfc and check 
                             if the key's string is meet to bundle and the BB fw
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.checkStationInfo(paraTab)
    local dut_cfg = DFUCommon.sfcQuery(paraTab)
    local bundle_path = "/Users/gdlocal/RestorePackage/"
    local baseband_path = "/Users/gdlocal/RestorePackage/CurrentBaseband/"

    local StationInfo = Atlas.loadPlugin("StationInfo")
    local Product = string.gsub(StationInfo.product(), 'J', '')
    local Product_number = tonumber(Product)

    local cfg, bb_flag = string.match(dut_cfg, "%_(%w+).-(%w+)")
    local LKey = string.sub(cfg, tonumber(#cfg), tonumber(#cfg))
    local FKey = string.sub(cfg, 1, 1)
    local bundleInfo_list_path = paraTab.path
    local target_value
    if dut_cfg ~= nil and dut_cfg ~= "" and comFunc.fileExists(bundleInfo_list_path) then
        local bundleInfo_list = utils.loadPlist(bundleInfo_list_path)
        for key, value in pairs(bundleInfo_list) do
            if #key == 3 then
                local target_key = FKey .. '*' .. LKey
                if key == target_key then
                    target_value = value
                    break
                end
            end
        end

        if not target_value then
            for key, value in pairs(bundleInfo_list) do
                if #key == 2 then
                    local target_key = '*' .. LKey
                    if key == target_key then
                        target_value = value
                        break
                    end
                end
            end
        end

        if target_value then
            local target_bundle_path = bundle_path .. target_value[2] .. '_J' .. tostring(Product_number) .. '_J' ..
                                           tostring(Product_number + 1)
            local target_baseband_path = baseband_path .. target_value[1]
            if not comFunc.fileExists(target_bundle_path) then
                helper.createRecord(false, paraTab, "bundle is not right", nil, nil,
                                    DFULoggingHelper.DEFAULT_FAIL_RESULT)
                return
            end
            if bb_flag ~= "P" then
                if not comFunc.fileExists(target_baseband_path) then
                    helper.createRecord(false, paraTab, "baseband is not right", nil, nil,
                                        DFULoggingHelper.DEFAULT_FAIL_RESULT)
                end
            end
        end
    end
end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID0110:, Version: v0.1, Type:Inner]
Name: USBC.SFCSendRead
Function description: [v0.1] Function to send Grimaldi VOUT_FS and VOUT_OFFECT
Input : table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.SFCSendRead(paraTab)
    local station_info_file = "/vault/data_collection/test_station_config/gh_station_info.json"
    local file = io.open(station_info_file, "r")
    local sfc_url = nil
    -- local sfc_url = "http://10.12.5.79:80/peach/exi/me/bobcat?"


    local sn = paraTab["MLB_Num"]
    Log.LogInfo("$$$$ sn: " .. sn)
    local sn_cmd = "&sn="..sn

    local Ace3_CRC1_I2C_Vault = string.gsub(paraTab["Ace3_CRC1_I2C"]," ",",")
    local Ace3_CRC1_I2C_Vault_cmd = "&ACE3L_CRC1_I2C="..Ace3_CRC1_I2C_Vault
    Log.LogInfo("$$$$ CRC1: " .. Ace3_CRC1_I2C_Vault_cmd)
    local Ace3_CRC2_I2C_Vault = string.gsub(paraTab["Ace3_CRC2_I2C"]," ",",")
    local Ace3_CRC2_I2C_Vault_cmd = "&ACE3L_CRC2_I2C="..Ace3_CRC2_I2C_Vault
    Log.LogInfo("$$$$ CRC2: " .. Ace3_CRC2_I2C_Vault_cmd)
    local Ace3_CRC3_I2C_Vault = string.gsub(paraTab["Ace3_CRC3_I2C"]," ",",")
    local Ace3_CRC3_I2C_Vault_cmd = "&ACE3L_CRC3_I2C="..Ace3_CRC3_I2C_Vault    
    Log.LogInfo("$$$$ CRC3: " .. Ace3_CRC3_I2C_Vault_cmd)

    -- local sfc_key_cmd = "&"..sfc_key.."="..sfc_value

    if file ~= nil then
        local context = file:read("*all")
        if context ~= nil then
            local config = comFunc.parseParameter(context)
            sfc_url = config["ghinfo"]["SFC_URL"]
        end
    end
    Log.LogInfo("$$$$ sfc_url: " .. sfc_url)
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    -- upload
    local SendDataResult = RunShellCommand.run("curl \""..sfc_url.."c=ADD_ATTR"..Ace3_CRC1_I2C_Vault_cmd..Ace3_CRC2_I2C_Vault_cmd..Ace3_CRC3_I2C_Vault_cmd..sn_cmd.."\"").output

    if string.find(SendDataResult,'SFC_OK') == nil then 
        Log.LogInfo("$$$Send curl command fail!$$$"..SendDataResult)
    else
        Log.LogInfo("$$$Send curl Success !$$$"..SendDataResult)
    end
    -- download
    local ResultURL = RunShellCommand.run("curl \""..sfc_url.."c=QUERY_RECORD"..sn_cmd.."&p=ACE3L_CRC1_I2C&p=ACE3L_CRC2_I2C&p=ACE3L_CRC3_I2C".."\"").output

    if string.find(ResultURL,'SFC_OK') ~= nil and string.find(ResultURL,Ace3_CRC1_I2C_Vault) and string.find(ResultURL,Ace3_CRC2_I2C_Vault) and string.find(ResultURL,Ace3_CRC3_I2C_Vault) then   
        Log.LogInfo("$$$ResultURL curl Success!$$$"..ResultURL)
        helper.createRecord(true, paraTab, nil, nil, nil, 'PASS')
    else
        Log.LogInfo("$$$ResultURL curl Fail!$$$"..ResultURL)
        helper.createRecord(false, paraTab, ret, nil, nil, 'FAIL')
    end

    return sfc_url

end

--[[---------------------------------------------------------------------------------
Unique Function ID : [ID:0034, Version: v0.1, Type:DFU]
Name: USBC.readACEVoltage(paraTab)
Function description: [v0.1]Function to get the ACE ADC results.
Input :  Table(paraTab)
Output : string
-----------------------------------------------------------------------------------]]

function USBC.readACEVoltage(paraTab)
    helper.flowLogStart(paraTab)
    local value_result = -1
    local ret = paraTab.Input
    local pattern = paraTab.pattern

    if ret == nil then   
         helper.reportFailure("miss inputValue")
    else
        local a, b = string.match(ret, pattern)
        Log.LogInfo("ACE a: ".. a)
        Log.LogInfo("ACE b: ".. b)

        local status, value_result = xpcall(common.calValue, debug.traceback, { value = tonumber("0x" .. b .. a), 
        scale = paraTab.scale, formula = paraTab.formula, calmode = paraTab.calmode, InnerCall = paraTab.InnerCall })

        Log.LogInfo("ACE value_result: ".. value_result)

        if status and value_result then
            helper.flowLogFinish(true, paraTab, value_result)
        else
            helper.flowLogFinish(false, paraTab, value_result, "Read ACE Voltage Fail")  
        end
    end
    return ret
end

return USBC
