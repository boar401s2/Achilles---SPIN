CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  CR = 13
  DEBUG_MODE = True

OBJ

  Serial: "FullDuplexSerialPlus"
  Strings: "Strings"
  Settings: "Settings"
  Profiler[1]: "Profiler"

VAR

  {{Enabled Parts}}

  byte primaryDebugEnabled, secondaryDebugEnabled, cmucamEnabled, cmucamDebugEnabled
  byte started

  {{Random global variables}}

  byte sampling
  byte subelement[4]
  byte element[12]
  byte subelementNumber
  byte elementNumber
  byte packetStartedFlag

  {{Loop Stack}}

  long stack[50]

  {{Debugging Parameters}}

  long baudrate, rxPin, txPin

  {{Profiler Times}}

  long loopTime, primaryTime, secondaryTime, cmucamTime
  long startupTime
  
  {{CMUCam Parameters}}

  byte pollModeActive

  byte trackingActive

  long cmucamAvgRed, cmucamAvgGreen, cmucamAvgBlue
  long cmucamStdDevRed, cmucamStdDevGreen, cmucamStdDevBlue

  long cmucamMiddleOfMassX, cmucamMiddleOfMassY
  long cmucamBBoxX1, cmucamBBoxY1, cmucamBBoxX2, cmucamBBoxY2                   'Per meaning percentage
                                                                                'So, percentage of pixels
  long cmucamPerPixTracked, cmucamBBoxPerPixTracked                             'tracked in all, or BBox

  long blackConfig[9]
  long greenConfig[9]

  {{Temp global variables}}

  byte temp1[128], temp2[128], temp3[256]
    
PUB start(rxPin_, txPin_) | rx

  Serial.start(rxPin_, txPin_, 0, 19200)
  repeat while not rx == 58
    rx := Serial.rx

  rxPin := rxPin_
  txPin := txPin_
  baudrate := 19200

  'sendCommand(String("AW 0"))
  'waitForResult

PUB startTracking

  cognew(trackingUpdateLoop, @stack)
  trackingActive := true

PUB stopTracking

  trackingActive := false
  waitForResult  

