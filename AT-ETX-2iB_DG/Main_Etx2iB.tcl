proc BuildTests {} {
  global gaSet gaGui glTests
  
  if {![info exists gaSet(DutInitName)] || $gaSet(DutInitName)==""} {
    puts "\n[MyTime] BuildTests DutInitName doesn't exists or empty. Return -1\n"
    return -1
  }
  puts "\n[MyTime] BuildTests DutInitName:$gaSet(DutInitName)\n"
  
  RetriveDutFam 
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set lTestsAllTests [list]
  set lDownloadTests [list Format SetDownload Download]
  if {$gaSet(enDownloadsBefore)==1} {
    eval lappend lTestsAllTests $lDownloadTests
  }
  if {$gaSet(radTsts)=="Full"} {
    set lTestNames [list SetToDefault PS_ID DyingGaspConf DyingGaspTest_1\
      DataTransmissionConf DataTransmissionSFP \
      SetToDefaultAll Mac_BarCode]     ; # dtsfp RtrConf RtrArp RtrData mac    LedsAlm
  } elseif {$gaSet(radTsts)=="SkipDG"} {
    set lTestNames [list SetToDefault PS_ID \
      DataTransmissionConf DataTransmissionSFP \
      SetToDefaultAll Mac_BarCode  ] ; #LedsAlm    
  } elseif {$gaSet(radTsts)=="OnlyDG"} {
    set lTestNames [list  DyingGaspConf DyingGaspTest_1 SetToDefaultAll]
  }    
  eval lappend lTestsAllTests $lTestNames
  ## next lines remove DataTransmissionConf and DataTransmissionTest
  foreach t $lTestNames {
    if ![string match DataTr* $t] {
     lappend lTestsTestsWithoutDataRun $t
    }
  }
    
  set glTests ""
  set gaSet(TestMode) AllTests
  set lTests [set lTests$gaSet(TestMode)]
  
#   if {$gaSet(defConfEn)=="1"} {
#     lappend lTests LoadDefaultConfiguration
#   }
  
  for {set i 0; set k 1} {$i<[llength $lTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTests $i]"
  }
  
  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests
  
}
# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests gaGui
  AddToLog "********* DUT: $gaSet(DutFullName) *********"
  MassConnect NC
  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  puts "\n 01. lRunTests:<$lRunTests> glTests:<$glTests>" ; update
  set lPassPair [list]
  file delete -force tmpFiles/passPair-$gaSet(pair).tcl
  set passPairID [open tmpFiles/passPair-$gaSet(pair).tcl a+]
  puts -nonewline $passPairID "set lPassPair \[list"
  close $passPairID
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   if {[string match {*Leds*} $gaSet(startFrom)] || [string match {*Mac_BarCode*} $gaSet(startFrom)]} {
#     set ret 0
#   }
  
  puts "\n Before LedsEth. lRunTests:<$lRunTests> glTests:<$glTests>" ; update
  
  foreach pair [PairsToTest] {
    #if {$gaSet(act)==0} {return -2}
    
    if {$gaSet(act)==0} {break}
    
    if {[lsearch [PairsToTest] $pair]=="-1"} {
      continue
    }
      
    set ::pair $pair
    puts "\n\n ********* DUT $pair start *********..[MyTime].."

    Status "DUT start"
    set gaSet(curTest) ""
    update
    
    AddToLog "********* DUT $pair start *********"
    
    PairPerfLab $pair yellow
    MassConnect $pair
  }  
     
    puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"

    foreach numberedTest $lRunTests {
      set gaSet(curTest) $numberedTest
      puts "\n **** Test $numberedTest start; [MyTime] "
      update
        
      set testName [lindex [split $numberedTest ..] end]
      $gaSet(startTime) configure -text "$startTime ."
      AddToLog "Test \'$testName\' start"
      puts "\n **** DUT ${pair}. Test $numberedTest start; [MyTime] "
      $gaSet(runTime) configure -text ""
      update
      
      set ret [$testName 1]
      #set ret 0 ; puts "$testName" ; update
      
      
  
      if {$ret==0} {
        set retTxt "PASS."              
      } else {
        set retTxt "FAIL. Reason: $gaSet(fail)"        
      }
      AddToLog "Test \'$testName\' $retTxt"
       
      puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
      update
      if {$ret!=0} {
        break
      }
      if {$gaSet(oneTest)==1} {
        set ret 0
        set gaSet(oneTest) 0
        break
      }
    }
    
    for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
      if {[$gaGui(labPairPerf$i) cget -bg]!="yellow"} {
        continue
      }  
      if {[$gaGui(labPairPerf$i) cget -bg]!="red"} {
        PairPerfLab $i green
      } elseif {[$gaGui(labPairPerf$i) cget -bg]=="red"} {
        ## if at least one lab is red, the common ret is -1
        set ret -1
      }
    }
    if {$ret==0} {      
      set passPairID [open tmpFiles/passPair-$gaSet(pair).tcl a+]
      puts -nonewline $passPairID " $pair"
      close $passPairID
      set retTxt PASS
      set logText "All tests pass"
    } else {
      set logText "Test $numberedTest fail. Reason: $gaSet(fail)" 
      PairPerfLab $pair red
      set retTxt FAIL
    }
              
   
    if {$gaSet(pair)=="5"} {
      puts "********* DUT $pair finish *********..[MyTime]..\n\n"
      AddToLog "$logText \n    ********* DUT $pair $retTxt   *********\n"
    } else {
      puts "********* DUT $gaSet(pair) finish *********..[MyTime]..\n\n"
      AddToLog "$logText \n    ********* DUT $gaSet(pair) $retTxt   *********\n"
    }
    
    if {$gaSet(nextPair)=="begin"} {
      set gaSet(oneTest) 0
    } elseif {$gaSet(nextPair)=="same"} {
      ## do nothing
    }      
  
  
  set gaSet(oneTest) 0
  set passPairID [open tmpFiles/passPair-$gaSet(pair).tcl a+]
  puts -nonewline $passPairID "\]"
  close $passPairID
  
  source tmpFiles/passPair-$gaSet(pair).tcl
  set lPassPair [lsort -unique -dict $lPassPair]
  puts "lPassPair:<$lPassPair>, llength $lPassPair:[llength $lPassPair]"
  
  if {$gaSet(act)==0} {return -2}
  
