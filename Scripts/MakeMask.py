#!/usr/bin/env python3
from PIL import Image

DIM = 256

image  = Image.new('RGBA', (DIM, DIM))
pixels = image.load()
for x in range(DIM):
    for y in range(DIM):
        alpha        = (255 if y >= DIM - 1 - x else 0)
        pixels[x, y] = (255, 255, 255, alpha)

image.save("triangle_mask.tga")

'''
image  = Image.new('RGBA', (DIM, DIM))
pixels = image.load()
for x in range(DIM):
    for y in range(DIM):
        if x >= DIM/2:
            if y >= DIM - 1 - x and y <= x - 1:
                alpha = 255
            else:
                alpha = 0
        else:
            if y <= DIM - 2 - x and y >= x:
                alpha = 255
            else:
                alpha = 0

        pixels[x, y] = (255, 255, 255, alpha)

image.save("triangle_mask_2.tga")

image  = Image.new('RGB', (16, 16))
pixels = image.load()
for x in range(16):
    for y in range(16):
        pixels[x, y] = (255, 255, 255)

image.save("square_mask.tga")

image  = Image.new('RGBA', (16, 16))
pixels = image.load()
for x in range(16):
    for y in range(16):
        if y == 0 or y == 15:
            alpha = 0
        else:
            alpha = 255
        pixels[x, y] = (255*x//15, 255*y//15, 255, alpha)

image.save("square_mask_2.tga")
'''
