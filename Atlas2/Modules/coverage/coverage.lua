return  {
  DisableOrphanedRecordChecking = true,
  Production = {
    conditions = {
      group = {
        {
          generator = {
            func = "product",
            module = "Schooner/DefaultConditionGeneratorAndValidator"
          },
          name = "Product",
          validator = {
            func = "returnTrue",
            module = "Schooner/DefaultConditionGeneratorAndValidator",
            type = "moduleFunction"
          }
        }
      },
      test = {
        {
          name = "SITE",
          validator = {
            allowedList = {
              "APPL",
              "FXLH",
              "FXCD",
              "BYLG",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "otp_program_words_flag",
          validator = {
            allowedList = {
              "OTP_NEED_PROGRAM_CUSTOMER_WORDS",
              "OTP_Already_PROGRAMMED",
              "OTP_DONTNEED_PROGRAM",
              "FAIL",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "otp_customer_Data_size",
          validator = {
            allowedList = {
              "PASS_0",
              "FAIL_Size_Not_0",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "otp_program_keydata_Size",
          validator = {
            allowedList = {
              "OTP_Key_SIZE_0",
              "OTP_Key_SIZE_NOT_0",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "otp_key_Data_flag",
          validator = {
            allowedList = {
              "TRUE",
              "FALSE",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "otp_key_Data_value",
          validator = {
            allowedList = {
              "TRUE",
              "FALSE",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "production_mode",
          validator = {
            allowedList = {
              "1",
              "0",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "otp_check_crc_flag",
          validator = {
            allowedList = {
              "Verify_Ace2_operating_state",
              "Verify_False",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "CFG_type",
          validator = {
            allowedList = {
              "ACE_VERSION_1",
              "ACE_VERSION_2",
              "ACE_VERSION_3",
              "ACE_VERSION_4",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "Project",
          validator = {
            allowedList = {
              "J410",
              "J507",
              "J537",
              "J481",
              "J817",
              "J820",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "SafetyCheck0V8",
          validator = {
            allowedList = {
              "PASS",
              "FAIL"
            },
            type = "IN"
          }
        },
        {
          name = "SafetyCheck1V2",
          validator = {
            allowedList = {
              "PASS",
              "FAIL"
            },
            type = "IN"
          }
        },
        {
          name = "SafetyCheck4V2",
          validator = {
            allowedList = {
              "PASS",
              "FAIL"
            },
            type = "IN"
          }
        },
        {
          name = "testfail",
          validator = {
            allowedList = {
              "TRUE",
              "FALSE"
            },
            type = "IN"
          }
        },
        {
          name = "Poison",
          validator = {
            allowedList = {
              "TRUE",
              "FALSE"
            },
            type = "IN"
          }
        },
        {
          name = "user",
          validator = {
            allowedList = {
              "MFG",
              "DQE",
              "UnSet"
            },
            type = "IN"
          }
        },
        {
          name = "mlb_type",
          validator = {
            allowedList = {
              "MLB_A",
              "MLB_B",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "SoC_CSEC",
          validator = {
            allowedList = {
              "0",
              "1"
            },
            type = "IN"
          }
        },
        {
          name = "I2C_Tag_1",
          validator = {
            allowedList = {
              "23",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "I2C_Tag_2",
          validator = {
            allowedList = {
              "01",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "Wallet_Tag_1",
          validator = {
            allowedList = {
              "01",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "ACE3_Responsive_Status_1",
          validator = {
            allowedList = {
              "TRUE",
              "FALSE",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "ACE3_Responsive_Status_2",
          validator = {
            allowedList = {
              "TRUE",
              "FALSE",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "ACE3_Responsive_Status_3",
          validator = {
            allowedList = {
              "TRUE",
              "FALSE",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "PRODUCTION_SOC",
          validator = {
            allowedList = {
              "0",
              "1",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "accel_selftest_result",
          validator = {
            allowedList = {
              "TRUE",
              "FALSE",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "otp_program_flag",
          validator = {
            allowedList = {
              "OTP_Need_Check_Key_Data_Size",
              "OTP_DONTNEED_PROGRAM",
              "OTP_Need_Check_Key_Data_Size_prod_fuse",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "HAS_TWO_STORAGE_DEVICE",
          validator = {
            allowedList = {
              "number of storage devices 2",
              "FALSE",
              "Unset"
            },
            type = "IN"
          }
        },
        {
          name = "MEMORY_SIZE",
          validator = {
            allowedList = {
              "16GB",
              "12GB",
              "Unset"
            },
            type = "IN"
          }
        }
      }
    },
    limitInfo = {
      conditions = {
      },
      limitPositionInfos = {
      },
      withMode = false,
      withProduct = false,
      withStationType = false
    },
    limits = {
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Get-Channel_ID",
        subtestname = "Channel",
        testname = "Fixture",
        upperLimit = 4
      },
      {
        lowerLimit = 600,
        required = true,
        subsubtestname = "Measure-PPBATT_VCC",
        subtestname = "VoltageCheck_Safety_VBAT0V8",
        testname = "Power",
        units = "mV",
        upperLimit = 1000
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck0V8==\"FAIL\"",
        subsubtestname = "Check-IBAT_OCP_Status",
        subtestname = "VoltageCheck_Safety_VBAT0V8",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck0V8==\"FAIL\"",
        subsubtestname = "Check-VBAT_UVP_Status",
        subtestname = "VoltageCheck_Safety_VBAT0V8",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck0V8==\"FAIL\"",
        subsubtestname = "Check-PPVCC_MAIN_UVP_Status",
        subtestname = "VoltageCheck_Safety_VBAT0V8",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck0V8==\"FAIL\"",
        subsubtestname = "Check-VBAT_OVP_Status",
        subtestname = "VoltageCheck_Safety_VBAT0V8",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 1000,
        required = true,
        subsubtestname = "Measure-PPVBUS_USB_EMI",
        subtestname = "VoltageCheck_Safety_VBUS1V2",
        testname = "Power",
        units = "mV",
        upperLimit = 1300
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck1V2==\"FAIL\"",
        subsubtestname = "Check-VBUS_OCP_Status",
        subtestname = "VoltageCheck_Safety_VBUS1V2",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck1V2==\"FAIL\"",
        subsubtestname = "Check-VBUS_UVP_Status",
        subtestname = "VoltageCheck_Safety_VBUS1V2",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck1V2==\"FAIL\"",
        subsubtestname = "Check-VBUS_OVP_Status",
        subtestname = "VoltageCheck_Safety_VBUS1V2",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 3700,
        required = true,
        subsubtestname = "Measure-PPBATT_VCC",
        subtestname = "VoltageCheck_Safety_VBAT4V2",
        testname = "Power",
        units = "mV",
        upperLimit = 4410
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck4V2==\"PASS\"",
        subsubtestname = "Measure-IBAT",
        subtestname = "VoltageCheck_Safety_VBAT4V2",
        testname = "Power",
        upperLimit = 155
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck4V2==\"FAIL\"",
        subsubtestname = "Check-IBAT_OCP_Status",
        subtestname = "VoltageCheck_Safety_VBAT4V2",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck4V2==\"FAIL\"",
        subsubtestname = "Check-VBAT_UVP_Status",
        subtestname = "VoltageCheck_Safety_VBAT4V2",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck4V2==\"FAIL\"",
        subsubtestname = "Check-PPVCC_MAIN_UVP_Status",
        subtestname = "VoltageCheck_Safety_VBAT4V2",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = "SafetyCheck4V2==\"FAIL\"",
        subsubtestname = "Check-VBAT_OVP_Status",
        subtestname = "VoltageCheck_Safety_VBAT4V2",
        testname = "Power",
        upperLimit = 0
      },
      {
        lowerLimit = 16,
        required = "mlb_type==\"MLB_B\"",
        subsubtestname = "Read-Key_Length",
        subtestname = "Syscfg_WSKU",
        testname = "DUTInfo",
        upperLimit = 16
      },
      {
        lowerLimit = 24,
        required = "mlb_type==\"MLB_B\"",
        subsubtestname = "Read-Key_Length",
        subtestname = "Syscfg_RFEM",
        testname = "DUTInfo",
        upperLimit = 24
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-Test_mode_Abbey",
        subtestname = "UnderVoltageWarning_Abbey",
        testname = "PMU",
        units = "string",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-Abbey_THROTTLE3_L_LOW",
        subtestname = "UnderVoltageWarning_Abbey",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-Abbey_UVWARN_L_LOW",
        subtestname = "UnderVoltageWarning_Abbey",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-Abbey_THROTTLE3_L_HIGH",
        subtestname = "UnderVoltageWarning_Abbey",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-Abbey_UVWARN_L_HIGH",
        subtestname = "UnderVoltageWarning_Abbey",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-Test_mode_Club",
        subtestname = "UnderVoltageWarning_Club",
        testname = "PMU",
        units = "string",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-Club_UVWARN_L_LOW",
        subtestname = "UnderVoltageWarning_Club",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-Club_UVWARN_L_HIGH",
        subtestname = "UnderVoltageWarning_Club",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 0.0001,
        required = true,
        subsubtestname = "Read-ADCMCVBUSVoltage",
        subtestname = "LeakageCheck_PP5V0_To_VBUS",
        testname = "USBC",
        upperLimit = 0.53
      },
      {
        lowerLimit = 0.0001,
        required = true,
        subsubtestname = "Read-ADCMCCC1Voltage",
        subtestname = "LeakageCheck_PP5V0_To_VBUS",
        testname = "USBC",
        upperLimit = 0.15
      },
      {
        lowerLimit = 0.0001,
        required = true,
        subsubtestname = "Read-ADCMCCC2Voltage",
        subtestname = "LeakageCheck_PP5V0_To_VBUS",
        testname = "USBC",
        upperLimit = 0.15
      },
      {
        lowerLimit = 4.5,
        required = "production_mode==\"0\"",
        subsubtestname = "Read-ADCMCPP5V0Voltage",
        subtestname = "LeakageCheck_PP5V0_To_VBUS",
        testname = "USBC",
        upperLimit = 5.5
      },
      {
        lowerLimit = 0.0001,
        required = "production_mode==\"1\"",
        subsubtestname = "Read-ADCMCPP5V0Voltage_Prodfuse",
        subtestname = "LeakageCheck_PP5V0_To_VBUS",
        testname = "USBC",
        upperLimit = 0.53
      },
      {
        lowerLimit = 0.0001,
        required = true,
        subsubtestname = "Read-ADCMCPP5V0Voltage",
        subtestname = "LeakageCheck_VBUS_To_PP5V0",
        testname = "USBC",
        upperLimit = 0.53
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-ADCMCPPCABLEVoltage",
        subtestname = "LeakageCheck_CC1-2_To_PPCABLE-PP5V0",
        testname = "USBC",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-ADCMCVOUTLVVoltage",
        subtestname = "LeakageCheck_VIN_LV_To_VOUT_LV",
        testname = "USBC",
        upperLimit = 0.1
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-VIN_LV_Status",
        subtestname = "LeakageCheck_VIN_LV_To_VOUT_LV",
        testname = "USBC",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-ADCMCVBUSVoltage",
        subtestname = "LeakageCheck_VIN_3V3_To_VBUS",
        testname = "USBC",
        upperLimit = 0.1
      },
      {
        lowerLimit = 3200,
        required = true,
        subsubtestname = "Read-VIN3V3_Voltage",
        subtestname = "LeakageCheck_VIN_3V3_To_VBUS",
        testname = "USBC",
        upperLimit = 3400
      },
      {
        lowerLimit = 4.5,
        required = true,
        subsubtestname = "Read-ADCMCVBUSVoltage",
        subtestname = "LeakageCheck_VBUS_To_PPHV",
        testname = "USBC",
        upperLimit = 5.5
      },
      {
        lowerLimit = 0.0001,
        required = true,
        subsubtestname = "Read-ADCMCPPHVVoltage",
        subtestname = "LeakageCheck_VBUS_To_PPHV",
        testname = "USBC",
        upperLimit = 0.53
      },
      {
        lowerLimit = 0.0001,
        required = true,
        subsubtestname = "Read-ADCMCVBUSVoltage",
        subtestname = "LeakageCheck_PPHV_To_VBUS",
        testname = "USBC",
        upperLimit = 0.5
      },
      {
        lowerLimit = 13000,
        required = true,
        subsubtestname = "Read-PPVBUS_PROT",
        subtestname = "LeakageCheck_PPHV_To_VBUS",
        testname = "USBC",
        upperLimit = 15000
      },
      {
        lowerLimit = 3072,
        required = "accel_selftest_result==\"FALSE\"",
        subsubtestname = "Read-accel_selftest_x_pos",
        subtestname = "SensorData_AccelOnly",
        testname = "Accel",
        upperLimit = 9216
      },
      {
        lowerLimit = 2048,
        required = "accel_selftest_result==\"FALSE\"",
        subsubtestname = "Read-accel_selftest_y_pos",
        subtestname = "SensorData_AccelOnly",
        testname = "Accel",
        upperLimit = 8192
      },
      {
        lowerLimit = 2048,
        required = "accel_selftest_result==\"FALSE\"",
        subsubtestname = "Read-accel_selftest_z_pos",
        subtestname = "SensorData_AccelOnly",
        testname = "Accel",
        upperLimit = 8192
      },
      {
        lowerLimit = 3072,
        required = "accel_selftest_result==\"FALSE\"",
        subsubtestname = "Read-accel_selftest_x_neg",
        subtestname = "SensorData_AccelOnly",
        testname = "Accel",
        upperLimit = 9216
      },
      {
        lowerLimit = 2048,
        required = "accel_selftest_result==\"FALSE\"",
        subsubtestname = "Read-accel_selftest_y_neg",
        subtestname = "SensorData_AccelOnly",
        testname = "Accel",
        upperLimit = 8192
      },
      {
        lowerLimit = 2048,
        required = "accel_selftest_result==\"FALSE\"",
        subsubtestname = "Read-accel_selftest_z_neg",
        subtestname = "SensorData_AccelOnly",
        testname = "Accel",
        upperLimit = 8192
      },
      {
        lowerLimit = 0,
        required = "accel_selftest_result==\"FALSE\"",
        subsubtestname = "Read-accel_selftest_x_symerr",
        subtestname = "SensorData_AccelOnly",
        testname = "Accel",
        upperLimit = 3840
      },
      {
        lowerLimit = 0,
        required = "accel_selftest_result==\"FALSE\"",
        subsubtestname = "Read-accel_selftest_y_symerr",
        subtestname = "SensorData_AccelOnly",
        testname = "Accel",
        upperLimit = 3840
      },
      {
        lowerLimit = 0,
        required = "accel_selftest_result==\"FALSE\"",
        subsubtestname = "Read-accel_selftest_z_symerr",
        subtestname = "SensorData_AccelOnly",
        testname = "Accel",
        upperLimit = 3840
      },
      {
        lowerLimit = -0.118,
        required = true,
        subsubtestname = "Read-accel_only_average_x",
        subtestname = "SensorData_FS8g_ODR100HZ_Zup",
        testname = "Accel",
        units = "g",
        upperLimit = 0.118
      },
      {
        lowerLimit = -0.118,
        required = true,
        subsubtestname = "Read-accel_only_average_y",
        subtestname = "SensorData_FS8g_ODR100HZ_Zup",
        testname = "Accel",
        units = "g",
        upperLimit = 0.118
      },
      {
        lowerLimit = 0.9,
        required = true,
        subsubtestname = "Read-accel_only_average_z",
        subtestname = "SensorData_FS8g_ODR100HZ_Zup",
        testname = "Accel",
        units = "g",
        upperLimit = 1.1
      },
      {
        lowerLimit = 1e-05,
        required = true,
        subsubtestname = "Read-accel_only_std_x",
        subtestname = "SensorData_FS8g_ODR100HZ_Zup",
        testname = "Accel",
        units = "g-rms",
        upperLimit = 0.05
      },
      {
        lowerLimit = 1e-05,
        required = true,
        subsubtestname = "Read-accel_only_std_y",
        subtestname = "SensorData_FS8g_ODR100HZ_Zup",
        testname = "Accel",
        units = "g-rms",
        upperLimit = 0.05
      },
      {
        lowerLimit = 1e-05,
        required = true,
        subsubtestname = "Read-accel_only_std_z",
        subtestname = "SensorData_FS8g_ODR100HZ_Zup",
        testname = "Accel",
        units = "g-rms",
        upperLimit = 0.05
      },
      {
        lowerLimit = 90,
        required = true,
        subsubtestname = "Read-accel_only_odr",
        subtestname = "SensorData_FS8g_ODR100HZ_Zup",
        testname = "Accel",
        units = "Hz",
        upperLimit = 110
      },
      {
        lowerLimit = -0.118,
        required = true,
        subsubtestname = "Read-accel_normal_average_x",
        subtestname = "SensorData_FS8g_ODR200HZ_Zup",
        testname = "IMU",
        units = "g",
        upperLimit = 0.118
      },
      {
        lowerLimit = -0.118,
        required = true,
        subsubtestname = "Read-accel_normal_average_y",
        subtestname = "SensorData_FS8g_ODR200HZ_Zup",
        testname = "IMU",
        units = "g",
        upperLimit = 0.118
      },
      {
        lowerLimit = 0.9,
        required = true,
        subsubtestname = "Read-accel_normal_average_z",
        subtestname = "SensorData_FS8g_ODR200HZ_Zup",
        testname = "IMU",
        units = "g",
        upperLimit = 1.1
      },
      {
        lowerLimit = 1e-05,
        required = true,
        subsubtestname = "Read-accel_normal_std_x",
        subtestname = "SensorData_FS8g_ODR200HZ_Zup",
        testname = "IMU",
        units = "g-rms",
        upperLimit = 0.05
      },
      {
        lowerLimit = 1e-05,
        required = true,
        subsubtestname = "Read-accel_normal_std_y",
        subtestname = "SensorData_FS8g_ODR200HZ_Zup",
        testname = "IMU",
        units = "g-rms",
        upperLimit = 0.05
      },
      {
        lowerLimit = 1e-05,
        required = true,
        subsubtestname = "Read-accel_normal_std_z",
        subtestname = "SensorData_FS8g_ODR200HZ_Zup",
        testname = "IMU",
        units = "g-rms",
        upperLimit = 0.05
      },
      {
        lowerLimit = 180,
        required = true,
        subsubtestname = "Read-accel_normal_odr",
        subtestname = "SensorData_FS8g_ODR200HZ_Zup",
        testname = "IMU",
        units = "Hz",
        upperLimit = 220
      },
      {
        lowerLimit = -25,
        required = true,
        subsubtestname = "Read-gyro_normal_average_x",
        subtestname = "SensorData_FS2000dps_ODR200HZ",
        testname = "IMU",
        units = "dps",
        upperLimit = 25
      },
      {
        lowerLimit = -25,
        required = true,
        subsubtestname = "Read-gyro_normal_average_y",
        subtestname = "SensorData_FS2000dps_ODR200HZ",
        testname = "IMU",
        units = "dps",
        upperLimit = 25
      },
      {
        lowerLimit = -25,
        required = true,
        subsubtestname = "Read-gyro_normal_average_z",
        subtestname = "SensorData_FS2000dps_ODR200HZ",
        testname = "IMU",
        units = "dps",
        upperLimit = 25
      },
      {
        lowerLimit = 3,
        required = true,
        subsubtestname = "Read-gyro_normal_temp",
        subtestname = "SensorData_FS2000dps_ODR200HZ",
        testname = "IMU",
        units = "oC",
        upperLimit = 50
      },
      {
        lowerLimit = 1e-05,
        required = true,
        subsubtestname = "Read-gyro_normal_std_x",
        subtestname = "SensorData_FS2000dps_ODR200HZ",
        testname = "IMU",
        units = "dps-rms",
        upperLimit = 1
      },
      {
        lowerLimit = 1e-05,
        required = true,
        subsubtestname = "Read-gyro_normal_std_y",
        subtestname = "SensorData_FS2000dps_ODR200HZ",
        testname = "IMU",
        units = "dps-rms",
        upperLimit = 1
      },
      {
        lowerLimit = 1e-05,
        required = true,
        subsubtestname = "Read-gyro_normal_std_z",
        subtestname = "SensorData_FS2000dps_ODR200HZ",
        testname = "IMU",
        units = "dps-rms",
        upperLimit = 1
      },
      {
        lowerLimit = 180,
        required = true,
        subsubtestname = "Read-gyro_normal_odr",
        subtestname = "SensorData_FS2000dps_ODR200HZ",
        testname = "IMU",
        units = "Hz",
        upperLimit = 220
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_BB_TO_PMU_HOST_WAKE_L_LOW",
        subtestname = "GPIOCheck_4",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_BB_TO_PMU_HOST_WAKE_L_HIGH",
        subtestname = "GPIOCheck_4",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 40,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_BBPMU_VBUS_DET_LOW",
        subtestname = "GPIOCheck_4",
        testname = "PMU",
        upperLimit = 40
      },
      {
        lowerLimit = 41,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_BBPMU_VBUS_DET_HIGH",
        subtestname = "GPIOCheck_4",
        testname = "PMU",
        upperLimit = 41
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_SOC_TO_DISPLAY_TOUCH_EB_LOW",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_SOC_TO_DISPLAY_TOUCH_EB_HIGH",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_TOUCH_TO_BT_SYNC_LOW",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-WLAN_GPIO_TOUCH_TO_BT_SYNC_LOW",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_TOUCH_TO_BT_SYNC_HIGH",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 1
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-WLAN_GPIO_TOUCH_TO_BT_SYNC_HIGH",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_GRAPE_TO_TCON_FORCE_PWM_1V8_LOW",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_GRAPE_TO_TCON_FORCE_PWM_1V8_HIGH",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_GRAPE_TO_SCORPIUS_TIME_SYNC_1V8_LOW",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_GRAPE_TO_SCORPIUS_TIME_SYNC_1V8_HIGH",
        subtestname = "GPIOCheck_5",
        testname = "Touch",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_POTOMAC_TO_PMU_WAKE_1V8_LOW",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_POTOMAC_TO_PMU_WAKE_1V8_HIGH",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_ROTTERDAM_EN_LOW",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_ROTTERDAM_EN_HIGH",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_SCORPIUS_EXT_DOTARA_EN_1V8_LOW",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_SCORPIUS_EXT_DOTARA_EN_1V8_HIGH",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_NAND_LOW_BATT_L_LOW",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_NAND_LOW_BATT_L_HIGH",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_SCORPIUS_MCU_NRST_L_1V8_LOW",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_SCORPIUS_MCU_NRST_L_1V8_HIGH",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_BBPMU_ON_LOW",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_BBPMU_ON_HIGH",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_WLAN_REG_ON_LOW",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-GPIO_PMU_TO_WLAN_REG_ON_HIGH",
        subtestname = "GPIOCheck_6",
        testname = "PMU",
        upperLimit = 1
      },
      {
        lowerLimit = 219,
        required = true,
        subsubtestname = "Read-Manu_ID",
        subtestname = "Registers",
        testname = "PressureSensor",
        upperLimit = 219
      },
      {
        lowerLimit = 44,
        required = true,
        subsubtestname = "Read-Chip_ID",
        subtestname = "Registers",
        testname = "PressureSensor",
        upperLimit = 44
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-Rev_ID_Mems",
        subtestname = "Registers",
        testname = "PressureSensor",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-Rev_ID_Asic",
        subtestname = "Registers",
        testname = "PressureSensor",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-Package_ID",
        subtestname = "Registers",
        testname = "PressureSensor",
        upperLimit = 1
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-Trim_ID",
        subtestname = "Registers",
        testname = "PressureSensor",
        upperLimit = 1
      },
      {
        lowerLimit = 90,
        required = true,
        subsubtestname = "Read-Press_Average",
        subtestname = "SensorData",
        testname = "PressureSensor",
        units = "kPa",
        upperLimit = 105
      },
      {
        lowerLimit = 0.01,
        required = true,
        subsubtestname = "Read-Press_Std",
        subtestname = "SensorData",
        testname = "PressureSensor",
        units = "Pa.rms",
        upperLimit = 3
      },
      {
        lowerLimit = 25,
        required = true,
        subsubtestname = "Read-ODR",
        subtestname = "SensorData",
        testname = "PressureSensor",
        units = "Hz",
        upperLimit = 35
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-Temp_Average",
        subtestname = "SensorData",
        testname = "PressureSensor",
        units = "oC",
        upperLimit = 65
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-Temp_Std",
        subtestname = "SensorData",
        testname = "PressureSensor",
        units = "oC.rms",
        upperLimit = 0.2
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_EFAIL",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_PFAIL",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_UNC",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_RVFAIL",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_UTIL_EFAIL",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_UTIL_PFAIL",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_UTIL_UNC",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_REFRESH",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_RXBURN_PERF_REFRESH",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_UTIL_REFRESH",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_RXBURN_REL_REFRESH",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-NAND_UNEXPECTED_BLANK",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Check-GBB",
        subtestname = "Info_GBBTest_2",
        testname = "NAND",
        upperLimit = 1
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-9_Smart_media_errors",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-814_Raid_reconstruct_fail_Internal",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-815_Raid_reconstruct_success_Host",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-816_Raid_reconstruct_fail_Host",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-1005_Avg_PE_cycle_over_MLC/TLC_bands",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 75
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-1042_Avg_PE_cycles_over_SLC_bands",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 1000
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-1965_RMX_double_error",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-2083_Number_of_Bad_Boot_Block",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-2125_Number_of_of_die_Failure",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-2180_RAID_Reconstruction_Fail_Sectors",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-2281_turboRaidClassificationReliabilityHost",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-2282_turboRaidClassificationReliabilityInternal",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-2379_Number_of_dip_failures",
        subtestname = "Info_ANS_HealthTest",
        testname = "NAND",
        upperLimit = 0
      },
      {
        lowerLimit = 230,
        required = true,
        subsubtestname = "Read-s6e_lane_0_eh_mv",
        subtestname = "PCIeBIST_AEMToolsS6E",
        testname = "NAND",
        units = "mV"
      },
      {
        lowerLimit = 9.375,
        required = true,
        subsubtestname = "Read-s6e_lane_0_ew_ps",
        subtestname = "PCIeBIST_AEMToolsS6E",
        testname = "NAND",
        units = "ps"
      },
      {
        lowerLimit = 230,
        required = "HAS_TWO_STORAGE_DEVICE == 'number of storage devices 2'",
        subsubtestname = "Read-s6e_lane_1_eh_mv",
        subtestname = "PCIeBIST_AEMToolsS6E",
        testname = "NAND",
        units = "mV"
      },
      {
        lowerLimit = 9.375,
        required = "HAS_TWO_STORAGE_DEVICE == 'number of storage devices 2'",
        subsubtestname = "Read-s6e_lane_1_ew_ps",
        subtestname = "PCIeBIST_AEMToolsS6E",
        testname = "NAND",
        units = "ps"
      },
      {
        lowerLimit = 230,
        required = true,
        subsubtestname = "Read-ans4_lane_0_eh_mv",
        subtestname = "PCIeBIST_AEMToolsANS4",
        testname = "NAND",
        units = "mV"
      },
      {
        lowerLimit = 9.375,
        required = true,
        subsubtestname = "Read-ans4_lane_0_ew_ps",
        subtestname = "PCIeBIST_AEMToolsANS4",
        testname = "NAND",
        units = "ps"
      },
      {
        lowerLimit = 230,
        required = "HAS_TWO_STORAGE_DEVICE == 'number of storage devices 2'",
        subsubtestname = "Read-ans4_lane_1_eh_mv",
        subtestname = "PCIeBIST_AEMToolsANS4",
        testname = "NAND",
        units = "mV"
      },
      {
        lowerLimit = 9.375,
        required = "HAS_TWO_STORAGE_DEVICE == 'number of storage devices 2'",
        subsubtestname = "Read-ans4_lane_1_ew_ps",
        subtestname = "PCIeBIST_AEMToolsANS4",
        testname = "NAND",
        units = "ps"
      },
      {
        lowerLimit = 100,
        required = true,
        subsubtestname = "Read-pcie_0_lane_0_eh_mv",
        subtestname = "Wifi_AEMToolsWifi3nm",
        testname = "RF",
        units = "mV"
      },
      {
        lowerLimit = 37.5,
        required = true,
        subsubtestname = "Read-pcie_0_lane_0_ew_ps",
        subtestname = "Wifi_AEMToolsWifi3nm",
        testname = "RF",
        units = "ps"
      },
      {
        lowerLimit = 100,
        required = true,
        subsubtestname = "Read-pcie_0_r0_lane_0_eh_mv",
        subtestname = "Wifi_AEMToolsWifi3nm",
        testname = "RF",
        units = "mV"
      },
      {
        lowerLimit = 37.5,
        required = true,
        subsubtestname = "Read-pcie_0_r0_lane_0_ew_ps",
        subtestname = "Wifi_AEMToolsWifi3nm",
        testname = "RF",
        units = "ps"
      },
      {
        lowerLimit = 100,
        required = true,
        subsubtestname = "Read-pciesinope_1_lane_0_eh_mv",
        subtestname = "Baseband_AEMToolsSinopeGen4",
        testname = "RF",
        units = "mV"
      },
      {
        lowerLimit = 18.75,
        required = true,
        subsubtestname = "Read-pciesinope_1_lane_0_ew_ps",
        subtestname = "Baseband_AEMToolsSinopeGen4",
        testname = "RF",
        units = "ps"
      },
      {
        lowerLimit = 100,
        required = true,
        subsubtestname = "Read-pcieproxima_0_lane_0_eh_mv",
        subtestname = "Wifi_AEMToolsProxima",
        testname = "RF",
        units = "mV"
      },
      {
        lowerLimit = 37.5,
        required = true,
        subsubtestname = "Read-pcieproxima_0_lane_0_ew_ps",
        subtestname = "Wifi_AEMToolsProxima",
        testname = "RF",
        units = "ps"
      },
      {
        lowerLimit = 100,
        required = "mlb_type==\"MLB_B\"",
        subsubtestname = "Read-baseband_1_lane_0_eh_mv",
        subtestname = "Baseband_AEMToolsBaseband3nm",
        testname = "RF",
        units = "mV"
      },
      {
        lowerLimit = 20,
        required = "mlb_type==\"MLB_B\"",
        subsubtestname = "Read-baseband_1_lane_0_ew_ps",
        subtestname = "Baseband_AEMToolsBaseband3nm",
        testname = "RF",
        units = "ps"
      },
      {
        lowerLimit = 70,
        required = false,
        subsubtestname = "Read-pcie_1_lane_0_eh_mv",
        subtestname = "AEMTools_Baseband_AEMTool_RC3V4",
        testname = "IMU",
        units = "mV",
        upperLimit = 99999
      },
      {
        lowerLimit = 19,
        required = false,
        subsubtestname = "Read-pcie_1_lane_0_ew_ps",
        subtestname = "AEMTools_Baseband_AEMTool_RC3V4",
        testname = "IMU",
        units = "ps",
        upperLimit = 99999
      },
      {
        lowerLimit = 0,
        required = false,
        subsubtestname = "Read-nRows",
        subtestname = "SmokeyTest_TiCC",
        testname = "Touch",
        upperLimit = 255
      },
      {
        lowerLimit = 0,
        required = false,
        subsubtestname = "Read-nCols",
        subtestname = "SmokeyTest_TiCC",
        testname = "Touch",
        upperLimit = 255
      },
      {
        lowerLimit = 0,
        required = false,
        subsubtestname = "Read-Rfb",
        subtestname = "SmokeyTest_TiCC",
        testname = "Touch",
        upperLimit = 255
      },
      {
        lowerLimit = 0,
        required = false,
        subsubtestname = "Read-DMD",
        subtestname = "SmokeyTest_TiCC",
        testname = "Touch",
        upperLimit = 255
      },
      {
        lowerLimit = 0,
        required = false,
        subsubtestname = "Read-HWGain",
        subtestname = "SmokeyTest_TiCC",
        testname = "Touch",
        upperLimit = 255
      },
      {
        lowerLimit = 5000,
        required = false,
        subsubtestname = "Terminal_Delay_Time",
        subtestname = "PresenceCheck",
        testname = "USBC",
        upperLimit = 20000
      },
      {
        lowerLimit = 0,
        required = false,
        subsubtestname = "Terminal_LoopCount",
        subtestname = "PresenceCheck",
        testname = "USBC",
        upperLimit = 200
      },
      {
        lowerLimit = 91,
        required = true,
        subsubtestname = "Read-AuthInfo1_Instant",
        subtestname = "Presencecheck_Mogul",
        testname = "DUTInfo",
        upperLimit = 91
      },
      {
        lowerLimit = 10,
        required = true,
        subsubtestname = "Read-Tp000_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 40,
        required = true,
        subsubtestname = "Read-pmu_TCAL_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV1_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV2_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV3_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV5_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV6_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV8_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK5_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK6_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK8_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK10_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK12_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK15_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_LDO4_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_LDO6_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_LDO15_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW4_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW5_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW6_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW7_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 40,
        required = true,
        subsubtestname = "Read-pmu2_TCAL_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV1_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV3_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV4_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV5_Instant",
        subtestname = "Temperature_1",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 10,
        required = true,
        subsubtestname = "Read-Tp000_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 40,
        required = true,
        subsubtestname = "Read-pmu_TCAL_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV1_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV2_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV3_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV5_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV6_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV8_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK5_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK6_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK8_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK10_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK12_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK15_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_LDO4_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_LDO6_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_LDO15_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW4_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW5_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW6_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW7_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 40,
        required = true,
        subsubtestname = "Read-pmu2_TCAL_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV1_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV3_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV4_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV5_Instant",
        subtestname = "Temperature_2",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 10,
        required = true,
        subsubtestname = "Read-Tp000_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 40,
        required = true,
        subsubtestname = "Read-pmu_TCAL_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV1_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV2_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV3_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV5_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV6_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu_TDEV8_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK5_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK6_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK8_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK10_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK12_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_BUCK15_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_LDO4_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_LDO6_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_LDO15_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW4_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW5_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW6_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDIE_SW7_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 40,
        required = true,
        subsubtestname = "Read-pmu2_TCAL_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV1_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV3_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV4_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 15,
        required = true,
        subsubtestname = "Read-pmu2_TDEV5_Instant",
        subtestname = "Temperature_3",
        testname = "SOC",
        units = "oC",
        upperLimit = 55
      },
      {
        lowerLimit = 0,
        required = true,
        subsubtestname = "Read-ATC0_SW_Disable_Name",
        subtestname = "Info_1",
        testname = "SOC",
        upperLimit = 0
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-ATC1_SW_Disable_Name",
        subtestname = "Info_1",
        testname = "SOC",
        upperLimit = 1
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-ATC2_SW_Disable_Name",
        subtestname = "Info_1",
        testname = "SOC",
        upperLimit = 1
      },
      {
        lowerLimit = 1,
        required = true,
        subsubtestname = "Read-ATC3_SW_Disable_Name",
        subtestname = "Info_1",
        testname = "SOC",
        upperLimit = 1
      }
    },
    mainActions = {
      {
        filename = "Tech/Fixture/Channel.csv",
        name = "RunChannel",
        testIdx = 1
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Init/Init.csv",
        name = "RunInitialize",
        plugins = {
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand",
          "StationInfo"
        },
        testConditions = {
          ACE3_Responsive_Status_1 = {
            returnIdx = 12
          },
          ACE3_Responsive_Status_2 = {
            returnIdx = 13
          },
          ACE3_Responsive_Status_3 = {
            returnIdx = 14
          },
          PRODUCTION_SOC = {
            returnIdx = 15
          },
          SITE = {
            returnIdx = 1
          },
          accel_selftest_result = {
            returnIdx = 18
          }
        },
        testIdx = 2
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Fixture/SoftwareCheck.csv",
        name = "RunSoftwareCheck",
        plugins = {
          "FixturePlugin",
          "StationInfo"
        },
        testConditions = {
          Project = {
            returnIdx = 2
          },
          user = {
            returnIdx = 1
          }
        },
        testIdx = 3
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Fixture/HardwareCheck.csv",
        name = "RunHardwareCheck",
        plugins = {
          "FixturePlugin",
          "StationInfo"
        },
        testIdx = 4
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Fixture/GeneralAction_Reset_Initial.csv",
        name = "RunGeneralAction_Reset_Initial",
        plugins = {
          "FixturePlugin"
        },
        testIdx = 5
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Fixture/GeneralAction_Led_Inprogress_On.csv",
        name = "RunGeneralAction_Led_Inprogress_On",
        plugins = {
          "FixturePlugin"
        },
        testIdx = 6
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/Discharge_Initial.csv",
        name = "RunDischarge_Initial",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testIdx = 7
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/VoltageCheck_Safety_VBAT0V8.csv",
        name = "RunVoltageCheck_Safety_VBAT0V8",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testConditions = {
          SafetyCheck0V8 = {
            returnIdx = 1
          }
        },
        testIdx = 8
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/VoltageCheck_Safety_VBUS1V2.csv",
        name = "RunVoltageCheck_Safety_VBUS1V2",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testConditions = {
          SafetyCheck1V2 = {
            returnIdx = 1
          }
        },
        testIdx = 9
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/VoltageCheck_Safety_VBAT4V2.csv",
        name = "RunVoltageCheck_Safety_VBAT4V2",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testConditions = {
          SafetyCheck4V2 = {
            returnIdx = 1
          }
        },
        testIdx = 10
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/On_Seq_OTP.csv",
        name = "RunOn_Seq_OTP",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testIdx = 11
      },
      {
        args = {
          {
            action = {
              actionIdx = 2,
              returnIdx = 2
            }
          },
          {
            action = {
              actionIdx = 3,
              returnIdx = 2
            }
          },
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/USBC/OTPProgram.csv",
        name = "RunOTPProgram",
        plugins = {
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testConditions = {
          mlb_type = {
            returnIdx = 2
          }
        },
        testIdx = 12
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/Discharge_Initial_OTP.csv",
        name = "RunDischarge_Initial_OTP",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testIdx = 13
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/On_Seq_FWDL.csv",
        name = "RunOn_Seq_FWDL",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testIdx = 14
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 11
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 9
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 7
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 12
            }
          },
          {
            action = {
              actionIdx = 3,
              returnIdx = 2
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 4
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 16
            }
          },
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/USBC/FWDL_ACEFlash_SPI.csv",
        name = "RunFWDL_ACEFlash_SPI",
        plugins = {
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Utilities"
        },
        testIdx = 15
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/Discharge_Initial_FWDL.csv",
        name = "RunDischarge_Initial_FWDL",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testIdx = 16
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/On_Seq_Restore.csv",
        name = "RunOn_Seq_Restore",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testIdx = 17
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 9
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 10
            }
          },
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/USBC/Info_ACE3_FWVersion.csv",
        name = "RunInfo_ACE3_FWVersion",
        plugins = {
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 18
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/SOC/Restore_DFUMode.csv",
        name = "RunRestore_DFUMode",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "SFC",
          "Regex",
          "Utilities",
          "DCSD",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 19
      },
      {
        args = {
          {
            action = {
              actionIdx = 19,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/SOC/Restore_NonUI_DCSD_1.csv",
        name = "RunRestore_NonUI_DCSD_1",
        plugins = {
          "DCSD",
          "VariableTable"
        },
        testIdx = 20
      },
      {
        filename = "Tech/SOC/Restore_NonUI_DCSD_2.csv",
        name = "RunRestore_NonUI_DCSD_2",
        plugins = {
          "Kis_dut",
          "FixturePlugin",
          "InteractiveView",
          "VariableTable"
        },
        testIdx = 21
      },
      {
        args = {
          {
            action = {
              actionIdx = 21,
              returnIdx = 1
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 2
            }
          }
        },
        filename = "Tech/SOC/Restore_NonUI_DCSD_4.csv",
        name = "RunRestore_NonUI_DCSD_4",
        plugins = {
          "RunShellCommand"
        },
        testIdx = 22
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/Discharge_Initial_Restore.csv",
        name = "RunDischarge_Initial_Restore",
        plugins = {
          "FixturePlugin",
          "RunShellCommand"
        },
        testIdx = 23
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/On_Seq_Diags.csv",
        name = "RunOn_Seq_Diags",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "RunShellCommand",
          "Regex",
          "SFC",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 24
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Process/Transition_Diags_1.csv",
        name = "RunTransition_Diags_1",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "InteractiveView",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Utilities"
        },
        testIdx = 25
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 5
            }
          }
        },
        filename = "Tech/DUTInfo/BoardRevision.csv",
        name = "RunBoardRevision",
        plugins = {
          "Dut",
          "ChannelPlugin",
          "Kis_dut",
          "Kis_channelPlugin",
          "FixturePlugin",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 26
      },
      {
        filename = "Tech/SOC/Temperature_1.csv",
        name = "RunTemperature_1",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "SFC",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 27
      },
      {
        filename = "Tech/DUTInfo/DiagsFW_Version.csv",
        name = "RunDiagsFW_Version",
        plugins = {
          "Dut",
          "ChannelPlugin",
          "Kis_dut",
          "Kis_channelPlugin",
          "FixturePlugin",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "RunShellCommand"
        },
        testIdx = 28
      },
      {
        filename = "Tech/Process/CB_Init.csv",
        name = "RunCB_Init",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 29
      },
      {
        filename = "Tech/DUTInfo/Syscfg.csv",
        name = "RunSyscfg",
        plugins = {
          "Dut",
          "ChannelPlugin",
          "Kis_dut",
          "Kis_channelPlugin",
          "FixturePlugin",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 30
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 6
            }
          }
        },
        filename = "Tech/SOC/Info_SBIN.csv",
        name = "RunInfo_SBIN",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "RunShellCommand",
          "Mutex",
          "SystemTool"
        },
        testConditions = {
          MEMORY_SIZE = {
            returnIdx = 3
          }
        },
        testIdx = 31
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 3
            }
          }
        },
        filename = "Tech/USBC/FWDL_ACE.csv",
        name = "RunFWDL_ACE",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 32
      },
      {
        filename = "Tech/USBC/Info_RT13.csv",
        name = "RunInfo_RT13",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 33
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 18
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 19
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 20
            }
          }
        },
        filename = "Tech/DUTInfo/DiagsFW_CRC_Check.csv",
        name = "RunDiagsFW_CRC_Check",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 34
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/SOC/Temperature.csv",
        name = "RunTemperature",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "RunShellCommand",
          "FixturePlugin"
        },
        testIdx = 35
      },
      {
        filename = "Tech/DUTInfo/Syscfg_List_1.csv",
        name = "RunSyscfg_List_1",
        plugins = {
          "Dut",
          "ChannelPlugin",
          "Kis_dut",
          "Kis_channelPlugin",
          "FixturePlugin",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 36
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Process/Transition_RTOS_1.csv",
        name = "RunTransition_RTOS_1",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 37
      },
      {
        filename = "Tech/DUTInfo/RTOSFW.csv",
        name = "RunRTOSFW",
        plugins = {
          "Dut",
          "ChannelPlugin",
          "Kis_dut",
          "Kis_channelPlugin",
          "FixturePlugin",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "RunShellCommand",
          "Runtest"
        },
        testIdx = 38
      },
      {
        args = {
          {
            action = {
              actionIdx = 38,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Process/Transition_RTOS_2.csv",
        name = "RunTransition_RTOS_2",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 39
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Process/Transition_RBM_1.csv",
        name = "RunTransition_RBM_1",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Utilities"
        },
        testIdx = 40
      },
      {
        filename = "Tech/DUTInfo/RBMFW.csv",
        name = "RunRBMFW",
        plugins = {
          "Dut",
          "ChannelPlugin",
          "Kis_dut",
          "Kis_channelPlugin",
          "FixturePlugin",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "RunShellCommand",
          "Runtest"
        },
        testIdx = 41
      },
      {
        args = {
          {
            action = {
              actionIdx = 41,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Process/Transition_RBM_2.csv",
        name = "RunTransition_RBM_2",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin"
        },
        testIdx = 42
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Process/Reset_Diags.csv",
        name = "RunReset_Diags",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Utilities"
        },
        testIdx = 43
      },
      {
        filename = "Tech/Process/Transition_Diags_2.csv",
        name = "RunTransition_Diags_2",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Utilities"
        },
        testIdx = 44
      },
      {
        args = {
          {
            action = {
              actionIdx = 2,
              returnIdx = 2
            }
          }
        },
        filename = "Tech/DUTInfo/Syscfg_MLBSN.csv",
        name = "RunSyscfg_MLBSN",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 45
      },
      {
        args = {
          {
            action = {
              actionIdx = 2,
              returnIdx = 2
            }
          }
        },
        filename = "Tech/DUTInfo/Syscfg_MLBCFG.csv",
        name = "RunSyscfg_MLBCFG",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 46
      },
      {
        args = {
          {
            action = {
              actionIdx = 2,
              returnIdx = 2
            }
          },
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          },
          {
            action = {
              actionIdx = 2,
              returnIdx = 1
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 5
            }
          },
          {
            action = {
              actionIdx = 31,
              returnIdx = 3
            }
          }
        },
        filename = "Tech/SOC/Info_1.csv",
        name = "RunInfo_1",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "StationInfo",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand",
          "Mutex"
        },
        testConditions = {
          HAS_TWO_STORAGE_DEVICE = {
            returnIdx = 3
          },
          production_mode = {
            returnIdx = 12
          }
        },
        testIdx = 47
      },
      {
        filename = "Tech/DUTInfo/Presencecheck_Mogul.csv",
        name = "RunPresencecheck_Mogul",
        plugins = {
          "Dut",
          "ChannelPlugin",
          "Kis_dut",
          "Kis_channelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 48
      },
      {
        filename = "Tech/PMU/UnderVoltageWarning_Abbey.csv",
        name = "RunUnderVoltageWarning_Abbey",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 49
      },
      {
        filename = "Tech/PMU/UnderVoltageWarning_Club.csv",
        name = "RunUnderVoltageWarning_Club",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 50
      },
      {
        args = {
          {
            action = {
              actionIdx = 47,
              returnIdx = 1
            }
          },
          {
            action = {
              actionIdx = 2,
              returnIdx = 2
            }
          },
          {
            action = {
              actionIdx = 12,
              returnIdx = 23
            }
          },
          {
            action = {
              actionIdx = 31,
              returnIdx = 3
            }
          },
          {
            action = {
              actionIdx = 31,
              returnIdx = 6
            }
          },
          {
            action = {
              actionIdx = 31,
              returnIdx = 5
            }
          },
          {
            action = {
              actionIdx = 47,
              returnIdx = 11
            }
          }
        },
        filename = "Tech/NAND/Info_2.csv",
        name = "RunInfo_2",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand",
          "Mutex"
        },
        testIdx = 51
      },
      {
        filename = "Tech/NAND/Info_GBBTest_1.csv",
        name = "RunInfo_GBBTest_1",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 52
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Speaker/Reset.csv",
        name = "RunReset",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "SFC",
          "Regex",
          "Utilities",
          "DCSD",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 53
      },
      {
        filename = "Tech/SOC/Info_SEP.csv",
        name = "RunInfo_SEP",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 54
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/USBC/LeakageCheck_VBUS_To_PP5V0.csv",
        name = "RunLeakageCheck_VBUS_To_PP5V0",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Mutex"
        },
        testIdx = 55
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/USBC/LeakageCheck_VBUS_To_PPHV.csv",
        name = "RunLeakageCheck_VBUS_To_PPHV",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Mutex"
        },
        testIdx = 56
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/USBC/LeakageCheck_VIN_3V3_To_VBUS.csv",
        name = "RunLeakageCheck_VIN_3V3_To_VBUS",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Mutex"
        },
        testIdx = 57
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/USBC/LeakageCheck_VIN_LV_To_VOUT_LV.csv",
        name = "RunLeakageCheck_VIN_LV_To_VOUT_LV",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Mutex"
        },
        testIdx = 58
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          },
          {
            condition = "PRODUCTION_SOC"
          }
        },
        filename = "Tech/USBC/LeakageCheck_CC1-2_To_PPCABLE-PP5V0.csv",
        name = "RunLeakageCheck_CC1-2_To_PPCABLE-PP5V0",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Mutex"
        },
        testIdx = 59
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          },
          {
            action = {
              actionIdx = 47,
              returnIdx = 12
            }
          }
        },
        filename = "Tech/USBC/LeakageCheck_PP5V0_To_VBUS.csv",
        name = "RunLeakageCheck_PP5V0_To_VBUS",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Mutex"
        },
        testIdx = 60
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/USBC/LeakageCheck_PPHV_To_VBUS.csv",
        name = "RunLeakageCheck_PPHV_To_VBUS",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin",
          "Mutex"
        },
        testIdx = 61
      },
      {
        args = {
          {
            action = {
              actionIdx = 47,
              returnIdx = 3
            }
          }
        },
        filename = "Tech/NAND/PCIeBIST_AEMToolsS6E.csv",
        name = "RunPCIeBIST_AEMToolsS6E",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 62
      },
      {
        args = {
          {
            action = {
              actionIdx = 47,
              returnIdx = 3
            }
          }
        },
        filename = "Tech/NAND/PCIeBIST_AEMToolsANS4.csv",
        name = "RunPCIeBIST_AEMToolsANS4",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "RunShellCommand"
        },
        testIdx = 63
      },
      {
        filename = "Tech/RF/Wifi_AEMToolsWifi3nm.csv",
        name = "RunWifi_AEMToolsWifi3nm",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 64
      },
      {
        filename = "Tech/RF/Baseband_AEMToolsBaseband3nm.csv",
        name = "RunBaseband_AEMToolsBaseband3nm",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 65
      },
      {
        filename = "Tech/RF/Wifi_AEMToolsProxima.csv",
        name = "RunWifi_AEMToolsProxima",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 66
      },
      {
        filename = "Tech/RF/Baseband_AEMToolsSinopeGen4.csv",
        name = "RunBaseband_AEMToolsSinopeGen4",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 67
      },
      {
        filename = "Tech/RF/Baseband.csv",
        name = "RunBaseband",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "DCSD",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 68
      },
      {
        filename = "Tech/RF/WIFI_BT.csv",
        name = "RunWIFI_BT",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "DCSD",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 69
      },
      {
        filename = "Tech/RF/NFC.csv",
        name = "RunNFC",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "DCSD",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 70
      },
      {
        filename = "Tech/DUTInfo/Syscfg_Mac.csv",
        name = "RunSyscfg_Mac",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "SFC",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 71
      },
      {
        filename = "Tech/Touch/SmokeyTest_TouchShorts.csv",
        name = "RunSmokeyTest_TouchShorts",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 72
      },
      {
        filename = "Tech/Touch/SmokeyTest_TouchTiCC.csv",
        name = "RunSmokeyTest_TouchTiCC",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 73
      },
      {
        filename = "Tech/Touch/SmokeyTest_TouchGeneralTest.csv",
        name = "RunSmokeyTest_TouchGeneralTest",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 74
      },
      {
        filename = "Tech/Touch/SmokeyTest_TouchGPIOTest.csv",
        name = "RunSmokeyTest_TouchGPIOTest",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 75
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 2
            }
          }
        },
        filename = "Tech/PMU/GPIOCheck_4.csv",
        name = "RunGPIOCheck_4",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 76
      },
      {
        filename = "Tech/Touch/GPIOCheck_5.csv",
        name = "RunGPIOCheck_5",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 77
      },
      {
        args = {
          {
            action = {
              actionIdx = 12,
              returnIdx = 2
            }
          }
        },
        filename = "Tech/PMU/GPIOCheck_6.csv",
        name = "RunGPIOCheck_6",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 78
      },
      {
        filename = "Tech/RF/SmokeyTest_WDFU.csv",
        name = "RunSmokeyTest_WDFU",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "DCSD",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 79
      },
      {
        filename = "Tech/SOC/Temperature_2.csv",
        name = "RunTemperature_2",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "RunShellCommand"
        },
        testIdx = 80
      },
      {
        filename = "Tech/Accel/SensorData_VendorInfor.csv",
        name = "RunSensorData_VendorInfor",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 81
      },
      {
        filename = "Tech/Accel/SensorData_AccelOnly.csv",
        name = "RunSensorData_AccelOnly",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 82
      },
      {
        args = {
          {
            action = {
              actionIdx = 82,
              returnIdx = 3
            }
          }
        },
        filename = "Tech/Accel/SensorData_FS8g_ODR100HZ_Zup.csv",
        name = "RunSensorData_FS8g_ODR100HZ_Zup",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 83
      },
      {
        filename = "Tech/IMU/SensorData_GyroNormal.csv",
        name = "RunSensorData_GyroNormal",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 84
      },
      {
        args = {
          {
            action = {
              actionIdx = 84,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/IMU/SensorData_IDInfor.csv",
        name = "RunSensorData_IDInfor",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 85
      },
      {
        args = {
          {
            action = {
              actionIdx = 84,
              returnIdx = 2
            }
          }
        },
        filename = "Tech/IMU/SensorData_FS8g_ODR200HZ_Zup.csv",
        name = "RunSensorData_FS8g_ODR200HZ_Zup",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 86
      },
      {
        args = {
          {
            action = {
              actionIdx = 84,
              returnIdx = 2
            }
          }
        },
        filename = "Tech/IMU/SensorData_FS2000dps_ODR200HZ.csv",
        name = "RunSensorData_FS2000dps_ODR200HZ",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 87
      },
      {
        filename = "Tech/PressureSensor/Registers.csv",
        name = "RunRegisters",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 88
      },
      {
        filename = "Tech/PressureSensor/SensorData.csv",
        name = "RunSensorData",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 89
      },
      {
        filename = "Tech/NAND/Info_GBBTest_2.csv",
        name = "RunInfo_GBBTest_2",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand",
          "Mutex"
        },
        testIdx = 90
      },
      {
        args = {
          {
            action = {
              actionIdx = 90,
              returnIdx = 1
            }
          }
        },
        filename = "Tech/NAND/Info_ANS_HealthTest.csv",
        name = "RunInfo_ANS_HealthTest",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "Regex",
          "Utilities",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "FixturePlugin",
          "InteractiveView",
          "RunShellCommand"
        },
        testIdx = 91
      },
      {
        filename = "Tech/DUTInfo/Syscfg_List_2.csv",
        name = "RunSyscfg_List_2",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "FixturePlugin",
          "InteractiveView",
          "Regex",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 92
      },
      {
        filename = "Tech/SOC/Temperature_3.csv",
        name = "RunTemperature_3",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "PListSerializationPlugin",
          "SMTCommonPlugin",
          "FileOperation",
          "VariableTable",
          "TimeUtility",
          "RunShellCommand"
        },
        testIdx = 93
      },
      {
        filename = "Tech/USBC/Info_AceTRNG.csv",
        name = "RunInfo_AceTRNG",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 94
      },
      {
        filename = "Tech/USBC/ForceDFU_ADFU.csv",
        name = "RunForceDFU_ADFU",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "FileOperation",
          "FixturePlugin",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 95
      },
      {
        filename = "Tech/USBC/Info_ECID.csv",
        name = "RunInfo_ECID",
        plugins = {
          "Kis_dut",
          "Kis_channelPlugin",
          "SFC",
          "Regex",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin",
          "PListSerializationPlugin"
        },
        testIdx = 96
      }
    },
    mainTests = {
      {
        Conditions = "",
        Coverage = "Channel",
        SamplingGroup = "",
        Technology = "Fixture",
        TestParameters = "",
        actions = {
          1
        },
        fullName = "Fixture Channel",
        outputs = {
          slotNum = {
            actionIdx = 1,
            actionName = "RunChannel",
            returnIdx = 1
          }
        },
        subTestName = "Channel",
        testName = "Fixture"
      },
      {
        Conditions = "",
        Coverage = "Initialize",
        SamplingGroup = "",
        Technology = "Fixture",
        TestParameters = "",
        actions = {
          2
        },
        deps = {
          1
        },
        fullName = "Fixture Initialize",
        outputs = {
          ACE3_Responsive_Status_1 = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 12
          },
          ACE3_Responsive_Status_2 = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 13
          },
          ACE3_Responsive_Status_3 = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 14
          },
          CFG_type = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 10
          },
          HAS_TWO_STORAGE_DEVICE = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 19
          },
          MEMORY_SIZE = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 20
          },
          MLB_Num = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 2
          },
          PRODUCTION_SOC = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 15
          },
          Production_Mode_SFC = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 16
          },
          Project = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 11
          },
          SITE = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 1
          },
          accel_selftest_result = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 18
          },
          otp_check_crc_flag = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 9
          },
          otp_customer_Data_size = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 4
          },
          otp_key_Data_flag = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 6
          },
          otp_key_Data_value = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 7
          },
          otp_program_flag = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 17
          },
          otp_program_keydata_Size = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 5
          },
          otp_program_words_flag = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 3
          },
          production_mode = {
            actionIdx = 2,
            actionName = "RunInitialize",
            returnIdx = 8
          }
        },
        subTestName = "Initialize",
        testName = "Fixture"
      },
      {
        Conditions = "",
        Coverage = "SoftwareCheck",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Fixture",
        TestParameters = "",
        actions = {
          3
        },
        deps = {
          1,
          2
        },
        fullName = "Fixture SoftwareCheck",
        outputs = {
          Project = {
            actionIdx = 3,
            actionName = "RunSoftwareCheck",
            returnIdx = 2
          },
          user = {
            actionIdx = 3,
            actionName = "RunSoftwareCheck",
            returnIdx = 1
          }
        },
        subTestName = "SoftwareCheck",
        testName = "Fixture"
      },
      {
        Conditions = "",
        Coverage = "HardwareCheck",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Fixture",
        TestParameters = "",
        actions = {
          4
        },
        deps = {
          1,
          3
        },
        fullName = "Fixture HardwareCheck",
        outputs = {
          fixtureID = {
            actionIdx = 4,
            actionName = "RunHardwareCheck",
            returnIdx = 1
          }
        },
        subTestName = "HardwareCheck",
        testName = "Fixture"
      },
      {
        Conditions = "",
        Coverage = "GeneralAction",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Fixture",
        TestParameters = "Reset_Initial",
        actions = {
          5
        },
        deps = {
          1,
          4
        },
        fullName = "Fixture GeneralAction_Reset_Initial",
        subTestName = "GeneralAction_Reset_Initial",
        testName = "Fixture"
      },
      {
        Conditions = "",
        Coverage = "GeneralAction",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Fixture",
        TestParameters = "Led_Inprogress_On",
        actions = {
          6
        },
        deps = {
          1,
          5
        },
        fullName = "Fixture GeneralAction_Led_Inprogress_On",
        subTestName = "GeneralAction_Led_Inprogress_On",
        testName = "Fixture"
      },
      {
        Conditions = "",
        Coverage = "Discharge",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Power",
        TestParameters = "Initial",
        actions = {
          7
        },
        deps = {
          1,
          6
        },
        fullName = "Power Discharge_Initial",
        subTestName = "Discharge_Initial",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "VoltageCheck",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Power",
        TestParameters = "Safety_VBAT0V8",
        actions = {
          8
        },
        deps = {
          1,
          7
        },
        fullName = "Power VoltageCheck_Safety_VBAT0V8",
        subTestName = "VoltageCheck_Safety_VBAT0V8",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "VoltageCheck",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Power",
        TestParameters = "Safety_VBUS1V2",
        actions = {
          9
        },
        deps = {
          1,
          8
        },
        fullName = "Power VoltageCheck_Safety_VBUS1V2",
        subTestName = "VoltageCheck_Safety_VBUS1V2",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "VoltageCheck",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Power",
        TestParameters = "Safety_VBAT4V2",
        actions = {
          10
        },
        deps = {
          1,
          9
        },
        fullName = "Power VoltageCheck_Safety_VBAT4V2",
        subTestName = "VoltageCheck_Safety_VBAT4V2",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "On_Seq",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Power",
        TestParameters = "OTP",
        actions = {
          11
        },
        deps = {
          1,
          10
        },
        fullName = "Power On_Seq_OTP",
        subTestName = "On_Seq_OTP",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "OTPProgram",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "",
        actions = {
          12
        },
        deps = {
          1,
          2,
          3,
          11
        },
        fullName = "USBC OTPProgram",
        outputs = {
          Ace3LUN = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 16
          },
          Ace3LogPath = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 10
          },
          Ace3_CRC1_I2C = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 18
          },
          Ace3_CRC2_I2C = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 19
          },
          Ace3_CRC3_I2C = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 20
          },
          Ace3_ECID = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 21
          },
          Ace3_PREV = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 11
          },
          CFG_type = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 3
          },
          DUT_stage = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 4
          },
          Location_ID = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 1
          },
          SoC_CPRO = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 17
          },
          SoC_CSEC = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 12
          },
          boardRev = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 5
          },
          dataI2CBus = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 15
          },
          deviceAddress = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 9
          },
          dut_cfg = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 6
          },
          isProgramming = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 22
          },
          matchingRecord4CC = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 14
          },
          matchingRelationship = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 13
          },
          mlb_type = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 2
          },
          payloadFilepath = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 8
          },
          sfc_url = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 23
          },
          superBinaryFolder = {
            actionIdx = 12,
            actionName = "RunOTPProgram",
            returnIdx = 7
          }
        },
        subTestName = "OTPProgram",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "Discharge",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Power",
        TestParameters = "Initial_OTP",
        actions = {
          13
        },
        deps = {
          1,
          12
        },
        fullName = "Power Discharge_Initial_OTP",
        subTestName = "Discharge_Initial_OTP",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "On_Seq",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Power",
        TestParameters = "FWDL",
        actions = {
          14
        },
        deps = {
          1,
          13
        },
        fullName = "Power On_Seq_FWDL",
        subTestName = "On_Seq_FWDL",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "FWDL_ACEFlash_SPI",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "USBC",
        TestParameters = "",
        actions = {
          15
        },
        deps = {
          1,
          3,
          12,
          14
        },
        fullName = "USBC FWDL_ACEFlash_SPI",
        outputs = {
          binSize = {
            actionIdx = 15,
            actionName = "RunFWDL_ACEFlash_SPI",
            returnIdx = 2
          },
          hostMD5 = {
            actionIdx = 15,
            actionName = "RunFWDL_ACEFlash_SPI",
            returnIdx = 1
          }
        },
        subTestName = "FWDL_ACEFlash_SPI",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "Discharge",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Power",
        TestParameters = "Initial_FWDL",
        actions = {
          16
        },
        deps = {
          1,
          15
        },
        fullName = "Power Discharge_Initial_FWDL",
        subTestName = "Discharge_Initial_FWDL",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "On_Seq",
        SamplingGroup = "",
        Technology = "Power",
        TestParameters = "Restore",
        actions = {
          17
        },
        deps = {
          1,
          16
        },
        fullName = "Power On_Seq_Restore",
        subTestName = "On_Seq_Restore",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "Info_ACE3_FWVersion",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "USBC",
        TestParameters = "",
        actions = {
          18
        },
        deps = {
          1,
          12,
          17
        },
        fullName = "USBC Info_ACE3_FWVersion",
        outputs = {
          Ace3FWVersion = {
            actionIdx = 18,
            actionName = "RunInfo_ACE3_FWVersion",
            returnIdx = 1
          }
        },
        subTestName = "Info_ACE3_FWVersion",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "Restore_DFUMode",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "SOC",
        TestParameters = "",
        actions = {
          19
        },
        deps = {
          1,
          18
        },
        fullName = "SOC Restore_DFUMode",
        outputs = {
          Location_ID = {
            actionIdx = 19,
            actionName = "RunRestore_DFUMode",
            returnIdx = 1
          }
        },
        subTestName = "Restore_DFUMode",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "Restore_NonUI_DCSD_1",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "SOC",
        TestParameters = "",
        actions = {
          20
        },
        deps = {
          19,
          19
        },
        fullName = "SOC Restore_NonUI_DCSD_1",
        subTestName = "Restore_NonUI_DCSD_1",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "Restore_NonUI_DCSD_2",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "SOC",
        TestParameters = "",
        actions = {
          21
        },
        deps = {
          19
        },
        fullName = "SOC Restore_NonUI_DCSD_2",
        outputs = {
          restore_uart_log = {
            actionIdx = 21,
            actionName = "RunRestore_NonUI_DCSD_2",
            returnIdx = 1
          }
        },
        subTestName = "Restore_NonUI_DCSD_2",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "Restore_NonUI_DCSD_4",
        SamplingGroup = "",
        Technology = "SOC",
        TestParameters = "",
        actions = {
          22
        },
        deps = {
          12,
          20,
          21,
          21
        },
        fullName = "SOC Restore_NonUI_DCSD_4",
        outputs = {
          LCRT = {
            actionIdx = 22,
            actionName = "RunRestore_NonUI_DCSD_4",
            returnIdx = 1
          },
          SIK = {
            actionIdx = 22,
            actionName = "RunRestore_NonUI_DCSD_4",
            returnIdx = 2
          }
        },
        subTestName = "Restore_NonUI_DCSD_4",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "Discharge",
        SamplingGroup = "",
        Technology = "Power",
        TestParameters = "Initial_Restore",
        actions = {
          23
        },
        deps = {
          1,
          22
        },
        fullName = "Power Discharge_Initial_Restore",
        subTestName = "Discharge_Initial_Restore",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "On_Seq",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Power",
        TestParameters = "Diags",
        actions = {
          24
        },
        deps = {
          1,
          23
        },
        fullName = "Power On_Seq_Diags",
        subTestName = "On_Seq_Diags",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "Transition_Diags_1",
        SamplingGroup = "",
        StopOnFail = true,
        Technology = "Process",
        TestParameters = "",
        actions = {
          25
        },
        deps = {
          12,
          24
        },
        fullName = "Process Transition_Diags_1",
        subTestName = "Transition_Diags_1",
        testName = "Process"
      },
      {
        Conditions = "",
        Coverage = "BoardRevision",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          26
        },
        deps = {
          12,
          25
        },
        fullName = "DUTInfo BoardRevision",
        outputs = {
          Board_REV_Compare = {
            actionIdx = 26,
            actionName = "RunBoardRevision",
            returnIdx = 1
          }
        },
        subTestName = "BoardRevision",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "Temperature_1",
        SamplingGroup = "",
        Technology = "SOC",
        TestParameters = "",
        actions = {
          27
        },
        deps = {
          26
        },
        fullName = "SOC Temperature_1",
        outputs = {
          THERMAL0_Instant = {
            actionIdx = 27,
            actionName = "RunTemperature_1",
            returnIdx = 1
          },
          tem_value = {
            actionIdx = 27,
            actionName = "RunTemperature_1",
            returnIdx = 2
          }
        },
        subTestName = "Temperature_1",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "DiagsFW_Version",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          28
        },
        deps = {
          27
        },
        fullName = "DUTInfo DiagsFW_Version",
        outputs = {
          Diags_version = {
            actionIdx = 28,
            actionName = "RunDiagsFW_Version",
            returnIdx = 1
          },
          Version_Info = {
            actionIdx = 28,
            actionName = "RunDiagsFW_Version",
            returnIdx = 2
          }
        },
        subTestName = "DiagsFW_Version",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "CB_Init",
        SamplingGroup = "",
        Technology = "Process",
        TestParameters = "",
        actions = {
          29
        },
        deps = {
          28
        },
        fullName = "Process CB_Init",
        subTestName = "CB_Init",
        testName = "Process"
      },
      {
        Conditions = "",
        Coverage = "Syscfg",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          30
        },
        deps = {
          29
        },
        fullName = "DUTInfo Syscfg",
        subTestName = "Syscfg",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "Info_SBIN",
        SamplingGroup = "",
        Technology = "SOC",
        TestParameters = "",
        actions = {
          31
        },
        deps = {
          12,
          30
        },
        fullName = "SOC Info_SBIN",
        outputs = {
          MEMORY_SIZE = {
            actionIdx = 31,
            actionName = "RunInfo_SBIN",
            returnIdx = 3
          },
          SBin_status = {
            actionIdx = 31,
            actionName = "RunInfo_SBIN",
            returnIdx = 7
          },
          SbinKey = {
            actionIdx = 31,
            actionName = "RunInfo_SBIN",
            returnIdx = 6
          },
          binFuse = {
            actionIdx = 31,
            actionName = "RunInfo_SBIN",
            returnIdx = 4
          },
          bin_fuse = {
            actionIdx = 31,
            actionName = "RunInfo_SBIN",
            returnIdx = 5
          },
          soc_info = {
            actionIdx = 31,
            actionName = "RunInfo_SBIN",
            returnIdx = 1
          },
          soc_p_resp = {
            actionIdx = 31,
            actionName = "RunInfo_SBIN",
            returnIdx = 2
          }
        },
        subTestName = "Info_SBIN",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "FWDL_ACE",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "",
        actions = {
          32
        },
        deps = {
          12,
          31
        },
        fullName = "USBC FWDL_ACE",
        outputs = {
          ace_resp = {
            actionIdx = 32,
            actionName = "RunFWDL_ACE",
            returnIdx = 2
          },
          ace_ret = {
            actionIdx = 32,
            actionName = "RunFWDL_ACE",
            returnIdx = 1
          }
        },
        subTestName = "FWDL_ACE",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "Info_RT13",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "",
        actions = {
          33
        },
        deps = {
          32
        },
        fullName = "USBC Info_RT13",
        outputs = {
          rt13_ret = {
            actionIdx = 33,
            actionName = "RunInfo_RT13",
            returnIdx = 1
          }
        },
        subTestName = "Info_RT13",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "DiagsFW_CRC_Check",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          34
        },
        deps = {
          12,
          33
        },
        fullName = "DUTInfo DiagsFW_CRC_Check",
        subTestName = "DiagsFW_CRC_Check",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "Temperature",
        SamplingGroup = "",
        Technology = "SOC",
        TestParameters = "",
        actions = {
          35
        },
        deps = {
          12,
          34
        },
        fullName = "SOC Temperature",
        subTestName = "Temperature",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "Syscfg_List_1",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          36
        },
        deps = {
          35
        },
        fullName = "DUTInfo Syscfg_List_1",
        subTestName = "Syscfg_List_1",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "Transition_RTOS_1",
        SamplingGroup = "",
        Technology = "Process",
        TestParameters = "",
        actions = {
          37
        },
        deps = {
          12,
          36
        },
        fullName = "Process Transition_RTOS_1",
        subTestName = "Transition_RTOS_1",
        testName = "Process"
      },
      {
        Conditions = "",
        Coverage = "RTOSFW",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          38
        },
        deps = {
          37
        },
        fullName = "DUTInfo RTOSFW",
        outputs = {
          RTOS_Version = {
            actionIdx = 38,
            actionName = "RunRTOSFW",
            returnIdx = 1
          }
        },
        subTestName = "RTOSFW",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "Transition_RTOS_2",
        SamplingGroup = "",
        Technology = "Process",
        TestParameters = "",
        actions = {
          39
        },
        deps = {
          38
        },
        fullName = "Process Transition_RTOS_2",
        subTestName = "Transition_RTOS_2",
        testName = "Process"
      },
      {
        Conditions = "",
        Coverage = "Transition_RBM_1",
        SamplingGroup = "",
        Technology = "Process",
        TestParameters = "",
        actions = {
          40
        },
        deps = {
          12,
          39
        },
        fullName = "Process Transition_RBM_1",
        subTestName = "Transition_RBM_1",
        testName = "Process"
      },
      {
        Conditions = "",
        Coverage = "RBMFW",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          41
        },
        deps = {
          40
        },
        fullName = "DUTInfo RBMFW",
        outputs = {
          RBM_Version = {
            actionIdx = 41,
            actionName = "RunRBMFW",
            returnIdx = 1
          }
        },
        subTestName = "RBMFW",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "Transition_RBM_2",
        SamplingGroup = "",
        Technology = "Process",
        TestParameters = "",
        actions = {
          42
        },
        deps = {
          41
        },
        fullName = "Process Transition_RBM_2",
        subTestName = "Transition_RBM_2",
        testName = "Process"
      },
      {
        Conditions = "",
        Coverage = "Reset_Diags",
        SamplingGroup = "",
        Technology = "Process",
        TestParameters = "",
        actions = {
          43
        },
        deps = {
          1,
          42
        },
        fullName = "Process Reset_Diags",
        subTestName = "Reset_Diags",
        testName = "Process"
      },
      {
        Conditions = "",
        Coverage = "Transition_Diags_2",
        SamplingGroup = "",
        Technology = "Process",
        TestParameters = "",
        actions = {
          44
        },
        deps = {
          43
        },
        fullName = "Process Transition_Diags_2",
        subTestName = "Transition_Diags_2",
        testName = "Process"
      },
      {
        Conditions = "",
        Coverage = "Syscfg",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "MLBSN",
        actions = {
          45
        },
        deps = {
          2,
          44
        },
        fullName = "DUTInfo Syscfg_MLBSN",
        subTestName = "Syscfg_MLBSN",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "Syscfg",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "MLBCFG",
        actions = {
          46
        },
        deps = {
          2,
          45
        },
        fullName = "DUTInfo Syscfg_MLBCFG",
        subTestName = "Syscfg_MLBCFG",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "Info_1",
        SamplingGroup = "",
        Technology = "SOC",
        TestParameters = "",
        actions = {
          47
        },
        deps = {
          1,
          2,
          12,
          31,
          46
        },
        fullName = "SOC Info_1",
        outputs = {
          BOARD_ID = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 1
          },
          Chip_ID = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 4
          },
          Chip_Ver = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 5
          },
          DIE_ID = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 6
          },
          ECID = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 8
          },
          FUSE_ID = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 7
          },
          HAS_TWO_STORAGE_DEVICE = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 3
          },
          binning_revision = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 9
          },
          fuse_rev = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 11
          },
          mlb_type = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 2
          },
          production_mode = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 12
          },
          soc_p_resp = {
            actionIdx = 47,
            actionName = "RunInfo_1",
            returnIdx = 10
          }
        },
        subTestName = "Info_1",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "Presencecheck_Mogul",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          48
        },
        deps = {
          47
        },
        fullName = "DUTInfo Presencecheck_Mogul",
        subTestName = "Presencecheck_Mogul",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "UnderVoltageWarning_Abbey",
        SamplingGroup = "",
        Technology = "PMU",
        TestParameters = "",
        actions = {
          49
        },
        deps = {
          48
        },
        fullName = "PMU UnderVoltageWarning_Abbey",
        subTestName = "UnderVoltageWarning_Abbey",
        testName = "PMU"
      },
      {
        Conditions = "",
        Coverage = "UnderVoltageWarning_Club",
        SamplingGroup = "",
        Technology = "PMU",
        TestParameters = "",
        actions = {
          50
        },
        deps = {
          49
        },
        fullName = "PMU UnderVoltageWarning_Club",
        subTestName = "UnderVoltageWarning_Club",
        testName = "PMU"
      },
      {
        Conditions = "",
        Coverage = "Info_2",
        SamplingGroup = "",
        Technology = "NAND",
        TestParameters = "",
        actions = {
          51
        },
        deps = {
          2,
          12,
          31,
          47,
          50
        },
        fullName = "NAND Info_2",
        outputs = {
          NAND_Chip_ID = {
            actionIdx = 51,
            actionName = "RunInfo_2",
            returnIdx = 2
          },
          NAND_Total_Controller_Count = {
            actionIdx = 51,
            actionName = "RunInfo_2",
            returnIdx = 1
          }
        },
        subTestName = "Info_2",
        testName = "NAND"
      },
      {
        Conditions = "",
        Coverage = "Info_GBBTest_1",
        SamplingGroup = "",
        Technology = "NAND",
        TestParameters = "",
        actions = {
          52
        },
        deps = {
          51
        },
        fullName = "NAND Info_GBBTest_1",
        subTestName = "Info_GBBTest_1",
        testName = "NAND"
      },
      {
        Conditions = "",
        Coverage = "Reset",
        SamplingGroup = "",
        Technology = "Speaker",
        TestParameters = "",
        actions = {
          53
        },
        deps = {
          1,
          52
        },
        fullName = "Speaker Reset",
        subTestName = "Reset",
        testName = "Speaker"
      },
      {
        Conditions = "",
        Coverage = "Info_SEP",
        SamplingGroup = "",
        Technology = "SOC",
        TestParameters = "",
        actions = {
          54
        },
        deps = {
          53
        },
        fullName = "SOC Info_SEP",
        subTestName = "Info_SEP",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "LeakageCheck",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "VBUS_To_PP5V0",
        actions = {
          55
        },
        deps = {
          1,
          54
        },
        fullName = "USBC LeakageCheck_VBUS_To_PP5V0",
        outputs = {
          ace_result = {
            actionIdx = 55,
            actionName = "RunLeakageCheck_VBUS_To_PP5V0",
            returnIdx = 1
          }
        },
        subTestName = "LeakageCheck_VBUS_To_PP5V0",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "LeakageCheck",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "VBUS_To_PPHV",
        actions = {
          56
        },
        deps = {
          1,
          55
        },
        fullName = "USBC LeakageCheck_VBUS_To_PPHV",
        outputs = {
          ace_result = {
            actionIdx = 56,
            actionName = "RunLeakageCheck_VBUS_To_PPHV",
            returnIdx = 1
          }
        },
        subTestName = "LeakageCheck_VBUS_To_PPHV",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "LeakageCheck",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "VIN_3V3_To_VBUS",
        actions = {
          57
        },
        deps = {
          1,
          56
        },
        fullName = "USBC LeakageCheck_VIN_3V3_To_VBUS",
        outputs = {
          PP3V3_S2_ACE_Result = {
            actionIdx = 57,
            actionName = "RunLeakageCheck_VIN_3V3_To_VBUS",
            returnIdx = 1
          },
          ace_result = {
            actionIdx = 57,
            actionName = "RunLeakageCheck_VIN_3V3_To_VBUS",
            returnIdx = 2
          }
        },
        subTestName = "LeakageCheck_VIN_3V3_To_VBUS",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "LeakageCheck",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "VIN_LV_To_VOUT_LV",
        actions = {
          58
        },
        deps = {
          1,
          57
        },
        fullName = "USBC LeakageCheck_VIN_LV_To_VOUT_LV",
        outputs = {
          PP1V8_S2_ACE_Result = {
            actionIdx = 58,
            actionName = "RunLeakageCheck_VIN_LV_To_VOUT_LV",
            returnIdx = 1
          },
          ace_result = {
            actionIdx = 58,
            actionName = "RunLeakageCheck_VIN_LV_To_VOUT_LV",
            returnIdx = 2
          }
        },
        subTestName = "LeakageCheck_VIN_LV_To_VOUT_LV",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "LeakageCheck",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "CC1-2_To_PPCABLE-PP5V0",
        actions = {
          59
        },
        deps = {
          1,
          58
        },
        fullName = "USBC LeakageCheck_CC1-2_To_PPCABLE-PP5V0",
        outputs = {
          ace_result = {
            actionIdx = 59,
            actionName = "RunLeakageCheck_CC1-2_To_PPCABLE-PP5V0",
            returnIdx = 1
          }
        },
        subTestName = "LeakageCheck_CC1-2_To_PPCABLE-PP5V0",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "LeakageCheck",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "PP5V0_To_VBUS",
        actions = {
          60
        },
        deps = {
          1,
          47,
          59
        },
        fullName = "USBC LeakageCheck_PP5V0_To_VBUS",
        outputs = {
          ace_result = {
            actionIdx = 60,
            actionName = "RunLeakageCheck_PP5V0_To_VBUS",
            returnIdx = 1
          }
        },
        subTestName = "LeakageCheck_PP5V0_To_VBUS",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "LeakageCheck",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "PPHV_To_VBUS",
        actions = {
          61
        },
        deps = {
          1,
          60
        },
        fullName = "USBC LeakageCheck_PPHV_To_VBUS",
        outputs = {
          ace_result = {
            actionIdx = 61,
            actionName = "RunLeakageCheck_PPHV_To_VBUS",
            returnIdx = 1
          }
        },
        subTestName = "LeakageCheck_PPHV_To_VBUS",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "PCIeBIST_AEMToolsS6E",
        SamplingGroup = "",
        Technology = "NAND",
        TestParameters = "",
        actions = {
          62
        },
        deps = {
          47,
          61
        },
        fullName = "NAND PCIeBIST_AEMToolsS6E",
        subTestName = "PCIeBIST_AEMToolsS6E",
        testName = "NAND"
      },
      {
        Conditions = "",
        Coverage = "PCIeBIST_AEMToolsANS4",
        SamplingGroup = "",
        Technology = "NAND",
        TestParameters = "",
        actions = {
          63
        },
        deps = {
          47,
          62
        },
        fullName = "NAND PCIeBIST_AEMToolsANS4",
        subTestName = "PCIeBIST_AEMToolsANS4",
        testName = "NAND"
      },
      {
        Conditions = "",
        Coverage = "Wifi_AEMToolsWifi3nm",
        SamplingGroup = "",
        Technology = "RF",
        TestParameters = "",
        actions = {
          64
        },
        deps = {
          63
        },
        fullName = "RF Wifi_AEMToolsWifi3nm",
        subTestName = "Wifi_AEMToolsWifi3nm",
        testName = "RF"
      },
      {
        Conditions = "mlb_type==\"MLB_B\"",
        Coverage = "Baseband_AEMToolsBaseband3nm",
        SamplingGroup = "",
        Technology = "RF",
        TestParameters = "",
        actions = {
          65
        },
        deps = {
          64
        },
        fullName = "RF Baseband_AEMToolsBaseband3nm",
        subTestName = "Baseband_AEMToolsBaseband3nm",
        testName = "RF"
      },
      {
        Conditions = "",
        Coverage = "Wifi_AEMToolsProxima",
        SamplingGroup = "",
        Technology = "RF",
        TestParameters = "",
        actions = {
          66
        },
        deps = {
          65
        },
        fullName = "RF Wifi_AEMToolsProxima",
        subTestName = "Wifi_AEMToolsProxima",
        testName = "RF"
      },
      {
        Conditions = "mlb_type==\"MLB_B\"",
        Coverage = "Baseband_AEMToolsSinopeGen4",
        SamplingGroup = "",
        Technology = "RF",
        TestParameters = "",
        actions = {
          67
        },
        deps = {
          66
        },
        fullName = "RF Baseband_AEMToolsSinopeGen4",
        subTestName = "Baseband_AEMToolsSinopeGen4",
        testName = "RF"
      },
      {
        Conditions = "mlb_type==\"MLB_B\"",
        Coverage = "Baseband",
        SamplingGroup = "",
        Technology = "RF",
        TestParameters = "",
        actions = {
          68
        },
        deps = {
          67
        },
        fullName = "RF Baseband",
        outputs = {
          BB_FIRMWARE = {
            actionIdx = 68,
            actionName = "RunBaseband",
            returnIdx = 4
          },
          BB_Load_Firmware_resp = {
            actionIdx = 68,
            actionName = "RunBaseband",
            returnIdx = 2
          },
          BB_Properties_resp = {
            actionIdx = 68,
            actionName = "RunBaseband",
            returnIdx = 3
          },
          BB_SNUM = {
            actionIdx = 68,
            actionName = "RunBaseband",
            returnIdx = 5
          },
          Load_Status = {
            actionIdx = 68,
            actionName = "RunBaseband",
            returnIdx = 1
          }
        },
        subTestName = "Baseband",
        testName = "RF"
      },
      {
        Conditions = "",
        Coverage = "WIFI_BT",
        SamplingGroup = "",
        Technology = "RF",
        TestParameters = "",
        actions = {
          69
        },
        deps = {
          68
        },
        fullName = "RF WIFI_BT",
        subTestName = "WIFI_BT",
        testName = "RF"
      },
      {
        Conditions = "",
        Coverage = "NFC",
        SamplingGroup = "",
        Technology = "RF",
        TestParameters = "",
        actions = {
          70
        },
        deps = {
          69
        },
        fullName = "RF NFC",
        outputs = {
          SH_FIRMWARE = {
            actionIdx = 70,
            actionName = "RunNFC",
            returnIdx = 2
          },
          SH_Properties_resp = {
            actionIdx = 70,
            actionName = "RunNFC",
            returnIdx = 1
          }
        },
        subTestName = "NFC",
        testName = "RF"
      },
      {
        Conditions = "",
        Coverage = "Syscfg_Mac",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          71
        },
        deps = {
          70
        },
        fullName = "DUTInfo Syscfg_Mac",
        subTestName = "Syscfg_Mac",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "SmokeyTest",
        SamplingGroup = "",
        Technology = "Touch",
        TestParameters = "TouchShorts",
        actions = {
          72
        },
        deps = {
          71
        },
        fullName = "Touch SmokeyTest_TouchShorts",
        subTestName = "SmokeyTest_TouchShorts",
        testName = "Touch"
      },
      {
        Conditions = "",
        Coverage = "SmokeyTest",
        SamplingGroup = "",
        Technology = "Touch",
        TestParameters = "TouchTiCC",
        actions = {
          73
        },
        deps = {
          72
        },
        fullName = "Touch SmokeyTest_TouchTiCC",
        subTestName = "SmokeyTest_TouchTiCC",
        testName = "Touch"
      },
      {
        Conditions = "",
        Coverage = "SmokeyTest",
        SamplingGroup = "",
        Technology = "Touch",
        TestParameters = "TouchGeneralTest",
        actions = {
          74
        },
        deps = {
          73
        },
        fullName = "Touch SmokeyTest_TouchGeneralTest",
        outputs = {
          Grape_Properties_resp = {
            actionIdx = 74,
            actionName = "RunSmokeyTest_TouchGeneralTest",
            returnIdx = 1
          },
          TOUCH_FIRMWARE = {
            actionIdx = 74,
            actionName = "RunSmokeyTest_TouchGeneralTest",
            returnIdx = 2
          }
        },
        subTestName = "SmokeyTest_TouchGeneralTest",
        testName = "Touch"
      },
      {
        Conditions = "",
        Coverage = "SmokeyTest",
        SamplingGroup = "",
        Technology = "Touch",
        TestParameters = "TouchGPIOTest",
        actions = {
          75
        },
        deps = {
          74
        },
        fullName = "Touch SmokeyTest_TouchGPIOTest",
        subTestName = "SmokeyTest_TouchGPIOTest",
        testName = "Touch"
      },
      {
        Conditions = "",
        Coverage = "GPIOCheck_4",
        SamplingGroup = "",
        Technology = "PMU",
        TestParameters = "",
        actions = {
          76
        },
        deps = {
          12,
          75
        },
        fullName = "PMU GPIOCheck_4",
        subTestName = "GPIOCheck_4",
        testName = "PMU"
      },
      {
        Conditions = "",
        Coverage = "GPIOCheck_5",
        SamplingGroup = "",
        Technology = "Touch",
        TestParameters = "",
        actions = {
          77
        },
        deps = {
          76
        },
        fullName = "Touch GPIOCheck_5",
        subTestName = "GPIOCheck_5",
        testName = "Touch"
      },
      {
        Conditions = "",
        Coverage = "GPIOCheck_6",
        SamplingGroup = "",
        Technology = "PMU",
        TestParameters = "",
        actions = {
          78
        },
        deps = {
          12,
          77
        },
        fullName = "PMU GPIOCheck_6",
        subTestName = "GPIOCheck_6",
        testName = "PMU"
      },
      {
        Conditions = "",
        Coverage = "SmokeyTest",
        SamplingGroup = "",
        Technology = "RF",
        TestParameters = "WDFU",
        actions = {
          79
        },
        deps = {
          78
        },
        fullName = "RF SmokeyTest_WDFU",
        outputs = {
          smokey_WDFU_resp = {
            actionIdx = 79,
            actionName = "RunSmokeyTest_WDFU",
            returnIdx = 1
          }
        },
        subTestName = "SmokeyTest_WDFU",
        testName = "RF"
      },
      {
        Conditions = "",
        Coverage = "Temperature_2",
        SamplingGroup = "",
        Technology = "SOC",
        TestParameters = "",
        actions = {
          80
        },
        deps = {
          79
        },
        fullName = "SOC Temperature_2",
        outputs = {
          THERMAL0_Instant = {
            actionIdx = 80,
            actionName = "RunTemperature_2",
            returnIdx = 1
          },
          tem_value = {
            actionIdx = 80,
            actionName = "RunTemperature_2",
            returnIdx = 2
          }
        },
        subTestName = "Temperature_2",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "SensorData_VendorInfor",
        SamplingGroup = "",
        Technology = "Accel",
        TestParameters = "",
        actions = {
          81
        },
        deps = {
          80
        },
        fullName = "Accel SensorData_VendorInfor",
        outputs = {
          listsensors_resp = {
            actionIdx = 81,
            actionName = "RunSensorData_VendorInfor",
            returnIdx = 1
          }
        },
        subTestName = "SensorData_VendorInfor",
        testName = "Accel"
      },
      {
        Conditions = "",
        Coverage = "SensorData_AccelOnly",
        SamplingGroup = "",
        Technology = "Accel",
        TestParameters = "",
        actions = {
          82
        },
        deps = {
          81
        },
        fullName = "Accel SensorData_AccelOnly",
        outputs = {
          accel_only_test_resp = {
            actionIdx = 82,
            actionName = "RunSensorData_AccelOnly",
            returnIdx = 1
          },
          accel_only_test_sec_resp = {
            actionIdx = 82,
            actionName = "RunSensorData_AccelOnly",
            returnIdx = 3
          },
          accel_selftest_result = {
            actionIdx = 82,
            actionName = "RunSensorData_AccelOnly",
            returnIdx = 2
          }
        },
        subTestName = "SensorData_AccelOnly",
        testName = "Accel"
      },
      {
        Conditions = "",
        Coverage = "SensorData_FS8g_ODR100HZ_Zup",
        SamplingGroup = "",
        Technology = "Accel",
        TestParameters = "",
        actions = {
          83
        },
        deps = {
          82
        },
        fullName = "Accel SensorData_FS8g_ODR100HZ_Zup",
        subTestName = "SensorData_FS8g_ODR100HZ_Zup",
        testName = "Accel"
      },
      {
        Conditions = "",
        Coverage = "SensorData_GyroNormal",
        SamplingGroup = "",
        Technology = "IMU",
        TestParameters = "",
        actions = {
          84
        },
        deps = {
          83
        },
        fullName = "IMU SensorData_GyroNormal",
        outputs = {
          accel_gyro_normal_test_resp = {
            actionIdx = 84,
            actionName = "RunSensorData_GyroNormal",
            returnIdx = 1
          },
          accel_gyro_test_resp = {
            actionIdx = 84,
            actionName = "RunSensorData_GyroNormal",
            returnIdx = 2
          }
        },
        subTestName = "SensorData_GyroNormal",
        testName = "IMU"
      },
      {
        Conditions = "",
        Coverage = "SensorData_IDInfor",
        SamplingGroup = "",
        Technology = "IMU",
        TestParameters = "",
        actions = {
          85
        },
        deps = {
          84
        },
        fullName = "IMU SensorData_IDInfor",
        subTestName = "SensorData_IDInfor",
        testName = "IMU"
      },
      {
        Conditions = "",
        Coverage = "SensorData_FS8g_ODR200HZ_Zup",
        SamplingGroup = "",
        Technology = "IMU",
        TestParameters = "",
        actions = {
          86
        },
        deps = {
          84,
          85
        },
        fullName = "IMU SensorData_FS8g_ODR200HZ_Zup",
        subTestName = "SensorData_FS8g_ODR200HZ_Zup",
        testName = "IMU"
      },
      {
        Conditions = "",
        Coverage = "SensorData_FS2000dps_ODR200HZ",
        SamplingGroup = "",
        Technology = "IMU",
        TestParameters = "",
        actions = {
          87
        },
        deps = {
          84,
          86
        },
        fullName = "IMU SensorData_FS2000dps_ODR200HZ",
        subTestName = "SensorData_FS2000dps_ODR200HZ",
        testName = "IMU"
      },
      {
        Conditions = "",
        Coverage = "Registers",
        SamplingGroup = "",
        Technology = "PressureSensor",
        TestParameters = "",
        actions = {
          88
        },
        deps = {
          87
        },
        fullName = "PressureSensor Registers",
        subTestName = "Registers",
        testName = "PressureSensor"
      },
      {
        Conditions = "",
        Coverage = "SensorData",
        SamplingGroup = "",
        Technology = "PressureSensor",
        TestParameters = "",
        actions = {
          89
        },
        deps = {
          88
        },
        fullName = "PressureSensor SensorData",
        subTestName = "SensorData",
        testName = "PressureSensor"
      },
      {
        Conditions = "",
        Coverage = "Info_GBBTest_2",
        SamplingGroup = "",
        Technology = "NAND",
        TestParameters = "",
        actions = {
          90
        },
        deps = {
          89
        },
        fullName = "NAND Info_GBBTest_2",
        outputs = {
          GBB_Test_resp = {
            actionIdx = 90,
            actionName = "RunInfo_GBBTest_2",
            returnIdx = 1
          }
        },
        subTestName = "Info_GBBTest_2",
        testName = "NAND"
      },
      {
        Conditions = "",
        Coverage = "Info_ANS_HealthTest",
        SamplingGroup = "",
        Technology = "NAND",
        TestParameters = "",
        actions = {
          91
        },
        deps = {
          90
        },
        fullName = "NAND Info_ANS_HealthTest",
        subTestName = "Info_ANS_HealthTest",
        testName = "NAND"
      },
      {
        Conditions = "",
        Coverage = "Syscfg_List_2",
        SamplingGroup = "",
        Technology = "DUTInfo",
        TestParameters = "",
        actions = {
          92
        },
        deps = {
          91
        },
        fullName = "DUTInfo Syscfg_List_2",
        subTestName = "Syscfg_List_2",
        testName = "DUTInfo"
      },
      {
        Conditions = "",
        Coverage = "Temperature_3",
        SamplingGroup = "",
        Technology = "SOC",
        TestParameters = "",
        actions = {
          93
        },
        deps = {
          92
        },
        fullName = "SOC Temperature_3",
        outputs = {
          THERMAL0_Instant = {
            actionIdx = 93,
            actionName = "RunTemperature_3",
            returnIdx = 1
          },
          tem_value = {
            actionIdx = 93,
            actionName = "RunTemperature_3",
            returnIdx = 2
          }
        },
        subTestName = "Temperature_3",
        testName = "SOC"
      },
      {
        Conditions = "",
        Coverage = "Info_AceTRNG",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "",
        actions = {
          94
        },
        deps = {
          93
        },
        fullName = "USBC Info_AceTRNG",
        outputs = {
          acetngr = {
            actionIdx = 94,
            actionName = "RunInfo_AceTRNG",
            returnIdx = 1
          }
        },
        subTestName = "Info_AceTRNG",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "ForceDFU_ADFU",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "",
        actions = {
          95
        },
        deps = {
          94
        },
        fullName = "USBC ForceDFU_ADFU",
        subTestName = "ForceDFU_ADFU",
        testName = "USBC"
      },
      {
        Conditions = "",
        Coverage = "Info_ECID",
        SamplingGroup = "",
        Technology = "USBC",
        TestParameters = "",
        actions = {
          96
        },
        deps = {
          95
        },
        fullName = "USBC Info_ECID",
        outputs = {
          acetngr = {
            actionIdx = 96,
            actionName = "RunInfo_ECID",
            returnIdx = 1
          }
        },
        subTestName = "Info_ECID",
        testName = "USBC"
      }
    },
    samplings = {
    },
    teardownActions = {
      {
        args = {
          {
            action = {
              actionIdx = 1,
              dag = "main",
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Power/Discharge_Initial_End.csv",
        name = "RunDischarge_Initial_End",
        plugins = {
          "Dut",
          "Kis_dut",
          "Kis_channelPlugin",
          "ChannelPlugin",
          "FixturePlugin",
          "StationInfo",
          "FileOperation",
          "VariableTable",
          "RunShellCommand",
          "TimeUtility",
          "SMTCommonPlugin"
        },
        testIdx = 1
      },
      {
        args = {
          {
            action = {
              actionIdx = 1,
              dag = "main",
              returnIdx = 1
            }
          }
        },
        filename = "Tech/Fixture/GeneralAction_Reset_Initial.csv",
        name = "RunGeneralAction_4",
        plugins = {
          "FixturePlugin",
          "StationInfo",
          "RunShellCommand"
        },
        testIdx = 2
      },
      {
        dataQuery = true,
        name = "data",
        testIdx = 3
      },
      {
        args = {
          {
            action = {
              actionIdx = 3,
              returnIdx = 4
            }
          }
        },
        filename = "Tech/Process/getDeviceOverallResult.csv",
        name = "RungetDeviceOverallResult",
        plugins = {
          "VariableTable",
          "StationInfo"
        },
        testConditions = {
          Poison = {
            returnIdx = 2
          },
          testfail = {
            returnIdx = 1
          }
        },
        testIdx = 3
      },
      {
        args = {
          {
            action = {
              actionIdx = 2,
              dag = "main",
              returnIdx = 2
            }
          },
          {
            action = {
              actionIdx = 1,
              dag = "main",
              returnIdx = 1
            }
          },
          {
            condition = "testfail"
          }
        },
        filename = "Tech/Fixture/GeneralAction.csv",
        name = "RunGeneralAction_6",
        plugins = {
          "FixturePlugin",
          "StationInfo",
          "RunShellCommand"
        },
        testIdx = 4
      },
      {
        args = {
          {
            action = {
              actionIdx = 2,
              dag = "main",
              returnIdx = 2
            }
          }
        },
        filename = "Tech/Fixture/GeneralAction_Flow_Log.csv",
        name = "RunGeneralAction_Flow_Log",
        plugins = {
          "StationInfo",
          "RunShellCommand"
        },
        testIdx = 5
      }
    },
    teardownTests = {
      {
        Conditions = "",
        Coverage = "Discharge",
        SamplingGroup = "",
        Technology = "Power",
        TestParameters = "Initial_End",
        actions = {
          1
        },
        fullName = "Power Discharge_Initial_End",
        subTestName = "Discharge_Initial_End",
        testName = "Power"
      },
      {
        Conditions = "",
        Coverage = "GeneralAction_4",
        SamplingGroup = "",
        Technology = "Fixture",
        TestParameters = "",
        actions = {
          2
        },
        deps = {
          1
        },
        fullName = "Fixture GeneralAction_4",
        subTestName = "GeneralAction_4",
        testName = "Fixture"
      },
      {
        Conditions = "",
        Coverage = "Teardown",
        SamplingGroup = "",
        Technology = "Process",
        TestParameters = "getDeviceOverallResult",
        actions = {
          3,
          4
        },
        deps = {
          2
        },
        fullName = "Process Teardown_getDeviceOverallResult",
        subTestName = "Teardown_getDeviceOverallResult",
        testName = "Process"
      },
      {
        Conditions = "",
        Coverage = "GeneralAction_6",
        SamplingGroup = "",
        Technology = "Fixture",
        TestParameters = "",
        actions = {
          5
        },
        deps = {
          3
        },
        fullName = "Fixture GeneralAction_6",
        subTestName = "GeneralAction_6",
        testName = "Fixture"
      },
      {
        Conditions = "",
        Coverage = "GeneralAction_Flow_Log",
        SamplingGroup = "",
        Technology = "Fixture",
        TestParameters = "",
        actions = {
          6
        },
        deps = {
          4
        },
        fullName = "Fixture GeneralAction_Flow_Log",
        subTestName = "GeneralAction_Flow_Log",
        testName = "Fixture"
      }
    },
    testPlanAttribute = {
      limitsHasConditions = true,
      requireConditionValidator = true
    }
  }
}