#   set retLed 0
#   if {[llength $lPassPair]>0} {
#     set ledsIndx [lsearch -glob $glTests *LedsAlm]
#     set gaSet(curTest) [lindex $glTests $ledsIndx]
#     AddToLog "********* Leds Test start *********"  
#     ##foreach pair $lPassPair {}
#     if {$gaSet(act)==0} {return -2}
#     #AddToLog "Pair:$pair Leds Test start"  
#     set res [LedsAlmTst $lPassPair]   
#     if {$res!=0} {
#       set retLed $res
#       set retTxt FAIL 
#       foreach pair $lPassPair { 
#         PairPerfLab $pair red
#       }
#     } elseif {$res==0} {
#       foreach pair $lPassPair { 
#         PairPerfLab $pair green
#       }
#       set retTxt PASS
#     }
#     
#     if {$gaSet(pair)=="5"} {
#       AddToLog "Pairs:$lPassPair. Leds Test finish. Result: $res"
#     } else {
#       AddToLog "Pair:$gaSet(pair). Leds Test finish. Result: $res"
#     }
#     if {$gaSet(act)==0} {return -2}
#       
#     
#     AddToLog "********* Leds Test finish *********"
#   }
#   
#   if {$ret==0 && $retLed==0} {
#     set ret 0
#   } else {
#     set ret -1
#   }
  AddToLog "********* TEST FINISHED  *********" 
  puts "RunTests4 ret:$ret gaSet(startFrom):$gaSet(startFrom)"   
  return $ret
}

