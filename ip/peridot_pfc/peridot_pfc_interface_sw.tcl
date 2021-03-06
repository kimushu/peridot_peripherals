#
# PERIDOT Pin function controller driver
# Copyright (C) 2016 @kimu_shu
#

create_driver peridot_pfc_interface

set_sw_property hw_class_name peridot_pfc_interface
set_sw_property min_compatible_hw_version 1.0
set_sw_property version 1.0

set_sw_property auto_initialize true
set_sw_property bsp_subdirectory drivers

# Source files
add_sw_property c_source HAL/src/peridot_pfc_interface.c
add_sw_property include_source HAL/inc/peridot_pfc_interface.h
add_sw_property include_source inc/peridot_pfc_interface_regs.h

# Supported BSP types
add_sw_property supported_bsp_type HAL
add_sw_property supported_bsp_type UCOSII

# End of file
