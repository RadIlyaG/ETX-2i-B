#***************************************************************************
#** GUI
#***************************************************************************
proc GUI {} {
  global gaSet gaGui glTests  
  
  wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  set gaSet(eraseTitleGui) $gaSet(eraseTitle)
  if {$gaSet(eraseTitle)==1} {
    wm title . "$gaSet(pair) : "
  }
  
  wm protocol . WM_DELETE_WINDOW {Quit}
  wm geometry . $gaGui(xy)
  wm resizable . 0 0
  set descmenu {
    "&File" all file 0 {	 
      {command "Log File"  {} {} {} -command ShowLog}
	    {separator}     
      {cascad "&Console" {} console 0 {
        {checkbutton "console show" {} "Console Show" {} -command "console show" -variable gConsole}  
        {command "Capture Console" cc "Capture Console" {} -command CaptureConsole}
        {command "Find Console" console "Find Console" {} -command {GuiFindConsole}}          
      }
      }
      {separator}
      {command "E&xit" exit "Exit" {Alt x} -command {Quit}}
    }
    "&Tests" tools tools 0 {
      {command "Select 1-7" cc "Select 1-7" {} -command {SelectToTest 1-7}}
      {command "Select 15-21" cc "Select 15-21" {} -command {SelectToTest 15-21}}
      {command "Select 1-7 15-21" cc "Select 1-7 15-21" {} -command {SelectToTest 1-7_15-21}}        
      {separator}
      {radiobutton "Perform LEDs Test before running" {} "" {} -command {} -variable gaSet(ledsBefore) -value 1}  
      {radiobutton "Skip LEDs Test before running" {} "" {} -command {} -variable gaSet(ledsBefore) -value 0}  
      {separator}
      {radiobutton "One test ON"  init {} {} -value 1 -variable gaSet(oneTest)}
      {radiobutton "One test OFF" init {} {} -value 0 -variable gaSet(oneTest)}
      {separator}   
      {radiobutton "Perform previous MAC-IDnumber check" init {} {} -value 1 -variable gaSet(performMacIdCheck)}
      {radiobutton "Skip previous MAC-IDnumber check" init {} {} -value 0 -variable gaSet(performMacIdCheck)}
      {separator}
      {radiobutton "Next pair will be checked from begin" init {} {} -command {} -variable gaSet(nextPair) -value begin}
      {radiobutton "Next pair will be checked from the same test" init {} {} -command {} -variable gaSet(nextPair) -value same}
      {separator}    
      {radiobutton "Rerun in Tester Multi: within configuration" init {} {} -command {} -variable gaSet(rerunTesterMulti) -value conf}
      {radiobutton "Rerun in Tester Multi: without configuration" init {} {} -command {} -variable gaSet(rerunTesterMulti) -value sync}
      {separator}    
      {radiobutton "Scan barcode each UUT" {} "" {} -command {ToogleEraseTitle 1} -variable gaSet(eraseTitleGui) -value 1}  
      {radiobutton "Scan barcode each batch" {} "" {} -command {ToogleEraseTitle 0} -variable gaSet(eraseTitleGui) -value 0}  
   
      
    }
    "&Tools" tools tools 0 {	  
      {command "Inventory" init {} {} -command {GuiInventory}}
      {command "Load Init File" init {} {} -command {GetInitFile}}
      {separator}  
      {cascad "Power" {} pwr 0 {
        {command "PS-1 & PS-2 ON" {} "" {} -command {GuiPower $gaSet(pair) 1}} 
        {command "PS-1 & PS-2 OFF" {} "" {} -command {GuiPower $gaSet(pair) 0}}  
        {command "PS-1 ON" {} "" {} -command {GuiPower $gaSet(pair).1 1}} 
        {command "PS-1 OFF" {} "" {} -command {GuiPower $gaSet(pair).1 0}} 
        {command "PS-2 ON" {} "" {} -command {GuiPower $gaSet(pair).2 1}} 
        {command "PS-2 OFF" {} "" {} -command {GuiPower $gaSet(pair).2 0}} 
        {command "PS-1 & PS-2 OFF and ON" {} "" {} \
            -command {
              GuiPower $gaSet(pair) 0
              after 1000
              GuiPower $gaSet(pair) 1
            }  
        }             
      }
      }                
      {separator}    
      {radiobutton "Don't use exist Barcodes" init {} {} -command {} -variable gaSet(useExistBarcode) -value 0}
      {radiobutton "Use exist Barcodes" init {} {} -command {} -variable gaSet(useExistBarcode) -value 1}      
      {separator}
      {radiobutton "PIO PCI" init {} {} -command {} -variable gaSet(pioType) -value Ex}
      {radiobutton "PIO USB" init {} {} -command {} -variable gaSet(pioType) -value Usb}
      {separator}   
      {cascad "Pairs switch" {} fs 0 {
          {command "Pair 1"  {} "Pair 1"  {} -command {ToolsMassConnect 1}}
          {command "Pair 2"  {} "Pair 2"  {} -command {ToolsMassConnect 2}}
          {command "Pair 3"  {} "Pair 3"  {} -command {ToolsMassConnect 3}}
          {command "Pair 4"  {} "Pair 4"  {} -command {ToolsMassConnect 4}}
          {command "Pair 5"  {} "Pair 5"  {} -command {ToolsMassConnect 5}}
          {command "Pair 6"  {} "Pair 6"  {} -command {ToolsMassConnect 6}}
          {command "Pair 7"  {} "Pair 7"  {} -command {ToolsMassConnect 7}}
          {command "Pair 8"  {} "Pair 8"  {} -command {ToolsMassConnect 8}}
          {command "Pair 9"  {} "Pair 9"  {} -command {ToolsMassConnect 9}}
          {command "Pair 10" {} "Pair 10" {} -command {ToolsMassConnect 10}}
          {command "Pair 11" {} "Pair 11" {} -command {ToolsMassConnect 11}}
          {command "Pair 12" {} "Pair 12" {} -command {ToolsMassConnect 12}}
          {command "Pair 13" {} "Pair 13" {} -command {ToolsMassConnect 13}}
          {command "Pair 14" {} "Pair 14" {} -command {ToolsMassConnect 14}}
          {command "Pair 15" {} "Pair 15" {} -command {ToolsMassConnect 15}}
          {command "Pair 16" {} "Pair 16" {} -command {ToolsMassConnect 16}}
          {command "Pair 17" {} "Pair 17" {} -command {ToolsMassConnect 17}}
          {command "Pair 18" {} "Pair 18" {} -command {ToolsMassConnect 18}}
          {command "Pair 19" {} "Pair 19" {} -command {ToolsMassConnect 19}}
          {command "Pair 20" {} "Pair 20" {} -command {ToolsMassConnect 20}}
          {command "Pair 21" {} "Pair 21" {} -command {ToolsMassConnect 21}}      
          {command "Pair 22" {} "Pair 22" {} -command {ToolsMassConnect 22}}      
          {command "Pair 23" {} "Pair 23" {} -command {ToolsMassConnect 23}}      
          {command "Pair 24" {} "Pair 24" {} -command {ToolsMassConnect 24}}      
          {command "Pair 25" {} "Pair 25" {} -command {ToolsMassConnect 25}}      
          {command "Pair 26" {} "Pair 26" {} -command {ToolsMassConnect 26}}      
          {command "Pair 27" {} "Pair 27" {} -command {ToolsMassConnect 27}}                                 
      }
      } 
      {separator}      
      {command "Init ETX204" {} "" {} -command {ToolsEtxGen}} 
      {separator} 
      {cascad "Email" {} fs 0 {
        {command "E-mail Setting" gaGui(ToolAdd) {} {} -command {GuiEmail .mail}} 
  		  {command "E-mail Test" gaGui(ToolAdd) {} {} -command {TestEmail}}       
      }
      }  
             
    }
    
    "&About" all about 0 {
      {command "&About" about "" {} -command {About} 
      }
    }
  }
  if 0 {
    "&Short Tests" all shortTests 0 {
      {radiobutton "Perform Short Test" {} {} {} -command {UpdStatBarShortTest; BuildTests} -variable gaSet(performShortTest) -value 1}
      {radiobutton "Perform Full Test" {} {} {} -command {UpdStatBarShortTest; BuildTests} -variable gaSet(performShortTest) -value 0}       
    }
    {separator}    
      {radiobutton "Read Mac in UploadAppl" {} {} {} -command {} -variable gaSet(readMacUploadAppl) -value 1}
      {radiobutton "Don't read Mac in UploadAppl" {} {} {} -command {} -variable gaSet(readMacUploadAppl) -value 0}
  }
   #{command "SW init" init {} {} -command {GuiSwInit}}	
#    {radiobutton "Stop on Failure" {} "" {} -value 1 -variable gaSet(stopFail)}
#       {separator}

  set mainframe [MainFrame .mainframe -menu $descmenu]
  
  set gaSet(sstatus) [$mainframe addindicator]  
  $gaSet(sstatus) configure -width 54 
  
  set gaSet(statBarShortTest) [$mainframe addindicator]
  
  
  set gaSet(startTime) [$mainframe addindicator]
  
  set gaSet(runTime) [$mainframe addindicator]
  $gaSet(runTime) configure -width 5
  
  set tb0 [$mainframe addtoolbar]
  pack $tb0 -fill x
  set labstartFrom [Label $tb0.labSoft -text "Start From   "]
  set gaGui(startFrom) [ComboBox $tb0.cbstartFrom  -height 18 -width 35 -textvariable gaSet(startFrom) -justify center  -editable 0]
  $gaGui(startFrom) bind <Button-1> {SaveInit}
  pack $labstartFrom $gaGui(startFrom) -padx 2 -side left
  set sepIntf [Separator $tb0.sepIntf -orient vertical]
  pack $sepIntf -side left -padx 6 -pady 2 -fill y -expand 0
	 
  set bb [ButtonBox $tb0.bbox0 -spacing 1 -padx 5 -pady 5]
    set gaGui(tbrun) [$bb add -image [Bitmap::get images/run1] \
        -takefocus 0 -command ButRun \
        -bd 1 -padx 5 -pady 5 -helptext "Run the Tester"]		 		 
    set gaGui(tbstop) [$bb add -image [Bitmap::get images/stop1] \
        -takefocus 0 -command ButStop \
        -bd 1 -padx 5 -pady 5 -helptext "Stop the Tester"]
    set gaGui(tbpaus) [$bb add -image [Bitmap::get images/pause] \
        -takefocus 0 -command ButPause \
        -bd 1 -padx 5 -pady 1 -helptext "Pause/Continue the Tester"]	    
  pack $bb -side left  -anchor w -padx 7 ;#-pady 3
  set bb [ButtonBox $tb0.bbox1 -spacing 1 -padx 5 -pady 5]
    set gaGui(noSet) [$bb add -image [Bitmap::get images/Set] \
        -takefocus 0 -command {PerfSet swap} \
        -bd 1 -padx 5 -pady 5 -helptext "Run with the UUTs Setup"]    
  pack $bb -side left  -anchor w -padx 7
  set bb [ButtonBox $tb0.bbox12 -spacing 1 -padx 5 -pady 5]
    set gaGui(email) [$bb add -image [image create photo -file  images/email16.ico] \
        -takefocus 0 -command {GuiEmail .mail} \
        -bd 1 -padx 5 -pady 5 -helptext "Email Setup"] 
    set gaGui(ramzor) [$bb add -image [image create photo -file  images/TRFFC09_1.ico] \
        -takefocus 0 -command {GuiIPRelay} \
        -bd 1 -padx 5 -pady 5 -helptext "IP-Relay Setup"]        
  pack $bb -side left  -anchor w -padx 7
  
  set sepIntf [Separator $tb0.sepFL -orient vertical]
  #pack $sepIntf -side left -padx 6 -pady 2 -fill y -expand 0 
  
  set bb [ButtonBox $tb0.bbox2]
    set gaGui(butShowLog) [$bb add -image [image create photo -file images/find1.1.ico] \
        -takefocus 0 -command {ShowLog} -bd 1 -helptext "View Log file"]     
  pack $bb -side left  -anchor w -padx 7
  
#   set lab1 [Label $tb0.lab1 -text "UUT Com:$gaSet(comDut)"]
#   set lab2 [Label $tb0.lab2 -text "GEN Com:$gaSet(comGen1)"]
#   pack $lab1 $lab2 -padx 2 -side left
    
    set frCommon [frame $mainframe.frCommon  -bd 2 -relief groove]
      set gaGui(enDownloadsBefore) [checkbutton $frCommon.chb1 -text "Perform Downloads" \
          -variable gaSet(enDownloadsBefore) -command {BuildTests}]
      grid $gaGui(enDownloadsBefore)
      set frTsts [frame $frCommon.frTsts -bd 2  -relief groove]
        set gaGui(radAllTsts) [radiobutton $frTsts.chb1 -text "Perform all tests" \
          -variable gaSet(radTsts) -value Full  -command {BuildTests}]  
        set gaGui(radSkipDG) [radiobutton $frTsts.chb2 -text "Skip DG" \
          -variable gaSet(radTsts) -value SkipDG  -command {BuildTests}] 
        set gaGui(radOnlyDG) [radiobutton $frTsts.chb3 -text "DG only" \
          -variable gaSet(radTsts) -value OnlyDG  -command {BuildTests}]  
        grid $gaGui(radAllTsts) -sticky w
        grid $gaGui(radSkipDG) -sticky w
        grid $gaGui(radOnlyDG) -sticky w
      grid $frTsts
    pack $frCommon -fill both -expand 1 -padx 2 -pady 0 -side left 
	 
    set frDUT [frame $mainframe.frDUT -bd 2 -relief groove] 
      set labDUT [Label $frDUT.labDUT -text "UUT's barcode" -width 15]
      set gaGui(entDUT) [Entry $frDUT.entDUT -bd 1 -justify center -width 50\
            -editable 1 -relief groove -textvariable gaSet(entDUT) -command {GetDbrName}\
            -helptext "Scan a barcode here"]
      set gaGui(clrDut) [Button $frDUT.clrDut -image [image create photo -file  images/clear1.ico] \
            -takefocus 1 \
            -command {
                global gaSet gaGui
                set gaSet(entDUT) ""
                focus -force $gaGui(entDUT)
            }]         
      pack $labDUT $gaGui(entDUT) $gaGui(clrDut) -side left -padx 2 
#     set frTestPerf [TitleFrame $mainframe.frTestPerf -bd 2 -relief groove \
#         -text "Test Performance"] 
#       set f [$frTestPerf getframe]      17/09/2014 16:26:46
    set frTestPerf [frame $mainframe.frTestPerf -bd 2 -relief groove]     
      set f $frTestPerf
      set frCur [frame $f.frCur]  
        set labCur [Label $frCur.labCur -text "Current Test  " -width 13]
        set gaGui(curTest) [Entry $frCur.curTest -bd 1 \
            -editable 0 -relief groove -textvariable gaSet(curTest) \
	       -justify center -width 50]
        pack $labCur $gaGui(curTest) -padx 7 -pady 1 -side left -fill x;# -expand 1 
      pack $frCur  -anchor w
      #set frStatus [frame $f.frStatus]
      #  set labStatus [Label $frStatus.labStatus -text "Status  " -width 12]
      #  set gaGui(labStatus) [Entry $frStatus.entStatus \
            -bd 1 -editable 0 -relief groove \
	   -textvariable gaSet(status) -justify center -width 58]
      #  pack $labStatus $gaGui(labStatus) -fill x -padx 7 -pady 3 -side left;# -expand 1 	 
      #pack $frStatus -anchor w
      set frFail [frame $f.frFail]
      set gaGui(frFailStatus) $frFail
        set labFail [Label $frFail.labFail -text "Fail Reason  " -width 12]
        set labFailStatus [Entry $frFail.labFailStatus \
            -bd 1 -editable 1 -relief groove \
            -textvariable gaSet(fail) -justify center -width 75]
      pack $labFail $labFailStatus -fill x -padx 7 -pady 3 -side left; # -expand 1	
      #pack $gaGui(frFailStatus) -anchor w
      
      set frPairPerf [frame $frTestPerf.frPairPerf -bd 0 -relief groove]
      set gaGui(labPairPerf0) [Button $frPairPerf.labPairPerf0 -text "None" -bd 1 -relief raised -command [list TogglePairButAll 0]]
      if {$gaSet(pair)=="5"} {
        pack $gaGui(labPairPerf0) -side left -padx 1 -fill x -expand 1
      }
      for {set i 1} {$i <= $gaSet(maxMultiQty)} {incr i} {}
      for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
        set gaGui(labPairPerf$i) [Button $frPairPerf.labPairPerf$i -text $i -bd 1 -relief raised -command [list TogglePairBut $i]]
        #set gaGui(labPairPerf$i) [Label $frPairPerf.labPairPerf$i -text $i -bd 1 -relief raised]
        #bind  . <Alt-$i> [list TogglePairBut $i]
        if {$gaSet(pair)=="5"} {
          pack $gaGui(labPairPerf$i) -side left -padx 1 -fill x -expand 1
        } else {
          if {$i=="1"} {
            #pack $gaGui(labPairPerf$i) -side left -padx 1 -fill x -expand 1
          }
        }
      }
      set gaGui(labPairPerfAll) [Button $frPairPerf.labPairPerfAll -text ALL -bd 1 -relief raised -command [list TogglePairButAll All]]
      if {$gaSet(pair)=="5"} {
        pack $gaGui(labPairPerfAll) -side left -padx 1 -fill x -expand 1
      } else {
        TogglePairBut 1
      }
      pack $frPairPerf -fill x -padx 2 -pady 1 -expand 1
  
    pack $frDUT $frTestPerf -fill both -expand yes -padx 2 -pady 2 -anchor nw	 
  pack $mainframe -fill both -expand yes

  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled  

  console eval {.console config -height 14 -width 92}
  console eval {set ::tk::console::maxLines 10000}
  console eval {.console config -font {Verdana 10}}
  focus -force .
  bind . <F1> {console show}
  bind . <Alt-i> {GuiInventory}
  bind . <Alt-r> {ButRun}
  bind . <Alt-s> {ButStop}
  bind . <Control-b> {set gaSet(useExistBarcode) 1}
  bind . <Control-p> {ToolsPower on}
  bind . <Control-i> {GuiInventory}

