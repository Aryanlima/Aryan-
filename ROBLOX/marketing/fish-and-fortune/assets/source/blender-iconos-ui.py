# Fish & Fortune: iconos 3D del HUD, uno por coleccion. Despues: ropilot_blender_render(items=ICONS, style='ultrabright', folder='FishFortuneUI').
import bpy, math
from math import radians as R
from mathutils import Vector
ICONS = ['Coin', 'Pearl', 'Bag', 'Shop', 'Rods', 'Bestiary', 'Season', 'Odds', 'Codes', 'Settings', 'Cast', 'Sell']
P = dict(gold=(1, .78, .24), gold2=(.95, .55, .05), white=(1, 1, 1), pearl=(1, .95, .97), shell=(1, .55, .65), shell2=(.95, .4, .5),
  wood=(.79, .54, .29), wood2=(.55, .34, .16), fish=(1, .62, .1), red=(1, .3, .32), navy=(.12, .16, .27), cream=(1, .93, .7),
  green=(.43, .82, .5), blue=(.35, .63, 1), purple=(.7, .43, 1), steel=(.62, .7, .8), teal=(.18, .77, .95), sack=(.86, .68, .42))
MT = {}
def mat(n):
    if n not in MT:
        m = bpy.data.materials.new('ui_' + n); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
        b.inputs['Base Color'].default_value = (*[c ** 2.2 for c in P[n]], 1); b.inputs['Roughness'].default_value = .35
        m.diffuse_color = b.inputs['Base Color'].default_value; MT[n] = m
    return MT[n]
for name in ICONS:
    old = bpy.data.collections.get(name)
    if old:
        for o in list(old.objects): bpy.data.objects.remove(o)
        bpy.data.collections.remove(old)
def start(name):
    c = bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c)
    bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[name]
def fin(o, m, bevel=0, smooth=True):
    o.data.materials.append(mat(m))
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    if bevel:
        b = o.modifiers.new('b', 'BEVEL'); b.width = bevel; b.segments = 3
    return o
def cyl(loc, r, d, m, rot=(0, 0, 0), v=48, bevel=.03):
    bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=d, location=loc, rotation=rot); return fin(bpy.context.object, m, bevel)
def cone(loc, r1, r2, d, m, rot=(0, 0, 0), v=48):
    bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r1, radius2=r2, depth=d, location=loc, rotation=rot); return fin(bpy.context.object, m, .03)
def ball(loc, r, m, sc=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=r, location=loc); o = bpy.context.object; o.scale = sc; return fin(o, m)
def box(loc, sc, m, rot=(0, 0, 0), bevel=.06):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot); o = bpy.context.object; o.scale = sc; return fin(o, m, bevel / max(min(sc), .05), smooth=False)
def torus(loc, r, t, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=t, location=loc, rotation=rot); return fin(bpy.context.object, m)
def star(loc, r, d, m, rot=(R(90), 0, 0)):
    pts = [(r * (1 if i % 2 == 0 else .45) * math.cos(math.pi / 2 + i * math.pi / 5), r * (1 if i % 2 == 0 else .45) * math.sin(math.pi / 2 + i * math.pi / 5)) for i in range(10)]
    me = bpy.data.meshes.new('star'); me.from_pydata([(x, y, 0) for x, y in pts], [], [list(range(10))]); me.update()
    o = bpy.data.objects.new('star', me); bpy.context.collection.objects.link(o); o.location = loc; o.rotation_euler = rot
    s = o.modifiers.new('s', 'SOLIDIFY'); s.thickness = d; s.offset = 0; return fin(o, m, .02, smooth=False)
def fishshape(loc, s, m, rot=(R(90), 0, 0)):
    ball((loc[0], loc[1], loc[2]), .5 * s, m, (1.4, .45, .9))
    me = bpy.data.meshes.new('tail'); me.from_pydata([(-.55 * s, 0, 0), (-1.05 * s, 0, .45 * s), (-1.05 * s, 0, -.45 * s)], [], [[0, 1, 2]]); me.update()
    o = bpy.data.objects.new('tail', me); bpy.context.collection.objects.link(o); o.location = loc
    sd = o.modifiers.new('s', 'SOLIDIFY'); sd.thickness = .12 * s; sd.offset = 0; return fin(o, m)

def coin_icon(loc=(0, 0, 0), r=1.0, tilt=R(70)):
    cyl(loc, r, .28 * r, 'gold2', (tilt, 0, 0)); cyl(loc, r * .8, .34 * r, 'gold', (tilt, 0, 0))
    star((loc[0], loc[1] - .19 * r * math.sin(tilt), loc[2] + .19 * r * math.cos(tilt)), .45 * r, .08 * r, 'gold2', (tilt, 0, 0))

