# ***************************************************************************
# GpibOpen
# ***************************************************************************
proc GpibOpen {} {
  return [ViOpen]
}
# ***************************************************************************
# ViOpen 
# ***************************************************************************
proc ViOpen {} {
  global gaSet
  set ret -1
  package require tclvisa
  # #set visaAddr [visa::find $rm "USB0?*"]
  set id 1
  if 1 {
  foreach field3 [list 6023 6023 6023 6023 6023 6023 6023 903 903 903 6023 903] \
      DSOX1102ASerNumber [list CN58064160 CN57344642 CN56404126 CN58064279 \
      CN56404116 CN58174246 CN59014296 CN60182123 CN60182353 CN61022152\
      CN59284320 CN61482385] {
    puts "field3:$field3 DSOX1102ASerNumber:$DSOX1102ASerNumber"
    set visaAddr "USB0::10893::[set field3]::[set DSOX1102ASerNumber]::INSTR"
    if [catch { set rm.$id [visa::open-default-rm] } rc] {
    # puts "Error opening default resource manager\n$rc"
    }
  
    if [catch { set gaSet(vi.$id) [visa::open [set rm.$id] $visaAddr] } rc] {
      close [set rm.$id]
      puts "Error opening instrument `$visaAddr`\n$rc"
      set ret -1
    } else {
      set ret 0
      puts "A id:$id OK"
      set ::DsScope A
      incr id
      #break
    }
  }
  if {$ret=="-1"} {
    foreach DSOX1102BSerNumber [list CN54030447 ] {
      puts "DSOX1102BSerNumber:$DSOX1102BSerNumber"
      set visaAddr "USB0::2391::1416::[set DSOX1102BSerNumber]::0"
      if [catch { set rm.$id [visa::open-default-rm] } rc] {
        puts "Error opening default resource manager\n$rc"
      }
    
      if [catch { set gaSet(vi.$id) [visa::open [set rm.$id] $visaAddr] } rc] {
        close $rm
        puts "Error opening instrument `$visaAddr`\n$rc"
        set ret -1
      } else {
        set ret 0
        puts "B id:$id OK"
        set ::DsScope B
        break
      }
    }
  }
  }
  
  
  #puts ""; update  
  
  if {$ret=="-1"} {
    return -1
  } 
  
  set gaSet(rm.0) [set rm.0]
  set gaSet(rm.1) [set rm.1]
  ViSet "*cls"
  return 0
}

# ***************************************************************************
# GpibClose
# ***************************************************************************
proc GpibClose {} {
  return [ViCloseInstruments]
}
# ***************************************************************************
# ViClose
# ***************************************************************************
proc _ViClose {} {
  global gaSet
  foreach id {0 1} {
    close $gaSet(vi.$id)
    close $gaSet(rm.$id)
    unset  gaSet(vi.$id)
    unset  gaSet(rm.$id)
  }  
}


# ***************************************************************************
# ViSet
# ***************************************************************************
proc ViSet {scp cmd} {
  global gaSet
  puts $gaSet(vi.id.$scp) "$cmd" 
}

# ***************************************************************************
# ViGet
# ***************************************************************************
proc ViGet {scp cmd res} {
  global gaSet buffer
  upvar $res buff
  ViSet $scp $cmd
  set buff [gets $gaSet(vi.id.$scp)]
}
# ***************************************************************************
# ExistTds520B
# ***************************************************************************
proc ExistTds520B {} {
  return [ExistDSOX1102A]
}
# ***************************************************************************
# ExistDSOX1102A
# ***************************************************************************
proc ExistDSOX1102A {} {
  global gaSet 
  foreach id {0 1} {
    catch {ViGet $id "*idn?" buffer} err
    if {[string match "*DSO-X 1102A*" $buffer]==0} {
      set gaSet(fail) "Wrong scope-$id identification - $buffer (expected DSO-X 1102A)"
      #return -1
    }
  }
  return 0
}
proc DefaultTds520b {} {
  return [DefaultDSOX1102A]
}
# ***************************************************************************
# DefaultDSOX1102A
# ***************************************************************************
proc DefaultDSOX1102A {} {
  global gaSet
  foreach scp {0 1} {
    Status "Set the Scope $gaSet(vi.scp$scp.SN) to default"
    ViSet $scp "*cls"
    ClearDSOX1102A $scp
    fconfigure $gaSet(vi.id.$scp) -timeout 500
    ViSet $scp ":aut"
  }  
  return {}
}
# ***************************************************************************
# ClearDSOX1102A
# ***************************************************************************
proc ClearDSOX1102A {scp} {
  global gaSet
  Status "Clear Scope $gaSet(vi.scp$scp.SN)"
  ViSet $scp :disp:cle
  ViSet $scp ":chan1:disp 0"
  ViSet $scp ":chan2:disp 0"
}


