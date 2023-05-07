# set pair [lindex $argv 0]
# set gaSet(pair) $pair
#set gaSet(javaLoc)  C:\\Program\ Files\ (x86)\\Java\\jre1.8.0_181\\bin\\
set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin\\
switch -exact -- $gaSet(pair) {
  1 {
      set gaSet(comDut)     2
      set gaSet(comGen1)    1; #8
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"}   
      set gaSet(pioBoxSerNum) FTEDK6F
  }
  2 {
      set gaSet(comDut)    5
      set gaSet(comGen1)    9
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"}          
      set gaSet(pioBoxSerNum) FTEDK6F     
  }
  3 {
      set gaSet(comDut)    6
      set gaSet(comGen1)    10
      console eval {wm geometry . +150+400}
      console eval {wm title . "Con 3"}   
      set gaSet(pioBoxSerNum) FTEDK6F
  }
  4 {
      set gaSet(comDut)    7
      set gaSet(comGen1)    11
      console eval {wm geometry . +150+600}
      console eval {wm title . "Con 4"}          
      set gaSet(pioBoxSerNum) FTEDK6F   
  }
  5 {
      set gaSet(comDut)     2
      set gaSet(comGen1)    5
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 5"}          
      set gaSet(mmuxMassPort)    1  
      set gaSet(pioBoxSerNum) FTEDK6F  
  }
}  
source lib_PackSour_Etx2iB.tcl
