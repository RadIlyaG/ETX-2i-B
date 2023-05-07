# ***************************************************************************
# EntryBootMenu
# ***************************************************************************
proc EntryBootMenu {} {
  global gaSet buffer
  puts "[MyTime] EntryBootMenu"; update
  Status "Entry to Boot Menu"
#   set ret [Reset2BootMenu $uut]
#   if {$ret!=0} {return $ret}
  Power all off
  RLTime::Delay 2
  Power all on
  RLTime::Delay 2
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
    set ret [Login]
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read USB port fail"
  set ret [Send $com "debug test usb\r" ETX-2I]
  if {$ret!=0} {return $ret}
  
  if {[string match {*DEV*Mouse*} $buffer] || \
      [string match {*DEV*Keyboard*} $buffer]} {
    set ret 0
  } else {
    set ret -1
    set gaSet(fail) "USB port doesn't recognize an USB Mouse"
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
    set ret [Login]
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
    set ret [Login]
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
    set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  Status "Read info"
  set com $gaSet(comDut)  
  set ret [Send $com "exit all\r" ETX-2I]
  if {$ret!=0} {return $ret}
  set ret [Send $com "info\r" more 30]  
#   regexp {sw\s+\"(\d+\.\d+\.\d+)\(} $buffer - sw
#   regexp {sw\s+\"(.+)\"\s} $buffer - sw
  regexp {sw\s+\"([\.\d\(\)\w]+)\"\s} $buffer - sw
  
  if ![info exists sw] {
    set gaSet(fail) "Can't read the SW version"
    return -1
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b=="RJIO"} {
    set dbrSW [set gaSet(dbrSW)]SR
    
    set dbrSW 6.0.1(0.32)SR
    AddToLog "set dbrSW 6.0.1(0.32)SR !!!!!"
    puts "set dbrSW 6.0.1(0.32)SR !!!!!" ; update
    
  } else {
    set dbrSW [set gaSet(dbrSW)]
  }  
  puts "sw:<$sw> dbrSW:<$dbrSW>" ; update
  set gaSet(fail) "Can't reach the \'ETX-2I\' prompt"
  set ret [Send $com "\3" ETX-2I 3.25]
  if {$ret!=0} {return $ret}
  if {$sw!=$dbrSW} {
    set gaSet(fail) "SW is \"$sw\". Should be \"$dbrSW\""
    return -1
  }
  if {[string range $sw end-1 end]=="SR" && $r=="R"} {
    set gaSet(fail) "The sw is \"$sw\" and the DUT is RTR"
    return -1
  }
  if {[string range $sw end-1 end]!="SR" && $r=="0"} {
    set gaSet(fail) "The sw is \"$sw\" and the DUT is not RTR"
    return -1
  }
  
  if {$b=="RJIO"} { 
    set portL [list 0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8 0/9 0/10]
  }  
  foreach port $portL {
    set ret [ReadEthPortStatus $port]
    if {$ret=="-1" || $ret=="-2"} {return $ret}
    
  }
  
  set ret [ReadMac]
  if {$ret!=0} {return $ret}
  
  return 0
  
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
  global gaSet buffer gRelayState gaGui
  Status "DyingGaspTest"
  set indx 0
  for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
    if {[$gaGui(labPairPerf$i) cget -bg]!="yellow"} {
      continue
    }
    puts "DyingGaspTest 1. $i"; update
    set gaSet(comDut) $gaSet(comDut$i)
    set ret [Login]
    if {$ret!=0} {
      set ret [Login]
      if {$ret!=0} {
        PairPerfLab $i red
        AddToLog "UUT-$i. Login fail"
        continue
      }
    }
    puts "DyingGaspTest 2. $i"; update
    
    set com $gaSet(comDut)
    Send $com "exit all\r" stam 0.25 
  
    set cf $gaSet(DGaspCF)
    set cfTxt "Dying Gasp"
    set ret [DownloadConfFile $cf $cfTxt 1]
    if {$ret!=0} {
      PairPerfLab $i red
      AddToLog "UUT-$i. Download Conf. File fail"
      continue
    }
    puts "DyingGaspTest 3. $i"; update
  
    set goodPings 0
    #set dutIp 10.10.10.1[set gaSet(comDut)]  
    set dutIp 10.10.10.1[set gaSet(com2dut.$gaSet(comDut))]
    Status "Pings to UUT-$i"
    for {set pi 1} {$pi<=4} {incr pi} {   
      set ret [Ping $dutIp]
      puts "DyingGaspSetup ping after download pi:$pi i:i ret:$ret"
      if {$ret!=0} {
        PairPerfLab $i red
        AddToLog "UUT-$i. No pings"
        continue
      }
      incr goodPings
      if {$goodPings==3} {
        break
      }
    }
    puts "DyingGaspTest 4. $i"; update
  }
  puts "DyingGaspTest 5. $i"; update
  Power all off
  after 1000
  Power all on
  set ret 0
  puts "DyingGaspTest 6. $i"; update
  
  Wait "Wait ETX booting" 35
  if {$ret!=0} {return $ret}
  
  for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
    puts "DyingGaspTest 7. $i"; update
    if {[$gaGui(labPairPerf$i) cget -bg]!="yellow"} {
      continue
    }
    puts "DyingGaspTest 8. $i"; update
    set gaSet(comDut) $gaSet(comDut$i)
    set ret [Login]
    if {$ret!=0} {
      set ret [Login]
      if {$ret!=0} {
        PairPerfLab $i red
        AddToLog "UUT-$i. Login fail"
        continue
      }
    }
    puts "DyingGaspTest 9. $i"; update
  }
  puts "DyingGaspTest ret:$ret 10. $i"; update

#   set snmpId [RLScotty::SnmpOpen $dutIp]
#   RLScotty::SnmpConfig $snmpId -version SNMPv3 -user initial
  return $ret
}    
 
