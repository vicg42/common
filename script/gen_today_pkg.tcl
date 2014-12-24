#
# gen_today_pkg.tcl - TCL script to generate a VHDL package containing
#                     constants for the current date and time.
#
# Usage: xtclsh gen_today_pkg.tcl [filename]
#

set _seconds [clock seconds]
set _datestr [clock format $_seconds -format %d/%m/%Y]
set _datevec [clock format $_seconds -format %d%m%Y]
set _timestr [clock format $_seconds -format %H:%M:%S]
set _timevec [clock format $_seconds -format %H%M%S]

puts "--"
if {[expr [llength $argv] >= 1]} {
	set _filename [lindex $argv 0]
	puts "-- ${_filename}"
}
puts "-- This file was generated automatically by gen_today_pkg.tcl"
puts "--"
puts "-- Date: ${_datestr} (dd/mm/YYYY)"
puts "-- Time: ${_timestr} (HH/MM/SS)"
puts "--"
puts ""
puts "library ieee;"
puts "use ieee.std_logic_1164.all;"
puts ""
puts "package today_pkg is"
puts ""
puts "    constant TODAYS_DATE : std_logic_vector(31 downto 0) := X\"${_datevec}\";"
puts "    constant TODAYS_TIME : std_logic_vector(31 downto 0) := X\"${_timevec}00\";"
puts ""
puts "end package today_pkg;"

return 0
