# ***************************************************************************
# BuildTests
# ***************************************************************************
proc BuildTests {} {
  global gaSet gaGui glTests
  
  set lTests [list SetToDefault 1PPS SyncE_conf SyncE_run SetToDefaultAll]
    
  set glTests [list]
  for {set i 0; set k 1} {$i<[llength $lTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTests $i]"
  }
  
  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests -height [llength $glTests]
  
  return {}
}
# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
  
  set pair 1
  if {$gaSet(act)==0} {return -2}
    
  set ::pair $pair
  puts "\n\n ********* DUT start *********..[MyTime].."
  Status "DUT start"
  set gaSet(curTest) ""
  update
    
  AddToPairLog $gaSet(pair) "********* DUT start *********"
  AddToPairLog $gaSet(pair) "$gaSet(rbTestMode) Tests"
  puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"

  foreach numberedTest $lRunTests {
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
      
    set testName [lindex [split $numberedTest ..] end]
    $gaSet(startTime) configure -text "$startTime ."
    AddToPairLog $gaSet(pair) "Test \'$testName\' started"
    set ret [$testName 1]
    
    if {$ret==0} {
      set retTxt "PASS."
    } else {
      set retTxt "FAIL. Reason: $gaSet(fail)"
    }
#     AddToLog "Test \'$testName\' $retTxt"
    AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"
       
    puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
    update
    if {$ret!=0} {
      break
    }
    if {$gaSet(oneTest)==1} {
      set ret 1
      set gaSet(oneTest) 0
      break
    }
  }
  
  AddToPairLog $gaSet(pair) "WS: $::wastedSecs"

  puts "RunTests4 ret:$ret gaSet(startFrom):$gaSet(startFrom)"   
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
  if {$ret!=0} {
    Power all off
    after 3000
    Power all on  
    Wait "Wait for UP" 40
    set ret [ExtClkTest Locked]
  }
  return $ret
}

# ***************************************************************************
# SetToDefault
# ***************************************************************************
proc SetToDefault {run} {
  global gaSet gaGui
  set ret [FactDefault std]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefaultAll
# ***************************************************************************
proc SetToDefaultAll {run} {
  global gaSet gaGui
  set ret [FactDefault stda]
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
    }  
  } 
  foreach unit {1} {
    if {![info exists gaSet($pair.barcode$unit)] || $gaSet($pair.barcode$unit)=="skipped"}  {
      set ret [ReadBarcode]
      if {$ret!=0} {return $ret}
    }  
  }
  #set ret [ReadBarcode [PairsToTest]]
#   set ret [ReadBarcode]
#   if {$ret!=0} {return $ret}
  set ret [RegBC]
      
  return $ret
}

# ***************************************************************************
# LoadDefaultConfiguration
# ***************************************************************************
proc LoadDefaultConfiguration {run} {
  global gaSet  
  Power all on
  set ret [FactDefault stda noWD]
  if {$ret!=0} {return $ret}
  set ret [LoadDefConf]
  return $ret
}
 

# ***************************************************************************
# 1PPS
# ***************************************************************************
proc 1PPS {run} {
  global gaSet  
  set ret [1pps_perf]
  return $ret
}

# ***************************************************************************
# SyncE_conf
# ***************************************************************************
proc SyncE_conf {run} {
  global gaSet  buffer
  
  ##23/02/2020 11:09:26 Check AUXes config
  foreach aux {Aux1 Aux2} {
    set com $gaSet(com$aux)
    catch {RLSerial::Close $com}
    after 100
    set ret [RLSerial::Open $com 9600 n 8 1]
    ##set ret [RLCom::Open $com 9600 8 NONE 1]
    set ret [Login205 $aux]
    if {$ret!=0} {
      set ret [Login205 $aux]
    }
    if {$ret!=0} {
      set gaSet(fail) "Logon to $aux fail"
      return -1
    }
    
    Send $com "exit all\r" stam 0.25
    set ret [Send $com "configure system clock domain 1\r" domain(1)] 
    if {$ret!=0} {
      set gaSet(fail) "Read Domain 1 at $aux fail"
      return -1
    }
    set ret [Send $com "info\r" domain(1)] 
    if {$ret!=0} {
      set gaSet(fail) "Read Info of Domain 1 at $aux fail"
      return -1
    }
    if {[string match *force-t4-as-t0* $buffer]} {
      ## the aux is configured
      set ret 0
      Status "$aux is configured"
      catch {RLSerial::Close $com}
      break
    } else {
      Send $com "exit all\r" stam 0.25 
      set cf ./ConfFiles/Aux${aux}.txt; #$gaSet([set aux]CF) 
      set cfTxt "$aux"
      set ret [DownloadConfFile $cf $cfTxt 1 $com] 
      if {$ret==0} {
        Status "$aux passed configuration"
      } else {
        set gaSet(fail) "Configuration of $aux failed" 
        return $ret 
      }
      catch {RLSerial::Close $com}
    }
  }
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  #foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set cf ./ConfFiles/SyncE.txt ; #$gaSet([set b]SyncECF) 
  set cfTxt "ETX-2i-B-PTP"
      
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
  
  ##MuxMngIO ioToCnt ioToCnt
    
  return $ret
} 

# ***************************************************************************
# SyncE_run
# ***************************************************************************
proc SyncE_run {run} {
  global gaSet
   
  # set ret [SyncELockClkTest] 
  # if {$ret!=0} {
    # Power all off
    # after 3000
    # Power all on  
    # Wait "Wait for UP" 40
    # set ret [SyncELockClkTest]
    # if {$ret!=0} {
      # return $ret
    # }
  # }
  
  # set ret [GpibOpen]
  # if {$ret!=0} {
    # set gaSet(fail) "No communication with Scope"
    # return $ret
  # }
  
  # set ret [ExistTds520B]
  # if {$ret!=0} {return $ret}
  
  for {set tr 1} {$tr <= 3} {incr tr} {
    puts "\n[MyTime] Try $tr of ChkLockClkTds"
    ##MuxMngIO ioToCnt ioToCnt
    DefaultTds520b    
    ##ClearTds520b
    after 2000
    SetLockClkTds   
    after 3000
    set ret [ChkLockClkTds]
    puts "Result of Try $tr of ChkLockClkTds: <$ret>"
    if {$ret!=0} {
      after 1000
    } else {
      break
    }
  }    
  if {$ret!=0} {
    GpibClose
    return $ret
  }
   
  set ret [SyncELockClkTest]
  if {$ret!=0} {
    Power all off
    after 3000
    Power all on  
    Wait "Wait for UP" 40
    set ret [SyncELockClkTest]
  }
  if {$ret!=0} {
    GpibClose
    return $ret
  }
   
  set ret [CheckJitter 100]
  GpibClose
  if {$ret=="-1" || $ret=="-2"} {return $ret}
  if {$ret>30} {
    set gaSet(fail) "Jitter: $ret nSec, should not exceed 30 nSec"
    set ret -1
  } else {
    set ret 0
  }
     
  return $ret
} 
