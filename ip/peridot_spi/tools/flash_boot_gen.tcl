#########################################################################
#######                 FLASH BOOT FILE GENERATOR                 #######
#########################################################################

#------------------------------------------------------------------------
# Parse options
#
array set opts $argv
set out $opts(-o)
set elf $opts(--elf)
set rbf {}
if { [ array get opts --rbf ] != "" } {
	set rbf $opts(--rbf)
	set ofs $opts(--offset)
} else {
	set ofs auto
}
set cmp $opts(--compress)

#------------------------------------------------------------------------
# Include other modules
#
set libdir [ file dirname $::argv0 ]
if { $cmp == "LZ4" } {
	source [ file join $libdir lz4hc.tcl ]
}
source [ file join $libdir elf.tcl ]

#------------------------------------------------------------------------
# RBF utilities
#
proc RBF_read_file { path } {
	set fd [ open $path r ]
	fconfigure $fd -translation binary
	binary scan [ read $fd ] b* bin
	close $fd
	binary format B* $bin
}

proc RBF_write_file { data path } {
	set fd [ open $path w ]
	fconfigure $fd -translation binary
	binary scan $data b* bin
	puts -nonewline $fd [ binary format B* $bin ]
	close $fd
}

#------------------------------------------------------------------------
# Main body
#
if { $rbf != "" } {
	puts stderr "Info: Reading RBF ($rbf) ..."
	set dest [ RBF_read_file $rbf ]
	puts stderr [ format "Info: Input RBF size = 0x%x" \
		[ string length $dest ] ]
} else {
	set dest {}
}
if { $ofs != "auto" } {
	set dlen [ string length $dest ]
	if { $dlen > $ofs } {
		puts stderr "Error: RBF is too large."
		exit 1
	}
	set dest $dest[ string repeat "\xff" [ expr $ofs - $dlen ] ]
}

puts stderr [ format "Info: ELF offset = 0x%x" \
	[ string length $dest ] ]
puts stderr "Info: Reading ELF ($elf) ..."
set elf_data [ ELF_read_file $elf ]
ELF_remove_sections elf_data { .entry .ipl }
ELF_strip elf_data
if { $cmp != "" } {
	puts stderr "Info: Compressing ELF contents ($cmp) ..."
	if { $cmp == "LZ4" } {
		set PT_LOCOMP 0x63700000
		set PT_COMP_LZ4 [ expr $PT_LOCOMP + 0x100 ]
		ELF_compact elf_data LZ4_compress $PT_COMP_LZ4
	}
}
set elf_new [ ELF_write elf_data ]
puts stderr [ format "Info: Stripped ELF size = 0x%x" \
	[ string length $elf_new ] ]
set dest $dest$elf_new

if { $rbf != "" } {
	puts stderr "Info: Writing RBF ($out) ..."
	RBF_write_file $dest $out
	puts stderr [ format "Info: Output RBF size = 0x%x" \
		[ string length $dest ] ]
} else {
	puts stderr "Info: Writing ELF ($out) ..."
	set fd [ open $out w ]
	fconfigure $fd -translation binary
	puts -nonewline $fd $dest
	close $fd
}

puts stderr \
	"Info: Flash program file ($out) has been generated successfully."
exit 0

