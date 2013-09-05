CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
OBJ

  CMUCam:        "CMUCam"
  Motors:        "Motors"
  Settings:      "Settings"
  Line:          "Line"
  Serial:        "FullDuplexSerial"

VAR

  long stack[50]
  long location

  long lowestDistance, lastX

  byte speed

  byte inGreenTile, lastTurnDirection '1 is left, 2 is right

  long timeOfFlight

  byte leftSpeed, rightSpeed, xPos, yPos

PUB Main | data, time, x, y

  Motors.start(3, 6, 9)   
  CMUCam.start(Settings#CMUCAM_RX, Settings#CMUCAM_TX)
  CMUCam.changeBaud(57600)
  'CMUCam.setPollMode(0)  
  CMUCam.configureToBlack
  CMUCam.setTrackingWindow(20, 20, 140, 120)
  waitcnt(clkfreq/2+cnt)  
  CMUCam.setAutoGain(0)
  CMUCam.startTracking
  Motors.setRawPWMDuty(Settings#LAMP_SIGNAL, Settings#CMUCAM_LAMP_HIGH)

  'cognew(debugloop, @stack)

  toLineFollowing

PUB followLine | x, y, stepsize

  x := CMUCam.getMiddleOfMassX
  y := CMUCam.getMiddleOfMassY
  xPos := x
  yPos := y
  Line.calculateSpeeds(x, y)
  leftSpeed := Line.getLeftSpeed
  rightSpeed := Line.getRightSpeed
  Motors.setLeftSpeed(leftSpeed)
  Motors.setRightSpeed(rightSpeed)

  

PUB toLineFollowing | y, leftSaturation, rightSaturation

  repeat
    followLine

PUB debugloop

  Serial.start(31, 30, 0, 115200)
  repeat
    Serial.tx(16)
    Serial.dec(xPos)
    Serial.str(string(", "))
    Serial.dec(yPos)
    Serial.tx(13)
    Serial.dec(leftSpeed)
    Serial.tx(13)
    Serial.dec(rightSpeed)
    waitcnt(clkfreq/10+cnt)
    