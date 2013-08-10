CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
OBJ

  CMUCam:        "CMUCam"  
  Comp:          "LightweightTerminal"
  Profiler[2]:      "Profiler"
  Motors:        "Motors"
  Settings:      "Settings"
  CogManager:    "CogManager"
  Sensors:       "Sensors"
  Ping:          "Ping"

VAR

  long stack[30]
  long location

  long lowestDistance, lastX

  byte speed

  byte inGreenTile

  long timeOfFlight

PUB Main | data, time, x, y

  Motors.start(3, 6, 9)   
  CMUCam.start(16, 17)
  CMUCam.changeBaud(57600)
  CMUCam.setPollMode(1)
  CMUCam.configureToBlack
  CMUCam.setTrackingWindow(0, 0, 160, 120)
  'CMUCam.sendCommand(String("AG 0"))
  'CMUCam.sendCommand(String("AW 0"))
  Motors.setRawPWMDuty(Settings#LIGHT_SIGNAL, Settings#CMUCAM_LAMP_MEDIUM)
  Sensors.start
  'Comp.init(31, 30, 9600)
  'cognew(DebugLoop, @stack)
  setSpeed(27)

  repeat until not Sensors.getGyroZ == 0

  toLineFollowing

  'toChemicalSpill

{{MISC Utilities}}

PUB strobeLED

  Motors.halt
  repeat
    Motors.setRawPWMDuty(2, 100)
    waitcnt(clkfreq/10+cnt)  
    Motors.setRawPWMDuty(2, 0)
    waitcnt(clkfreq/10+cnt)

PUB scanForClosest

  Sensors.resetGyroZ
  lowestDistance := 100

  Motors.setSpinLeft(30)
  repeat until Sensors.getGyroZ > 500
    waitcnt(clkfreq/100+cnt)

  location := string("Scanning..")
      
  Motors.setSpinRight(30)
  repeat until Sensors.getGyroZ < -150 
    if Sensors.getFrontUltrasonic < lowestDistance
      Motors.Halt
      waitcnt(clkfreq/4+cnt)
      if Sensors.getFrontUltrasonic < lowestDistance
        lowestDistance := Sensors.getFrontUltrasonic
      Motors.setSpinRight(30)

  location := String("Spinning to location...")  

  Motors.setSpinLeft(30)
  repeat
    if Sensors.getFrontUltrasonic > lowestDistance - 6 and Sensors.getFrontUltrasonic < lowestDistance + 6
      Motors.halt
      waitcnt(clkfreq/2+cnt)
      if Sensors.getFrontUltrasonic > lowestDistance - 6 and Sensors.getFrontUltrasonic < lowestDistance + 6
        quit
      Motors.setSpinLeft(30)
      if Sensors.getGyroZ > 500
        Motors.setSpinRight(30)
        repeat until Sensors.getGyroZ          
        Motors.halt
        scanForClosest
      
PUB scanForClosestBlock

  Sensors.resetGyroZ
  lowestDistance := 100

  Motors.setSpinLeft(30)
  repeat until Sensors.getGyroZ > 300
    waitcnt(clkfreq/100+cnt)

  location := string("Scanning..")
      
  Motors.setSpinRight(30)
  repeat until Sensors.getGyroZ < -300 
    if Sensors.getFrontUltrasonic < lowestDistance
      Motors.Halt
      waitcnt(clkfreq/4+cnt)
      if Sensors.getFrontUltrasonic < lowestDistance and Sensors.getFrontUltrasonic > 19
        lowestDistance := Sensors.getFrontUltrasonic
      Motors.setSpinRight(30)

  location := String("Spinning to location...")  

  Motors.setSpinLeft(30)
  repeat
    if Sensors.getFrontUltrasonic > lowestDistance - 6 and Sensors.getFrontUltrasonic < lowestDistance + 6
      Motors.halt
      waitcnt(clkfreq/2+cnt)
      if Sensors.getFrontUltrasonic > lowestDistance - 6 and Sensors.getFrontUltrasonic < lowestDistance + 6
        quit
      Motors.setSpinLeft(30)
      if Sensors.getGyroZ > 500
        Motors.setSpinRight(30)
        repeat until Sensors.getGyroZ          
        Motors.halt
        scanForClosest

PUB setSpeed(speed_)

  speed := speed_

PUB detectOffline | x, y                                       

  x := CMUCam.getMiddleOfMassX
  y := CMUCam.getMiddleOfMassY
  if x == 0 and y == 0 or CMUCam.getPerPixTracked < 15 or CMUCam.getPerPixTracked > 200
    return true
  else
    return false

PUB canSeeGreen

  CMUCam.configureToGreen
  waitcnt(clkfreq/10+cnt)
  CMUCam.updateTrackingData
  CMUCam.configureToBlack
  if CMUCam.getPerPixTracked > 15
    CMUCam.updateTrackingData
    return true
  else
    CMUCam.updateTrackingData
    return false

PUB isOnShortcut

  if CMUCam.getPerPixTracked > 110
    Motors.halt
    lastX := CMUCam.getMiddleOfMassX
    waitcnt(clkfreq/10+cnt)
    CMUCam.updateTrackingData
    if CMUCam.getPerPixTracked > 110
      return canSeeGreen
      
PUB followLine | x, stepsize

  stepsize := 75
  setSpeed(25)

  x := CMUCam.getMiddleOfMassX
  if x < 65
    Motors.SpinLeft(speed+10, stepsize)
  elseif x > 95
    Motors.SpinRight(speed+10, stepsize)
  else 
    Motors.setForward(speed)', stepsize)'a, stepsize)  

