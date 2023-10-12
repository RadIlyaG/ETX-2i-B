# ***************************************************************************
# EntryBootMenu
# ***************************************************************************
proc EntryBootMenu {} {
  global gaSet buffer
  puts "[MyTime] EntryBootMenu"; update
  set ret [Send $gaSet(comDut) \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
  set ret [Send $gaSet(comDut) \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
#   set ret [Reset2BootMenu $uut]
#   if {$ret!=0} {return $ret}
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="V"|| $b=="DNFV"} {
    set ret [DnfvPower off]
    if {$ret!=0} {
      set gaSet(fail) "DNFV Power OFF fail"
      return -1
    }
  }
  Power all off
  RLTime::Delay 2
  Power all on
  RLTime::Delay 2
  Status "Entry to Boot Menu"
  set gaSet(fail) "Entry to Boot Menu fail"
  set ret [Send $gaSet(comDut) \r "stop auto-boot.." 20]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) \r\r "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  return 0
}

# ***************************************************************************
# DownloadUsbPortApp
# ***************************************************************************
proc DownloadUsbPortApp  {} { 
  global gaSet buffer
  puts "[MyTime] DownloadUsbPortApp"; update
  set gaSet(fail) "Config IP in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c ip\r" "(ip)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "10.10.10.1$gaSet(pair)\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
    
  set gaSet(fail) "Config DM in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c dm\r" "(dm)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "255.255.255.0\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config SIP in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c sip\r" "(sip)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "10.10.10.10\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config GW in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c g\r" "(g)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "10.10.10.10\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config TFTP in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c p\r" "ftp\]"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "tftp\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $gaSet(comDut) "\r" "\[boot\]:"]
  if {$ret!=0} {return $ret} 
  
  set gaSet(fail) "Start \'download 3,sw-pack_2i_USB_test.bin\' fail"
  set ret [Send $gaSet(comDut) "download 3,sw-pack_2i_USB_test.bin\r" "transferring" 3]
  if [string match {*you sure(y/n)*} $buffer] {
    set ret [Send $gaSet(comDut) "y\r" "transferring"]    
  }
  if {$ret!=0} {return $ret} 
  
  set startSec [clock seconds]
  while 1 {
    Status "Wait for application downloading"
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set dwnlSec [expr {$nowSec - $startSec}]
    #puts "dwnlSec:$dwnlSec"
    $gaSet(runTime) configure -text $dwnlSec
    if {$dwnlSec>500} {
      set ret -1 
      break
    }
    set ret [RLSerial::Waitfor $gaSet(comDut) buffer "\[boot\]:" 2]
    puts "<$dwnlSec><$buffer>" ; update
    if {$ret==0} {break}
    if [string match {*\[boot\]*} $buffer] {
      set ret 0
      break
    }
  }  
  if {$ret=="-1"} {
    set gaSet(fail) "Download \'3,sw-pack_2i_usb.bin\' fail"
    return -1 
  }
  
  set gaSet(fail) "\'set-active 3\' fail" 
  set ret [Send $gaSet(comDut) "set-active 3\r" "\[boot\]:" 15]
  if {$ret!=0} {return $ret}  
  Status "Wait for Loading/un-compressing sw-pack-3"
  set ret [Send $gaSet(comDut) "run 3\r" "sw-pack-3.." 15]
  if {$ret!=0} {return $ret} 
          
  return 0
}  
# ***************************************************************************
# CheckUsbPort
# ***************************************************************************
proc CheckUsbPort {} {
  puts "[MyTime] CheckUsbPort"; update
  global gaSet buffer accBuffer
  
 ### 13/07/2016 15:06:43 6.0.1 reads the USB port without a special app 
#   set startSec [clock seconds]
#   while 1 {
#     if {$gaSet(act)==0} {return -2}
#     set nowSec [clock seconds]
#     set dwnlSec [expr {$nowSec - $startSec}]
#     #puts "dwnlSec:$dwnlSec"
#     $gaSet(runTime) configure -text $dwnlSec
#     update
#     if {$dwnlSec>120} {
#       set ret -1 
#       break
#     }
#     set ret [RLSerial::Waitfor $gaSet(comDut) buffer "user>" 2]
#     append accBuffer [regsub -all {\s+} $buffer " "]
#     $gaSet(runTime) configure -text $dwnlSec
#     puts "<$dwnlSec><$buffer>" ; update
#     if {$ret==0} {break}
#     if [string match {*user>*} $buffer] {
#       set ret 0
#       break
#     }
#   }  
#   if {$ret=="-1"} {
#     set gaSet(fail) "Getting \'user>\' fail"
#     return -1 
#   }
#   
# #   if [string match {*A device is connected to Bus:000 Port:0*} $accBuffer] {
# #     set ret 0
# #   } else {
# #     set ret -1
# #     set gaSet(fail) "USB port doesn't recognize device on Bus:000 Port:0"
# #   }
#   #set ret [Send $gaSet(comDut) "run 3\r" "sw-pack-3.." 15]
#   
  Status "USB port Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read USB port"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read USB port fail"
  
  set sw $::sw ; # 6.2.1(0.44)
  set majSW [string range $sw 0 [expr {[string first ( $sw] - 1}]]; # 6.2.1
  
  puts "sw:$sw majSW:$majSW"
  if {$majSW<6.3} {
    set ret [Send $com "debug test usb\r" ETX-2I]
    if {$ret!=0} {return $ret}
    
  #   if {[string match {*DEV*Mouse*} $buffer] || \
  #       [string match {*DEV*Keyboard*} $buffer]} {}
  ## 05/07/2017 07:46:19 Just DEV
    if {[string match {*DEV*} $buffer]} {    
      set ret 0
    } else {
      set ret -1
      set gaSet(fail) "USB port doesn't recognize any USB DEV"
    }        
  } else {
    set ret [Send $com "debug usb display-device-param\r" ETX-2I]
    if {$ret!=0} {return $ret}
  
    if {[string match {*USB device in*} $buffer]} {    
      set ret 0
    } else {
      set ret -1
      set gaSet(fail) "USB port doesn't recognize USB device"
    }
  } 
  return $ret
}  
# ***************************************************************************
# DeleteUsbPortApp
# ***************************************************************************
proc DeleteUsbPortApp {} { 
  puts "[MyTime] DeleteUsbPortApp"; update
  global gaSet buffer
  set gaSet(fail) "Delete UsbPort App fail"
  set ret [Send $gaSet(comDut) "set-active 1\r" "\[boot\]:" 15]
  if {$ret!=0} {return $ret} 
  set ret [Send $gaSet(comDut) "delete sw-pack-3\r" "\[boot\]:" 15]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "run\r" "sw-pack-1.." 15]
  if {$ret!=0} {return $ret} 
  return $ret
}  

