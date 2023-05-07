set pair [lindex $argv 0]
set gaSet(pair) $pair

switch -exact -- $gaSet(pair) {
  1 {
      set gaSet(comDut)     7
      set gaSet(comGen1)    6
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"}   
      set gaSet(pioBoxSerNum) FTLVIHO 
  }
  2 {
      set gaSet(comDut)    2
      set gaSet(comGen1)   8
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"}
      set gaSet(pioBoxSerNum)  FTLVMGR         
  }
  3 {
      set gaSet(comDut)    6
      set gaSet(comGen1)    10
      console eval {wm geometry . +150+400}
      console eval {wm title . "Con 3"}
      set gaSet(pioBoxSerNum) FTEDO7R   
  }
  4 {
      set gaSet(comDut)    7
      set gaSet(comGen1)    11
      console eval {wm geometry . +150+600}
      console eval {wm title . "Con 4"}
      set gaSet(pioBoxSerNum) FTEDO7R          
  }
  5 {
      set gaSet(comDut)     2
      set gaSet(comGen1)    4
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 5"}   
      set gaSet(pioBoxSerNum) FTEDO7R         
  }
}  
source lib_PackSour_Etx2iB.tcl
