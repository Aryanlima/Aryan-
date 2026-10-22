# Fish & Fortune: kit de piezas del mundo (estilo cartoon saturado). Uso: exec en el Blender de Ropilot.
# Despues: ropilot_blender_screenshot / ropilot_blender_import(collection=...) hacia Workspace.Extras.
import bpy, bmesh, math, random
from math import radians as R
random.seed(7)
COL = dict(trunk=(.55, .3, .12), trunk2=(.42, .22, .09), leaf=(.25, .85, .2), leaf2=(.1, .65, .25), leaf3=(.55, .95, .2),
  pine=(.05, .5, .3), pine2=(.1, .62, .35), rock=(.45, .5, .72), rock2=(.58, .55, .8), moss=(.3, .8, .3), coco=(.35, .17, .07),
  boat=(.95, .3, .25), boat2=(.98, .9, .75), wood=(.7, .45, .2), lamp=(1, .85, .3), glass=(.4, .95, 1), white=(.97, .97, 1),
  red=(.95, .15, .18), roof=(.2, .25, .55), pink=(1, .35, .85), cyan=(.3, 1, 1), purple=(.6, .35, 1), sand=(1, .85, .5))
M = {}
def mat(n):
    if n not in M:
        m = bpy.data.materials.new('mk_' + n); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
        b.inputs['Base Color'].default_value = (*[c ** 2.2 for c in COL[n]], 1); b.inputs['Roughness'].default_value = .55
        m.diffuse_color = b.inputs['Base Color'].default_value; M[n] = m
    return M[n]
def fresh(name):
    c = bpy.data.collections.get(name)
    if c:
        for o in list(c.objects): bpy.data.objects.remove(o)
        bpy.data.collections.remove(c)
    c = bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c)
    bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[name]
    return c
def fin(o, m, smooth=True):
    o.data.materials.clear(); o.data.materials.append(mat(m))
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    return o
def ico(loc, r, m, sc=(1, 1, 1), rot=(0, 0, 0), sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=loc, rotation=rot); o = bpy.context.object; o.scale = sc; return fin(o, m)
def cyl(loc, r1, r2, d, m, rot=(0, 0, 0), v=12):
    bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r1, radius2=r2, depth=d, location=loc, rotation=rot); return fin(bpy.context.object, m)
def box(loc, sc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot); o = bpy.context.object; o.scale = sc
    b = o.modifiers.new('b', 'BEVEL'); b.width = .08; b.segments = 2; return fin(o, m, False)
def finish(name):
    # une por material para importar rapido; aplica modificadores
    c = bpy.data.collections[name]
    objs = [o for o in c.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]; bpy.ops.object.convert(target='MESH')
    groups = {}
    for o in [o for o in c.objects if o.type == 'MESH']: groups.setdefault(o.data.materials[0].name, []).append(o)
    for k, g in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in g: o.select_set(True)
        bpy.context.view_layer.objects.active = g[0]
        if len(g) > 1: bpy.ops.object.join()
        bpy.context.object.name = name + '_' + k
    # base en z=0 y centrado en x/y
    allm = [o for o in c.objects if o.type == 'MESH']
    zs = [(o.matrix_world @ v.co).z for o in allm for v in o.data.vertices]
    for o in allm: o.location.z -= min(zs)

# ---- Palmera
fresh('Palm')
pts = [(0, 0, 0)]
for i in range(1, 9):
    t = i / 8; pts.append((math.sin(t * 1.2) * 3.2, 0, t * 15))
for i in range(8):
    a, b = pts[i], pts[i + 1]; mid = ((a[0] + b[0]) / 2, 0, (a[2] + b[2]) / 2)
    ang = math.atan2(b[0] - a[0], b[2] - a[2])
    cyl(mid, 1.15 - i * .07, 1.05 - (i + 1) * .07, 2.1, 'trunk' if i % 2 else 'trunk2', (0, ang, 0))
top = pts[-1]
ico((top[0], 0, top[2] + .4), 1.1, 'trunk2')
for k in range(8):
    az = k * math.tau / 8; col = 'leaf' if k % 2 else 'leaf2'
    for j in range(3):
        d = 2.2 + j * 2.2; droop = j * .9
        ico((top[0] + math.cos(az) * d, math.sin(az) * d, top[2] + 1.2 - droop), 1.5, col, (3.1, 1.5, .3), (0, R(18 * j), az), 1)
