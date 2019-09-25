import scipy.misc
from PIL import Image

image = Image.open('img_600x600_8bit.bmp')

image_bilinear = scipy.misc.imresize(image, 2.0, interp='bilinear')
image_bilinear_out = Image.fromarray(image_bilinear)
image_bilinear_out.save("img_600x600_8bit_bilinear.bmp")


image_bicubic = scipy.misc.imresize(image, 2.0, interp='bicubic')
image_bicubic_out = Image.fromarray(image_bicubic)
image_bicubic_out.save("img_600x600_8bit_bicubic.bmp")


image_lanczos = scipy.misc.imresize(image, 2.0, interp='lanczos')
image_lanczos_out = Image.fromarray(image_lanczos)
image_lanczos_out.save("img_600x600_8bit_lanczos.bmp")

