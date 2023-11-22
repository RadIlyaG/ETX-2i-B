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
  if {$b!="DNFV"} {
    set lDownloadTests [list BootDownload SetDownload]
    if {$gaSet(enPart1Test)==0} {
      lappend lDownloadTests Pages
    }      
    lappend lDownloadTests SoftwareDownload
    if {$gaSet(enDownloadsBefore)==1} {
      ## since the empty unit can't turn the leds on, we will skip the led test before
      ## the tests and check them after 
      set gaSet(ledsBefore) 0
      
      eval lappend lTestsAllTests $lDownloadTests
    } elseif {$gaSet(enDownloadsBefore)==0} {
      set gaSet(ledsBefore) 1
    }
  #   if {$gaSet(radTsts)=="Full"} {
  #     set lTestNames [list SetToDefault PS_ID DyingGaspConf DyingGaspTest_1\
  #       DataTransmissionConf DataTransmissionSFP \
  #       SetToDefaultAll Mac_BarCode]     ; # dtsfp RtrConf RtrArp RtrData mac    LedsAlm
  #   } elseif {$gaSet(radTsts)=="SkipDG"} {
  #     set lTestNames [list SetToDefault PS_ID \
  #       DataTransmissionConf DataTransmissionSFP \
  #       SetToDefaultAll Mac_BarCode  ] ; #LedsAlm    
  #   } elseif {$gaSet(radTsts)=="OnlyDG"} {
  #     set lTestNames [list SetToDefault DyingGaspConf DyingGaspTest_1 SetToDefaultAll]
  #   }   
  
    if {$gaSet(enPart1Test)==1} {
    
    } else {
    
      lappend lTestNames SetToDefault ID
      if {$b=="V"} {
        lappend lTestNames DnfvParameters   DnfvMacSwID DnfvHwType ; # DnfvBIOS
      }
      if {$b=="V" || $b=="2iB"} {
        if {$up=="4SFP4UTP" && $d=="D"} {
          ## don't check USB in product ETX-2I-B/H/WR/2SFP/4SFP4UTP/DRC
        } else {  
          if {$gaSet(enUsbTest)==1} {
            ## from 2020.09.17 no USB test for all options
            #lappend lTestNames USBport
          }
        }   
        if {$np eq "2SFP" && $up eq "8SFP"} {
          ## don't check DyingGasp on UUT 10 ports, 24/04/2017 08:14:39;  puts 10p
        } else {
          ## 21/04/2019 08:25:46 lappend lTestNames DyingGaspConf DyingGaspTest_1
          lappend lTestNames DyingGaspConf DyingGaspTest
        }
      }
    
      lappend lTestNames DataTransmissionConf
      if {[string match *4SFP4UTP* $up]} {
        lappend lTestNames DataTransmissionUTP ; # DataTransmissionSFP
      } elseif {[string match *SFP* $up]} {
        lappend lTestNames DataTransmissionSFP
      } elseif {[string match *UTP* $up]} {
        lappend lTestNames DataTransmissionUTP
      } elseif {[string match *CMB* $up]} {
        lappend lTestNames DataTransmissionUTP DataTransmissionSFP
      }
    
      if {$p=="P"} {
        lappend lTestNames ExtClk 
      }
    
      if {$d=="D"} {
        ## since DryContact is a manual test, I add it to the leds test 
        #lappend lTestNames DryContact      
      }
    
    ## we check RTR anyway (just not in RJIO box)  31/08/2017 
#     if {$r=="R"} {
#       lappend lTestNames RtrConf RtrArp RtrData
#     } 
# 04/04/2019 07:28:51 RTR tests are deleted from the FTI
#     if {$b!="RJIO"} {
#       lappend lTestNames RtrConf RtrArp RtrData
#     }
    
      if {$b=="2iB" && $up=="4SFP4UTP" && $d=="D" && [string match *HRC* $gaSet(DutInitName)]==0} {
        lappend lTestNames FAN
      } 
    
      lappend lTestNames SetToDefaultAll Mac_BarCode 
    
#     08/04/2019 13:53:39
#     if {$b=="RJIO" || [string match *CEL* $gaSet(DutFullName)]} {
#       lappend lTestNames LoadDefaultConfiguration
#     }
    }
    
    if {$gaSet(enSerNum) eq "1"} {
      lappend lTestNames WriteSerialNumber
    }
    
    if {$gaSet(DefaultCF)!="" && $gaSet(DefaultCF)!="c:/aa"} {
      lappend lTestNames LoadDefaultConfiguration
    }
    
    
    if {$gaSet(enPart1Test)==0} {
      if {$gaSet(enDownloadsBefore)==1} {
        lappend lTestNames Leds
      } 
    }
  } elseif {$b=="DNFV"} {    
    set lTestNames [list DnfvSoftwareDownload DnfvParameters    DnfvMacSwID DnfvHwType\
        DnfvDataTransmissionConf DnfvDataTransmission DnfvMac_BarCode DnfvLed]
    # DnfvBIOS
  }
  eval lappend lTestsAllTests $lTestNames
  
