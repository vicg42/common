#https://en.wikipedia.org/wiki/%CE%9C-law_algorithm

import numpy as np
from matplotlib import pyplot as plt

x = range(1024)
def Discrete(x):
    return int(round(x))

def mu_law(x, a):
    return np.log(1 + x*a) / np.log(1 + a)

# u = 0.009165
u = 0.009265
f = [Discrete(mu_law(point, u)) for point in x]

f0 = open("width_converter_ram_default.txt", "w")
for i in x :
    print("input=0x%x  output=0x%x" % (i, Discrete(mu_law(i, u))) )
    f0.write(hex(Discrete(mu_law(i, u)))[2:] + '\n')

plt.plot(x, f)
plt.grid(True)
plt.show()
