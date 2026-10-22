# Fish & Fortune: icono 1024 y miniatura 1920x1080 (Blender Workbench FLAT). Uso: exec en Blender via Ropilot.
import bpy, math
from math import radians as R, sin, cos, sqrt
OUT = 'C:/Users/Administrator/Desktop/Aryan-/ROBLOX/.toolchain/ropilot/'
try: RENDER
except NameError: RENDER = ('icon', 'thumb')
M = {}
C = dict(gold=(1, .58, .02), orange=(1, .42, .03), dorange=(.9, .27, .02), cream=(1, .93, .55), white=(1, 1, 1), black=(.03, .02, .08),
  water=(.05, .55, 1), deep=(.02, .3, .8), foam=(.9, .98, 1), coral=(1, .35, .42), mouth=(.5, .02, .1), tongue=(1, .45, .55),
  magenta=(1, .3, .45), purple=(.42, .18, .72), ray=(1, .6, .28), sun=(1, .97, .72), halo=(1, .85, .4), wood=(.62, .34, .12), wood2=(.45, .22, .08),
  hill=(.38, .15, .6), hill2=(.55, .2, .62), star=(1, 1, .7), pink=(1, .55, .7))
def mat(n):
    if n not in M:
        m = bpy.data.materials.new(n); c = C[n]; m.diffuse_color = (c[0] ** 2.2, c[1] ** 2.2, c[2] ** 2.2, 1); M[n] = m
    return M[n]
def parent(o, p):
    if p: o.parent = p
    return o
def S(loc, sc, m, p=None, r=1, rot=(0, 0, 0), seg=40):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=r, location=loc)
    o = bpy.context.object; o.scale = sc; o.rotation_euler = rot; o.data.materials.append(mat(m)); return parent(o, p)
def B(loc, sc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc); o = bpy.context.object
    o.scale = sc; o.rotation_euler = rot; o.data.materials.append(mat(m)); return o
def Cyl(loc, r, d, m, rot=(0, 0, 0), v=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=d, location=loc); o = bpy.context.object
    o.rotation_euler = rot; o.data.materials.append(mat(m)); return o
def P(pts, y, m, p=None, th=0.0, rot=(0, 0, 0), x0=0, z0=0):
    me = bpy.data.meshes.new('p'); me.from_pydata([(x + x0, 0, z + z0) for x, z in pts], [], [list(range(len(pts)))]); me.update()
    o = bpy.data.objects.new('p', me); bpy.context.collection.objects.link(o); o.location = (0, y, 0); o.rotation_euler = rot
    o.data.materials.append(mat(m))
    if th:
        s = o.modifiers.new('s', 'SOLIDIFY'); s.thickness = th; s.offset = 0
    return parent(o, p)
def star(cx, cz, r, y, m='star'):
    pts = []
    for i in range(8):
        a = i * math.pi / 4; rr = r if i % 2 == 0 else r * .22; pts.append((rr * cos(a + math.pi / 2), rr * sin(a + math.pi / 2)))
    return P(pts, y, m, x0=cx, z0=cz)