#   ## next lines remove DataTransmissionConf and DataTransmissionTest
#   foreach t $lTestNames {
#     if ![string match DataTr* $t] {
#      lappend lTestsTestsWithoutDataRun $t
#     }
#   }
    
  set glTests ""
  ## meantime we perform AllTests
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
  global gaSet glTests  gaGui
  #AddToLog "********* DUT: $gaSet(DutFullName) *********"
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
#   set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   if {[string match {*Leds*} $gaSet(startFrom)] || [string match {*Mac_BarCode*} $gaSet(startFrom)]} {
#     set ret 0
#   }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  puts "\n Before LedsEth. lRunTests:<$lRunTests> glTests:<$glTests>" ; update
  if {$gaSet(ledsBefore)==1 && $b!="DNFV"} {
    set ret [Leds]
    if {$ret!=0} {
      if {$gaSet(pair)==5} {
        ## in multi do nothing
      } else {
        return $ret
      }
      
    }
#     if {$ret==0} {
#       ## if we start from leds for all units, then the testList should start from
#       ## the next test
#       set lRunTests [lrange $glTests 1 end]
#       set glTests $lRunTests
#     }
  }
  puts "After LedsEth. lRunTests:<$lRunTests> glTests:<$glTests>\n" ; update
  
  foreach pair [PairsToTest] {
    #if {$gaSet(act)==0} {return -2}
    
    if {[string match {*Leds} $gaSet(startFrom)]} {
      ## if we start from Leds, just sign all pairs as goods and do not perform nothing
      set passPairID [open tmpFiles/passPair-$gaSet(pair).tcl a+]
        puts -nonewline $passPairID " $pair"
      close $passPairID
      set ret 0
      continue
    }  
    
    if {$gaSet(act)==0} {break}
    
    if {[lsearch [PairsToTest] $pair]=="-1"} {
      continue
    }
      
    set ::pair $pair
    puts "\n\n ********* DUT $pair start *********..[MyTime].."

    Status "DUT start"
    set gaSet(curTest) ""
    update
    
    #AddToLog "********* DUT $pair start *********"
    if {$gaSet(pair)=="5"} {
      AddToLog "********* DUT $pair start *********" 
      AddToPairLog $::pair "********* DUT $pair start *********"
    } else {
      AddToLog "********* DUT $gaSet(pair) start *********"
      AddToPairLog $gaSet(pair) "********* DUT $pair start *********"
    }
    
    PairPerfLab $pair yellow
    MassConnect $pair
     
    puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"

    foreach numberedTest $lRunTests {
      if {[string match {*Leds} $numberedTest]} {
        ## do not perform the Leds Test together with all test
        ## it will performed for all passed pairs at end of the proc
        continue
      }
      set gaSet(curTest) $numberedTest
      puts "\n **** Test $numberedTest start; [MyTime] "
      update
      
      MuxMngIO ioToGenMngToPc
        
      set testName [lindex [split $numberedTest ..] end]
      $gaSet(startTime) configure -text "$startTime ."
      AddToLog "Test \'$testName\' start"
      if {$gaSet(pair)=="5"} {
        AddToPairLog $::pair "Test \'$testName\' start"
      } else {   
        AddToPairLog $gaSet(pair) "Test \'$testName\' start"    
      }
      puts "\n **** DUT ${pair}. Test $numberedTest start; [MyTime] "
      $gaSet(runTime) configure -text ""
      update
      
      set ret [$testName 1]
      #set ret 0 ; puts "$testName" ; update
      
      
      if {$ret!=0 && $ret!="-2" && $testName!="Mac_BarCode" && $testName!="ID" && $testName!="Leds"} {
#     set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
#     puts $logFileID "**** Test $numberedTest fail and rechecked. Reason: $gaSet(fail); [MyTime]"
#     close $logFileID
#     puts "\n **** Rerun - Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n"
#     $gaSet(startTime) configure -text "$startTime .."
      
#     set ret [$testName 2]
      }
    
      if {$ret==0} {
        set retTxt "PASS."              
      } else {
        set retTxt "FAIL. Reason: $gaSet(fail)"        
      }
      AddToLog "Test \'$testName\' $retTxt"
      if {$gaSet(pair)=="5"} {
        AddToPairLog $::pair "Test \'$testName\' $retTxt"
        set pa $::pair
      } else {   
        AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"  
        set pa $gaSet(pair)
      }
       
      puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
      update
      if {$ret!=0} {
        if {$ret=="-1"} {
          UnregIdBarcode $pa $gaSet($pa.barcode1)
        }
        break
      }
      if {$gaSet(oneTest)==1} {
        set ret 0
        set gaSet(oneTest) 0
        break
      }
    }
    
    if {$ret==0} {
      if {$gaSet(plEn)=="only"} {
        PairPerfLab $pair green
      } else {
        #PairPerfLab $pair #ddffdd ; #$gaSet(halfPassClr) ; # #ccffcc ; #green  ; #ddffdd
        
        ## since there is no LedTest after the running, I'm coloring the labs in final green
        PairPerfLab $pair green
      }
      set passPairID [open tmpFiles/passPair-$gaSet(pair).tcl a+]
      puts -nonewline $passPairID " $pair"
      close $passPairID
      set retTxt Pass
      set logText "All tests pass"
    } else {
      set logText "Test $numberedTest fail. Reason: $gaSet(fail)" 
      PairPerfLab $pair red
      set retTxt Fail
    }
              
    if {($ret!=0) && ($pair==[lindex [PairsToTest] end])} {
      ## the test failed and the pair is last (or single) and  - do nothing
    } else {
      if {[string match {*Mac_BarCode*} $gaSet(startFrom)]} {
        # the Tester started with Mac_BarCode, then just perform this test in all pairs
      } else {
        if {$gaSet(nextPair)=="begin"} {
          # the next pair will start from first test
          set gaSet(startFrom) [lindex $glTests 0]
          set startIndx [lsearch $glTests $gaSet(startFrom)]
          set lRunTests [lrange $glTests $startIndx end]
#           set gaSet(startFrom) [lindex $lRunTests 0]
#           set startIndx [lsearch $lRunTests $gaSet(startFrom)]
          puts "glTests:$glTests   lRunTests:$lRunTests"
          update
        } elseif {$gaSet(nextPair)=="same"} {
          ## do nothing
        }
      }  
    }
    if {$gaSet(pair)=="5"} {
      set pa $pair
    } else {
      set pa $gaSet(pair)
    }
    puts "********* DUT $pa finish *********..[MyTime]..\n\n"
    AddToLog "$logText \n    ********* DUT $pa $retTxt   *********\n"
    AddToPairLog $pa "$logText \n    ********* DUT $pa $retTxt   *********\n"
#     if {$ret!=0} {
#       file rename $gaSet(log.$pa) [file rootname $gaSet(log.$pa)]-Fail.txt
#     }
    
    if {$gaSet(nextPair)=="begin"} {
      set gaSet(oneTest) 0
    } elseif {$gaSet(nextPair)=="same"} {
      ## do nothing
    }      
  }
  
  set gaSet(oneTest) 0
  set passPairID [open tmpFiles/passPair-$gaSet(pair).tcl a+]
  puts -nonewline $passPairID "\]"
  close $passPairID
  
  source tmpFiles/passPair-$gaSet(pair).tcl
  set lPassPair [lsort -unique -dict $lPassPair]
  puts "lPassPair:<$lPassPair>, llength $lPassPair:[llength $lPassPair]"
  
  if {$gaSet(act)==0} {return -2}
 
 ## 07/11/2016 11:38:04 
  set retLed 0
  set ledsIndx [lsearch -glob $glTests *Leds]
  if {[llength $lPassPair]>0 && $ledsIndx!="-1"} {
    #set ledsIndx [lsearch -glob $glTests *Leds]
    set gaSet(curTest) [lindex $glTests $ledsIndx]
    AddToLog "********* Leds Test start *********"  

    if {$gaSet(act)==0} {return -2}
#     #AddToLog "Pair:$pair Leds Test start"  
    set ret [Leds]   
  }
  if {$ret==0 && $retLed==0} {
    set ret 0    
    set endFlag Pass
  } else {
    set ret -1
    set endFlag Fail
  }
  
  if {$gaSet(pair)=="5"} {
    for {set pair 1} {$pair <= $gaSet(maxMultiQty)} {incr pair} {
      set bg [$gaGui(labPairPerf$pair) cget -bg]
      if {$bg=="green" || $bg=="#ddffdd"} {
        set endFlag Pass
      } elseif {$bg=="red"} {
        set endFlag Fail
      } else {
        continue
      }
      set pa $pair
      if {[string index [file rootname $gaSet(log.$pa)] end]=="s" ||\
          [string index [file rootname $gaSet(log.$pa)] end]=="l"} {
        ## in case of -Pass or -Fail
        set newLog [string range [file rootname $gaSet(log.$pa)] 0 end-5]
        file rename -force $gaSet(log.$pa) $newLog.txt    
      }
      file rename -force $gaSet(log.$pa) [file rootname $gaSet(log.$pa)]-$endFlag.txt
      set gaSet(runStatus) $endFlag
      SQliteAddLine $pa
    }  
  } else {
    set pa $gaSet(pair)
    if {[string index [file rootname $gaSet(log.$pa)] end]=="s" ||\
        [string index [file rootname $gaSet(log.$pa)] end]=="l"} {
      ## in case of -Pass or -Fail
      set newLog [string range [file rootname $gaSet(log.$pa)] 0 end-5]
      file rename -force $gaSet(log.$pa) $newLog.txt    
    }
    file rename -force $gaSet(log.$pa) [file rootname $gaSet(log.$pa)]-$endFlag.txt
    set gaSet(runStatus) $endFlag
    SQliteAddLine $pa
  }
    
  
  AddToLog "********* TEST FINISHED  *********" 
  
  AddToLog "WS: $::wastedSecs"


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
# ID
# ***************************************************************************
proc ID {run} {
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
  global gaSet
  Power all on
  for {set i 1} {$i<=3} {incr i} {
    if {$gaSet(act)==0} {return -2}
    Status "DyingGasp trial $i"
    set ret [DyingGaspPerf 1 2]
    AddToLog "Result of DyingGasp trial $i : <$ret> "
#     if {$gaSet(pair)=="5"} {
#       AddToPairLog $pair "Result of DyingGasp trial $i : <$ret> "
#     } else {
#       AddToPairLog $pair "Result of DyingGasp trial $i : <$ret> "
#     }
    puts "[MyTime] Ret of DyingGasp trial $i : $ret" ; update
    if {$ret==0} {break}
  }
  
  return $ret
}
# ***************************************************************************
# DyingGaspTest
# ***************************************************************************
proc DyingGaspTest {run} {
  global gaSet
  Power all on
  for {set i 1} {$i<=2} {incr i} {
    if {$gaSet(act)==0} {return -2}
    Status "DyingGasp trial $i"
    set ret [DyingGaspLogPerf 1 2]
    AddToLog "Result of DyingGasp trial $i : <$ret> "
#     if {$gaSet(pair)=="5"} {
#       AddToPairLog $pair "Result of DyingGasp trial $i : <$ret> "
#     } else {
#       AddToPairLog $pair "Result of DyingGasp trial $i : <$ret> "
#     }
    puts "[MyTime] Ret of DyingGasp trial $i : $ret" ; update
    if {$ret==0} {break}
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
  
  
  ## 13/07/2016 13:43:05 1/3 and 1/4 have been added
  if {$up=="2CMB"} {
    set ret [ForceMode $b rj45 {3 4}]
    if {$ret!=0} {return $ret}
    Wait "Wait for RJ45 mode" 15
    
    set portL [list 0/3 0/4]   
    foreach port $portL {
      ## RJ45+SFP Out - RJ45 Active
      ## RJ45+SFP In - SFP Active
      set ret [ReadEthPortStatus $port "RJ45+SFP Out - RJ45 Active"]
      if {$ret=="-1" || $ret=="-2"} {return $ret}      
    }  
  }
 
#   set ret [AdminSave]
#   if {$ret!=0} {return $ret}
#   Power all off
#   after 1000
#   Power all on
    
  if {$b=="V"} {
    set packRate 50000
    set stream 8
  } elseif {($b=="2iB" && $up=="8SFP") || $b=="RJIO"} {
    set packRate 930000 ; # 1000000 15/07/2019 15:54:57
    set stream 1
  } elseif {$b=="2iB" && $up=="4SFP4UTP"} {
    set packRate  930000 ; # 990000  15/07/2019 15:55:24    
    set stream 1
  } else {
    set packRate 1200000
    set stream 1
  }  
  InitEtxGen 1 
  Status "EtxGen::GenConfig -packRate $packRate -stream $stream"
  RLEtxGen::GenConfig $gaSet(idGen1) -updGen all -packRate $packRate -stream $stream
  
  if {$b=="V"} {
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
  
  set ret [DataTransmissionTestPerf [list 1 2] $packRate UTP]
  if {$b=="V" && $ret==0} {
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
  if {$up=="2CMB"} {
    Power all off
    after 1000
    Power all on 
    set ret [Login]
    if {$ret!=0} {return $ret}
    set ret [Wait "Wait for ETX up" 30]
    if {$ret!=0} {return $ret}
    set portL [list 0/3 0/4]   
    foreach port $portL {
      ## RJ45+SFP Out - RJ45 Active
      ## RJ45+SFP In - SFP Active
      set ret [ReadEthPortStatus $port "RJ45+SFP In - SFP Active"]
      if {$ret=="-1" || $ret=="-2"} {return $ret}      
    } 
  }
  
  if {$b=="V"} {
    set packRate 50000
    set stream 8
  } elseif {($b=="2iB" && $up=="8SFP") || $b=="RJIO"} {
    set packRate 930000 ; # 1000000 15/07/2019 15:54:57
    set stream 1
  } elseif {$b=="2iB" && $up=="4SFP4UTP"} {
    set packRate  930000 ; # 990000  15/07/2019 15:55:24  
    set stream 1
  } else {
    set packRate 1200000
    set stream 1
  }  
  Status "EtxGen::GenConfig -packRate $packRate -stream $stream"
  RLEtxGen::GenConfig $gaSet(idGen1) -updGen all -packRate $packRate -stream $stream
  
  if {$b=="V"} {
    set ret [DnfvCross on] 
    if {$ret!=0} {return $ret}  
  } 
  
  set ret [DataTransmissionTestPerf [list 1 2] $packRate SFP]  
  if {$ret=="-2"} {return $ret} 
  if {$ret=="-1"} {
    set ret [DataTransmissionTestPerf [list 1 2] $packRate SFP]
  }
  if {$b=="V" && $ret==0} {
    DnfvCross off
  }
  return $ret
}
# ***************************************************************************
# DataTransmissionTestPerf
# ***************************************************************************
proc DataTransmissionTestPerf {lGens packRate mode} {
  global gaSet
  puts "[MyTime] DataTransmissionTestPerf $lGens $packRate $mode"
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
  set ret [Etx204Check $lGens $packRate $b]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Data is running" 120 white]
  if {$ret!=0} {return $ret}
  
  set ret [Etx204Check $lGens $packRate $b]
  if {$ret!=0} {return $ret}
  
  ##16/12/2019 07:31:18
  if {[string match *CMB* $up] && $mode=="SFP"} {
    ## don't check additional off-on for Combo in SFP. It already done in UTP
  } else {   
    for {set addRun 1} {$addRun <= 5} {incr addRun} {
      Status "Additional run $addRun"
      Power all off
      after 3000
      Power all on
      
      set ret [Login]
      if {$ret!=0} {return $ret}
      set ret [Wait "Waiting for stabilization" 15 white]
      if {$ret!=0} {return $ret}
    
      Etx204Start
      set ret [Wait "Data is running" 10 white]
      if {$ret!=0} {return $ret}
      set ret [Etx204Check $lGens $packRate $b]
      if {$ret!=0} {return $ret}  
    }
  }
 
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

  if {$gaSet(pair)==5} {
    set txt0 "UUT-$uut"
    set pa $uut
  } else {
    set txt0 UUT
    set pa 1
  }
  set txt "On $txt0 verify that:\n\
  GREEN \'LINK\' and ORANGE \'ACT\' leds of \'MNG-ETH\' are ON\n\
  GREEN \'LINK/ACT\' leds of ETH ports are ON/blinking"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" \
      -message $txt  -parent $gaSet(sstatus) -place below]
  update
  
  #catch {exec pskill.exe -t $pingId}
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    set ret -1
    UnregIdBarcode $pa $gaSet($pa.barcode1)
  } else {
    set ret 0    
  }
  puts "ret of LedsEthTst $txt0 : <$ret>"
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
proc Leds {} {
  global gaSet gaGui gRelayState
  if {$gaSet(pair)==5} {
    set ret [LedsMulti]
  } else {
    set ret [LedsSingle]
  }
  return $ret
}
# ***************************************************************************
# LedsSingle
# ***************************************************************************
proc LedsSingle {} {
  global gaSet gaGui gRelayState
  Status "Leds' Test on UUT"
  MuxMngIO ioToGen
  RLSound::Play information
  set txt "On UUT verify that:\n\
  GREEN \'PWR\' led is ON\n\
  RED \'TST/ALM\' led is ON\n\
  GREEN \'LINK/ACT\' leds of ETH ports are ON/blinking"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    set ret -1
    AddToLog "********* Leds' Test FAIL *********"
    AddToPairLog $gaSet(pair) "********* Leds' Test FAIL *********"
    UnregIdBarcode $gaSet(pair) $gaSet($gaSet(pair).barcode1)
    return -1    
  } else {
    set ret 0
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="V"} {
    set ret [DnfvLed 1]
    if {$ret!=0} {return $ret}
  }
  
  ## set the final result
  set res $ret
  foreach pair 1 {
    MuxMngIO  ioToGenMngToPc
    if {$gaSet(act)==0} {break}
    PairPerfLab $pair yellow
    MassConnect $pair
    after 1000
    set ret [LedsEthTst $pair]
    if {$b!="V" && $d=="D" && $ret==0} {
      set ret [DryContactTest $pair]
      puts "ret after DryContactTest $pair : <$ret>"
    }
    if {$ret=="-1"} {        
      set clr red
      set txt FAIL
      ## update the final result
      set res $ret
      UnregIdBarcode $pair $gaSet($pair.barcode1)
    } elseif {$ret=="0"} {
      set clr #ddffdd 
      set txt PASS
    } 
    PairPerfLab $pair $clr
    AddToLog "********* Leds' Test $txt *********"
    AddToPairLog $gaSet(pair) "********* Leds' Test $txt *********"
    
  }
  ## return with the final result
  puts "[MyTime] res of Leds:<$res>"; update
  return $res
}
# ***************************************************************************
# LedsMulti
# ***************************************************************************
proc LedsMulti {} {
  global gaSet gaGui gRelayState
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$gaSet(pair)==5} {
    #set pairsToTestL [PairsToTest]
    
    set txt0 "UUTs [PairsToTest]"
  } else {
    #set pairsToTestL ""
    Status "Leds' Test on UUT"
    set txt0 "UUT"
  }
  Status "Leds' Test on UUTs [PairsToTest]"
  MuxMngIO nc
  MassConnect NC
  RLSound::Play information
  set txt "On UUTs [PairsToTest] verify that:\n\
  GREEN \'PWR\' led is ON\n\
  RED \'TST/ALM\' led is ON"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" \
      -message $txt -parent $gaSet(sstatus) -place below]
  update
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    set ret -1
    foreach pair [PairsToTest] {
      MuxMngIO ioToGenMngToPc
      PairPerfLab $pair red
      UnregIdBarcode $pair $gaSet($pair.barcode1)
    }    
  } else {
    set ret 0
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="V"} {
    set ret [DnfvLed 1]
    if {$ret!=0} {return $ret}
  }
  
  ## set the final result
  set res $ret
  foreach pair [PairsToTest] {
    if {$gaSet(act)==0} {break}
    PairPerfLab $pair yellow
    MassConnect $pair
    after 1000
    set ret [LedsEthTst $pair]
    if {$b!="V" && $d=="D" && $ret==0} {
      set ret [DryContactTest $pair]
      puts "ret after DryContactTest $pair : <$ret>"
    }
    if {$ret=="-1" || $ret=="-2"} {        
      set clr red
      set txt FAIL
      ## update the final result
      set res $ret
      if {$ret=="-1"} {
        UnregIdBarcode $pair $gaSet($pair.barcode1)
      }
    } elseif {$ret=="0"} {
      set clr #ddffdd 
      set txt PASS
    } 
    PairPerfLab $pair $clr
    AddToLog "********* Leds' Test of UUT $pair $txt *********"
    AddToPairLog $pair "********* Leds' Test of UUT $pair $txt *********"    
  }
  ## return with the final result
  puts "[MyTime] res of Leds:<$res>"; update
  return $res
}
# ***************************************************************************
# SetToDefault
# ***************************************************************************
proc SetToDefault {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault std 7]  ; # 20
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefaultAll
# ***************************************************************************
proc SetToDefaultAll {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda 20]  ; # 20
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
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="V"} {
    if ![info exists gaSet($pair.mac2)] {
      set ret [DnfvMacSwIDTest]
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
  if {$ret==0 && ($b=="V" || $b=="DNFV")} {
    set ret [DnfvPower off] 
    if {$ret!=0} {return $ret} 
  }    
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
  set ret [FactDefault stda]
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
  InitEtxGen 1 
  set id $gaSet(idGen1) 
  RLEtxGen::GenConfig $id -updGen all -packRate 10
  ## -payload should have digits and low case letters!
  set payl1 0001080006040001000000000001010101010000000000000101010a
  set sa1 000000000001
  set payl2 0001080006040001000000000002020202010000000000000202020a
  set sa2 000000000002
  puts "PacketConfig 1 $sa1 $payl1"
  puts "PacketConfig 2 $sa2 $payl2"
  update
  RLEtxGen::PacketConfig $id MAC -updGen 1 -SA $sa1 -DA FFFFFFFFFFFF \
      -payload $payl1 -ethType 0806 
  RLEtxGen::PacketConfig $id MAC -updGen 2 -SA $sa2 -DA FFFFFFFFFFFF \
      -payload $payl2  -ethType 0806  
      
  return [ShowArpTable]   
}
# ***************************************************************************
# RtrData
# ***************************************************************************
proc RtrData {run} {
  global gaSet
  #ConfigEtxGen
  Status "EtxGen::GenConfig"
  InitEtxGen 1 
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
  set sa1 000000000001
  set payl1 [string tolower 4500001400000000FFFDB4E801010101020202010000000000000000]
  set sa2 000000000002
  set payl2 [string tolower 4500001400000000FFFDB4E802020201010101010000000000000000]
  puts "PacketConfig 1 $sa1 $payl1"
  puts "PacketConfig 2 $sa2 $payl2"
  update
  RLEtxGen::PacketConfig $id MAC -updGen 1 -SA $sa1 -DA $da1 -payload $payl1 -ethType 0800 
  RLEtxGen::PacketConfig $id MAC -updGen 2 -SA $sa2 -DA $da2 -payload $payl2 -ethType 0800  
      
  return [DataTransmissionTestPerf [list 1 2] 20000 RTR] 
}      

 
# ***************************************************************************
# DnfvBIOS
# ***************************************************************************
proc DnfvBIOS {run} {
  Power all on
  return [BiosTest]
}
# ***************************************************************************
# DnfvParameters
# ***************************************************************************
proc DnfvParameters {run} {
  Power all on
  return [DnfvParametersTest]
}
# ***************************************************************************
# BurnMAC
# ***************************************************************************
proc BurnMAC {run} {
  set ret [BurnMacTest]
  return $ret
}
# ***************************************************************************
# DnfvHwType
# ***************************************************************************
proc DnfvHwType {run} {
  set ret [DnfvHwTypeTest]
  return $ret
}


# ***************************************************************************
# DnfvMacSwID
# ***************************************************************************
proc DnfvMacSwID {run} {
   set ret [DnfvMacSwIDTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# BootDownload
# ***************************************************************************
proc BootDownload {run} {
  set ret [Boot_Download]
  if {$ret!=0} {return $ret}
  
  set ret [FormatFlashAfterBootDnl]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# SetDownload
# ***************************************************************************
proc SetDownload {run} {
  set ret [SetSWDownload]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# Pages
# ***************************************************************************
proc Pages {run} {
  global gaSet buffer
  set ret [GetPageFile $gaSet($::pair.barcode1) $gaSet($::pair.trace)]
  if {$ret!=0} {return $ret}
  
  set ret [WritePages]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SoftwareDownload
# ***************************************************************************
proc SoftwareDownload {run} {
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [SoftwareDownloadTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# DnfvSoftwareDownload
# ***************************************************************************
proc DnfvSoftwareDownload {run} {
  #Power all off
  global gaSet
  RLSound::Play information
  set txt "Insert DiskOnKey with application into the DNFV's USB port and press OK"
  set res [DialogBox -type "OK Cancel" -icon /images/question \
      -title "Burn MAC" -message $txt -aspect 2000 -parent $gaSet(sstatus) -place below]
  update
  if {$res=="Cancel"} {
    return -2
  }
  
  #Power all on
  
  set ret [DnfvSoftwareDownloadTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# DnfvDataTransmissionConf
# ***************************************************************************
proc DnfvDataTransmissionConf {run} {
  global gaSet
  Power all on
     
  #ConfigEtxGen
  
  set ret [FactDefault stda]
  if {$ret!=0} {return $ret}   
  set ret [DataTransmissionSetup]
  if {$ret!=0} {return $ret} 
  
  return $ret
} 
# ***************************************************************************
# DnfvDataTransmission
# ***************************************************************************
proc DnfvDataTransmission {run} {
  global gaSet
  
  Status "EtxGen::GenConfig"
  InitEtxGen 1
  RLEtxGen::GenConfig $gaSet(idGen1) -updGen all -packRate 50000 -stream 8
  
  set ret [DnfvCross on] 
  if {$ret!=0} {return $ret}  
  
  set ret [DataTransmissionTestPerf [list 1 2] 50000 DNFV]  
  if {$ret!=0} {return $ret}
  
  set ret [DnfvCross off] 
  if {$ret!=0} {return $ret}  
  
#   set ret [DnfvPower off] 
#   if {$ret!=0} {return $ret} 
  return $ret
}
# ***************************************************************************
# DnfvLeds
# ***************************************************************************
proc DnfvLed {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  
  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX-2I" "Manual Test"
  
  #catch {set pingId [exec ping.exe 10.10.10.1[set gaSet(pair)] -t &]}
  
  RLSound::Play information
  set txt "On DNFV verify that:\n\
  GREEN \'ACTIVE\' led is ON\n\
  Fans rotate"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" \
      -message $txt -parent $gaSet(sstatus) -place below]
  update
  
  #catch {exec pskill.exe -t $pingId}
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
  
  
  return $ret
}
# ***************************************************************************
# DnfvMac_BarCode
# ***************************************************************************
proc DnfvMac_BarCode {run} {
  global gaSet  
  set pair $::pair 
  puts "DnfvMac_BarCode \"$pair\" "
  mparray gaSet *mac* ; update
  mparray gaSet *barcode* ; update
  set badL [list]
  set ret -1
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit))] {
      set ret [DnfvMacSwIDTest]
      if {$ret!=0} {return $ret}
    }  
  } 
  foreach unit {1} {
    if ![info exists gaSet($pair.barcode$unit)] {
      set ret [ReadBarcode [PairsToTest]]
      if {$ret!=0} {return $ret}
    }  
  }
  #set ret [ReadBarcode [PairsToTest]]
#   set ret [ReadBarcode]
#   if {$ret!=0} {return $ret}
  set ret [RegBC $pair]
               
  if {$ret==0} {
    set ret [DnfvPower off] 
    if {$ret!=0} {return $ret} 
  }    
  return $ret
}

# ***************************************************************************
# FAN
# ***************************************************************************
proc FAN {run} {
  global gaSet
  set ret [FanTestPerf]
  return $ret
}
# ***************************************************************************
# WriteSerialNumber
# ***************************************************************************
proc WriteSerialNumber {run} {
  global gaSet gaGui buffer
#   set ret [GuiReadSerNum]
#   parray gaSet *serialNum*
#   if {$ret!=0} {return $ret}  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}   
  set ret [WritePage0 ]
  if {$ret!=0} {return $ret} 
    set ret [AdminFactAll]
    if {$ret!=0} {return $ret} 
    set ret [VerifySN]
    if {$ret!=0} {return $ret}
  return $ret
}