PUB toLineFollowing

  location := @LINE
  
  repeat
    CMUCam.updateTrackingData
    '
    if detectOffline and Sensors.getFrontUltrasonic < 45
      location := string("Checking for endtile")
      Motors.halt
      waitcnt(clkfreq/4+cnt)
      if detectOffline and Sensors.getFrontUltrasonic < 45
        toChemicalSpill
    '
     'if Sensors.getFrontUltrasonic < 30
     ' Motors.halt
     ' waitcnt(clkfreq/10+cnt)
     ' if Sensors.getFrontUltrasonic < 30
     '   toWaterTower

    'if isOnShortcut      
    '  toShortcut
    '  
    'elseif detectOffline
    '  toOffline
    ''elseif isOnShortcut
    ''  toShortcut
    'else                                                   
    followLine

PUB toOffline

  location := @OFF_LINE

  repeat until not detectOffline
    CMUCam.updateTrackingData
    Motors.setBackward(20)
  waitcnt(clkfreq/2+cnt)
  Motors.halt

PUB toShortcut | x, stepsize, y

  location := @SHORTCUT
  stepsize := 100

  CMUCam.updateTrackingData
  x := CMUCam.getMiddleOfMassX

  if lastX < x+5

    location := String("Right Turn")

    CMUCam.configureToBlack
    CMUCam.updateTrackingData
    waitcnt(clkfreq/2+cnt)

    repeat until cmucam.getPerPixTracked < 50
      CMUCam.updateTrackingData
      Motors.forward(speed, 100)

    repeat until x > 60 and x < 100 and CMUCam.getPerPixTracked > 70 and y > 45 and y < 75 
      CMUCam.updateTrackingData
      x := CMUCam.getMiddleOfMassX
      y := CMUCam.getMiddleOfMassY
      Motors.spinRight(speed+10, 75)
        
    repeat 20
      CMUCam.updateTrackingData
      x := CMUCam.getMiddleOfMassX
      if x < 65
        Motors.SpinLeft(speed+10, stepsize)
      elseif x > 95
        Motors.SpinRight(speed+10, stepsize)
      else 
        Motors.setForward(speed)', stepsize)
    Motors.halt  
    
  elseif lastX > x-5

    location := String("Left Turn")

    CMUCam.configureToBlack
    CMUCam.updateTrackingData
    waitcnt(clkfreq/2+cnt)

    repeat until cmucam.getPerPixTracked < 50
      CMUCam.updateTrackingData
      Motors.spinRight(speed, 100)

    repeat until x > 60 and x < 100 and CMUCam.getPerPixTracked > 70 and y > 45 and y < 75 
      CMUCam.updateTrackingData
      x := CMUCam.getMiddleOfMassX
      y := CMUCam.getMiddleOfMassY
      Motors.spinLeft(speed+10, 75)
        
    repeat 20
      CMUCam.updateTrackingData
      x := CMUCam.getMiddleOfMassX
      if x < 65
        Motors.SpinLeft(speed+10, stepsize)
      elseif x > 95
        Motors.SpinRight(speed+10, stepsize)
      else 
        Motors.setForward(speed)', stepsize)
    Motors.halt

  'inGreenTile
    toLineFollowing
  'else
  '  toShortcutTile

PUB toShortcutTile | x, y, stepsize

  location := @SHORTCUT_TILE
  inGreenTile := true
  stepsize := 100
  
  repeat
    CMUCam.updateTrackingData
    x := CMUCam.getMiddleOfMassX
    y := CMUCam.getMiddleOfMassY

    if x == 0 and y == 0
      repeat until x > 60 and x < 150
        CMUCam.updateTrackingData
        x := CMUCam.getMiddleOfMassX
        Motors.setBackward(20)
      waitcnt(clkfreq/2+cnt)
    elseif CMUCam.getPerPixTracked < 30
      repeat until CMUCam.getPerPixTracked > 50
        CMUCam.updateTrackingData
        Motors.setBackward(20)
    elseif CMUCam.getPerPixTracked > 80
      Motors.halt
      lastX := x
      waitcnt(clkfreq/4+cnt)
      CMUCam.updateTrackingData
      if CMUCam.getPerPixTracked > 105
        CMUCam.configureToGreen
        waitcnt(clkfreq/2+cnt)
        CMUCam.updateTrackingData
        if CMUCam.getPerPixTracked > 15
          toShortcut
        else
          CMUCam.configureToBlack
        waitcnt(clkfreq/2+cnt)
                                                   
    elseif x < 65
      Motors.SpinLeft(speed+10, stepsize)
    elseif x > 95
      Motors.SpinRight(speed+10, stepsize)
    else 
      Motors.setForward(speed)', stepsize)
  

