local diags = {}

diags.list = {
               
                Send_accel_init_normal_CMD                      = { cmd = "sensor --sel gyro --turnoff;wait 20;sensor --sel accel,gyro --init;wait 200",parse_str = ""},
                Send_accel_selftest_CMD                         = { cmd = "sensor --sel gyro --exectest selftest;sensor --sel accel,gyro --turnoff;wait 20",parse_str = ""},
                Read_accel_only_test                            = { cmd = "sensor --sel accel --init;wait 20;sensor --sel accel --exectest selftest;sensor --sel accel --turnoff;wait 20",parse_str = ""},
                Read_accel_connectivity                         = { cmd = "sensor --sel accel --init;wait 20;sensor --sel accel --conntest;sensor --sel accel --turnoff;wait 20",parse_str = ""},
                Send_accel_only_test_CMD                        = { cmd = "sensor --sel accel --exectest selftest_manual;sensor --sel accel --turnoff;wait 20",parse_str = ""},
                Send_accel_only_test_sec_CMD                    = { cmd = "sensor --sel accel --init;wait 20;sensor --sel accel --set rate 100;sensor --sel accel --set dynamic_range 16;sensor --sel accel --sample 500ms --stats;sensorreg -s accel --dump;sensor --sel accel --turnoff",parse_str = ""},
                Send_sample_stats_CMD_1                         = { cmd = "sensor --sel accel,gyro --init;wait 200;sensor --sel accel --set rate 200;sensor --sel gyro --set rate 200;sensor --sel accel --set dynamic_range 16;sensor --sel gyro --set dynamic_range 2000;sensor --sel accel,gyro --sample 500ms --stats",parse_str = ""},
                Read_vendor                                     = { cmd = "sensor --listsensors",parse_str = ""},
                Send_GPIO_SOC_TO_FCAM_SHTDWN_L_HIGH_CMD         = { cmd = "socgpio --port 0 --pin 118 --output 1",parse_str = ""},
                Read_GPIO_SOC_TO_FCAM_SHTDWN_L                  = { cmd = "socgpio --port 0 --pin 118 --get",parse_str = "]%s+=%s+(%d)"},
                Send_GPIO_SOC_TO_FCAM_SHTDWN_L_LOW_CMD          = { cmd = "socgpio --port 0 --pin 118 --output 0",parse_str = ""},
                Send_GPIO_SOC_TO_RCAM_SHTDWN_L_HIGH_CMD         = { cmd = "socgpio --port 0 --pin 119 --output 1",parse_str = ""},
                Read_GPIO_SOC_TO_RCAM_SHTDWN_L                  = { cmd = "socgpio --port 0 --pin 119 --get", parse_str = "]%s+=%s+(%d)"},
                Send_GPIO_SOC_TO_RCAM_SHTDWN_L_LOW_CMD          = { cmd = "socgpio --port 0 --pin 119 --output 0",parse_str = ""},
                Read_Diag_Board_REV                             = { cmd = "boardrev",parse_str ="Board Revision: ([0-9a-zA-Z]+)"},
                Read_Diags_version                              = { cmd = "version",parse_str ="Version%s*%-%s*([0-9A-Za_-z-.]+)"},
                Send_Initial_CMD                                = { cmd = "syscfg init",parse_str =""},
                Set_RTC_syscfg                                  = { cmd = "rtc --set",parse_str =""},
                Send_RTC_get_CMD                                = { cmd = "rtc --get",parse_str =""},
                Send_Begin_syscfglist_CMD                       = { cmd = "syscfg list",parse_str = ""},
                Send_RFEM_print_CMD                             = { cmd = "syscfg printbyte RFEM",parse_str = ""},
                Send_WSKU_print_CMD                             = { cmd = "syscfg print WSKU",parse_str = ""},
                Send_accel_gyro_normal_test_CMD                 = { cmd = "sensor --sel gyro --get",parse_str = ""},
                Send_gyro_init_normal_CMD                       = { cmd = "sensor --sel gyro --init;wait 200",parse_str = ""},
                Send_gyro_connectivity_CMD                      = { cmd = "wait 20;sensor --sel gyro --conntest",parse_str = ""},
                Send_gyro_selftest_CMD                          = { cmd = "sensor --sel accel,gyro --init;wait 200;sensor --sel gyro --exectest selftest;sensor --sel accel,gyro --turnoff;wait 20",parse_str = ""},
                Send_sample_stats_CMD                           = { cmd = "sensor --sel accel,gyro --init;wait 200;sensor --sel accel --set rate 200;sensor --sel gyro --set rate 200;sensor --sel accel --set dynamic_range 16;sensor --sel gyro --set dynamic_range 2000;sensor --sel accel,gyro --sample 500ms --stats;sensorreg -s gyro --dump;sensor --sel accel,gyro --turnoff",parse_str = ""},
                Read_NANDUID                                    = { cmd = "nanduid",parse_str = ""},
                Read_NAND_CSID                                  = { cmd = "nandcsid",parse_str = "NANDID = ([0-9A-Za-z]+);"},
                Read_NAND_Vendor                                = { cmd = "NANDInfoTool",parse_str = "Vendor:%s+([A-Za-z]+)"},
                Read_NAND_Model_Number                          = { cmd = "nand --get Identify",parse_str = "Model number%s+: ([0-9A-Za-z ]+)"},
                Send_NAND_SIZE_RUN_CMD                          = { cmd = "nandsize",parse_str = ""},
                Send_NAND_DEBUG_TEST_BEGIN_CMD                  = { cmd = "upy nandfs:\\AppleInternal\\Diags\\Python\\lib\\test\\nand.py -d",parse_str = ""},
                Send_NAND_DEBUG_TEST_END_CMD                    = { cmd = "upy nandfs:\\AppleInternal\\Diags\\Python\\lib\\test\\nand.py -d",parse_str = ""},
                Send_Smokey_PCIe_Eye_Scan_CMD                   = { cmd = "smokey --run PCIeEyeScan ResultsBehavior=NoFile LogBehavior=ConsoleOnly DisplayBehavior=NoDisplay --clean", parse_str = ""},
                Send_Smokey_PCIe_S5E_CMD                        = { cmd = "upy nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsS5E\\main.py --AdditionalPdca nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsS5E\\AdditionalPdca.plist;cat nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsS5E\\results.txt", parse_str = ""},
                Send_Touch_ShortsTest_Off_CMD                   = { cmd = "touch --off",parse_str = ""},
                Send_Set_Safe_Mode_CMD                          = { cmd = "touch --set_param boot-safe-mode yes", parse_str = ""},
                Send_Touch_On_CMD                               = { cmd = "touch --on",parse_str = ""},
                Send_GPIO_GRAPE_TO_TCON_FORCE_PWM_LOW_CMD       = { cmd = "egpio --pick touch:1 --pin 11 --mode output --write 0", parse_str = ""},
                Send_GPIO_GRAPE_TO_TCON_FORCE_PWM_HIGH_CMD      = { cmd = "egpio --pick touch:1 --pin 11 --mode output --write 1", parse_str = ""},
                Read_GPIO_GRAPE_TO_TCON_FORCE_PWM_STATE         = { cmd = "egpio --pick touch:1 --pin 11 --read", parse_str = "unit 1 pin 0.11:%s*(%d)"},
                Send_Touch_ShortsTest_Off_CMD                   = { cmd = "touch --off",parse_str = ""},
                Set_SWD_NUB_BI_PMU_SWDIO_H                      = { cmd = "socgpio --port 5 --pin 3 --output 1",parse_str = ""},
                Read_SWD_NUB_BI_PMU_SWDIO                       = { cmd = "socgpio --port 5 --pin 3 --get",parse_str = "]%s+=%s+(%d)"},
                Set_SWD_NUB_BI_PMU_SWDIO_L                      = { cmd = "socgpio --port 5 --pin 3 --output 0",parse_str = ""},
                Read_GPIO_SOC_TO_BT_TO_GRAPE_TS_SYNC            = { cmd = "socgpio --port 0 --pin 10 --get", parse_str = "]%s+=%s+(%d)"},
                Send_SOCGPIO_PORT0_PIN10_OUTPUT_1_CMD           = { cmd = "socgpio --port 0 --pin 10 --output 1", parse_str = ""},
                Send_SOCGPIO_PORT0_PIN10_OUTPUT_0_CMD           = { cmd = "socgpio --port 0 --pin 10 --output 0", parse_str = ""},
                Send_GPIO_ACE_TO_SMC_IRQ_L_LOW_CMD              = { cmd = "socgpio --port 5 --pin 14 --output 0", parse_str = ""},
                Read_GPIO_ACE_TO_SMC_IRQ_L                      = { cmd = "socgpio --port 5 --pin 14 --get", parse_str = "]%s+=%s+(%d)"},
                Send_GPIO_ACE_TO_SMC_IRQ_L_HIGH_CMD             = { cmd = "socgpio --port 5 --pin 14 --output 1", parse_str = ""},
                Send_Test_mode_Enable_CMD_BAKU                  = { cmd = "reg select pmu;reg write 0xfe00 0x61 0x45 0x72 0x4F", parse_str = ""},
                Read_Test_mode_BAKU                             = { cmd = "reg read 0xfe05",parse_str ="0xFE05%s*=>%s*(%w+)"},
                Send_Trigger_PIN_CMD                            = { cmd = "reg write 0x18a9 0x1C;reg write 0x18ad 0x1C;reg write 0x18a5 0x3", parse_str = ""},
                Read_THROTTLE1_L                                = { cmd = "socgpio --port 0 --pin 83 --get", parse_str = "SoC%s*GPIO%[%d*,%d*%]%s*=%s*(%d+)"},
                Read_THROTTLE2_L                                = { cmd = "socgpio --port 0 --pin 84 --get", parse_str = "SoC%s*GPIO%[%d*,%d*%]%s*=%s*(%d+)"},
                Read_THROTTLE3_L                                = { cmd = "socgpio --port 0 --pin 85 --get", parse_str = "SoC%s*GPIO%[%d*,%d*%]%s*=%s*(%d+)"},
                Send_Throttle_Outputs_High_CMD_BAKU             = { cmd = "reg write 0x18b0 0x01",parse_str =""},
                Send_Throttle_Outputs_Default_CMD_BAKU          = { cmd = "reg write 0x18ba 0x14;reg write 0x18be 0x04;reg write 0x18c2 0x0c;reg write 0x18b2 0x00", parse_str = ""},
                Send_Config_PMU_Trigger0_Default_CMD            = { cmd = "reg write 0x18a9 0x01",parse_str =""},
                Send_Config_PMU_Trigger1_Default_CMD            = { cmd = "reg write 0x18ad 0x01",parse_str =""},
                Send_Config_PMU_UVWRN_Default_CMD               = { cmd = "reg write 0x18a5 0x0",parse_str =""},
                Send_Exit_test_mode_CMD                         = { cmd = "reg write 0xfe04 0x0",parse_str =""},
                Send_Test_mode_Enable_CMD_Firebird              = { cmd = "spmi --select spmi_nub1;spmi --write --sid 0xF --addr 0xd000 --data 0x61;spmi --write --sid 0xF --addr 0xd001 --data 0x45;spmi --write --sid 0xF --addr 0xd002 --data 0x72;spmi --write --sid 0xF --addr 0xd003 --data 0x4f", parse_str = ""},
                Read_Test_mode_Firebird                         = { cmd = "spmi --read --sid 0xF --addr 0xd005",parse_str ="0xD005%s*=>%s*(%w+)"},
                Send_Firebird_Config_PMU_Trigger_CMD            = { cmd = "spmi --write --sid 0xF --addr 0x181e --data 0xA0", parse_str = ""},
                Send_Throttle_Outputs_Default_CMD_Firebird      = { cmd = "spmi --write --sid 0xF --addr 0x181e --data 0x00", parse_str = ""},
                Send_Throttle_Outputs_HIGH_CMD_Firebird         = { cmd = "spmi --write --sid 0xF --addr 0x181f --data 0x00", parse_str = ""},
                Send_SHUT_DOWN_CMD                              = { cmd = "shutdown", parse_str = ""},
                Send_Phos2_test_CMD                             = { cmd = "sensor --listsensors;sensor --sel pressure --init;sensor --sel pressure --conntest;sensor --sel pressure --turnoff;wait 20;sensor --sel pressure --init;sensorreg --sel pressure -r 0xD0 1;sensorreg --sel pressure -r 0xF3 3;sensorreg --sel pressure -r 0x80 36",parse_str = ""},
                Read_Press_Average                              = { cmd = "sensorreg --sel pressure -r 0xF7 6;sensor --sel pressure --sample 1000ms --stats;sensor --sel pressure --turnoff",parse_str = "average: pressure = ([+-]?[0-9.]+), temp = [+-]?[0-9.]+"},
                Send_CB_Initial_CMD                             = { cmd = "cbinit",parse_str =""},
                Send_Enter_Diag_CMD                             = { cmd = "diags",parse_str = ""},
                Send_Enter_Iboot_CMD                            = { cmd = "iboot",parse_str = ""},
                Send_Enter_RBM_CMD                              = { cmd = "rbm",parse_str =""},
                Send_Enter_RTOS_CMD                             = { cmd = "rtos",parse_str =""},
                Write_ICT_CB                                    = { cmd = "cbskip smt",parse_str = ""},
                Set_RTC_Start                                   = { cmd = "rtc --set",parse_str =""},
                Disable_UART_TX_ACE3L                           = { cmd = "consolesinkctrl --sink uart --dis",parse_str = ""},
                Send_BB_Load_Firmware_CMD                       = { cmd = "time baseband --off --on --load_firmware",parse_str = "firmware%-load%=(%S+)"},
                Send_BB_Wait_For_Ready_CMD                      = { cmd = "time baseband --wait_for_ready ",parse_str = ""},
                Send_BB_PING_CMD                                = { cmd = "baseband --ping",parse_str = ""},
                Send_BB_Properties_CMD                          = { cmd = "baseband --properties",parse_str = ""},
                Send_BB_OFF_CMD                                 = { cmd = "baseband --off",parse_str = ""},
                Send_BT_ON_CMD                                  = { cmd = "bluetooth --on",parse_str = ""},
                Send_BT_Load_Firmware_CMD                       = { cmd = "bluetooth --load_firmware",parse_str = ""},
                Send_BT_Properties_CMD                          = { cmd = "bluetooth --properties",parse_str = ""},
                Send_BT_OFF_CMD                                 = { cmd = "bluetooth --off",parse_str = ""},
                Send_SH_ON_CMD                                  = { cmd = "stockholm --on",parse_str = ""},
                Send_SH_INIT_CMD                                = { cmd = "stockholm --init",parse_str = ""},
                Send_SH_Load_Firmware_CMD                       = { cmd = "stockholm --download_fw mfg",parse_str = ""},
                Send_SH_Properties_CMD                          = { cmd = "stockholm --properties",parse_str = ""},
                Send_SH_Loopback_20_CMD                         = { cmd = "stockholm --loopback 20",parse_str = "PASS"},
                Send_SH_OFF_CMD                                 = { cmd = "stockholm --off",parse_str = ""},
                Send_Smokey_PCIe_BB_CMD                         = { cmd = "upy nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsBaseband\\main.py --AdditionalPdca nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsBaseband\\AdditionalPdca.plist;cat nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsBaseband\\results.txt",parse_str = ""},
                Send_Smokey_PCIe_Gpstorage_CMD                  = { cmd = "upy nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsGPStorage\\main.py --AdditionalPdca nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsGPStorage\\AdditionalPdca.plist;cat nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsGPStorage\\results.txt",parse_str = ""},
                Send_Smokey_PCIe_Wifi_CMD                       = { cmd = "upy nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsWifi\\main.py --AdditionalPdca nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsWifi\\AdditionalPdca.plist;cat nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\AEMToolsWifi\\results.txt",parse_str = ""},
                Send_Sunrise_Efuse_CMD                          = { cmd = "smokey --run SunriseEfuse DisplayBehavior=NoDisplay LogBehavior=ConsoleOnly ResultsBehavior=NoFile --clean",parse_str = ""},
                Send_Smokey_Run_CMD                             = { cmd = "Smokey WDFU --run DisplayBehavior=NoDisplay;consoleformat --dis --sink serial -o ts",parse_str = ""},
                Send_WMAC_Write_CMD                             = { cmd = "syscfg add WMac 0x00000000 0x00000100 0x00000000 0x00000000",parse_str = ""},
                Send_WMAC_Read_CMD                              = { cmd = "syscfg print WMac",parse_str = "0x00000000 0x00000100 0x00000000 0x00000000"},
                Send_BMAC_Write_CMD                             = { cmd = "syscfg add BMac 0x00000000 0x00000200 0x00000000 0x00000000",parse_str = ""},
                Send_BMAC_Read_CMD                              = { cmd = "syscfg print BMac",parse_str = "0x00000000 0x00000200 0x00000000 0x00000000"},
                Send_EMAC_Write_CMD                             = { cmd = "syscfg add EMac 0x00000000 0x00000300 0x00000000 0x00000000",parse_str = ""},
                Send_EMAC_Read_CMD                              = { cmd = "syscfg print EMac",parse_str = "0x00000000 0x00000300 0x00000000 0x00000000"},
                Send_WIFI_ON_CMD                                = { cmd = "wifi --on",parse_str = ""},
                Send_WIFI_Load_Firmware_CMD                     = { cmd = "wifi --load_firmware",parse_str = ""},
                Send_WIFI_Properties_CMD                        = { cmd = "wifi --properties",parse_str = ""},
                Send_WIFI_OTP_CMD                               = { cmd = "wifi --dump_otp ",parse_str = ""},
                Send_WIFI_OFF_CMD                               = { cmd = "wifi --off",parse_str = ""},
                Read_BOARD_ID                                   = { cmd = "boardid command",parse_str ="Board Id: (0x[0-9A-Fa-f]+)"},
                Read_QUERY_CHIP_ID                              = { cmd = "chipid",parse_str =""},
                Read_SOC_Binning_Revision_Write                 = { cmd = "soc -p",parse_str ="binning%-revision:%s*(%d+)"},
                Send_ISP_FW_Mes_CMD                             = { cmd = "camisp --find",parse_str = ""},
                Send_INIT_SEP_CMD                               = { cmd = "sep --init",parse_str = ""},
                Send_Wait_SEP_CMD                               = { cmd = "sep --wait_for_ready",parse_str = ""},
                Send_INFO_SEP_CMD                               = { cmd = "sep --info",parse_str = ""},
                Send_SEP_Get_CMD                                = { cmd = "sep -g",parse_str = ""},
                Send_LYNX_CMD                                   = { cmd = "sep -e lynx lynt --timeout 60000000",parse_str = ""},
                Send_Console_CMD                                = { cmd = "sep -c",parse_str = "self%-test successful"},
                Send_AWL_eeprom_set_CMD                         = { cmd = "i2c -s 9",parse_str =""},
                Send_AWL_eeprom_CMD                             = { cmd = "i2c -z 2 -d 9 0x50 0x0010 8",parse_str =""},
                Send_AWL_eeprom_set_1_CMD                       = { cmd = "i2c -z 2 -v 9 0x50 0x0010 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08",parse_str =""},
                Send_AWL_eeprom_read_CMD                        = { cmd = "i2c -z 2 -d 9 0x50 0x0010 8",parse_str =""},
                Send_AWL_eeprom_set_2_CMD                       = { cmd = "i2c -z 2 -v 9 0x50 0x0010 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF",parse_str =""},
                Send_AWL_eeprom_read_2_CMD                      = { cmd = "i2c -z 2 -d 9 0x50 0x0010 8",parse_str =""},
                Read_THERMAL0_Instant                           = { cmd = "temperature --all",parse_str = "THERMAL0.-Instant: (-?[0-9.]+)"},
                Read_cpmu2_TCAL                                 = { cmd = "camisp --find;reg select cpmu2;pmuadc --sel cpmu --read tcal",parse_str = "expansion cpmu: tcal: (-?[0-9.]+)"},
                Read_cpmu2_TDEV1                                = { cmd = "pmuadc --sel cpmu --read tdev1;camisp --exit",parse_str = "expansion cpmu: tdev1: (-?[0-9.]+)"},
                Read_cpmu_TCAL                                  = { cmd = "camisp --find;reg select cpmu;pmuadc --sel cpmu --read tcal",parse_str = "expansion cpmu: tcal: (-?[0-9.]+)"},
                Read_cpmu_TDEV1                                 = { cmd = "pmuadc --sel cpmu --read tdev1;camisp --exit",parse_str = "expansion cpmu: tdev1: (-?[0-9.]+)"},
                Send_Audio_reset_1_CMD                          = { cmd = "audio -r",parse_str = ""},
                Send_Audio_reset_2_CMD                          = { cmd = "audio --resetblock spk_cn_l_w",parse_str = ""},
                Send_Audio_reset_3_CMD                          = { cmd = "audio --resetblock spk_cn_l_w",parse_str = ""},
                Send_Audio_turnoff_1_CMD                        = { cmd = "audio --turnoff",parse_str = ""},
                Send_Audio_reset_4_CMD                          = { cmd = "audio -r",parse_str = ""},
                Send_Audio_reset_5_CMD                          = { cmd = "audio --resetblock spk_fh_l_w",parse_str = ""},
                Send_Audio_reset_6_CMD                          = { cmd = "audio --resetblock spk_fh_l_w",parse_str = ""},
                Send_Audio_turnoff_2_CMD                        = { cmd = "audio --turnoff",parse_str = ""},
                Send_Touch_ShortsTest_Off_CMD                   = { cmd = "touch --off",parse_str = ""},
                Send_Touch_set_power_delay_normal_CMD           = { cmd = "touch --set_param power-delay normal",parse_str = ""},
                Send_Kona_Power_Cycles_CMD                      = { cmd = "repeat 5 \"touch --off;stall 30000;touch --on;stall 50000\"",parse_str = ""},
                Send_touch_set_power_delay_disable_CMD          = { cmd = "touch --set_param power-delay disabled",parse_str = ""},
                Send_Kona_Trimmed_CMD                           = { cmd = "touch --off;wait 500;touch --on;touch --test trim_data --run",parse_str = ""},
                Send_Touch_ShortsTest_Off_CMD                   = { cmd = "touch --off",parse_str = ""},
                Send_TouchDFUIQMeas_CMD                         = { cmd = "smokey Wildfire --test TouchDFUIQMeas --testargs \"TouchDFUIQMeas,TestStation='dfuiq'\" --run \"SerialNumberSource='MLB#'\" DisplayBehavior=NoDisplay --clean",parse_str = ""},
                Send_Smokey_Log_cat_CMD                         = { cmd = "cat nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\Wildfire\\Smokey.log",parse_str = ""},
                Send_Touch_GPIO_Test_CMD                        = { cmd = "smokey Wildfire --run DisplayBehavior=NoDisplay ControlBitAccess=ReadOnly BrickRequired=None ResultsBehavior=NoFile LogBehavior=ConsoleOnly --test TouchGpio",parse_str = ""},
                Send_Touch_Off_CMD                              = { cmd = "touch --off",parse_str = ""},
                Send_Touch_Safe_Mode_CMD                        = { cmd = "touch --sel grape --set_param boot-safe-mode true",parse_str = ""},
                Send_Touch_Shorts_Test_CMD                      = { cmd = "smokey --run Wildfire --test \"TouchShorts\" ControlBitAccess=ReadOnly \"SerialNumberSource='MLB#'\" DisplayBehavior=NoDisplay",parse_str = ""},
                Read_FW_Version                                 = { cmd = "ace --pick ATC0;ace --read 0x0f",parse_str ="0000000:%s+(%w+%s+%w+%s+%w+%s+%w+%s+%w+%s+%w+%s+%w+%s+%w+)"},
                Send_AID0_Channel_Enable_CMD                    = { cmd = "device -k ATC0 -e “send_aid_bidirectional --bus=0 --op_type=IDLE”",parse_str =""},
                Send_Break_Pulse_CMD                            = { cmd = "device -k ATC0 -e “send_aid_bidirectional --bus=0 —op_type=BREAK”",parse_str =""},
                Send_GetAuthInfo                                = { cmd = "device -k ATC0 -e “send_aid_bidirectional --bus=0 --data=‘0x90’ --response_len=0x09”",parse_str =""},
                Send_Mogul_SelfTest_Result_CMD                  = { cmd = "device -k ATC0 -e “send_aid_bidirectional --bus=0 --data=‘0xEE 0x02 0x01 0x00 0x00’ --response_len=0x2”",parse_str =""},
                Send_Reset_AID0_line_CMD                        = { cmd = "device -k ATC0 -e “send_aid_bidirectional --bus=0 —op_type=RESET”",parse_str =""},
                Send_ACE_Enter_S0_CMD                           = { cmd = "ace --pick ATC0 --4cc SSPS --txdata 0x00 --rxdata 0;ace --pick ATC0 --4cc SRDY --txdata 0x00 --rxdata 0",parse_str = ""},
                Send_PP5V0_Disable_CMD                          = { cmd = "ace -p ATC0 -c GPIO -t 0x80 0x00 0x00 0x00 0x01 0x84",parse_str = ""},
                Send_Ace_Read_0x6a_CMD                          = { cmd = "ace -r 0x6a",parse_str = ""},
                Send_PP3V3_S2_ACE_PARROT_Voltage_CMD            = { cmd = "ace --pick ATC0 --4cc SSPS --txdata 0x00 --rxdata 0;ace --pick ATC0 --4cc SRDY --txdata 0x00 --rxdata 0",parse_str = ""},
                Send_TypeC_CC_Disable_CMD                       = { cmd = 'ace -p ATC0 -c LDCM -t ""0x08 0x31 0x33 0x44 0x56 0x00 0x10 0x12 0x12 0x02 0xBF 0x0E 0xFF 0xBF 0x04 0xFF 0x14 0x64 0x02 0xA0 0xB0 0x38 0xCC 0x98 0x8C 0xFE 0xFF 0x9C 0xAF 0xFF 0xFF 0x3C 0x2C 0x17 0xF3 0x01 0xE8 0x03 0x22 0xB4 0x0F 0x00 0x00 0x00 0x00 0x1B 0x88 0xA2 0xFC 0x6C 0x00""',parse_str = ""},
                Send_LDCM_Enable_CMD                            = { cmd = "ace --pick ATC0 --4cc LDCM --txdata 0xC0 0x00 0x00 0x00 0x00 ",parse_str = ""},
                Send_PP5V0_Enable_CMD                           = { cmd = "ace -p ATC0 -c GPIO -t 0x80 0x00 0x00 0x00 0x01 0x85",parse_str = ""},
                Send_Ace_leakage_CMD                            = { cmd = 'ace --pick ATC0 --4cc LDCM --txdata ""0x80 0x00 0x00 0x00 0x00"";ace -r 0x6a',parse_str = ""},
                Send_LDCM_Disable_CMD                           = { cmd = "ace --pick ATC0 --4cc LDCM --txdata 0x00 0x00 0x00 0x00 0x00",parse_str = ""},
                Send_PP5V0_Disable_CMD                          = { cmd = "ace -p ATC0 -c GPIO -t 0x80 0x00 0x00 0x00 0x01 0x84",parse_str = ""},
                Send_ACE_reset_CMD                              = { cmd = 'ace --4cc ""GAID""',parse_str = ""},
                Send_Grape_GPIO_Test_CMD                        = { cmd = "ace --pick ATC0 --4cc SSPS --txdata \"0x00\" --rxdata 0;ace --pick ATC0 --4cc SRDY --txdata \"0x00\" --rxdata 0",parse_str = ""},
                Send_PP1V8_S4_Voltage_CMD                       = { cmd = "pmu --readadc all",parse_str = ""},
                Send_Grape_Load_CMD                             = { cmd = "touch --load",parse_str = ""},
                Send_Touch_Properties_CMD                       = { cmd = "touch -p",parse_str = ""},
                Send_FW_Critical_Error_Check_CMD                = { cmd = "touch --test critical --run",parse_str = ""},
                Send_Baku_Test_Mode_Cmd                         = { cmd = "reg select pmu;reg write 0xfe00 0x61 0x45 0x72 0x4f;reg read 0xfe05 1;wait 1",parse_str = ""},
                Send_Juno_check_CMD                             = { cmd = "nandfs:\\AppleInternal\\Diags\\Scripts\\J481\\radios.nsh",parse_str = ""},
                Send_Juno_check_2_CMD                           = { cmd = "bblib -e SE_DumpAClogs()",parse_str = ""},
                Send_WIFI_On_Load_CMD                           = { cmd = "wifi --on --load",parse_str = ""},
                Send_WIFI_Secure_Efuse_CMD                      = { cmd = "wifi --send_cmd sec_efuse",parse_str = ""},
                Check_WIFI_Secure_Efuse_Status                  = { cmd = "wifi --send_cmd get_sec_efuse",parse_str = ""},
                Send_Bluetooth_On_Load_CMD                      = { cmd = "bluetooth --on --load",parse_str = ""},
                Send_SunriseOTP_CMD                             = { cmd = "upy nandfs:\\AppleInternal\\Diags\\Logs\\Smokey\\SunriseOTP\\J481\\main.py -d",parse_str = ""},
                Send_Baku_Select_CMD                            = { cmd = "spmi --select spmi",parse_str = ""},
                Send_SOCHOT1_READ_CMD                           = { cmd = "spmi --read --sid 0xF --addr 0xf901",parse_str = ""},
                Send_SOCHOT1_Off_CMD                            = { cmd = "device -k ThermalSensor -e sochot 1 off",parse_str = ""},
                Send_SOCHOT1_On_CMD                             = { cmd = "device -k ThermalSensor -e sochot 1 on 10",parse_str = ""},



			}

return diags
