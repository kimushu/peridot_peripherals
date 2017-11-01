#
# PERIDOT SPI driver (master)
# Copyright (C) 2016 @kimu_shu
#

create_driver peridot_spi_master_driver

set_sw_property hw_class_name peridot_spi_master
set_sw_property min_compatible_hw_version 1.0
set_sw_property version 1.2

set_sw_property auto_initialize true
set_sw_property bsp_subdirectory drivers

set_sw_property isr_preemption_supported true
set_sw_property supported_interrupt_apis "legacy_interrupt_api enhanced_interrupt_api"

# Source files
add_sw_property c_source HAL/src/peridot_spi_master.c
add_sw_property include_source HAL/inc/peridot_spi_master.h
add_sw_property include_source inc/peridot_spi_regs.h

add_sw_property c_source HAL/src/peridot_spi_flash.c
add_sw_property asm_source HAL/src/peridot_spi_flash_boot.S
add_sw_property include_source HAL/inc/peridot_spi_flash.h
add_sw_property include_source tools/flash_boot_gen.tcl
add_sw_property include_source tools/elf.tcl
add_sw_property include_source tools/lz4hc.tcl
add_sw_property include_source tools/lz4tcl.dll

# Supported BSP types
add_sw_property supported_bsp_type HAL
add_sw_property supported_bsp_type UCOSII

# Callbacks for settings
set_sw_property callback_source_file peridot_spi_master_cb.tcl
set_sw_property initialization_callback initialize
set_sw_property generation_callback generate

# Settings
add_sw_setting boolean_define_only system_h_define flash.enable PERIDOT_SPI_FLASH_ENABLE 1 "Enable flash feature"
add_sw_setting unquoted_string system_h_define flash.name PERIDOT_SPI_FLASH_NAME none "Slave descriptor for SPI flash"
add_sw_setting decimal_number system_h_define flash.slave_number PERIDOT_SPI_FLASH_SLAVE_NUMBER 0 "Slave number (SS_N bit number) for SPI flash device"
add_sw_setting decimal_number system_h_define flash.bitrate PERIDOT_SPI_FLASH_BITRATE 40000000 "Bitrate for SPI flash device"

add_sw_setting boolean_define_only system_h_define flash_boot.enable PERIDOT_SPI_FLASH_BOOT_ENABLE 0 "Enable boot from flash (hal.linker.allow_code_at_reset must be disabled)"
add_sw_setting unquoted_string system_h_define flash_boot.name PERIDOT_SPI_FLASH_BOOT_NAME none "Slave descriptor for SPI flash"
#add_sw_setting decimal_number system_h_define flash_boot.slave_number PERIDOT_SPI_FLASH_SLAVE_NUMBER 0 "Slave number (SS_N bit number) for SPI flash device"
add_sw_setting decimal_number system_h_define flash_boot.bitrate PERIDOT_SPI_FLASH_BITRATE 40000000 "Bitrate for SPI flash device"
add_sw_setting boolean_define_only system_h_define flash_boot.after_cfg PERIDOT_SPI_FLASH_BOOT_AFTER_CFG 0 "Load ELF image after FPGA configuration data (Not available in MAX10 devices)"
add_sw_setting hex_number system_h_define flash_boot.offset PERIDOT_SPI_FLASH_BOOT_OFFSET 0 "Load offset in bytes"
add_sw_setting boolean_define_only system_h_define flash_boot.decompress_lz4 PERIDOT_SPI_FLASH_BOOT_DECOMPRESS_LZ4 0 "Enable decompression with LZ4 algorithm"

# End of file
