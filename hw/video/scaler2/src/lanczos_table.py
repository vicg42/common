import numpy as np
from matplotlib import pyplot as plt
import sys

x_chank = 6
x_resolution = 32*x_chank
y_resolution = 512

x = np.linspace(-3.0, 3.0, num=x_resolution, endpoint=False)

def Discrete(x):
    return int(round(y_resolution*x))

def Lanczos(x, a):
    x = abs(x)
    if x == 0.0:
        return 1
    elif x < 3.0:
        return ( a*np.sin(np.pi*x)*np.sin((np.pi*x)/a) ) / ((np.pi**2)*(x**2))
    else:
        return 0.0

interp_param = 3.0
f = [Discrete(Lanczos(point, a=interp_param)) for point in x]
val = [Lanczos(point, a=interp_param) for point in x]

ToBIN = lambda x : ''.join(reversed( [str((x >> i) & 1) for i in range(10)] ) )

LogFile = open("log.txt", "w")
for y in range(x_chank):
    for i in range(x_resolution/x_chank):
        print >> LogFile,("%d:%05d %+02.5f, %+05i(DEC), %+05x(HEX), %s(BIN)" %(y, i, val[i + (y*(x_resolution/x_chank))], f[i + (y*(x_resolution/x_chank))], int(f[i + (y*(x_resolution/x_chank))]), ToBIN(abs(f[i + (y*(x_resolution/x_chank))]))) )

plt.plot(x, f)
plt.grid(True)
plt.show()

# save init file for verilog array
f0 = open("lanczos_table_0.txt", "w")
f1 = open("lanczos_table_1.txt", "w")
f2 = open("lanczos_table_2.txt", "w")
f3 = open("lanczos_table_3.txt", "w")
f4 = open("lanczos_table_4.txt", "w")
f5 = open("lanczos_table_5.txt", "w")
for i in range(x_resolution/x_chank):
    f0.write(ToBIN(abs(f[i + (x_resolution/4)*0])) + '\n')
    f1.write(ToBIN(abs(f[i + (x_resolution/4)*1])) + '\n')
    f2.write(ToBIN(abs(f[i + (x_resolution/4)*2])) + '\n')
    f3.write(ToBIN(abs(f[i + (x_resolution/4)*3])) + '\n')
    f4.write(ToBIN(abs(f[i + (x_resolution/4)*3])) + '\n')
    f5.write(ToBIN(abs(f[i + (x_resolution/4)*3])) + '\n')