# ***************************************************************************
# USBport
# ***************************************************************************
proc USBport {run} {
  global gaSet
  set ret 0
   ### 13/07/2016 15:06:43 6.0.1 reads the USB port without a special app
#   set ret [EntryBootMenu]
#   if {$ret=="-1"} {
#     set ret [EntryBootMenu]
#   }
#   if {$ret!=0} {return $ret}
#   
#   set ret [DownloadUsbPortApp]
#   if {$ret!=0} {return $ret}
  
  set ret [CheckUsbPort]
  if {$ret!=0} {return $ret}
  
#   set ret [EntryBootMenu]
#   if {$ret!=0} {return $ret}
#   
#   set ret [DeleteUsbPortApp]
#   if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# FansTemperature
# ***************************************************************************
proc FansTemperature {run} {
  global gaSet
  Power all on
  set ret [FansTemperatureTest]
  return $ret
}

# ***************************************************************************
# PS_ID
# ***************************************************************************
proc PS_ID {run} {
  global gaSet
  Power all on
  set ret [PS_IDTest]
  return $ret
}

# ***************************************************************************
# SK_ID
# ***************************************************************************
proc SK_ID {run} {
  global gaSet
  Power all on
  set ret [SK_IDTest]
  return $ret
}

# ***************************************************************************
# DyingGaspConf
# ***************************************************************************
proc DyingGaspConf {run} {
  global gaSet
  Power all on
  set ret [DyingGaspSetup]
  return $ret
}
# ***************************************************************************
# DyingGaspTest_1
# ***************************************************************************
proc DyingGaspTest_1 {run} {
  global gaSet gaGui
  Power all on
  for {set tri 1} {$tri<=1} {incr tri} {
    for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
      if {[$gaGui(labPairPerf$i) cget -bg]=="red"} {
        PairPerfLab $i yellow
      }
    }  
  
    if {$gaSet(act)==0} {return -2}
    Status "DyingGasp trial $tri"
    set ret [DyingGaspPerf 1 2]
    AddToLog "Result of DyingGasp trial $tri : <$ret> "
    puts "[MyTime] Ret of DyingGasp trial $tri : $ret" ; update
    if {$ret==0} {break}
  }  
  return $ret
}
# ***************************************************************************
# DyingGaspTest_2
# ***************************************************************************
proc DyingGaspTest_2 {run} {
  global gaSet gRelayState
  Power all on
  set ret [DyingGaspPerf 2 1]
  if {$ret!=0} {return $ret}
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$ps=="DC"} {
    Power all off
    set gRelayState red
    IPRelay-LoopRed
    SendEmail "ETX-2I" "Manual Test"
    RLSound::Play information
    set txt "Remove the AC PSs and insert DC PSs"
    set res [DialogBox -type "OK Cancel" -icon /images/question -title "Change PS" -message $txt]
    update
    if {$res!="OK"} {
      return -2
    } else {
      set ret 0
    }
    Power all on
    set gRelayState green
    IPRelay-Green
  }
  return $ret
}

# ***************************************************************************
# XFP_ID
# ***************************************************************************
proc XFP_ID {run} {
  global gaSet
  Power all on
  set ret [XFP_ID_Test]
  return $ret
}  

# ***************************************************************************
# SfpUtp_ID
# ***************************************************************************
proc SfpUtp_ID {run} {
  global gaSet
  Power all on
  set ret [SfpUtp_ID_Test]
  return $ret
} 
# ***************************************************************************
# DateTime
# ***************************************************************************
proc DateTime {run} {
  global gaSet
  Power all on
  set ret [DateTime_Test]
  return $ret
} 

