#https://en.wikipedia.org/wiki/%CE%9C-law_algorithm

import numpy as np
from matplotlib import pyplot as plt
import sys
import getopt
import os

usrfile = "width_converter_ram_default.txt"
law = "mu"

x = range(1024)
def Discrete(x):
    return int(round(x))

def mu_law(x, a):
    return np.log(1 + x*a) / np.log(1 + a)

def line_law(x, a, b):
    return x*a + b

try:
    options, remainder = getopt.gnu_getopt(
        sys.argv[1:],
        'hf:l:',
        ['help',
         'file=',
         'law=',
         ])
except getopt.GetoptError as err:
    print('ERROR:', err)
    sys.exit(1)

def help() :
    print('Mandatory option: ')
    print('\t-h   help')
    print('\t-f   path to file. Default %s' % (usrfile) )
    print('\t-l   law (mu, line). Default %s' % (law) )
    print("using:")
    print("\t %s -f <path to file> " % (os.path.basename(__file__)))
    sys.exit()

for opt, arg in options:
    if opt in ('-f', '--file'):
        usrfile = arg
    elif opt in ('-l', '--law'):
        law = arg
    elif opt in ('-h', '--help'):
        help()

if law == "mu" :
    u = 0.009265
    f = [Discrete(mu_law(point, u)) for point in x]
elif law == "line" :
    a = 0.249
    b = 0
    f = [Discrete(line_law(point, a, b)) for point in x]
else :
    print('ERROR: bad value for -z rgument')
    sys.exit(1)

fd = open(usrfile, "w")
for i in x :
    if law == "mu" :
        print("input=0x%x  output=0x%x" % (i, Discrete(mu_law(i, u))) )
        fd.write(hex(Discrete(mu_law(i, u)))[2:] + '\n')
    elif law == "line" :
        print("input=0x%x  output=0x%x" % (i, Discrete(line_law(i, a, b))) )
        fd.write(hex(Discrete(line_law(i, a, b)))[2:] + '\n')

print("\n")
print("Law is %s" % (law))
print("table write to file %s" % (usrfile))

plt.plot(x, f)
plt.grid(True)
plt.show()