#   RLStatus::Show -msg atp
#   RLStatus::Show -msg fti
   set gaSet(entDUT) ""
  focus -force $gaGui(entDUT)
  
}
proc About {} {
  DialogBox -title "About the Tester" -icon info -type ok\
          -message "The software upgrated at 07.03.2016"
}
#***************************************************************************
#** ButRun
#***************************************************************************
proc ButRun {} {
  global gaSet gaGui glTests gRelayState
  
  pack forget $gaGui(frFailStatus)
  Status ""
  
  set gaSet(act) 1
  console eval {.console delete 1.0 end}
  console eval {set ::tk::console::maxLines 100000}
#   if {$gaSet(pair)!="1"} {
#     $gaGui(labPairPerf1) configure -bg $gaSet(toTestClr)
#   }
  set ret 0
  puts "[wm title .]"
  if {[wm title .]=="$gaSet(pair) : "} {
    set ret -1
    set gaSet(fail) "Please scan the UUT's barcode"
  }

  if ![file exists c:/logs] {
    file mkdir c:/logs
  }
  if {[catch {glob *logFile.txt} lTxt]==0} {
    ## if there is no logFile, the [glob] rises error. therefor i use catch]
    foreach fil [glob *logFile.txt] {
      file copy -force $fil c:/logs/$fil
    } 
    foreach fil [glob *logFile.txt] {
      file delete -force $fil
    }
  }
  
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile.$gaSet(pair)) c:/logs/$ti.$gaSet(pair).logFile.txt
  
  if {![file exists uutInits/$gaSet(DutInitName)]} {
    set txt "Init file for \'$gaSet(DutFullName)\' is absent"
    Status  $txt
    set gaSet(fail) $txt
    set gaSet(curTest) $gaSet(startFrom)
    set ret -1
    AddToLog $gaSet(fail)
  }
  
  if {[llength [PairsToTest]]==0} {
    #RLSound::Play beep
    RLSound::Play fail
    set txt "You should choose at least one UUT for testing."
    set res [DialogBox -icon images/info -type "OK" -text $txt -aspect 2000 -title ASMi53]
    set ret -1
    set gaSet(fail) "$txt"
    Status "$txt"
    AddToLog $gaSet(fail)
 } else {
   foreach lab [PairsToTest] {
      PairPerfLab $lab $gaSet(toTestClr)
   }
 }
  
  if {$gaSet(performShortTest)=="1"} {
    #RLSound::Play beep
    RLSound::Play fail
    set txt "Be aware!\r\rYou are about to perform the short test.\r\r\
    If you are not sure, click the GUI's \'Short Tests\'->\'Perform Full Test\'"
    set res [DialogBox -icon images/info -type "Continue Abort" -text $txt -default 1 -aspect 2000 -title ASMi53]
    if {$res=="Abort"} {
      set ret -1
      set gaSet(fail) "Short test abort"
      Status "Short test abort"
      AddToLog $gaSet(fail)
    } else {
      set ret 0
    }
  }
  foreach v {sw} {
    if {$gaSet($v)=="??"} {
      puts "ButRun v:$v gaSet($v):$gaSet($v)"
      set txt "Init file for \'$gaSet(DutFullName)\' is wrong"
      Status  $txt
      set gaSet(fail) $txt
      set gaSet(curTest) $gaSet(startFrom)
      set ret -1
      AddToLog $gaSet(fail)
      break
    }
  }
  