# ***************************************************************************
# DataTransmissionConf
# ***************************************************************************
proc DataTransmissionConf {run} {
  global gaSet
  Power all on
     
  #ConfigEtxGen
#   Status "EtxGen::GenConfig"
#   foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
#   if {$b=="19V"} {
#     set packRate 50000
#   } else {
#     set packRate 1200000
#   }
#   RLEtxGen::GenConfig $gaSet(idGen1) -updGen all -packRate $packRate
  InitEtxGen 1    
  set ret [DataTransmissionSetup]
    
  return $ret
} 
# ***************************************************************************
# DataTransmissionTest
# ***************************************************************************
proc DataTransmissionUTP {run} {
  global gaSet
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b!="19"} {}
    set ret [ForceMode $b rj45]
    if {$ret!=0} {return $ret}
    Wait "Wait for RJ45 mode" 15
    ## 13/07/2016 13:43:05 1/3 and 1/4 have been added
    if {$b=="19"} {
      set portsL [list 0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8]
    } elseif {$b=="19V"} {
      set portsL [list 0/1 0/2 0/3 0/4 1/1 1/2]
    } else {
      set portsL [list 1012/1]
    }
    foreach port $portsL {
      set ret [ReadEthPortStatus $port]
      if {$ret=="-1" || $ret=="-2"} {return $ret}
      if {$ret!="RJ45"} {
        set gaSet(fail) "The $ret in port $port is active instead of RJ45"
        return -1
      }
    }
  #{}
