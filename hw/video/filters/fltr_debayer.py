#
# author: Golovachenko Viktor
#
# import cv2
import numpy as np
import getopt
import sys
import os

import matplotlib.pyplot as plt
import matplotlib.cbook as cbook

usrfile_I = ""
usrfile_O = ""

cpath = os.getcwd()

try:
    options, remainder = getopt.gnu_getopt(
        sys.argv[1:],
        "hi:o:",
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
    print('\t-i  --input   path to input image file')
    print('\t-o  --output  path to output image file')
    print("usage:")
    print("\t %s -i <path to file> -o <path to file>" % (os.path.basename(__file__)))
    sys.exit()

for opt, arg in options:
    if opt in ('-i', '--input'):
        usrfile_I = arg
    elif opt in ('-o', '--output'):
        usrfile_O = arg
    elif opt in ('-h', '--help'):
        help()

# if (not usrfile_I) or (not usrfile_O):
#     print("error: set path to image file.")
#     help()


with cbook.get_sample_data(os.path.abspath(usrfile_I)) as image_file:
    image = plt.imread(image_file)

fig, ax = plt.subplots()
ax.imshow(image)
ax.axis('off')  # clear x-axis and y-axis

plt.show()