#   puts "[MyTime] source Lib_Put_RicEth.tcl" ; update
#   source Lib_Put_RicEth.tcl
#   puts "[MyTime] source Lib_Put_RicEth_$gaSet(dutFam).tcl" ; update
#   source Lib_Put_RicEth_$gaSet(dutFam).tcl
#   
  if {$ret==0} {
    IPRelay-Green
    Status ""
    set gaSet(curTest) [$gaGui(startFrom) cget -text]
    console eval {.console delete 1.0 "end-1001 lines"}
    pack forget $gaGui(frFailStatus)
    $gaSet(startTime) configure -text " Start: [MyTime] "
    $gaGui(tbrun) configure -relief sunken -state disabled
    $gaGui(tbstop) configure -relief raised -state normal
    $gaGui(tbpaus) configure -relief raised -state normal
    set gaSet(fail) ""
    foreach wid {startFrom} {
      $gaGui($wid) configure -state disabled
    }
    
#     for {set pair 1} {$pair<=$gaSet(maxMultiQty)} {incr pair} {
#       #PairPerfLab $pair gray
#       foreach uut {1} {
#         catch {unset gaSet($pair.mac$uut)}
#         if {$gaSet(useExistBarcode)==0} {
#           catch {unset gaSet($pair.barcode$uut)}
#         }
#       }
#     }
    
    #.mainframe setmenustate tools disabled
    update
#     catch {exec taskkill.exe /im hypertrm.exe /f /t}
#     catch {exec taskkill.exe /im mb.exe /f /t}
    
    RLTime::Delay 1
        
    set ret 0
    GuiPower all 1 ; ## power ON before scan barcodes and OpenRL
    set gaSet(plEn) 0
    if {$ret==0} {
#       if {[string match {*SetToDefaultAll*} $gaSet(startFrom)]==0} {
#         set gRelayState red
#         IPRelay-LoopRed
#         set ret [ReadBarcode [PairsToTest]]
#         if {$ret=="-3"} {
#           ## SKIP is pressed, we can continue
#           set ret 0
#         }
#       } else {
#         set ret 0
#       }
      
      if {$ret==0} {
        IPRelay-Green
        set ret [OpenRL]
        if {$ret==0} {
          set ret [Testing]
        }
      }
    }
    puts "ret of Testing: $ret"  ; update
    foreach wid {startFrom } {
      $gaGui($wid) configure -state normal
    }
    .mainframe setmenustate tools normal
    puts "end of normal widgets"  ; update
    update
    set retC [CloseRL]
    puts "ret of CloseRL: $retC"  ; update
    
    set gaSet(oneTest) 0
    set gaSet(rerunTesterMulti) conf
    set gaSet(nextPair) begin
    set gaSet(readMacUploadAppl) 1
    
    set gRelayState red
    IPRelay-LoopRed
#     ## since I deleted the LedsEth test from the glTests, I should add it again by BuildTests
#     BuildTests
	  

  }
  
  if {$ret==0} {
    RLSound::Play pass
    Status "Done"  green
	  
	  set gaSet(curTest) ""
    set gaSet(startFrom) [lindex $glTests 0]
  } elseif {$ret==1} {
    RLSound::Play information
    Status "The test has been perform"  yellow
  } else {
    if {$ret=="-2"} {
	    set gaSet(fail) "User stop"
	  }
	  pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
	  RLSound::Play fail
	  Status "Test FAIL"  red
	         
    ##27/11/2015 14:32:38   
#     if {$gaSet(failAnd)=="stay"} {   
#       set gaSet(startFrom) $gaSet(curTest)
#     } elseif {$gaSet(failAnd)=="jump2Start"} {   
#       set gaSet(startFrom) [lindex $glTests 0]
#     }
    set gaSet(startFrom) $gaSet(curTest)
    update
  }
  SendEmail "ETX-2i" [$gaSet(sstatus) cget -text]
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled
  $gaGui(tbpaus) configure -relief sunken -state disabled
  
  if {$gaSet(eraseTitle)==1} {
    wm title . "$gaSet(pair) : "
  }
  set gaSet(ledsBefore) 1
  set gaSet(performMacIdCheck) 1
  update
}


