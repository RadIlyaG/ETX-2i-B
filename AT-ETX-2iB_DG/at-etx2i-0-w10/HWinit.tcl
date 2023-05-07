set pair [lindex $argv 0]
set gaSet(pair) $pair

switch -exact -- $gaSet(pair) {

  5 {
      set gaSet(comDut1)     2 ; 
      set gaSet(comDut2)     5
      set gaSet(comDut3)     6
      set gaSet(comDut4)     7
      set gaSet(comDut5)     1
      set gaSet(comDut6)     9
      set gaSet(comDut7)     11
      set gaSet(maxUnitsQty) 7
      
      for {set un 1} {$un <= $gaSet(maxUnitsQty)} {incr un} {
        set gaSet(com2dut.$gaSet(comDut$un)) $un
      }
      
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 5"}          
      set gaSet(mmuxMassPort)    4     
  }
}  
source lib_PackSour_Etx2iB.tcl