#   set ret [AdminSave]
#   if {$ret!=0} {return $ret}
#   Power all off
#   after 1000
#   Power all on
    
  if {$b=="19V"} {
    set packRate 50000
  } else {
    set packRate 1200000
  }  
  Status "EtxGen::GenConfig -packRate $packRate"
  RLEtxGen::GenConfig $gaSet(idGen1) -updGen all -packRate $packRate
  
  if {$b=="19V"} {
    set ret [DnfvCross on] 
    if {$ret!=0} {return $ret}  
  }  
  
  set ret [ShutDown 0/1 "shutdown"]
  if {$ret!=0} {return $ret}
  
  after 2000
  
  set ret [ShutDown 0/1 "no shutdown"]
  if {$ret!=0} {return $ret}
  after 2000
  
  set ret [ShutDown 0/1 "no shutdown"]
  if {$ret!=0} {return $ret}
  
  set ret [DataTransmissionTestPerf [list 1 2] $packRate]
  if {$ret==0} {
    DnfvCross off
  }  
  return $ret
}
# ***************************************************************************
# DataTransmissionSFP
# ***************************************************************************
proc DataTransmissionSFP {run} {
  global gaSet gRelayState
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
 
  if {$b=="RJIO"} { 
    set portL [list 0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8 0/9 0/10]
  }  
  
  ## for Ronen it is not enough good test 
#   set ret [ReadEthPortsStatus $portL]
#   if {$ret!=0} {return $ret}   
  
  ## done in PS_ID test
#   foreach port $portL {
#     set ret [ReadEthPortStatus $port]
#     if {$ret=="-1" || $ret=="-2"} {return $ret}
#     
#   }
#   set ret [AdminSave]
#   if {$ret!=0} {return $ret}
  
  
  if {$b=="RJIO"} {
    set packRate 1000000
  } else {
    ## meantime
    set packRate 1000000
  }
  Status "EtxGen::GenConfig -packRate $packRate"
  RLEtxGen::GenConfig $gaSet(idGen1) -updGen all -packRate $packRate
  
  set ret [DataTransmissionTestPerf [list 1 2] $packRate]  
  if {$ret=="-2"} {return $ret} 
  if {$ret=="-1"} {
    set ret [DataTransmissionTestPerf [list 1 2] $packRate]
  }
  return $ret
}
# ***************************************************************************
# DataTransmissionTestPerf
# ***************************************************************************
proc DataTransmissionTestPerf {lGens packRate} {
  global gaSet
  Power all on 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
#   if {$b=="19V"} {
#     set packRate 50000
#   } else {
#     set packRate 1200000
#   }
  set ret [Wait "Waiting for stabilization" 10 white]
  if {$ret!=0} {return $ret}
  
  Etx204Start
  set ret [Wait "Data is running" 10 white]
  if {$ret!=0} {return $ret}
  set ret [Etx204Check $lGens $packRate]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Data is running" 120 white]
  if {$ret!=0} {return $ret}
  
  set ret [Etx204Check $lGens $packRate]
  if {$ret!=0} {return $ret}
 
  return $ret
}  
# ***************************************************************************
# ExtClkUnlocked
# ***************************************************************************
proc ExtClkUnlocked {run} {
  global gaSet
  Power all on
  set ret [ExtClkTest Unlocked]
  return $ret
}
# ***************************************************************************
# ExtClkLocked
# ***************************************************************************
proc ExtClkLocked {run} {
  global gaSet
  Power all on
  set ret [ExtClkTest Locked]
  return $ret
}
# ***************************************************************************
# ExtClk
# ***************************************************************************
proc ExtClk {run} {
  global gaSet
  Power all on
  set ret [ExtClkTest Unlocked]
  if {$ret!=0} {return $ret}
  set ret [ExtClkTest Locked]
  return $ret
}
# ***************************************************************************
# LedsEth
# ***************************************************************************
proc noLedsEth {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  
  foreach pair $lPassPair {
    MassConnect $pair
    set ret [LedsEthTst $pair]
    if {$ret!=0} {return $ret}
  }
  
  return $ret
}  
# ***************************************************************************
# LedsEth
# ***************************************************************************
proc LedsEthTst {uut} {
  global gaSet gaGui gRelayState
  Status ""
  puts "[MyTime] LedsEthTst $uut"; update
  Power all on
  
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX-2I" "Manual Test"
  
  #catch {set pingId [exec ping.exe 10.10.10.1[set gaSet(pair)] -t &]}
  
  RLSound::Play information
#   set txt "On UUT-$uut verify that:\n\
#   GREEN \'PWR\' led is ON\n\
#   RED \'TST/ALM\' led is ON or blinking\n\
#   GREEN \'LINK\' and ORANGE \'ACT\' leds of \'MNG-ETH\' are ON\n\
#   GREEN \'LINK/ACT\' leds of ports are ON or blinking"
  set txt "On UUT-$uut verify that:\n\
  GREEN \'LINK\' and ORANGE \'ACT\' leds of \'MNG-ETH\' are ON"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  
  #catch {exec pskill.exe -t $pingId}
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    set ret -1
  } else {
    set ret 0    
  }
  puts "ret of LedsEthTst UUT-$uut : <$ret>"
  return $ret
}  
# ***************************************************************************
# LedsAlmTst
# ***************************************************************************
proc LedsAlmTst {lPassPair} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  
  foreach uut $lPassPair {
    MassConnect $uut
    set ret [Loopback on $uut]
    if {$ret!=0} {return $ret}
  }
  RLSound::Play information
  set txt "Verify on unit/s $lPassPair:\n\
  RED \'TST/ALM\' led is blinking"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  
  #catch {exec pskill.exe -t $pingId}
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    set ret -1
  } else {
    set ret 0
  }
  puts "ret of LedsAlmTst <$lPassPair> : <$ret>"; update
  return $ret
}  
# ***************************************************************************
# Leds
# ***************************************************************************
proc Leds {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  
  set ret [Loopback on]
  if {$ret!=0} {return $ret}
  
#   if {$gaSet(TestMode)!="AllTests"} {
#     ## full configuration for LINKs' led
#     set cf $gaSet($gaSet(10G)CF) 
#     set cfTxt "$gaSet(10G)XFP"
#     set ret [DownloadConfFile $cf $cfTxt 0]
#     if {$ret!=0} {return $ret}
#     
#     ## DyingGasp for pings
#     set cf $gaSet(dgCF)
#     set cfTxt "Dying Gasp"
#     set ret [DownloadConfFile $cf $cfTxt 1]
#     if {$ret!=0} {return $ret}
#   }
  
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX-2I" "Manual Test"
  
  #catch {set pingId [exec ping.exe 10.10.10.1[set gaSet(pair)] -t &]}
  
  RLSound::Play information
  set txt "Verify that:\n\
  GREEN \'PWR\' led is ON\n\
  RED \'TST/ALM\' led is blinking\n\
  GREEN \'LINK\' and ORANGE \'ACT\' leds of \'MNG-ETH\' are ON\n\
  GREEN \'LINK/ACT\' leds of ports are blinking"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  
  #catch {exec pskill.exe -t $pingId}
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  set ret [Loopback off]
  if {$ret!=0} {return $ret} 
  
  return 0
  
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
#   set gaSet(fail) "Logon fail"
#   set com $gaSet(comDut)
#   Send $com "exit all\r" stam 0.25 
  
  foreach ps {2 1} {
    Power $ps off
    after 3000
    set val [ShowPS $ps]
    puts "val:<$val>"
    if {$val=="-1"} {return -1}
    if {$val!="Failed"} {
      set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Failed\""
#       AddToLog $gaSet(fail)
      return -1
    }
    RLSound::Play information
    set txt "Verify on PS-$ps that GREEN led is OFF"
    set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "LED Test failed"
      return -1
    } else {
      set ret 0
    }
    
    RLSound::Play information
    set txt "Remove PS-$ps and verify that led is OFF"
    set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "PS_ID Test failed"
      return -1
    } else {
      set ret 0
    }
    
    set val [ShowPS $ps]
    puts "val:<$val>"
    if {$val=="-1"} {return -1}
    if {$val!="Not exist"} {
      set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
#       AddToLog $gaSet(fail)
      return -1
    }
    
