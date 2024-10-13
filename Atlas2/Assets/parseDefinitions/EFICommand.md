EFI parsing definition file
===========================

Version Info
------------
AUGUST 22, 2015 ver01

[TOC]

Commands that can be parsed
===========================

version
--------
 - Command name: `version`
 - Command to send: `version`
```
{{ANYTHING}}
{{ANYTHING}}. Revision {{ANYTHING}}.
{{ANYTHING}}Built at {{ANYTHING}}
```

boardrev
--------
 - Command name: `boardrev`
 - Command to send: `boardrev`
```
Board Revision: {{ANYTHING}}
```

boardid
--------
 - Command name: `boardid`
 - Command to send: `boardid`
```
Board Id: {{boardid}}
```

soc -p
--------
 - Command name: `soc -p`
 - Command to send: `soc -p`
```
{{ANYTHING}}vendor: Apple
{{ANYTHING}}model: {{model}}
{{ANYTHING}}fuse-rev: {{fuse-re}} 
{{ANYTHING}}primary-cpu: {{ANYTHING}}
{{ANYTHING}}security-epoch: {{ANYTHING}}
{{ANYTHING}}security-domain: {{ANYTHING}}
{{ANYTHING}}production-mode: {{ANYTHING}}
{{ANYTHING}}board-id: {{ANYTHING}}
{{ANYTHING}}io-leakage-bin-fuse: {{io-leakage-bin-fuse}}
{{ANYTHING}}cpu-sram-io-leakage-bin-fuse: {{ANYTHING}}
{{ANYTHING}}gpu-sram-io-leakage-bin-fuse: {{ANYTHING}}
{{ANYTHING}}vdd-low-io-leakage-bin-fuse: {{ANYTHING}}
{{ANYTHING}}vdd-fixed-io-leakage-bin-fuse: {{vdd-fixed-io-leakage-bin-fuse}}
{{ANYTHING}}cpu-io-leakage-bin-fuse: {{cpu-io-leakage-bin-fuse}}
{{ANYTHING}}vdd-var-soc-io-leakage-bin-fuse: {{vdd-var-soc-io-leakage-bin-fuse}}
{{ANYTHING}}gpu-io-leakage-bin-fuse: {{gpu-io-leakage-bin-fuse}}
{{ANYTHING}}binning-revision: {{binning-revision}}
{{ANYTHING}}efi-memory-size: {{ANYTHING}}
{{ANYTHING}}revision: {{CPRV}}
{{ANYTHING}}prod-id:{{ANYTHING}}
{{ANYTHING}}secure-mode: {{ANYTHING}}
{{ANYTHING}}secure-storage: {{ANYTHING}}
{{ANYTHING}}package-id: {{ANYTHING}}
{{ANYTHING}}dram-memory-vendor: {{ANYTHING}}
{{ANYTHING}}dram-memory-type: {{ANYTHING}}
{{ANYTHING}}dram-memory-density: {{ANYTHING}}
{{ANYTHING}}dram-memory-io-width: {{ANYTHING}}
{{ANYTHING}}memctlr-cfg-channels: {{ANYTHING}}
{{ANYTHING}}memctlr-cfg-size: {{ANYTHING}}
```

sn
--------
 - Command name: `sn`
 - Command to send: `sn`
```
Serial: {{ANYTHING}}
```

syscfg print MLB#
--------
 - Command name: `syscfg print MLB#`
 - Command to send: `syscfg print MLB#`
```
{{MLB_CMD}}
{{MLB_Num}}
```

syscfg print CFG#
--------
 - Command name: `syscfg print CFG#`
 - Command to send: `syscfg print CFG#`
```
{{CFG_CMD}}
{{CFG}}
```

RTC__SET
--------
 - Command name: `RTC__SET`
 - Command to send: `RTC__SET`
```
:-)
```

cbwrite 0x02 incomplete
--------
 - Command name: `cbwrite 0x02 incomplete`
 - Command to send: `cbwrite 0x02 incomplete`
```
:-)
```

<!-- pmu --readadc all --avg 100
--------
 - Command name: `pmu --readadc all --avg 100`
 - Command to send: `pmu --readadc all --avg 100`
```
{{ANYTHING}}
``` -->

cb read 2
--------
 - Command name: `cb read 2`
 - Command to send: `cb read 2`
```
{{station}} {{state}} {{rel_fail_ct}} {{abs_fail_ct}} {{erase_ct}} {{test-time}} {{sw-version}}
```

enterDiags
--------
 - Command name: `enterDiags`
 - Command to send: `echo enterDiags`
```
enterDiags
```

