#
# PERIDOT SWI driver
# Copyright (C) 2017 @kimu_shu and J-7SYSTEM WORKS
#

create_driver peridot_swi_driver

set_sw_property hw_class_name peridot_hostbridge
set_sw_property min_compatible_hw_version 16.1
set_sw_property version 16.1

source "[ file dirname $argv0 ]/peridot_swi_sw_common.tcl"

add_sw_property include_source HAL/inc/peridot_hostbridge.h

# End of file