#     RLSound::Play information
#     set txt "Verify on PS $ps that led is OFF"
#     set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#     update
#     if {$res!="OK"} {
#       set gaSet(fail) "LED Test failed"
#       return -1
#     } else {
#       set ret 0
#     }
    
    RLSound::Play information
    set txt "Assemble PS-$ps"
    set res [DialogBox -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "PS_ID Test failed"
      return -1
    } else {
      set ret 0
    }
    Power $ps on
    after 2000
  }
  
#   RLSound::Play information
#   set txt "Verify EXT CLK's GREEN SD led is ON"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$p=="P"} {
    RLSound::Play information
    set txt "Remove the EXT CLK cable and verify the SD led is OFF"
    set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "LED Test failed"
      return -1
    } else {
      set ret 0
    }
  }
 
  set ret [TstAlm off]
  if {$ret!=0} {return $ret} 
  RLSound::Play information
  set txt "Verify the TST/ALM led is OFF"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  
  RLSound::Play information
  set txt "Disconnect all cables and optic fibers and verify GREEN leds are off"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  
#   set ret [TstAlm on]
#   if {$ret!=0} {return $ret} 
#   RLSound::Play information
#   set txt "Verify the TST/ALM led is ON"
#   set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
#   update
#   if {$res!="OK"} {
#     set gaSet(fail) "LED Test failed"
#     return -1
#   } else {
#     set ret 0
#   }
  
  
  return $ret
}
# ***************************************************************************
# SetToDefault
# ***************************************************************************
proc SetToDefault {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault std 20]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefaultAll
# ***************************************************************************
proc SetToDefaultAll {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda 2]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# Mac_BarCode
# ***************************************************************************
proc Mac_BarCode {run} {
  global gaSet  
  set pair $::pair 
  puts "Mac_BarCode \"$pair\" "
  mparray gaSet *mac* ; update
  mparray gaSet *barcode* ; update
  set badL [list]
  set ret -1
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit)] {
      set ret [ReadMac]
      if {$ret!=0} {return $ret}
    } else {
      set ret 0
    }  
  } 
  #set ret [ReadBarcode [PairsToTest]]
  #set ret [ReadBarcode]
  if {$ret!=0} {return $ret}
  #set ret [RegBC [PairsToTest]]
  set ret [RegBC $pair]
      
  return $ret
}

