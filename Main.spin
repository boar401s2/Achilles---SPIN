CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  DEBUG_VIA_USB = FALSE
  DEBUG_ENABLED = TRUE
  
OBJ

  CMUCam:        "CMUCam"
  Sensors:       "Sensors"
  Motors:        "Motors"
  Settings:      "Settings"
  Line:          "Line"
  Serial:        "FullDuplexSerial"

VAR

  long stack[50]
  long location

  byte leftSpeed, rightSpeed
  byte leftSaturation, rightSaturation

  byte direction, cornersTurned
  byte speed
  long spare
  long spare2

PUB Main | data, time, x, y

  Motors.start(3, 6, 9)
  Sensors.start
  CMUCam.start(Settings#CMUCAM_RX, Settings#CMUCAM_TX)
  CMUCam.changeBaud(57600)
  'CMUCam.setPollMode(0)  
  CMUCam.configureToBlack
  CMUCam.setTrackingWindow(20, 20, 140, 120)
  Motors.clawFullyOpen
  waitcnt(clkfreq/2+cnt)
  Motors.clawOff  
  CMUCam.setAutoGain(0)
  CMUCam.setAutoWhiteBalance(0)
  CMUCam.startTracking
  Motors.setRawPWMDuty(Settings#LAMP_SIGNAL, Settings#CMUCAM_LAMP_MEDIUM)
  Line.init

  if DEBUG_ENABLED
    if (DEBUG_VIA_USB and ina[Settings#COMPUTER_RX] == 1) or DEBUG_VIA_USB==False 'Propeller Connected to USB
    cognew(debugloop, @stack)
  
  toLineFollowing  

PUB followLine | x, y, stepsize

  x := CMUCam.getMiddleOfMassX
  y := CMUCam.getMiddleOfMassY
  Line.calculateSpeeds(x, y)
  leftSpeed := Line.getLeftSpeed
  rightSpeed := Line.getRightSpeed
  Motors.setLeftDirection(0)
  Motors.setRightDirection(0)
  Motors.setLeftSpeed(leftSpeed)
  Motors.setRightSpeed(rightSpeed)

PUB shortcutDirection | x

  x := CMUCam.getMiddleOfMassX
  Motors.halt
  CMUCam.stopTracking
  CMUCam.setPollMode(1)
  CMUCam.setTrackingWindow(20, 40, 80, 120)
  CMUCam.updateTrackingData
  leftSaturation := CMUCam.getPerPixTracked
  CMUCam.setTrackingWindow(120, 20, 140, 120)
  CMUCam.updateTrackingData
  rightSaturation := CMUCam.getPerPixTracked
  CMUCam.setTrackingWindow(20, 20, 140, 120)
  CMUCam.setPollMode(0)
  CMUCam.startTracking
  if leftSaturation > rightSaturation
    return Settings#LEFT
  else
    return Settings#RIGHT

PUB scanForShortcutDirection | x

  leftSaturation := -1000
  rightSaturation := 0

  repeat until abs_(leftSaturation-rightSaturation) > 20
  x := CMUCam.getMiddleOfMassX
  Motors.halt
  'Motors.backward(25, 100) 
  Motors.spinLeft(25, 300)
  waitcnt(clkfreq*1+cnt)
  leftSaturation := CMUCam.getPerPixTracked    
  Motors.spinRight(25, 600)
  waitcnt(clkfreq*1+cnt)
  rightSaturation := CMUCam.getPerPixTracked  
  Motors.spinLeft(25, 300)
  'if abs_(leftSaturation-rightSaturation) < 100
  '  return Settings#NUTER
  if leftSaturation > rightSaturation
    return Settings#LEFT
  else
    return Settings#RIGHT

PUB canSeeTower

  if Sensors.getFrontUltrasonic < 9
    Motors.halt
    waitcnt(clkfreq/10+cnt)
    if Sensors.getFrontUltrasonic < 9
      toWaterTower

PUB toWaterTower

  location := String("Water Tower")
   

  speed := 25
  Motors.setSpinRight(speed)
  repeat until Sensors.getLeftIRSensor > Settings#TOWER_IR_ADJUST_THRESHOLD
  Motors.halt

  location := String("Water Tower Side")

  repeat until CMUCam.getPerPixTracked > 50
    repeat until CMUCam.getPerPixTracked > 50
      if Sensors.getLeftIRSensor < 300
        waitcnt(clkfreq/50+cnt)
        if Sensors.getLeftIRSensor < 300
          quit
      Motors.Forward(speed, 30)
    repeat until CMUCam.getPerPixTracked > 50
      if Sensors.getLeftIRSensor > 500
        waitcnt(clkfreq/50+cnt)
        if Sensors.getLeftIRSensor > 500
          quit
      Motors.SpinLeft(speed, 30)

  location := String("Finding Line")
      
  repeat 40
    if CMUCam.getMiddleOfMassX > 70 and CMUCam.getMiddleOfMassX < 90
      Motors.SpinRight(speed, 10)
    elseif CMUCam.getPerPixTracked < 20
      Motors.SpinRight(Speed, 10)
    else
      Motors.Forward(speed, 10)

  toLineFollowing

PUB toLineFollowing | y

  location := String("Line Following")

  repeat
  
    canSeeTower
  
    if CMUCam.getPerPixTracked > 160
      Motors.halt
      waitcnt(clkfreq/5+cnt)
      if CMUCam.getPerPixTracked > 160 
        spare2 := CMUCam.getPerPixTracked
        direction := scanForShortcutDirection

        {if direction == Settings#RIGHT and (cornersTurned // 2) == 0
          Motors.setForward(20)
          repeat until CMUCam.getPerPixTracked < 120
          repeat                       
            if CMUCam.getPerPixTracked > 150
              location := String("Gridlock")
              Motors.setBackward(20)  
              repeat until CMUCam.getPerPixTracked < 120
              repeat until CMUCam.getPerPixTracked > 200
              Motors.backward(25, 200)
              Motors.spinRight(25, 300)
              repeat until CMUCam.getMiddleOfMassX > 70 and CMUCam.getMiddleOfMassX < 90 and CMUCam.getPerPixTracked > 50
              Motors.halt
              Motors.forward(25, 500)          
              quit
            elseif CMUCam.getPerPixTracked < 20
              location := String("Corner")
              Motors.setBackward(25)
              repeat until CMUCam.getPerPixTracked > 160
              repeat until CMUCam.getPerPixTracked < 120
              Motors.halt
              quit }
        
        if direction == Settings#LEFT
          location := String("Left Corner")

          'repeat

          Motors.backward(25, 150)
          Motors.spinLeft(25, 250)
          Motors.setForward(25)
          waitcnt(clkfreq/2+cnt)
          repeat until CMUCam.getMiddleOfMassX > 70 and CMUCam.getMiddleOfMassX < 90 and CMUCam.getPerPixTracked > 50
          Motors.halt
            
          location := String("Line Following")
          direction := 100

          cornersTurned++
          
        elseif direction == Settings#RIGHT
          location := String("Right Corner")
          
          Motors.backward(25, 150)
          Motors.spinRight(25, 300)
          Motors.setForward(25)
          waitcnt(clkfreq/2+cnt)
          repeat until CMUCam.getMiddleOfMassX > 70 and CMUCam.getMiddleOfMassX < 90 and CMUCam.getPerPixTracked > 50
          Motors.halt                      
         
          location := String("Line Following")
          direction := 100

          cornersTurned++
          
        else
          Motors.forward(25, 300)
    followLine

PUB debugloop

  if DEBUG_VIA_USB
    Serial.start(31, 30, 0, 115200)
  else
    Serial.start(Settings#BLUETOOTH_RX, Settings#BLUETOOTH_TX, 0, 115200)    
  repeat
    Serial.tx(16)
    Serial.str(location)
    Serial.tx(13)
    Serial.dec(CMUCam.getMiddleOfMassX)
    Serial.str(string(", "))
    Serial.dec(CMUCam.getMiddleOfMassY)
    Serial.tx(13)
    if direction == Settings#LEFT
      Serial.str(String("Left"))
    elseif direction == Settings#RIGHT
      Serial.str(String("Right"))
    elseif direction == Settings#NUTER
      Serial.str(String("Neither"))
    else
      Serial.str(String("None"))
    Serial.tx(13)
    Serial.dec(CMUCam.getPerPixTracked)
    'Serial.tx(13)
    'Serial.dec(leftSpeed)
    'Serial.tx(13)
    'Serial.dec(rightSpeed)
    Serial.tx(13)
    Serial.dec(leftSaturation)
    Serial.tx(13)
    Serial.dec(rightSaturation)
    Serial.tx(13)
    Serial.dec(cornersTurned)
    Serial.tx(13)
    Serial.dec(Sensors.getLeftIRSensor)
    Serial.tx(13)
    Serial.dec(Sensors.getFrontUltrasonic)
    Serial.tx(13)
    'Serial.dec(spare)
    'Serial.tx(13)
    Serial.dec(spare2)
    waitcnt(clkfreq/10+cnt)

PRI abs_(number)

  if number < 0
    return -number
  else
    return number
        
    