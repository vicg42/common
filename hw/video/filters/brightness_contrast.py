#
# author: Golovachenko Viktor
#
import cv2
import numpy as np
import getopt
import sys
import os

usrfile_I = ""
usrfile_O = ""
brightness = 0
contrast = 1

cpath = os.getcwd()

try:
    options, remainder = getopt.gnu_getopt(
        sys.argv[1:],
        "hi:o:c:b:",
        ["help",
        "input=",
        "output=",
         ])
except getopt.GetoptError as err:
    print('ERROR:', err)
    sys.exit(1)

def help() :
    print('Mandatory option: ')
    print('\t-h  --help')
    print('\t-i  --input   path to input file')
    print('\t-o  --output  path to output file')
    print('\t-c            contrast value')
    print('\t-b            brightness value')
    print("usage:")
    print("\t python ./%s -i <path to input file>" % (os.path.basename(__file__)))
    sys.exit()

for opt, arg in options:
    if opt in ('-c'):
        contrast = int(arg)
    elif opt in ('-b'):
        brightness = int(arg)
    elif opt in ('-i', '--input'):
        usrfile_I = arg
    elif opt in ('-o', '--output'):
        usrfile_O = arg
    elif opt in ('-h', '--help'):
        help()

if ((not usrfile_I) or (not usrfile_O)):
    print("error: path to input file.")
    help()


print ("input file: " + usrfile_I)

imgRGB_in = cv2.imread(usrfile_I, cv2.IMREAD_COLOR)

b, g, r = cv2.split(imgRGB_in)
frame_h, frame_w = r.shape
print ("frame: %d x %d" % (frame_w, frame_h))
print ("R,G,B(min): %d, %d, %d" % (np.amin(r),np.amin(g),np.amin(b)))
print ("R,G,B(max): %d, %d, %d" % (np.amax(r),np.amax(g),np.amax(b)))

print ("\nuser ctrl:")
print ("brigtness: " + str(brightness))
print ("contrast(value): " + str(contrast))

# imgYUV_in = cv2.cvtColor(imgRGB_in, cv2.COLOR_BGR2YUV)
# v, cr, cb = cv2.split(imgYUV_in)
# v_o = np.zeros((frame_h, frame_w), dtype = np.int16)

coe = (259*(contrast+255)) / (255*(259-contrast))
print ("contrast(coe): " + str(coe))

r_o = np.zeros((frame_h, frame_w), dtype = np.int16)
g_o = np.zeros((frame_h, frame_w), dtype = np.int16)
b_o = np.zeros((frame_h, frame_w), dtype = np.int16)
for h in range(0,frame_h):
    for w in range(0,frame_w):
        r_o[h,w] = coe*(r[h,w] - 128) + 128 + brightness
        g_o[h,w] = coe*(g[h,w] - 128) + 128 + brightness
        b_o[h,w] = coe*(b[h,w] - 128) + 128 + brightness

        if r_o[h,w] > 255 :
            r_o[h,w] = 255
        if r_o[h,w] < 0 :
            r_o[h,w] = 0

        if g_o[h,w] > 255 :
            g_o[h,w] = 255
        if g_o[h,w] < 0 :
            g_o[h,w] = 0

        if b_o[h,w] > 255 :
            b_o[h,w] = 255
        if b_o[h,w] < 0 :
            b_o[h,w] = 0

        # v_o[h,w] = coe*(v[h,w] - 128) + 128 + brightness

        # if v_o[h,w] > 255 :
        #     v_o[h,w] = 255
        # if v_o[h,w] < 0 :
        #     v_o[h,w] = 0

print ("\nresult: %s" % (usrfile_O))
print ("R,G,B(min): %d, %d, %d" % (np.amin(r_o),np.amin(g_o),np.amin(b_o)))
print ("R,G,B(max): %d, %d, %d" % (np.amax(r_o),np.amax(g_o),np.amax(b_o)))

imgRGB_out = cv2.merge((b_o, g_o, r_o))
cv2.imwrite(usrfile_O, imgRGB_out)

# imgYUV_out = cv2.merge((v, cr, cb))
# imgRGBYUV_out = cv2.cvtColor(imgYUV_out, cv2.COLOR_YUV2BGR)
# cv2.imwrite("ttt2.png", imgRGBYUV_out)
