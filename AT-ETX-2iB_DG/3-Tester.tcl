if ![file exists [info host]] {
  file mkdir [info host]
  foreach f [glob -directory tmpInits -nocomplain *.tcl] {
    file copy -force $f [info host]/[file tail $f]
  }
}
package require RLTime
#console show
RLTime::Delay 1

puts   "[info nameofexecutable] [info host]/HWinit.tcl 3 f"
exec [info nameofexecutable] [info host]/HWinit.tcl 3 f &
#console show
exit
    
