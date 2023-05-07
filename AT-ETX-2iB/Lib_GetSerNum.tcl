package require img::gif
package require img::jpeg
package require img::ico
package require RLSound
# ***************************************************************************
# GetOperator
#
# args:
# -i  - icon's path+name (example: -i images/serNum.32.ico)
# -ti - the Dialog's title
# -te - the Dialog's text near the entry 
# ***************************************************************************
proc GetSerNum {args} {
  global gaGetSnDBox gaSet
  RLSound::Open
  set gaSet(radNet) 0
  foreach {jj ip} [regexp -all -inline {v4 Address[\.\s\:]+([\d\.]+)} [exec ipconfig]] {
    if {[string match {*192.115.243.*} $ip] || [string match {*172.18.9*} $ip]} {
      set gaSet(radNet) 1
    }  
  }  
  if {$gaSet(radNet)==0} {return 0}
  
  set iIndx [lsearch $args "-i"]
  if {$iIndx=="-1"} {
    set icon images/serNum.32.ico
  } else {
    set icon [lindex $args [expr {$iIndx+1}]]    
  }
  if ![file exists $icon] {
    tk_messageBox -type ok -icon error -message "$icon doesn't exist"
    return -1
  }
  
  set tiIndx [lsearch $args "-ti"]
  if {$tiIndx=="-1"} {
    set ti "Get Serial Number"
  } else {
    set ti [lindex $args [expr {$tiIndx+1}]]    
  }
  set teIndx [lsearch $args "-te"]
  if {$teIndx=="-1"} {
    #set te "Operator's Name "
    set te "UUT's Serial Number "
  } else {
    set te [lindex $args [expr {$teIndx+1}]]    
  }
  
  set pairsIndx [lsearch $args "-pairs"]
  if {$pairsIndx=="-1"} {
    set pairs 1
  } else {
    set pairs [lindex $args [expr {$pairsIndx+1}]]    
  }
  set entLab ""
  foreach pa $pairs {
    lappend entLab "UUT $pa"
  }
  puts "pairs:<$pairs> entLab:<$entLab>"
  
   
  set errTxt ""
  set serL ""
  while 1 {
    RLSound::Play information
    set ret [GetSnDlg -title $ti -text "$te" -type "Ok Cancel" -icon $icon -entQty [llength $pairs] -entLab $entLab]     
    #puts "\n<$ret> was clicked\n" 
    if {$ret=="Cancel"} {
      return -1
    }
    
    set serL ""
    set te ""
    set ind 1
    foreach pa $pairs {
      set serNum [string toupper $gaGetSnDBox(entVal$ind)]
      puts "entryValue of $pa:<$serNum>"
      if {[string length $serNum]==10  && [string is digit $serNum]} {
        set serL [concat $serL $pa $serNum]      
      } else {
        ## try again
        set te "UUT-$pa $serNum is not valid\nTry again"
        break
      }
      incr ind
    } 
    if {$te==""} {
      ## all pair OK, break the while
      break
    } 
  }
  return $serL
}
# ***************************************************************************
# GetOpDlg
# ***************************************************************************
proc GetSnDlg {args} {
  global gaGetSnDBox
  catch {array unset gaGetSnDBox}
  
  # each option & default value
  foreach {opt def} {title "DialogBox" text "" icon "" type ok \
                     parent . aspect 1150 default 0 entQty 1 entLab "" entPerRow 1\
                     linkText "" linkCmd "" justify center width "" message ""\
                     ent1focus 1 place center font TkDefaultFont DotEn 1 DashEn 1} {
    set var$opt [GetSnOpt $args "-$opt" $def]
  }
  
  set varaccpButIndx $vardefault
  if {$varentQty>0} {
    set vardefault [llength $vartype]
  }
  
  set lOptions [list -parent $varparent -modal local -separator 0 \
      -title $vartitle -side bottom -anchor c -default $vardefault -cancel 1 -place $varplace]
  if [winfo exists .tmpldlg] {
    wm deiconify .tmpldlg
    wm deiconify $varparent
    wm deiconify .tmpldlg
    return {}
  }

  #create icon 
  if {[string length $varicon]>0} {
    if {[string index $varicon end-3]=="."} {
      set micon $varicon
    } else {
      set micon $varicon.gif
    }
  }
  if {[catch {image create photo -file [pwd]/$micon} img] == 0} {
    set lOptions [concat $lOptions "-image $img"]
  }
  
  #create Dialog
  set dlg [eval Dialog .tmpldlg $lOptions]

  #create Buttons
  foreach but $vartype {
    if {[lsearch $vartype $but]==$varaccpButIndx} {
      $dlg add -text $but -name $but -command [list GetSnEndDlg $dlg $but $varentQty $varDotEn $varDashEn]
    } else {
      $dlg add -text $but -name $but -command [list Dialog::enddialog $dlg $but]
    }    
  }
  
  #create message
  ## supports -message for convertion from tk_messageBox to DialogBox 
  if {$varmessage!=""} {
    set vartext $varmessage
  }
  set msg [message [$dlg getframe].msg -text $vartext  \
     -anchor c -aspect $varaspect -justify left -font $varfont]
  pack $msg -anchor w -padx 3 -pady 3 ; #-fill both -expand 1
  
  if {$varentQty>0} {
    #-textvariable gaGetOpDBox(entVal$fi)
    #-vcmd {GetOpEntryValidCmd %P}  -validate all
    #set varentPerRow 2
    set fr [frame [$dlg getframe].fr -bd 0 -relief groove]
      for {set fi 1} {$fi<=$varentQty} {incr fi} {
        set f [frame $fr.f$fi -bd 0 -relief groove]
          set labText [lindex $varentLab [expr $fi-1]]
          set lab$fi [label $f.lab$fi  -text $labText]
          set ent$fi [entry $f.ent$fi] 
          
          ## user defined Entry width
          if {$varwidth!=""} {
            [set ent$fi] configure -width $varwidth
          }
          pack [set ent$fi] -padx 2 -side right -fill x -expand 1
          
          ## don't pack empty Label
          if {$labText!=""} {            
            pack [set lab$fi] -padx 2 -side right
          }
          
        #pack $f -padx 2 -pady 2  -anchor e -fill x -expand 1
        grid $f -padx 2 -pady 2 -row [expr {($fi-1) / $varentPerRow}] -column [expr {($fi-1) % $varentPerRow}]
        
        
        ## in case of 2 Entries pack them side-by-side
        if {$varentQty=="2"} {
          #pack configure $f -side left; # -fill x -expand 1
        }
        [set ent$fi] delete 0 end					         
      }
    pack $fr -padx 2 -pady 2 -fill both -expand 1 
    set taskL [exec tasklist.exe]
    if {[regexp -all wish* $taskL]!="1"} {
      if {$varent1focus==1} {
        focus -force $ent1
      }  
    } else {
      ##  if just one wish is existing - put the focus
      focus -force $ent1
    }
    
    ## binding for each Entries, except last
    for {set fi 1} {$fi<$varentQty} {incr fi} {
      bind [set ent$fi] <Return> [list GetSnReturnOnEntry [set ent$fi] $fi [list focus -force [set ent[expr {$fi+1}]] ] $varDotEn $varDashEn ]
    }
    ## binding for the last Entry
    bind [set ent$varentQty] <Return> [list GetSnReturnOnEntry [set ent$varentQty] $fi [list $dlg invoke $varaccpButIndx ] $varDotEn $varDashEn ]
  }
  
  #create "html" link
  if {$varlinkText!=""} {
    set ht [label [$dlg getframe].ht -text $varlinkText -fg blue -cursor hand2]
    set curFont [$ht cget -font]
    if {[llength $curFont]>1} {
      set newFont [linsert $curFont end underline]
    } else {
      set newFont {{MS Sans Serif} 8 underline}
    }
    $ht configure -font $newFont
    pack $ht -anchor w  -padx 6
    bind $ht <1> $varlinkCmd
  }
  
  set ret [$dlg draw]		
  destroy $dlg
  return $ret
}
#***************************************************************************
#** Opt
#***************************************************************************
proc GetSnOpt {lOpt opt def} {
  set tit [lsearch $lOpt $opt]
  if {$tit != "-1"} {
    set title [lindex $lOpt [incr tit]]
  } else {
    set title $def
  }
  return $title
}
# ***************************************************************************
# GetOpEndDlg
# ***************************************************************************
proc GetSnEndDlg {dlg but varentQty dotEn dashEn} {
  set res 1
  for {set fi 1} {$fi<=$varentQty} {incr fi} {
    set res [GetSnReturnOnEntry [$dlg getframe].fr.f$fi.ent$fi $fi [list return 1]  $dotEn $dashEn]
    #puts "fi:$fi res:$res"
    if {$res!="1"} {return}
  }    
  Dialog::enddialog $dlg $but
}
# ***************************************************************************
# GetOpReturnOnEntry
# ***************************************************************************
proc GetSnReturnOnEntry {e fi cmd dotEn dashEn} {
  global gaGetSnDBox
  set P [$e get]
  set res [GetSnEntryValidCmd $P $dotEn $dashEn]
  #puts "e:$e P:$P res:$res cmd:$cmd fi:$fi" ; update
  if {$res==1} {
    set gaGetSnDBox(entVal$fi) $P
    eval $cmd
  } else {
    $e selection range 0 end 
  }
}
# ***************************************************************************
# GetOpEntryValidCmd
# this proc must return 1 or 0
# ***************************************************************************
proc GetSnEntryValidCmd {P dotEn dashEn} {
  #puts "GetOpEntryValidCmd $P $dotEn $dashEn"
  set leng [string length $P]
	set rep [regexp -all { } $P]
	if {$dotEn=="1"} {
    set dot "OK"
    set P  [regsub -all {[\.]} $P ""]
  } elseif {$dotEn=="0"}  {
    if {[regexp {\.} $P]==0} {
      set dot "OK"
    } else {
      set dot "BAD"
    }
  }
  if {$dashEn=="1"} {
    set dash "OK"
    set P  [regsub -all {[\-]} $P ""]
  } elseif {$dashEn=="0"}  {
    if {[regexp {\-} $P]==0} {
      set dash "OK"
    } else {
      set dash "BAD"
    }
  }
  set num [string is alnum [regsub -all {[\s]} $P ""]]
  
  #puts "leng:<$leng> rep:<$rep> num:<$num> $dot $dash"
	if {($leng>0) && ($leng!=$rep) && ($num=="1") && ($dot=="OK") && ($dash=="OK")} {
	  return 1
  } else {
    return 0
  }
}
# ***************************************************************************
# CRC
# ***************************************************************************
proc CRC {ldata} {

  #demo:
  #set ldata [list 11 02 11 10 00 00 00 00 00 01 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00]
  #set ldata [list 00 00 00 00 00 00 00 00 00 00 00 00 00 00 03 00 20 D2 FB 5E C5 00 00 00 00 00 00 00 00 00 00 00]

  set lKey [list \
  00 07 0E 09 1C 1B 12 15 \
  38 3F 36 31 24 23 2A 2D \
  70 77 7E 79 6C 6B 62 65 \
	48 4F 46 41 54 53 5A 5D \
	E0 E7 EE E9 FC FB F2 F5 \
	D8 DF D6 D1 C4 C3 CA CD \
	90 97 9E 99 8C 8B 82 85 \
	A8 AF A6 A1 B4 B3 BA BD \
	C7 C0 C9 CE DB DC D5 D2 \
	FF F8 F1 F6 E3 E4 ED EA \
	B7 B0 B9 BE AB AC A5 A2 \
	8F 88 81 86 93 94 9D 9A \
	27 20 29 2E 3B 3C 35 32 \
	1F 18 11 16 03 04 0D 0A \
	57 50 59 5E 4B 4C 45 42 \
	6F 68 61 66 73 74 7D 7A \
	89 8E 87 80 95 92 9B 9C \
	B1 B6 BF B8 AD AA A3 A4 \
	F9 FE F7 F0 E5 E2 EB EC \
	C1 C6 CF C8 DD DA D3 D4 \
  69 6E 67 60 75 72 7B 7C \
	51 56 5F 58 4D 4A 43 44 \
	19 1E 17 10 05 02 0B 0C \
	21 26 2F 28 3D 3A 33 34 \
	4E 49 40 47 52 55 5C 5B \
	76 71 78 7F 6A 6D 64 63 \
	3E 39 30 37 22 25 2C 2B \
	06 01 08 0F 1A 1D 14 13 \
	AE A9 A0 A7 B2 B5 BC BB \
	96 91 98 9F 8A 8D 84 83 \
	DE D9 D0 D7 C2 C5 CC CB \
	E6 E1 E8 EF FA FD F4 F3 ]

  set crc 00
  set lvar "$ldata"
  foreach a "$lvar" {
    set crc [lindex $lKey [expr 0x$crc^0x$a]]    
  }
  return $crc
}

