#--------------------------------------------------------------------------------
# ELF utility
#--------------------------------------------------------------------------------

proc ELF_read_file { path } {
	set fd [ open $path r ]
	fconfigure $fd -translation binary
	set bin [ read $fd ]
	close $fd
	ELF_read $bin
}

proc ELF_read { bin } {
	set EH_SIZE 0x34
	set ELFMAG 0x464c457f
	set EM_ALTERA_NIOS2 113
	set SHT_STRTAB 3
	set SHF_ALLOC [ expr (1 << 1) ]

	# Read file header
	binary scan [ string range $bin 0 [ expr $EH_SIZE - 1 ] ] i4ssiiiiissssss \
		idt typ mac ver ent pho sho flg ehs phs phn shs shn ssx
	if { [ lindex $idt 0 ] != $ELFMAG || $mac != $EM_ALTERA_NIOS2 } {
		puts stderr "Error: Not a valid ELF file for NiosII"
		exit 1
	}
	array set ehdr [ list \
		e_ident     $idt \
		e_type      $typ \
		e_machine   $mac \
		e_version   $ver \
		e_entry     $ent \
		e_phoff     $pho \
		e_shoff     $sho \
		e_flags     $flg \
		e_ehsize    $ehs \
		e_phentsize $phs \
		e_phnum     $phn \
		e_shentsize $shs \
		e_shnum     $shn \
		e_shstrndx  $ssx \
	]

	# Read section header string table
	set tmp [ expr $ehdr(e_shoff) + \
		$ehdr(e_shentsize) * $ehdr(e_shstrndx) ]
	binary scan \
		[ string range $bin $tmp [ expr $tmp + $ehdr(e_shentsize) - 1 ] ] \
		iiiiiiiiii \
		nam typ flg adr ofs siz lnk inf aln esz
	if { $typ == $SHT_STRTAB } {
		set shstrtab [ string range $bin $ofs [ expr $tmp + $siz - 1 ] ]
	} else {
		set shstrtab {}
	}

	# Read section headers (only sections with SHF_ALLOC)
	set shlist [ list ]
	for { set i 0 } { $i < $ehdr(e_shnum) } { incr i } {
		set tmp [ expr $ehdr(e_shoff) + $ehdr(e_shentsize) * $i ]
		binary scan \
			[ string range $bin $tmp [ expr $tmp + $ehdr(e_shentsize) - 1 ] ] \
			iiiiiiiiii \
			nam typ flg adr ofs siz lnk inf aln esz
		if { !($flg & $SHF_ALLOC) } { continue }

		set npos [ string first "\0" $shstrtab $nam ]
		if { $npos < 0 } { continue }
		set str [ string range $shstrtab $nam [ expr $npos - 1 ] ]
		lappend shlist [ list \
			name    $str \
			sh_addr $adr \
			sh_size $siz \
		]
	}

	puts stderr "Info: Reading ELF with program headers:"
	puts stderr "Info:   Type       Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align"

	# Read program headers
	set phlist [ list ]
	lappend phlist [ array get ehdr ]
	for { set i 0 } { $i < $ehdr(e_phnum) } { incr i } {
		set tmp [ expr $ehdr(e_phoff) + $ehdr(e_phentsize) * $i ]
		binary scan \
			[ string range $bin $tmp [ expr $tmp + $ehdr(e_phentsize) - 1 ] ] \
			iiiiiiii \
			typ off vad pad fsz msz flg aln

		# Search included sections
		set sec {}
		for { set j 0 } { $j < [ llength $shlist ] } { incr j } {
			set tmp [ lindex $shlist $j ]
			array set shdr $tmp
			if { ($vad <= $shdr(sh_addr)) \
				&& ($shdr(sh_addr) < ($vad + $msz)) } {
				lappend sec $tmp
			}
		}

		# Report
		puts stderr [ format \
			"Info:   0x%08x 0x%06x 0x%08x 0x%08x 0x%05x 0x%05x 0x%x 0x%x" \
			$typ $off $vad $pad $fsz $msz $flg $aln ]

		# Store data
		lappend phlist [ list \
			p_type   $typ \
			p_offset $off \
			p_vaddr  $vad \
			p_paddr  $pad \
			p_filesz $fsz \
			p_memsz  $msz \
			p_flags  $flg \
			p_align  $aln \
			content  [ string range $bin $off [ expr $off + $fsz - 1 ] ] \
			sections $sec \
			discard  0
		]
	}

	return $phlist
}

