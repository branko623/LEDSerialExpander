'''
Author: Branko Mirkovic

This is a python driver for the LED Serial Expander Board for Pixelblaze created by Ben Hencke
Lets you use board in similar fashion to that of neopixel_write()

First import the class: 

from LEDSerialExpander import LEDSerialExpander

Configure your strip with a dictionary, with the keys as the board pin numbers: 

strips = {0: {'size':80, 'order': 'RGB' ,'type':1},
          1: {'size':30, 'order': 'RGBW' ,'type':1},
          4: {'size':72, 'order': 'RGB' ,'type':1}}

display = LEDSerialExpander(strips)

The type:1 indicated is for WS281x strips, which are the only ones that this driver currently supports.

Pass data to be written either by a bytearray() that contains data for all strips in channel-sequential order:

data = bytearray([0 for _ in range(576)]) 
#your code to manipulate data
display.write(data)

or alternatively, pass a dict with individual channels as keys containing their own bytearrays: 

data_dict = {0: data1,
	     1: data2,
	     4: data3}

display.write(data_dict) 
'''

import serial
import time
import math
from struct import pack
from cpython cimport array
from libc.string cimport memcpy

LARGEST_STRIP_BYTES = 2400
DEBUG_LIGHTS = False

CRC = [ 0x00000000, 0x77073096, 0xee0e612c,
    0x990951ba, 0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3, 0x0edb8832,
    0x79dcb8a4, 0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07,
    0x90bf1d91, 0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de, 0x1adad47d,
    0x6ddde4eb, 0xf4d4b551, 0x83d385c7, 0x136c9856, 0x646ba8c0, 0xfd62f97a,
    0x8a65c9ec, 0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5, 0x3b6e20c8,
    0x4c69105e, 0xd56041e4, 0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd,
    0xa50ab56b, 0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3,
    0x45df5c75, 0xdcd60dcf, 0xabd13d59, 0x26d930ac, 0x51de003a, 0xc8d75180,
    0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f, 0x2802b89e,
    0x5f058808, 0xc60cd9b2, 0xb10be924, 0x2f6f7c87, 0x58684c11, 0xc1611dab,
    0xb6662d3d, 0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589,
    0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433, 0x7807c9a2, 0x0f00f934, 0x9609a88e,
    0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01, 0x6b6b51f4,
    0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed, 0x1b01a57b, 0x8208f4c1,
    0xf50fc457, 0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf,
    0x15da2d49, 0x8cd37cf3, 0xfbd44c65, 0x4db26158, 0x3ab551ce, 0xa3bc0074,
    0xd4bb30e2, 0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a,
    0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5, 0xaa0a4c5f,
    0xdd0d7cc9, 0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086, 0x5768b525,
    0x206f85b3, 0xb966d409, 0xce61e49f, 0x5edef90e, 0x29d9c998, 0xb0d09822,
    0xc7d7a8b4, 0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad, 0xedb88320,
    0x9abfb3b6, 0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615,
    0x73dc1683, 0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b,
    0x9309ff9d, 0x0a00ae27, 0x7d079eb1, 0xf00f9344, 0x8708a3d2, 0x1e01f268,
    0x6906c2fe, 0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7, 0xfed41b76,
    0x89d32be0, 0x10da7a5a, 0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43,
    0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1,
    0xa6bc5767, 0x3fb506dd, 0x48b2364b, 0xd80d2bda, 0xaf0a1b4c, 0x36034af6,
    0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79, 0xcb61b38c,
    0xbc66831a, 0x256fd2a0, 0x5268e236, 0xcc0c7795, 0xbb0b4703, 0x220216b9,
    0x5505262f, 0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7,
    0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d, 0x9b64c2b0, 0xec63f226, 0x756aa39c,
    0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713, 0x95bf4a82,
    0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7,
    0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e, 0x81be16cd,
    0xf6b9265b, 0x6fb077e1, 0x18b74777, 0x88085ae6, 0xff0f6a70, 0x66063bca,
    0x11010b5c, 0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45, 0xa00ae278,
    0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7, 0x4969474d,
    0x3e6e77db, 0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0, 0xa9bcae53,
    0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9, 0xbdbdf21c, 0xcabac28a, 0x53b39330,
    0x24b4a3a6, 0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf, 0xb3667a2e,
    0xc4614ab8, 0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b,
    0x2d02ef8d]