for k in range(3): ico((top[0] + math.cos(k * 2.1) * 1.3, math.sin(k * 2.1) * 1.3, top[2] - .4), .65, 'coco')
finish('Palm')
# ---- Arbol redondo
fresh('RoundTree')
cyl((0, 0, 4), 1.5, 1.0, 9, 'trunk'); cyl((0, 0, 1), 2.2, 1.5, 2, 'trunk2')
for p, r, m in [((0, 0, 11.5), 6.5, 'leaf'), ((-4, 1.5, 9.5), 4.6, 'leaf2'), ((4, -1, 10), 5, 'leaf3'), ((.5, -4, 9.5), 4.2, 'leaf'), ((0, 3.5, 13.5), 3.8, 'leaf3')]:
    ico(p, r, m, (1, 1, .88))
finish('RoundTree')
# ---- Pino
fresh('Pine')
cyl((0, 0, 2.2), 1.1, .8, 4.4, 'trunk')
for i, (z, r, h) in enumerate([(5, 6, 6), (9, 4.8, 5.5), (13, 3.6, 5), (16.5, 2.3, 4.5)]):
    cyl((0, 0, z + h / 2 - 1), r, .05, h, 'pine' if i % 2 else 'pine2', v=14)
finish('Pine')
# ---- Rocas
fresh('Rocks')
for p, r, sc, m in [((0, 0, 3), 5, (1.2, 1, .8), 'rock'), ((5.5, 1.5, 2), 3.6, (1, 1.2, .85), 'rock2'), ((-5, -1.5, 1.8), 3.2, (1.1, 1, .9), 'rock'), ((2, -4.5, 1.2), 2.2, (1, 1, .8), 'rock2'), ((-2.5, 4, 1.4), 2.4, (1.2, 1, .8), 'rock')]:
    ico(p, r, m, sc, (random.random(), random.random(), random.random()), 1)
ico((0, 0, 5.6), 3.2, 'moss', (1.3, 1.1, .4), (0, 0, 0), 1)
finish('Rocks')
# ---- Bote
fresh('Rowboat')
bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1, location=(0, 0, 0)); h = bpy.context.object
bm = bmesh.new(); bm.from_mesh(h.data)
bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z > .1], context='VERTS'); bm.to_mesh(h.data); bm.free()
h.scale = (5.2, 2.4, 2.4); h.location.z = 2.4
s = h.modifiers.new('s', 'SOLIDIFY'); s.thickness = .25; s.offset = 1
fin(h, 'boat')
band = ico((0, 0, 2.2), 1, 'boat2', (5.25, 2.45, .15), (0, 0, 0), 2)
for x in (-1.8, 0, 1.8): box((x, 0, 1.4), (.4, 4.2, .3), 'wood')
cyl((4.6, 0, 3.6), .12, .12, 2.6, 'wood'); ico((4.6, 0, 5.1), .5, 'lamp')
finish('Rowboat')
# ---- Cristales
fresh('Crystals')
for k, (x, y, h, r, tilt, m) in enumerate([(0, 0, 20, 3.2, 0, 'pink'), (-4, 1, 13, 2.4, 14, 'cyan'), (4, 1.5, 15, 2.6, -12, 'purple'), (-6.5, -1, 8, 1.8, 24, 'cyan'), (6.8, -.5, 9.5, 2, -22, 'pink'), (1.5, 4, 7, 1.6, 8, 'purple'), (-2, -4, 6, 1.5, -10, 'cyan')]):
    cyl((x, y, h / 2), r, .05, h, m, (R(tilt), R(tilt / 2), 0), v=6)
finish('Crystals')
# ---- Faro
fresh('Lighthouse')
for i, (z, r) in enumerate([(0, 6.2), (1.6, 5.7), (3.2, 5.2)]): ico((0, 0, 1 + i * 1.2), r, 'rock' if i % 2 == 0 else 'rock2', (1, 1, .55), (0, 0, i), 1)
for i in range(6):
    z0 = 4 + i * 4.4; r0 = 4.8 - i * .42; r1 = r0 - .42
    cyl((0, 0, z0 + 2.2), r0, r1, 4.4, 'red' if i % 2 == 0 else 'white', v=20)
cyl((0, 0, 31.4), 4.6, 4.6, .6, 'roof', v=20)
cyl((0, 0, 33.4), 2.8, 2.8, 3.4, 'glass', v=16); ico((0, 0, 33.4), 1.9, 'lamp')
cyl((0, 0, 36.4), 3.8, .1, 2.8, 'roof', v=16); ico((0, 0, 38.2), .4, 'lamp')
finish('Lighthouse')
# colocar lado a lado para revisar
for i, n in enumerate(['Palm', 'RoundTree', 'Pine', 'Rocks', 'Rowboat', 'Crystals', 'Lighthouse']):
    for o in bpy.data.collections[n].objects: o.location.x += i * 24
result = [c.name for c in bpy.data.collections if c.name in ('Palm', 'RoundTree', 'Pine', 'Rocks', 'Rowboat', 'Crystals', 'Lighthouse')]
