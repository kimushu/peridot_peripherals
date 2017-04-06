#
# PERIDOT SPI driver (master) - callback module
# Copyright (C) 2016 @kimu_shu
#

proc initialize { args } {
	set name [ get_module_name ]
	set mod [ string toupper $name ]
	add_module_systemh_line DRIVER_INSTANCE "({ extern peridot_spi_master_state $name; &$name; })"
}

# End of file