# ***************************************************************************
# SetLockClkTds
# ***************************************************************************
proc SetLockClkTds {} {
  global gaSet
  set scp $gaSet(scpSyncE.scp)
  set sn $gaSet(vi.scp$scp.SN)
  Status "Set Scope $scp $sn Lock Clock test"
  
  
  #GpibSet "select:control ch1"
  ViSet $scp ":chan1:disp 1"
  ViSet $scp ":chan2:disp 1"
  
  ViSet $scp ":trig:mode edge"
  ViSet $scp ":trig:edge:source chan1"
  ViSet $scp ":trig:edge:lev 15" ; # 1.5
  ViSet $scp ":trig:edge:coup dc"
#   ViSet ":trig:edge:slope neg" ; #21/11/2018 13:49:28
  ViSet $scp ":trig:edge:slope pos"
  ViSet $scp ":trig:force"
#   GpibSet "data:source CH1"
  ViSet $scp ":chan1:prob 10"
  ViSet $scp ":chan2:prob 10"
  #ViSet ":chan2:range 200V"
  ViSet $scp ":chan1:coup dc"
#   ViSet ":chan1:offs 25V"
  ViSet $scp ":chan2:coup dc"
#   ViSet ":chan2:offs -25V"
  ViSet $scp ":tim:scal 1E-7" ; #2.5E-7
  after 1000
  ViSet $scp ":acq:type norm"
}

