import numpy as np
from matplotlib import pyplot as plt

x_resolution = 1024
y_resolution = 512

# x = np.linspace(0.0, 1.0, num=x_resolution, endpoint=False)
x = np.linspace(-2.0, 2.0, num=x_resolution*4, endpoint=False)

def Discrete(x):
    return int(round(y_resolution*x))

def Cubic(x, a):
    x = abs(x)
    if x < 1.0:
        return (a+2.0)*x*x*x - (a+3)*x*x + 1
    elif x < 2.0:
        return a*x*x*x - 5*a*x*x + 8*a*x - 4*a
    else:
        return 0.0

# interp_param = -0.5
interp_param = -1.0
# interp_param = -2.0
f = [Discrete(Cubic(point, a=interp_param)) for point in x]

plt.plot(x, f)

# plt.plot(x, [Discrete(Cubic(point, a=-0.5)) for point in x])
# plt.plot(x, [Discrete(Cubic(point, a=-1.0)) for point in x])
# plt.plot(x, [Discrete(Cubic(point, a=-2.0)) for point in x])

plt.show()

# save init file for verilog array
f0 = open("cubic_table_0.txt", "w")
f1 = open("cubic_table_1.txt", "w")
f2 = open("cubic_table_2.txt", "w")
f3 = open("cubic_table_3.txt", "w")
for i in range(x_resolution):
    f0.write(bin(-f[i + x_resolution*0])[2:] + '\n')
    f1.write(bin( f[i + x_resolution*1])[2:] + '\n')
    f2.write(bin( f[i + x_resolution*2])[2:] + '\n')
    f3.write(bin(-f[i + x_resolution*3])[2:] + '\n')