# ***************************************************************************
# LoadDefaultConfiguration
# ***************************************************************************
proc LoadDefaultConfiguration {run} {
  global gaSet  
  Power all on
  set ret [LoadDefConf]
  return $ret
}
# ***************************************************************************
# DDR
# ***************************************************************************
proc DDR {run} {
  global gaSet
  Power all on
  set ret [DdrTest]
  return $ret
}
# ***************************************************************************
# DryContact
# ***************************************************************************
proc DryContact {run} {
  global gaSet
  Power all on
  set ret [DryContactTest]
  return $ret
}
# ***************************************************************************
# RtrConf
# ***************************************************************************
proc RtrConf {run} {
  global gaSet
  Power all on
  set ret [FactDefault stda 20]
  if {$ret!=0} {return $ret}
  set ret [RtrSetup]
  return $ret
} 
# ***************************************************************************
# DataTransmissionSFP
# ***************************************************************************
proc RtrArp {run} {
  global gaSet
  #ConfigEtxGen
  Status "EtxGen::GenConfig"
  set id $gaSet(idGen1) 
  RLEtxGen::GenConfig $id -updGen all -packRate 10
  ## -payload should have digits and low case letters!
  RLEtxGen::PacketConfig $id MAC -updGen 1 -SA 000000000001 -DA FFFFFFFFFFFF \
      -payload 0001080006040001000000000001010101010000000000000101010a \
      -ethType 0806 
  RLEtxGen::PacketConfig $id MAC -updGen 2 -SA 000000000002 -DA FFFFFFFFFFFF \
      -payload 0001080006040001000000000002020202010000000000000202020a \
      -ethType 0806  
      
  return [ShowArpTable]   
}
# ***************************************************************************
# RtrData
# ***************************************************************************
proc RtrData {run} {
  global gaSet
  #ConfigEtxGen
  Status "EtxGen::GenConfig"
  set id $gaSet(idGen1) 
  RLEtxGen::GenConfig $id -updGen all -packRate 20000
  
  set da1 [ReadPortMac 0/1]
  if {$da1=="-1" || $da1=="-2"} {
    return $da1
  }
  set da2 [ReadPortMac 0/2]
  if {$da2=="-1" || $da2=="-2"} {
    return $da2
  }
  ## -payload should have digits and low case letters!
  RLEtxGen::PacketConfig $id MAC -updGen 1 -SA 000000000001 -DA $da1 \
      -payload [string tolower 4500001400000000FFFDB4E801010101020202010000000000000000] \
      -ethType 0800 
  RLEtxGen::PacketConfig $id MAC -updGen 2 -SA 000000000002 -DA $da2 \
      -payload [string tolower 4500001400000000FFFDB4E802020201010101010000000000000000] \
      -ethType 0800  
      
  return [DataTransmissionTestPerf [list 1 2] 20000] 
}      
 
# ***************************************************************************
# BIOS
# ***************************************************************************
proc BIOS {run} {
  Power all off
  
  RLSound::Play information
  set txt "Insert DiskOnKey with rad.bat programm (MAC) and press OK"
  set res [DialogBox -type "OK Cancel" -icon /images/question \
      -title "Burn MAC" -message $txt -aspect 2000]
  update
  if {$res=="Cancel"} {
    return -2
  }
  
  Power all on
  return [BiosTest]
}
# ***************************************************************************
# BurnMAC
# ***************************************************************************
proc BurnMAC {run} {
  set ret [BurnMacTest]
  return $ret
}

# ***************************************************************************
# SoftwareDownload
# ***************************************************************************
proc SoftwareDownload {run} {
  Power all off
  
  RLSound::Play information
  set txt "Insert DiskOnKey with application and press OK"
  set res [DialogBox -type "OK Cancel" -icon /images/question \
      -title "Burn MAC" -message $txt -aspect 2000]
  update
  if {$res=="Cancel"} {
    return -2
  }
  
  Power all on
  
  set ret [SoftwareDownloadTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# MacSwID
# ***************************************************************************
proc MacSwID {run} {
   set ret [MacSwIDTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