# ***************************************************************************
# ChkLockClkTds
# ***************************************************************************
proc ChkLockClkTds {} {
  global gaSet
  set scp $gaSet(scpSyncE.scp)
  puts "Get Scope $scp : Lock clock test"
  set gaSet(fail) ""
#   GpibSet "select:ch1 on"
#   GpibSet "select:control ch1"
  Status "Check freq at CH1"
  ViSet $scp ":meas:freq chan1"
#   GpibSet "measurement:meas1:state on"
   after 100
  ViGet $scp ":meas:freq?" freq1
  puts "freq1:<$freq1>" ; update
  if {[expr $freq1]>2060000 || [expr $freq1]<2030000} {
    set gaSet(fail) "Ch-1 is not 2.048MHz frequency (found [expr $freq1])"
    return -1
  }
  
  Status "Check freq at CH2"
#   GpibSet "select:ch2 on"
#   GpibSet "select:control ch2"
  ViSet $scp ":meas:freq chan2"
#   GpibSet "measurement:meas2:state on"
   after 100
  ViGet $scp ":meas:freq?" freq2
  puts "freq2:<$freq2>" ; update
  if {[expr $freq2]>2060000 || [expr $freq2]<2030000} {
    set gaSet(fail) "Ch-2 is not 2.048MHz frequency (found [expr $freq2])"
    return -1
  }
  
  ViSet $scp ":tim:scal 5E-8"
  after 1000
  Status "Check edges"
  set checks 100
  set maxTry 3 
  
  if {$::DsScope=="A"} {
    for {set try 1} {$try <= $maxTry} {incr try} {
      puts "\n [MyTime] Try:$try"; update
      set ret -1
      set minch1 [set maxch1 [ViGet $scp ":meas:tedge? +1, chan1" te]]
      set minch2 [set maxch2 [ViGet $scp ":meas:tedge? +1, chan2" te]]
      ViSet $scp ":meas:del chan1,chan2"
      set mindel [set maxdel 0]
      for {set i 1} {$i<=$checks} {incr i} {
        ## example p374
        foreach ch {1 2} {
          ViGet $scp ":meas:tedge? +1, chan$ch" te
          if {$te<[set minch$ch] && $te!=""} {
            set minch[set ch] $te
          }
          if {$te>[set maxch$ch] && $te!=""} {
            set maxch[set ch] $te
          }
          set de [expr {[set maxch$ch] - [set minch$ch]}]
          #puts "try:$try i:$i minch$ch:[set minch$ch] maxch$ch:[set maxch$ch] de:$de" ; update
          after 50
        } 
      }
      puts "try:$try minch1:$minch1 maxch1:$maxch1 minch2:$minch2 maxch2:$maxch2"
      
      set ret 0
      foreach ch {2 1} {
        if {$ret ne "0"} {break}
        set de [expr {[set maxch$ch] - [set minch$ch]}]
        set delta [2nano [expr {[set maxch$ch] - [set minch$ch]}]]
        puts "[MyTime] try:$try ch-$ch delta:$delta nSec de:$de"
        AddToPairLog $gaSet(pair) "Delta: $delta ns"
        if {$delta>100} {
          set ret -1
          set gaSet(fail) "The CH-$ch is not stable"
          if {$try eq $maxTry} {
            return -1
          }  
          continue
        } else {
          set ret 0
        }
        if {$ret eq "0"} {
          if {$delta>30} {
            set ret -1
            set gaSet(fail) "The Jitter at CH-$ch more then 30nSec ($delta nSec)"
            if {$try eq $maxTry} {
              return -1
            }
            continue
          } else {
            set ret 0
            break
          }
        }
      }
      if {$ret==0} {break}
    }
    puts "[MyTime] After Try:$try ret:$ret"
  } elseif {$::DsScope=="B"} {
    for {set i 1} {$i<=7} {incr i} {
      ViGet $id ":MEASure:PDELay? ch1,ch2" te
      regsub -all {<} $te "" te
      if {$te!="9.9e+037"} {
        set minPdly [set maxPdly $te]
        break
      }
      after 250  
    }
    puts "i:$i"
      
    after 100
    
    ViSet $scp ":meas:del chan1,chan2"
    after 100
    for {set i 1} {$i<=$checks} {incr i} {
      ViGet $scp ":MEASure:PDELay? ch1,ch2" te
      regsub -all {<} $te "" te
      #puts $te
      if {($te<$minPdly) && ($te!="") && ($te!="9.9e+037") } {
        set minPdly $te
      }
      if {($te>$maxPdly) && ($te!="") && ($te!="9.9e+037")} {
        set maxPdly $te
      }
      if {($i==10)||($i==20)||($i==30)||($i==40)||($i==50)||\
            ($i==60)||($i==70)||($i==80)||($i==90)||($i==100)} {
          puts "Delta Meas($i): \t Min--> $minPdly \t Max--> $maxPdly" ; update
      }
      after 50
    }
  
    # Jitter Result:
    set delta [2nano [expr {$maxPdly - $minPdly}]]
    puts "[MyTime] Jitter:  $delta nSec"
    if {$delta>100} {
      puts stderr "CH-2 Signal not stable"
      set gaSet(fail) "CH-2 Signal not stable" ; update
      return -1
    }
    if {$delta>30} {
      set gaSet(fail) "The Jitter at CH-2 more then 30nSec ($delta nSec)"
      puts stderr "CH2 Jitter is  more then 30nSec"
      set gaSet(fail) "CH2 Jitter is  more then 30nSec" ; update
      return -1
    }
    set ret 0
  }
  update 
  
  return $ret
}

# ***************************************************************************
# 2nano
# ***************************************************************************
proc 2nano {tim} {
  #puts "2nano $tim"
  #foreach {b ex} [split [string toupper $tim] E] {}
  foreach {b ex} [split [string toupper [format %E $tim ]] E] {}
  switch -exact -- $ex {
    -002 - -02 - -2 {set m 10000000}
    -003 - -03 - -3 {set m 1000000}
    -004 - -04 - -4 {set m 100000}
    -005 - -05 - -5 {set m 10000}
    -006 - -06 - -6 {set m 1000}
    -007 - -07 - -7 {set m 100}
    -008 - -08 - -8 {set m 10}
    -009 - -09 - -9 {set m 1}
    -010 - -10 {set m 0.1}
    -011 - -11 {set m 0.01}
    -012 - -12 {set m 0.001}
    default    {set m $ex}
  }
  set ret [expr {$b*$m}]
  puts "2nano $tim $ret"
  return $ret
}

