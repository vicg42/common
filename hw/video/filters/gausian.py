import sys
import math
import pylab
from mpl_toolkits.mplot3d import Axes3D
import numpy


def gaussian(x, y, sigma):
    return (1.0 / (2 * numpy.pi * (sigma ** 2))) * numpy.exp(- ((x ** 2) + (y ** 2))/ (2 * sigma ** 2))


def makeData ():
    x = numpy.arange (-2, 3, 1)
    y = numpy.arange (-2, 3, 1)
    xgrid, ygrid = numpy.meshgrid(x, y)

    zgrid = gaussian(xgrid, ygrid, 0.84089642)
    return xgrid, ygrid, zgrid

x, y, z = makeData()

print (x)
print (y)
print (z)

fig = pylab.figure()
axes = Axes3D(fig)

axes.plot_surface(x, y, z)

pylab.show()