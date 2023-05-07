
##***************************************************************************
##** OpenRL
##***************************************************************************
proc OpenRL {} {
  global gaSet
  if [info exists gaSet(curTest)] {
    set curTest $gaSet(curTest)
  } else {
    set curTest "1..ID"
  }
  CloseRL
  catch {RLEH::Close}
  
  RLEH::Open
  
  puts "Open PIO [MyTime]"
  set ret [OpenPio]
  set ret1 [OpenComUut]
  
  if {[string match {*Mac_BarCode*} $gaSet(startFrom)] || [string match {*LedsAlm*} $gaSet(startFrom)] ||\
      [string match {*Memory*} $gaSet(startFrom)]      || [string match {*License*} $gaSet(startFrom)] ||\
      [string match {*SaveUserFile*} $gaSet(startFrom)] ||\
      [string match {*SetToDefaultAll*} $gaSet(startFrom)] } {
    set openGens 0  
  } else {
    set openGens 1
  } 
  
  #25/08/2016 09:53:23  
  set openGens 0
  if {$openGens==1} {  
    Status "Open ETH GENERATOR"
    set ret2 [OpenEtxGen]    
  } else {
    set ret2 0
  }  
   
  
  set gaSet(curTest) $curTest
  puts "[MyTime] ret:$ret ret1:$ret1 ret2:$ret2 " ; update
  if {$ret1!=0 || $ret2!=0} {
    return -1
  }
  return 0
}

# ***************************************************************************
# OpenComUut
# ***************************************************************************
proc OpenComUut {} {
  global gaSet
  for {set u 1} {$u<=$gaSet(maxUnitsQty)} {incr u} {
    RLSerial::Open $gaSet(comDut$u) 9600 n 8 1
  }
  return 0
}
proc ocu {} {OpenComUut}
proc ccu {} {CloseComUut}
# ***************************************************************************
# CloseComUut
# ***************************************************************************
proc CloseComUut {} {
  global gaSet
  for {set u 1} {$u<=$gaSet(maxUnitsQty)} {incr u} {
    catch {RLSerial::Close $gaSet(comDut$u)}
  }
  
  return {}
}

#***************************************************************************
#** CloseRL
#***************************************************************************
proc CloseRL {} {
  global gaSet
  set gaSet(serial) ""
  ClosePio
  puts "CloseRL ClosePio" ; update
  CloseComUut
  puts "CloseRL CloseComUut" ; update 
  catch {RLEtxGen::CloseAll}
  #catch {RLScotty::SnmpCloseAllTrap}
  catch {RLEH::Close}
}
# ***************************************************************************
# OpenPio
# ***************************************************************************
proc OpenPio {} {
  global gaSet descript
  RLUsbPio::GetUsbChannels descript
  foreach rb {1 2} {
    set gaSet(idPwr$rb) [RL[set gaSet(pioType)]Pio::Open $rb RBA]
  }
  set gaSet(mmuxMassId) [RL[set gaSet(pioType)]Mmux::Open $gaSet(mmuxMassPort)]
  return 0
}

# ***************************************************************************
# ClosePio
# ***************************************************************************
proc ClosePio {} {
  global gaSet
  set ret 0
  foreach rb "1 2" {
	  catch {RL[set gaSet(pioType)]Pio::Close $gaSet(idPwr$rb)}
  }
  catch {RL[set gaSet(pioType)]Mmux::Close $gaSet(mmuxMassId)}
  return $ret
}

