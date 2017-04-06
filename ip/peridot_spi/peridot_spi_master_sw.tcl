#
# PERIDOT SPI driver (master)
# Copyright (C) 2016 @kimu_shu
#

create_driver peridot_spi_master_driver

set_sw_property hw_class_name peridot_spi_master
set_sw_property min_compatible_hw_version 1.0
set_sw_property version 1.1

set_sw_property auto_initialize true
set_sw_property bsp_subdirectory drivers

set_sw_property isr_preemption_supported true
set_sw_property supported_interrupt_apis "legacy_interrupt_api enhanced_interrupt_api"

# Source files
add_sw_property c_source HAL/src/peridot_spi_master.c
add_sw_property include_source HAL/inc/peridot_spi_master.h
add_sw_property include_source inc/peridot_spi_regs.h

# Supported BSP types
add_sw_property supported_bsp_type HAL
add_sw_property supported_bsp_type UCOSII

# Callbacks for settings
set_sw_property callback_source_file peridot_spi_master_cb.tcl
set_sw_property initialization_callback initialize

# End of file
