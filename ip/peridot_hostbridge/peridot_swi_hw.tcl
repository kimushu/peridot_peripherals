# TCL File Generated by Component Editor 15.0
# Tue May 19 06:14:06 JST 2015
# DO NOT MODIFY


# 
# peridot_swi "PERIDOT SWI" v1.1
#  2015.05.19.06:14:06
# 
# 

# 
# request TCL package from ACDS 15.0
# 
package require -exact qsys 15.0


# 
# module peridot_swi
# 
set_module_property DESCRIPTION ""
set_module_property NAME peridot_swi
set_module_property VERSION 1.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR "J-7SYSTEM WORKS LIMITED"
set_module_property DISPLAY_NAME "PERIDOT SWI"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false
set_module_property VALIDATION_CALLBACK validate


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL peridot_swi
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file peridot_swi.v VERILOG PATH peridot_swi.v TOP_LEVEL_FILE
add_fileset_file peridot_spi.v VERILOG PATH peridot_spi.v
add_fileset_file altchip_id.v VERILOG PATH altchip_id.v


# 
# parameters
# 
add_parameter CLASSID INTEGER 0x72A00000
set_parameter_property CLASSID DISPLAY_NAME "32 bit Class ID"
set_parameter_property CLASSID HDL_PARAMETER true

add_parameter TIMECODE INTEGER 0
set_parameter_property TIMECODE DISPLAY_NAME "Time code"
set_parameter_property TIMECODE HDL_PARAMETER true
set_parameter_property TIMECODE SYSTEM_INFO {GENERATION_ID}
set_parameter_property TIMECODE ENABLED false
set_parameter_property TIMECODE VISIBLE false

add_parameter CLOCKFREQ INTEGER 0
set_parameter_property CLOCKFREQ DISPLAY_NAME "Drive clock rate"
set_parameter_property CLOCKFREQ UNITS Hertz
set_parameter_property CLOCKFREQ HDL_PARAMETER true
set_parameter_property CLOCKFREQ SYSTEM_INFO {CLOCK_RATE clock}
set_parameter_property CLOCKFREQ ENABLED false
set_parameter_property CLOCKFREQ VISIBLE false

add_parameter DEVICE_FAMILY STRING ""
set_parameter_property DEVICE_FAMILY DISPLAY_NAME "Device family"
set_parameter_property DEVICE_FAMILY HDL_PARAMETER true
set_parameter_property DEVICE_FAMILY SYSTEM_INFO {DEVICE_FAMILY}
set_parameter_property DEVICE_FAMILY ENABLED false
set_parameter_property DEVICE_FAMILY VISIBLE false

add_parameter PART_NAME STRING ""
set_parameter_property PART_NAME DISPLAY_NAME "Part number"
set_parameter_property PART_NAME HDL_PARAMETER true
set_parameter_property PART_NAME SYSTEM_INFO {DEVICE}
set_parameter_property PART_NAME ENABLED false
set_parameter_property PART_NAME VISIBLE false


# 
# display items
# 
add_display_item "" CLASSID PARAMETER  
set_display_item_property CLASSID DISPLAY_HINT hexadecimal
add_display_item "Description" CLASSID text "Please use hexadecimal numbers only in CLASS-ID."
add_display_item "Information" CLOCKFREQ text "Maximum frequency of clock signal is 100MHz."


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock csi_clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset rsi_reset reset Input 1


# 
# connection point avs
# 
add_interface avs avalon end
set_interface_property avs addressUnits WORDS
set_interface_property avs associatedClock clock
set_interface_property avs associatedReset reset
set_interface_property avs bitsPerSymbol 8
set_interface_property avs burstOnBurstBoundariesOnly false
set_interface_property avs burstcountUnits WORDS
set_interface_property avs explicitAddressSpan 0
set_interface_property avs holdTime 0
set_interface_property avs linewrapBursts false
set_interface_property avs maximumPendingReadTransactions 0
set_interface_property avs maximumPendingWriteTransactions 0
set_interface_property avs readLatency 0
set_interface_property avs readWaitTime 1
set_interface_property avs setupTime 0
set_interface_property avs timingUnits Cycles
set_interface_property avs writeWaitTime 0
set_interface_property avs ENABLED true
set_interface_property avs EXPORT_OF ""
set_interface_property avs PORT_NAME_MAP ""
set_interface_property avs CMSIS_SVD_VARIABLES ""
set_interface_property avs SVD_ADDRESS_GROUP ""

add_interface_port avs avs_address address Input 3
add_interface_port avs avs_read read Input 1
add_interface_port avs avs_readdata readdata Output 32
add_interface_port avs avs_write write Input 1
add_interface_port avs avs_writedata writedata Input 32
set_interface_assignment avs embeddedsw.configuration.isFlash 0
set_interface_assignment avs embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avs embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avs embeddedsw.configuration.isPrintableDevice 0


# 
# connection point irq
# 
add_interface irq interrupt end
set_interface_property irq associatedAddressablePoint avs
set_interface_property irq associatedClock clock
set_interface_property irq associatedReset reset
set_interface_property irq bridgedReceiverOffset ""
set_interface_property irq bridgesToReceiver ""
set_interface_property irq ENABLED true
set_interface_property irq EXPORT_OF ""
set_interface_property irq PORT_NAME_MAP ""
set_interface_property irq CMSIS_SVD_VARIABLES ""
set_interface_property irq SVD_ADDRESS_GROUP ""

add_interface_port irq ins_irq irq Output 1


# 
# connection point export
# 
add_interface export conduit end
set_interface_property export associatedClock clock
set_interface_property export associatedReset reset
set_interface_property export ENABLED true
set_interface_property export EXPORT_OF ""
set_interface_property export PORT_NAME_MAP ""
set_interface_property export CMSIS_SVD_VARIABLES ""
set_interface_property export SVD_ADDRESS_GROUP ""

add_interface_port export coe_cpureset cpureset Output 1
add_interface_port export coe_led led Output 1
add_interface_port export coe_cso_n cso_n Output 1
add_interface_port export coe_dclk dclk Output 1
add_interface_port export coe_asdo asdo Output 1
add_interface_port export coe_data0 data0 Input 1


#
# Validation callback
#
proc validate {} {

	set freq		[ format %u [get_parameter_value CLOCKFREQ] ]
	set id			[ format %u [get_parameter_value CLASSID] ]
	set timestamp	[ format %u [get_parameter_value TIMECODE] ]

	#
	# Software assignments for system.h
	#
	set_module_assignment embeddedsw.CMacro.FREQ	$freq
	set_module_assignment embeddedsw.CMacro.ID		$id
	set_module_assignment embeddedsw.CMacro.TIMESTAMP	$timestamp

	# Device tree parameters
	set_module_assignment embeddedsw.dts.vendor "altr"
	set_module_assignment embeddedsw.dts.group "sysid"
	set_module_assignment embeddedsw.dts.name "sysid"
	set_module_assignment embeddedsw.dts.compatible "altr,sysid-1.0"
	set_module_assignment embeddedsw.dts.params.id   $id
	set_module_assignment embeddedsw.dts.params.timestamp   $timestamp

	# Remind the user to set class id
	send_message info "Class id is not assigned automatically. Edit the class id parameter to provide a unique number."
	# Explain that timestamp will only be known during generation thus will not be shown
	send_message info "Time code and clock rate will be automatically updated when this component is generated."
}
