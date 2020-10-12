import scipy.misc
import numpy as np

image = np.zeros((9, 9))
image[4][4] = 255
# print image

print scipy.misc.imresize(image, 1.0, interp='bicubic')
print scipy.misc.imresize(image, 1.5, interp='bicubic')
