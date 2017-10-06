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

proc compare_small_files { file1 file2 } {
    if { [ catch { open $file1 } fd ] } {
        return 1
    }
    fconfigure $fd -translation binary
    set data1 [ read $fd ]
    close $fd
    if { [ catch { open $file2 } fd ] } {
        return 1
    }
    fconfigure $fd -translation binary
    set data2 [ read $fd ]
    close $fd
    return [ string compare $data1 $data2 ]
}

proc copy_from_spi { path } {
    set root [ file dirname $::argv0 ]
    file mkdir [ file dirname $root/$path ]
    set path1 $root/../peridot_spi/$path
    set path2 $root/$path
    if { [ compare_small_files $path1 $path2 ] } {
        puts "INFO: Copying $path from peridot_spi"
        file copy -force $path1 $path2
    }
    return $path
}
add_sw_property c_source [ copy_from_spi HAL/src/peridot_spi_flash.c ]
add_sw_property asm_source [ copy_from_spi HAL/src/peridot_spi_flash_boot.S ]
add_sw_property include_source [ copy_from_spi HAL/inc/peridot_spi_flash.h ]
add_sw_property include_source [ copy_from_spi tools/flash_boot_gen.tcl ]
add_sw_property include_source [ copy_from_spi tools/elf.tcl ]
add_sw_property include_source [ copy_from_spi tools/lz4hc.tcl ]

# Supported BSP types
add_sw_property supported_bsp_type HAL
add_sw_property supported_bsp_type UCOSII
add_sw_property supported_bsp_type TINYTH

# Callbacks
set_sw_property callback_source_file ../peridot_spi/peridot_spi_master_cb.tcl
set_sw_property generation_callback generate

# Settings
add_sw_setting boolean_define_only system_h_define flash.enable PERIDOT_SWI_FLASH_ENABLE 1 "Enable flash feature"

add_sw_setting boolean_define_only system_h_define flash_boot.enable PERIDOT_SWI_FLASH_BOOT_ENABLE 0 "Enable boot from flash (hal.linker.allow_code_at_reset must be disabled)"
add_sw_setting boolean_define_only system_h_define flash_boot.after_cfg PERIDOT_SPI_FLASH_BOOT_AFTER_CFG 0 "Load ELF image after FPGA configuration data (Not available in MAX10 devices)"
add_sw_setting hex_number system_h_define flash_boot.offset PERIDOT_SPI_FLASH_BOOT_OFFSET 0 "Load offset in bytes"
add_sw_setting boolean_define_only system_h_define flash_boot.decompress_lz4 PERIDOT_SPI_FLASH_BOOT_DECOMPRESS_LZ4 0 "Enable decompression with LZ4 algorithm"
