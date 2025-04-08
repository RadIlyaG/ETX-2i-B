#***************************************************************************
#** DialogBoxEnt
#** 
#** For icon option in [pwd] must be gif file with name like icon.  
#**   error.gif for icon 'error'
#**   stop.gif  for icon 'stop'
#**
#** Input parameters:
#**   -title   Specifies a string to display as the title of the message box. 
#**            The default value is an empty string. 
#**   -text    Specifies the message to display in this message box.  
#**            The default value is an empty string. 
#**   -icon    Specifies an icon to display.
#**            If this option is not specified, then no icon will be displayed. 
#**   -type    Arranges for a predefined set of buttons to be displayed.
#**            The default value is 'ok' button.
#**   -parent  Makes window the logical parent of the message box. 
#**            The message box is displayed on top of its parent window.
#**            The default value is window '.'
#**   -aspect  Specifies a non-negative integer value indicating desired 
#**            aspect ratio for the text.
#**            The aspect ratio is specified as 100*width/height.
#**            100 means the text should be as wide as it is tall, 
#**            200 means the text should be twice as wide as it is tall, 
#**            50 means the text should be twice as tall as it is wide, and so on.
#**            Used to choose line length for text if width option isn't specified. 
#**            Defaults to 150. 
#**   -default Name gives the symbolic name of the default button 
#**            for this message window ('ok', 'cancel', and so on). 
#**            If the message box has just one button it will automatically 
#**            be made the default, otherwise if this option is not specified,
#**            there won't be any default button. 
#**
#** Return value: name of the pressed button
#** Example:
#**   DialogBox
#**   DialogBox -icon error -type "ok yes TCL" -text "Move the Cables"
#***************************************************************************
proc DialogBoxEnt {args} {

  # each option & default value
  foreach {opt def} {title "DialogBoxE" text "" icon "" type ok \
                     parent . aspect 2000 default 0 entVar ""} {
    set var$opt [Opte $args "-$opt" $def]
  }
  wm deiconify $varparent
  set lOptions [list -parent $varparent -modal local -separator 0 \
      -title $vartitle -side bottom -anchor c -default $vardefault -cancel 1]

  if {[catch {Bitmap::get [pwd]\\$varicon.gif} img] == 0} {
    set lOptions [concat $lOptions "-image $img"]
  }

  #create Dialog
  set dlg [eval Dialog .tmpldlg $lOptions]

  #create Buttons
  foreach but $vartype {
    $dlg add -text $but -name $but -command [list Dialog::enddialog $dlg $but]
  }

  #create message
  set msg [message [$dlg getframe].msg -text $vartext -justify center \
     -anchor c -aspect $varaspect]  
  pack $msg -fill both -expand 1 -padx 10 -pady 3

  if {$varentVar!=""} {
    set ent [Entry [$dlg getframe].ent -justify center]
    pack  $ent
	 focus $ent
  }

  set ret [$dlg draw]
  if {$varentVar!=""} {
    set entryString  [$ent cget -text]
	  set ::$varentVar $entryString
  }
  destroy $dlg
  return $ret
}



#***************************************************************************
#** Opte
#***************************************************************************
proc Opte {lOpt opt def} {
  set tit [lsearch $lOpt $opt]
  if {$tit != "-1"} {
    set title [lindex $lOpt [incr tit]]
  } else {
    set title $def
  }
  return $title
} 

# ***************************************************************************
# RegBC
# ***************************************************************************
proc RegBC {lPassPair} {
  global gaSet gaDBox
  Status "BarCode Registration"
  puts "RegBC \"$lPassPair\"" ;  update
  set ret  -1
  set res1 -1
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$b!="V"} {
    set laL 1
    set namL "UUT"
    set res2 0
  } elseif {$b=="V"} {
    set laL "1 2"
    set namL "UUT DNFV"
    set res2 -1
  }  
  
