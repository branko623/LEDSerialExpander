import time
import random
import LEDSerialExpander

#TESTING 2 STRIPS on channel 3 and 4

strips = { 3: {'size':40, 'order': 'RGB' ,'type':1},
           4: {'size':40, 'order': 'RGB' ,'type':1}}
display = LEDSerialExpander.LEDSerialExpander(strips,fps_show=True,baud=2000000)

tot = sum(strips[k]['size'] for k in strips.keys())
bpp = 3
data = bytearray([0 for _ in range(tot*bpp)])

pal = [0,0,150],[150,0,0],[0,150,0]

while True:
    x = random.randint(0,300)
    if len(data) > tot*bpp-bpp:
        data = data[3:]
    if x<3:
        data.extend(pal[x])
    else:
        data.extend([0,0,0])

    display.write(data)

