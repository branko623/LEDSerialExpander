#TESTING 2 STRIPS on channel 0 and 1
from import 
strip0 = {'channel': 0, 'size':30, 'order': 'RBG' ,'type':1}
strip1 = {'channel': 1, 'size':30, 'order': 'RBG' ,'type':1}
display = LEDSerialExpanderBoard ([strip0,strip1],fps_show=True)


tot = strip0['size'] + strip1['size']
bpp = 3
data = bytearray([0 for _ in range(tot*bpp)])

pal = [0,0,150],[150,0,0],[0,150,0]

while True:
    x = random.randint(0,90)
    if len(data) > tot*bpp-bpp:
        data = data[3:tot*bpp ]
    if x<3:
        data.extend(pal[x])
    else:
        data.extend([0,0,0])

    display.write(data)

