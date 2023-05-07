wm iconify . ; update

if 0 {
package require RLAutoUpdate
#set s1 //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-64ET1/AT-ETX-2i-64ET1
#set s1 //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2iB/AT-ETX-2iB
#set d1 [pwd]

set sdl [list]
set s1 [pwd]/uutInits
foreach host [list at-etx2ib-2-w10 at-etx2ib-3-w10] {
  if {$host!=[info host]} {
    set dest //$host/c$/AT-ETX-2iB/uutInits
    lappend sdl $s1 $dest
  }
}
#set d1 //at-etx2ib-3-w10/c$/AT-ETX-2iB/uutInits
#set s2 //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-64ET1/download
#set d2 c://download
# set noCopyL [list  [pwd]/tmpFiles]
# set noCopyGlobL [list init* result*]
# set emailL [list ilya_g@rad.com]

# set ret [RLAutoUpdate::AutoUpdate [list $s1 $d1 $s2 $d2] -noCopyL $noCopyL -noCopyGlobL $noCopyGlobL -emailL $emailL]
#set ret [RLAutoUpdate::AutoUpdate [list $s1 $d1] -noCopyGlobL $noCopyGlobL -noCopyL $noCopyL -emailL $emailL]
if {$sdl!=""} {
  set ret [RLAutoUpdate::AutoUpdate $sdl]
}  
if {$ret=="-1"} {exit}
}

foreach fi [glob -nocomplain -type f *.txt] {
  if [regexp {\w{2}\d{9,}} $fi] {
    file delete -force $fi
  }
}
after 1000


  set gaSet(radNet) 0
if 0 {  
  foreach {jj ip} [regexp -all -inline {v4 Address[\.\s\:]+([\d\.]+)} [exec ipconfig]] {
    if {[string match {*192.115.243.*} $ip] || [string match {*172.18.9*} $ip]} {
      set gaSet(radNet) 1
    }  
  }
  if {$gaSet(radNet)} {
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautosync.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl c:/tcl/lib/rl
      after 2000
    }
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautoupdate.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl c:/tcl/lib/rl
      after 2000
    }
    update
  }
  
  package require RLAutoSync
  
  #set s1 [file normalize //prod-svm1/tds/Temp/ilya/shared/ETX-2i/AT-ETX-2i/AT-ETX-2i_v1]
  set s1 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2iB/AT-ETX-2iB]
  set d1 [file normalize  C:/AT-ETX-2iB]
  set s2 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2iB/download]
  set d2 [file normalize  C:/download]
  
  if {$gaSet(radNet)} {
    set emailL {{ronen_be@rad.com} {} {} }
    #set emailL {{ilya_g@rad.com} {} {} }
  } else {
    set emailL [list]
  }
  
  set ret [RLAutoSync::AutoSync "$s1 $d1 $s2 $d2" -noCheckFiles {init*.tcl} -noCheckDirs {skipped temp tmpFiles OLD old} \
      -javaLocation $gaSet(javaLocation) -emailL $emailL -putsCmd 1 -radNet $gaSet(radNet)]
  #console show
  puts "ret:<$ret>"
  set gsm $gMessage
  foreach gmess $gMessage {
    puts "$gmess"
  }
  update
  if {$ret=="-1"} {
    set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
    -message "The AutoSync process did not perform successfully.\n\n\
    Do you want to continue? "]
    if {$res=="no"} {
      exit
    }
  }
}

package require BWidget
package require img::ico
package require RLSerial
package require RLEH
package require RLTime
package require RLStatus
package require RLEtxGen
package require RLUsbMmux
package require RLUsbPio
package require RLSound
RLSound::Open ; # [list failbeep fail.wav passbeep pass.wav beep warning.wav]
#package require RLScotty ; #RLTcp  13/12/2016 08:29:24 we use tshark
package require ezsmtp
package require http
package require RLAutoUpdate
package require sqlite3

package require registry
set gaSet(hostDescription) [registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters" srvcomment ]

source Gui_Etx2iB.tcl
source Main_Etx2iB.tcl
source Lib_Put_Etx2iB.tcl
source Lib_Gen_Etx2iB.tcl
source [info host]/init$gaSet(pair).tcl
source lib_bc.tcl
source Lib_DialogBox.tcl
source Lib_FindConsole.tcl
source LibEmail.tcl
source LibIPRelay.tcl
source Lib_Etx204.tcl
source Lib_Ds280e01_Etx2iB.tcl
source lib_DeleteOldApp.tcl
source lib_SQlite.tcl
DeleteOldApp
DeleteOldUserDef

#console show 

if {[info host]=="ate-dbg01-w10"} {
  set gaSet(DutInitName) "ETX-2I-B_RJIO.H.WR.2SFP.8SFP.tcl"
}

if [file exists uutInits/$gaSet(DutInitName)] {
  source uutInits/$gaSet(DutInitName)
} else {
  source [lindex [glob uutInits/ETX*.tcl] 0]
}


set gaSet(maxMultiQty) 27
set gaSet(act) 1
set gaSet(initUut) 1
set gaSet(oneTest)    0
set gaSet(puts) 1
set gaSet(noSet) 0


set gaSet(toTestClr)    #aad5ff
set gaSet(toNotTestClr) SystemButtonFace
set gaSet(halfPassClr)  #ccffcc

set gaSet(useExistBarcode) 0
set gaSet(nextPair) begin
set gaSet(rerunTesterMulti) conf

if ![info exists gaSet(pioType)] {
  set gaSet(pioType) Usb
}  

set gaSet(ledsBefore) 1

if ![info exists gaSet(radTsts)] {
  set gaSet(radTsts) Full
}
set gaSet(performMacIdCheck) 0

#set gaSet(1.barcode1) CE100025622

GUI
BuildTests
update

ToolsMassConnect 1
after 50

wm deiconify .
wm geometry . $gaGui(xy)
update

Status "Ready"
set ret [SQliteOpen]