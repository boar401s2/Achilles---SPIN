{{
ADXL345Object

Author: Andrew Colwell (c) February 2010
Version: 1.0

The ADXL345 3-axis accelerometer chip has many functions.
It is an I2C chip for 3-axis acceleration. The chip can make measurements
for +/-2g, 4g, 8g, 16g ranges. This object only utilizes a few functions,
and could certainly be enhanced. However, some other may find benefit
in the routines to build more tailored objects.

For instance, an object could easily be developed to run in a cog
which constantly receives axis values and updates a memory space with
current acceleration values.

Associated with this object, is the ADXL345ObjectDemo which utilizes
the routines. Other users may find some value.

This object uses modified code from Mike Green's Basic_I2C_Driver
as well as modified code from I2C objects created by James Burrows.
See the Parallax Propeller Object Exchange for material produced
by both authors.
 
This object is built for the ADXL345 breakout board from SparkFun.
http://www.sparkfun.com/commerce/product_info.php?products_id=9156
http://www.analog.com/static/imported-files/data_sheets/ADXL345.pdf

The device address with SDO pin HIGH is 0x1D (7 bit) %0011_101
The 8th bit is a R/W bit.
To write, the address is 0x3A  (%0011_1010)
To read, the address is  0x3B  (%0011_1011)

The device address with SDO pin LOW  is 0x53 (7 bit) %1010_011
The 8th bit is a R/W bit. Used in this object
To write, the address is 0xA6  (%1010_0110)
To read, the address is  0xA7  (%1010_0111)

        Prop   Board    Sparkfun
                        Breakout Board           ADXL345
               GND ---  GND --•  ┌─── Y  ─     Pins 2,4,5,10
               +3.6V--  VCC --•  │(•)     ─     Pins 1,6
               +3.6V--  CS  --•     Z    ─     Pin  7  (Should be driven/tied to Vcc high for I2C mode)
               NC       Int1--•  X        ─     Pin  8
               NC       Int2--•           ─     Pin  9
               GND ---  SDO --•           ─     Pin  12 (alt address for I2C)
        P21   ────┬──── SDA --•           ─     Pin  13 *
                     ┌ SCL --•           ─     Pin  14 *
           +3.6V──┴─┤                          Pins 3,11 (Not Connected)
        P20   ────────┘   
                                                 * Connected to 4.7k Pull up resistors

  
   Data Output  Rate Code
   3200Hz       1111
   1600Hz       1110
    800Hz       1101
    400Hz       1100
    200Hz       1011
    100Hz       1010
     50Hz       1001
     25Hz       1000
   12.5Hz       0111
   6.25Hz       0110                        
}}
CON

   deviceAddressWrite = $A6     'Device uses two addresses, one to write
   deviceAddressRead  = $A7     'and one to read

   ' Register Map addresses (partial list)
   _DeviceID   = $00   'Device ID (0xE5)      r   Always %1110_0101
   _xOffset    = $1E   'User defined offset   r/w Each bit has a factor of 
   _yOffset    = $1F   'User defined offset   r/w 15.6mg/LSB per offset
   _zOffset    = $20   'User defined offset   r/w
   _FreeFallTh = $28   'freefall threshold    r/w 62.5mg/LSB Recommended between 0x05 and 0x09
   _FreeFall   = $29   'freefall time         r/w
   _Rate       = $2C   'Transfer Rate         r/w See datasheet table default 100Hz output
   _PwrCtrl    = $2D   'Measurement Controls  r/w
   _IntEnable  = $2E   'Interrupt control     r/w (%0000_0100 for freefall)
   _IntMap     = $2F   'Interrupt mapping     r/w (%0000_0000 for Int1 output)
   _IntSource  = $30   'Source of interrupts  r   (%0000_0100 freefall triggered int1)
   _DataFormat = $31   'Data format           r/w (%0000_0011 +/-16g with sign extension, 10 bit mode)
                       '                          (%1000_0000 Self-Test)
   _X0         = $32   '                      r    LSB
   _X1         = $33   '                      r    MSB
   _Y0         = $34   '                      r    LSB
   _Y1         = $35   '                      r    MSB
   _Z0         = $36   '                      r    LSB
   _Z1         = $37   '                      r    MSB
   _FifoCtrl   = $38   'FIFO control          r/w
   _FifoStat   = $39   'FIFO status           r

   ACK      = 0        ' I2C Acknowledge
   NAK      = 1        ' I2C No Acknowledge
   
   SCL      = Settings#IMU_SCL
   SDA      = Settings#IMU_SDA

OBJ

  Settings:       "Settings"   
 
PRI InitI2C                            ' An I2C device may be left in an
                                       '  invalid state and may need to be
   outa[SCL] := 1                      '   reinitialized.  Drive SCL high.
   dira[SCL] := 1
   dira[SDA] := 0                      ' Set SDA as input
   repeat 9
      outa[SCL] := 0                   ' Put out up to 9 clock pulses
      outa[SCL] := 1
      if ina[SDA]                      ' Repeat if SDA not driven high
         quit                          '  by the EEPROM

