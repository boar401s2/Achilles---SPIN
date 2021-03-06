CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  CR = 13
  EOT = 58 'End Of Transmission

OBJ

  Serial: "FullDuplexSerialPlus"
  Comp: "FullDuplexSerialPlus"
  Btooth: "FullDuplexSerialPlus"
  Motors: "Motors"
  Settings: "Settings"

VAR

  long recv[100]
  
PUB Start | directory, rx, lastPacket, packNum, x

  Comp.start(Settings#COMPUTER_RX, Settings#COMPUTER_TX,0, 19200) 'erial with computer
  Serial.start(Settings#CMUCAM_RX, Settings#CMUCAM_TX, 0, 19200)  'Start serial with camera
  Comp.str(String("CamTerm v1.0", CR))
  Motors.start(3, 6, 9)

  '20 80 30 90 30 90
  'CC: -5

  Motors.setRawPWMDuty(Settings#LAMP_SIGNAL, 50)

  'serial.rxStr(@recv)
  'serial.rxStr(@recv)           'Wait for camera to send it's name... (CMUCam4 v1.02)

  Comp.str(string("Camera Ready!", CR))
  
  Comp.str(String("----------------------------",CR))

  'sendCommand(string("ST 25 139 41 153 33 147"))
  'sendCommand(string("NF 10"))
  'sendCommand(string("CB 20"))

  'Terminal
  
  repeat
    repeat'This makes the terminal only work for one command, but it dumps all the output of the camera
      rx := serial.rx
      comp.tx(rx)
      packNum++
      if lastPacket == 13 and rx==58
        packNum := 0
        quit
      if packNum > 1000
        serial.rxflush
        serial.tx(13)
        packNum := 0
        quit
      lastPacket := rx
    comp.tx(CR)
    comp.tx(CR)
    'comp.str(directory)                             w
    'comp.str(string("> "))
    'comp.rxStr(@recv)
    'comp.tx(CR)

    repeat
      rx := comp.rx
      serial.tx(rx)
      if rx==13
        quit
    
    'sendCommand(@recv)                                                                                 
PUB sendCommand(cmd)

  serial.str(cmd)
  serial.str(string(" '\r'", CR))    

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