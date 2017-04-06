#
# PERIDOT Servo driver
# Copyright (C) 2017 @kimu_shu
#

create_driver peridot_servo_driver

set_sw_property hw_class_name peridot_servo
set_sw_property min_compatible_hw_version 1.0
set_sw_property version 1.1

set_sw_property auto_initialize true
set_sw_property bsp_subdirectory drivers

# Source files
add_sw_property c_source HAL/src/peridot_servo.c
add_sw_property include_source HAL/inc/peridot_servo.h
add_sw_property include_source inc/peridot_servo_regs.h

# Supported BSP types
add_sw_property supported_bsp_type HAL

# End of file