# ***************************************************************************
# DyingGaspPerf
# ***************************************************************************
proc DyingGaspPerf {psOffOn psOff} {
  global trp tmsg gaSet gaGui
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
    if {[$gaGui(labPairPerf$i) cget -bg]!="yellow"} {
      continue
    }
    set gaSet(comDut) $gaSet(comDut$i)
    set ret [Login]
    if {$ret!=0} {
      set ret [Login]
      if {$ret!=0} {
        PairPerfLab $i red
        AddToLog "UUT-$i. Login fail"
        continue
      }
    }
  
    set gaSet(fail) "Logon fail"
    set com $gaSet(comDut)
    Send $com "exit all\r" stam 0.25 
  }  
  
 #   set dutIp 10.10.10.1[set gaSet(comDut)]
#     set ret [Ping $dutIp]
#     if {$ret!=0} {return $ret}
  
  RLScotty::SnmpCloseAllTrap
  ##catch {exec arp.exe -d $dutIp} resArp
  #puts "[MyTime] resArp:$resArp"
  
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
#   #Power $psOff off
#   for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
#     if {[$gaGui(labPairPerf$i) cget -bg]!="yellow"} {
#       continue
#     }
#     set gaSet(comDut) $gaSet(comDut$i)
#     set ret [Send $gaSet(comDut) "configure port ethernet 0/1\r" "0/1"]
#     if {$ret!=0} {
#       PairPerfLab $i red
#       AddToLog "UUT-$i. configure port ethernet fail"
#       continue
#     }
#   }  
#   
#   set ret -1
#   for {set i 1} {$i<=5} {incr i} {
#     set tmsg ""
#     set ret [Send $com "shutdown\r" "0/1"]
#     if {$ret==0} {
#       after 1000
#       set ret [Send $com "no shutdown\r" "0/1"]
#       if {$ret!=0} {
#         RLScotty::SnmpCloseTrap $trp(id)
#         return $ret
#       }
#     } 
#     puts "i:$i tmsgStClk:<$tmsg>"
#     if {$tmsg!=""} {
#       set ret 0
#       #break
#     }
#     after 1000
#   }
#   if {$ret=="-1"} {
#     set gaSet(fail) "Traps are not sent"
#     RLScotty::SnmpCloseTrap $trp(id)
#     return -1
#   }
#   
#   #after 3000
#   Wait "Wait for traps" 10 white
  set tmsg ""
  
  Power $psOffOn on
  Power $psOff off
  Wait "Wait for trap 1" 3 white
  puts "tmsgDG 1.1:<$tmsg>"
  set tmsg ""
  puts "tmsgDG 1.2:<$tmsg>"
  
  Power $psOffOn off
  Wait "Wait for trap 2" 3 white 
   
  #set ret [regexp -all "$dutIp\[\\s\\w\\:\\-\\.\\=\]+\\\"\\w+\\\"\[\\s\\w\\:\\-\\.\\=\]+\\\"\[\\w\\:\\-\\.\]+\\\"\[\\s\\w\\:\\-\\.\\=\]+\\\"\[\\w\\-\]+\\\"" $tmsg v]  
  puts "tmsgDG 2:<$tmsg>"
  AddToLog ""
  AddToLog "DyingGasplog:"
  AddToLog "$tmsg"
  AddToLog ""
  set ret 0
  for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
    if {[$gaGui(labPairPerf$i) cget -bg]!="yellow"} {
      continue
    }
    set gaSet(comDut) $gaSet(comDut$i)
    #set dutIp 10.10.10.1[set gaSet(comDut)]
    set dutIp 10.10.10.1[set gaSet(com2dut.$gaSet(comDut))]
    set res$i [regexp "from\\s$dutIp:\\s\.\+\:systemDyingGasp" $tmsg -]
    if {[set res$i]=="0"} {
      PairPerfLab $i red
      AddToLog "UUT-$i. No \"DyingGasp\" trap was detected"
      set ret -1
      set gaSet(fail) "UUT-$i. No \"DyingGasp\" trap was detected"
      continue
    } else {
      AddToLog "UUT-$i. \"DyingGasp\" trap was detected"
    }  
  }
  Power $psOffOn on
  
  # Close sesion:
  RLScotty::SnmpCloseTrap $trp(id)  
  
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
    set ret [Login]
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
    set ret [Login]
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
    set ret [Login]
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
    set ret [Login]
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
    set ret [Login]
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
    set ret [Login]
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
    set ret [Login]
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
    set ret [Login]
    if {$ret!=0} {return $ret}
  }
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
  if {($mac2<0x0020D2500000) || ($mac2>0x0020D2FFFFFF)} {
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
    set ret [Login]
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
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "UUT-[set gaSet(com2dut.$gaSet(comDut))].Login into ETX-2i"
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
    set ret 0
    return 0
  }
  if {[string match *boot* $buffer]} {
    Send $gaSet(comDut) run\r stam 1
  }
  if {[string match *user* $buffer]} {
    Send $gaSet(comDut) su\r stam 0.25
    set ret [Send $gaSet(comDut) 1234\r "ETX-2I"]
    $gaSet(runTime) configure -text ""
    return $ret
  }
  if {$ret!=0} {
    set ret [Wait "Wait for ETX up" 20 white]
    if {$ret!=0} {return $ret}  
  }
  for {set i 1} {$i <= 15} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into ETX-2I"
    puts "Login into ETX-2I i:$i"; update
    $gaSet(runTime) configure -text $i
    Send $gaSet(comDut) \r stam 5
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2I user> } 5 60]
    if {([string match {*-2I*} $buffer]==1) || ([string match {*user>*} $buffer]==1)} {
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
    if {[string match *user* $buffer]} {
      Send $gaSet(comDut) su\r stam 1
      set ret [Send $gaSet(comDut) 1234\r "-2I"]
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
proc FactDefault {mode waitAfter} {
  global gaSet buffer gaGui
  for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
    if {[$gaGui(labPairPerf$i) cget -bg]!="yellow"} {
      continue
    }
    set gaSet(comDut) $gaSet(comDut$i)
    puts "FactDefault gaSet(comDut):$gaSet(comDut)"
    set ret [Login]
    if {$ret!=0} {
      set ret [Login]
      if {$ret!=0} {
        PairPerfLab $i red
        AddToLog "UUT-$i. Login fail"
        continue
      }
    }
    
    set com $gaSet(comDut)
    Send $com "exit all\r" stam 0.25 
 
    Status "UUT-$i. Factory Default..."
    if {$mode=="std"} {
      set ret [Send $com "admin factory-default\r" "yes/no" ]
    } elseif {$mode=="stda"} {
      set ret [Send $com "admin factory-default-all\r" "yes/no" ]
    }
    if {$ret==0} {
      set ret [Send $com "y\r" "seconds" 20]
      if {$ret!=0} {
        PairPerfLab $i red
        AddToLog "UUT-$i. Set to Default fail"
        continue
      }
    }  
  }
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
    set ret [Login]
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
    set ret [Login]
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
    set ret [Login]
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
    set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Load Default Configuration fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(defConfCF) 
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
    set ret [Login]
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
proc DryContactTest {} {
  global gaSet buffer
  Status "Dry Contact Test"
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
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
    set ret [Login]
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
# BiosTest
# ***************************************************************************
proc BiosTest {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Enter to BIOS fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure chassis ve-module remote-terminal\r" 2I]
  if {$ret!=0} {return $ret}
  
  for {set attempt 1} {$attempt<=10} {incr attempt} {
    
    RLSound::Play information
    set txt "Click \'OK\' and immediately push on Reset button of the DNFV"
    set res [DialogBox -type "OK Cancel" -icon /images/question \
        -title "Reset of DNFV" -message $txt -aspect 2000]
    update
    if {$res=="Cancel"} {
      return -2
    }
    set ret [Send $com "\r" "to enter setup"]
    if {$ret=="-1"} {continue}
    
    set ret [Send $com "\33" "stam" 5]
    set ret 0
    
    if ![string match *Project* $buffer] {
      continue
    }
    
    set res [regexp {Project Version.*(Z.*) x64} $buffer - val]
    if {$res==0} {
      set ret -1
      set gaSet(fail) "Read \'Project Version\' fail"
      break
    }
    set val [string trim $val]
    set gaSet(dnfvProject) [string trim $gaSet(dnfvProject)]
    puts "gaSet(dnfvProject):<$gaSet(dnfvProject)> val:<$val>"
    if {$gaSet(dnfvProject) != $val} {
      set ret -1
      set gaSet(fail) "The \'Project Version\' is \'$val\'. Should be \'$gaSet(dnfvProject)\'"
      break
    }
    
    set res [regexp {EC Version\s+C ([\d\s]+)} $buffer - val]
    if {$res==0} {
      set ret -1
      set gaSet(fail) "Read \'EC Version\' fail"
      break
    }
    set val [string trim $val]
    set gaSet(dnfvEC) [string trim $gaSet(dnfvEC)]
    puts "gaSet(dnfvEC):<$gaSet(dnfvEC)> val:<$val>"
    if {$gaSet(dnfvEC) != $val} {
      set ret -1
      set gaSet(fail) "The \'EC Version\' is \'$val\'. Should be \'$gaSet(dnfvEC)\'"
      break
    }
    
    set res [regexp {Total Memory\s+(\d+)} $buffer - val]
    if {$res==0} {
      set ret -1
      set gaSet(fail) "Read \'Total Memory\' fail"
      break
    }
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
    puts "b:$b r:$r val:<$val>"
    if {$r != $val} {
      set ret -1
      set gaSet(fail) "The \'Total Memory\' is \'$val\'. Should be \'$r\'"
      break
    }
    
    ## move right
    Send $com "\33\[C" stam 3
    ## move down
    Send $com "\33\[B" stam 3
    ## enter to CPU screen
    Send $com "\r"  stam 3
    
    set res [regexp {TM\) (i.*GHz)} $buffer - val]
    if {$res==0} {
      set ret -1
      set gaSet(fail) "Read \'CPU Type\' fail"
      break
    }
    set val [string trim $val]
    set gaSet(dnfvCPU) [string trim $gaSet(dnfvCPU)]
    puts "gaSet(dnfvCPU):<$gaSet(dnfvCPU)> val:<$val>"
    if {$gaSet(dnfvCPU) != $val} {
      set ret -1
      set gaSet(fail) "The \'CPU Type\' is \'$val\'. Should be \'$gaSet(dnfvCPU)\'"
      break
    }
    
    Send $com "\33\[A" "Config TDP LOCK"
    Send $com "\33\[A" "Config TDP LOCK"
    Send $com "\33\[A" "Save & Exit"
    Send $com "\33\[A" "Save & Exit"
    if {[string match {*Turbo Mode \[Disabled\]*} $buffer]} {
      set ret 0
    } elseif {[string match {*Turbo Mode \[Enabled\]*} $buffer]} {
      Send $com \r stam 1
      ## move down
      Send $com "\33\[B" stam 1
      Send $com \r stam 3
      if {![string match {*Turbo Mode \[Disabled\]*} $buffer]} {
        set gaSet(fail) "Configuration Turbo Mode to Disabled failed"
        set ret -1
        break
      }
    }
    #Send $com "\33\[A" "Previous Values"
#     for {set i 1} {$i <= 5} {incr i} {
#       ## move up
#       Send $com "\33\[A" stam 8
#       if {[string match {*Turbo Mode \[Disabled\]*} $buffer]} {
#         set ret 0
#         break
#       } 
#       if {[string match {*Turbo Mode \[Enabled\]*} $buffer]} {
#         Send $com \r stam 1
#         ## move down
#         Send $com "\33\[B" stam 1
#         Send $com \r stam 8
#         if {[string match {*Turbo Mode \[Disabled\]*} $buffer]} {
#           set ret 0
#           break
#         }
#       } 
#     }
    
    for {set i 1} {$i <= 6} {incr i} {
      ## move up
      Send $com "\33\[A" stam 1 
    }  
    Send $com "22" stam 1 
    ## move down to see all changes
    Send $com "\33\[B" stam 3
    
    Send $com "\33" stam 2
    
    ## move left
    Send $com "\33\[D" stam 3
    Send $com "\33\[D" stam 2
    Send $com "\r" stam 2
    Send $com "\r" stam 2
    
    set ret 0
    break
    
  }
  puts "res of attempt-$attempt : <$ret>"
  return $ret
}
# ***************************************************************************
# BurnMacTest
# ***************************************************************************
proc BurnMacTest {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Enter to DNFV fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure chassis ve-module remote-terminal\r" 2I]
  if {$ret!=0} {return $ret}
  set ret [Send $com "\r" "stam" 1]
  if {[string match {*login*} $buffer] || [string match {*Password*} $buffer]} {
    ## the DNFV is not new, so he MACs are burned already
    set gaSet(dnfvMac1) rad
    set gaSet(dnfvMac2) rad
    return 0
  }
  
  set secStart [clock seconds]
  while 1 {
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set runSec [expr {$nowSec - $secStart}]
    $gaSet(runTime) configure -text $runSec
    update
    if {$runSec>45} {
      return -1
    }
    set ret [Send $com "\r" "new date" 1]
    if {$ret==0} {break}
    #RLSerial::Waitfor $com buffer stam 2
    #puts "$runSec <$buffer>" ; update
    #if {[string match {*new date*} $buffer]==1} {
    #  set ret 0
    #  break
    #}
    if {[string match {*login*} $buffer] || [string match {*Password*} $buffer]} {
      ## the DNFV is not new, so he MACs are burned already
      set gaSet(dnfvMac1) rad
      set gaSet(dnfvMac2) rad
      return 0
    }
  }
  
  
  set ret [GetMac 1]
  if {$ret=="-1"} {return $ret}
  set mac1 $ret
  
  set ret [GetMac 2]
  if {$ret=="-1"} {return $ret}
  set mac2 $ret
  set gaSet(dnfvMac1) $mac1
  set gaSet(dnfvMac2) $mac2
  
  
  if {$ret!=0} {return $ret}
  set ret [Send $com "\r" "new time" 1]
  #if {$ret!=0} {return $ret}
  set ret [Send $com "\r" "C:"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "rad.bat\r" "1 MAC Address:"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "$mac1\r" "2 MAC Address:" 30]
  if {$ret!=0} {return $ret}
  if ![string match {*updated successfully*} $buffer] {
    set gaSet(fail) "MAC1 updating fail"  
  }
  
  set ret [Send $com "$mac2\r" "complete the programming process" 30]
  if {$ret!=0} {return $ret}
  
  return 0 
}

# ***************************************************************************
# SoftwareDownloadTest
# ***************************************************************************
proc SoftwareDownloadTest {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Enter to DNFV fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  Status "Wait for DNFV booting"
  set ret [Send $com "configure chassis ve-module remote-terminal\r\r" "login:" 2]
  
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
  
  Status "Wait DNFV up"
  set ret [Send $com "\r" "login:" 1]
  set secStart [clock seconds]
  while 1 {
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set runSec [expr {$nowSec - $secStart}]
    $gaSet(runTime) configure -text $runSec
    update
    if {$runSec>90} {
      return -1
    }
    RLSerial::Waitfor $com buffer stam 2
    puts "$runSec <$buffer>" ; update
    if {[string match {*login:*} $buffer]==1} {
      set ret 0
      break
    }
    
  }
  
  if {$ret!=0} {return $ret}
  if {$ret!=0} {return $ret}
  
  return $ret
}  

# ***************************************************************************
# MacSwIDTest
# ***************************************************************************
proc MacSwIDTest {} {
  global gaSet buffer 
  set com $gaSet(comDut)
  
  set gaSet(fail) "DNFV boot fail"
  set secStart [clock seconds]
  while 1 {
    if {$gaSet(act)==0} {return -2}
    set secNow [clock seconds]
    set secUp [expr {$secNow - $secStart}] 
    $gaSet(runTime) configure -text $secUp
    update
    if {$secUp>30} {
      return -1  
    }
    if {$gaSet(act)==0} {return -2}
    set ret [Send $com \r "login:" 2]
    #set ret [RLSerial::Waitfor $com buffer "login:" 2]
    #puts "$secUp <$buffer>"
    
    if [string match *:~$* $buffer] {
      set ret 0
    }
    if [string match *user>* $buffer] {
      set ret [Login]
      if {$ret!=0} {return $ret}
      Send $com "configure chassis ve-module remote-terminal\r\r" "stam" 1
      set ret 0
    }
    if {$ret=="0"} {break}
  }
  
  if [string match *login:* $buffer] {
    set gaSet(fail) "Enter to DNFV fail"
    set ret [Send $com "rad\r" "Password:"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "rad123\r" ":~\$"]
    if {$ret!=0} {return $ret}
  }
  set ret [Send $com "ifconfig\r" ":~\$" 11]
  if {$ret!=0} {return $ret}
  
  if ![info exists gaSet(dnfvMac1)] {
    set gaSet(dnfvMac1) rad
    set mac1 $gaSet(dnfvMac1) 
  } else {
    #set mac1 [string tolower [join [SplitString2Paires  $gaSet(dnfvMac1)] :]]
    set mac1 [string tolower $gaSet(dnfvMac1)]  
  } 
  if ![info exists gaSet(dnfvMac2)] {
    set gaSet(dnfvMac2) rad
    set mac2 $gaSet(dnfvMac2) 
  } else {
    #set mac2 [string tolower [join [SplitString2Paires  $gaSet(dnfvMac2)] :]]
    set mac2 [string tolower $gaSet(dnfvMac2)]  
  }  
    
  set ret [regexp {p4p1\s+Link encap:Ethernet\s+HWaddr\s+([0-9a-f\:]+)} $buffer - val]
  if {$ret==0} {
    set gaSet(fail) "Get p4p1 fail"
    return -1
  }
  set val 0x[join [split $val :] ""]
  set radMin 0x0020d2500000
  set radMax 0x0020d2ffffff
  if {$mac1 =="rad"} {
    if {$val<$radMin || $val>$radMax} {
      set gaSet(fail) "MAC at P4P1 is $val. Should be between $radMin and $radMax"
      return -1  
    }
  } else {
    if {$mac1 != $val} {
      set gaSet(fail) "MAC at P4P1 is $val. Should be $mac1"
      return -1  
    }
  }
  
  set ret [regexp {p4p2\s+Link encap:Ethernet\s+HWaddr\s+([0-9a-f\:]+)} $buffer - val]
  if {$ret==0} {
    set gaSet(fail) "Get p4p2 fail"
    return -1
  }
  set val 0x[join [split $val :] ""]
  if {$mac2=="rad"} {
    if {$val<$radMin || $val>$radMax} {
      set gaSet(fail) "MAC at P4P2 is $val. Should be between $radMin and $radMax"
      return -1  
    }
  } else {
    if {$mac2 != $val} {
      set gaSet(fail) "MAC at P4P2 is $val. Should be $mac2"
      return -1  
    }
  }
  
  set ret [Send $com "dnfv-ver\r" :~$]
  set res [regexp {dnfv-([\d\.]+)} $buffer - val]
  if {$ret!=0 || $res==0} {
    set gaSet(fail) "Read DNFV ver fail"
    return -1
  }
  if {$gaSet(dnfvVer) != $val} {
    set gaSet(fail) "The DNFV ver is $val. Should be $gaSet(dnfvVer)"
    return -1  
  }
    
  return 0 
}
# ***************************************************************************
# ForceMode
# ***************************************************************************
proc ForceMode {b mode} {
  global gaSet buffer
  Status "Force Mode $mode"
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Activation debug test fail"
  set ret [Send $com "debug test\r" test]
  if {$ret!=0} {return $ret}
  
  ## 13/07/2016 13:42:51 6 -> 8
  for {set port 1} {$port <= 8} {incr port} {
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
proc ReadEthPortStatus {port} {
  global gaSet buffer
#   Status "Read EthPort Status of $port"
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
  Status "Read EthPort Status of $port"
  set gaSet(fail) "Show status of port $port fail"
  set com $gaSet(comDut) 
  Send $com "exit all\r" stam 1 
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  set res [Send $com "show status\r" "SFP In" 20]
  set ::bu $buffer
  if {$res!=0} {
    after 2000
    set ret [Send $com "\r" ($port)]
    append ::bu $buffer 
    if {$ret!=0} {return $ret}
    set res [Send $com "show status\r" "SFP In" 20]   
    append ::bu $buffer 
  }
  set ret [Send $com "\r" ($port)]
  append ::bu $buffer
  if {$ret!=0} {return $ret}
  
  if {$res!=0} {
    set gaSet(fail) "The port's $port status is not \'SFP In\'"
    return -1
  }
  
  set ret -1
  foreach connType [list RJ-45 LC] {
    if {[string match *$connType* $::bu]} {
      set ret 0
      puts "connType: $connType"
      break
    }
  } 
  puts ret:$ret
  if {$ret!=0} {
    set gaSet(fail) "The port's $port Connector Type is not RJ-45 or LC"
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
  set ret [Send $com "show summary\r" "port"]
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
    for {set lo 1} {$lo<=4} {incr lo} {
      if {$gaSet(act)==0} {return -2}
      set ret [Send $com "\r" "login" 0.5]
      if {$ret==0} {break} 
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
  
  set ret [Send $com "dnfv-br-cross-off\r" :~$ 2]
  
  if {[string match {*password for rad*} $buffer]} {
    set ret [Send $com "rad123\r" :~$]
    if {$ret!=0} {return $ret}
  }  
  
  set ret [Send $com "dnfv-br-cross-$mode\r" :~$ 2]
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