# ***************************************************************************
# SaveUutInit
# ***************************************************************************
proc SaveUutInit {fil} {
  global gaSet
  puts "SaveUutInit $fil"
  set id [open $fil w]
  puts $id "set gaSet(sw)          \"$gaSet(sw)\""
  puts $id "set gaSet(dbrSW)       \"$gaSet(dbrSW)\""
  puts $id "set gaSet(swPack)      \"$gaSet(swPack)\""
  
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(DutFullName) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
  foreach indx {RJIO DGasp ExtClk RTR } {
    if ![info exists gaSet([set indx]CF)] {
      set gaSet([set indx]CF) ??
    }
    puts $id "set gaSet([set indx]CF) \"$gaSet([set indx]CF)\""
  }
  foreach indx {dnfvProject dnfvEC dnfvCPU licDir dnfvVer} {
    if ![info exists gaSet($indx)] {
      set gaSet($indx) ???
    }
    puts $id "set gaSet($indx) \"$gaSet($indx)\""
  }
  
  #puts $id "set gaSet(macIC)      \"$gaSet(macIC)\""
  close $id
}  
# ***************************************************************************
# SaveInit
# ***************************************************************************
proc SaveInit {} {
  global gaSet  
  set id [open [info host]/init$gaSet(pair).tcl w]
  puts $id "set gaGui(xy) +[winfo x .]+[winfo y .]"
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(entDUT) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
    
  puts $id "set gaSet(performShortTest) \"$gaSet(performShortTest)\""  
  
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  puts $id "set gaSet(eraseTitle) \"$gaSet(eraseTitle)\""
  
  if [info exists gaSet(pioType)] {
    set pioType $gaSet(pioType)
  } else {
    set pioType Ex
  }  
  puts $id "set gaSet(pioType) \"$pioType\""
  
  if ![info exists gaSet(enDownloadsBefore)] {
    set gaSet(enDownloadsBefore) 0
  }
  puts $id "set gaSet(enDownloadsBefore) \"$gaSet(enDownloadsBefore)\""
  
  if ![info exists gaSet(radTsts)] {
    set gaSet(radTsts) Full
  }
  puts $id "set gaSet(radTsts) \"$gaSet(radTsts)\""
  
  close $id
   
}

#***************************************************************************
#** MyTime
#***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T   %d/%m/%Y"]
}