#   set pairIndx -1
  foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] { }
  foreach pair $lPassPair {
    #incr pairIndx
    #set pair [lindex $lPassPair $pairIndx]
    foreach la $laL nam $namL {
      set mac $gaSet($pair.mac$la)
      if {![info exists gaSet($pair.barcode$la)] || $gaSet($pair.barcode$la)=="skipped"} {
        set ret [ReadBarcode $pair]
        if {$ret!=0} {return $ret}
      }
      set barcode $gaSet($pair.barcode$la)
      set barcode$la $barcode
      set barc$la $barcode
      #puts "pairIndx:$pairIndx pair:$pair"
      Status "Registration the ${nam}'s $pair MAC ($barcode $mac)."
      set ret 0
      puts "gaSet(performMacIdCheck):<$gaSet(performMacIdCheck)>"
      if {$gaSet(performMacIdCheck)=="1"} {
        set barc [string range $barcode 0 10]
        catch {exec java -jar $::RadAppsPath/CheckMAC.jar $barc $mac} resChk
        #foreach {ret resTxt} [::RLWS::CheckMac $barcode AABBCCFFEEDD] {}
        #puts "[MyTime] Res of CheckMac $barc $mac ret:<$ret> resTxt:<$resTxt>" ; update
        puts "[MyTime] Res of CheckMAC $barc $mac : <$resChk>" ; update
        if {$resChk!="0"} {
          set gaSet(fail) $resChk
          if {$gaSet(pair)=="5"} {
            AddToLog "$nam:$pair Barcode:$barcode MAC:$mac <$resChk>"
            AddToPairLog $pair "$nam:$pair Barcode:$barcode MAC:$mac <$resChk>"
          } else {
            AddToLog "Tester:$gaSet(pair) $nam Barcode:$barcode MAC:$mac <$resChk>" 
            AddToPairLog $gaSet(pair) "Tester:$gaSet(pair) $nam Barcode:$barcode MAC:$mac <$resChk>"        
          }
          return -1
        }
      }
      
      if {$ret==0} {
#         set mr [file mtime $::RadAppsPath/MACReg.exe]
#         set prevMr [clock scan "Wed Jan 22 23:20:40 2020"] ; # last working version, with 1 MAC
#         if {$mr>$prevMr} {
#           ## the newest MacReg
#           set str "$::RadAppsPath/MACReg.exe /$mac / /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE"
#         } else {
#           set str "$::RadAppsPath/MACReg.exe /$mac /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE"
#         }
#         puts "mr:<[clock format $mr]> prevMr:<[clock format $prevMr]> \n str<$str>"
        set str "$::RadAppsPath/MACReg_2Mac_2IMEI.exe /$mac / /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE"
        set res$la [string trim [catch {eval exec $str} retVal$la]]
        #set res$la [string trim [catch {exec c://RADapps/MACReg.exe /$mac /$barcode /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE /DISABLE} retVal$la]]
        puts "nam:$nam mac:$mac barcode:$barcode res$la:<[set res$la]> retVal$la:<[set retVal$la]>"
        if {$gaSet(pair)=="5"} {
          AddToLog "$nam:$pair Barcode:$barcode MAC:$mac"
          AddToPairLog $pair "$nam:$pair Barcode:$barcode MAC:$mac"
        } else {
          AddToLog "Tester:$gaSet(pair) $nam Barcode:$barcode MAC:$mac"  
          AddToPairLog $gaSet(pair) "Tester:$gaSet(pair) $nam Barcode:$barcode MAC:$mac"       
        }
        update
        #after 1000
        if {[set res$la]!="0" } {
          puts "ret:[set res$la]"
          set ret -1
          break
        } else {
          set ret 0        
        }
      } else {
        set res$la -1
      }
    } 
    
      
    if {$ret!="0"} {
      break
    }
   
#     AddToLog "mac:$mac Barcode-1 - $barcode1"
    
    if ![file exists c://logs//macHistory.txt] {
      set id [open c://logs//macHistory.txt w]
      after 100
      close $id
    }
    set id [open c://logs//macHistory.txt a+]
    foreach la $laL nam $namL {
      puts $id "[MyTime] Tester:$gaSet(pair) $nam MAC:$gaSet($pair.mac$la) BarCode:[set barcode$la] res:[set res$la]"
    }      
    close $id
  
    if {$ret!=0} {
      break
    } 
  }  
  Status ""	  

  if {$res1 != 0 || $res2 != 0} {
	  set gaSet(fail)  "Fail to update Data-Base"
	  return -1 
	} else {
 		return 0 
  }
} 

# ***************************************************************************
# CheckBcOk
# ***************************************************************************
proc CheckBcOk {lPassPair} {
	global  gaDBox  gaSet
  puts "CheckBcOk \"$lPassPair\"" ;  update
  set pair 1
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$gaSet(useExistBarcode)==0} {
    if {$gaSet(pair)=="5"} {
      foreach pair $lPassPair {
        #lappend entLabL "Pair-$pair Local ($gaSet($pair.mac1))" "Remote ($gaSet($pair.mac2))"
        if {$b=="DNFV"} {   
          lappend entLabL "DNFV-$pair "
        } elseif {$b=="V"} { 
          if {$gaSet(readTrace)=="0"} {  
            lappend entLabL "UUT-$pair" "DNFV"
          } elseif {$gaSet(readTrace)=="1"} {  
            lappend entLabL "UUT-$pair" "Traceability" "DNFV"
          } 
        } else {   
          #lappend entLabL "UUT-$pair "
          if {$gaSet(readTrace)=="0"} {  
            lappend entLabL "UUT-$pair "
          } elseif {$gaSet(readTrace)=="1"} {  
            lappend entLabL "UUT-$pair " "Traceability"
          }
        }  
      }
    } else {
      foreach pair $lPassPair {
        #lappend entLabL "Pair-$pair Local ($gaSet($pair.mac1))" "Remote ($gaSet($pair.mac2))"   
        if {$b!="V"} {
          #lappend entLabL "UUT" 
          if {$gaSet(readTrace)=="0"} {  
            lappend entLabL "UUT"
          } elseif {$gaSet(readTrace)=="1"} {  
            lappend entLabL "UUT" "Traceability"
          }
        } elseif {$b=="V"} {
          #lappend entLabL "UUT" "DNFV"
          if {$gaSet(readTrace)=="0"} {  
            lappend entLabL "UUT" "DNFV"
          } elseif {$gaSet(readTrace)=="1"} {  
            lappend entLabL "UUT" "Traceability" "DNFV"
          }
        }
      }
    }
    RLSound::Play information
    set entLab $entLabL
    SendEmail "ETX-2i" "Read barcodes"
    if {$b!="V"} {
      if {$gaSet(readTrace)=="0"} { 
        set entPerRow 1
        set entQty [llength $lPassPair]        
        set entL "ent1"
      } elseif {$gaSet(readTrace)=="1"} { 
        set entPerRow 2
        set entQty [expr {2*[llength $lPassPair]}]
        set entL "ent1 ent3"
      }
      set checkEntQty [llength $lPassPair]
    } elseif {$b=="V"} {
      if {$gaSet(readTrace)=="0"} {
        set entPerRow 2
        set entQty [expr {2*[llength $lPassPair]}]
        set entL "ent1 ent2"
      } elseif {$gaSet(readTrace)=="1"} {
        set entPerRow 3
        set entQty [expr {3*[llength $lPassPair]}]
        set entL "ent1 ent3 ent2"
      }
      set checkEntQty [expr {2*[llength $lPassPair]}]
    }
    set ret [DialogBox -title "Barcode" -text "Enter the UUT's barcode" \
        -type "Ok Cancel" -entQty $entQty -entPerRow $entPerRow \
        -ent1focus 1 -entLab $entLab -icon /images/info] 
    #  -type "Ok Cancel Skip" 12/10/2020 09:41:19    
  	if {$ret == "Cancel" } {
  	  return -2 
  	} elseif {$ret=="Ok"} {
      foreach $entL [lsort -dict [array names gaDBox entVal*]] {
        set barcode1 [string toupper $gaDBox($ent1)] 
        puts "barcode1 == $barcode1"
        if ![string is xdigit $barcode1] {
          set gaSet(fail) "The barcode ($barcode1) should be an HEX number"
          return -1
        }
        if {[string length $barcode1]!=11 && [string length $barcode1]!=12} {
          set gaSet(fail) "The barcode ($barcode1) should be 11 or 12 HEX digits"
          return -1
        }
        if {$b=="V"} { 
          set barcode2 [string toupper $gaDBox($ent2)] 
          puts "barcode2 == $barcode2" 
          if ![string is xdigit $barcode2] {
            set gaSet(fail) "The barcode ($barcode2) should be an HEX number"
            return -1
          }
          if {[string length $barcode2]!=11 && [string length $barcode2]!=12} {
            set gaSet(fail) "The barcode ($barcode2) should be 11 or 12 HEX digits"
            return -1
          }
        }            	    
      }
         
#       if {$gaSet(readTrace)=="0"} {
#         foreach name [lsort -dict [array names gaDBox]] {
#           lappend scanbarcodesL $gaDBox($name)
#         }
#       } elseif {$gaSet(readTrace)=="1"} {
#         set names [lsort -dict [array names gaDBox]]
#         for {set nameIndx 0} {$nameIndx<[llength $names]} {incr nameIndx} {
#           if {$b!="V"} {
#             if {$nameIndx!="1" && $nameIndx!="3" && $nameIndx!="5" && $nameIndx!="7" &&\
#                 $nameIndx!="9" && $nameIndx!="11" && $nameIndx!="13" && $nameIndx!="15" &&\
#                 $nameIndx!="17" && $nameIndx!="19" && $nameIndx!="21" && $nameIndx!="23" &&\
#                 $nameIndx!="25" && $nameIndx!="25"} {
#               set name [lindex $names nameIndx]  
#               lappend scanbarcodesL $gaDBox($name)  
#             }
#           } elseif {$b=="V"} {
#             if {$nameIndx!="1" && $nameIndx!="4" && $nameIndx!="7" && $nameIndx!="10" &&\
#                 $nameIndx!="13" && $nameIndx!="16" && $nameIndx!="19" && $nameIndx!="22" &&\
#                 $nameIndx!="17" && $nameIndx!="19" && $nameIndx!="21" && $nameIndx!="23" &&\
#                 $nameIndx!="25" && $nameIndx!="25"} {
#               set name [lindex $names nameIndx]  
#               lappend scanbarcodesL $gaDBox($name)  
#             }
#           }
#         }
#       }
      foreach name [lsort -dict [array names gaDBox]] {
        set scanbarcode $gaDBox($name)
        if {[string is integer [string index $scanbarcode 0]]!="1"} {
          ## ID numbers have 2 letters as 2 first characters
          ## traceability ID is only numbers
          ## so, if first character is not integer then the barcode is ID and 
          ## we should take it to test
          lappend scanbarcodesL $gaDBox($name)
          
        }
      }
      set scanbarcodesLUnique [lsort -unique $scanbarcodesL]
      set llenScannedUnique [llength $scanbarcodesLUnique]
      #set llenlPassPair [llength $lPassPair]
      set llenlPassPair $checkEntQty
      if {$llenScannedUnique != $llenlPassPair} {
        set gaSet(fail) "A barcode was scanned more then once"
        return -1
      }
      return 0  	
  	} elseif {$ret=="Skip"} {
      set gaSet(fail) "No barcode. The reading was skipped"
      return -3
    }
  } elseif {$gaSet(useExistBarcode)==1} {
    foreach pair $lPassPair {
      if ![info exists gaSet($pair.barcode1)] {
        set gaSet(useExistBarcode) 0
        return -1
      } else {
        puts "CheckBcOk useExistBarcode==1 gaSet($pair.barcode1):$gaSet($pair.barcode1)"
      }
      if {$b=="V"} {
        if ![info exists gaSet($pair.barcode2)] {
          set gaSet(useExistBarcode) 0
          return -1
        } else {
          puts "CheckBcOk useExistBarcode==1 gaSet($pair.barcode2):$gaSet($pair.barcode2)"
        }
      }
    }
    set gaSet(useExistBarcode) 0
    return 0
  }
}
# ***************************************************************************
# ReadBarcode
# ***************************************************************************
proc ReadBarcode {lPassPair} {
  global gaSet gaDBox
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  puts "ReadBarcode \"$lPassPair\"" ;  update
  set ret -1
  catch {array unset gaDBox}
  while {$ret != "0" } {
    set ret [CheckBcOk $lPassPair]
    puts "[MyTime] ret of CheckBcOk: $ret"
    Status $gaSet(fail)
    puts "CheckBcOk res:$ret "
    if {$ret == "-2" ||  $ret == "-1" } {
      return $ret
    }
    
    #07/02/2019 08:11:30
    if { $ret == "-3"} {
      foreach {pair} $lPassPair {
        if {$gaSet(pair)=="5"} {
          set gaSet(log.$pair) c:/logs/${gaSet(logTime)}-skipped.txt
          set pa $pair
        } else {
          set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-skipped.txt
          set pa $gaSet(pair)
        }
        set gaSet($pa.barcode1) "skipped"
        AddToPairLog $pa "$gaSet(DutFullName)"
        AddToPairLog $pa "UUT - barcode skipped"
      }
      return $ret
    }  
	}	
  Status ""
#   foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] {
#     foreach la {1} {
#       set barcode [string toupper $gaDBox([set ent$la])]  
#       set gaSet(1.barcode$la) $barcode
#     }
#   }    
  
  set pairIndx -1
  puts "b:$b"
  if {$b!="V"} {
    if {$gaSet(readTrace)=="0"} {
      foreach {ent1} [lsort -dict [array names gaDBox entVal*]] {
        incr pairIndx
        set pair [lindex $lPassPair $pairIndx]
        foreach uut {1} ent {1} {
          set barcode [string toupper $gaDBox([set ent$ent])]  
          set gaSet($pair.barcode$uut) $barcode
          
          if {$gaSet(pair)=="5"} {
            AddToLog "UUT $pair - $barcode"
  #           AddToPairLog $pair "UUT $pair - $barcode"
          } else {
            AddToLog "Pair $gaSet(pair) , $uut - $barcode"
  #           AddToPairLog $gaSet(pair) "Pair $gaSet(pair) , $uut - $barcode"
          }
        }
        set gaSet($pair.trace) NA
        if {$gaSet(pair)=="5"} {
          set gaSet(log.$pair) c:/logs/${gaSet(logTime)}-$barcode.txt
          set pa $pair
        } else {
          set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-$barcode.txt
          set pa $gaSet(pair) 
        }
        CheckMac $barcode $pa $uut
        AddToPairLog $pa "$gaSet(DutFullName)"
        AddToPairLog $pa "UUT - $barcode"
      } 
    } elseif {$gaSet(readTrace)=="1"} {
      foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] {
        incr pairIndx
        set pair [lindex $lPassPair $pairIndx]
        foreach uut {1} ent {1} {
          set barcode [string toupper $gaDBox([set ent$ent])]  
          set gaSet($pair.barcode$uut) $barcode
          if {$gaSet(pair)=="5"} {
            AddToLog "UUT $pair - $barcode"
  #           AddToPairLog $pair "UUT $pair - $barcode"
          } else {
            AddToLog "Pair $gaSet(pair) , $uut - $barcode"
  #           AddToPairLog $gaSet(pair) "Pair $gaSet(pair) , $uut - $barcode"
          }
        }
        set gaSet($pair.trace) [string toupper $gaDBox(entVal2)] 
        if {$gaSet(pair)=="5"} {
          set gaSet(log.$pair) c:/logs/${gaSet(logTime)}-$barcode.txt
          set pa $pair
        } else {
          set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-$barcode.txt
          set pa $gaSet(pair) 
        }
        AddToPairLog $pa "$gaSet(DutFullName)"
        AddToPairLog $pa "UUT - $barcode $gaSet($pair.trace) "
        CheckMac $barcode $pa $uut
      } 
    }
  } elseif {$b=="V"} {
    if {$gaSet(readTrace)=="0"} {
      foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] {
        incr pairIndx
        set pair [lindex $lPassPair $pairIndx]
        puts "ent1:$ent1 ent2:$ent2 pairIndx:$pairIndx pair:$pair"
        foreach uut {1 2} ent {1 2} nam {UUT DNFV} {
          puts "uut:$uut ent:$ent nam:$nam" 
          set barcode [string toupper $gaDBox([set ent$ent])]  
          set gaSet($pair.barcode$uut) $barcode
          set barc$uut $barcode
          if {$gaSet(pair)=="5"} {
            AddToLog "Pair $pair - $nam <$barcode>"            
          } else {
            AddToLog "Pair $gaSet(pair) , $nam <$barcode>"
          }
        }
        set gaSet($pair.trace) NA
        puts "pair:$pair gaSet(pair):$gaSet(pair)"
        if {$gaSet(pair)=="5"} {
          set gaSet(log.$pair) c:/logs/${gaSet(logTime)}-$barc1-$barc2.txt
          set pa $pair
        } else {
          set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-$barc1-$barc2.txt
          set pa $gaSet(pair) 
        }
        AddToPairLog $pa "$gaSet(DutFullName)"
        AddToPairLog $pa "UUT - $barc1"
        AddToPairLog $pa "DNFV - $barc2"
        CheckMac $barc1 $pa 1
      } 
    } elseif {$gaSet(readTrace)=="1"} {
      foreach {ent1 ent2 ent3} [lsort -dict [array names gaDBox entVal*]] {
        incr pairIndx
        set pair [lindex $lPassPair $pairIndx]
        puts "ent1:$ent1 ent2:$ent2 ent3:$ent3 pairIndx:$pairIndx pair:$pair"
        foreach uut {1 2} ent {1 3} nam {UUT DNFV} {
          puts "uut:$uut ent:$ent nam:$nam" 
          set barcode [string toupper $gaDBox([set ent$ent])]  
          set gaSet($pair.barcode$uut) $barcode
          set barc$uut $barcode
          if {$gaSet(pair)=="5"} {
            AddToLog "Pair $pair - $nam <$barcode>"
          } else {
            AddToLog "Pair $gaSet(pair) , $nam <$barcode>"
          }
        }
        set gaSet($pair.trace) [string toupper $gaDBox(entVal2)] 
        puts "pair:$pair gaSet(pair):$gaSet(pair)"
        if {$gaSet(pair)=="5"} {
          set gaSet(log.$pair) c:/logs/${gaSet(logTime)}-$barc1-$barc2.txt
          set pa $pair
        } else {
          set gaSet(log.$gaSet(pair)) c:/logs/${gaSet(logTime)}-$barc1-$barc2.txt
          set pa $gaSet(pair) 
        }
        AddToPairLog $pa "$gaSet(DutFullName)"
        AddToPairLog $pa "UUT - $barc1"
        AddToPairLog $pa "DNFV - $barc2"
        CheckMac $barc1 $pa 1
      } 
    }
  }
  
  return $ret
}


