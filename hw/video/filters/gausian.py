import sys
import math
import pylab
from mpl_toolkits.mplot3d import Axes3D
import numpy


def gaussian(x, y, sigma):
    return (1.0 / (2 * numpy.pi * (sigma ** 2))) * numpy.exp(- ((x ** 2) + (y ** 2))/ (2 * sigma ** 2))
#    return (1.0 / (2 * math.pi * (sigma ** 2))) * math.exp(- ((x ** 2) + (y ** 2))/ (2 * sigma ** 2))
#    return (1.0 / math.exp(- ((x ** 2) + (y ** 2))/ (2 * sigma ** 2)) )
#    return (1.0 / (x * y * math.pi * (sigma ** 2)))

#sigma = 2.8408

#for y in range(0, 4):
#    for x in range(0, 4):
#        g = gaussian(x, y, 0.84089642)
#        print "x(%02d) y(%02d) = %.08f" %(x, y, g)
##        print "x(%02d) y(%02d) = %.04f" %(x, y, (2 * math.pi))
#
#print "\t",




def makeData ():
    x = numpy.arange (-4, 4, 1)
    y = numpy.arange (-4, 4, 1)
    xgrid, ygrid = numpy.meshgrid(x, y)

#    zgrid = numpy.sin (xgrid) * numpy.sin (ygrid) / (xgrid * ygrid)
    zgrid = gaussian(xgrid, ygrid, 0.84089642)
    return xgrid, ygrid, zgrid

x, y, z = makeData()

fig = pylab.figure()
axes = Axes3D(fig)

axes.plot_surface(x, y, z)

pylab.show()