#***************************************************************************
#** Send
#** #set ret [RLCom::SendSlow $com $toCom 150 buffer $fromCom $timeOut]
#** #set ret [Send$com $toCom buffer $fromCom $timeOut]
#** 
#***************************************************************************
proc Send {com sent expected {timeOut 8}} {
  global buffer gaSet
  if {$gaSet(act)==0} {return -2}

  #puts "sent:<$sent>"
  regsub -all {[ ]+} $sent " " sent
  #puts "sent:<[string trimleft $sent]>"
  ##set cmd [list RLSerial::SendSlow $com $sent 50 buffer $expected $timeOut]
  set cmd [list RLSerial::Send $com $sent buffer $expected $timeOut]
  if {$gaSet(act)==0} {return -2}
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  #puts buffer:<$buffer> ; update
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B.\;..H}  $b1 " " b1
  regsub -all -- {\x1B\x5B..\;.H}  $b1 " " b1
  regsub -all -- {\x1B\x5B.\;.H}   $b1 " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J}      $b1 " " b1
  regsub -all -- {\x1B\x5BK}       $b1 " " b1
  regsub -all -- {\x1B\x5B\x38\x30\x44}     $b1 " " b1
  regsub -all -- {\x1B\x5B\x31\x42}      $b1 " " b1
  regsub -all -- {\x1B\x5B.\x6D}      $b1 " " b1
  regsub -all -- \\\[m $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  regsub -all {\-+} $b3 "-" b3
  regsub -all -- {\[0\;30\;47m} $b3 " " b3
  regsub -all -- {\[1\;30\;47m} $b3 " " b3
  regsub -all -- {\[0\;34\;47m} $b3 " " b3
  set buffer $b3
  #puts "sent:<$sent>"
  if $gaSet(puts) {
    #puts "\nsend: ---------- [clock format [clock seconds] -format %T] ---------------------------"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent,  expected=$expected, buffer=$buffer"
    puts "send: ----------------------------------------\n"
    update
  }
  
  RLTime::Delayms 50
  return $ret
}

#***************************************************************************
#** Status
#***************************************************************************
proc Status {txt {color white}} {
  global gaSet gaGui
  #set gaSet(status) $txt
  #$gaGui(labStatus) configure -bg $color
  $gaSet(sstatus) configure -bg $color  -text $txt
  if {$txt!=""} {
    puts "\n ..... $txt ..... /* [MyTime] */ \n"
  }
  $gaSet(runTime) configure -text ""
  update
}


##***************************************************************************
##** Wait
##** 
##** 
##***************************************************************************
proc Wait {txt count {color white}} {
  global gaSet
  puts "\nStart Wait $txt $count.....[MyTime]"; update
  Status $txt $color 
  for {set i $count} {$i > 0} {incr i -1} {
    if {$gaSet(act)==0} {return -2}
	 $gaSet(runTime) configure -text $i
	 RLTime::Delay 1
  }
  $gaSet(runTime) configure -text ""
  Status "" 
  puts "Finish Wait $txt $count.....[MyTime]\n"; update
  return 0
}


#***************************************************************************
#** Init_UUT
#***************************************************************************
proc Init_UUT {init} {
  global gaSet
  set gaSet(curTest) $init
  Status ""
  OpenRL
  $init
  CloseRL
  set gaSet(curTest) ""
  Status "Done"
}


# ***************************************************************************
# PerfSet
# ***************************************************************************
proc PerfSet {state} {
  global gaSet gaGui
  set gaSet(perfSet) $state
  puts "PerfSet state:$state"
  switch -exact -- $state {
    1 {$gaGui(noSet) configure -relief raised -image [Bitmap::get images/Set] -helptext "Run with the UUTs Setup"}
    0 {$gaGui(noSet) configure -relief sunken -image [Bitmap::get images/noSet] -helptext "Run without the UUTs Setup"}
    swap {
      if {[$gaGui(noSet) cget -relief]=="raised"} {
        PerfSet 0
      } elseif {[$gaGui(noSet) cget -relief]=="sunken"} {
        PerfSet 1
      }
    }  
  }
}
# ***************************************************************************
# MyWaitFor
# ***************************************************************************
proc MyWaitFor {com expected testEach timeout} {
  global buffer gaGui gaSet
  #Status "Waiting for \"$expected\""
  if {$gaSet(act)==0} {return -2}
  puts [MyTime] ; update
  set startTime [clock seconds]
  set runTime 0
  while 1 {
    #set ret [RLCom::Waitfor $com buffer $expected $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    set ret [Send $com \r stam $testEach]
    foreach expd $expected {
      puts "buffer:__[set buffer]__ expected:\"$expected\" expd:$expd ret:$ret runTime:$runTime" ; update
#       if {$expd=="PASSWORD"} {
#         ## in old versiond you need a few enters to get the uut respond
#         Send $com \r stam 0.25
#       }
      if [string match *$expd* $buffer] {
        set ret 0
        break
      }
    }
    #set ret [Send $com \r $expected $testEach]
    set nowTime [clock seconds]; set runTime [expr {$nowTime - $startTime}] 
    $gaSet(runTime) configure -text $runTime
    #puts "i:$i runTime:$runTime ret:$ret buffer:_${buffer}_" ; update
    if {$ret==0} {break}
    if {$runTime>$timeout} {break }
    if {$gaSet(act)==0} {set ret -2 ; break}
    update
  }
  puts "[MyTime] ret:$ret runTime:$runTime"
  $gaSet(runTime) configure -text ""
  Status ""
  return $ret
}   
# ***************************************************************************
# Power
# ***************************************************************************
proc Power {ps state} {
  global gaSet gaGui 
  puts "[MyTime] Power $ps $state"
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
#   return 0
  set ret 0
  switch -exact -- $ps {
    1   {set pioL 1}
    2   {set pioL 2}
    all {set pioL "1 2"}
  } 
  switch -exact -- $state {
    on  {
	    foreach pio $pioL {      
        RLUsbPio::Set $gaSet(idPwr$pio) 1
      }
    } 
	  off {
	    foreach pio $pioL {
	      RLUsbPio::Set $gaSet(idPwr$pio) 0
      }
    }
  }
#   $gaGui(tbrun)  configure -state disabled 
#   $gaGui(tbstop) configure -state normal
  Status ""
  update
  #exec C:\\RLFiles\\Btl\\beep.exe &
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
  return $ret
}

# ***************************************************************************
# GuiPower
# ***************************************************************************
proc GuiPower {n state} { 
  global gaSet descript
  RLEH::Open
  RLUsbPio::GetUsbChannels descript
  switch -exact -- $n {
    1.1 - 2.1 - 3.1 - 4.1 - 5.1 {set portL [list 1]}
    1.2 - 2.2 - 3.2 - 4.2 - 5.2 {set portL [list 2]}      
    1 - 2 - 3 - 4 - 5 - all  {set portL [list 1 2]}  
  }        
  foreach rb $portL {
    set id [RLUsbPio::Open $rb RBA 1]
    puts "rb:<$rb> id:<$id>"
    RLUsbPio::Set $id $state
    RLUsbPio::Close $id 
  }
  RLEH::Close
} 

#***************************************************************************
#** Wait
#***************************************************************************
proc _Wait {ip_time ip_msg {ip_cmd ""}} {
  global gaSet 
  Status $ip_msg 

  for {set i $ip_time} {$i >= 0} {incr i -1} {       	 
	 if {$ip_cmd!=""} {
      set ret [eval $ip_cmd]
		if {$ret==0} {
		  set ret $i
		  break
		}
	 } elseif {$ip_cmd==""} {	   
	   set ret 0
	 }

	 #user's stop case
	 if {$gaSet(act)==0} {		 
      return -2
	 }
	 
	 RLTime::Delay 1	 
    $gaSet(runTime) configure -text " $i "
	 update	 
  }
  $gaSet(runTime) configure -text ""
  update   
  return $ret  
}

# ***************************************************************************
# AddToLog
# ***************************************************************************
proc AddToLog {line} {
  global gaSet
  #set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
  set logFileID [open $gaSet(logFile.$gaSet(pair)) a+] 
    puts $logFileID "..[MyTime]..$line"
  close $logFileID
}

# ***************************************************************************
# ShowLog
# ***************************************************************************
proc ShowLog {} {
	global gaSet
	#exec notepad tmpFiles/logFile-$gaSet(pair).txt &
  if {[info exists gaSet(logFile.$gaSet(pair))] && [file exists $gaSet(logFile.$gaSet(pair))]} {
    exec notepad $gaSet(logFile.$gaSet(pair)) &
  }
}

# ***************************************************************************
# mparray
# ***************************************************************************
proc mparray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
	  error "\"$a\" isn't an array"
  }
  set maxl 0
  foreach name [lsort -dict [array names array $pattern]] {
	  if {[string length $name] > $maxl} {
	    set maxl [string length $name]
  	}
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name [lsort -dict [array names array $pattern]] {
	  set nameString [format %s(%s) $a $name]
	  puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
  update
}
# ***************************************************************************
# GetDbrName
# ***************************************************************************
proc GetDbrName {} {
  global gaSet gaGui
  set barcode $gaSet(entDUT)
  
  if [file exists MarkNam_$barcode.txt] {
    file delete -force MarkNam_$barcode.txt
  }
  wm title . "$gaSet(pair) : "
  after 500
  
  catch {exec java -jar c:/RADapps/OI4Barcode.jar $barcode} b
  set fileName MarkNam_$barcode.txt
  after 1000
  if ![file exists MarkNam_$barcode.txt] {
    set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set fileId [open "$fileName"]
    seek $fileId 0
    set res [read $fileId]    
  close $fileId
  
  #set txt "$barcode $res"
  set txt "[string trim $res]"
  #set gaSet(entDUT) $txt
  set gaSet(entDUT) ""
  puts <$txt>
  
  set initName [regsub -all / $res .]
  set gaSet(DutFullName) $res
  set gaSet(DutInitName) $initName.tcl
  
  file delete -force MarkNam_$barcode.txt
  #file mkdir [regsub -all / $res .]
  
  if {[file exists uutInits/$gaSet(DutInitName)]} {
    source uutInits/$gaSet(DutInitName)  
    UpdateAppsHelpText  
  } else {
    ## if the init file doesn't exist, fill the parameters by ? signs
    foreach v {sw} {
      set gaSet($v) ??
    }
    foreach en {licEn} {
      set gaSet($v) 0
    } 
  } 
  wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  pack forget $gaGui(frFailStatus)
  Status ""
  update
  BuildTests
  
  set ret [GetDbrSW $barcode]
  puts "GetDbrName ret of GetDbrSW:$ret" ; update
  
  focus -force $gaGui(tbrun)
}

# ***************************************************************************
# DelMarkNam
# ***************************************************************************
proc DelMarkNam {} {
  if {[catch {glob MarkNam*} MNlist]==0} {
    foreach f $MNlist {
      file delete -force $f
    }  
  }
}

# ***************************************************************************
# GetInitFile
# ***************************************************************************
proc GetInitFile {} {
  global gaSet gaGui
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl]
  if {$fil!=""} {
    source $fil
    set gaSet(entDUT) "" ; #$gaSet(DutFullName)
    wm title . "$gaSet(pair) : $gaSet(DutFullName)"
    UpdateAppsHelpText
    pack forget $gaGui(frFailStatus)
    Status ""
    BuildTests
  }
}
# ***************************************************************************
# UpdateAppsHelpText
# ***************************************************************************
proc UpdateAppsHelpText {} {
  global gaSet gaGui
  #$gaGui(labPlEnPerf) configure -helptext $gaSet(pl)
  #$gaGui(labUafEn) configure -helptext $gaSet(uaf)
  #$gaGui(labUdfEn) configure -helptext $gaSet(udf)
}

# ***************************************************************************
# RetriveDutFam
# RetriveDutFam [regsub -all / ETX-DNFV-M/I7/128S/8R .].tcl
# ETX-2I-B_RJIO.H.WR.2SFP.8SFP.tcl 
# ***************************************************************************
proc RetriveDutFam {{dutInitName ""}} {
  global gaSet 
  set gaSet(dutFam) NA 
  set gaSet(dutBox) NA 
  if {$dutInitName==""} {
    set dutInitName $gaSet(DutInitName)
  }
  puts "RetriveDutFam $dutInitName"
  if {[string match *RJIO.* $dutInitName]==1} {
    set gaSet(dutFam) RJIO.0.0.0.0.2SFP.8SFP
  }
  
  if {[string match *.RTR.* $dutInitName]==1} {
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $b.R.$p.$d.$ps.$np.$up  
    }
  }
  if {[string match *.PTP.* $dutInitName]==1} {
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $b.$r.P.$d.$ps.$np.$up  
    }
  }
  if {[string match *.DRC.* $dutInitName]==1} {
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $b.$r.$p.D.$ps.$np.$up  
    }
  }
  if {[string match *.WR.* $dutInitName]==1} {
    set PS WR
  } elseif {[string match *.AC* $dutInitName]==1} {
    set PS AC
  } elseif {[string match *DC* $dutInitName]==1} {
    set PS DC
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
    set gaSet(dutFam) $b.$r.$p.$d.$PS.$np.$up  
  }
  
  
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set gaSet(dutBox) $b
  
  puts "dutInitName:$dutInitName dutBox:$gaSet(dutBox) DutFam:$gaSet(dutFam)" ; update
}                               