start('Coin'); coin_icon()
start('Pearl')
ball((0, .1, -.25), 1.1, 'shell', (1, .9, .35)); ball((0, .55, .45), 1.05, 'shell2', (1, .3, .8))
for i in range(5): box((-.6 + i * .3, .1, -.2), (.06, .9, .06), 'shell2', bevel=.02)
ball((0, -.05, .2), .55, 'pearl')
start('Bag')
cone((0, 0, 0), .78, 1.0, 1.4, 'wood'); torus((0, 0, .7), 1.0, .08, 'wood2'); torus((0, 0, -.2), .9, .06, 'wood2')
torus((0, 0, .85), .75, .05, 'steel', (R(90), 0, 0))
fishshape((.15, 0, 1.05), .9, 'fish', (R(90), R(-60), 0))
start('Shop')
box((0, 0, -.25), (2, 1.3, 1.1), 'wood'); cyl((0, 0, .3), .65, 2, 'wood2', (0, R(90), 0))
for x in (-.7, .7): box((x, 0, 0), (.18, 1.36, 1.7), 'gold', bevel=.03)
box((0, -.66, .15), (.4, .12, .45), 'gold'); ball((0, -.73, .1), .1, 'navy')
for x, z in ((-.35, .95), (.25, 1.05), (.0, .85)): coin_icon((x, -.1, z), .3, R(80))
start('Rods')
cyl((0, 0, .2), .07, 3.2, 'navy', (0, R(40), 0)); cyl((-.8, 0, -.75), .12, .8, 'wood', (0, R(40), 0))
cyl((-.55, -.2, -.55), .28, .22, 'steel', (R(90), 0, 0)); cyl((-.55, -.33, -.55), .12, .08, 'red', (R(90), 0, 0))
ball((1.15, 0, -.45), .32, 'red'); ball((1.15, 0, -.53), .3, 'white', (1, 1, .7)); cyl((1.15, 0, -.1), .04, .3, 'navy')
cyl((1.1, 0, .75), .015, 1.75, 'white', v=8, bevel=0)
start('Bestiary')
box((0, 0, 0), (1.5, .32, 1.9), 'teal', bevel=.05); box((.04, .02, 0), (1.42, .26, 1.78), 'cream', bevel=.02)
box((-.72, 0, 0), (.14, .36, 1.92), 'navy', bevel=.03); fishshape((.1, -.2, .05), .55, 'gold')
start('Season')
cone((0, 0, .45), .75, .42, 1.0, 'gold', (R(180), 0, 0)); ball((0, 0, .95), .75, 'gold', (1, 1, .25))
for s in (-1, 1): torus((s * .78, 0, .55), .28, .07, 'gold', (R(90), 0, 0))
cyl((0, 0, -.25), .14, .4, 'gold2'); box((0, 0, -.6), (1, .7, .3), 'navy'); star((0, -.48, .5), .3, .06, 'cream')
start('Odds')
for m, a0, a1 in (('blue', 0, 150), ('green', 150, 250), ('purple', 250, 320), ('gold', 320, 360)):
    n = 24; ring = [(1.05 * math.cos(R(a0 + (a1 - a0) * i / n)), 1.05 * math.sin(R(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]
    pts = [(0, 0)] + ring; vs = [(x, y, z) for z in (-.17, .17) for x, y in pts]; k = len(pts)
    faces = [list(range(k))[::-1], [i + k for i in range(k)]] + [[i, i + 1, i + 1 + k, i + k] for i in range(k - 1)] + [[k - 1, 0, k, 2 * k - 1]]
    me = bpy.data.meshes.new('wedge'); me.from_pydata(vs, [], faces); me.update()
    o = bpy.data.objects.new('wedge', me); bpy.context.collection.objects.link(o); fin(o, m, .03, smooth=False)
    am = R((a0 + a1) / 2); off = .14 if m == 'gold' else .03
    o.rotation_euler = (R(65), 0, 0); o.location = o.rotation_euler.to_matrix() @ Vector((off * math.cos(am), off * math.sin(am), 0))
start('Codes')
box((0, 0, -.2), (1.5, 1.5, 1.1), 'red'); box((0, 0, .45), (1.65, 1.65, .32), 'red')
box((0, 0, .1), (.28, 1.7, 1.5), 'gold', bevel=.02); box((0, 0, .1), (1.7, .28, 1.5), 'gold', bevel=.02)
for s in (-1, 1): torus((s * .32, 0, .78), .3, .1, 'gold', (R(90), R(s * 25), 0))
start('Settings')
cyl((0, 0, 0), .8, .4, 'steel', (R(90), 0, 0), v=64)
for i in range(8):
    a = i * math.tau / 8; box((.95 * math.cos(a), 0, .95 * math.sin(a)), (.42, .4, .36), 'steel', (0, -a, 0), bevel=.04)
cyl((0, -.05, 0), .35, .5, 'navy', (R(90), 0, 0))
start('Cast')
ball((0, 0, .32), .85, 'red', (1, 1, .9)); ball((0, 0, -.05), .82, 'white', (1, 1, .75)); torus((0, 0, .1), .83, .06, 'navy')
cyl((0, 0, 1.35), .07, .8, 'navy'); ball((0, 0, 1.75), .14, 'gold')
start('Sell')
ball((0, 0, 0), 1, 'sack', (1, 1, .95)); cone((0, 0, .95), .32, .55, .5, 'sack'); torus((0, 0, .8), .34, .08, 'wood2')
star((0, -.98, .05), .45, .1, 'gold')
for x, z in ((.95, -.55), (1.25, -.75)): coin_icon((x, -.3, z), .32, R(75))
result = ICONS
