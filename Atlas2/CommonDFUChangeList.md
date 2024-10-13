Coverage_Version = "1.0.21.2"

*****************************************************************
script Ver：1.0.21.2
change date：20240813
SW engineer： Haoran Zhou

1. add copyToHost function copy AEMTool file to host upload insight.
2. update compareValueWithOpreation function follow new ERS.

*****************************************************************
script Ver：1.0.21
change date：20240813
SW engineer： Andrew Chen

1. del Group.setDevicePrimaryIdentity function when UOP Fail not show message on UI.
2. Optimize functions of checkHangAndKernelPanicr for set “Poison” variable to true when restore hit panic.
3. Optimize DiagsTriage feature for collection NPI debug log at teardown when send command fail or error.

*****************************************************************
script Ver：1.0.20
change date：20240812
SW engineer： Allen Zhong

1. diagstriage function spilt enableUSB, DiagsTriage, disableUSB.

*****************************************************************
script Ver：1.0.20
change date：20240809
SW engineer： Allen Zhong

1.Add diagstriage function when send command fail.

*****************************************************************
script Ver：1.0.16
change date：20240805
SW engineer： Allen Zhong

1.Add Check Limit function in GroupFunctions.lua when open atlas2.
2.delete device.log limit check.
3.Optimize getLocationID and restoreDFUModeCheck function, add judge inner call of "paraTab.InnerCall" in DFUCommon.lua and restore.lua.

*****************************************************************
script Ver：1.0.15
change date：20240723
SW engineer： liang liu

1.Optimize getBaseLoctionID function, when PRM Vendor don't find right kis port result can't enter diag.
2.ptimize sendCmdAndParse function in DUTCmd.lua.
3.Optimize finishCB error result stop test.

*****************************************************************
script Ver：1.0.14
change date：20240705
SW engineer： Allen Zhong

1.add createParametricRecord function for smokey test record .
2.copy actives csv to user folder.
*****************************************************************

*****************************************************************

script Ver：1.0.13
change date：20240705
SW engineer： Allen Zhong

1.add GetCMDFromTable function for common sequence.
2.get ECID/UUID value from diag, then use little-endian.
3.update getVersions require file.

*****************************************************************

*****************************************************************

script Ver：1.0.11
change date：20240629
SW engineer： Allen Zhong

1.del Ace3CRC32, ACE3OTP and ACEFW lua files, station repo require Ace3FactoryProgrammingLua module.
2.Optimize writeCB not channel plugin function.

*****************************************************************

*****************************************************************

script Ver：1.0.10
change date：20240629
SW engineer： Allen Zhong

1 fix set-RTC command fail

*****************************************************************

*****************************************************************

script Ver：1.0.9
change date：20240628
SW engineer： Allen Zhong

1 Save the dutPluginName variable to the VariableTable at StartCB and finishCB

*****************************************************************

*****************************************************************

script Ver：1.0.8
change date：20240627
SW engineer： Allen Zhong

1 remove utils.lua to tech folder
2 update ALE folder to modules

*****************************************************************

*****************************************************************

script Ver：1.0.7
change date：20240624
SW engineer： Allen Zhong

1 use SMTLoggingHelper.lua replace log.lua for record log
2 plugin name use Camel-Case
3 optimize parseWithRegexString function

*****************************************************************

*****************************************************************

script Ver：1.0.4
change date：20240530
SW engineer： Andrew Chen / Yanzhao Hu / Hongliang Liu /Wenguang Zhang / Di Zhang

1 DeviceFunctions.lua <Fun loadKISPlugin> pid set: add vendor HYC  


*****************************************************************


*****************************************************************

Add Changelist to Schooner common lua for record

*****************************************************************
