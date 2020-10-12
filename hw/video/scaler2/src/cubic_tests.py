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


def InterpolateCubic(y0, y1, y2, y3, x):
    dx = int(round(x_resolution*x)) % x_resolution
    y = y3*f[dx] + y2*f[dx + x_resolution*1] + y1*f[dx + x_resolution*2] + y0*f[dx + x_resolution*3]
    print y0, y1, y2, y3, "|", y/y_resolution, "|", x
    # , 1.0*f[dx + x_resolution*2]/y_resolution

def InterpolateCubicList(y, x):
    x_int_coord = int(round(x_resolution*x))
    dx = x_int_coord % x_resolution
    x_int = x_int_coord / x_resolution
    y = y[x_int+3]*f[dx] + y[x_int+2]*f[dx + x_resolution*1] + y[x_int+1]*f[dx + x_resolution*2] + y[x_int+0]*f[dx + x_resolution*3]
    print y/y_resolution, "|", x


step = 1/1.5
# InterpolateCubic(0, 0, 0, 100, step*0)
# InterpolateCubic(0, 0, 0, 100, step*1)
# InterpolateCubic(0, 0, 100, 200, step*2)
# InterpolateCubic(0, 100, 200, 300, step*3)
# InterpolateCubic(0, 100, 200, 300, step*4)
# InterpolateCubic(100, 200, 300, 400, step*5)
# InterpolateCubic(200, 300, 400, 500, step*6)
# InterpolateCubic(200, 300, 400, 500, step*7)
# InterpolateCubic(300, 400, 500, 600, step*8)
# InterpolateCubic(400, 500, 600, 700, step*9)
# InterpolateCubic(400, 500, 600, 700, step*10)
# InterpolateCubic(500, 600, 700, 800, step*11)
# InterpolateCubic(600, 700, 800, 900, step*12)


y_list = [0] + [i*100 for i in range(100)]
for i in range(10):
    InterpolateCubicList(y_list, step*i)


print
from scipy import interpolate

end = 12
xx = range(end)

def PrintTestCase(yy, step):
    print "-----------------------------------------------------------------"
    f_cub = interpolate.interp1d(xx, yy, kind='cubic')
    for x in np.arange(0, end, step):
        print x, 

        y = f_cub(x)
        if y < 0.5:
            y = 0
        print "%.0f"%y
    print "\t",

yy = [0 for x in xx]
yy[5] = 4095
PrintTestCase(yy, 2.0)
print "odd fullscale /2"


yy = [0 for x in xx]
yy[6] = 4095
PrintTestCase(yy, 2.0)
print "even fullscale /2"


# yy = [0 for x in xx]
# yy[6] = 4095
# PrintTestCase(yy, 0.5)
# print "even fullscale *2"


# yy = [0 for x in xx]
# yy[5] = 4095
# PrintTestCase(yy, 0.5)
# print "odd fullscale *2"