def build(mode):
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
    thumb = mode == 'thumb'
    # fondo
    B((0, 9, 4), (70, .2, 30), 'magenta')
    B((0, 8.8, 12.5), (70, .2, 9), 'purple')
    for x, z, w in [(-5, 7.2, 3), (3, 7.8, 3.6), (9, 7.0, 2.8), (-10, 7.6, 3.2)]:
        S((x, 8.5, z), (w, .1, .8), 'pink')
    for i in range(20):
        a0 = i * 2 * math.pi / 20; a1 = a0 + math.pi / 20
        P([(0, 0), (30 * cos(a0), 30 * sin(a0)), (30 * cos(a1), 30 * sin(a1))], 8, 'ray', x0=0, z0=4.8)
    S((0, 7.5, 4.8), (1, .1, 1), 'halo', r=3.9); S((0, 7.4, 4.8), (1, .1, 1), 'sun', r=2.9)
    if thumb:
        S((11, 6, 1.0), (7, 1, 1.9), 'hill'); S((-4, 6.5, .6), (6, 1, 1.4), 'hill2'); S((6, 5.5, 0.9), (4, 1, 1), 'hill2')
    # agua
    B((0, -1, -.6), (60, 6, 3), 'water'); B((0, -3.6, -.9), (60, 1, 3), 'deep')
    for x in range(-16, 17, 2):
        S((x * 0.8 + .4, -2.45, .95), (.8, .5, .22), 'foam')
    for x in range(-15, 16, 3):
        S((x * 0.8, -4.2, .15), (1.1, .1, .12), 'foam')
    if thumb:
        for x in (4.6, 6.4, 8.2, 10.0):
            for yy in (-1.6, .8): Cyl((x, yy, .4), .13, 2.2, 'wood2')
        B((8, -.4, 1.35), (7.6, 2.5, .22), 'wood')
        for x in range(0, 16): B((4.4 + x * .5, -.4, 1.47), (.04, 2.5, .05), 'wood2')
        for x in (4.6, 10.0): Cyl((x, -1.6, 1.9), .12, 1.0, 'wood2')
    # salpicadura
    cx, cz = -2.8, 1.0
    S((cx, -.2, cz), (2.6, 1.2, .75), 'foam')
    for i in range(14):
        a = i * 2 * math.pi / 14; px, py = cx + 2.3 * cos(a), -.2 + 1.1 * sin(a)
        bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=.34, depth=1.5 + .5 * (i % 2), location=(px, py, cz + .7))
        c = bpy.context.object; c.data.materials.append(mat('foam')); c.rotation_euler = (0, R(25) * cos(a), 0)
        S((cx + 3.0 * cos(a), -.8 + 1.3 * sin(a) - .5, cz + 1.7 + .5 * (i % 3)), (1, 1, 1), 'foam', r=.16 + .06 * (i % 3))
    for x, z, r in [(-4.6, 3.3, .26), (-4.9, 1.8, .18), (1.6, 2.2, .24), (2.4, 3.1, .17), (.4, 1.8, .2)]:
        S((x, -1.4, z), (1, 1, 1), 'foam', r=r)
    # pez
    f = bpy.data.objects.new('fish', None); bpy.context.collection.objects.link(f)
    f.location = (.5, 0, 4.2); f.rotation_euler = (0, R(-30), R(-35)); f.scale = (1.3, 1.3, 1.3)
    S((0, 0, 0), (2.3, .95, 1.35), 'gold', f, seg=64)
    S((.2, -.14, -.55), (2.0, .86, .75), 'cream', f, seg=48)
    for x in (-1.3, -.7, -.1, .5):
        for z in (.35, -.1):
            if (x * x) / 5.29 + z * z / 1.82 > .8: continue
            ys = -.95 * sqrt(1 - x * x / 5.29 - z * z / 1.82) * .98
            S((x, ys, z), (1, .3, 1), 'cream', f, r=.17, seg=16)
    S((1.1, -.8, -.3), (1, .25, .75), 'coral', f, r=.3, seg=16)
    # cola y aletas
    P([(-1.7, .4), (-2.8, 1.35), (-3.9, 2.1), (-3.5, .7), (-3.2, 0), (-3.5, -.7), (-3.9, -2.1), (-2.8, -1.35), (-1.7, -.4)], 0, 'orange', f, .14)
    P([(-1.9, .2), (-2.9, .8), (-3.3, 0), (-2.9, -.8), (-1.9, -.2)], -.09, 'gold', f, .06)
    P([(1.0, 1.0), (.6, 2.0), (-.4, 2.3), (-1.1, 1.8), (-1.7, .7)], 0, 'orange', f, .14)
    P([(.4, -.1), (-.2, .1), (-.9, -.5), (-.4, -.95), (.2, -.7)], -.95, 'dorange', f, .1)
    P([(.3, -1.0), (-.2, -2.0), (-1.1, -1.9), (-.9, -.9)], 0, 'orange', f, .12)
    # ojos
    for s in (-1, 1):
        S((1.45, s * .72, .85), (1, 1, 1), 'white', f, r=.55)
        S((1.85, s * .84, .9), (1, 1, 1), 'black', f, r=.33)
        S((2.0, s * .86, 1.08), (1, 1, 1), 'white', f, r=.12, seg=16)
    # boca abierta
    S((2.0, 0, -.15), (.45, .75, .55), 'mouth', f)
    S((2.2, 0, -.45), (.25, .45, .22), 'tongue', f)
        # destellos y monedas
    for x, z, r, yy in [(3.8, 6.8, .7, -2), (-4.2, 6.0, .5, -2), (3.3, 2.8, .45, -2), (-4.6, 4.6, .4, -2)]:
        star(x, z, r, yy)
    for x, z in [(4.3, 3.4), (-4.3, 7.6)]:
        Cyl((x, -2.2, z), .62, .16, 'dorange', (R(90), 0, 0)); Cyl((x, -2.31, z), .5, .16, 'gold', (R(90), 0, 0))
    # camara
    bpy.ops.object.camera_add(location=(0, -20, 3.8)); cam = bpy.context.object
    cam.rotation_euler = (R(90), 0, 0); cam.data.type = 'ORTHO'
    if thumb: cam.location = (3.3, -20, 3.9); cam.data.ortho_scale = 16
    else: cam.data.ortho_scale = 11
    bpy.context.scene.camera = cam

def render(mode):
    sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'
    sh = sc.display.shading; sh.light = 'FLAT'; sh.color_type = 'MATERIAL'; sh.show_object_outline = True; sh.object_outline_color = (.04, .02, .12)
    sc.display.render_aa = '32'; sc.render.film_transparent = False
    sc.view_settings.view_transform = 'Standard'
    sc.render.resolution_x, sc.render.resolution_y = (1920, 1080) if mode == 'thumb' else (1024, 1024)
    sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = 'PNG'
    sc.render.filepath = OUT + ('miniatura-final.png' if mode == 'thumb' else 'icono-final.png')
    bpy.ops.render.render(write_still=True)

for m in RENDER:
    build(m); render(m)
print('ok', RENDER)