#***************************************************************************
#** ButStop
#***************************************************************************
proc ButStop {} {
  global gaGui gaSet
  set gaSet(act) 0
  $gaGui(tbrun) configure -relief raised -state normal
  $gaGui(tbstop) configure -relief sunken -state disabled
  $gaGui(tbpaus) configure -relief sunken -state disabled
  foreach wid {startFrom } {
    $gaGui($wid) configure -state normal
  }
  .mainframe setmenustate tools normal
  CloseRL
  update
}
# ***************************************************************************
# ButPause
# ***************************************************************************
proc ButPause {} {
  global gaGui gaSet
  if { [$gaGui(tbpaus) cget -relief] == "raised" } {
    $gaGui(tbpaus) configure -relief "sunken"     
    #CloseRL
  } else {
    $gaGui(tbpaus) configure -relief "raised" 
    #OpenRL   
  }
        
  while { [$gaGui(tbpaus) cget -relief] != "raised" } {
    RLTime::Delay 1
  }  
}

#***************************************************************************
#** GuiSwInit
#***************************************************************************
proc GuiSwInit {} {  
  global gaSet tmpSw tmpCsl
  set tmpSw  $gaSet(soft)
  set base .topHwInit
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base +200+200
  wm resizable $base 1 1 
  wm title $base "SW init"
  pack [LabelEntry $base.entHW -label "UUT's SW:  " \
      -justify center -textvariable tmpSw] -pady 1 -padx 3  
  pack [Separator $base.sep1 -orient horizontal] -fill x -padx 2 -pady 3
  pack [frame $base.frBut ] -pady 4 -anchor e
    pack [Button $base.frBut.butCanc -text Cancel -command ButCanc -width 7] -side right -padx 6
    pack [Button $base.frBut.butOk -text Ok -command ButOk -width 7]  -side right -padx 6
  
  focus -force $base
  grab $base
  return {}  
}


