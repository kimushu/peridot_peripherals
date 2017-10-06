#
# PERIDOT SPI driver (master) - callback module
# Copyright (C) 2016 @kimu_shu
#

proc initialize { args } {
	# Add SPI driver instance macro
	set name [ get_module_name ]
	set mod [ string toupper $name ]
	add_module_systemh_line DRIVER_INSTANCE "({ extern peridot_spi_master_state $name; &$name; })"
}

proc calc_clkdiv { inst bitrate name } {
	set clock [ get_module_assignment embeddedsw.CMacro.FREQ ]
	set clkdiv [ expr int(ceil($clock / 2.0 / $bitrate) - 1) ]
	if { $clkdiv < 1 } {
		set clkdiv 1
	}
	set actual [ expr $clock / (($clkdiv + 1) * 2) ]
	if { $bitrate != $actual } {
		puts "WARNING: $name will be driven at $actual Hz"
	}
	return $clkdiv
}

proc generate { args } {
	set inst [ lindex [ split [ get_driver [ lindex $args 0 ] ] : ] 0 ]
	set bspdir [ lindex $args 1 ]
	generate_flash $inst
	generate_flash_boot $inst $bspdir
}

proc generate_flash { inst } {
	if { [ get_setting $inst.flash.enable ] != "true" } {
		return
	}

	if { $inst == "peridot_swi_driver" } {
		# for SWI
		set devname [ get_module_name ]
	} else {
		# for SPI
		set devname [ get_setting $inst.flash.name ]
		if { $devname != [ get_module_name ] } {
			return
		}
	}
	add_class_systemh_line FLASH_INSTANCE $devname

	puts "INFO: SPI flash is enabled ($inst)"

	if { $inst != "peridot_swi_driver" } {
		# Calculate clkdiv for SPI flash
		set bitrate [ get_setting $inst.flash.bitrate ]
		set clkdiv [ calc_clkdiv $inst $bitrate "SPI flash" ]
		add_class_systemh_line FLASH_CLKDIV $clkdiv
	}
}

proc generate_flash_boot { inst bspdir } {
	set deviceFamily [ get_module_assignment DEVICE_FAMILY ]
	set mkfile $bspdir/flash_boot_gen.mk
	set example "include $(BSP_ROOT_DIR)/flash_boot_gen.mk"

	if { [ get_setting $inst.flash_boot.enable ] != "true" } {
		if { [ file exists $mkfile ] } {
			puts "WARNING: SPI flash boot has been disabled."
			puts "WARNING: Please remove `$example' line from your Makefile!"
			file delete $mkfile
		}
		return
	}

	if { $inst == "peridot_swi_driver" } {
		# for SWI
		set devname [ get_module_name ]
	} else {
		# for SPI
		set devname [ get_setting $inst.flash_boot.name ]
		if { $devname != [ get_module_name ] } {
			return
		}
	}
	add_class_systemh_line FLASH_BOOT_BASE [ string toupper $devname ]_BASE

	puts "INFO: SPI flash boot is enabled ($inst)"

	if { $inst != "peridot_swi_driver" } {
		# Calculate clkdiv for SPI flash boot
		set bitrate [ get_setting $inst.flash_boot.bitrate ]
		set clkdiv [ calc_clkdiv $inst $bitrate "SPI flash boot" ]
		add_class_systemh_line FLASH_BOOT_CLKDIV $clkdiv
	}

	if { [ get_section_mapping .ipl ] == "" } {
		puts "ERROR: .ipl section is required to use SPI flash boot."
		puts "ERROR: Add .ipl section in `Linker Script' page of BSP Editor."
		add_class_systemh_line FLASH_BOOT_NO_IPL 1
		return
	}

	puts "INFO: Please append `$example' to your Makefile."

	if { $deviceFamily == "MAX 10" } {
		set offset [ get_setting $inst.flash_boot.offset ]
		if { [ get_setting $inst.flash_boot.after_cfg ] == "true" } {
			puts "WARNING: $inst.flash_boot.after_cfg cannot be used in MAX10 devices. This setting is ignored."
		}
	} else {
		puts "INFO: You can build ELF-embedded RBF by running `combined_rbf' target"

		if { [ get_setting $inst.flash_boot.after_cfg ] == "true" } {
			set offset "auto"
		} else {
			set offset [ get_setting $inst.flash_boot.offset ]
		}
	}

	set comp "none"
	if { [ get_setting $inst.flash_boot.decompress_lz4 ] == "true" } {
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
QUARTUS_PROJECT_DIR_GUESS := $(firstword $(QUARTUS_PROJECT_DIR) $(dir $(SOPC_FILE)))
RBF_FILE := $(firstword $(wildcard $(QUARTUS_PROJECT_DIR_GUESS)/output_files/*.rbf) $(wildcard $(QUARTUS_PROJECT_DIR_GUESS)/*.rbf))
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
