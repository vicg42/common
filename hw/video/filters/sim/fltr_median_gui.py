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

median_ko = 1
save_en = 0

cpath = os.getcwd()

try:
    options, remainder = getopt.gnu_getopt(
        sys.argv[1:],
        "hi:s",
        ["help",
        "input=",
        "save=",
         ])
except getopt.GetoptError as err:
    print('ERROR:', err)
    sys.exit(1)

def help() :
    print('Mandatory option: ')
    print('\t-h  --help')
    print('\t-i  --input   path to input image file')
    print('\t-s  --save    enable save output image after exit()')
    print("usage:")
    print("\t %s -i <path to file> " % (os.path.basename(__file__)))
    sys.exit()

for opt, arg in options:
    if opt in ('-i', '--input'):
        usrfile_I = arg
    elif opt in ('-o', '--output'):
        usrfile_O = arg
    elif opt in ('-s', '--save'):
        save_en = 1
    elif opt in ('-h', '--help'):
        help()

if (not usrfile_I):
    print("error: set path to image file.")
    help()

print ("input image: " + usrfile_I)
# cv2.IMREAD_COLOR : Loads a color image. Any transparency of image will be neglected. It is the default flag.
# cv2.IMREAD_GRAYSCALE : Loads image in grayscale mode
# cv2.IMREAD_UNCHANGED : Loads image as such including alpha channel
img_i = cv2.imread(usrfile_I, cv2.IMREAD_GRAYSCALE)
frame_h, frame_w = img_i.shape
print ("frame: " + str(frame_w) + " x " + str(frame_h))

def nothing(x):
    pass

# cv2.WINDOW_NORMAL If this is set, the user can resize the window (no constraint).
# cv2.WINDOW_AUTOSIZE If this is set, the window size is automatically adjusted to fit the displayed image (see imshow() ), and you cannot change the window size manually.
# cv2.WINDOW_OPENGL If this is set, the window will be created with OpenGL support.
cv2.namedWindow('image_median',cv2.WINDOW_AUTOSIZE)

cv2.namedWindow('median_CTRL',cv2.WINDOW_AUTOSIZE)
cv2.createTrackbar('Kernel size','median_CTRL',1,16,nothing)


median_k = 1
median_img_o = img_i
while(1):
    cv2.imshow('image_median',median_img_o)
    k = cv2.waitKey(1) & 0xFF
    if k == 27:
        if (save_en == 1) :
            usrfile_O = usrfile_I + 'k' + str(median_ko) + '.bmp'
            cv2.imwrite(usrfile_O, median_img_o)
            print ("output image: " + usrfile_O)
        break

    # get current positions of four trackbars
    median_k = cv2.getTrackbarPos('Kernel size','median_CTRL')
    if (median_k%2) :
        median_ko = median_k

    median_img_o = cv2.medianBlur(img_i, median_ko)


cv2.destroyAllWindows()