# ***************************************************************************
# CheckJitter
# ***************************************************************************
proc CheckJitter {stam} {
  ## performed by ChkLockClkTds
  return 0
}
# ***************************************************************************
# Set1PpsTds
# ***************************************************************************
proc Set1PpsTds {} {
  global gaSet
  set scp $gaSet(scp1PPS.scp)
  set sn $gaSet(vi.scp$scp.SN)
  puts "Set Scope $scp $sn : 1PPS test"
  
  ViSet $scp ":meas:cle"
  ViSet $scp ":chan1:disp 1"
  ViSet $scp ":chan2:disp 0"
  ViSet $scp ":chan1:range 50V"
  ViSet $scp ":chan1:offs 0V"
  ViSet $scp ":trig:edge:lev 0" ; # 1.5
  ViSet $scp ":trig:edge:coup dc"
  ViSet $scp ":trig:edge:slope pos"
  ViSet $scp ":trig:force"
  ViSet $scp ":chan1:prob 10"
  ViSet $scp ":chan1:coup dc"
  ViSet $scp ":tim:scal 50E-2" ; #2.5E-7
  ViSet $scp ":meas:freq chan1"
  ViSet $scp ":meas:vpp chan1"
  ViSet $scp ":meas:duty chan1"
  after 1000
  ViSet $scp ":acq:type norm"
}
# ***************************************************************************
# Chk1PpsTds
# ***************************************************************************
proc Chk1PpsTds {} {
  global gaSet
  set scp $gaSet(scp1PPS.scp)
  set sn $gaSet(vi.scp$scp.SN)
  Status "Check 1PPS at Scope $scp $sn"
  #Status "Get Scope $scp : 1PPS test"
  set gaSet(fail) ""
  
  #puts "Set Scope $scp $sn : 1PPS test"
  #ViSet $scp ":meas:freq chan1"
  after 2000
  set ret 0
  for {set i 1} {$i<=3} {incr i} {
    puts "\n[MyTime] Get Scope $scp : 1PPS test $i"
    if {$ret=="-1"} {after 1000}
    ViGet $scp ":meas:res?" res1; puts $res1
    set resList [split $res1 ,]
    set fr1 [lindex $resList [expr {1 + [lsearch $resList "Frequency(1)"] }] ]
    set exprfr1 [expr $fr1]
    #set ptp1 [lindex $resList [expr {1 + [lsearch $resList "Pk-Pk(1)"] }] ]
    #set exprptp1 [expr $ptp1]
    set dt1 [lindex $resList [expr {1 + [lsearch $resList "Duty(1)"] }] ]
    set exprdt1 [expr $dt1]
    #puts "fr1:<$fr1> exprfr1:<$exprfr1> ptp1:<$ptp1> exprptp1:<$exprptp1> dt1:<$dt1> exprdt1:<$exprdt1>" ; update
    puts "fr1:<$fr1> exprfr1:<$exprfr1> dt1:<$dt1> exprdt1:<$exprdt1>" ; update
    
    if {$exprfr1=="9.9e+37"} {
      after 1000
      continue
    }
    set max 1.001
    set min 0.999
    if {$exprfr1>$max || $exprfr1<$min} {
      set gaSet(fail) "1PPS port: $exprfr1 Hz"
      set ret -1
    } else {
      set ret 0
    }
    
    # if {$ret==0} {
      # set max 2.8
      # set min 2.6
      # if {$exprptp1>$max || $exprptp1<$min} {
        # set gaSet(fail) "1PPS port: $exprptp1 V"
        # set ret -1
      # } else {
        # set ret 0
      # }
    # }
    
    if {$ret==0} {
      set max 50.1
      set min 49.9
      if {$exprdt1>$max || $exprdt1<$min} {
        set gaSet(fail) "1PPS port: $exprdt1 %"
        set ret -1
      } else {
        set ret 0
      }
    }
    
  }
  AddToPairLog $gaSet(pair) "$exprfr1 Hz, $exprdt1 \%"
  if {$exprfr1=="9.9e+37"} {
    set ret -1
    set gaSet(fail) "1PPS port: $exprfr1"
  }
  puts "gaSet(fail):<$gaSet(fail)>"
  return $ret
}