PRI StartI2C                           ' SDA goes HIGH to LOW with SCL HIGH
   outa[SCL]~~                         ' Initially drive SCL HIGH
   dira[SCL]~~
   outa[SDA]~~                         ' Initially drive SDA HIGH
   dira[SDA]~~
   outa[SDA]~                          ' Now drive SDA LOW
   outa[SCL]~                          ' Leave SCL LOW

PRI StopI2C                            ' SDA goes LOW to HIGH with SCL High
   outa[SCL]~~                         ' Drive SCL HIGH
   outa[SDA]~~                         '  then SDA HIGH
   dira[SCL]~                          ' Now let them float
   dira[SDA]~                          ' If pullups present, they'll stay HIGH


PRI Write(data) : ackbit               ' Mike Green's Routine
'' Write i2c data.  Data byte is output MSB first, SDA data line is valid
'' only while the SCL line is HIGH.  Data is always 8 bits (+ ACK/NAK).
'' SDA is assumed LOW and SCL and SDA are both left in the LOW state.
   ackbit := 0 
   data <<= 24
   repeat 8                            ' Output data to SDA
      outa[SDA] := (data <-= 1) & 1
      outa[SCL]~~                      ' Toggle SCL from LOW to HIGH to LOW
      outa[SCL]~
   dira[SDA]~                          ' Set SDA to input for ACK/NAK
   outa[SCL]~~
   ackbit := ina[SDA]                  ' Sample SDA when SCL is HIGH
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW
   dira[SDA]~~

PRI Read(ackbit): data                 ' Mike Green's Routine
'' Read in i2c data, Data byte is output MSB first, SDA data line is
'' valid only while the SCL line is HIGH.  SCL and SDA left in LOW state.
   data := 0
   dira[SDA]~                          ' Make SDA an input
   repeat 8                            ' Receive data from SDA
      outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~
   outa[SDA] := ackbit                 ' Output ACK/NAK to SDA
   dira[SDA]~~
   outa[SCL]~~                         ' Toggle SCL from LOW to HIGH to LOW
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW

PRI WrLoc(register, value)             ' James Burrows Routine
  StartI2C
  Write(deviceAddressWrite)
  Write(register)
  Write(value)  
  StopI2C

PRI ReLoc(register) : value            ' James Burrows Routine
  StartI2C
  Write(deviceAddressWrite | 0)
  Write(register)
  StartI2C
  Write(deviceAddressRead | 1)  
  value := read(NAK)
  stopI2C
  return value     
   
PRI WriteDataFormat(configByte)
  ' Configure the chip - recommend config byte of %0000_0011
    WrLoc(_DataFormat, configByte)

PRI ReadDataFormat : dataFormat
  ' Read the data configuration
  dataFormat := ReLoc(_DataFormat)
  return dataFormat
  
PRI ReadDeviceID : deviceID
  ' Read the Device ID which should always respond with %1110_0101
  deviceID := ReLoc(_DeviceID)
  if deviceID == %1110_0101
    deviceID~~     'set to -1 (true)
  else
    deviceID~      'set to 0 (false)
  return deviceID

PRI Read2byte(_axis): data
'' Read in i2c data, Data byte is output MSB first, SDA data line is
'' valid only while the SCL line is HIGH.  SCL and SDA left in LOW state.
'' The routine reflects the ADXL345 datasheet recommendations for
'' multiple byte read for each axis.

   StartI2C
   Write(deviceAddressWrite | 0)
   Write(_axis)
   StartI2C
   Write(deviceAddressRead | 0)

   data := 0
   dira[SDA]~                          ' Make SDA an input
   repeat 8                            ' Receive data from SDA
      outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~
   outa[SDA] := ACK                    ' Output ACK
   repeat 8                            ' Receive data from SDA
      outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~

   data := data << 16                  ' Shift data bits 16 bits left these are LSB 
   outa[SDA] := NAK                    ' Output NAK to SDA
   
   dira[SDA]~~
   outa[SCL]~~                         ' Toggle SCL from LOW to HIGH to LOW
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW
   StopI2C

   data := data <- 8                   ' puts the 8MSB to the 8LSB
   data := ~data                       ' extend sign

CON

        { Access Methods }

PUB init

  InitI2C
  WriteDataFormat(%0000_0000)                           'Set data format to default
  WriteDataFormat(%0000_0001)                           'Creating 4G, 10bit
  WrLoc(_Rate, %0000_1010)                              'Set data rate at 100Hz
  WrLoc(_PwrCtrl, %0000_1000)                           'Set chip to take measurements

PUB getX

  return Read2Byte(_X0)

PUB getY

  return Read2Byte(_Y0)

PUB getZ

  return Read2Byte(_Z0)

PUB rd_xyz(p_x, p_y, p_z)

  long[p_x] := getX
  long[p_y] := getY
  long[p_z] := getZ

PUB finalize

  WrLoc(_PwrCtrl, %0000_0000)
  
DAT

{{
                            TERMS OF USE: MIT License                                                           

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
}}  