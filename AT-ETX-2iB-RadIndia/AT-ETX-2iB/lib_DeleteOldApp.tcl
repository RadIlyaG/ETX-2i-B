# ***************************************************************************
# DeleteOldApp
# ***************************************************************************
proc DeleteOldApp {} {
  foreach fol [glob -nocomplain -type d c:/download/*] {
    if {[string match -nocase {6.5.1(0.15)} [file tail $fol]]} {
      catch {file delete -force $fol}
    } 
    if {[string match -nocase {6.4.0(0.49)_TWC} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.6.1(0.23)} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
  }
}
# ***************************************************************************
# DeleteOldUserDef
# ***************************************************************************
proc DeleteOldUserDef {} {
#   foreach userDef [glob -nocomplain -type f C:/AT-ETX-2iB/ConfFiles/Default\ conf/*.txt] {
#     puts "userDef:<$userDef>"
#     if {[string match -nocase ETX-2IB-10x1G.TXT [file tail $userDef]]} {
#       puts "delete [file tail $userDef]"
#       catch {file delete -force $userDef}
#     } 
#     update
#   }
  file delete -force C:/AT-ETX-2iB/ConfFiles/Default\ conf/Cellcom/ETX-2IB-10x1G.TXT
}

  
