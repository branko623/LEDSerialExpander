import random
from LEDSerialExpander import LEDSerialExpander

#first configure your setup
strips = { 0: {'size':70, 'order': 'RGB' ,'type':1},
           7: {'size':70, 'order': 'RGB' ,'type':1}}

display = LEDSerialExpander(strips,fps_show=True,baud=2000000,draw_wait=.0001)

tot = sum(strips[k]['size'] for k in strips.keys())
bpp = 3
data = bytearray([0 for _ in range(tot*bpp)])

pal = [0,0,150],[150,0,0],[0,150,0]

while True:
    #time.sleep(.0003)
    x = random.randint(0,300)
    if len(data) > tot*bpp-bpp:
        data = data[bpp:]
    if x<3:
        data.extend(pal[x])
    else:
        data.extend([0,0,0])

    display.write(data)

