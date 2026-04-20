### A7 xdc file
### Marshall Graves & Sheel Shah -- FPGA Chess
### Created: 4/14/26
### Adapted from A7 xdc file for moving block VGA demo A7_nexys7.xdc by Sharath Krishnan

### ClkPort
set_property PACKAGE_PIN E3 [get_ports ClkPort]							
	set_property IOSTANDARD LVCMOS33 [get_ports ClkPort]
	create_clock -add -name ClkPort -period 10.00 [get_ports ClkPort]

### SSD CATHODES
set_property PACKAGE_PIN T10 [get_ports {Ca}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Ca}]

set_property PACKAGE_PIN R10 [get_ports {Cb}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cb}]

set_property PACKAGE_PIN K16 [get_ports {Cc}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cc}]

set_property PACKAGE_PIN K13 [get_ports {Cd}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cd}]

set_property PACKAGE_PIN P15 [get_ports {Ce}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Ce}]

set_property PACKAGE_PIN T11 [get_ports {Cf}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cf}]

set_property PACKAGE_PIN L18 [get_ports {Cg}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cg}]

set_property PACKAGE_PIN H15 [get_ports Dp] 
	set_property IOSTANDARD LVCMOS33 [get_ports Dp]

### SSD ANODES
set_property PACKAGE_PIN J17 [get_ports {An0}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An0}]

set_property PACKAGE_PIN J18 [get_ports {An1}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An1}]

set_property PACKAGE_PIN T9 [get_ports {An2}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An2}]

set_property PACKAGE_PIN J14 [get_ports {An3}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An3}]

set_property PACKAGE_PIN P14 [get_ports {An4}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An4}]

set_property PACKAGE_PIN T14 [get_ports {An5}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An5}]

set_property PACKAGE_PIN K2 [get_ports {An6}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An6}]

set_property PACKAGE_PIN U13 [get_ports {An7}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An7}]

### PUSH BUTTONS
set_property PACKAGE_PIN N17 [get_ports BtnC] 
	set_property IOSTANDARD LVCMOS33 [get_ports BtnC]

set_property PACKAGE_PIN M18 [get_ports BtnU] 
	set_property IOSTANDARD LVCMOS33 [get_ports BtnU]

set_property PACKAGE_PIN P17 [get_ports BtnL] 
	set_property IOSTANDARD LVCMOS33 [get_ports BtnL]

set_property PACKAGE_PIN M17 [get_ports BtnR] 
	set_property IOSTANDARD LVCMOS33 [get_ports BtnR]

set_property PACKAGE_PIN P18 [get_ports BtnD] 
	set_property IOSTANDARD LVCMOS33 [get_ports BtnD]

### VGA
set_property PACKAGE_PIN A3 [get_ports {vgaR[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaR[0]}]

set_property PACKAGE_PIN B4 [get_ports {vgaR[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaR[1]}]

set_property PACKAGE_PIN C5 [get_ports {vgaR[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaR[2]}]

set_property PACKAGE_PIN A4 [get_ports {vgaR[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaR[3]}]

set_property PACKAGE_PIN B7 [get_ports {vgaB[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaB[0]}]

set_property PACKAGE_PIN C7 [get_ports {vgaB[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaB[1]}]

set_property PACKAGE_PIN D7 [get_ports {vgaB[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaB[2]}]

set_property PACKAGE_PIN D8 [get_ports {vgaB[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaB[3]}]

set_property PACKAGE_PIN C6 [get_ports {vgaG[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaG[0]}]

set_property PACKAGE_PIN A5 [get_ports {vgaG[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaG[1]}]

set_property PACKAGE_PIN B6 [get_ports {vgaG[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaG[2]}]

set_property PACKAGE_PIN A6 [get_ports {vgaG[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaG[3]}]

set_property PACKAGE_PIN B11 [get_ports hSync]						
	set_property IOSTANDARD LVCMOS33 [get_ports hSync]

set_property PACKAGE_PIN B12 [get_ports vSync]						
	set_property IOSTANDARD LVCMOS33 [get_ports vSync]

### QuadSpiFlashCS
set_property PACKAGE_PIN L13 [get_ports QuadSpiFlashCS]					
	set_property IOSTANDARD LVCMOS33 [get_ports QuadSpiFlashCS]

### SWITCHES
set_property PACKAGE_PIN J15 [get_ports {Sw0}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw0}]

set_property PACKAGE_PIN L16 [get_ports {Sw1}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw1}]

set_property PACKAGE_PIN M13 [get_ports {Sw2}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw2}]

### LEDS
set_property PACKAGE_PIN H17 [get_ports {Ld0}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld0}]

set_property PACKAGE_PIN K15 [get_ports {Ld1}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld1}]

set_property PACKAGE_PIN J13 [get_ports {Ld2}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld2}]

set_property PACKAGE_PIN N14 [get_ports {Ld3}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld3}]

set_property PACKAGE_PIN R18 [get_ports {Ld4}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld4}]

set_property PACKAGE_PIN V17 [get_ports {Ld5}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld5}]

set_property PACKAGE_PIN U17 [get_ports {Ld6}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld6}]

set_property PACKAGE_PIN U16 [get_ports {Ld7}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld7}]

set_property PACKAGE_PIN V16 [get_ports {Ld8}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld8}]

set_property PACKAGE_PIN T15 [get_ports {Ld9}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld9}]

set_property PACKAGE_PIN U14 [get_ports {Ld10}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld10}]

set_property PACKAGE_PIN T16 [get_ports {Ld11}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld11}]

set_property PACKAGE_PIN V15 [get_ports {Ld12}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld12}]

set_property PACKAGE_PIN V14 [get_ports {Ld13}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld13}]

set_property PACKAGE_PIN V12 [get_ports {Ld14}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld14}]

set_property PACKAGE_PIN V11 [get_ports {Ld15}]
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld15}]