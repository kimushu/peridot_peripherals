# ===================================================================
# TITLE : PERIDOT-NG / "PERIDOT SERVO controller "
#
#   DEGISN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
#   DATE   : 2017/02/20 -> 2017/02/20
#
# ===================================================================
# *******************************************************************
#    (C)2016-2017, J-7SYSTEM WORKS LIMITED.  All rights Reserved.
#
# * This module is a free sourcecode and there is NO WARRANTY.
# * No restriction on use. You can use, modify and redistribute it
#   for personal, non-profit or commercial products UNDER YOUR
#   RESPONSIBILITY.
# * Redistributions of source code must retain the above copyright
#   notice.
# *******************************************************************

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module peridot_i2c_master
# 
set_module_property NAME peridot_servo
set_module_property DISPLAY_NAME "PERIDOT SERVO contoller"
set_module_property DESCRIPTION "PERIDOT SERVO contoller"
set_module_property AUTHOR "J-7SYSTEM WORKS LIMITED"
set_module_property VERSION 16.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property HIDE_FROM_SOPC true
set_module_property HIDE_FROM_QUARTUS true
set_module_property EDITABLE false
set_module_property VALIDATION_CALLBACK validate


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL peridot_servo
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file peridot_servo.v VERILOG PATH hdl/peridot_servo.v TOP_LEVEL_FILE
add_fileset_file peridot_servo_pwmgen.v VERILOG PATH hdl/peridot_servo_pwmgen.v


# 
# parameters
# 
add_parameter PWM_CHANNEL INTEGER
set_parameter_property PWM_CHANNEL TYPE INTEGER
set_parameter_property PWM_CHANNEL DEFAULT_VALUE 16
set_parameter_property PWM_CHANNEL DISPLAY_NAME "PWM Channel (1-30)"
set_parameter_property PWM_CHANNEL ALLOWED_RANGES {1:30}
set_parameter_property PWM_CHANNEL UNITS None
set_parameter_property PWM_CHANNEL HDL_PARAMETER true

add_parameter CLOCKFREQ INTEGER 0
set_parameter_property CLOCKFREQ TYPE INTEGER
set_parameter_property CLOCKFREQ SYSTEM_INFO {CLOCK_RATE clock}
set_parameter_property CLOCKFREQ DISPLAY_NAME "Drive clock rate"
set_parameter_property CLOCKFREQ UNITS Hertz
set_parameter_property CLOCKFREQ HDL_PARAMETER true


# 
# display items
# 


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
# connection point avalon_slave
# 
add_interface avalon_slave avalon end
set_interface_property avalon_slave addressUnits WORDS
set_interface_property avalon_slave associatedClock clock
set_interface_property avalon_slave associatedReset reset
set_interface_property avalon_slave bitsPerSymbol 8
set_interface_property avalon_slave burstOnBurstBoundariesOnly false
set_interface_property avalon_slave burstcountUnits WORDS
set_interface_property avalon_slave explicitAddressSpan 0
set_interface_property avalon_slave holdTime 0
set_interface_property avalon_slave linewrapBursts false
set_interface_property avalon_slave maximumPendingReadTransactions 0
set_interface_property avalon_slave maximumPendingWriteTransactions 0
set_interface_property avalon_slave readLatency 0
set_interface_property avalon_slave readWaitTime 1
set_interface_property avalon_slave setupTime 0
set_interface_property avalon_slave timingUnits Cycles
set_interface_property avalon_slave writeWaitTime 0
set_interface_property avalon_slave ENABLED true
set_interface_property avalon_slave EXPORT_OF ""
set_interface_property avalon_slave PORT_NAME_MAP ""
set_interface_property avalon_slave CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave avs_address address Input 5
add_interface_port avalon_slave avs_read read Input 1
add_interface_port avalon_slave avs_readdata readdata Output 32
add_interface_port avalon_slave avs_write write Input 1
add_interface_port avalon_slave avs_writedata writedata Input 32
set_interface_assignment avalon_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave embeddedsw.configuration.isPrintableDevice 0


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

add_interface_port export pwm_out pwm Output PWM_CHANNEL
add_interface_port export dsm_out dsm Output PWM_CHANNEL


#
# Validation callback
#
proc validate {} {

	#
	# Software assignments for system.h
	#
	set_module_assignment embeddedsw.CMacro.CHANNEL [get_parameter_value PWM_CHANNEL]
	set_module_assignment embeddedsw.CMacro.FREQ [get_parameter_value CLOCKFREQ]

}