# ***************************************************************************
# FansTemperatureTest
# ***************************************************************************
proc FansTemperatureTest {} {
  global gaSet buffer
  Status "FansTemperatureTest"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read thermostat"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Write to thermostat fail"
  set ret [Send $com "debug thermostat\r" thermostat]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point upper 60\r" thermostat]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point lower 55\r" thermostat]
  if {$ret!=0} {return $ret}
  
  scan $gaSet(dbrSW) %3d\.%3d\.%3d(%3d\.%3d) v1 v2 v3 v4 v5
  set sw $v1.$v2.$v3.$v4.$v5
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="19V"} {
    set fanState1 "off off off off"
  } elseif {$b=="19" && $p=="0" && $d=="0"} {
    set fanState1 "off off off off"
  } elseif {$b=="19" && ($p=="1" || $d=="1"} {
    set fanState1 "off off on on"
  } elseif {$b=="M" && && $p=="0" && $d=="0"} {
    set fanState1 "off off off off"
  } elseif {$b=="M" && && $p=="1"} {
    set fanState1 "on on on on"
  }
  puts "b:$b r:$r p:$p d:$d sw:$sw fanState1:$fanState1"
      
  set gaSet(fail) "Read from thermostat fail"
  for {set i 1} {$i<=40} {incr i} {
    puts "i:$i wait for \'$fanState1\'" ; update
    set ret [Send $com "show status\r" thermostat]
    if {$ret!=0} {return $ret}

    set res [string match *$fanState1* $buffer]
    if {$res=="1"} {
      break
    }
    after 2000
  }
  if {$res!="1"} {
    set gaSet(fail) "\'$fanState1\' doesn't apprear"
    return -1
  }
  regexp  {Current:\s([\d\.]+)\s} $buffer - ct1
  puts "ct1:$ct1"  
  
  set gaSet(fail) "Write to thermostat fail"
  set ret [Send $com "set-point lower 20\r" thermostat]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point upper 30\r" thermostat]
  if {$ret!=0} {return $ret}
  
  if {$b=="19V"} {
    set fanState2 "off on on on"
  } elseif {$b=="19" && $p=="0" && $d=="0"} {
    set fanState2 "off off on on"
  } elseif {$b=="19" && ($p=="1" || $d=="1"} {
    set fanState2 "off off on on"
  } elseif {$b=="M" && && $p=="0" && $d=="0"} {
    set fanState2 "on on on on"
  } elseif {$b=="M" && && $p=="1"} {
    set fanState2 "on on on on"
  }
  puts "b:$b r:$r p:$p d:$d sw:$sw fanState2:$fanState2"
    
  set gaSet(fail) "Read from thermostat fail"
  for {set i 1} {$i<=40} {incr i} {
    puts "i:$i wait for \'$fanState2\'" ; update
    set ret [Send $com "show status\r" thermostat]
    if {$ret!=0} {return $ret}
    set res [string match *$fanState2* $buffer]
    if {$res=="1"} {
      break
    }
    after 2000
  }
  if {$res!="1"} {
    set gaSet(fail) "\'$fanState2\' doesn't apprear"
    return -1
  }
 
  if {$fanState1!=$fanState2} {
    ## if we turn off the fans, the temperature should change and we should check it
    set gaSet(fail) "Read from thermostat fail"
    for {set i 1} {$i<=5} {incr i} {
      set ret [Send $com "show status\r" thermostat 1]
      if {$ret!=0} {return $ret}
      regexp  {Current:\s([\d\.]+)\s} $buffer - ct2 
      puts "i:$i ct2:$ct2" ; update
      if {$ct2!=$ct1} {
        set ret 0
        break
      }
      after 2000
    }  
    if {$ct2==$ct1} {
      
      set gaSet(fail) "\"Current\" doesn't change: $ct2"
      return -1
    }
  }
  
  set gaSet(fail) "Write to thermostat fail"
  set ret [Send $com "set-point upper 40\r" thermostat 1]
  if {$ret!=0} {return $ret}
  set ret [Send $com "set-point lower 32\r" thermostat 1]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# SK_IDTest
# ***************************************************************************
proc SK_IDTest {} {
  global gaSet buffer
  Status "SK_ID Test"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  set gaSet(fail) "Read SK version fail"
  set ret [Send $com "exit all\r" ETX-2I]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure qos queue-group-profile \"DefaultQueueGroup\" queue-block 0/1\r" (0/1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" #]
  if {$ret!=0} {return $ret}
  set ret [Send $com "queue-block 0/2\r" (0/2)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" #]
  if {$ret!=0} {return $ret}
  set ret [Send $com "queue-block 0/3\r" stam 1]
  #if {$ret!=0} {return $ret}
  
  if {$gaSet(sk)=="BSK" && [string match {*cli error: License limitation*} $buffer]} {
    set ret 0
  } elseif {$gaSet(sk)=="BSK" && ![string match {*cli error: License limitation*} $buffer]} {
    set ret -1
  } elseif {$gaSet(sk)=="ESK" && [string match {*cli error: License limitation*} $buffer]} {
    set ret -1
  } elseif {$gaSet(sk)=="ESK" && ![string match {*cli error: License limitation*} $buffer]} {
    set ret 0
  }
  if {$ret=="-1"} {
    set gaSet(fail) "The $gaSet(sk) unmatch License limitation"
  }
  return $ret
}
# ***************************************************************************
# PS_IDTest
# ***************************************************************************
proc PS_IDTest {} {
  global gaSet buffer
  Status "PS_ID Test"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  Status "Read info"
  set com $gaSet(comDut)  
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="RJIO"} { 
    set portL [list 0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8 0/9 0/10]
  } elseif {$b=="V" || $b=="2iB"} {
    set portL [list 0/1 0/2]
    if {$up=="8SFP"} {
      set portL [concat $portL [list 0/3 0/4 0/5 0/6 0/7 0/8 0/9 0/10]]
    } elseif {$up=="2CMB"} {
      set portL [concat $portL [list 0/3 0/4]]
    } elseif {$up=="4SFP"} {
      set portL [concat $portL [list 0/3 0/4 0/5 0/6]]
    } elseif {$up=="4UTP"} {
      ## don't check utp
    } elseif {$up=="4SFP4UTP"} {
      set portL [concat $portL [list 0/7 0/8 0/9 0/10]]
    }
  } 
  foreach port $portL {
    set ret [ReadEthPortStatus $port "SFP In"]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    
  }
  
  set ret [Send $com "exit all\r" ETX-2I]
  if {$ret!=0} {return $ret}
  if {$b=="RJIO"} { 
    set portL [list 0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8 0/9 0/10]
  } elseif {$b=="V" || $b=="2iB"} {
    set portL [list 0/1 0/2]
    if {$up=="8SFP"} {
      set portL [concat $portL [list 0/3 0/4 0/5 0/6 0/7 0/8 0/9 0/10]]
    } elseif {$up=="2CMB"} {
      set portL [concat $portL [list 0/3 0/4]]
    } elseif {$up=="4SFP"} {
      set portL [concat $portL [list 0/3 0/4 0/5 0/6]]
    } elseif {$up=="4UTP"} {
      set portL [concat $portL [list 0/3 0/4 0/5 0/6]]
    } elseif {$up=="4SFP4UTP"} {
      set portL [concat $portL [list 0/7 0/8 0/9 0/10]]
    }
  }
  set ret [ReadEthPortsStatus $portL]
  if {$ret=="-2"} {return $ret}
  if {$ret=="-1"} {
    Wait "Wait for Show Summary" 20 
    set ret [ReadEthPortsStatus $portL]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
  }
  
  set ret [Send $com "exit all\r" ETX-2I]
  if {$ret!=0} {return $ret}
  set ret [Send $com "info\r" more 45]  
#   regexp {sw\s+\"(\d+\.\d+\.\d+)\(} $buffer - sw
#   regexp {sw\s+\"(.+)\"\s} $buffer - sw
  
  catch {unset ::sw}
  regexp {sw\s+\"([\.\d\(\)\w]+)\"\s} $buffer - sw
  
  if ![info exists sw] {
    set gaSet(fail) "Can't read the SW version"
    return -1
  }
  set ::sw $sw
  
  ## 10/01/2017 09:28:04  don't do any exception for RJIO
  set dbrSW [set gaSet(dbrSW)]
#   if {$b=="RJIO"} {
#     set dbrSW [set gaSet(dbrSW)]SR
#     
#     set dbrSW 6.2.0(0.24)SR ; #6.0.1(0.32)SR
#     AddToLog "set dbrSW 6.0.1(0.32)SR !!!!!"
#     puts "set dbrSW 6.0.1(0.32)SR !!!!!" ; update
#     
#   } else {
#     set dbrSW [set gaSet(dbrSW)]
#   }  
  
  puts "sw:<$sw> dbrSW:<$dbrSW> r:<$r>" ; update
  set gaSet(fail) "Can't reach the \'ETX-2I\' prompt"
  set ret [Send $com "\3" ETX-2I 3.25]
  if {$ret!=0} {return $ret}
  
  if {[string range $sw end-1 end]=="SR" && $r=="R"} {
    set gaSet(fail) "The sw is \"$sw\" and the DUT is RTR"
    return -1
  }
  if {[string range $sw end-1 end]!="SR" && $r=="0"} {
    set gaSet(fail) "The sw is \"$sw\" and the DUT is not RTR"
    return -1
  }
  
  if {[string range $sw end-1 end]=="SR"} {
    puts "sw1:$sw"
    set sw [string range $sw 0 end-2]  
    puts "sw2:$sw"
  }
  if {$sw!=$dbrSW} {
    set gaSet(fail) "SW is \"$sw\". Should be \"$dbrSW\""
    return -1
  }
  
#   if {$b=="RJIO"} { 
#     set portL [list 0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8 0/9 0/10]
#   } elseif {$b=="V" || $b=="2iB"} {
#     set portL [list 0/1 0/2]
#     if {$up=="8SFP"} {
#       set portL [concat $portL [list 0/3 0/4 0/5 0/6 0/7 0/8 0/9 0/10]]
#     } elseif {$up=="2CMB"} {
#       set portL [concat $portL [list 0/3 0/4]]
#     } elseif {$up=="4SFP"} {
#       set portL [concat $portL [list 0/3 0/4 0/5 0/6]]
#     } elseif {$up=="4UTP"} {
#       ## don't check utp
#     }
#   } 
#   foreach port $portL {
#     set ret [ReadEthPortStatus $port]
#     if {$ret=="-1" || $ret=="-2"} {return $ret}
#     
#   }

  if [string match *MOT.H.* $gaSet(DutInitName)] {
    set ret [Send $com "exit all\r" ETX-2I]
    if {$ret!=0} {return $ret}
    set ret [Send $com "configure chassis\r" chassis]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show environment\r" chassis]
    if {$ret!=0} {return $ret}

    set val "FAN NA"
    set res [regexp {(FAN[\s\-A-Za-z\d]+)Sensor} $buffer ma val]
    if {$res==0} {
      set gaSet(fail) "Fail to get FAN status"
      return -1
    }
    if [string match {*FAN Status - 1 OK*} $ma] {
      ## OK
    } else {
      set gaSet(fail) "$val"
      return -1
    }
  }
  
  set ret [ReadMac]
  if {$ret!=0} {return $ret}
  
  puts "b:<$b>" ; update
  if {$b!="DNFV"} {
    set ret [ReadCPLD]
    if {$ret!=0} {return $ret}
    if {[info exists gaSet(uutBootVers)]} {
      puts "PS_ID gaSet(uutBootVers):<$gaSet(uutBootVers)>" ; update
    }
    if {![info exists gaSet(uutBootVers)] || $gaSet(uutBootVers)==""} {
      set ret [Send $com "exit all\r" 2I]
      if {$ret!=0} {return $ret}
      set ret [Send $com "admin reboot\r" "yes/no"]
      if {$ret!=0} {return $ret}
      set ret [Send $com "y\r" "seconds" 20]
      if {$ret!=0} {return $ret}
      Wait "Wait ETX rebooting" 10
      if {$ret!=0} {return $ret}
      set ret [Login]
      if {$ret!=0} {return $ret}
    }
    
    puts "gaSet(uutBootVers):<$gaSet(uutBootVers)>"
    puts "gaSet(dbrBVer):<$gaSet(dbrBVer)>"
    update
    if {$gaSet(uutBootVers)!=$gaSet(dbrBVer)} {
      set gaSet(fail) "Boot Version is \"$gaSet(uutBootVers)\". Should be \"$gaSet(dbrBVer)\""
      return -1
    }
    set gaSet(uutBootVers) ""
  }
  
  return $ret
  
  ##########################################################
  
  set ret [Send $com "\3" ETX-2I 0.25]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" ETX-2I]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set psQty [regexp -all $ps $buffer]
  if {$psQty!=2} {
    set gaSet(fail) "Qty or type of PSs is wrong."
#     AddToLog $gaSet(fail)
    return -1
  }
  #regexp {\-+\s(.+)\s+FAN} $buffer - psStatus
  regexp {\-+\s(.+\s+FAN)} $buffer - psStatus
  regexp {1\s+\w+\s+([\s\w]+)\s+2} $psStatus - ps1Status
  set ps1Status [string trim $ps1Status]
  
  ## remove HP (from "AC HP")
  if {[lindex [split $ps1Status " "] 0]=="HP"} {
    set ps1Status [lrange [split $ps1Status " "] 1 end ]
  }
  if {$ps1Status!="OK"} {
    set gaSet(fail) "Status of PS-1 is \'$ps1Status\'. Should be \'OK\'"
#     AddToLog $gaSet(fail)
    return -1
  }
  regexp {2\s+\w+\s+([\s\w]+)\s+} $psStatus - ps2Status
  set ps2Status [string trim $ps2Status]
  ## remove HP (from "AC HP")
  if {[lindex [split $ps2Status " "] 0]=="HP"} {
    set ps2Status [lrange [split $ps2Status " "] 1 end ]
  }
  if {$ps2Status!="OK"} {
    set gaSet(fail) "Status of PS-2 is \'$ps2Status\'. Should be \'OK\'"
#     AddToLog $gaSet(fail)
    return -1
  }

 
  return $ret
}
# ***************************************************************************
# DyingGaspSetup
# ***************************************************************************
proc DyingGaspSetup {} {
  global gaSet buffer gRelayState
  Status "DyingGaspTest"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(DGaspCF)
  set cfTxt "Dying Gasp"
  set ret [DownloadConfFile $cf $cfTxt 1]
  if {$ret!=0} {return $ret}
  
  set goodPings 0
  set dutIp 10.10.10.1[set gaSet(pair)]  
  for {set i 1} {$i<=20} {incr i} {   
    set ret [Ping $dutIp]
    puts "DyingGaspSetup ping after download i:$i ret:$ret"
    if {$ret!=0} {return $ret}
    incr goodPings
    if {$goodPings==3} {
      break
    }
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="V"|| $b=="DNFV"} {
    set ret [DnfvPower off]
    if {$ret!=0} {
      set gaSet(fail) "DNFV Power OFF fail"
      return -1
    }
  }
  
  Power all off
  after 3000
  Power all on
  
  Wait "Wait ETX booting" 35
  if {$ret!=0} {return $ret}
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }

#   set snmpId [RLScotty::SnmpOpen $dutIp]
#   RLScotty::SnmpConfig $snmpId -version SNMPv3 -user initial
  return $ret
}    
 
# ***************************************************************************
# DyingGaspPerf
# ***************************************************************************
proc DyingGaspPerfScotty {psOffOn psOff} {
  global trp tmsg gaSet
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set dutIp 10.10.10.1[set gaSet(pair)]
  set ret [Ping $dutIp]
  if {$ret!=0} {return $ret}
  
  RLScotty::SnmpCloseAllTrap
  catch {exec arp.exe -d $dutIp} resArp
  puts "[MyTime] resArp:$resArp"
  
  for {set wc 1} {$wc<=10} {incr wc} {
    set trp(id) [RLScotty::SnmpOpenTrap tmsg]
    puts "wc:$wc trp(id):$trp(id)"
    if {$trp(id)=="-1"} {
      set ret -1
      set gaSet(fail) "Open Trap failed"
      set ret [Wait "Wait for SNMP session" 5 white]
      if {$ret!=0} {return $ret}
    } else {
      set ret 0
      break
    }
  }
  if {$ret!=0} {return $ret}
  RLScotty::SnmpConfigTrap $trp(id) -version SNMPv3 -user initial ; #SNMPv2c ;# SNMPv1 , SNMPv2c , SNMPv3
  
  set tmsg ""
  #Power $psOff off
  set ret [Send $com "configure port ethernet 0/1\r" "0/1"]
  if {$ret!=0} {
    RLScotty::SnmpCloseTrap $trp(id)
    return $ret
  }
  
  set ret -1
  for {set i 1} {$i<=5} {incr i} {
    set tmsg ""
    set ret [Send $com "shutdown\r" "0/1"]
    if {$ret==0} {
      after 1000
      set ret [Send $com "no shutdown\r" "0/1"]
      if {$ret!=0} {
        RLScotty::SnmpCloseTrap $trp(id)
        return $ret
      }
    } 
    puts "i:$i tmsgStClk:<$tmsg>"
    if {$tmsg!=""} {
      set ret 0
      #break
    }
    after 1000
  }
  if {$ret=="-1"} {
    set gaSet(fail) "Trap is not sent"
    RLScotty::SnmpCloseTrap $trp(id)
    return -1
  }
  
  #after 3000
  Wait "Wait for traps" 10 white
  set tmsg ""
  
  Power $psOffOn on
  Power $psOff off
  Wait "Wait for trap 1" 3 white
  puts "tmsgDG 1.1:<$tmsg>"
  set tmsg ""
  puts "tmsgDG 1.2:<$tmsg>"
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="V"|| $b=="DNFV"} {
    set ret [DnfvPower off]
    if {$ret!=0} {
      set gaSet(fail) "DNFV Power OFF fail"
      return -1
    }
  }
  
  Power $psOffOn off
  Wait "Wait for trap 2" 3 white 
   
  #set ret [regexp -all "$dutIp\[\\s\\w\\:\\-\\.\\=\]+\\\"\\w+\\\"\[\\s\\w\\:\\-\\.\\=\]+\\\"\[\\w\\:\\-\\.\]+\\\"\[\\s\\w\\:\\-\\.\\=\]+\\\"\[\\w\\-\]+\\\"" $tmsg v]  
  puts "tmsgDG 2:<$tmsg>"
  set res [regexp "from\\s$dutIp:\\s\.\+\:systemDyingGasp" $tmsg -]
  Power $psOffOn on
  
  # Close sesion:
  RLScotty::SnmpCloseTrap $trp(id)  

  if {$res==1} {
    set ret 0
  } elseif {$res==0} {
    set ret -1
    set gaSet(fail) "No \"DyingGasp\" trap was detected"
  }
  return $ret
  
}
# ***************************************************************************
# DyingGaspPerfTshark
# ***************************************************************************
proc DyingGaspPerf {psOffOn psOff} {
  global trp tmsg gaSet
  puts "[MyTime] DyingGaspPerf $psOffOn $psOff"
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
#   set com $gaSet(comDut)
#   Send $com "exit all\r" stam 0.25 

  set ret [Wait "Wait for Management up" 130 white]
  if {$ret!=0} {return $ret}
    
  set wsDir C:\\Program\ Files\\Wireshark
  set npfL [exec $wsDir\\tshark.exe -D]
  
#   ## 1. \Device\NPF_{3EEEE372-9D9D-4D45-A844-AEA458091064} (ATE net)
#   ## 2. \Device\NPF_{6FBA68CE-DA95-496D-83EA-B43C271C7A28} (RAD net)
#   set intf 1 ; ## ATE
#   
#   ##1. \Device\NPF_{3DB9307D-AEDE-443F-BB6C-0AF58BE7EB06} (RAD net)
#   ##2. \Device\NPF_{68176654-734E-4851-9A7B-C2365D8E7DC5} (ATE net)
#   set intf 2 ; ## ATE
  
  set intf ""
  foreach npf [split $npfL "\n\r"] {
    set res [regexp {(\d)\..*ATE} $npf - intf] ; puts "<$res> <$npf> <$intf>"
    if {$res==1} {break}
  }
  if {$res==0} {
    set gaSet(fail) "Get ATE net's Network Interface fail"
    return -1
  }
  
  Status "Wait for Ping traps"
  set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  set dur 8
  exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &
  after 1000
  set dutIp 10.10.10.1[set gaSet(pair)]
  set ret [Ping $dutIp]
  if {$ret!=0} {return $ret}
  after "[expr {$dur +1}]000" ; ## one sec more then duration
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\r[MyTime] Ping resFile:$resFile ---<$monData>---\r"; update
  
  set res [regexp -all "Src: $dutIp, Dst: 10.10.10.10" $monData]
  puts "res:$res"
  if {$res<2} {
    set gaSet(fail) "2 Ping traps did not sent"
    return -1
  }
  file delete -force $resFile
  
  #catch {exec arp.exe -d $dutIp} resArp
  #puts "[MyTime] resArp:$resArp"
  
  for {set logOutIn 1} {$logOutIn<=5} {incr logOutIn} {
    puts "\n start logOutIn $logOutIn"
    if {$gaSet(act)==0} {return -2}
    #Send $gaSet(comDut) logout\r user
    after 1000
    Status "Wait for Login trap"
    set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
    set dur 6
    
    #set sec1 [clock seconds]
    exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &
    #after 1000
    set dutIp 10.10.10.1[set gaSet(pair)]
    #set sec3  [clock seconds]
    Send $gaSet(comDut) logout\r user
    #set sec4  [clock seconds]
    Send $gaSet(comDut) su\r password
    Send $gaSet(comDut) 1234\r ETX
    #set sec2 [clock seconds]
    #puts "[expr {$sec2 - $sec4}]" ; update
    #puts "[expr {$sec2 - $sec3}]" ; update
    #puts "[expr {$sec2 - $sec1}]" ; update
    if {$ret!=0} {return $ret}
    after "[expr {$dur +1}]000" ; ## one sec more then duration
    set id [open $resFile r]
      set monData [read $id]
      set ::md $monData 
    close $id  
  
    puts "\r[MyTime] logOutIn_$logOutIn resFile:$resFile ---<$monData>---\r"; update
    
    set framsL [regexp -all -inline "Src: $dutIp.+?\\n\\n" $monData]
    if {[llength $framsL]==0} {
      set gaSet(fail) "No frame from $dutIp was detected"
      continue
    }
    
    ## 6c 6f 67 69 6e    == login
    ## 6c 6f 67 6f 75 74 == logout
    set res 0
    foreach fram $framsL {
      puts "\rFrameA---<$fram>---\r"; update
      if {[string match *6c6f67696e* $fram] || [string match *6c6f676f7574* $fram]} {
        set res 1
        file delete -force $resFile
        break
      }
    } 
    if {$res} {
      puts "\rFrameB---<$fram>---\r"; update
    }
    if {$res==1} {
      set ret 0
      break
    } elseif {$res==0} {
      set ret -1
      set gaSet(fail) "No \"Login\" trap was detected"
    }
      
    file delete -force $resFile  
  }
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="V"|| $b=="DNFV"} {
    set ret [DnfvPower off]
    if {$ret!=0} {
      set gaSet(fail) "DNFV Power OFF fail"
      return -1
    }
  }
  Power $psOffOn on
  Power $psOff off
  
  Status "Wait for Dying Gasp trap"
  set dur 10
  set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  catch {exec C:\\Program\ Files\\Wireshark\\tshark.exe -i $intf -O snmp -x -S lIsT -a duration:$dur  -A "c:\\temp\\tmp.cap" > [set resFile] &} rr
  ##10/04/2019 11:49:31 exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile &
  after 5000
  
  #10/04/2019 11:49:34 after 1000
  Power $psOffOn off
  after 1000
  Power $psOffOn on
  
  ## one more sec then duration, minus 5 sec after starting of tshark
  after "[expr {$dur - 5 + 1}]000"
  
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\r[MyTime] resFile:$resFile MonData---<$monData>---\r"; update
  
  
  ## 4479696e672067617370
  ## D y i n g   g a s p
  set framsL [regexp -all -inline "Src: $dutIp.+?\\n\\n" $monData]
  if {[llength $framsL]==0} {
    set gaSet(fail) "No frame from $dutIp was detected"
    return -1
  }
  
  set res 0
  foreach fram $framsL {
    puts "\rFrameA---<$fram>---\r"; update
    if [string match *4479696e672067617370* $fram] {
      set res 1
      file delete -force $resFile
      break
    }
  } 
  if {$res} {
    puts "\rFrameB---<$fram>---\r"; update
  }
#   set frameQty [expr {[regexp -all "Frame " $monData] - 1}]
#   for {set fFr 1; set nextFr 2} {$fFr <= $frameQty} {incr fFr} {
#     puts "fFr:$fFr  nextFr:$nextFr"
#     if [regexp "Frame $fFr:.*\\sFrame $nextFr" $monData m] {
#       if [regexp "Src: [set dutIp].*" $m mm] {
#         if [string match *4479696e672067617370* $mm] {
#           puts $mm
#           set res 1
#         }
#       }
#     }
#     puts ""
#     
#     incr nextFr
#     if {$nextFr>$frameQty} {set nextFr 99}
#   }
# 
#   

  if {$res==1} {
    set ret 0
  } elseif {$res==0} {
    set ret -1
    set gaSet(fail) "No \"DyingGasp\" trap was detected"
  }
  return $ret
  
}

# ***************************************************************************
# XFP_ID_Test
# ***************************************************************************
proc XFP_ID_Test {} {
  global gaSet buffer
  Status "XFP_ID_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  
  foreach 10Gp {3/1 3/2 4/1 4/2} {
    if {$gaSet(10G)=="2" && ($10Gp=="3/1" || $10Gp=="3/2")} {
      continue
    }
    if {$gaSet(10G)=="3" && $10Gp=="3/2"} {
      continue
    }
    Status "XFP $10Gp ID Test"
    set gaSet(fail) "Read XFP status of port $10Gp fail"
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure port ethernet $10Gp\r" #]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show status\r" "MAC Address" 20]
    if {$ret!=0} {return $ret}
    set b $buffer
    set ::b1 $b
      
    set ret [Send $com "\r" #]
    if {$ret!=0} {return $ret}
    append b $buffer
    set ::b2 $b
    set res [regexp {Connector Type\s+:\s+(.+)Auto} $b - connType]
    set connType [string trim $connType]
    if {$connType!="XFP In"} {
      set gaSet(fail) "XFP status of port $10Gp is \"$connType\". Should be \"XFP In\"" 
      set ret -1
      break 
    }
    set xfpL [list "XFP-1D" XPMR01CDFBRAD]
    regexp {Part Number[\s:]+([\w\-]+)\s} $b - xfp
    if ![info exists xfp] {
      puts "b:<$b>"
      puts "b1:<$::b1>"
      puts "b2:<$::b2>"
      set gaSet(fail) "Port $10Gp. Can't read XFP's Part Number"
      return -1
    }
#     if {$xfp!="XFP-1D"} {}
    if {[lsearch $xfpL $xfp]=="-1"} {
      set gaSet(fail) "XFP Part Number of port $10Gp is \"$xfp\". Should be one from $xfpL" 
      set ret -1
      break 
    }    
  }
  return $ret  
}

# ***************************************************************************
# SfpUtp_ID_Test
# ***************************************************************************
proc SfpUtp_ID_Test {} {
  global gaSet buffer
#   if {$gaSet(1G)=="10UTP" || $gaSet(1G)=="20UTP"} {
#     ## don't check ports UTP
#     return 0
#   }
  Status "SfpUtp_ID_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  
  foreach 1Gp {1/1 1/2 1/3 1/4 1/5 1/6 1/7 1/8 1/9 1/10 2/1 2/2 2/3 2/4 2/5 2/6 2/7 2/8 2/9 2/10} {
    if {($gaSet(1G)=="10SFP" || $gaSet(1G)=="10UTP") && [lindex [split $1Gp /] 0]==2} {
      ## dont check ports 2/x
      continue
    }
#     if {$gaSet(1G)=="10UTP" || $gaSet(1G)=="20UTP"} {
#       ## dont check ports UTP
#       set ret 0
#       break
#     }
#     if {$gaSet(1G)=="10SFP_10UTP" && [lindex [split $1Gp /] 0]==2} {
#       ## dont check ports UTP  2/x
#       continue
#     }
    Status "SfpUtp $1Gp ID Test"
    set gaSet(fail) "Read SfpUtp status of port $1Gp fail"
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure port ethernet $1Gp\r" #]
    if {$ret!=0} {return $ret}
    if [string match {*Entry instance doesn't exist*} $buffer] {
      set gaSet(fail) "Status of port $1Gp is \"Entry instance doesn't exist\"." 
      set ret -1
      break
    }
    set ret [Send $com "show status\r\r" "#" 20]
    if {$ret!=0} {return $ret}    
    set res [regexp {Connector Type\s+:\s+(.+)Auto} $buffer - connType]
    set connType [string trim $connType]
    if {([lindex [split $1Gp /] 0]==1 && ($gaSet(1G)=="10UTP" || $gaSet(1G)=="20UTP")) ||\
        ([lindex [split $1Gp /] 0]==2 && ($gaSet(1G)=="10SFP_10UTP" || $gaSet(1G)=="20UTP"))} {
      ## 1/x ports
      ## 2/x ports
      set conn "RJ45" 
      set name "UTP"
    } else {
      set conn "SFP In"
      set name "SFP"
    } 
    
    if {$connType!=$conn} {
      set gaSet(fail) "$name status of port $1Gp is \"$connType\". Should be \"$conn\"" 
      set ret -1
      break 
    }
    if {$name=="SFP"} {
      regexp {Part Number[\s:]+([\w\-]+)\s} $buffer - sfp
      if ![info exists sfp] {
        set gaSet(fail) "Can't read SFP's Part Number"
        return -1
      }
      set sfpL [list "SFP-5D" "SFP-6D" "SFP-6H" "SFP-30" "SFP-6" "SPGBTXCNFCRAD" "EOLS-1312-10-RAD" "EOLS131210RAD"]
      if {[lsearch $sfpL $sfp]=="-1"} {
        set gaSet(fail) "SFP Part Number of port $1Gp is \"$sfp\". Should be one from $sfpL" 
        set ret -1
        break 
      }
    }
    
  }
  return $ret  
}

# ***************************************************************************
# DateTime_Test
# ***************************************************************************
proc DateTime_Test {} {
  global gaSet buffer
  Status "DateTime_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure system\r" >system]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show system-date\r" >system]
  if {$ret!=0} {return $ret}
  
  regexp {date\s+([\d-]+)\s+([\d:]+)\s} $buffer - dutDate dutTime
  
  set dutTimeSec [clock scan $dutTime]
  set pcSec [clock seconds]
  set delta [expr abs([expr {$pcSec - $dutTimeSec}])]
  if {$delta>300} {
    set gaSet(fail) "Difference between PC and the DUT is more then 5 minutes ($delta)"
    set ret -1
  } else {
    set ret 0
  }
  
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    if {$pcDate!=$dutDate} {
      set gaSet(fail) "Date of the DUT is \"$dutDate\". Should be \"$pcDate\""
      set ret -1
    } else {
      set ret 0
    }
  }
  return $ret
}

