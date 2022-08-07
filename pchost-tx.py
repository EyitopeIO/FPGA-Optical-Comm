import serial
import time


port = input("Enter port: ")
baud = 28800
par = serial.PARITY_EVEN
filepath = "C:\\Users\\Florence\\Desktop\\data.json"
rcv = b""
start = int()

try:
    s = serial.Serial(port=port, baudrate=baud, parity=par, stopbits=serial.STOPBITS_TWO, timeout=1)    

    start = time.monotonic()
    print(f"Start timestamp: {start}")
    with open(filepath, "rb") as f:
        i = f.read()
        s.write(i)
        print(f"Sent in {time.monotonic() - start} seconds")
        rcv += s.read(8192)
        print(f"Received -> {rcv}")

            
except Exception as e:
    print(e)
finally:
    s.close()




            

