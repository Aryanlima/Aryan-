# Fish & Fortune: kit del muelle y props con formas suaves (bordes redondeados, madera con curvatura, colores vivos).
# Uso: exec en el Blender de Ropilot; despues ropilot_blender_render / ropilot_blender_import(collection=...) hacia Workspace.Extras.Kit.
import bpy, bmesh, math, random
from math import radians as R
random.seed(11)
COL = dict(plank=(.95, .6, .28), plank2=(.85, .48, .2), post=(.55, .3, .13), rope=(.95, .85, .55), metal=(.55, .6, .7), red=(.95, .25, .25),
  teal=(.2, .75, .85), lamp=(1, .85, .35), glass=(1, .95, .6), roof=(.9, .3, .25), roof2=(.98, .75, .25), wall=(1, .85, .6), dark=(.3, .17, .08),
  board=(1, .88, .62), pink=(1, .45, .55), green=(.3, .85, .3))
M = {}
def mat(n):
    if n not in M:
        m = bpy.data.materials.new('mp_' + n); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
        b.inputs['Base Color'].default_value = (*[c ** 2.2 for c in COL[n]], 1); b.inputs['Roughness'].default_value = .5
        m.diffuse_color = b.inputs['Base Color'].default_value; M[n] = m
    return M[n]
def fresh(name):
    c = bpy.data.collections.get(name)
    if c:
        for o in list(c.objects): bpy.data.objects.remove(o)
        bpy.data.collections.remove(c)
    c = bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c)
    bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[name]
def fin(o, m, bevel=0.0, smooth=True, sub=0):
    o.data.materials.clear(); o.data.materials.append(mat(m))
    if bevel:
        b = o.modifiers.new('b', 'BEVEL'); b.width = bevel; b.segments = 4; b.limit_method = 'NONE'
    if sub: o.modifiers.new('s', 'SUBSURF').levels = sub
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    return o
def box(loc, sc, m, rot=(0, 0, 0), bevel=.12, sub=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot); o = bpy.context.object; o.scale = sc
    bpy.ops.object.transform_apply(scale=True); return fin(o, m, bevel, True, sub)
def cyl(loc, r, d, m, rot=(0, 0, 0), v=20, bevel=.06):
    bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=d, location=loc, rotation=rot); return fin(bpy.context.object, m, bevel)
def sph(loc, r, m, sc=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=r, location=loc); o = bpy.context.object; o.scale = sc; return fin(o, m)
def cone(loc, r1, r2, d, m, v=20, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r1, radius2=r2, depth=d, location=loc, rotation=rot); return fin(bpy.context.object, m, .05)
def finish(name):
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
    allm = [o for o in c.objects if o.type == 'MESH']
    zs = [(o.matrix_world @ v.co).z for o in allm for v in o.data.vertices]
    for o in allm: o.location.z -= min(zs)

# ---- Muelle: 6 tablones gruesos con borde redondeado, 4 postes redondos, barandas con cuerda
fresh('Pier')
for i in range(8):
    box((0, i * 1.5 - 5.2, 1.2), (7.2, 1.4, .5), 'plank' if i % 2 else 'plank2', (0, 0, R(random.uniform(-1.2, 1.2))), .18)
for sx in (-3.5, 3.5):
    for j in range(4):
        y = -4.4 + j * 3.4
        cyl((sx, y, .2), .45, 3.4, 'post'); sph((sx, y, 1.95), .55, 'post')
        cyl((sx, y, 2.9), .22, 1.9, 'post')
    box((sx, 0, 2.55), (.3, 12.4, .3), 'plank2', (0, 0, 0), .1)
    for k in range(4):
        cyl((sx, -3.2 + k * 3.2, 3.5), .28, .28, 'rope', v=12)