# ***************************************************************************
# DataTransmissionSetup
# ***************************************************************************
proc DataTransmissionSetup {} {
  global gaSet
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set cf $gaSet([set b]CF) 
  set cfTxt "$b"
      
  set ret [DownloadConfFile $cf $cfTxt 1]
  if {$ret!=0} {return $ret}
    
  return $ret
}
# ***************************************************************************
# RtrSetup
# ***************************************************************************
proc RtrSetup {} {
  global gaSet
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  set cf $gaSet(RTRCF) 
  set cfTxt "RTR"
      
  set ret [DownloadConfFile $cf $cfTxt 0]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# ExtClkTest
# ***************************************************************************
proc ExtClkTest {mode} {
  puts "[MyTime] ExtClkTest $mode"
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
#   set ret [Send $com "configure system clock station 1/1\r" "(1/1)"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "shutdown\r" "(1/1)"]
#   if {$ret!=0} {return $ret}
#   Send $com "exit all\r" stam 0.25 
  
  if {$mode=="Unlocked"} {
    set ret [Send $com "configure system clock\r" ">clock"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "domain 1\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "show status\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set syst [set clkSrc [set state ""]]
    regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s} $buffer syst clkSrc state
    if {$clkSrc!="0" && $state!="Freerun"} {
      set gaSet(fail) "$syst"
      return -1
    }
  }
 
 if {$mode=="Locked"} {
    set cf $gaSet(ExtClkCF) 
    set cfTxt "EXT CLK"
    set ret [DownloadConfFile $cf $cfTxt 0]
    if {$ret!=0} {return $ret}
    
    set ret [Send $com "configure system clock\r" ">clock"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "domain 1\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    for {set i 1} {$i<=10} {incr i} {
      set ret [Send $com "show status\r" "domain(1)"]
      if {$ret!=0} {return $ret} 
      set syst [set clkSrc [set state ""]]
      regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s} $buffer syst clkSrc state
      if {$clkSrc=="1" && $state=="Locked"} {
        set ret 0
        break
      } else {      
        set ret -1
        after 1000
      }
    }
    if {$ret=="-1"} {
      set gaSet(fail) "$syst"
    } elseif {$ret=="0"} {
      set ret [Send $com "no source 1\r" "domain(1)"]
      if {$ret!=0} {return $ret}
    }
  }
  return $ret
}