enterrbm
--------
 - Command name: `enterrbm`
 - Command to send: `echo enterrbm`
```
{{ANYTHING}}
```

enterrtos
--------
 - Command name: `enterrtos`
 - Command to send: `echo enterrtos`
```
{{ANYTHING}}
```

pdump --set loops 5
--------
 - Command name: `pdump --set loops 5`
 - Command to send: `pdump --set loops 5`
```
:-)
```

pdump --play nandfs:\AppleInternal\Diags\Pdump\ -r
--------
 - Command name: `pdump --play nandfs:\AppleInternal\Diags\Pdump\ -r`
 - Command to send: `pdump --play nandfs:\AppleInternal\Diags\Pdump\ -r`
```
OK
```

NANDInfoTool
--------
 - Command name: `NANDInfoTool`
 - Command to send: `NANDInfoTool`
```
{{/\s*/}}NAND Configuration:
{{/\s*/}}
{{/\s*/}}Vendor:           {{NAND_Vendor}}
{{/\s*/}}Capacity:         {{NAND_SIZE}}
```
```
{{/\s*/}}Cell Type:        {{NAND_Cell_Type}}
```

soc -p list-perf-state
--------
 - Command name: `soc -p list-perf-state`
 - Command to send: `soc -p list-perf-state`
```
{{/.*/}}ECPU:
{{/.*/}}ECpu Perf State Index   :0
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}ECpu SafeVol Voltage    :{{ECpu_Bin_0_SafeVol_Voltage}}mV
```
```
{{/.*/}}ECpu Perf State Index   :1
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}ECpu SafeVol Voltage    :{{ECpu_Bin_1_SafeVol_Voltage}}mV
```
```
{{/.*/}}ECpu Perf State Index   :2
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}ECpu SafeVol Voltage    :{{ECpu_Bin_2_SafeVol_Voltage}}mV
```
```
{{/.*/}}ECpu Perf State Index   :3
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}ECpu SafeVol Voltage    :{{ECpu_Bin_3_SafeVol_Voltage}}mV
```
```
{{/.*/}}ECpu Perf State Index   :4
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}ECpu SafeVol Voltage    :{{ECpu_Bin_4_SafeVol_Voltage}}mV
```
```
{{/.*/}}ECpu Perf State Index   :5
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}ECpu SafeVol Voltage    :{{ECpu_Bin_5_SafeVol_Voltage}}mV
```
```
{{/.*/}}ECpu Perf State Index   :6
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}ECpu SafeVol Voltage    :{{ECpu_Bin_6_SafeVol_Voltage}}mV
```
```
{{/.*/}}ECpu Perf State Index   :7
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}ECpu SafeVol Voltage    :{{ECpu_Bin_7_SafeVol_Voltage}}mV
```
```
{{/.*/}}DCS:
{{/.*/}}
{{/.*/}}
{{/.*/}}Dcs VDD Voltage         :{{DCS_Bin_3_VDD_Voltage}}mV
{{/.*/}}DCS DRAM VDD Voltage    :{{DCS_Bin_3_DRAM_VDD_Voltage}}mV
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}Dcs VDD Voltage         :{{DCS_Bin_4_VDD_Voltage}}mV
{{/.*/}}DCS DRAM VDD Voltage    :{{DCS_Bin_4_DRAM_VDD_Voltage}}mV
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}Dcs VDD Voltage         :{{DCS_Bin_5_VDD_Voltage}}mV
{{/.*/}}DCS DRAM VDD Voltage    :{{DCS_Bin_5_DRAM_VDD_Voltage}}mV
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}Dcs VDD Voltage         :{{DCS_Bin_6_VDD_Voltage}}mV
{{/.*/}}DCS DRAM VDD Voltage    :{{DCS_Bin_6_DRAM_VDD_Voltage}}mV
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}Dcs VDD Voltage         :{{DCS_Bin_7_VDD_Voltage}}mV
{{/.*/}}DCS DRAM VDD Voltage    :{{DCS_Bin_7_DRAM_VDD_Voltage}}mV
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}Dcs VDD Voltage         :{{DCS_Bin_8_VDD_Voltage}}mV
{{/.*/}}DCS DRAM VDD Voltage    :{{DCS_Bin_8_DRAM_VDD_Voltage}}mV
{{/.*/}}
{{/.*/}}
{{/.*/}}
{{/.*/}}Dcs VDD Voltage         :{{DCS_Bin_9_VDD_Voltage}}mV
{{/.*/}}DCS DRAM VDD Voltage    :{{DCS_Bin_9_DRAM_VDD_Voltage}}mV
```

Future commands to be parsed
----------------------------
