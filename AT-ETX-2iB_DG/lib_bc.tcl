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
  set res2 -1
  
#   set pairIndx -1
  foreach {ent1 ent2} [lsort -dict [array names gaDBox entVal*]] { }
  foreach pair $lPassPair {
    #incr pairIndx
    #set pair [lindex $lPassPair $pairIndx]
    foreach la {1} {
      set mac $gaSet($pair.mac$la)
      if ![info exists gaSet($pair.barcode$la)] {
        set ret [ReadBarcode $pair]
        if {$ret!=0} {return $ret}
      }
      set barcode $gaSet($pair.barcode$la)
      set barcode$la $barcode
      #puts "pairIndx:$pairIndx pair:$pair"
      Status "Registration the UUT's $pair MAC ($mac $barcode)."
      if ![file exists c://RADapps/MACReg.exe] {
        file copy W://WinProg/MACRegistry/MACReg.exe c://RADapps/MACReg.exe
        after 1000
      }
      
      set ret 0
      if {$gaSet(performMacIdCheck)=="aa1"} {
        set ret [exec java -jar c:/radapps/CheckMAC.jar $barcode $mac]
        puts "[MyTime] Res of CheckMAC $barcode $mac : <$ret>" ; update
        if {$resChk!="0"} {
          set gaSet(fail) $ret
          if {$gaSet(pair)=="5"} {
            AddToLog "UUT:$pair MAC:$mac Barcode:$barcode <$ret>"
          } else {
            AddToLog "Pair:$gaSet(pair) $uut MAC:$mac Barcode:$barcode <$ret>"         
          }
        }
      }
      
      if {$ret==0} {
        set res$la [string trim [catch {exec c://RADapps/MACReg.exe /$mac /$barcode /DISABLE /DISABLE /DISABLE /DISABLE} retVal$la]]
        puts "mac:$mac barcode:$barcode res$la:<[set res$la]> retVal$la:<[set retVal$la]>"
        if {$gaSet(pair)=="5"} {
          AddToLog "UUT:$pair MAC:$mac Barcode:$barcode"
        } else {
          AddToLog "Pair:$gaSet(pair) $uut MAC:$mac Barcode:$barcode"         
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
    set id [open c://logs//macHistory.txt a]
    foreach la {1} {
      puts $id "[MyTime] Tester:$gaSet(pair) MAC:$gaSet($pair.mac$la) BarCode:[set barcode$la] res:[set res$la]"
    }      
    close $id
  
    if {$ret!=0} {
      break
    } 
  }  
  Status ""	  

  if {$res1 != 0} {
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
  if {$gaSet(useExistBarcode)==0} {
    if {$gaSet(pair)=="5"} {
      foreach pair $lPassPair {
        #lappend entLabL "Pair-$pair Local ($gaSet($pair.mac1))" "Remote ($gaSet($pair.mac2))"   
        lappend entLabL "UUT-$pair " 
      }
    } else {
      foreach pair $lPassPair {
        #lappend entLabL "Pair-$pair Local ($gaSet($pair.mac1))" "Remote ($gaSet($pair.mac2))"   
        lappend entLabL "UUT $gaSet(pair)" 
      }
    }
    RLSound::Play information
    set entLab $entLabL
    SendEmail "ETX-2i" "Read barcodes"
    set ret [DialogBox -title "barcode" -text "Enter the ETX-2i's barcode" \
        -type "Ok Cancel Skip" -entQty [llength $lPassPair] -entPerRow 1 -entLab $entLab -icon /images/info] 
  	if {$ret == "Cancel" } {
  	  return -2 
  	} elseif {$ret=="Ok"} {
      foreach {ent1} [lsort -dict [array names gaDBox entVal*]] {
        set barcode1 [string toupper $gaDBox($ent1)]  
        #set barcode2 [string toupper $gaDBox($ent2)]  
        puts "barcode1 == $barcode1"
  	    if ![string is xdigit $barcode1] {
          set gaSet(fail) "The barcode should be an HEX number"
          return -1
        }
        if {[string length $barcode1]!=11 && [string length $barcode1]!=12} {
          set gaSet(fail) "The barcode should be 11 or 12 HEX digits"
          return -1
        }
      }

      foreach name [lsort -dict [array names gaDBox]] {
        lappend scanbarcodesL $gaDBox($name)
      }
      set scanbarcodesLUnique [lsort -unique $scanbarcodesL]
      set llenScannedUnique [llength $scanbarcodesLUnique]
      set llenlPassPair [llength $lPassPair]
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
    if ![info exists gaSet(1.barcode1)] {
      set gaSet(useExistBarcode) 0
      return -1
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
  puts "ReadBarcode \"$lPassPair\"" ;  update
  set ret -1
  while {$ret != "0" } {
    set ret [CheckBcOk $lPassPair]
    puts "[MyTime] ret of CheckBcOk: $ret"
    Status $gaSet(fail)
    puts "CheckBcOk res:$ret "
    if { $ret == "-3" ||   $ret == "-2" ||  $ret == "-1" } {
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
  foreach {ent1} [lsort -dict [array names gaDBox entVal*]] {
    incr pairIndx
    set pair [lindex $lPassPair $pairIndx]
    foreach uut {1} ent {1} {
      set barcode [string toupper $gaDBox([set ent$ent])]  
      set gaSet($pair.barcode$uut) $barcode
      if {$gaSet(pair)=="5"} {
        AddToLog "UUT $pair - $barcode"
      } else {
        AddToLog "Pair $gaSet(pair) , $uut - $barcode"
      }
    }
  } 
  return $ret
}

