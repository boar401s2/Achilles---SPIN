CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  DEBUG_VIA_USB = TRUE
  DEBUG_ENABLED = TRUE
  
OBJ

  CMUCam:        "CMUCam"
  Sensors:       "Sensors"
  Motors:        "Motors"
  Settings:      "Settings"
  Line:          "Line"
  Serial:        "LightweightSerial"
  CogManager:    "CogManager"
  Time:          "Time"

VAR

  long stack[25]
  long location

  byte leftSpeed, rightSpeed

  byte leftSaturation, rightSaturation

  byte direction, cornersTurned, lastCornerDirection
  word intersectionDelta
  
  byte speed

  byte errorsDetected

  word closestDistanceUS, closestDistanceIR, lastDist

  byte inSlopedTile

PUB Main | data, x, y

  'Cogs:
  '0: Main                      Enabled
  '1: PWM                       Enabled
  '2: Sensors                   Enabled
  '3: ADC                       Enabled
  '4: CMUCam Updater
  '5: CMUCam Serial             Enabled
  '6: Debug                     Enabled
  '7: Terminal                  Enabled
  
  

  Time.startGlobalClock
  Motors.start(3, 6, 9)
  Sensors.start
  CMUCam.start(Settings#CMUCAM_RX, Settings#CMUCAM_TX)
  CMUCam.changeBaud(57600)   
  CMUCam.configureToBlack  
  CMUCam.setTrackingWindow(20, 20, 140, 120)
  Motors.clawFullyOpen
  waitcnt(clkfreq/2+cnt)
  Motors.clawOff
  Motors.setRawPWMDuty(Settings#LAMP_SIGNAL, Settings#CMUCAM_LAMP_MEDIUM)
  CMUCam.setAutoGain(0)
  CMUCam.setAutoWhiteBalance(0)
  Motors.lowerArm
  Motors.armUp(50, 400)  
  CMUCam.startTracking  
  Line.init                               

  if DEBUG_ENABLED
    cognew(debugloop, @stack)
  
  toLineFollowing

{{==========[ Code for detecting obsticals ]==========}}

PUB canSeeTower

  if Sensors.getFrontUltrasonic < Settings#TOWER_DETECT_THRESHOLD
    Motors.halt
    waitcnt(clkfreq/10+cnt)
    if Sensors.getFrontUltrasonic < Settings#TOWER_DETECT_THRESHOLD
      return true
    else
      return false
  else
    return false

PUB isAtIntersection

  if CMUCam.getPerPixTracked > 160
    Motors.halt
    waitcnt(clkfreq/20+cnt)
    if CMUCam.getPerPixTracked > 160
      return true
    else
      return false
  else
    return false

PUB isAtChemSpill

  if isAtIntersection and Sensors.getFrontUltrasonic < 50
    Motors.halt
    waitcnt(clkfreq/10+cnt)
    if isAtIntersection and Sensors.getFrontUltrasonic < 50
      return true
    else
      return false
  else
    return false

PUB scanForShortcutDirection | x

  ''TODO: Implement nuter detector

  leftSaturation := -1000
  rightSaturation := 0

  repeat until abs_(leftSaturation-rightSaturation) > 20
  x := CMUCam.getMiddleOfMassX
  Motors.halt
  Motors.spinLeft(25, 300)
  leftSaturation := CMUCam.getPerPixTracked    
  Motors.spinRight(25, 600)
  rightSaturation := CMUCam.getPerPixTracked  
  Motors.spinLeft(25, 300)
  'if abs_(leftSaturation-rightSaturation) < 100
  '  return Settings#NUTER
  if leftSaturation > rightSaturation
    return Settings#LEFT
  else
    return Settings#RIGHT

PUB crudeUSScan

  closestDistanceUS := 60

  Sensors.resetGyro
  Motors.setSpinLeft(30)
  repeat until Sensors.getGyroZ > 40
  Motors.halt

  Motors.setSpinRight(25)
  repeat until Sensors.getGyroZ < -40
    if Sensors.getFrontUltrasonic < closestDistanceUS
      Motors.halt
      waitcnt(clkfreq/20+cnt)
      if Sensors.getFrontUltrasonic < closestDistanceUS
        closestDistanceUS := Sensors.getFrontUltrasonic
      Motors.setSpinRight(25)                                               

  Motors.setSpinLeft(25)
  repeat until Sensors.getFrontUltrasonic > closestDistanceUS - 3 and Sensors.getFrontUltrasonic < closestDistanceUS + 3
  Motors.halt

PUB spinToHeading(heading)

  repeat until Sensors.getGyroZ > heading - 1 and Sensors.getGyroZ < heading + 1
    if Sensors.getGyroZ > 0
      Motors.spinRight(25, 50)
    else
      Motors.spinLeft(25, 50)            
  
PUB fineIRScan(threshold)

  {closestDistanceIR := 150

  Sensors.resetGyro
  Motors.setSpinLeft(30)
  repeat until Sensors.getGyroZ > 40
  Motors.halt

  Motors.setSpinRight(25)
  repeat until Sensors.getGyroZ < -50
    if Sensors.getFrontIRSensor > closestDistanceIR
      Motors.halt
      waitcnt(clkfreq/20+cnt)
      if Sensors.getFrontIRSensor > closestDistanceIR
        closestDistanceIR := Sensors.getFrontIRSensor
      Motors.setSpinRight(25)                                               

  Motors.setSpinLeft(25)
  repeat until Sensors.getFrontIRSensor > closestDistanceIR - 3 and Sensors.getFrontIRSensor < closestDistanceIR + 3
  Motors.halt

  if closestDistanceUS > 20
    Motors.forward(25, 1000)}
 
  Sensors.resetGyro
  Motors.setSpinLeft(25)
  repeat until Sensors.getGyroZ > 30
  Motors.halt

  Motors.setSpinRight(20)
  repeat until Sensors.getFrontIRSensor > threshold
  Motors.halt
  

{  repeat
    if Sensors.getFrontIRSensor < lastDist - 50
 }
  'lastDist := 100

 { Motors.setSpinRight(25)
  repeat
    if Sensors.getFrontIRSensor > lastDist - 50 and Sensors.getFrontIRSensor > 300
      Motors.halt
      waitcnt(clkfreq/10+cnt)
      if Sensors.getFrontIRSensor > lastDist - 50 and Sensors.getFrontIRSensor > 300
        quit
      Motors.setSpinRight(25)
    lastDist := Sensors.getFrontIRSensor
  Motors.halt

  lastDist := 100

  Motors.spinRight(25, 500)
  Motors.setSpinLeft(25)
  repeat
    if Sensors.getFrontIRSensor < lastDist - 50 and Sensors.getFrontIRSensor > 300
      Motors.halt
      waitcnt(clkfreq/10+cnt)
      if Sensors.getFrontIRSensor < lastDist - 50 and Sensors.getFrontIRSensor > 300
        quit
      Motors.setSpinLeft(25)
    if Sensors.getFrontIRSensor > lastDist    
      lastDist := wSensors.getFrontIRSensor
  Motors.halt}

PUB scanForCan
  
  crudeUSScan
  repeat until Sensors.getFrontUltrasonic < 20
    if Sensors.getFrontUltrasonic > closestDistanceUS + 3
      crudeUSScan
    Motors.forward(25, 50)
    lastDist := Sensors.getFrontUltrasonic

  if Sensors.getFrontUltrasonic < 15
    Motors.backward(25, 1000)
    fineIRScan(600)
  else
    fineIRScan(600)

  'location := String("Rescanning with IR")
  'fineIRScan
{  
  location := String("Moving in closer")
  Motors.setForward(25)
  lastDist := 0  
  repeat until Sensors.getFrontUltrasonic < 20
    if Sensors.getFrontUltrasonic > lastDist + 10
      location := String("Lost the can")
      crudeUSScan
      fineIRScan
      location := String("Found it again")      
      Motors.setForward(25)
    lastDist := Sensors.getFrontUltrasonic
  location := String("Within 20 cm")
  Motors.halt
 } 
  {Motors.setSpinRight(25)
  repeat until Sensors.getGyroZ < -50
    if Sensors.getFrontIRSensor > closestDistanceIR and Sensors.getFrontIRSensor < 2000
      Motors.halt
      waitcnt(clkfreq/10+cnt)
      if Sensors.getFrontIRSensor > closestDistanceIR and Sensors.getFrontIRSensor < 2000
        closestDistanceIR := Sensors.getFrontIRSensor
      Motors.setSpinRight(25)                                               

  Motors.setSpinLeft(25)
  repeat until Sensors.getFrontIRSensor > closestDistanceIR - 200 and Sensors.getFrontIRSensor < closestDistanceIR + 200
  Motors.halt

  Motors.setForward(25)
  repeat until Sensors.getFrontUltrasonic < 5
  Motors.halt }
    
PUB driveToCan

  scanForCan

  Motors.clawOpen
  Motors.setForward(25)
  repeat until Sensors.getFrontUltrasonic < 6
  Motors.halt

PUB scanForBlock
  
  crudeUSScan  

  repeat until Sensors.getFrontUltrasonic < 20
    if Sensors.getFrontUltrasonic > closestDistanceUS + 3
      crudeUSScan
    Motors.forward(25, 50)
    lastDist := Sensors.getFrontUltrasonic
    
PUB driveToBlock

  scanForBlock
  Motors.spinLeft(25, 200)
  Motors.setForward(25)
  repeat until Sensors.getFrontUltrasonic < 5
    if Sensors.getFrontUltrasonic > lastDist + 3
      if lastDist > 15
        Motors.backward(25, 500)
      scanForBlock
    lastDist := Sensors.getFrontUltrasonic
  Motors.halt

{{==========[ Util Functions ]==========}}

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

{{==========[ Code for the different tiles ]==========}}


PUB toLineFollowing | y

  location := String("Line Following")

  repeat
  
    if canSeeTower
      toWaterTower
    if isAtChemSpill
      toChemSpill
    elseif isAtIntersection
      toIntersection
      
    followLine

PUB toIntersection | temp

  location := String("Intersection")

  Time.markTime(Settings#CORNER_TIME_END)
  intersectionDelta := Time.getMarkedtime(Settings#CORNER_TIME_END)-Time.getMarkedTime(Settings#CORNER_TIME_BEG)

  if (cornersTurned // 2) == 0
    direction := scanForShortcutDirection
  else
    if intersectionDelta < 1000
      direction := scanForShortcutDirection
    else
      direction := lastCornerDirection

  if not (cornersTurned // 2 == 0) and not lastCornerDirection == direction and intersectionDelta < Settings#GRIDLOCK_DELTA_THRESHOLD    
    location := string("Gridlock")

    toShortcut

    Line.setSpeed(25)
    
    repeat until CMUCam.getPerPixTracked > 210
      followLine
    Motors.halt

    direction := Settings#RIGHT
    temp := cornersTurned
    cornersTurned := 1         
    toShortcut
    cornersTurned := temp + 1 

    repeat until CMUCam.getPerPixTracked > 210

    repeat until CMUCam.getPerPixTracked < 120
      followLine
    Motors.halt
    
    {direction := Settings#LEFT
    temp := cornersTurned
    cornersTurned := 1
    toShortcut}
    direction := Settings#LEFT
    cornersTurned := temp + 1

    Line.setSpeed(Settings#GOAL_SPEED)

    toLineFollowing

  elseif direction == Settings#LEFT or direction == Settings#RIGHT
    toShortcut
    location := String("Line Following")                                  
  else
    Motors.forward(25, 300)
        
  
PUB toShortcut

  location := String("Intersection")
    
  {if direction == Settings#RIGHT and (cornersTurned // 2) == 0
    Motors.setForward(20)
    repeat until CMUCam.getPerPixTracked < 120
    repeat                       
      if CMUCam.getPerPixTracked > 150
        location := String("Gridlock")
        Motors.setBackward(20)  
        repeat until CMUCam.getPerPixTracked < 120
        repeat until CMUCam.getPerPixTracked > 200
        Motors.backwarard(25, 200)
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

    Motors.setForward(25)
    waitcnt(clkfreq/3+cnt)      
    if (cornersTurned // 2) == 0      
      repeat until CMUCam.getPerPixTracked < 20
    else
      repeat until CMUCam.getPerPixTracked < 120
    Motors.halt
    Motors.spinLeft(25, 250)
    Motors.forward(25, 100)
    Motors.setSpinLeft(25)
    waitcnt(clkfreq/4+cnt)
    repeat until CMUCam.getMiddleOfMassX > 70 and CMUCam.getMiddleOfMassX < 90 and CMUCam.getPerPixTracked > 40
    Motors.Halt    

    lastCornerDirection := Settings#LEFT    
     
  elseif direction == Settings#RIGHT
  
    location := String("Right Corner")

    Motors.setForward(25)
    waitcnt(clkfreq/3+cnt)      
    if (cornersTurned // 2) == 0      
      repeat until CMUCam.getPerPixTracked < 20
        repeat until CMUCam.getPerPixTracked < 120
        repeat until CMUCam.getPerPixTracked < 20 or CMUCam.getPerPixTracked > 160
        if CMUCam.getPerPixTracked > 160
          Motors.setBackward(25)
          repeat until CMUCam.getPerPixTracked < 120
          repeat until CMUCam.getPerPixTracked > 160
          Motors.setForward(25)
          repeat until CMUCam.getPerPixTracked > 120
          Motors.halt
          quit
    else
      repeat until CMUCam.getPerPixTracked < 120
      
    Motors.halt
    Motors.spinRight(25, 250)
    Motors.forward(25, 100)
    Motors.setSpinRight(25)
    waitcnt(clkfreq/4+cnt)
    repeat until CMUCam.getMiddleOfMassX > 70 and CMUCam.getMiddleOfMassX < 90 and CMUCam.getPerPixTracked > 40
    Motors.Halt         
  
    lastCornerDirection := Settings#RIGHT

  inSlopedTile := Sensors.isTilting

  cornersTurned++
  Time.markTime(Settings#CORNER_TIME_BEG)
  direction := Settings#NONE
  repeat 200
    followLine
                                                          
PUB toWaterTower

  location := String("Water Tower")
   

  speed := 25
  Motors.setSpinRight(speed)
  repeat until Sensors.getLeftIRSensor > 200'Settings#TOWER_IR_ADJUST_THRESHOLD
  Motors.halt

  location := String("Water Tower Side")


  repeat until CMUCam.getPerPixTracked > 50
    repeat until CMUCam.getPerPixTracked > 50
      if Sensors.getLeftIRSensor < 300
        waitcnt(clkfreq/50+cnt)
        if Sensors.getLeftIRSensor < 300
          quit
      Motors.setForward(speed)', 30)
    repeat until CMUCam.getPerPixTracked > 50
      if Sensors.getLeftIRSensor > 500
        waitcnt(clkfreq/50+cnt)
        if Sensors.getLeftIRSensor > 500
          quit
      Motors.setSpinLeft(speed)', 30)

  location := String("Finding Line")
      
  repeat 40
    if CMUCam.getMiddleOfMassX > 70 and CMUCam.getMiddleOfMassX < 90
      Motors.SpinRight(speed, 10)
    elseif CMUCam.getPerPixTracked < 20
      Motors.SpinRight(Speed, 10)
    else
      Motors.Forward(speed, 10)

  toLineFollowing

PUB toChemSpill

  location := string("Chemical Spill")

  Motors.backward(25, 1000)

  driveToCan

  Motors.lowerArm
  Motors.clawClose
  Motors.raiseArm

  Motors.Backward(25, 2000)

  driveToBlock
  
  Motors.clawOpen

  Motors.backward(25, 1000)

  Motors.clawClose
  waitcnt(clkfreq/2+cnt)
  Motors.clawOff
  Motors.lowerArm

  location := String("Finished!")

  repeat

{{==========[ Debugging Code ]==========}}

PUB debugloop | tiltDirection

  if DEBUG_VIA_USB
    Serial.init(31, 30, 19200)
  else
    Serial.init(Settings#BLUETOOTH_RX, Settings#BLUETOOTH_TX, 19200)    
  repeat
    Serial.tx(16)
    Serial.str(String("Location: "))
    Serial.str(location)
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
    Serial.tx(13)
    Serial.tx(13)

    Serial.dec(cornersTurned)
    Serial.tx(13)
    Serial.dec(intersectionDelta)
    Serial.tx(13)
    Serial.dec(errorsDetected)
    Serial.tx(13)
    Serial.tx(13)

    Serial.dec(Sensors.getFrontUltrasonic)
    Serial.tx(13)
    Serial.dec(Sensors.getFrontIRSensor)
    Serial.tx(13)
    Serial.dec(Sensors.getLeftIRSensor)
    Serial.tx(13)
    Serial.tx(13)

    Serial.dec(closestDistanceUS)
    Serial.tx(13)
    Serial.dec(closestDistanceIR)
    Serial.tx(13)
    Serial.dec(lastDist)
    Serial.tx(13)
    Serial.tx(13)

    Serial.dec(Sensors.getGyroZ)
    Serial.tx(13)
    Serial.tx(13)

    Serial.dec(Sensors.getTiltX)
    Serial.tx(13)
    Serial.dec(Sensors.getTiltY)
    Serial.tx(13)
    Serial.dec(Sensors.getTiltZ)
    Serial.tx(13)
    Serial.tx(13)

    tiltDirection := Sensors.getTiltDirection
    if tiltDirection == Settings#LEFT
      Serial.str(String("Left"))
    elseif tiltDirection == Settings#RIGHT
      Serial.str(String("Right"))
    elseif tiltDirection == Settings#NONE
      Serial.str(String("Level"))
    elseif tiltDirection == Settings#FORWARD
      Serial.str(String("Forward"))
    else
      Serial.str(String("Backward"))
    Serial.tx(13)
    Serial.tx(13)
    
    
    {Serial.str(string("Centre of Mass: "))
    Serial.dec(CMUCam.getMiddleOfMassX)
    Serial.str(string(", "))
    Serial.dec(CMUCam.getMiddleOfMassY)
    Serial.tx(13)
    Serial.tx(13)

    Serial.str(String("Corner Direction: "))
    if direction == Settings#LEFT
      Serial.str(String("Left"))
    elseif direction == Settings#RIGHT
      Serial.str(String("Right"))
    elseif direction == Settings#NUTER
      Serial.str(String("Neither"))
    else
      Serial.str(String("None"))
    Serial.tx(13)
    Serial.tx(13)
    
    Serial.str(string("Saturation: "))
    Serial.dec(CMUCam.getPerPixTracked)
    Serial.tx(13)
    Serial.str(string("Left Corner Saturation: "))
    Serial.dec(leftSaturation)
    Serial.tx(13)
    Serial.str(string("Right Corner Saturation: "))
    Serial.dec(rightSaturation)
    Serial.tx(13)
    Serial.tx(13)

    Serial.str(string("Corners Turned: "))
    Serial.dec(cornersTurned)
    Serial.tx(13)
    Serial.str(string("Intersection Delta: "))
    Serial.dec(intersectionDelta)
    Serial.tx(13)
    Serial.tx(13)

    Serial.str(string("Left IR: "))
    Serial.dec(Sensors.getLeftIRSensor)
    Serial.tx(13)
    Serial.str(string("Front IR: "))
    Serial.dec(Sensors.getFrontIRSensor)
    Serial.tx(13)
    Serial.str(string("Front Ultrasonic: "))
    Serial.dec(Sensors.getFrontUltrasonic)
    Serial.tx(13)
    Serial.tx(13)

    Serial.str(String("Cogs Used: "))
    Serial.dec(CogManager.getUsedCogs)
    Serial.tx(13)}
    
    waitcnt(clkfreq/10+cnt)

PRI abs_(number)

  if number < 0
    return -number
  else
    return number
        
    