# ***************************************************************************
# TstAlm
# ***************************************************************************
proc TstAlm {state} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure reporting\r" ">reporting"]
  if {$ret!=0} {return $ret}
  if {$state=="off"} { 
    set ret [Send $com "mask-minimum-severity log major\r" ">reporting"]
  } elseif {$state=="on"} { 
    set ret [Send $com "no mask-minimum-severity log\r" ">reporting"]
  } 
  return $ret
}

# ***************************************************************************
# ReadMac
# ***************************************************************************
proc ReadMac {} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Read MAC"
  set gaSet(fail) "Read MAC fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25
  set ret [Send $com "configure system\r" ">system"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "show device-information\r" ">system"]
  if {$ret!=0} {return $ret}
  
  set mac 00-00-00-00-00-00
  regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac
  if [string match *:* $mac] {
    set mac [join [split $mac :] ""]
  }
  set mac1 [join [split $mac -] ""]
  set mac2 0x$mac1
  puts "mac1:$mac1" ; update
  if {($mac2<0x0020D2500000 || $mac2>0x0020D2FFFFFF) && ($mac2<0x1806F5000000 || $mac2>0x1806F5FFFFFF)} {
    RLSound::Play fail
    set gaSet(fail) "The MAC of UUT is $mac"
    set ret [DialogBox -type "Terminate Continue" -icon /images/error -title "MAC check"\
        -text $gaSet(fail) -aspect 2000]
    if {$ret=="Terminate"} {
      return -1
    }
  }
  set gaSet(${::pair}.mac1) $mac1
  
  return 0
}
# ***************************************************************************
# ReadPortMac
# ***************************************************************************
proc ReadPortMac {port} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Read MAC of port $port fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25
  set ret [Send $com "configure port\r" "port"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show status\r" "($port)" 20]
  if {$ret!=0} {return $ret}
  regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac
  if [string match *:* $mac] {
    set mac [join [split $mac :] ""]
  }
  set mac1 [join [split $mac -] ""]
  return $mac1
}

#***************************************************************************
#**  Login
#***************************************************************************
proc Login {} {
  global gaSet buffer gaLocal
  set ret 0
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into ETX-2i"
#   set ret [MyWaitFor $gaSet(comDut) {ETX-2I user>} 5 1]
  Send $gaSet(comDut) "\r" stam 0.25
  Send $gaSet(comDut) "\r" stam 0.25
  if {([string match {*-2I*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set ret 0
  }
  if {[string match {*Are you sure?*} $buffer]==1} {
   Send $gaSet(comDut) n\r stam 1
  }
   
   
  if {[string match *password* $buffer] || [string match {*press a key*} $buffer]} {
    set ret 0
    Send $gaSet(comDut) \r stam 0.25
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $gaSet(comDut) exit\r\r -2I
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
    set ret 0
    Send $gaSet(comDut) \x1F\r\r -2I
  }
  if {[string match *-2I* $buffer]} {
    set gaSet(prompt) "-2I"
    set ret 0
    return 0
  } elseif {[string match *ztp* $buffer]} {
    set gaSet(prompt) "ztp"
    set ret 0
    return 0
  }
  if {[string match *->* $buffer]} {
    set ret 0
    Send $gaSet(comDut) exit\r\r stam 2
  }
  if {[string match *boot* $buffer]} {
    Send $gaSet(comDut) run\r stam 1
  }
  if {[string match *user* $buffer]} {
    Send $gaSet(comDut) su\r stam 0.25
    set ret [Send $gaSet(comDut) 1234\r "ETX-2I" 3]
    if {[string match {*Login failed*} $buffer]} {
      Send $gaSet(comDut) \r stam 1
    }
    if {[string match *-2I* $buffer]} {
      set gaSet(prompt) "-2I"
    } elseif {[string match *ztp* $buffer]} {
      set gaSet(prompt) "ztp"
    }  
    if {[string match {*Authorized users only*} $buffer]} {
      Send $gaSet(comDut) \r stam 0.5
      Send $gaSet(comDut) su\r stam 0.25
      set ret [Send $gaSet(comDut) "DCtiful1\r" $gaSet(prompt)]
    }
    $gaSet(runTime) configure -text ""
    return $ret
  }
  if {$ret!=0} {
    #set ret [Wait "Wait for ETX up" 20 white]
    #if {$ret!=0} {return $ret}  
  }
  for {set i 1} {$i <= 36} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into ETX-2I"
    puts "Login into ETX-2I i:$i"; update
    $gaSet(runTime) configure -text $i
    Send $gaSet(comDut) \r stam 5
    
    append gaSet(loginBuffer) "$buffer"
    puts "<$gaSet(loginBuffer)>\n" ; update
    
    set res [regexp {Boot version:\s([\d\.\(\)]+)\s} $buffer - value]
    if {$res==1} {
      set gaSet(uutBootVers) $value
      puts "gaSet(uutBootVers):$gaSet(uutBootVers)"
      set ret 0
    }
    
    foreach ber $gaSet(bootErrorsL) {
      if [string match "*$ber*" $gaSet(loginBuffer)] {
       set gaSet(fail) "\'$ber\' occured during ETX-2I's up"  
        return -1
      } else {
        puts "[MyTime] \'$ber\' was not found"
      } 
    }
    
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2I user> } 5 60]
    if {[string match *-2I* $buffer]} {
      set gaSet(prompt) "-2I"
    } elseif {[string match *ztp* $buffer]} {
      set gaSet(prompt) "ztp"
    }
    if {([string match {*-2I*} $buffer]==1) || ([string match {*ztp*} $buffer]==1) || ([string match {*user>*} $buffer]==1)} {
      puts "if1 <$buffer>"
      set ret 0
      break
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $gaSet(comDut) run\r stam 1
    }   
    if {[string match *login:* $buffer]} { }
    if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
      Send $gaSet(comDut) \x1F\r\r -2I
      return 0
    }
  }
  if {$ret==0} {
    if {[string match *user>* $buffer]} {
      Send $gaSet(comDut) su\r stam 1
      set ret [Send $gaSet(comDut) 1234\r "-2I" 3]
      if {[string match {*Login failed*} $buffer]} {
        Send $gaSet(comDut) \r stam 1
      }
      if {[string match *-2I* $buffer]} {
        set gaSet(prompt) "-2I"
      } elseif {[string match *ztp* $buffer]} {
        set gaSet(prompt) "ztp"
      }
      if {[string match {*Authorized users only*} $buffer]} {
        Send $gaSet(comDut) \r stam 0.5
        Send $gaSet(comDut) su\r stam 0.25
        set ret [Send $gaSet(comDut) "DCtiful1\r" $gaSet(prompt)]
      }
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to ETX-2I Fail"
  }
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}
# ***************************************************************************
# FormatFlash
# ***************************************************************************
proc FormatFlash {} {
  global gaSet buffer
  set com $gaSet(comDut)
  
  Power all on 
  
  return $ret
}
# ***************************************************************************
# FactDefault
# ***************************************************************************
proc FactDefault {mode {waitAfter 20}} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Set to Default fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  Status "Factory Default..."
  if {$mode=="std"} {
    set ret [Send $com "admin factory-default\r" "yes/no" ]
  } elseif {$mode=="stda"} {
    set ret [Send $com "admin factory-default-all\r" "yes/no" ]
  }
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "seconds" 20]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Wait DUT reboot" $waitAfter white]
  return $ret
}
# ***************************************************************************
# ShowPS
# ***************************************************************************
proc ShowPS {ps} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Read PS-$ps status"
  set gaSet(fail) "Read PS status fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  if {$ps==1} {
    regexp {1\s+[AD]C\s+([\w\s]+)\s2} $buffer - val
  } elseif {$ps==2} {
    regexp {2\s+[AD]C\s+([\w\s]+)\sFAN} $buffer - val
  }
  set val [string trim $val]
  puts "ShowPS val:<$val>"
  if {[lindex [split $val " "] 0] == "HP"} {
    set val [lrange [split $val " "] 1 end] 
  }
  return $val
}
# ***************************************************************************
# Loopback
# ***************************************************************************
proc Loopback {mode uut} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "UUT-$uut. Set Loopback to \'$mode\'"
  set gaSet(fail) "Loopback configuration fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure port ethernet 0/1\r" (0/1)]
  if {$ret!=0} {return $ret}
  if {$mode=="off"} {
    set ret [Send $com "no loopback\r" (0/1)]
  } elseif {$mode=="on"} {
    set ret [Send $com "loopback remote\r" (0/1)]
  }
  if {$ret!=0} {return $ret}
#   Send $com "exit\r" stam 0.25 
#   set ret [Send $com "ethernet 4/2\r" (4/2)]
#   if {$ret!=0} {return $ret}
#   if {$mode=="off"} {
#     set ret [Send $com "no loopback\r" (4/2)]
#   } elseif {$mode=="on"} {
#     set ret [Send $com "loopback remote\r" (4/2)]
#   }
#   if {$ret!=0} {return $ret}
  set gaSet(fail) ""
  puts "ret of Loopback $mode $uut : <$ret>"; update
  return $ret
}