PUB configureToBlack

  setTrackingParameters(Settings#CMUCAM_BLACK_RED_BOTTOM, {
                                } Settings#CMUCAM_BLACK_RED_TOP, {
                                } Settings#CMUCAM_BLACK_GREEN_TOP, {
                                } Settings#CMUCAM_BLACK_GREEN_BOTTOM, {
                                } Settings#CMUCAM_BLACK_BLUE_TOP, {
                                } Settings#CMUCAM_BLACK_BLUE_BOTTOM)

  setBrightness(Settings#CMUCAM_BLACK_BRIGHTNESS)
  setContrast(Settings#CMUCAM_BLACK_CONTRAST)
  setNoiseFilter(Settings#CMUCAM_BLACK_NOISE_FILTER)                                                       

PUB configureToGreen

  {setTrackingParameters(Settings#CMUCAM_GREEN_RED_BOTTOM, {
                                } Settings#CMUCAM_GREEN_RED_TOP, {
                                } Settings#CMUCAM_GREEN_GREEN_TOP, {
                                } Settings#CMUCAM_GREEN_GREEN_BOTTOM, {
                                } Settings#CMUCAM_GREEN_BLUE_TOP, {
                                } Settings#CMUCAM_GREEN_BLUE_BOTTOM)

  setBrightness(Settings#CMUCAM_GREEN_BRIGHTNESS)
  setContrast(Settings#CMUCAM_GREEN_CONTRAST)
  setNoiseFilter(Settings#CMUCAM_GREEN_NOISE_FILTER)}
  
{{CMUCam Gets}}

PUB getMiddleOfMassX

  return cmucamMiddleOfMassX

PUB getMiddleOfMassY

  return cmucamMiddleOfMassY

PUB getBBoxX1
  
  return cmucamBBoxX1

PUB getBBoxY1
  
  return cmucamBBoxY1

PUB getBBoxX2
  
  return cmucamBBoxX2

PUB getBBoxY2
  
  return cmucamBBoxY2
  
PUB getPerPixTracked

  return cmucamPerPixTracked

PUB getBBoxPerPixTracked

  return cmucamBBoxPerPixTracked

PUB getAverageRed

  return cmucamAvgRed

PUB getAverageGreen
          
  return cmucamAvgGreen

PUB getAverageBlue

  return cmucamAvgBlue

PUB getStdDevRed

  return cmucamStdDevRed

PUB getStdDevGreen

  return cmucamStdDevGreen

PUB getStdDevBlue

  return cmucamStdDevBlue

PUB setPollMode(int) | buffer

  Strings.stringConcatenate(@temp3, string("PM "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(int, 1))
  sendCommand(@temp3)
  waitForResult
  pollModeActive := int

PUB setNoiseFilter(int) | buffer

  Strings.stringConcatenate(@temp3, string("NF "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(int, 3))
  sendCommand(@temp3)
  waitForResult

PUB changeBaud(int) | buffer, rx

  Strings.stringConcatenate(@temp3, string("BM "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(int, 7))
  sendCommand(@temp3)
  repeat until rx == 13
    rx := serial.rx
  Serial.stop
  Serial.start(rxPin, txPin, 0, int)
  Serial.tx(13)
  waitForResult
  
  
PUB setBrightness(int) | buffer

  Strings.stringConcatenate(@temp3, string("CB "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(int, 3))
  sendCommand(@temp3)
  waitForResult

PUB setContrast(int) | buffer

  Strings.stringConcatenate(@temp3, string("CC "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(int, 3))
  sendCommand(@temp3)
  waitForResult

PUB setAutoGain(int)

  Strings.stringConcatenate(@temp3, string("AG "))
  Strings.stringConcatenate(@temp3, strings.integerToDecimal(int, 1))
  sendCommand(@temp3)
  waitForResult

PUB setAutoWhiteBalance(int)

  Strings.stringConcatenate(@temp3, string("AW "))
  Strings.stringConcatenate(@temp3, strings.integerToDecimal(int, 1))
  sendCommand(@temp3)
  waitForResult  

PUB getLoopTime

  return loopTime

PUB setTrackingParameters(rB, rT, gB, gT, bB, bT) | buffer

  Strings.stringConcatenate(@temp3, string("ST "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(rB, 3))
  Strings.stringConcatenate(@temp3, string(" "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(rT, 3))
  Strings.stringConcatenate(@temp3, string(" "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(gB, 3))
  Strings.stringConcatenate(@temp3, string(" "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(gT, 3))
  Strings.stringConcatenate(@temp3, string(" "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(bB, 3))
  Strings.stringConcatenate(@temp3, string(" "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(bT, 3))
  sendCommand(@temp3)

PUB setTrackingWindow(x1, y1, x2, y2) | buffer

  Strings.stringConcatenate(@temp3, string("SW "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(x1, 3))
  Strings.stringConcatenate(@temp3, string(" "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(y1, 3))
  Strings.stringConcatenate(@temp3, string(" "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(x2, 3))
  Strings.stringConcatenate(@temp3, string(" "))
  Strings.stringConcatenate(@temp3, Strings.integerToDecimal(y2, 3)) 
  sendCommand(@temp3)

PUB trackingUpdateLoop

  sendCommand(string("TC"))
  repeat while trackingActive
    Profiler[0].StartTimer
    updateTrackingData
    loopTime := Profiler[0].StopTimer_
  Serial.tx(13)

PUB updateTrackingData | x, packet

  if pollModeActive
    sendCommand(string("TC"))
    
  repeat
    packet := Serial.rx

    if packetStartedFlag
      if packet == 13
        element[elementNumber] := Strings.decimalToInteger(@subelement)
        elementNumber++
        subelementNumber := 0      
        bytefill(@subelement, 0, 3)
        cmucamMiddleOfMassX := element[0]
        cmucamMiddleOfMassY := element[1]
        cmucamBBoxX1 := element[2]
        cmucamBBoxY1 := element[3]
        cmucamBBoxX2 := element[4]
        cmucamBBoxY2 := element[5]
        cmucamPerPixTracked := element[6]
        cmucamBBoxPerPixTracked := element[7]
        elementNumber := 0
        bytefill(@element, 0, 12)
        packetStartedFlag := false
        subelementNumber := 0
        elementNumber := 0
        quit 
      elseif packet == 32 and subelementNumber => 1
        element[elementNumber] := Strings.decimalToInteger(@subelement)
        elementNumber++
        subelementNumber := 0      
        bytefill(@subelement, 0, 3) 
      elseif packet => 48 and packet =< 57
        subelement[subelementNumber] := packet 
        subelementNumber++
    else
      if packet == 84
        packetStartedFlag := true

  if pollModeActive
    waitForResult        

PUB updateColorData | x, packet

  sendCommand(string("GM"))
  repeat
    packet := Serial.rx
    if packetStartedFlag
      if packet == 13
        cmucamAvgRed := element[0]
        cmucamAvgGreen := element[1]
        cmucamAvgBlue := element[2]
        cmucamStdDevRed := element[9]
        cmucamStdDevGreen := element[10]
        cmucamStdDevBlue := element[11]
        elementNumber := 0
        bytefill(@element, 0, 12)
        packetStartedFlag := false
        subelementNumber := 0
        quit
      elseif packet == 32 and subelementNumber => 1
        element[elementNumber] := Strings.decimalToInteger(@subelement)
        elementNumber++
        subelementNumber := 0      
        bytefill(@subelement, 0, 3)  
      elseif packet => 48 and packet =< 57
        subelement[subelementNumber] := packet 
        subelementNumber++
    else
      if packet == 83
        packetStartedFlag := true
  waitForResult       
    
PUB Stop

  sendCommand(string("RS"))
  waitForResult
  Serial.stop

PUB ledOn

  sendCommand(String("L0", 13))
  waitForResult

PUB ledOff

  sendCommand(String("L1", 13))
  waitForResult

PUB monitorOn

  sendCommand(String("M0", 13))
  waitForResult

PUB monitorOff

  sendCommand(String("M1", 13))
  waitForResult  

PUB getVersion

  sendCommand(String("GV", 13))
  waitForResult

PUB resetSystem

  sendCommand(String("RS", 13))
  waitForResult

PUB sleepDeeply

  sendCommand(String("SD", 13))
  waitForResult
                                
PUB sleepLightly

  sendCommand(String("SL", 13))
  waitForResult

PUB sendCommand(Command)

  Serial.Str(Command)
  Serial.tx(13)
  clearTemp3

pub waitForResult | rx

  repeat until rx == 58
    rx := serial.rx

PUB clearTempVariables | x

  repeat x from 0 to 127
    temp1[x] := 0
    temp2[x] := 0
    temp3[x] := 0

PUB clearTemp1 | x

  repeat x from 0 to 127
    temp1[x] := 0

PUB clearTemp2 | x

  repeat x from 0 to 127
    temp2[x] := 0

PUB clearTemp3 | x

  repeat x from 0 to 127
    temp3[x] := 0        
    

DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  