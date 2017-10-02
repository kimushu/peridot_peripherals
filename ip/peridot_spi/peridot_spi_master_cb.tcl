#
# PERIDOT SPI driver (master) - callback module
# Copyright (C) 2016 @kimu_shu
#

proc initialize { args } {
	# Add SPI driver instance macro
	set name [ get_module_name ]
	set mod [ string toupper $name ]
	add_module_systemh_line DRIVER_INSTANCE "({ extern peridot_spi_master_state $name; &$name; })"

	# Add SPI_FLASH_BOOT_AFTER_CFG (except for MAX10)
	set deviceFamily [ get_module_assignment DEVICE_FAMILY ]
	if { $deviceFamily != "MAX 10" } {
		set name flash_boot.after_cfg
		add_class_sw_setting $name boolean_define_only
		set_class_sw_setting_property $name destination system_h_define
		set_class_sw_setting_property $name identifier PERIDOT_SPI_FLASH_BOOT_AFTER_CFG
		set_class_sw_setting_property $name default_value 0
		set_class_sw_setting_property $name description "Load ELF image after FPGA configuration data"
	}
}

proc generate { args } {
	set inst [ lindex [ split [ get_driver [ lindex $args 0 ] ] : ] 0 ]
	set bspdir [ lindex $args 1 ]
	set subdir [ lindex $args 2 ]
	set deviceFamily [ get_module_assignment DEVICE_FAMILY ]

	if { [ get_setting $inst.flash.enable ] != "true" } {
		if { [ get_setting $inst.flash_boot.enable ] == "true" } {
			puts "WARNING: SPI flash feature must be enabled to use SPI flash boot"
		}
		return 0
	}

	puts "INFO: SPI flash is enabled."

	set devname [ get_setting $inst.flash.name ]
	if { $devname == [ get_module_name ] } {
		# Set instance name for SPI flash
		add_class_systemh_line INSTANCE [ string toupper $devname ]

		# Calculate clkdiv for SPI flash
		set clock [ get_module_assignment embeddedsw.CMacro.FREQ ]
		set bitrate [ get_setting $inst.flash.bitrate ]
		set clkdiv [ expr int(ceil($clock / 2.0 / $bitrate) - 1) ]
		if { $clkdiv < 1 } {
			set clkdiv 1
		}
		set actual [ expr $clock / (($clkdiv + 1) * 2) ]
		if { $bitrate != $actual } {
			puts "WARNING: SPI flash will be driven at $actual bps"
		}
		add_module_systemh_line FLASH_CLKDIV ($clkdiv)
	}

	set mkfile $bspdir/flash_boot_gen.mk
	set example "include $(BSP_ROOT_DIR)/flash_boot_gen.mk"

	if { [ get_setting $inst.flash_boot.enable ] != "true" } {
		if { [ file exists $mkfile ] } {
			puts "WARNING: SPI flash boot has been disabled."
			puts "WARNING: Please remove `$example' line from your Makefile!"
			file delete $mkfile
		}
		return 0
	}

	puts "INFO: SPI flash boot is enabled."

	if { [ get_section_mapping .ipl ] == "" } {
		puts "ERROR: .ipl section is required to use SPI flash boot."
		puts "ERROR: Add .ipl section in `Linker Script' page of BSP Editor."
		return -code error
	}

	puts "INFO: Please append `$example' to your Makefile."

	if { $deviceFamily == "MAX 10" } {
		set offset [ get_setting $inst.flash_boot.offset ]
	} else {
		puts "INFO: You can build ELF-embedded RBF by running `combined_rbf' target"

		if { [ get_setting $inst.flash_boot.after_cfg ] == "true" } {
			set offset "auto"
		} else {
			set offset [ get_setting $inst.flash_boot.offset ]
		}
	}

	set comp "none"
	if { [ get_setting $inst.flash_boot.decompress.lz4 ] == "true" } {
		set comp "LZ4"
	}

	set fd [ open $mkfile w ]
	puts $fd "
#########################################################################
#######          MAKEFILE FOR GENERATING FLASH BOOT FILE          #######
#########################################################################

#########################################################################
# This file is intended to be included by Makefile of each application
#
#
# The following variables must be defined before including this file:
# - ELF
# - BSP_ROOT_DIR
# - QUARTUS_PROJECT_DIR
#
# The following variables may be defined to override the default behavior:
# - RBF_FILE
# - COMBINED_RBF
#
#########################################################################

ifeq ($(RBF_FILE),)
RBF_FILE := $(firstword $(wildcard $(QUARTUS_PROJECT_DIR)/output_files/*.rbf) $(wildcard $(QUARTUS_PROJECT_DIR)/*.rbf))
endif

ifeq ($(COMBINED_RBF),)
COMBINED_RBF := $(dir $(ELF))/$(notdir $(basename $(RBF_FILE)))_$(notdir $(basename $(ELF))).rbf
endif

combined_rbf: $(COMBINED_RBF)

$(COMBINED_RBF): $(ELF) $(RBF_FILE)
	tclsh $(BSP_ROOT_DIR)/drivers/tools/flash_boot_gen.tcl -o $@ --elf $(ELF) $(addprefix --rbf ,$(RBF_FILE)) --offset $offset --compress $comp

.DELETE_ON_ERROR: $(COMBINED_RBF)

clean: flash_boot_clean

flash_boot_clean:
	@$(RM) $(COMBINED_RBF)"
	close $fd
}

# End of file