# ***************************************************************************
# DateTime_Set
# ***************************************************************************
proc DateTime_Set {} {
  global gaSet buffer
  OpenComUut
  Status "Set DateTime"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
  }
  if {$ret==0} {
    set gaSet(fail) "Logon fail"
    set com $gaSet(comDut)
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure system\r" >system]
  }
  if {$ret==0} {
    set gaSet(fail) "Set DateTime fail"
    set ret [Send $com "date-and-time\r" "date-time"]
  }
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    set ret [Send $com "date $pcDate\r" "date-time"]
  }
  if {$ret==0} {
    set pcTime [clock format [clock seconds] -format "%H:%M"]
    set ret [Send $com "time $pcTime\r" "date-time"]
  }
  CloseComUut
  RLSound::Play information
  if {$ret==0} {
    Status Done yellow
  } else {
    Status $gaSet(fail) red
  } 
}
# ***************************************************************************
# LoadDefConf
# ***************************************************************************
proc LoadDefConf {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Load Default Configuration fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(DefaultCF) 
  set cfTxt "DefaultConfiguration"
  set ret [DownloadConfFile $cf $cfTxt 1]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "file copy running-config user-default-config\r" "yes/no" ]
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "successfull" 30]
  
  return $ret
}
# ***************************************************************************
# DdrTest
# ***************************************************************************
proc DdrTest {} {
  global gaSet buffer
  Status "DDR Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read MEA LOG"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read MEA LOG fail"
  set ret [Send $com "debug mea\r" FPGA 11]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mea debug log show\r" FPGA>> 30]
  if {$ret!=0} {return $ret}
  
  if {[string match {*ENTU_ERROR*} $buffer]} {
    set gaSet(fail) "\'ENTU_ERROR\' exists in the MEA log"
    return -1
  }
  if {[string match {*init DDR ..........................OK*} $buffer]==0} {
    set gaSet(fail) "\'init DDR ..OK\' doesn't exist in the MEA log"
    return -1
  }
  if {[string match {*DDR NOT OK*} $buffer]==1} {
    set gaSet(fail) "\'DDR NOT OK\' exists in the MEA log"
    return -1
  }
  
  set ret [Send $com "exit\r\r\r" ETX-2I 16]
  if {$ret!=0} {return $ret}
  return $ret
}  
# ***************************************************************************
# DryContactTest
# ***************************************************************************
proc DryContactTest {pair} {
  global gaSet buffer
  Status "Dry Contact Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "config reporting alarm-input 1 active high\r" IB]
  if {$ret!=0} {return $ret}
  set ret [Send $com "config reporting alarm-input 2 active high\r" IB]
  if {$ret!=0} {return $ret}
  set ret [Send $com "config reporting alarm-input 3 active high\r" IB]
  if {$ret!=0} {return $ret}
  
  
  RLSound::Play information
  set txt "UUT $pair\nSet SW1, SW2, and SW3 into OFF position"
  set res [DialogBox -type "OK Cancel" -icon /images/info -title "Dry Contact Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "Dry Contact Test fail"
    return -2
  }
  for {set tr 1} {$tr<=10} {incr tr} {
    puts "no SW tr:$tr"
    set ret [Send $com "show config reporting active-alarms\r" IB]
    if {$ret!=0} {return $ret}
    #set res [regexp -all {Alarm Input} $buffer]
    set res [string match {*Alarm Input*} $buffer]
    if {$res!=0} {
      set ret -1
      after 2000
    } else {
      set ret 0
      break
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "UUT $pair. There is at least one Alarm Input. Should be no one"
    return -1
  }
  
  RLSound::Play information
  set txt "UUT $pair\nSet SW1 to ON position"
  set res [DialogBox -type "OK Cancel" -icon /images/info -title "Dry Contact Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "Dry Contact Test fail"
    return -2
  }
  for {set tr 1} {$tr<=10} {incr tr} {
    puts "SW1 tr:$tr"
    set ret [Send $com "show config reporting active-alarms\r" IB]
    if {$ret!=0} {return $ret}
    set res1 [string match {*Alarm Input 1*} $buffer]
    if {$res1!=1} {
      set ret -1
      after 2000
    } else {
      set ret 0
      break
    }
  }
  if {$ret!=0} {
    set gaSet(fail) "UUT $pair. Alarm Input 1 does not exist"
    return -1
  }
  
  
  RLSound::Play information
  set txt "UUT $pair\nSet SW2 to ON position"
  set res [DialogBox -type "OK Cancel" -icon /images/info -title "Dry Contact Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "Dry Contact Test fail"
    return -2
  }
  for {set tr 1} {$tr<=10} {incr tr} {
    puts "SW1_2 tr:$tr"
    set ret [Send $com "show config reporting active-alarms\r" IB]
    if {$ret!=0} {return $ret}
    set res1 [string match {*Alarm Input 1*} $buffer]
    set res2 [string match {*Alarm Input 2*} $buffer]
    if {$res1!=1 || $res2!=1} {
      set ret -1
      after 2000
    } else {
      set ret 0
      break
    }
  }
  if {$ret!=0} {
    set gaSet(fail) "UUT $pair. Alarm Input 1 or 2 does not exist"
    return -1
  }
  
  RLSound::Play information
  set txt "UUT $pair\nSet SW3 to ON position"
  set res [DialogBox -type "OK Cancel" -icon /images/info -title "Dry Contact Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "Dry Contact Test fail"
    return -2
  }
  for {set tr 1} {$tr<=10} {incr tr} {
    puts "SW1_2_3 tr:$tr"
    set ret [Send $com "show config reporting active-alarms\r" IB]
    if {$ret!=0} {return $ret}
    set res1 [string match {*Alarm Input 1*} $buffer]
    set res2 [string match {*Alarm Input 2*} $buffer]
    set res3 [string match {*Alarm Input 3*} $buffer]
    if {$res1==0 || $res2==0 || $res3==0} {
      set ret -1
      after 2000
    } else {
      set ret 0
      break
    }
  }
  if {$ret!=0} {
    set gaSet(fail) "UUT $pair. Alarm Input 1 or 2 or 3 does not exist"
    return -1
  }
  
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Alarm Leds Activation"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  Send $com "debug\r" stam 0.25
  Send $com "memory address c2100000 write char value FC\r" stam 0.25
  set ret 0
  RLSound::Play information
  set txt "UUT $pair\nVerify LD1 is On and LD2 is Off"
  set res [DialogBox -type "OK Cancel" -icon /images/info -title "Dry Contact Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "Dry Contact Test fail"
    return -2
  }
  Send $com "memory address c2100000 write char value F8\r" stam 0.25
  RLSound::Play information
  set txt "UUT $pair\nVerify LD1 is Off and LD2 is On"
  set res [DialogBox -type "OK Cancel" -icon /images/info -title "Dry Contact Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "Dry Contact Test fail"
    return -2
  }
  
  return $ret
  #####################################
  
  RLUsbPio::SetConfig $gaSet(idDrc) 11111000 ; # 3 first bits are OUT
  RLUsbPio::Set $gaSet(idDrc) xxxxx000 ; # 3 first bits are 0 
  
  set gaSet(fail) "Read MEA HW DRY fail"
  set ret [Send $com "debug mea\r" FPGA 11]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mea hw dry\r" dry>>]
  if {$ret!=0} {return $ret}
  set ret [Send $com "read 0\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x0\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 0\' fail"
    return -1
  }
  if {$val!="0xf7"} {
    set gaSet(fail) "The value of 0x0 is \'$val\'. Should be \'0xf7\'"
    return -1
  }
  
  set ret [Send $com "read 1\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x1\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 1\' fail"
    return -1
  }
  if {$val!="0xff"} {
    set gaSet(fail) "The value of 0x1 is \'$val\'. Should be \'0xff\'"
    return -1
  }
  
  RLUsbPio::Set $gaSet(idDrc) xxxxx111 ; # 3 first bits are 1
  set ret [Send $com "read 0\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x0\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 0\' fail"
    return -1
  }
  if {$val!="0xf0"} {
    set gaSet(fail) "The value of 0x0 is \'$val\'. Should be \'0xf0\'"
    return -1
  }
     
  set ret [Send $com "exit\r\r" ETX-2I 16]
  if {$ret!=0} {return $ret}
  return $ret
}  

# ***************************************************************************
# ShowArpTable
# ***************************************************************************
proc ShowArpTable {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Show ARP Table fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure router 1\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show arp-table\r" (1)]
  if {$ret!=0} {return $ret}
  
  set lin1 "1.1.1.1 00-00-00-00-00-01 Dynamic"
  set lin2 "2.2.2.1 00-00-00-00-00-02 Dynamic"
   
  foreach lin [list $lin1 $lin2] {
    if {[string match *$lin* $buffer]==0} {
      set gaSet(fail) "The \'$lin\' doesn't exist"
      return -1
    }
  }

  return 0
}
# ***************************************************************************
# DnfvSoftwareDownloadTest
# ***************************************************************************
proc DnfvSoftwareDownloadTest {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Enter to DNFV fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  Status "Wait for DNFV booting"
  set ret [Send $com "configure terminal timeout forever\r" 2I]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis ve-module reset-wake\r" 2I]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis ve-module remote-terminal\r\r" "login:" 2]
  
  if 0 {
  set secStart [clock seconds]
  while 1 {
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set runSec [expr {$nowSec - $secStart}]
    $gaSet(runTime) configure -text $runSec
    update
    if {$runSec>50} {
      set ret -1
      break
    }
    RLSerial::Waitfor $com buffer stam 2
    puts "$runSec <$buffer>" ; update
    if {[string match {*login:*} $buffer]==1} {
      set ret 0
      break
    }
    
  }
  
  #if [string match {*login:*} $buffer] {}
  if {$ret==0} {
    ## the dnfv is not empty
    ## go to bios and at boot menu change the priority of DoK to first 
    for {set attempt 1} {$attempt<=10} {incr attempt} {
#       set gaSet(fail) "Change Boot priority fail"
#       RLSound::Play information
#       set txt "Click \'OK\' and immediately push on Reset button of the DNFV"
#       set res [DialogBox -type "OK Cancel" -icon /images/question \
#           -title "Reset of DNFV" -message $txt -aspect 2000]
#       update
#       if {$res=="Cancel"} {
#         return -2
#       }
      Status "Login into DNFV"
      set ret [Send $com "rad\r" "Password:"]
      if {$ret!=0} {return $ret}
      set ret [Send $com "rad123\r" ":~$"]
      if {$ret!=0} {return $ret}
      set ret [Send $com "sudo su\r" ":"]
      if {$ret!=0} {return $ret}
      set ret [Send $com "rad123\r" "#"]
      if {$ret!=0} {return $ret}
      set ret [Send $com "reboot\r" ":"]
      if {$ret!=0} {return $ret}
      set ret [RLSerial::Waitfor $com buffer "Version" 12]      
      #set ret [Send $com "\r" "to enter setup"]
      if {$ret=="-1"} {
        set ret [Wait "Wait for DNFV reseting" 40]
        if {$ret!=0} {return $ret}
        continue
      }
      
      for {set dok 1} {$dok<=4} {incr dok} {
        puts "[MyTime] Start of dok-$dok" ; update
        set ret [DnfvBiosDOK]
        puts "[MyTime] ret of dok-$dok : <$ret>" ; update
        if {$ret=="0"} {
          break
        } elseif {$ret=="-1"} {
          set ret [RLSerial::Waitfor $com buffer "BIOS Date" 3]
          puts "-1 dok-$dok <$buffer>" ; update
          set ret [Wait "Wait for DNFV reseting" 40]
          if {$ret!=0} {return $ret}
        } elseif {$ret=="1"} {  
          set ret [RLSerial::Waitfor $com buffer "BIOS Date" 3]
          puts "1 dok-$dok <$buffer>" ; update        
          continue
        }
      } 
      if {$ret=="0" || $ret=="-2"} {
        break
      }
    }  
  }
  
  set gaSet(fail) "Software download fail"
  if {$ret!=0} {return $ret}
    
  
  #set ret [Send $com "y\r" "(y/n)" 15]
  #if {$ret!=0} {return $ret}
  #set ret [Send $com "y\r" "Start over" 1]
  
  }
  set gaSet(fail) "Software download fail"
  Status "Wait for SW download"  
  set secStart [clock seconds]
  while 1 {
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set runSec [expr {$nowSec - $secStart}]
    $gaSet(runTime) configure -text $runSec
    update
    if {$runSec>240} {
      return -1
    }
    RLSerial::Waitfor $com buffer stam 2
    puts "$runSec <$buffer>" ; update
    if {[string match {*Start over*} $buffer]==1} {
      set ret 0
      break
    }
    
  }
  
  if {$ret!=0} {return $ret}
  
  ## move up
  after 1000
  Send $com "\33\[A" stam 1 
  
  RLSound::Play information
  set txt "Remove the DiskOnKey"
  set res [DialogBox -type "OK Cancel" -icon /images/question \
      -title "DiskOnKey" -message $txt]
  update
  if {$res=="Cancel"} {
    return -2
  }
  
  set alreadyPowerOffOn 0
  Status "Wait DNFV up"
  set ret [Send $com "\r" "login:" 1]
  set secStart [clock seconds]
  while 1 {
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set runSec [expr {$nowSec - $secStart}]
    $gaSet(runTime) configure -text $runSec
    update
    if {$runSec>120} {
      return -1
    }
    RLSerial::Waitfor $com buffer stam 2
    puts "$runSec <$buffer>" ; update
    
    if {[string match {*login:*} $buffer]==1} {
      set ret 0
      break
    }
    if {[string match {*Fixing recursive fault but reboot is needed*} $buffer]==1} {
      if {$alreadyPowerOffOn=="1"} {
        set gaSet(fail) "The DNFV already rebboted after app. download"
        set ret -1
        break
      }
      foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
      if {$b=="V"|| $b=="DNFV"} {
        set ret [DnfvPower off]
        if {$ret!=0} {
          set gaSet(fail) "DNFV Power OFF fail"
        }
      }
      Power all off
      set secStart [clock seconds]
      after 2000
      Power all on
      set alreadyPowerOffOn 1
    }
    
  }
  
  if {$ret!=0} {return $ret}  
  return $ret
} 