# ***************************************************************************
# PPS
# ***************************************************************************
proc PPS {} {
  global gaSet
  set pps.LC.E1.1     3333
  set pps.LC.E1.4    13333
  set pps.LC.E1.8    27027
  set pps.LC.E1.16   52631  
  set pps.LC.T1.4    10000
  set pps.LC.T1.8    20000
  set pps.LC.T1.16   40000
  
  set pps.E1LC.E1.1   3333
  
  set pps.iE1T1.E1.1  3272
  set pps.iE1T1.T1.1  2454
  
  set pps.i4_8E1T1.E1.4    12000
  set pps.i4_8E1T1.E1.8    20000 ; #24000
  set pps.i4_8E1T1.T1.4     9230
  set pps.i4_8E1T1.T1.8    18461
  
  
  set pps.i16.E1.16   52631
  set pps.i16.E1.8    27027
  set pps.i16.E1.4    13333
  ## UUT with 16 ports is tested full *PACK* and
  if {[GetMountPorts]=="16"} {
    set pps.i16.E1.12 [set pps.i16.E1.16]
    set pps.i16.E1.8  [set pps.i16.E1.16]
    set pps.i16.E1.4  [set pps.i16.E1.16]
  }
  
  set pps.i16.T1.16   40000
  set pps.i16.T1.8    20000
  set pps.i16.T1.4    10000
  ##  UUT with 16 ports is tested full
  if {[GetMountPorts]=="16"} {
    set pps.i16.T1.12 [set pps.i16.T1.16]
    set pps.i16.T1.8  [set pps.i16.T1.16]
    set pps.i16.T1.4  [set pps.i16.T1.16]
  }
  
  set pps [set pps.[set gaSet(dutFam)].[set gaSet(tdm)].[set gaSet(e1)]]
  puts "PPS [set gaSet(dutFam)].[set gaSet(tdm)].[set gaSet(e1)] pps:$pps"
  
  return $pps
}
# ***************************************************************************
# PingPerform
# ***************************************************************************
proc PingPerform {uut} {
  global gaSet
  if {$gaSet(eth)=="2UTP_1SFP"} {
    set ret [Wait "Wait for Data Transmission" 80]
    return $ret
  }
  
  puts "[MyTime] PingPerform $uut"
  
  $gaSet(runTime) configure -text ""
    
  Status "Send 4 Pings to $uut"  
  for {set i 1} {$i<=4} {incr i} {
    set res [catch {exec ping.exe 1.1.1.[set gaSet(pair)][string index $uut end] -n 1} pRes]
    puts "res:$res pRes:$pRes"
    RLTime::Delay 1
  }
  set startTime [clock seconds]
  Status "Sending Pings to $uut"
  for {set i 1} {$i<=80} {incr i} {     
    if {$gaSet(act)==0} {return -2}
     
    set res [catch {exec ping.exe 1.1.1.[set gaSet(pair)][string index $uut end] -n 1} pRes]
    #puts $pRes; update
    regexp {Lost = (\d+)} $pRes - losses
    regexp {Received = (\d+)} $pRes - rcves
    if {$rcves=="1" && $losses=="0"} {
      #puts "Received==1 && Lost==0" ; update
    } else {    
      if {$losses=="1"} {
        set gaSet(fail) "There is $losses Lost of Ping to $uut"
        return -1
      } elseif {$losses>1} {
        set gaSet(fail) "There are $losses Lostes of Ping to $uut"
        return -1
      }
    }
    set nowTime [clock seconds]
    set runTime [expr {$nowTime - $startTime}]
    $gaSet(runTime) configure -text $runTime
    puts "Received==1 && Lost==0  runTime:$runTime i:$i" ; update
    if {$runTime>71} {
      set ret 0
      break
    }
    RLTime::Delay 1
  }
  return $ret
}
# ***************************************************************************
# DataTransmPerform
# ***************************************************************************
proc neDataTransmPerform {} {
  global gaSet buffer
  Etx204Start
  puts "1. 10sec"; update
  set ret [Wait "Wait for Data Transmission" 10]
  if {$ret!=0} {return $ret}
  set ret [Etx204Check]
  if {$ret!=0} {
    Etx204Start
    puts "2. 10sec"
    set ret [Wait "Wait for Data Transmission" 10]
    if {$ret!=0} {return $ret}
    set ret [Etx204Check]
    if {$ret!=0} {return $ret}
  }
  
  if {$gaSet(dutFam)=="iE1T1"} {
    Etx204Start
    puts "1. 110sec"
    set ret [Wait "Wait for Data Transmission" 110]
    if {$ret!=0} {return $ret}
    set ret [Etx204Check]
    if {$ret!=0} {return $ret}
  } else {
    set uut Uut1
    PingConnect $uut
    for {set try 1} {$try <= 3} {incr try} {
      Etx204Start
      puts "try:$try. pings to $uut"
      set ret [PingPerform $uut]
      puts "try:$try. ret of PingPerform: $ret"
      if {$ret==0} {
        set ret [Etx204Check]
        puts "try:$try. ret of Etx204Check: $ret"
        if {$ret==0} {
          break
        }
      }    
    }  
    if {$ret!=0} {return $ret}
    
    if {$gaSet(eth)=="2UTP_1SFP"} {
      ## since we do not send pings, no need to connect UUT2 and send pings there 
    } else {
      set uut Uut2
      PingConnect $uut
      for {set try 1} {$try <= 3} {incr try} {
        Etx204Start
        puts "try:$try. pings to $uut"
        set ret [PingPerform $uut]
        puts "try:$try. ret of PingPerform: $ret"
        if {$ret==0} {
          set ret [Etx204Check]
          puts "try:$try. ret of Etx204Check: $ret"
          if {$ret==0} {
            break
          }
        }    
      }  
      if {$ret!=0} {return $ret}
    }
  }
  return 0
}
# ***************************************************************************
# TogglePreLoad
# ***************************************************************************
proc TogglePreLoad {but} {
  return 
  global gaSet gaGui
  if {$but=="skip" && $gaSet(plEn)=="0"} {
    set gaSet(plEnOnly) 0
  } 
  if {$but=="only"} {
    set gaSet(plEn) 1
    if {$gaSet(plEnOnly)=="1"} {
      set gaSet(plEnOnly) 0
    } elseif {$gaSet(plEnOnly)=="0"} {
      set gaSet(plEnOnly) 1
    } 
  }
}