# ***************************************************************************
# AsciiToHex_Convert_Split
# ***************************************************************************
proc AsciiToHex_Convert_Split {Ascii} {
  for {set i 0} {$i<=[expr [string length $Ascii]-1]} {incr i} {
    set arg [string range $Ascii $i $i]   
    lappend Hex [format %.2X [scan $arg %c]]
  }
  return $Hex
}

# ***************************************************************************
# DecToHex_Convert_Split
# ***************************************************************************
proc DecToHex_Convert_Split {Dec} {
  set Hex [format "%.2X" $Dec]
  return $Hex
}

# ***************************************************************************
# Split_Mac
# ***************************************************************************
proc Split_Mac {Mac} {
  foreach from "0 2 4 6 8 10" to "1 3 5 7 9 11" {
    lappend Split_Mac [string range $Mac $from $to]
  }
  return $Split_Mac
}
# ***************************************************************************
# WritePage0
# ***************************************************************************
proc WritePage0 {} {
  global gaGui buffer buff  gaSet
  set com $gaSet(comDut)
  
	if {[Send $com "\r" "\[boot" 1] != 0} {
	  set gaSet(fail) "Failed to get Boot Menu" ; update
    return -1
	}
       
  Send $com  "c ip\r" stam 0.5
  Send $com  "10.10.10.5\r" "\[boot" 1
  Send $com  "c sip\r" stam 0.5
  Send $com  "10.10.10.10\r" "\[boot" 1
  
  Send $com "p\r" "\[boot" 1
  set ret [regexp {device IP[ \(\w \)]+:[ ]+[\w]+.[\w]+.([\w]+).([\w]+)} $buffer var var1 var2]	
  if {$ret!=1} {
    set gaSet(fail) "Failed to get Device IP" ; update
    return -1	  
  }
	  
  # Dec:
  set var1 [string trim $var1]
  set var2 [string trim $var2]
  #dec to Hex
  set var1 [format %.2x $var1]
  set var2 [format %.2x $var2]
  set password "y$var1$var2"
  puts "password:$password"
  
  Send $com "\20\r" "\[boot" 1 ;# Shift ctrl-p
  
  set device 00 ; #constant
	set offSet 00
  Send $com "d2 $device,00,32,$offSet\r" "\[boot" 2
  set ret [regexp {([\w\.]{47})\s+([\w\.]{47})} $buffer var var1 var2]
  if {$ret!=1} {
    set gaSet(fail) "Page0 check fail." ; update
    return -1	  
  }
  set var1 [string trim [regsub -all -- {\.} $var1 " "]]
  set var2 [string trim [regsub -all -- {\.} $var2 " "]]
  set res "$var1 $var2"
  set resL [split $res " "]
  set l1 [list 00 00 00 [string range $gaSet(serialNum.$::pair) 0 1] [string range $gaSet(serialNum.$::pair) 2 3]\
   [string range $gaSet(serialNum.$::pair) 4 5] [string range $gaSet(serialNum.$::pair) 6 7]  [string range $gaSet(serialNum.$::pair) 8 9]] 
  set l2 [lrange $resL 8 end]   
  set page0 [concat $l1 $l2]      		
	  		  
	puts "page0:<$page0>"; update
  #set device 00 ; #constant
	set crc [CRC $page0]
	#set offSet 00   
  Status "Writing page 0"   	
		
	if {[Send $com "c2 $device,00,$offSet,$page0,$crc\r" "data ?" 3] != 0} {
	 set gaSet(fail) "Writing Error - Page 0"
    return -1
  }			      
  Send $com "$password\r" "\[boot" 2
    
  # Read:
  #d2 <device#>,<page#>,<#byte>,<offset>
  Send $com "d2 $device,00,32,$offSet\r" "\[boot" 2
  set ret [regexp {([\w\.]{47})\s+([\w\.]{47})} $buffer var var1 var2]
  if {$ret!=1} {
    set gaSet(fail) "Page0 check fail." ; update
    return -1	  
  }
  set var1 [string trim [regsub -all -- {\.} $var1 " "]]
  set var2 [string trim [regsub -all -- {\.} $var2 " "]]
  set res "$var1 $var2"
  if {[string match *$page0* $res]==0} {
    set gaSet(fail) "Page0 result fail." ; update
    puts "res:$res"
    puts "pag:$page0"
    #puts stderr "Page$page result fail." 
    return -1    
  }            		
	Send $com "run\r" stam 0.25
  Wait "Wait for UUT up" 30
	return 0
}



