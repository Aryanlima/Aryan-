# Fondo + texto sobre el render de Ropilot (IconScene.png). Uso: python compose-icono.py [icon|thumb] [en|es]
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont
RENDERS = os.path.expanduser('~/Documents/Ropilot/Renders/FishFortune/')
OUT = os.path.join(os.path.dirname(__file__), '..', '')
mode = sys.argv[1] if len(sys.argv) > 1 else 'icon'
lang = sys.argv[2] if len(sys.argv) > 2 else 'en'
hall = len(sys.argv) > 3 and sys.argv[3] == 'halloween'
SUF = '-halloween' if hall else ''
W, H = (1024, 1024) if mode == 'icon' else (1920, 1080)
WATER, DEEP, GOLD, NIGHT = (46, 196, 241), (20, 120, 200), (255, 200, 61), (30, 42, 68)

img = Image.new('RGB', (W, H), (52, 20, 92) if hall else (120, 50, 170))
d = ImageDraw.Draw(img)
cx, cy = (W * .66, H * .32) if mode == 'icon' else (W * .6, H * .36)
for i in range(24):
    a0, a1 = i * math.tau / 24, (i + .5) * math.tau / 24
    d.polygon([(cx, cy), (cx + 3000 * math.cos(a0), cy + 3000 * math.sin(a0)), (cx + 3000 * math.cos(a1), cy + 3000 * math.sin(a1))], fill=(255, 106, 0) if hall else (255, 140, 40))
glow = Image.new('L', (W, H), 0)
ImageDraw.Draw(glow).ellipse([cx - 330, cy - 330, cx + 330, cy + 330], fill=255)
img.paste((255, 170, 60) if hall else (255, 225, 120), mask=glow.filter(ImageFilter.GaussianBlur(90)))
wy = int(H * (.72 if mode == 'icon' else .7))
d = ImageDraw.Draw(img)
d.rectangle([0, wy, W, H], fill=WATER)
d.rectangle([0, wy + (H - wy) // 2, W, H], fill=DEEP)
for x in range(-40, W, 120):
    d.ellipse([x, wy - 14, x + 130, wy + 18], fill=(225, 248, 255))
    d.ellipse([x + 50, wy + 70, x + 150, wy + 82], fill=(160, 230, 255))

fg = Image.open(RENDERS + 'IconScene.png').convert('RGBA')
if mode == 'icon':
    fg = fg.resize((930, 930), Image.LANCZOS); img.paste(fg, (40, -10), fg)
else:
    fg = fg.resize((1060, 1060), Image.LANCZOS); img.paste(fg, (860, 10), fg)

def text(s, size, cxy, rot):
    f = ImageFont.truetype('C:/Windows/Fonts/ariblk.ttf', size)
    l = Image.new('RGBA', (W, H), (0, 0, 0, 0)); ld = ImageDraw.Draw(l)
    ld.text(cxy, s, font=f, anchor='mm', fill=GOLD, stroke_width=max(8, size // 9), stroke_fill=NIGHT)
    ld.text((cxy[0], cxy[1] - size * .06), s, font=f, anchor='mm', fill=(255, 236, 150))
    ld.text((cxy[0], cxy[1] + size * .03), s, font=f, anchor='mm', fill=GOLD)
    l = l.rotate(rot, center=cxy, resample=Image.BICUBIC)
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0)); sh.paste((0, 0, 0, 120), (0, 10), l.split()[3].point(lambda a: a))
    img.paste(sh.filter(ImageFilter.GaussianBlur(6)), (0, 0), sh.filter(ImageFilter.GaussianBlur(6)))
    img.paste(l, (0, 0), l)
if mode == 'icon':
    text('HALLOWEEN' if hall else 'LEGENDARY', 132, (W // 2, int(H * .88)), 4)
else:
    text('FISH &', 150, (440, 330), 4); text('FORTUNE', 150, (440, 500), 4); text(('HALLOWEEN EVENT!' if lang == 'en' else '¡EVENTO DE HALLOWEEN!') if hall else ('LEGENDARY!' if lang == 'en' else '¡LEGENDARIO!'), (60 if lang == 'en' else 48) if hall else 84, (440, 680), 4)
img.save(OUT + (f'icon/icon-ropilot{SUF}.png' if mode == 'icon' else f'thumbnails/thumb-ropilot{SUF}-{lang}.png'), optimize=True)
print('ok', mode)
