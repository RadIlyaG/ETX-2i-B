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
package require RLScotty ; #RLTcp
package require ezsmtp
package require http

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

#console show 

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
set gaSet(performMacIdCheck) 1

#set gaSet(1.barcode1) CE100025622

GUI
BuildTests
update

ToolsMassConnect 1
after 50

Status "Ready"