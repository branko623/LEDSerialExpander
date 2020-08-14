Python Raspberry Pi Serial Expander Board driver
======================

This is a driver written in python and optimized with cython for the [Pixelblaze Output Expander Board](https://github.com/simap/pixelblaze_output_expander) for use on Raspberry Pi (it could work for other systems, but it has not been tested). 

The raspberry pi hardware is not optimized for tasks such as driving neopixels through its GPIO. Drivers exist such as neopixel_write, but cannot drive larger arrays or pass 100fps for smaller ones, and a lot of precious CPU cycles are lost in driving them. Also, you can only run one strip, the Expander board allows for up to 64. 

This board makes use of the UART TX port on your device. Any raspberry pi with a serial interface can be used, as long as the port and baudrate that are passed are correct, and your UART is set up and working (Enable by going to sudo raspi-config -> interface options -> serial -> turn OFF serial terminal/turn ON serial interface -> reboot). After doing this, GPIO14 should be activiated for serial use. You will know that the expander board is recieving valid serial data if it begins blinking an orange LED. 

Currently only ws281x strips are supported by this python code (APA strips are also supported by this board) 

Installation
-------------------

```bash
pip install --user cython-package-example
```
or compile with cython:
```bash
compile code
```

Usage
-------------------
Import the Library:
```python
import LEDSerialExpanderBoard
```

Configure your strip with a dictionary, with the keys as the board pin numbers: 
```python
strips = {0: {'size':80, 'order': 'RGB' ,'type':1},
          1: {'size':30, 'order': 'RGBW' ,'type':1},
          4: {'size':72, 'order': 'RGB' ,'type':1}}

display = LEDSerialExpanderBoard (strips)
```
The type:1 indicated is for WS281x strips, which are the only ones that this driver currently supports.

Pass data to be written either by a bytearray() that contains data for all strips in channel-sequential order:

```python
data = bytearray([0 for _ in range(576)]) 
#your code to manipulate data

display.write(data)
```

or alternatively, pass a dict with individual channels as keys containing their own bytearrays: 

```python
data_dict = {0: data1,
             1: data2,
             4: data3}

display.write(data_dict) 
```

Other Parameters
-------------------
<ul>
<li>
<b> uart: </b>
default: "/dev/ttyS0"
This controls the uart tx port. Raspberry pi 3, 4, and zero W all use the default above. Others might use "/dev/ttyAMA0". 
</li>

<li>
<b>baud:</b>
default: 2000000
The baudrate is the speed at which the serial connection operates. It has been discovered that for RPI ZERO W, a baudrate of 2304000 (a standard baudrate multiple) was needed for the connection to work, while on the PI 4, only 2000000 worked. Others remain untested.
</li>

<li>
<b>fps_show:</b>
default: False
If set to True, this will print the FPS being displayed every second to the console
</li>
</ul>

Notes on fast framerates:
-------------------
The smaller your largest strip, the higher the theoretical framerate you can get. With 50 per strip, you can achieve over 300fps with this board (if your math is efficient enough to output at this speed, python in itself has a lot of overhead). 

Also keep in mind that the baudrate will bottleneck the framerate for larger arrays. Every pixel contains 24 (or 32 for RGBW) bits. Consider that (bits per pixel) * (number of pixels) * x  = (baudrate) * (.8). The .8 accounts for parity. Solving for x will give you the maximum framerate for your setup. It is possible for this to be higher, if you consider that you don't have to send every strip during a send. 

Troubleshooting:
------------------- 
If you are not seeing the orange on the expander board (valid data recieved), things to check: 

<ul>
<li>Make sure that ground is continuous across your strip, the expander board, and your pi (or other device), and all other wiring in order.</li> 
<li>Your UART interface may not be turned on, or may be set to a different port. You can test using an application called minicom ( <code>sudo apt-get install minicom</code> ), connecting your UX and RX pins on your board, and opening two terminals, the TX controlled by your TX port (like /dev/ttyS0) with command: <code>minicom -b 9600 -o -D /dev/ttyS0</code> and RX connected to your RX port (usually /dev/serial0) with command: <code>minicom -b 9600 -o -D /dev/serial0</code> Typing anything into the TX terminal should echo back on the RX window.</li> 
<li>The default baudrate is not syncing. Set to a different rate.</li> 
</ul>
