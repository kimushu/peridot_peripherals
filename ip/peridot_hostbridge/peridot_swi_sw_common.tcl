#
# PERIDOT SWI driver (Common part for separated and hostbridge-based)
# Copyright (C) 2017 @kimu_shu and J-7SYSTEM WORKS
#

set_sw_property auto_initialize true
set_sw_property bsp_subdirectory drivers

set_sw_property isr_preemption_supported true
set_sw_property supported_interrupt_apis "legacy_interrupt_api enhanced_interrupt_api"

set_sw_property callback_source_file peridot_swi_cb.tcl
set_sw_property initialization_callback initialize
set_sw_property generation_callback generate

# Source files
add_sw_property c_source HAL/src/peridot_swi.c
add_sw_property c_source HAL/src/peridot_swi_flash.c
add_sw_property asm_source HAL/src/peridot_swi_flash_boot.S
add_sw_property include_source HAL/inc/peridot_swi.h
add_sw_property include_source inc/peridot_swi_regs.h
add_sw_property include_source tools/flash_boot_gen.tcl
add_sw_property include_source tools/elf.tcl
add_sw_property include_source tools/lz4hc.tcl

# Supported BSP types
add_sw_property supported_bsp_type HAL
add_sw_property supported_bsp_type UCOSII
add_sw_property supported_bsp_type TINYTH

# Settings
add_sw_setting boolean_define_only system_h_define flash_boot.enable SWI_FLASH_BOOT_ENABLE 0 "Enable boot from flash (ALT_ALLOW_CODE_RESET must be disabled)"
#add_sw_setting boolean_define_only system_h_define flash_boot.after_cfg SWI_FLASH_BOOT_AFTER_CFG 0 "Load ELF image after FPGA configuration data"
add_sw_setting hex_number system_h_define flash_boot.offset SWI_FLASH_BOOT_OFFSET 0 "Load offset in bytes"
#add_sw_setting boolean_define_only system_h_define flash_boot.decompress.lzss SWI_FLASH_BOOT_DECOMPRESS_LZSS 0 "Enable decompression with LZSS algorithm"
add_sw_setting boolean_define_only system_h_define flash_boot.decompress.lz4 SWI_FLASH_BOOT_DECOMPRESS_LZ4 0 "Enable decompression with LZ4 algorithm"