# ***************************************************************************
# ReadExistScops
# ***************************************************************************
proc ReadExistScops {mode} {
  puts "ReadExistScops $mode"
  global gaSet gaGui
  package require tclvisa
  
  ViCloseInstruments
  after 1000
  
  foreach scp {0 1} {
    $gaGui(labSc$scp) configure -text ""  -bd 0
  } 
  update
  
  if [catch {set rm [visa::open-default-rm]} rc] {
    set gaSet(fail) "Open RM to Tcl_VISA fail ($rc)"
    return -1
  }
  set gaSet(rm) $rm 
  set visaAddrList [visa::find $rm "USB0?*"] 
  puts "ReadExistScops visaAddrList:<$visaAddrList>"  
  set gaSet(visaAddrList) $visaAddrList
  foreach scp {0 1} {
    set gaSet(vi.addr.$scp) [lindex $visaAddrList $scp]
    set gaSet(vi.scp$scp.SN) [lindex [split [lindex $visaAddrList $scp] "::"] 6]
    if {$gaSet(vi.scp$scp.SN)!=""} {
      $gaGui(labSc$scp) configure -text $gaSet(vi.scp$scp.SN) -bd 2
    }
  }
  
  set ret 0
  if {$mode=="start" && [llength $visaAddrList]!=2} {
    DialogBox -icon images/error -message "Not both Scopes are connected" -type Ok
    set ret -1
  }
  return $ret
}

# ***************************************************************************
# ViOpenInstruments
# ***************************************************************************
proc ViOpenInstruments {} {
  global gaSet gaGui
  set ret 0
  set ret [ReadExistScops start]
  if {$ret=="-1"} {
    set gaSet(fail) "ReadExistScops fail"
    AddToPairLog $gaSet(pair) $gaSet(fail)
    return $ret
  }
  set ::DsScope A
  foreach scp {0 1} {
    if [catch {set gaSet(vi.id.$scp) [visa::open $gaSet(rm) [lindex $gaSet(visaAddrList) $scp]] } rc] {
      puts "ViOpenInstruments scp:<$scp> rc:<$rc>"
      set ret -1
      set gaSet(fail) "Open Scope $gaSet(vi.scp${scp}.SN) fail ($rc)"
      break
    } 
  }
  ParseScp
  if {$ret=="-1"} {
    AddToPairLog $gaSet(pair) $gaSet(fail)
  }
  return $ret
}
# ***************************************************************************
# ViCloseInstruments
# ***************************************************************************
proc ViCloseInstruments {} {
  global gaSet 
  foreach scp {0 1} {
    catch {close $gaSet(vi.id.$scp)} rc
    catch {unset gaSet(vi.id.$scp)}
    catch {unset gaSet(vi.addr.$scp)}
    catch {unset gaSet(vi.scp1.SN)}
  }
  catch {close $gaSet(rm)}
  catch {unset gaSet(rm)}
  catch {unset gaSet(scp1PPS.vi)}
  catch {unset gaSet(scpSyncE.vi)}
  catch {unset gaSet(visaAddrList)}
  
  return 0
}
# ***************************************************************************
# ParseScp
# ***************************************************************************
proc ParseScp {} {
  global gaSet
  puts "ParseScp"
  if {$gaSet(scp0)=="SyncE"} {
    set gaSet(scpSyncE.vi) $gaSet(vi.id.0)
    set gaSet(scp1PPS.vi) $gaSet(vi.id.1)
    set gaSet(scpSyncE.scp) 0
    set gaSet(scp1PPS.scp)  1
  } elseif {$gaSet(scp1)=="SyncE"} {
    set gaSet(scpSyncE.vi) $gaSet(vi.id.1)
    set gaSet(scp1PPS.vi) $gaSet(vi.id.0)
    set gaSet(scpSyncE.scp) 1
    set gaSet(scp1PPS.scp)  0
  }
  parray gaSet *vi*
}