# ***************************************************************************
# UnregIdBarcode
# UnregIdBarcode $gaSet(1.barcode1)
# UnregIdBarcode EA100463652
# ***************************************************************************
proc UnregIdBarcode {pa barcode {mac {}}} {
  global gaSet
  Status "Unreg ID Barcode $pa $barcode"
  set res [UnregIdMac $barcode $mac]
    
  puts "\nUnreg ID Barcode $barcode res:<$res>\n"
  if {$res=="OK" || [string match "*No records to Delete by ID-Number*" $res]} {
    set ret 0
  } else {
    set ret $res
  }
  AddToPairLog $pa "Unreg ID Barcode $barcode mac:<$mac> res:<$res> ret:<$ret>"
  return $ret
}

# ***************************************************************************
# UnregIdMac
# ***************************************************************************
proc UnregIdMac {barcode {mac {}}} {
  set ret 0
  set res ""
  set url "http://ws-proxy01.rad.com:10211/ATE_WS/ws/rest/"
  #set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param "DisconnectBarcode\?mac=[set mac]\&idNumber=[set barcode]"
  append url $param
  puts "url:<$url>"
  if [catch {set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]} res] {
    return $res
  } 
  update
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    set res "http::status: <$st> http::ncode: <$nc>"
    set ret -1
  }
  upvar #0 $tok state
  #parray state
  #puts "body:<$state(body)>"
  set ret $state(body)
  ::http::cleanup $tok
  
  return $ret
}