# ***************************************************************************
# SoftwareDownloadTest
# ***************************************************************************
proc SoftwareDownloadTest {} {
  global gaSet buffer 
  set com $gaSet(comDut)
  
  set tail [file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  # Download:   
  Status "Wait for download .."
  set gaSet(fail) "Application download fail"
  Send $com "download 1,[set tail]\r" "stam" 3
  if {[string match {*Are you sure(y/n)?*} $buffer]==1} {
    Send $com "y" "stam" 2
  }
   
  set ret [MyWaitFor $com "boot" 5 420]
  if {$ret!=0} {return $ret}
 
  Status "Wait for set active 1 .."
  set ret [Send $com "set-active 1\r" "SW set active 1 completed successfully" 30] 
  if {$ret!=0} {
    set gaSet(fail) "Activate SW Pack1 fail"
    return -1
  }
  
  set ret [Send $com "run\r" "Loading" 20]
  return $ret
}  
# ***************************************************************************
# ForceMode
# ***************************************************************************
proc ForceMode {b mode ports} {
  global gaSet buffer
  Status "Force Mode $mode $ports"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Activation debug test fail"
  set ret [Send $com "debug test\r" test]
  if {$ret!=0} {return $ret}
  
  ## 13/07/2016 13:42:51 6 -> 8
  for {set port 1} {$port <= $ports} {incr port} {}
  foreach port $ports {
    set gaSet(fail) "Force port $port to mode \'$mode\' fail"
    set ret [Send $com "forced-combo-mode $port $mode\r" "test"]
    if {$ret!=0} {return $ret}
    if {[string match {*cli error*} $buffer]==1} {
      return -1
    }
    if {$gaSet(act)=="0"} {return "-2"}
  }
  return $ret
}
# ***************************************************************************
# ReadEthPortStatus
# ***************************************************************************
proc ReadEthPortStatus {port shbState} {
  global gaSet buffer
#   Status "Read EthPort Status of $port"
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
  Status "Read EthPort Status of $port"
  puts "ReadEthPortStatus $port \'$shbState\'"
  set gaSet(fail) "Show status of port $port fail"
  set com $gaSet(comDut) 
  Send $com "exit all\r" stam 1 
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  set res [Send $com "show status\r" "($port)" 20]
  set ::bu $buffer
  if {$res!=0} {
    after 2000
    set ret [Send $com "\r" ($port)]
    append ::bu $buffer 
    if {$ret!=0} {
      set res [Send $com "show status\r" "($port)" 20]   
      append ::bu $buffer
    }   
  }
  set ret [Send $com "\r" ($port)]
  append ::bu $buffer
  if {$ret!=0} {return $ret}
  
#   if {$res!=0} {
#     #set gaSet(fail) "The port's $port status is not \'SFP In\'"
#     set gaSet(fail) "Read port's $port status fail"
#     return -1
#   }
  
  set ret -1
  foreach connType [list RJ-45 LC RJ45] {
    if {[string match *$connType* $::bu]} {
      set ret 0
      puts "connType: $connType"
      break
    }
  } 
  puts "connType: $connType ret:$ret"
  if {$ret!=0} {
    set gaSet(fail) "The port's $port Connector Type is not \'RJ-45\' or \'LC\'"
    return -1
  } 
  
  if {![string match *$shbState* $::bu]} {
    set gaSet(fail) "The port's $port status is not \'$shbState\'"
    return -1
  }
  
  return $ret
}
# ***************************************************************************
# ReadEthPortsStatus
# ***************************************************************************
proc ReadEthPortsStatus {portL} {
  global gaSet buffer
  Status "Read EthPort Status of $portL"
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Read EthPort Status of $portL"
  set gaSet(fail) "Read show summary fail"
  set com $gaSet(comDut) 
  Send $com "exit all\r" stam 1 
  set ret [Send $com "config port\r" port]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show summary\r" "port" 20]
  if {$ret!=0} {return $ret}
  set ret 0
  foreach port $portL {
    set res [regexp "ETH-$port Up \(\[\\w\]+\)" $buffer ma val]
    if {$res==0} {
      set gaSet(fail) "Read show summary of port $port fail"
      set ret -1
      break
    }
    if {$val!="Up"} {
      set gaSet(fail) "Oper status of port $port is \'$val'.  Should be \'Up\'"
      set ret -1
      break
    }
  }
  return $ret
}  
# ***************************************************************************
# DnfvCross
# ***************************************************************************
proc DnfvCross {mode} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  set txt "Configure Dnfv-br-Cross to \'$mode\'" 
  set gaSet(fail) "$txt fail"
  if {$ret!=0} {return $ret}
  Status $txt
  Send $com "exit all\r" stam 0.5
  
  set ret [Send $com "configure chassis ve-module remote-terminal\r" "stam" 2]
  set ret [Send $com "\r" "login" 2] 
  if {$ret!=0} {
    for {set lo 1} {$lo<=14} {incr lo} {
      if {$gaSet(act)==0} {return -2}
      puts "DnfvCross 1 lo:$lo" ; update
      set ret [Send $com "\r" "$" 1.5]
      if {$ret==0} {break} 
      if {[string match {*login:*} $buffer]} {
        set ret 0
        break
      }
      after 2000
    }
  }
  if {$ret!=0} {return $ret}
  
  for {set lo 1} {$lo<=14} {incr lo} {
    if {$gaSet(act)==0} {return -2}
    puts "DnfvCross 2 lo:$lo" ; update
    set ret [Send $com "\r" "$" 1.5]
    if {$ret==0} {break} 
    if {[string match {*login:*} $buffer]} {
      set ret 0
      break
    }
    after 2000
  }
  
  if {[string match {*login:*} $buffer]} {
    set ret [Send $com "rad\r" Password:]
    if {$ret!=0} {return $ret}
    set ret [Send $com "rad123\r" :~$]
    if {$ret!=0} {return $ret}
  }  
  
  Send $com "dddd\r" stam 2
  set ret [Send $com "dnfv-br-cross-off\r" :~$ 2]
  
  if {[string match {*password for rad*} $buffer]} {
    set ret [Send $com "rad123\r" :~$]
    if {$ret!=0} {return $ret}
  }  

  if {$mode eq "on"} {
    for {set i 1} {$i<=5} {incr i} {
      puts "dnfv-br-cross-$mode i:$i" ; update
      set ret [Send $com "dnfv-br-cross-$mode\r" :~$]
      if {$ret!=0} {
        set ret [Send $com "\r" :~$]
        if {$ret!=0} {return $ret}
      }
      
      if {[string match {*does not exist*} $buffer]} {
        set ret [Send $com "dnfv-br-cross-off\r" :~$ 2]
        set ret [Wait "Wait for eth. interfaces" 10]
        if {$ret!=0} {return $ret}
      } else {
        set ret 0
        break
      }
    }
  }
  return $ret
}
# ***************************************************************************
# DnfvPower
# ***************************************************************************
proc DnfvPower {mode} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  set txt "Configure Dnfv Power to \'$mode\'" 
  set gaSet(fail) "$txt fail"
  if {$ret!=0} {return $ret}
  Status $txt
  Send $com "exit all\r" stam 0.5
  
  set ret [Send $com "configure chassis ve-module remote-terminal\r" "stam" 2]
  set ret [Send $com "\r" "login" 2] 
  if {$ret!=0} {
    for {set lo 1} {$lo<=30} {incr lo} {
      if {$gaSet(act)==0} {return -2}
      puts "DnfvPower lo:$lo" ; update
      set ret [Send $com "\r" "$" 0.5]
      if {$ret==0} {break} 
      if {[string match {*login:*} $buffer]} {
        set ret 0
        break
      }
      after 2000
    }
  }
  if {$ret!=0} {return $ret}
  if {[string match {*login:*} $buffer]} {
    set ret [Send $com "rad\r" Password:]
    if {$ret!=0} {return $ret}
    set ret [Send $com "rad123\r" :~$]
    if {$ret!=0} {return $ret}
  }  
  
  set ret [Send $com "sudo su\r" :~$ 2]
  
  if {[string match {*password for rad*} $buffer]} {
    set ret [Send $com "rad123\r" :~$]
    if {$ret!=0} {
      if {![string match *rad#* $buffer]} {
        set ret -1
        return $ret 
      }
    }  
  }  
  
  set ret [Send $com "power$mode\r" "reboot: Power down" 30]
  return $ret
}
# ***************************************************************************
# AdminSave
# ***************************************************************************
proc AdminSave {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  Status "Admin Save"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "admin save\r" "successfull" 60]
  return $ret
}

# ***************************************************************************
# ShutDown
# ***************************************************************************
proc ShutDown {port state} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "$state of port $port fail"
  Status "ShutDown $port \'$state\'"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r $state" "($port)"]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# Boot_Download
# ***************************************************************************
proc Boot_Download {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Empty unit prompt"
  Send $com "\r\r" "=>" 2
  set ret [Send $com "\r\r" "=>" 2]
  if {$ret!=0} {
    # no:
    puts "Skip Boot Download" ; update
    set ret 0
  } else {
    # yes:   
    Status "Setup in progress ..."
    
    #dec to Hex
    set x [format %.2x $::pair]
    
    # Config Setup:
    Send $com "env set ethaddr 00:20:01:02:03:$x\r" "=>"
    Send $com "env set netmask 255.255.255.0\r" "=>"
    Send $com "env set gatewayip 10.10.10.10\r" "=>"
    Send $com "env set ipaddr 10.10.10.1[set ::pair]\r" "=>"
    Send $com "env set serverip 10.10.10.10\r" "=>"
    
    # Download Comment: download command is: run download_vxboot
    # the download file name should be always: vxboot.bin
    # else it will not work !
    if [file exists c:/download/temp/vxboot.bin] {
      file delete -force c:/download/temp/vxboot.bin
    }
    if {[file exists $gaSet(BootCF)]!=1} {
      set gaSet(fail) "The BOOT file ($gaSet(BootCF)) doesn't exist"
      return -1
    }
    file copy -force $gaSet(BootCF) c:/download/temp              
    #regsub -all {\.[\w]*} $gaSet(BootCF) "" boot_file
    
    
        
    # Download:   
    Send $com "run download_vxboot\r" stam 1
    set ret [Wait "Download Boot in progress ..." 10]
    if {$ret!=0} {return $ret}
    
    file delete -force c:/download/temp/vxboot.bin
    
    
    Send $com "\r\r" "=>" 1
    Send $com "\r\r" "=>" 3
    
    set ret [regexp {Error} $buffer]
    if {$ret==1} {
      set gaSet(fail) "Boot download fail" 
      return -1
    }  
    
    Status "Reset the unit ..."
    Send $com "reset\r" "stam" 1
    set ret [Wait "Wait for Reboot ..." 40]
    if {$ret!=0} {return $ret}
    
  }      
  return $ret
}

# ***************************************************************************
# FormatFlashAfterBootDnl
# ***************************************************************************
proc FormatFlashAfterBootDnl {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Format Flash after Boot Download"
  Send $com "\r\r" "Are you sure(y/n)?" 2
  set ret [Send $com "\r\r" "Are you sure(y/n)?" 2]
  if {$ret!=0} {
    puts "Skip Flash format" ; update
    set ret 0
  } else {
    Send $com "y\r" "\[boot\]:"
    puts "Format in progress ..." ; update
    set ret [MyWaitFor $com "boot]:" 5 680]
  }
  return $ret
}

