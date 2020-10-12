import numpy as np
from matplotlib import pyplot as plt

x_resolution = 256
y_resolution = 128

# x = np.linspace(0.0, 1.0, num=x_resolution, endpoint=False)
x = np.linspace(-2.0, 2.0, num=x_resolution*4, endpoint=False)

def Cubic(x, a):
    x = abs(x)
    if x < 1.0:
        return (a+2.0)*(x**3) - (a+3)*(x**2) + 1
    elif x < 2.0:
        return a*(x**3) - 5*a*(x**2) + 8*a*x - 4*a
    else:
        return 0.0

def Discrete(x):
    return int(round(y_resolution*x))

#interp_param = -0.5
interp_param = -1.0
#interp_param = -2.0
f = [Discrete(Cubic(point, a=interp_param)) for point in x]

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
    # print(f[i + x_resolution*0])

# print(x[0])
# print(x[1024])
# print(x[2048])
# print(x[3072])
# print(x)
print(len(f))

plt.plot(x, f)
plt.grid(True)
# plt.plot(x, [Discrete(Cubic(point, a=-0.5)) for point in x])
# plt.plot(x, [Discrete(Cubic(point, a=-1.0)) for point in x])
# plt.plot(x, [Discrete(Cubic(point, a=-2.0)) for point in x])
plt.show()