#***************************************************************************
#** ButOk
#***************************************************************************
proc ButOk {} {
  global gaSet lp
  #set lp [PasswdDlg .topHwInit.passwd -parent .topHwInit]
  set login 1 ; #[lindex $lp 0]
  set pw    1 ; #[lindex $lp 1]
  if {$login!="1" || $pw!="1"} {
    #exec c:\\rlfiles\\Tools\\btl\\beep.exe &
    RLSound::Play information
    tk_messageBox -icon error -title "Access denied" -message "The Login or Password isn't correct" \
       -type ok
  } else {
    set sw  [.topHwInit.entHW cget -text]
    puts "$sw"
    set gaSet(soft) $sw
    SaveInit
  }
  ButCanc
}


#***************************************************************************
#** ButCanc -- 
#***************************************************************************
proc ButCanc {} {
  grab release .topHwInit
  focus .
  destroy .topHwInit
}


#***************************************************************************
#** GuiInventory
#***************************************************************************
proc GuiInventory {} {  
  global gaSet gaTmpSet gaGui
  
  if {![info exists gaSet(DutFullName)] || $gaSet(DutFullName)==""} {
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play fail    
    set txt "Define the UUT first"
    DialogBox -title "Wrong UUT" -message $txt -type OK -icon images/error
    focus -force $gaGui(entDUT)
    return -1
  }
  
  array unset gaTmpSet
  
  set parL [list sw dbrSW swPack]
  foreach par $parL {
    if ![info exists gaSet($par)] {set gaSet($par) ??}
    set gaTmpSet($par) $gaSet($par)
  }
  foreach indx {RJIO DGasp ExtClk RTR } { 
    if ![info exists gaSet([set indx]CF)] {set gaSet([set indx]CF) c:/aa}
    set gaTmpSet([set indx]CF)  $gaSet([set indx]CF)
  }

  
  set base .topHwInit
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1 
  wm title $base "Inventory of $gaSet(DutFullName)"
  
  set indx 0
  
  set fr [frame $base.frSwVer -bd 0 -relief groove]
    pack [Label $fr.labSW  -text "SW Ver" -width 15] -pady 1 -padx 2 -anchor w -side left
    pack [Entry $fr.cbSW -justify center -width 45 -state disabled -editable 0 -textvariable gaTmpSet(dbrSW)] -pady 1 -padx 2 -anchor w -side left
  pack $fr  -anchor w
  set fr [frame $base.frSwPack -bd 0 -relief groove]
    pack [Label $fr.labSW  -text "SW Pack" -width 15] -pady 1 -padx 2 -anchor w -side left
    pack [Entry $fr.cbSW -justify center -editable 1 -textvariable gaTmpSet(swPack)] -pady 1 -padx 2 -anchor w -side left
  pack $fr  -anchor w
    
  pack [Separator $base.sep[incr inx] -orient horizontal] -fill x -padx 2 -pady 3
  
  set txtWidth 30
  
     
  foreach indx {RJIO DGasp ExtClk RTR} {
    if {$indx==$gaSet(dutBox) || $indx=="DGasp" || $indx=="ExtClk" || $indx=="RTR"} {
      set fr [frame $base.fr$indx -bd 0 -relief groove]
        set txt "Browse to \'[set indx]\' Conf File..."
        set f [set indx]CF
        pack [Button $fr.brw -text $txt -width $txtWidth -command [list BrowseCF $txt $f]] -side left -pady 1 -padx 3 -anchor w
        pack [Label $fr.lab  -textvariable gaTmpSet($f)] -pady 1 -padx 3 -anchor w
      pack $fr  -fill x -pady 3
    }
  } 
  
  #pack [Separator $base.sep3 -orient horizontal] -fill x -padx 2 -pady 3
  
  pack [frame $base.frBut ] -pady 4 -anchor e
    pack [Button $base.frBut.butImp -text Import -command ButImportInventory -width 7] -side right -padx 6
    pack [Button $base.frBut.butCanc -text Cancel -command ButCancInventory -width 7] -side right -padx 6
    pack [Button $base.frBut.butOk -text Ok -command ButOkInventory -width 7]  -side right -padx 6
  
  focus -force $base
  grab $base
  return {}  
}
# ***************************************************************************
# BrowseCF
# ***************************************************************************
proc BrowseCF {txt f} {
  global gaTmpSet
  set gaTmpSet($f) [tk_getOpenFile -title $txt -initialdir "C:\\ConfFiles"]
  focus -force .topHwInit
}
# ***************************************************************************
# BrowseLic
# ***************************************************************************
proc BrowseLic {} {
  global gaTmpSet
  set gaTmpSet(licDir) [tk_chooseDirectory -title "Choose Licence file location" -initialdir "c:\\Download"]
  focus -force .topHwInit
}
# ***************************************************************************
# ButImportInventory
# ***************************************************************************
proc ButImportInventory {} {
  global gaSet gaTmpSet
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl ]
  if {$fil!=""} {  
    set gaTmpSet(DutFullName) $gaSet(DutFullName)
    set gaTmpSet(DutInitName) $gaSet(DutInitName)
    set DutInitName $gaSet(DutInitName)
    
    source $fil
    set parL [list sw licDir]
    foreach par $parL {
      set gaTmpSet($par) $gaSet($par)
    }
    
    set gaSet(DutFullName) $gaTmpSet(DutFullName)
    set gaSet(DutInitName) $DutInitName ; #xcxc ; #gaTmpSet(DutInitName)    
  }    
  focus -force .topHwInit
}
#***************************************************************************
#** ButOk
#***************************************************************************
proc ButOkInventory {} {
  global gaSet gaTmpSet
  
#   set saveInitFile 0
#   foreach nam [array names gaTmpSet] {
#     if {$gaTmpSet($nam)!=$gaSet($nam)} {
#       puts "ButOkInventory1 $nam tmp:$gaTmpSet($nam) set:$gaSet($nam)"
#       #set gaSet($nam) $gaTmpSet($nam)      
#       set saveInitFile 1 
#       break
#     }  
#   }
  
  set saveInitFile 1  
  if {$saveInitFile=="1"} {
    set res Save
    if {[file exists uutInits/$gaSet(DutInitName)]} {
      set txt "Init file for \'$gaSet(DutFullName)\' exists.\n\nAre you sure you want overwright the file?"
      set res [DialogBox -title "Save init file" -message  $txt -icon images/question \
          -type [list Save "Save As" Cancel] -default 2]
      if {$res=="Cancel"} {array unset gaTmpSet ; return -1}
    }
    if ![file exists uutInits] {
      file mkdir uutInits
    }
    if {$res=="Save"} {
      #SaveUutInit uutInits/$gaSet(DutInitName)
      set fil "uutInits/$gaSet(DutInitName)"
    } elseif {$res=="Save As"} {
      set fil [tk_getSaveFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl ]
      if {$fil!=""} {        
        set fil1 [file tail [file rootname $fil]]
        puts fil1:$fil1
        set gaSet(DutInitName) $fil1.tcl
        set gaSet(DutFullName) $fil1
        #set gaSet(entDUT) $fil1
        wm title . "$gaSet(pair) : $gaSet(DutFullName)"
        #SaveUutInit $fil
        update
      }
    } 
    puts "ButOkInventory fil:<$fil>"
    if {$fil!=""} {
      foreach nam [array names gaTmpSet] {
        if {$gaTmpSet($nam)!=$gaSet($nam)} {
          puts "ButOkInventory2 $nam tmp:$gaTmpSet($nam) set:$gaSet($nam)"
          set gaSet($nam) $gaTmpSet($nam)      
        }  
      }
      #mparray gaTmpSet
      #mparray gaSet
      SaveUutInit $fil
    } 
  }
  #mparray gaSet dnf*
  array unset gaTmpSet
  SaveInit
  BuildTests
  ButCancInventory
}