# ***************************************************************************
# GetMountPorts
# ***************************************************************************
proc GetMountPorts {{dut ""}} {
  global gaSet
  if {$dut==""} {
    set dut $gaSet(DutInitName)
  }
  set mountedPorts 16
  regexp {\.(\d+)} $dut - mountedPorts
  if {$mountedPorts==2} {
    ## like RICI-16T1.2T3.R.tcl
    set mountedPorts 16 
  }
  return $mountedPorts
}

# ***************************************************************************
# DownloadConfFile
# ***************************************************************************
proc DownloadConfFile {cf cfTxt save} {
  global gaSet  buffer
  puts "[MyTime] DownloadConfFile $cf $cfTxt $save"
  set com $gaSet(comDut)
  if ![file exists $cf] {
    set gaSet(fail) "The $cfTxt configuration file ($cf) doesn't exist"
    return -1
  }
  Status "Download Configuration File $cf" ; update
  set s1 [clock seconds]
  set id [open $cf r]
  set c 0
  while {[gets $id line]>=0} {
    if {$gaSet(act)==0} {close $id ; return -2}
    if {[string length $line]>2 && [string index $line 0]!="#"} {
      incr c
      #puts "line:<$line>"
      if {[string match {*address*} $line] && [llength $line]==2} {
        if {[string match *DefaultConf* $cfTxt] || [string match *RTR* $cfTxt]} {
          ## don't change address in DefaultConf
        } else {
          ##  address 10.10.10.12/24
          ##set dutIp 10.10.10.1[set gaSet(pair)]
          ##set dutIp 10.10.10.1[set gaSet(comDut)]
          set dutIp 10.10.10.1[set gaSet(com2dut.$gaSet(comDut))]
          set address [set dutIp]/[lindex [split [lindex $line 1] /] 1]
          set line "address $address"
        }
      }
      if {[string match *EXT* $cfTxt] || [string match *vvDefaultConf* $cfTxt]} {
        ## perform the configuration fast (without expected)
        set ret 0
        set buffer bbb
        RLSerial::Send $com "$line\r" 
      } else {
        set ret [Send $com $line\r 2I 60]
      }  
      if {$ret!=0} {
        set gaSet(fail) "Config of DUT failed"
        break
      }
      if {[string match {*cli error*} [string tolower $buffer]]==1} {
        set gaSet(fail) "CLI Error"
        set ret -1
        break
      }            
    }
  }
  close $id  
  if {$ret==0} {
    set ret [Send $com "exit all\r" "2I"]
    if {$save==1} {
      set ret [Send $com "admin save\r" "successfull" 60]
    }
     
    set s2 [clock seconds]
    puts "[expr {$s2-$s1}] sec c:$c" ; update
  }
  Status ""
  puts "[MyTime] Finish DownloadConfFile" ; update
  return $ret 
}
# ***************************************************************************
# Ping
# ***************************************************************************
proc Ping {dutIp} {
  global gaSet
  set i 0
  while {$i<=4} {
    if {$gaSet(act)==0} {return -2}
    incr i
    #------
    catch {exec arp.exe -d}  ;#clear pc arp table
    catch {exec ping.exe $dutIp -n 2} buffer
    if {[info exist buffer]!=1} {
	    set buffer "?"  
    }  
    set ret [regexp {Packets: Sent = 2, Received = 2, Lost = 0 \(0% loss\)} $buffer var]
    puts "ping i:$i ret:$ret buffer:<$buffer>"  ; update
    if {$ret==1} {break}    
    #------
    after 500
  }
  
  if {$ret!=1} {
    puts $buffer ; update
	  set gaSet(fail) "Ping fail"
 	  return -1  
  }
  return 0
}
# ***************************************************************************
# GetMac
# ***************************************************************************
proc GetMac {fi} {
  set macFile c:/tmp/mac[set fi].txt
  exec c:/radapps/MACServer.exe 0 1 $macFile 1
  set ret [catch {open $macFile r} id]
  if {$ret!=0} {
    set gaSet(fail) "Open Mac File fail"
    return -1
  }
  set buffer [read $id]
  close $id
  file delete $macFile)
  set ret [regexp -all {ERROR} $buffer]
  if {$ret!=0} {
    set gaSet(fail) "MACServer ERROR"
    exec beep.exe
    return -1
  }
  return [lindex $buffer 0]
}
# ***************************************************************************
# SplitString2Paires
# ***************************************************************************
proc SplitString2Paires {str} {
  foreach {f s} [split $str ""] {
    lappend l [set f][set s]
  }
  return $l
}

