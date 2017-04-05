proc class_generation { args } {
	set inst [ lindex $args 0 ]
	set bspdir [ lindex $args 1 ]
	set subdir [ lindex $args 2 ]

	set mkfile $bspdir/flash_boot_gen.mk
	set example "include $(BSP_ROOT_DIR)/flash_boot_gen.mk"

	if { [ get_setting $inst.flash_boot.enable ] != "true" } {
		if { [ file exists $mkfile ] } {
			puts "WARNING: SWI flash boot has been disabled."
			puts "WARNING: Please remove `$example' line from your Makefile!"
			file delete $mkfile
		}
		return 0
	}

	puts "INFO: SWI flash boot is enabled."

	if { [ get_section_mapping .ipl ] == "" } {
		puts "ERROR: .ipl section is required to use SWI flash boot."
		puts "ERROR: Add .ipl section in `Linker Script' page of BSP Editor."
		return -code error
	}

	puts "INFO: Please append `$example' to your Makefile."
	puts "INFO: You can build ELF-embedded RBF by running `combined_rbf' target"

	if { [ get_setting $inst.flash_boot.after_cfg ] == "true" } {
		set offset "auto"
	} else {
		set offset [ get_setting $inst.flash_boot.offset ]
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
