import numpy as np
from matplotlib import pyplot as plt
import sys

x_chank = 4
x_resolution = 32*x_chank
y_resolution = 512

x = np.linspace(-2.0, 2.0, num=x_resolution, endpoint=False)

def Discrete(x):
    return int(round(y_resolution*x))

def Cubic(x, a):
    x = abs(x)
    if x < 1.0:
        return (a+2.0)*(x**3) - (a+3)*(x**2) + 1
    elif x < 2.0:
        return a*(x**3) - 5*a*(x**2) + 8*a*x - 4*a
    else:
        return 0.0

interp_param = -1.0
f = [Discrete(Cubic(point, a=interp_param)) for point in x]
cubic_val = [Cubic(point, a=interp_param) for point in x]

ToBIN = lambda x : ''.join(reversed( [str((x >> i) & 1) for i in range(10)] ) )

LogFile = open("log.txt", "w")
for y in range(x_chank):
    for i in range(x_resolution/x_chank):
        print >> LogFile,("%d:%05d %+02.5f, %+05i(DEC), %+05x(HEX), %s(BIN)" %(y, i, cubic_val[i + (y*(x_resolution/x_chank))], f[i + (y*(x_resolution/x_chank))], int(f[i + (y*(x_resolution/x_chank))]), ToBIN(abs(f[i + (y*(x_resolution/x_chank))]))) )
#        print >> LogFile,("%d:%04d %+02.3f, %+05i(DEC), %+05x(HEX), %s(BIN)" %(y, i, cubic_val[i + (y*(x_resolution/x_chank))], f[i + (y*(x_resolution/x_chank))], int(f[i + (y*(x_resolution/x_chank))]), ToBIN(f[i + (y*(x_resolution/x_chank))])) )

plt.plot(x, f)
plt.grid(True)
plt.show()

# save init file for verilog array
f0 = open("cubic_table_0.txt", "w")
f1 = open("cubic_table_1.txt", "w")
f2 = open("cubic_table_2.txt", "w")
f3 = open("cubic_table_3.txt", "w")
for i in range(x_resolution/4):
    f0.write(ToBIN(abs(f[i + (x_resolution/4)*0])) + '\n')
    f1.write(ToBIN(abs(f[i + (x_resolution/4)*1])) + '\n')
    f2.write(ToBIN(abs(f[i + (x_resolution/4)*2])) + '\n')
    f3.write(ToBIN(abs(f[i + (x_resolution/4)*3])) + '\n')