proc ELF_remove_sections { varName sections } {
	upvar $varName phlist
	set phlen [ llength $phlist ]
	for { set i 1 } { $i < $phlen } { incr i } {
		array set phdr [ lindex $phlist $i ]
		if { $phdr(discard) } { continue }

		set sec $phdr(sections)
		set slen [ llength $sec ]
		set modified 0
		for { set j [ expr $slen - 1 ] } { $j >= 0 } { incr j -1 } {
			array set shdr [ lindex $sec $j ]
			if { [ lsearch $sections $shdr(name) ] >= 0 } {
				puts stderr [ format \
					"Info: Removing %s section from segment %02u" \
					$shdr(name) [ expr $i - 1 ] ]
				set sec [ lreplace $sec $j $j ]
				set modified 1
			}
		}
		if { $modified } {
			set phdr(sections) $sec
			set phlist [ lreplace $phlist $i $i [ array get phdr ] ]
		}
	}
}

proc ELF_strip { varName } {
	set PT_LOAD   1
	set PT_LOOS   0x60000000
	set PT_LOCOMP 0x63700000
	set PT_HICOMP 0x6370ffff
	set PT_HIOS   0x6fffffff
	set PT_COMP_MASK 0xff

	upvar $varName phlist
	set phlen [ llength $phlist ]
	for { set i 1 } { $i < $phlen } { incr i } {
		array set phdr [ lindex $phlist $i ]
		if { $phdr(discard) } { continue }

		set pt $phdr(p_type)
		set dropReason {}

		if { ($PT_LOCOMP <= $pt) && ($pt <= $PT_HICOMP) } {
			if { ($pt & $PT_COMP_MASK) != $PT_LOAD } {
				set dropReason "compressed, non LOAD"
			}
		} elseif { $pt != $PT_LOAD } {
			set dropReason "Non LOAD"
		} elseif { $phdr(p_filesz) == 0 } {
			set dropReason "No data"
		} else {
			# Non-compressed LOAD segment
			set vmin 0x7fffffff
			set vmax 0
			set sec $phdr(sections)
			set slen [ llength $sec ]
			for { set j 0 } { $j < $slen } { incr j } {
				array set shdr [ lindex $sec $j ]
				set vsta $shdr(sh_addr)
				set vend [ expr $vsta + $shdr(sh_size) ]
				if { $vsta < $vmin } { set vmin $vsta }
				if { $vend > $vmax } { set vmax $vend }
			}
			if { $vmax <= $vmin } {
				# No valid sections in this segment
				set dropReason "No sections"
			} elseif { $phdr(p_filesz) != $phdr(p_memsz) } {
				# Cannot process segments with mismatch size
			} elseif { ($phdr(p_vaddr) < $vmin) \
				|| ($vmax < ($phdr(p_vaddr) + $phdr(p_memsz))) } {
				# Segment can be trimmed
				puts stderr [ format "Info: Shrinking segment %02u" \
					[ expr $i - 1 ] ]
				set diff [ expr $vmin - $phdr(p_vaddr) ]
				set size [ expr $vmax - $vmin ]
				incr phdr(p_vaddr) $diff
				incr phdr(p_paddr) $diff
				set phdr(p_filesz) $size
				set phdr(p_memsz) $size
				set phdr(content) [ string range $phdr(content) $diff \
					[ expr $diff + $size - 1 ] ]
				# Update
				set phlist [ lreplace $phlist $i $i [ array get phdr ] ]
			}
		}
		if { $dropReason != "" } {
			# Drop segment
			set phdr(discard) 1
			set phlist [ lreplace $phlist $i $i [ array get phdr ] ]
			puts stderr [ format \
				"Info: Marked segment %02u as discarded (%s)" \
				[ expr $i - 1 ] $dropReason ]
		}
	}
}

