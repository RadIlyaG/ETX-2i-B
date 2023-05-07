# set pair [lindex $argv 0]
# set gaSet(pair) $pair

switch -exact -- $gaSet(pair) {
  1 {
      set gaSet(comDut)     2
      set gaSet(comAux1)    4
      set gaSet(comAux2)    5
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"}         
  }
  
}  
source lib_PackSour_2iB_PTP.tcl
