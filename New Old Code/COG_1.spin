CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  COG_2:        "COG_2"
  Strings:      "Strings"

PUB Main | data

  COG_2.start(false, false, true, true)
  COG_2.cmucamDebug(string("Reached first command.", 13)) 
  COG_2.cmucamSetTrackingParameters(0, 255, 0, 255, 0, 255)
  COG_2.cmucamDebug(string("Reached second command.", 13))
  COG_2.cmucamSetTrackingWindow(60, 40, 100, 80)
  COG_2.cmucamDebug(string("Reached next command.", 13))
  COG_2.startSampling

  waitcnt(clkfreq*3+cnt)
  
  repeat
    COG_2.cmucamDebug(Strings.integerToDecimal(COG_2.getMiddleOfMassX, 3))
    COG_2.cmucamDebugNewLine
    waitcnt(clkfreq/2+cnt)
    


  'Bluetooth Stuff Pins:
  '  TX: 18
  '  RX: 19