PUB toWaterTower

  location := @WATER_TOWER

  toLineFollowing

PUB toGridlock

  location := @GRIDLOCK

PUB toChemicalSpill

  location := @CHEMICAL_SPILL

  toFindingCan
  toLiftingCan
  toFindingBlock
  toFinished

PUB toFindingCan

  location := @FINDING_CAN

  Motors.lowerArm
  Motors.clawOpen
  waitcnt(clkfreq/2+cnt)
  Motors.clawOff

  scanForClosest


  Profiler[1].StartTimer                          
  repeat
    Motors.forward(30, 50)
    if Sensors.getFrontUltrasonic < 7
      waitcnt(clkfreq/4+cnt)
      if Sensors.getFrontUltrasonic < 7
      quit
  timeOfFlight := Profiler[1].StopTimer_

  Motors.forward(30, 200)
  Motors.clawClose

PUB toLiftingCan

  location := @LIFTING_CAN

  Motors.raiseArm

PUB toFindingBlock | t

  location := @FINDING_BLOCK

  Motors.setBackward(30)
  waitcnt((clkfreq/1000)*timeOfFlight+cnt)
  Motors.halt

  repeat
  
  repeat
    if Sensors.getFrontUltrasonic < 7
      Motors.halt
      waitcnt(clkfreq/4+cnt)
      if Sensors.getFrontUltrasonic < 7
        Motors.clawOpen
        quit
      Motors.setForward(30)
    elseif Sensors.getFrontUltrasonic > 50
      Motors.halt
      waitcnt(clkfreq/4+cnt)
      if Sensors.getFrontUltrasonic > 50
        scanForClosest
      Motors.setForward(30)  

PUB toFinished

  location := @FINISHED

  Motors.backward(30, 400)
  Motors.lowerArm
  Motors.clawHalfOpen

  repeat


{{Is at location}}

PUB isAtLine

  return strcomp(location, @LINE)

PUB isOffLine

  return strcomp(location, @OFF_LINE)

PUB isAtShortcut

  return strcomp(location, @SHORTCUT)

PUB isAtShortcutTile

  return strcomp(location, @SHORTCUT_TILE)

PUB isAtWaterTower

  return strcomp(location, @WATER_TOWER)

PUB isAtGridlock

  return strcomp(location, @GRIDLOCK)

PUB isAtChemicalSpill

  return strcomp(location, @CHEMICAL_SPILL)  

PUB isAtFindingCan

  return strcomp(location, @FINDING_CAN)

PUB isAtLiftingCan

  return strcomp(location, @LIFTING_CAN)

PUB isAtFindingBlock

  return strcomp(location, @FINDING_BLOCK)

PUB isAtFinished

  return strcomp(location, @FINISHED)

PUB DebugLoop

  repeat
    Comp.tx(16)                 
    Comp.str(string("Used Cogs: "))
    Comp.dec(CogManager.getUsedCogs)
    Comp.tx(13)
    Comp.dec(CMUCam.getMiddleOfMassX)
    Comp.tx(13)
    Comp.dec(CMUCam.getBBoxPerPixTracked)
    Comp.tx(13)
    Comp.dec(CMUCam.getPerPixTracked)
    Comp.tx(13)
    Comp.str(location)
    Comp.tx(13)
    Comp.dec(Sensors.getGyroZ)
    Comp.tx(13)
    Comp.dec(lowestDistance)
    Comp.tx(13)
    Comp.dec(Sensors.getFrontUltrasonic)
    waitcnt(clkfreq/10+cnt)
DAT

LINE                    byte    "Line", 0
OFF_LINE                byte    "Off Line", 0
SHORTCUT                byte    "Shortcut", 0
SHORTCUT_TILE           byte    "Shortcut Tile", 0
WATER_TOWER             byte    "Water Tower", 0
GRIDLOCK                byte    "Gridlock", 0
CHEMICAL_SPILL          byte    "Chemical Spill", 0
FINDING_CAN             byte    "Finding Can", 0
LIFTING_CAN             byte    "Lifting Can", 0 
FINDING_BLOCK           byte    "Finding Block", 0
PLACING_CAN             byte    "Placing Can", 0
FINISHED                byte    "Finished!", 0
                        