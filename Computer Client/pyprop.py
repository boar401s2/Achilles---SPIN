#---[Imports]---#
import threading
import serial
import pygame.event as e

#---[Variables]---#

#---[Reciever]---#

class Reciever:
    """
    Format: [Key: Value]
    """
    def __init__(self):
        self.port = 0
        self.msgs = {}
        self.thread = None
        self.serial = None
        self.running = False
        self.registeredListeners = {}
        self.usingPygame = True

    def registerListener(self, key, func):
        self.registeredListeners[key] = func

    def deleteListener(self, key):
        del self.registeredListeners[key]

    def update(self):
        msgs = self.msgs
        self.msgs = {}
        for x in msgs:
            try:
                m = msgs[x]
                l = self.registeredListeners[x]
                l(m)
            except:
                pass
            
    def start(self, port, usingPygame=True):
        self.port = port
        self.running = True
        self.usingPygame = usingPygame
        self.thread = threading.Thread(target=self.run)
        self.thread.start()

    def stop(self):
        self.running = False

    def run(self):
        self.serial = serial.Serial(self.port-1)
        self.serial.setBaudrate(9600)

        temp = ""
        recving = False

        while self.running:
            e.pump()
            rx = self.serial.read(1)
            
            if rx == "[":
                recving = True
            elif rx == "]":
                try:
                    recving = False
                    x = temp.split(":")
                    key = x[0].strip()
                    value = x[1].strip()
                    self.msgs[key] = eval(value)
                    temp = ""
                except:
                    temp = ""
                    recving = False
            elif recving==True:
                temp = temp + rx

        self.serial.close()
        

if __name__ == "__main__":
    recv = Reciever()
    recv.start()
    while 1:
        if input("Continue Running: ")==0:
            recv.stop()
            quit()
            
        
            
