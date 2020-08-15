import time
import random
import LEDSerialExpander

#TESTING 2 STRIPS on channel 0 and 1

strips = { 7: {'size':127, 'order': 'RGB' ,'type':1},
           0: {'size':115, 'order': 'RGB' ,'type':1}}
display = LEDSerialExpander.LEDSerialExpander(strips,fps_show=True,baud=2000000)

tot = strips[7]['size'] + strips[0]['size']
bpp = 3
data = bytearray([0 for _ in range(tot*bpp)])

pal = [0,0,150],[150,0,0],[0,150,0]

while True:
    x = random.randint(0,290)
    if len(data) > tot*bpp-bpp:
        data = data[3:]
    if x<3:
        data.extend(pal[x])
    else:
        data.extend([0,0,0])

    display.write(data)