#***************************************************************************
#** ButCancInventory
#***************************************************************************
proc ButCancInventory {} {
  grab release .topHwInit
  focus .
  destroy .topHwInit
}


#***************************************************************************
#** Quit
#***************************************************************************
proc Quit {} {
  global gaSet
  SaveInit
  RLSound::Play information
  set ret [DialogBox -title "Confirm exit"\
      -type "yes no" -icon images/question -aspect 2000\
      -text "Are you sure you want to close the application?"]
  if {$ret=="yes"} {CloseRL; IPRelay-Green; exit}
}

#***************************************************************************
#** CaptureConsole
#***************************************************************************
proc CaptureConsole {} {
  console eval { 
    set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
    if ![file exists c:\\temp] {
      file mkdir c:\\temp
    }
    set fi c:\\temp\\ConsoleCapt_[set ti].txt
    if [file exists $fi] {
      set res [tk_messageBox -title "Save Console Content" \
        -icon info -type yesno \
        -message "File $fi already exist.\n\
               Do you want overwrite it?"]      
      if {$res=="no"} {
         set types { {{Text Files} {.txt}} }
         set new [tk_getSaveFile -defaultextension txt \
                 -initialdir c:\\ -initialfile [file rootname $fi]  \
                 -filetypes $types]
         if {$new==""} {return {}}
      }
    }
    set aa [.console get 1.0 end]
    set id [open $fi w]
    puts $id $aa
    close $id
  }
}