cdef array.array crc_table256 = array.array('I',CRC)
cdef unsigned int[:] crcv = crc_table256

# in full c; avoids GIL
# calculates crc32 from b_pointer to b_pointer+length 
# then memcpy that crc in the following 4 bytes
cdef void crc(unsigned char* b_pointer, int length): 

    cdef int i
    cdef int tbl_idx = 0
    cdef unsigned char* destination = b_pointer 
    destination += length
    cdef unsigned int crc = 0xffffffff

    for i from 0 <= i < length: 
        tbl_idx = crc ^ b_pointer[i];
        crc = crcv[tbl_idx & 0xff] ^ (crc >> 8)

    crc &= 0xffffffff
    crc = crc ^0xffffffff
    
    memcpy(destination,<unsigned char*>&crc,4)

class LEDSerialExpander:
    # config: dict of dictionaries, each configuring a strip
    #     eg: { 0: {'size': 34, 'order': 'RGB', 'type': 1} , 4: {'size': 55, 'order': 'RGBW', 'type': 1}}
    # uart: 3,4,zero w all use ttyS0, else ttyAMA0
    # baud: should be one of the standardized values
    # fps_show: shows fps counter
    # draw_wait: Time to wait after draw_all command before sending new data
    def __init__(self,config, uart = "/dev/ttyS0", baud=2000000, fps_show = False, draw_wait = .0036):
        self.uart = uart
        self.baud = baud
        
        #although the draw_all command takes 7.2 ms, data can be sent before it's completion. .0036 is mentioned as safe 
        self.draw_wait = draw_wait 

        self.largest_channel = 0
        self.draw_time = time.time()
        
        self.fps_show = fps_show
        self.frametime = time.time()
        self.fps = 0
        
        self.config = config
        self.__setup()
        

    #one time setup run, create the buffer
    def __setup(self):
        self.size = 0 #total pixels among all strips
        self.port = serial.Serial(self.uart, baudrate=self.baud, timeout=3)  # 3,4,zero w all use ttyS0, else ttyAMA0
        
        #individual channel headers setup
        self.headers = {}
        self.buffer_size = 0
        
        for channel, c  in self.config.items():
            self.baud * 0.8
            
            if c['size'] > 0:
                self.size += c['size']
                c['bpp'] = len (c['order'])
                c['header_size'] = 10 # each ws2812 instruction has 10 byte header
                c['header_offset'] = self.buffer_size
                
                self.buffer_size += c['header_size'] 
                c['data_offset'] = self.buffer_size
                c['data_bytes'] = c['size'] *c['bpp']
                self.buffer_size += c['data_bytes'] + 4 # 4 is crc size
                
                if c['bpp'] <3 or c['bpp'] >4:
                    raise ValueError("channel: %s : color_order must be 3 or 4 items"%c['channel'])
                
                if c['bpp'] * c['size'] > 2400: # 800 RGB or 600 RGBW
                    raise ValueError("Each channel supports up to 800 RGB or 600 RGBW pixels")
                    
                c['order_byte'] = 0
                for i,color in enumerate(c['order']):
                    if color == "R":
                        c['order_byte'] += i << 6
                    elif color == "G":
                        c['order_byte'] += i << 4
                    elif color == "B":
                        c['order_byte'] += i << 2
                    elif color == "W":
                        c['order_byte'] += i 
                    else:
                        raise ValueError("channel: %s : color_order needs to be capitalized and contain these letters: RGBW "%c['channel'])
                    
                if self.largest_channel < c['data_bytes']:
                    self.largest_channel = c['data_bytes']
                    
                header = bytearray(b"UPXL") #magic start sequence
                header.append (channel) # channel 1 byte
                header.append (c['type']) # recordtype 1=ws2812 2=draw all 
                if c['type'] != 1:
                    raise ValueError("Non ws281x not supported yet")
                
                instruction = bytearray()
                instruction.append(c['bpp']) #numElements
                instruction.append(c['order_byte']) #colororder
                instruction.extend(pack("<h",c['size'])) # number of pixels, 2 bytes, LITTLE ENDIAN
                self.headers[channel] = header+instruction
                
        self.draw_all_offset = self.buffer_size

        #timing constants
        self.send_speed = (self.buffer_size*8) / (self.baud * 0.8) # time it takes in seconds for full command to reach the board
        
        #draw_all command:
        self.draw_all = bytearray(b"UPXL") #magic start sequence
        self.draw_all.append (0x00) # channel ignored but needs to be here
        self.draw_all.append (0x02) # recordtype 1=ws2812 2=draw all
        
        self.buffer = bytearray(self.buffer_size+10) #super important buffer declaration
        
        # this part copies headers and instructions to  the buffer. These headers are static
        for i,h in self.headers.items(): # traversing list of bytearrays, memcpy them into buffer
            start = self.config[i]['header_offset']
            end   = self.config[i]['header_offset']+self.config[i]['header_size']
            self.buffer[start:end] = h

        #draw_all memcpy
        start = self.draw_all_offset
        end   = self.draw_all_offset+len(self.draw_all)

        self.buffer[start:end] = self.draw_all
        cdef unsigned char* bufstart = self.buffer
        bufstart+= self.draw_all_offset
        crc(bufstart,<int>6)

        if DEBUG_LIGHTS:
            print ("Buffer size: %s :" %self.buffer_size)
        
    # main write thats called by user:
    # data can be (dict of bytearrays) or (just one bytearray that gets seperated according to configuration)
    def write (self,data):
        cdef unsigned char* buf_pointer
        cdef unsigned char* data_pointer
        cdef int s
        
        #FPS display
        if self.fps_show:
            now = time.time()
            self.fps += 1
            if now > math.ceil(self.frametime):
                print ("FPS: %s" %self.fps)
                self.fps = 0
            self.frametime = now
                
        if isinstance(data,bytearray): # one bytearray 

            start = 0
            for channel,c in self.config.items(): 
                end = start+(c['data_bytes'])
                buf_pointer = self.buffer
                buf_pointer += c['data_offset']
                data_pointer = data
                data_pointer+= start
                s = (c['data_bytes'])
                memcpy (buf_pointer,<unsigned char *>data_pointer,s)
                
                buf_pointer = self.buffer
                buf_pointer += c['header_offset']
                s += c['header_size']
                crc(buf_pointer,s)

                start = end 
                
        elif isinstance(data,dict): # dict of bytearrays

            for channel, c in data.items(): #channel is int, c is bytearray of data
                expected = self.config[channel]['data_bytes']
                if len(c) != expected:
                    raise ValueError("Channel %s: %s bytes passed, %s expected "%(channel,len(c),expected))
                 
                buf_pointer = self.buffer
                buf_pointer += self.config[channel]['data_offset']
                data_pointer = c
                s = (self.config[channel]['data_bytes'])
                memcpy (buf_pointer,<unsigned char*>data_pointer,s)
                
                buf_pointer = self.buffer
                buf_pointer += self.config[channel]['header_offset']
                s += self.config[channel]['header_size']
                crc(buf_pointer,<int>expected)

        else:
            raise ValueError("pixel data can be a dict of bytearrays or one large bytearray with data in order of channels")
        
        if DEBUG_LIGHTS:
            print (' '.join('{:02x}'.format(x) for x in self.buffer))
            print ("size: %s "%len(self.buffer))
        self.__draw()
        
    # Send all 
    def __draw(self): 
        
        #Timing
        #if self.send_speed > self.draw_wait: 
        #    pass
            #only reached if large amount of pixels is being sent. 
            #wait for the appropriate time to send 
            #print ("FIRST %s"%(self.send_speed - self.draw_wait))
            #time.sleep(self.send_speed - self.draw_wait) 
            

        when = (self.draw_time + self.draw_wait) #when to send
        now = time.time()
        if DEBUG_LIGHTS:
            print ("when: %s"%when)
            print ("now: %s"%now)
            print ("diff %s"%(when-now))
        if when > now:
            
            wait = when - now
            if DEBUG_LIGHTS:
                print ("draw time %s"%self.draw_time)
                print ("draw speed %s"%self.draw_wait)
                print ("send speed %s"%self.send_speed)
                print ("wait %s"%wait)

            if wait < 0:
                wait = 0

            # this will only be reached if the amount of pixels to be sent is low. 
            # Wait until last draw command has enough time to get head start before sending new data 
            time.sleep(wait) 
            
        self.draw_time = time.time() + self.send_speed
        self.__send()
        
    #UART TX
    def __send(self):
        self.port.write(self.buffer)

