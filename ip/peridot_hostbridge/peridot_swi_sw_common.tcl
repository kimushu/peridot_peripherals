#
# PERIDOT SWI driver (Common part for separated and hostbridge-based)
# Copyright (C) 2017 @kimu_shu and J-7SYSTEM WORKS
#

set_sw_property auto_initialize true
set_sw_property bsp_subdirectory drivers

set_sw_property isr_preemption_supported true
set_sw_property supported_interrupt_apis "legacy_interrupt_api enhanced_interrupt_api"

# Source files
add_sw_property c_source HAL/src/peridot_swi.c
add_sw_property include_source HAL/inc/peridot_swi.h
add_sw_property include_source inc/peridot_swi_regs.h

# Supported BSP types
add_sw_property supported_bsp_type HAL
add_sw_property supported_bsp_type UCOSII
add_sw_property supported_bsp_type TINYTH

# Settings