proc ELF_compact { varName procName type } {
	set PT_NULL 0
	set PT_NUM 8

	upvar $varName phlist
	set phlen [ llength $phlist ]
	for { set i 1 } { $i < $phlen } { incr i } {
		array set phdr [ lindex $phlist $i ]
		if { $phdr(discard) } { continue }

		if { ($phdr(p_type) == $PT_NULL) \
			|| ($phdr(p_type) >= $PT_NUM) \
			|| ($phdr(p_filesz) == 0) } {
			# Skip this segment
			continue
		}

		# Make filler
		set filler [ string repeat { } [ expr $phdr(p_memsz) - $phdr(p_filesz) ] ]

		# Try compression
		set result [ $procName $phdr(content)$filler ]
		set newlen [ string length $result ]
		if { ($newlen == 0) || ($newlen >= $phdr(p_filesz)) } {
			# Compression error / Enlarged by compression :-(
			continue
		}

		puts stderr [ format \
			"Info: Segment %02u has been compressed (%u -> %u bytes)" \
			[ expr $i - 1 ] $phdr(p_filesz) $newlen ]

		# Update
		set phdr(p_type) [ expr $type + $phdr(p_type) ]
		set phdr(p_filesz) $newlen
		set phdr(content) $result
		set phlist [ lreplace $phlist $i $i [ array get phdr ] ]
	}
}

proc ELF_write_file { varName path } {
	upvar $varName phlist
	set fd [ open $path w ]
	fconfigure $fd -translation binary
	puts -nonewline $fd [ ELF_write phlist ]
	close $fd
}

proc ELF_write { varName } {
	set EH_SIZE 0x34
	set PH_SIZE 0x20
	set SH_SIZE 0x28

	upvar $varName phlist
	set phlen [ llength $phlist ]

	# Count available segments
	set phnum 0
	for { set i 1 } { $i < $phlen } { incr i } {
		array set phdr [ lindex $phlist $i ]
		if { !$phdr(discard) } { incr phnum }
	}

	# Write file header
	array set ehdr [ lindex $phlist 0 ]
	set bin_ehdr [ binary format i4ssiiiiissssss \
		$ehdr(e_ident) \
		$ehdr(e_type) \
		$ehdr(e_machine) \
		$ehdr(e_version) \
		$ehdr(e_entry) \
		$EH_SIZE \
		0 \
		$ehdr(e_flags) \
		$EH_SIZE \
		$PH_SIZE \
		$phnum \
		$SH_SIZE \
		0 \
		0 \
	]

	puts stderr "Info: Writing ELF with program headers:"
	puts stderr "Info:   Type       Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align"

	set bin_phdr {}
	set bin_body {}

	# Write program headers and contents
	set doffset [ expr $EH_SIZE + $PH_SIZE * $phnum ]
	for { set i 1 } { $i < $phlen } { incr i } {
		array set phdr [ lindex $phlist $i ]
		if { $phdr(discard) } { continue }

		# Write header
		set bin_phdr $bin_phdr[ binary format iiiiiiii \
			$phdr(p_type) \
			$doffset \
			$phdr(p_vaddr) \
			$phdr(p_paddr) \
			$phdr(p_filesz) \
			$phdr(p_memsz) \
			$phdr(p_flags) \
			$phdr(p_align) \
		]

		# Report
		puts stderr [ format \
			"Info:   0x%08x 0x%06x 0x%08x 0x%08x 0x%05x 0x%05x 0x%x 0x%x" \
			$phdr(p_type) $doffset $phdr(p_vaddr) $phdr(p_paddr) \
			$phdr(p_filesz) $phdr(p_memsz) $phdr(p_flags) $phdr(p_align) ]

		# Write content
		set bin_body $bin_body$phdr(content)
		incr doffset $phdr(p_filesz)
		set padding [ expr 4 - ($doffset & 3) ]
		if { $padding < 4 } {
			set bin_body $bin_body[ string repeat "\0" $padding ]
			incr doffset $padding
		}
	}

	return $bin_ehdr$bin_phdr$bin_body
}