# ***************************************************************************
# GetDbrSW
# ***************************************************************************
proc GetDbrSW {barcode} {
  global gaSet gaGui
  set gaSet(dbrSW) ""
  set javaLoc1  C:\\Program\ Files\ (x86)\\Java\\jre6\\bin\\
  if [file exist $javaLoc1] {
    ## continue
  } else {
    set gaSet(fail) "Java application is missing"
    return -1
  }  
  catch {exec $javaLoc1\\java -jar c:/RADapps/SWVersions4IDnumber.jar $barcode} b
  puts "GetDbrSW b:<$b>" ; update
  after 1000
  if ![info exists gaSet(swPack)] {
    set gaSet(swPack) ""
  }
  set swIndx [lsearch $b $gaSet(swPack)]  
  if {$swIndx<0} {
    set gaSet(fail) "There is no SW ID for $gaSet(swPack) ID:$barcode. Verify the Barcode."
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  set dbrSW [string trim [lindex $b [expr {1+$swIndx}]]]
  puts dbrSW:<$dbrSW>
  set gaSet(dbrSW) $dbrSW
  pack forget $gaGui(frFailStatus)
  Status ""
  update
  BuildTests
  focus -force $gaGui(tbrun)
  return 0
}
# ***************************************************************************
# SwMulti
# ***************************************************************************
proc SwMulti {ch} {
  global gaSet
  package require RLEH
  package require RLUsbMmux    
  RLEH::Open
  set gaSet(idMulti) [RLUsbMmux::Open 4]
  RLUsbMmux::AllNC $gaSet(idMulti)
  if {$ch!="NC"} {
     RLUsbMmux::BusState $gaSet(idMulti) "A,B,C,D"
     RLUsbMmux::ChsCon $gaSet(idMulti) $ch
  }
  RLUsbMmux::Close $gaSet(idMulti) 
  RLEH::Close
}

# ***************************************************************************
# MassConnect
# ***************************************************************************
proc MassConnect {massNum} {
	global gaSet 
  puts "MassConnect $massNum"
	set gaSet(massNum) $massNum
	RL[set gaSet(pioType)]Mmux::AllNC $gaSet(mmuxMassId)  
  RLTime::Delay 1
  if {$massNum=="NC"} {return 0}
  if {$massNum<="7"} {
    RL[set gaSet(pioType)]Mmux::BusState $gaSet(mmuxMassId) "A,B,C,D"
  } elseif {$massNum>="8" && $massNum<="14"} {
    RL[set gaSet(pioType)]Mmux::BusState $gaSet(mmuxMassId) "A B,C,D"
  } elseif {$massNum>="15" && $massNum<="21"} {
    RL[set gaSet(pioType)]Mmux::BusState $gaSet(mmuxMassId) "A B C,D"
  } elseif {$massNum>"21"} {
    RL[set gaSet(pioType)]Mmux::BusState $gaSet(mmuxMassId) "A B C D"
  }
  RL[set gaSet(pioType)]Mmux::ChsCon $gaSet(mmuxMassId) $massNum,28                 
	return 0
}
# ***************************************************************************
# ToolsMassConnect
# ***************************************************************************
proc ToolsMassConnect {massNum} {
	global gaSet
	set gaSet(mmuxMassId) [RL[set gaSet(pioType)]Mmux::Open $gaSet(mmuxMassPort)]  
	MassConnect $massNum  
	RL[set gaSet(pioType)]Mmux::Close $gaSet(mmuxMassId)  
  return 0
}