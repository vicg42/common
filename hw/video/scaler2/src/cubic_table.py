#-----------------------------------------------------------------------
# author : Viktor Golovachenko
#-----------------------------------------------------------------------
#https://teaching.csse.uwa.edu.au/units/CITS4241/Handouts/Lecture04.html
import numpy as np
from matplotlib import pyplot as plt
import sys
import os

x_chank = 4 #number of coe_table files
x_resolution = 128 #total number of coeficient
y_resolution = 128 #accuracy

x = np.linspace(-2.0, 2.0, num=x_resolution, endpoint=False)

def Cubic(x, a):
    x = abs(x)
    if x < 1.0:
        return (a+2.0)*(x**3) - (a+3)*(x**2) + 1
    elif x < 2.0:
        return a*(x**3) - 5*a*(x**2) + 8*a*x - 4*a
    else:
        return 0.0

def B_spline(x, a):
    x = abs(x)
    if x < 1.0:
        return 1/2*(x**3) - (x**2) + 2/3
    elif x < 2.0:
        return (-1/6)*(x**3) + (x**2) - 2*x + 4/3
    else:
        return 0.0

def Discrete(x):
    return int(round(y_resolution*x))

interp_param = -1.0
coe = [Discrete(Cubic(point, a=interp_param)) for point in x] #discret values
coe_f = [Cubic(point, a=interp_param) for point in x] #folat values

original_stdout = sys.stdout # Save the original standard output
LogFile = open("log.txt", "w")
sys.stdout = LogFile # Change the standard output to the file we created.
print(os.path.basename(__file__))
x_chank_len=int(x_resolution/x_chank)
for i in range(x_chank_len):
    for y in range(x_chank):
        f0 = coe_f[(x_chank_len*y) + i]
        v0 = coe[(x_chank_len*y) + i]
        print("[%5d:%d] %+02.3f %05d(dec)   " % ( ((x_chank_len*y) + i),y,f0,v0), end="")
    print()
LogFile.close
sys.stdout = original_stdout # restore original value

# save init file for verilog array
coe_table=[]
coe_table.append(open("cubic_table_0.txt", "w"))
coe_table.append(open("cubic_table_1.txt", "w"))
coe_table.append(open("cubic_table_2.txt", "w"))
coe_table.append(open("cubic_table_3.txt", "w"))
for i in range(int(x_resolution/x_chank)):
    coe_table[0].write(bin(-coe[i + int(x_resolution/x_chank)*0])[2:] + '\n')
    coe_table[1].write(bin( coe[i + int(x_resolution/x_chank)*1])[2:] + '\n')
    coe_table[2].write(bin( coe[i + int(x_resolution/x_chank)*2])[2:] + '\n')
    coe_table[3].write(bin(-coe[i + int(x_resolution/x_chank)*3])[2:] + '\n')
    # print(f[i + x_resolution*0])

print("coe_width: %1.1f" % (np.log2(int(y_resolution))+1))
print("coe_table column (len): %d" % (x_chank))
print("coe_table raw (len)   : %d" % (int(x_resolution/x_chank)))
print("pixel_step (coe count): %d" % (x_resolution))

plt.grid(True)
plt.plot(x, [Discrete(Cubic(point, a=-0.5)) for point in x], color='green', linestyle='dashed', label='cubic a=-0.5')
plt.plot(x, [Discrete(Cubic(point, a=-1.0)) for point in x], color='blue', linestyle='solid', label='cubic a=-1.0')
plt.plot(x, [Discrete(Cubic(point, a=-2.0)) for point in x], color='black', linestyle='dotted', label='cubic a=-2.0')
plt.plot(x, [Discrete(B_spline(point, a=-2.0)) for point in x], color='red', linestyle='dashdot', label='b_spline')
plt.plot(x, coe, color='blue', linestyle='solid', label='my')
plt.legend(loc='best')
plt.show()