finish('Pier')
# ---- Cartel con arco, dos postes y cuerda
fresh('Sign')
for sx in (-3.2, 3.2): cyl((sx, 0, 3.6), .45, 7.2, 'post'); sph((sx, 0, 7.3), .62, 'post')
bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=3.7, depth=.55, location=(0, 0, 5.2)); b = bpy.context.object
b.scale = (1, 1, .62); b.rotation_euler = (R(90), 0, 0); bpy.ops.object.transform_apply(scale=True, rotation=True); fin(b, 'board', .12)
box((0, 0, 4.1), (6.6, .55, 2.2), 'board', (0, 0, 0), .2)
box((0, -.34, 4.1), (6.9, .2, 2.5), 'dark', (0, 0, 0), .15)
for sx in (-1.6, 0, 1.6): sph((sx, -.5, 5.5), .26, 'lamp')
sph((0, -.55, 7.6), .5, 'red')
finish('Sign')
# ---- Barril
fresh('Barrel')
bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.4, location=(0, 0, 1.6)); o = bpy.context.object; o.scale = (1, 1, 1.15)
bpy.ops.object.transform_apply(scale=True); fin(o, 'plank2')
for z in (.7, 1.6, 2.5):
    t = (1 - ((z - 1.6) / 1.9) ** 2) ** .5 * 1.4 + .04; bpy.ops.mesh.primitive_torus_add(major_radius=t, minor_radius=.1, location=(0, 0, z)); fin(bpy.context.object, 'metal')
cyl((0, 0, 3.15), 1.05, .15, 'plank')
finish('Barrel')
# ---- Caja
fresh('Crate')
box((0, 0, 1.1), (2.2, 2.2, 2.2), 'plank', (0, 0, 0), .2)
for s in (-1, 1):
    box((0, s * 1.12, 1.1), (2.0, .16, .4), 'dark', (0, 0, R(0)), .06); box((s * 1.12, 0, 1.1), (.16, 2.0, .4), 'dark', (0, 0, 0), .06)
box((0, 0, 2.25), (2.1, 2.1, .2), 'plank2', (0, 0, 0), .08)
finish('Crate')
# ---- Farol de muelle
fresh('Lantern')
cyl((0, 0, 2.2), .25, 4.4, 'post'); sph((0, 0, .15), .7, 'post', (1, 1, .5))
box((0, 0, 4.8), (1.5, 1.5, 1.6), 'glass', (0, 0, 0), .25); sph((0, 0, 4.8), .6, 'lamp')
cone((0, 0, 6.0), 1.3, .15, 1.1, 'roof', 16); sph((0, 0, 6.7), .22, 'lamp')
finish('Lantern')
# ---- Caseta de carnada
fresh('Hut')
box((0, 0, 2.3), (7, 6, 4.6), 'wall', (0, 0, 0), .35)
for k in range(5): box((-3.3 + k * 1.65, -3.05, 2.3), (.18, .2, 4.4), 'plank2', (0, 0, 0), .05)
bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=6.2, radius2=.3, depth=3.6, location=(0, 0, 6.4), rotation=(0, 0, R(45))); r = bpy.context.object
r.scale = (1.0, .85, 1); bpy.ops.object.transform_apply(scale=True); fin(r, 'roof', .08, False)
box((0, -3.2, 2.0), (1.8, .25, 3.2), 'dark', (0, 0, 0), .1); box((-2.1, -3.15, 2.6), (1.4, .2, 1.4), 'teal', (0, 0, 0), .1); box((2.1, -3.15, 2.6), (1.4, .2, 1.4), 'teal', (0, 0, 0), .1)
sph((0, -3.5, 4.4), .35, 'lamp'); box((0, -3.6, 3.7), (2.6, .15, .6), 'board', (0, 0, 0), .1)
finish('Hut')
for i, n in enumerate(['Pier', 'Sign', 'Barrel', 'Crate', 'Lantern', 'Hut']):
    for o in bpy.data.collections[n].objects: o.location.x += i * 16
result = ['Pier', 'Sign', 'Barrel', 'Crate', 'Lantern', 'Hut']