# ***************************************************************************
# UpdStatBarShortTest
# ***************************************************************************
proc UpdStatBarShortTest {} {
  global gaSet
  
  if {$gaSet(performShortTest)==1} {
    set txt " SHORT TEST! " 
    set bg red
    set fg SystemButtonText  
  } else {
    set txt ""
    set bg SystemButtonFace
    set fg SystemButtonText
  }
  $gaSet(statBarShortTest) configure -text $txt -bg $bg -fg $fg
}

# ***************************************************************************
# ToogleEraseTitle
# ***************************************************************************
proc ToogleEraseTitle {changeTo} {
  global gaSet
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  if {$gaSet(eraseTitle)==1 && $changeTo==0} {
    set log ""
    set gaSet(eraseTitle) 0
    # while 1 {
      # set p [PasswdDlg .p -parent . -type okcancel]
      # if {[llength $p]==0} {
        # ## cancel button
        # return {}
      # } else {
        # foreach {log pass} $p {}
      # }
      # if {$log=="rad" && $pass=="123"} {set gaSet(eraseTitle) 0; break}
    # }
  }
  if {$changeTo==1} {
    set gaSet(eraseTitle) 1
    wm title . "$gaSet(pair) : "
  }  
}

#***************************************************************************
#** PairPerfLab
#***************************************************************************
proc PairPerfLab {lab bg} {
  global gaGui gaSet
  $gaGui(labPairPerf$lab) configure -bg $bg
}