# ***************************************************************************
# SetSWDownload
# ***************************************************************************
proc SetSWDownload {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Set SW Download"
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DeleteBootFiles]
  if {$ret!=0} {return $ret}
  
  if {[file exists $gaSet(SWCF)]!=1} {
    set gaSet(fail) "The SW file ($gaSet(SWCF)) doesn't exist"
    return -1
  }
     
  ## C:/download/SW/6.0.1_0.32/etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin -->> \
  ## etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin
  set tail [file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 1000
  }
    
  file copy -force $gaSet(SWCF) c:/download/temp 
  
  #gaInfo(TftpIp.$::ID) = 10.10.8.1 (device IP)
  #gaInfo(PcIp) = "10.10.10.254" (gateway IP/server IP)
  #gaInfo(mask) = "255.255.248.0"  (device mask)  
  #gaSet(Apl) = C:/Apl/4.01.10sw-pack_203n.bin

  
  # Config Setup:
  Send $com "\r\r" "\[boot\]:"
  set ret [Send $com "\r\r" "\[boot\]:"]  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail"
    return -1
  }
  #Send $com "c\r" "file name" 
  #Send $com "$tail\r" "device IP"
  Send $com "c\r" "device IP"
  if {$gaSet(pair)==5} {
    Send $com "10.10.10.1[set ::pair]\r" "device mask"
  } else {
    Send $com "10.10.10.1[set gaSet(pair)]\r" "device mask"
  }
  Send $com "255.255.255.0\r" "server IP"
  Send $com "10.10.10.10\r" "gateway IP"
  Send $com "10.10.10.10\r" "user"
  Send $com "\r" "(pw)" ;# vxworks

  # device name: 8313
  set ret [Send $com "\r" "quick autoboot"]  
  if {$ret!=0} {  
    Send $com "\r" "quick autoboot"
  } 

  Send $com "n\r" "protocol" 
  #Send $com "tftp\12" "baud rate" ;# 9600
  Send $com "ftp\r" "baud rate" ;# 9600
  Send $com "\r" "\[boot\]:"
  
  # Reboot:
  Status "Reset the unit ..."
  Send $com "reset\r" "y/n"
  Send $com "y\r" "\[boot\]:" 10
                                                               
  set i 1
  set ret [Send $com "\r" "\[boot\]:" 2]  
  while {($ret!=0)&&($i<=4)} {
    incr i
    set ret [Send $com "\r" "\[boot\]:" 2]  
  }
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail."
    return -1 
  }  
  
  return $ret  
}
# ***************************************************************************
# DeleteBootFiles
# ***************************************************************************
proc DeleteBootFiles {} {
  global  gaSet buffer
  set com $gaSet(comDut)
  
  Status "Delete Boot Files"
  Send $com "dir\r" "\[boot\]:"
  set ret0 [regexp -all {No files were found} $buffer]
  set ret1 [regexp -all {sw-pack-1} $buffer]
  set ret2 [regexp -all {sw-pack-2} $buffer]
  set ret3 [regexp -all {sw-pack-3} $buffer]
  set ret4 [regexp -all {sw-pack-4} $buffer]
  set ret5 [regexp -all {factory-default-config} $buffer]
  set ret6 [regexp -all {user-default-config} $buffer]
  set ret7 [regexp {Active SW-pack is:\s*(\d+)} $buffer var ActSw]
  set ret8 [regexp -all {startup-config} $buffer]
  
  
  if {$ret7==1} {set ActSw [string trim $ActSw]}
  
  # No files were found:
  if {$ret0!=0} {
    puts "No files were found to delete" ; update
    return 0
  }
  
  foreach SwPack "1 2 3 4" {
    # Del sw-pack-X:
    if {[set ret$SwPack]!=0} {
      if {([info exist ActSw]== 1) && ($ActSw==$SwPack)} {
        # exist:  (Active SW-pack is: 1)
        Send $com "delete sw-pack-[set SwPack]\r" ".?"
        set res [Send $com "y\r" "deleted successfully" 20]
        if {$res!=0} {
          set gaSet(fail) "sw-pack-[set SwPack] delete fail"
          return -1      
        }      
      } else {
        # not exist: ("Active SW-pack isn't: X"   or  "No active SW-pac")
        set res [Send $com "delete sw-pack-[set SwPack]\r" "deleted successfully" 20]
        if {$res!=0} {
          set gaSet(fail) "sw-pack-[set SwPack] delete fail"
          return -1      
        }       
      }
      puts "sw-pack-[set SwPack] Delete" ; update
    } else {
      puts "sw-pack-[set SwPack] not found" ; update
    }
  }

  # factory-default-config:
  if {$ret5!=0} {
    set res [Send $com "delete factory-default-config\r" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "fac-def-config delete fail"
      return -1      
    } 
    puts "factory-default-config Delete" ; update      
  } else {
    puts "factory-default-config not found" ; update
  }
  
  # user-default-config:
  if {$ret6!=0} {
    set res [Send $com "delete user-default-config\12" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "Use-def-config delete fail"
      return -1      
    } 
    puts "user-default-config Delete" ; update      
  } else {
    puts "user-default-config not found" ; update
  }
  
  # startup-config:
  if {$ret8!=0} {
    set res [Send $com "delete startup-config\12" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "Use-str-config delete fail"
      return -1      
    } 
    puts "startup-config Delete" ; update      
  } else {
    puts "startup-config not found" ; update
  }  
    
  return 0
}
# ***************************************************************************
# DnfvBiosDOK
# ***************************************************************************
proc DnfvBiosDOK {} {
  global gaSet buffer
  Status "Change boot priority"
  set com $gaSet(comDut)
  set ret [Send $com "\33" "stam" 10]
  set ret 0
  
  if ![string match {*ME Firmware SKU*} $buffer] {
    return -1
  }
  ## move right 3 times
  Send $com "\33\[C" "Save & Exit" 2; #stam 2
  Send $com "\33\[C" " (SA) Configuration" 2; #stam 2
  Send $com "\33\[C" "CSM parameters" 2
  
  if {[string match {*Option #1 \[SATA*} $buffer]} {
    puts "boot from inside memory, we should change it to DoK"; update
    
    ## move down 4 times
    Send $com "\33\[B" "options." 2
    Send $com "\33\[B" "...\]" 2
    Send $com "\33\[B" stam 2
    Send $com "\33\[B" "BBS Priorities" 2
    
    Send $com "\r" "order" 2
    Send $com "\r" "stam" 2
    
    ## move down
    Send $com "\33\[B" "stam" 2
    
    Send $com "\r" "stam" 4
    Send $com "\33" "CSM parameters" 2
    
    set checkAgain 1
  } else {                        
    puts "boot from Dok" ; update
    set checkAgain 0
  } 
  
  ## move right 2 times
  Send $com "\33\[C" "User Password" 3
  Send $com "\33\[C" "Previous Values" 2
  
  Send $com "\r" "No" 2
  Send $com "\r"  stam 0.1
  
  return $checkAgain
}
# ***************************************************************************
# DnfvMacSwIDTest
# ***************************************************************************
proc DnfvMacSwIDTest {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set gaSet(fail) "DNFV boot fail"
  set secStart [clock seconds]
  while 1 {
    if {$gaSet(act)==0} {return -2}
    set secNow [clock seconds]
    set secUp [expr {$secNow - $secStart}] 
    $gaSet(runTime) configure -text $secUp
    puts "DNFV boot $secUp"
    update
    
    if {$secUp>90} {
      return -1  
    }
    
    if {$gaSet(act)==0} {return -2}
    
    set ret [Send $com \r "login:" 2]
    if {$ret=="0"} {break}
    #set ret [RLSerial::Waitfor $com buffer "login:" 2]
    #puts "$secUp <$buffer>"
    
    if [string match *:~$* $buffer] {
      set ret 0
      break
    }
    if [string match *rad#* $buffer] {
      set ret 0
      break
    }
    if [string match *user>* $buffer] {
      set ret [Login]
      if {$ret!=0} {return $ret}
      Send $com "configure chassis ve-module remote-terminal\r\r" "stam" 1
      set ret -1
    }
    if [string match *2I* $buffer] {
      Send $gaSet(comDut) "exit all\r" stam 1
      Send $com "configure chassis ve-module remote-terminal\r\r" "stam" 1
      set ret -1
    }
    #if {$ret=="0"} {break}
  }
  puts "DnfvMacSwIDTest 1 ret:$ret"
  
  if [string match *login:* $buffer] {
    set gaSet(fail) "Enter to DNFV fail"
    set ret [Send $com "rad\r" "Password:"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "rad123\r" ":~\$"]
    if {$ret!=0} {return $ret}
  }
  puts "DnfvMacSwIDTest 2 ret:$ret"
  
  set ret [regexp {86-(\w+):} $buffer - val]
  if {$ret==0} {
    set gaSet(fail) "Login to DNFV fail"
    return $ret
  }
  puts "DnfvMacSwIDTest p:<$p> val:<$val>"; update
  if {$p=="ACC" && $val=="opt"} {
    set gaSet(fail) "DNFV\'s prompt has \'opt\' and not \'acc\'"
    return $ret
  }
  if {$p=="noACC" && $val=="acc"} {
    set gaSet(fail) "DNFV\'s prompt has \'acc\' and not \'opt\'"
    return $ret
  }
  
  set gaSet(fail) "Get ifconfig fail"
  set ret [Send $com "ifconfig\r" ":~\$" 11]
  if {$ret!=0} {
    puts "ifconfig ret!=0 1"; update
    if ![string match *rad#* $buffer] {
      puts "ifconfig ret!=0 2"; update
      set ret -1
      return $ret
    }
  }
  
  
  set ret [regexp {\seth0\s+Link encap:Ethernet\s+HWaddr\s+([0-9a-f\:]+)} $buffer - val]
  if {$ret==0} {
    set ret [Wait "Wait for eth0" 15]
    if {$ret!=0} {return $ret}
    set ret [Send $com "ifconfig\r" ":~\$" 11]
    if {$ret!=0} {return $ret}
    set ret [regexp {\seth0\s+Link encap:Ethernet\s+HWaddr\s+([0-9a-f\:]+)} $buffer - val]
    if {$ret==0} {
      set gaSet(fail) "Get eth0 fail"
      return -1
    }
  }
  set val 0x[join [split $val :] ""]
  set radMin1 0x0020d2000000
  set radMax1 0x0020d2ffffff
  set radMin2 0x1806F5000000
  set radMax2 0x1806F5FFFFFF
  if {($val<$radMin1 || $val>$radMax1) && ($val<$radMin2 || $val>$radMax2)} {
    set gaSet(fail) "MAC at eth0 is $val. Should be between $radMin1 and $radMax1 or $radMin2 and $radMax2"
    return -1  
  }
  set ma [string toupper [string range $val 2 end]]
  set pair $::pair
  if {$b!="V"} {
    set gaSet($pair.mac1) $ma
  } elseif {$b=="V"} {
    ## in case of ETX with DNFV module, the DNFV's mas is mac2
    set gaSet($pair.mac2) $ma
  }   
  puts "MAC at eth0 is $ma"
  AddToLog "MAC at eth0 is $ma"
  if {$gaSet(pair)=="5"} {
    AddToPairLog $pair "MAC at eth0 is $ma"
  } else {
    AddToPairLog $gaSet(pair) "MAC at eth0 is $ma"        
  }
  
  set ret [regexp {\seth1\s+Link encap:Ethernet\s+HWaddr\s+([0-9a-f\:]+)} $buffer - val]
  if {$ret==0} {
    set ret [Wait "Wait for eth1" 15]
    if {$ret!=0} {return $ret}
    set ret [Send $com "ifconfig\r" ":~\$" 11]
    if {$ret!=0} {return $ret}
    set ret [regexp {\seth1\s+Link encap:Ethernet\s+HWaddr\s+([0-9a-f\:]+)} $buffer - val]
    if {$ret==0} {
      set gaSet(fail) "Get eth1 fail"
      return -1
    }
  }
  set val 0x[join [split $val :] ""]
  if {$val<$radMin || $val>$radMax} {
    set gaSet(fail) "MAC at eth1 is $val. Should be between $radMin and $radMax"
    return -1  
  }
  set ma [string toupper [string range $val 2 end]]
  set gaSet(dnfvMac.$pair.P4P2) $ma
  puts "MAC at eth1 is $ma"
  AddToLog "MAC at eth1 is $ma"
  if {$gaSet(pair)=="5"} {
    AddToPairLog $pair "MAC at eth1 is $ma"
  } else {
    AddToPairLog $gaSet(pair) "MAC at eth1 is $ma"        
  }
  
  
  set ret [Send $com "dnfv-ver\r" :~$]
  set res [regexp {dnfv-([\d\.]+)} $buffer - val]
  if {$ret!=0 || $res==0} {
    set gaSet(fail) "Read DNFV ver fail"
    return -1
  }
  #if {$gaSet(dnfvVer) != $val} {}
  if {$b!="V"} {
    foreach {a bb c d e f} [split $gaSet(dbrSW) \(\).] {}
  } elseif {$b=="V"} {
    foreach {a bb c d e f} [split $gaSet(DNFVdbrSW) \(\).] {}
  }  
  append dbrSW $a.$bb.$c.$e
  if {$b!="V"} {
    puts "gaSet(dbrSW):<$gaSet(dbrSW)> dbrSW:<$dbrSW> val:<$val>"; update
  } elseif {$b=="V"} {
    puts "gaSet(dbrSW):<$gaSet(DNFVdbrSW)> dbrSW:<$dbrSW> val:<$val>"; update
  }

  if {$dbrSW != $val} {
    if {$b!="V"} {
      set gaSet(fail) "The DNFV ver is $val. Should be $gaSet(dbrSW)"; update
    } elseif {$b=="V"} {
      set gaSet(fail) "The DNFV ver is $val. Should be $gaSet(DNFVdbrSW)"; update
    }
    
    return -1  
  }
    
  return 0 
}
# ***************************************************************************
# BiosTest
# ***************************************************************************
proc BiosTest {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Enter to BIOS fail"
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  Status "Enter to BIOS"
  set ret [Send $com "configure chassis ve-module reset-wake\r" 2I]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis ve-module remote-terminal\r" 2I]
  if {$ret!=0} {return $ret}
  
  for {set attempt 1} {$attempt<=10} {incr attempt} {
    puts "BiosTest attempt:$attempt"
    if {$attempt>1} {
      RLSound::Play information
      set txt "Click \'OK\' and immediately push on Reset button of the DNFV"
      set res [DialogBox -type "OK Cancel" -icon /images/question \
          -title "Reset of DNFV" -message $txt -aspect 2000]
      update
      if {$res=="Cancel"} {
        return -2
      }
    }
    #set ret [Send $com "\r" "to enter setup"]
    #if {$ret=="-1"} {continue}
    for {set es 1} {$es <= 30} {incr es} {
      puts "es:$es" ; update
      Send $com "\33" "stam" 0.25
      if [string match *Project* $buffer] {
        set ret 0
        break
      }
      if [string match {*Quit without saving?*} $buffer] {
        Send $com "\33" "stam" 0.5
        set ret 0
        break
      }
    }  
    set ret 0
    
    if ![string match *Project* $buffer] {
      continue
    }
    after 3000
    
#     set res [regexp {Project Version.*(Z.*) x64} $buffer - val]
#     if {$res==0} {
#       set ret -1
#       set gaSet(fail) "Read \'Project Version\' fail"
#       break
#     }
#     set val [string trim $val]
#     set gaSet(dnfvProject) [string trim $gaSet(dnfvProject)]
#     puts "gaSet(dnfvProject):<$gaSet(dnfvProject)> val:<$val>"
#     if {$gaSet(dnfvProject) != $val} {
#       set ret -1
#       set gaSet(fail) "The \'Project Version\' is \'$val\'. Should be \'$gaSet(dnfvProject)\'"
#       break
#     }
#     
#     set res [regexp {EC Version\s+C ([\d\s]+)} $buffer - val]
#     if {$res==0} {
#       set ret -1
#       set gaSet(fail) "Read \'EC Version\' fail"
#       break
#     }
#     set val [string trim $val]
#     set gaSet(dnfvEC) [string trim $gaSet(dnfvEC)]
#     puts "gaSet(dnfvEC):<$gaSet(dnfvEC)> val:<$val>"
#     if {$gaSet(dnfvEC) != $val} {
#       set ret -1
#       set gaSet(fail) "The \'EC Version\' is \'$val\'. Should be \'$gaSet(dnfvEC)\'"
#       break
#     }
#     
    Status "Checking the CPU Type"
    ## move right
    Send $com "\33\[C" stam 3
    ## move right
    Send $com "\33\[C" stam 3
    ## enter to CPU screen
    Send $com "\r"  stam 3
    
    set res [regexp {CPU\s+(\w+)\s} $buffer - val]
    if {$res==0} {
      set ret -1
      set gaSet(fail) "Read \'CPU Type\' fail"
      break
    }
    set val [string trim $val]
    
    if {$b!="V"} {
      ## do nothing, d it's d
    } elseif {$b=="V"} {
      set d $gaSet(DNFVd)
    } 
    
    if {$d=="4C"} {
      set procVerShBe C2558
    } elseif {$d=="8C"} {
      set procVerShBe C2758
    }
    puts "procVerShBe:<$procVerShBe> val:<$val>"
    if {$procVerShBe != $val} {
      set ret -1
      set gaSet(fail) "The \'Processor Version\' is \'$val\'. Should be \'$procVerShBe\'"
      break
    }
    
    set res [regexp {Processor Frequency\s+([\d\.]+GHz) } $buffer - val]
    if {$res==0} {
      set ret -1
      set gaSet(fail) "Read \'Processor Frequency\' fail"
      break
    }
    set val [string trim $val]
    if {$b!="V"} {
      set gaSet(dnfvCPU) [string trim $gaSet(dnfvCPU)]
      set dnfvCPU $gaSet(dnfvCPU)
    } elseif {$b=="V"} {
      set gaSet(DNFVdnfvCPU) [string trim $gaSet(DNFVdnfvCPU)]
      set dnfvCPU $gaSet(DNFVdnfvCPU)
    }

    puts "dnfvCPU:<$dnfvCPU> val:<$val>"
    if {$dnfvCPU != $val} {
      set ret -1
      set gaSet(fail) "The \'Processor Frequency\' is \'$val\'. Should be \'$dnfvCPU\'"
      break
    }
    
    Send $com "\33" stam 3
    ## move down
    Send $com "\33\[B" stam 3
    ## move down
    Send $com "\33\[B" stam 3
    Send $com "\r"  stam 3
    
    set res [regexp {Total Memory\s+(\d+)} $buffer - val]
    if {$res==0} {
      set ret -1
      set gaSet(fail) "Read \'Total Memory\' fail"
      break
    }
    
    if {$b!="V"} {
      ## do nothing, r it's r
    } elseif {$b=="V"} {
      set r $gaSet(DNFVr)
    }
    puts "b:$b r:$r val:<$val>"
    if {$r != $val} {
      set ret -1
      set gaSet(fail) "The \'Total Memory\' is \'$val\'. Should be \'$r\'"
      break
    }
    Send $com "\33" stam 3
    Send $com "\33" stam 3
    Send $com "\r"  stam 3
    
    set ret 0
    break
    
  }
  puts "res of attempt-$attempt : <$ret>"
  return $ret
}
# ***************************************************************************
# DnfvParametersTest
# ***************************************************************************
proc DnfvParametersTest {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Enter to BIOS fail"
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  Status "Enter to BIOS"
  set ret [Send $com "configure chassis ve-module remote-terminal\r" 2I]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "DNFV boot fail"
  set secStart [clock seconds]
  while 1 {
    if {$gaSet(act)==0} {return -2}
    set secNow [clock seconds]
    set secUp [expr {$secNow - $secStart}] 
    $gaSet(runTime) configure -text $secUp
    puts "DNFV boot $secUp"
    update
    
    if {$secUp>90} {
      return -1  
    }
    
    if {$gaSet(act)==0} {return -2}
    
    set ret [Send $com \r "login:" 2]
    if {$ret=="0"} {break}
    #set ret [RLSerial::Waitfor $com buffer "login:" 2]
    #puts "$secUp <$buffer>"
    
    if [string match *:~$* $buffer] {
      set ret 0
      break
    }
    if [string match *rad#* $buffer] {
      set ret 0
      break
    }
    if [string match *user>* $buffer] {
      set ret [Login]
      if {$ret!=0} {return $ret}
      Send $com "configure chassis ve-module remote-terminal\r\r" "stam" 1
      set ret -1
    }
    if [string match *2I* $buffer] {
      Send $gaSet(comDut) "exit all\r" stam 1
      Send $com "configure chassis ve-module remote-terminal\r\r" "stam" 1
      set ret -1
    }
    #if {$ret=="0"} {break}
  }
  
  puts "DnfvParametersTest 1 ret:$ret"
  
  if [string match *login:* $buffer] {
    set gaSet(fail) "Enter to DNFV fail"
    set ret [Send $com "rad\r" "Password:"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "rad123\r" ":~\$"]
    if {$ret!=0} {return $ret}
  }
  puts "DnfvParametersTest 2 ret:$ret"
  
  set ret [regexp {86-(\w+):} $buffer - val]
  if {$ret==0} {
    set gaSet(fail) "Login to DNFV fail"
    return $ret
  }
  
  set ret [Send $com "cat /proc/cpuinfo \r" ":~\$" 20]
  if {$ret!=0} {return $ret}
  set res [regexp {model name : Intel\(R\) Atom\(TM\) CPU (C\d+) @ ([\w\.]+) stepping} $buffer - val1 val2]
  if {$res==0} {
    set gaSet(fail) "Read DNFV CPU info fail"
    return -1
  }
  
  if {$b!="V"} {
    ## do nothing, d it's d
  } elseif {$b=="V"} {
    set d $gaSet(DNFVd)
  } 
  
  if {$d=="4C"} {
    set procVerShBe C2558
  } elseif {$d=="8C"} {
    set procVerShBe C2758
  }
  puts "procVerShBe:<$procVerShBe> va1l:<$val1>"
  if {$procVerShBe != $val1} {
    set gaSet(fail) "The \'Processor Version\' is \'$val1\'. Should be \'$procVerShBe\'"
    return -1
  }
  
  set val2 [string trim $val2]
  if {$b!="V"} {
    set gaSet(dnfvCPU) [string trim $gaSet(dnfvCPU)]
    set dnfvCPU $gaSet(dnfvCPU)
  } elseif {$b=="V"} {
    set gaSet(DNFVdnfvCPU) [string trim $gaSet(DNFVdnfvCPU)]
    set dnfvCPU $gaSet(DNFVdnfvCPU)
  }

  puts "dnfvCPU:<$dnfvCPU> val2:<$val2>"
  if {$dnfvCPU != $val2} {
    set gaSet(fail) "The \'Processor Frequency\' is \'$val2\'. Should be \'$dnfvCPU\'"
    return -1
  }  
  
  set ret [Send $com "free -m \r" ":~\$" 20]
  if {$ret!=0} {return $ret}
  set res [regexp {Mem: (\d+) \d} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read DNFV MEMORY info fail"
    return -1
  }
  if {$b!="V"} {
    ## do nothing, r it's r
  } elseif {$b=="V"} {
    set r $gaSet(DNFVr)
  }
  puts "b:$b r:$r val:<$val>"
  if {$r != $val} {
    set gaSet(fail) "The \'Total Memory\' is \'$val\'. Should be \'$r\'"
    return -1
  }
  return 0
}

# ***************************************************************************
# DnfvHwTypeTest
# ***************************************************************************
proc DnfvHwTypeTest {} {
  global gaSet buffer
  Status "H.W Type Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read HWPORT_EPROM"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "HWPORT_EPROM_Read fail"
  Send $com "debug shell\r\r" stam 2
  set ret [Send $com "HWPORT_EPROM_Read(1)\r" "->"]
  if {$ret!=0} {return $ret}

  set ret [regexp {result:\s([\s\d]+) Interface} $buffer - val]
  if {$ret==0} {
    set gaSet(fail) "Get result fail"
    return -1
  }
  set val [string trim $val]
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b!="V"} {
    ## do nothing, d it's d
    ## do nothing, r it's r
  } elseif {$b=="V"} {
    set d $gaSet(DNFVd)
    set r $gaSet(DNFVr)
  }
  
  puts "d:$d r:$r" ; update
  if {$d=="4C"} {
    set resShBe "00 02 00 21 10 00 00 30"
  } elseif {$d=="8C"} {
    if {$r=="8192" || $r=="7972"} {
      set resShBe "00 02 00 21 10 00 00 50"
    } elseif {$r=="16384" || $r=="16036"} {
      set resShBe "00 02 00 51 10 00 00 50"
    }  
  }
  puts "resShBe:<$resShBe> val:<$val>" ; update
  if {$val!=$resShBe} {
    set gaSet(fail) "The HW Type is \'$val\'. Should be \'$resShBe\'"
    return -1
  }
  return 0
}
# ***************************************************************************
# ReadCPLD
# ***************************************************************************
proc ReadCPLD {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Read CPLD"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read CPLD"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  if ![info exists gaSet(cpld)] {
    set gaSet(cpld) ???
  } 
  set gaSet(fail) "Read CPLD fail"  
  set ret [Send $com "debug memory address c0100000 read char length 1\r" 2I]
  if {$ret!=0} {return $ret}
  set res [regexp {0xC0100000\s+(\w+)\s} $buffer - value]
  if {$res==0} {return -1}
  puts "\nReadCPLD value:<$value> gaSet(cpld):<$gaSet(cpld)>\n"; update
  if {$value!=$gaSet(cpld)} {
    set gaSet(fail) "CPLD is \'$value\'. Should be \'$gaSet(cpld)\'"  
    return -1
  }
  #set gaSet(cpld) ""
  return $ret
}
# ***************************************************************************
# FanTestPerf
# ***************************************************************************
proc FanTestPerf {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "FAN Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  set res [regexp {FAN Status[\s\-\d]+([\w\s]+)Sensor} $buffer - value]
  if {$res==0} {
    set gaSet(fail) "Read FAN Status fail"
    return -1
  } 
  set value [string trim $value]
  if {$value!="OK"} {
    set gaSet(fail) "FAN Status is \'$value\'. Should be \'OK\'"  
    return -1
  }
  return $ret
}

# ***************************************************************************
# DyingGaspLogPerf
# ***************************************************************************
proc DyingGaspLogPerf {psOffOn psOff} {
  global gaSet
  puts "[MyTime] DyingGaspLogPerf $psOffOn $psOff"
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  
  set ret [Wait "Wait for Management up" 10 white]
  if {$ret!=0} {return $ret}
  
  set ret [ClearLog]
  if {$ret!=0} {return $ret}
  ReadLog "stam"
  set ret [ClearLog]
  if {$ret!=0} {return $ret}
  
  Power $psOffOn on
  Power $psOff off
  Power $psOffOn off
  after 5000
  Power $psOffOn on
  
  set ret [Wait "Wait for reboot" 20 white ]
  if {$ret!=0} {return $ret}
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  
  set ret [ReadLog "Dying gasp"]
  if {$ret!=0} {
    return $ret
  }
  
  return $ret  
}

# ***************************************************************************
# ClearLog
# ***************************************************************************
proc ClearLog {} {
  global gaSet buffer
  set com $gaSet(comDut)
  puts "[MyTime] ClearLog"
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure reporting\r" ">reporting"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "clear-alarm-log all-logs\r" ">reporting"]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# ReadLog
# ***************************************************************************
proc ReadLog {findIt} {
  global gaSet buffer
  set com $gaSet(comDut)
  puts "[MyTime] ReadLog (\'$findIt\')"
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure reporting\r" ">reporting"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show log\r" ">reporting" 0.5]
  set resFind -1
  for {set i 1} {$i <= 20} {incr i} {
    if {$gaSet(act)==0} {return -2}
    
    puts "[MyTime] ReadLog (\'$findIt\') $i"
    if {[string match "*$findIt*" $buffer]} {
      set resFind 0
      break
    }
    set ret [Send $com "\r" "reporting" 1.5]
    if {$ret==0} {
      break
    }
  }
  ## check after last Enter when the unit already at "reporting" level
  if {[string match "*$findIt*" $buffer]} {
    set resFind 0
  }
  
  if {$resFind==0} {
    set ret 0
  } else {
    set gaSet(fail) "$findIt was not found in the report log"
    set ret -1
  }
  return $ret
}  
  
# ***************************************************************************
# AdminFactAll
# ***************************************************************************
proc AdminFactAll {} {
  global gaSet buffer
  global gaSet buffer gaGui
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Admin Factory All to UUT"  
  set com $gaSet(comDut)
  set ret [Send $com "admin factory-default-all\r" "yes/no"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "y\r" "seconds" 20]
  if {$ret!=0} {return $ret} 
  Wait "Wait for UUT up" 30
  return 0
}  
# ***************************************************************************
# VerifySN
# ***************************************************************************
proc VerifySN {} {
  global gaSet buffer
  global gaSet buffer gaGui
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
  }  
  Status "Read Serial Number at UUT"
  set com $gaSet(comDut)
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}  
  set ret [Send $com "configure system\r" system]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show device-information\r" system]
  if {$ret!=0} {return $ret}
  set res [regexp {Serial Number[\s\:]+(\d+)} $buffer ma val ]
  if {$res==0} {
    set res [string match {*Manufacturer Serial Number : Not Available*} $buffer]
    if {$res==0} {
      set gaSet(fail) "Read Serial Number fail"
      return -1
    } else {
      set val "0000000000000000"
    }
  }
  set gaSet(dutSerNum) [string trim $val]
  if {[string range $gaSet(dutSerNum) 0 5]=="000000"} {
    set dutSerNum [string range $gaSet(dutSerNum) 6 end]
  } else {
    set dutSerNum $gaSet(dutSerNum)
  }
  puts "SerNum:<$gaSet(dutSerNum)> dutSerNum:<$dutSerNum> gaSet(serialNum.$::pair):<$gaSet(serialNum.$::pair)>"
  if {$dutSerNum=="$gaSet(serialNum.$::pair)"} {
    return 0
  } else {
    set gaSet(fail) "SN is $dutSerNum instead of $gaSet(serialNum.$::pair)"
    return -1
  }
}