# ***************************************************************************
# AllPairPerfLab
# ***************************************************************************
proc AllPairPerfLab {bg} {
  global gaSet
  for {set i 1} {$i <= $gaSet(maxMultiQty)} {incr i} {}
  for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
    PairPerfLab $i $bg
  }
}
# ***************************************************************************
# TogglePairBut
# ***************************************************************************
proc TogglePairBut {pair} {
  global gaGui gaSet
  set _toTestClr $gaSet(toTestClr)
  set _toNotTestClr $gaSet(toNotTestClr)
  set bg  [$gaGui(labPairPerf$pair) cget -bg]
  set _bg $bg
  #puts "pair:$pair bg1:$bg"
  if {$bg=="gray" || $bg==$_toNotTestClr} {
    ## initial state, for change to _toTest change it to blue
    set _bg $_toTestClr
  } elseif {$bg==$_toTestClr || $bg=="green" || $bg=="red" || \
      $bg==$gaSet(halfPassClr) || $bg=="yellow" || $bg=="#ddffdd"} {
    ## for under Test, pass or fail - for change to _toNoTest change it to gray
    set _bg $_toNotTestClr
    IPRelay-Green
  } 
  $gaGui(labPairPerf$pair) configure -bg $_bg
}
# ***************************************************************************
# TogglePairButAll
# ***************************************************************************
proc TogglePairButAll {mode} {
  global gaGui   gaSet
  set _toNotTestClr $gaSet(toNotTestClr)
  set _toTestClr $gaSet(toTestClr)
  if {$mode=="0"} {
    set _bg $_toNotTestClr
  } elseif {$mode=="All"} {
    set _bg $_toTestClr
  }
  for {set pair 1} {$pair <= $gaSet(maxMultiQty)} {incr pair} {}
  for {set pair 1} {$pair <= $gaSet(maxUnitsQty)} {incr pair} {
    $gaGui(labPairPerf$pair) configure -bg $_bg
  }
}
# ***************************************************************************
# PairsToTest
# ***************************************************************************
proc PairsToTest {} {
  global gaGui gaSet
  set _toTestClr $gaSet(toTestClr)
  set l [list]
  for {set i 1} {$i <= $gaSet(maxMultiQty)} {incr i} {}
  for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
    set bg  [$gaGui(labPairPerf$i) cget -bg]
    if {$bg==$_toTestClr  || $bg=="green" || $bg=="yellow" || $bg=="#ddffdd"} {
      lappend l $i
    }
  }
  return $l
}

# ***************************************************************************
# CheckPairsToTest
# ***************************************************************************
proc CheckPairsToTest {} {
  global gaGui gaSet
  set l [list]
  for {set i 1} {$i <= $gaSet(maxMultiQty)} {incr i} {}
  for {set i 1} {$i <= $gaSet(maxUnitsQty)} {incr i} {
    set bg  [$gaGui(labPairPerf$i) cget -bg]
    if {$bg!=$gaSet(toNotTestClr)} {
      lappend l $i
    }
  }
  return $l
}
# ***************************************************************************
# SelectToTest
# ***************************************************************************
proc SelectToTest {range} {
  global gaGui gaSet
  set labL [list]
  switch -exact -- $range {
    1-7 {
      set labL [list 1 2 3 4 5 6 7]
    }
    15-21 {
      set labL [list  15 16 17 18 19 20 21]
    }
    1-7_15-21 {
      set labL [list 1 2 3 4 5 6 7 15 16 17 18 19 20 21]
    }
  } 
  for {set lab 1} {$lab<=27} {incr lab} {
    PairPerfLab $lab $gaSet(toNotTestClr)
  }
  foreach lab $labL {
    PairPerfLab $lab $gaSet(toTestClr)
  } 
  update
}
