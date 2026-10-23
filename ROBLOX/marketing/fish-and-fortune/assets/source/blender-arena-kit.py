# arrow-rogue: kit de la arena (formas redondeadas, paleta saturada, acabado de icono). Uso: exec en el Blender de Ropilot.
# Despues: ropilot_blender_render para revisar y ropilot_blender_import(collection=...) a Workspace.Extras.Kit del juego.
import bpy, bmesh, math, random
from math import radians as R
random.seed(5)
COL = dict(grass=(.38, .85, .3), grass2=(.28, .72, .26), dirt=(.62, .4, .2), stone=(.62, .66, .85), stone2=(.5, .55, .78), moss=(.3, .82, .35),
  wall=(.72, .62, .9), cap=(1, .85, .45), wood=(.75, .48, .22), red=(.95, .3, .3), teal=(.2, .85, .85), lamp=(1, .88, .4), white=(.97, .97, 1), dark=(.28, .24, .4),
  leaf=(.25, .8, .3), trunk=(.55, .3, .12))
M = {}
def mat(n):
    if n not in M:
        m = bpy.data.materials.new('ar_' + n); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
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
def fin(o, m, bevel=.0, sub=0, smooth=True):
    o.data.materials.clear(); o.data.materials.append(mat(m))
    if bevel:
        b = o.modifiers.new('b', 'BEVEL'); b.width = bevel; b.segments = 3; b.limit_method = 'NONE'
    if sub: o.modifiers.new('s', 'SUBSURF').levels = sub
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    return o
def box(loc, sc, m, rot=(0, 0, 0), bevel=.25):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot); o = bpy.context.object; o.scale = sc
    bpy.ops.object.transform_apply(scale=True); return fin(o, m, bevel)
def cyl(loc, r, d, m, v=14, bevel=.1):
    bpy.ops.mesh.primitive_cylinder_add(vertices=v, radius=r, depth=d, location=loc); return fin(bpy.context.object, m, bevel)
def cone(loc, r1, r2, d, m, v=14):
    bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r1, radius2=r2, depth=d, location=loc); return fin(bpy.context.object, m, .08)
def ico(loc, r, m, sc=(1, 1, 1), sub=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=loc); o = bpy.context.object; o.scale = sc; return fin(o, m)
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

# Suelo 16x16: losa de pasto con borde de tierra redondeado y manchas (sin esferas como relieve)
fresh('FloorTile')
box((0, 0, -.6), (16, 16, 1.2), 'dirt', bevel=.5); box((0, 0, .15), (15.4, 15.4, .5), 'grass', bevel=.35)
for _ in range(7): box((random.uniform(-6, 6), random.uniform(-6, 6), .45), (random.uniform(1.4, 2.6), random.uniform(1.4, 2.6), .12), 'grass2', (0, 0, R(random.uniform(0, 90))), .1)
finish('FloorTile')
# Muro recto 16x2.5x3 con cornisa y piedras
fresh('WallSegment')
box((0, 0, 1.4), (16, 2.4, 2.8), 'wall', bevel=.45); box((0, 0, 3.0), (16.4, 3, .7), 'cap', bevel=.3)
for i in range(4): box((-6 + i * 4, -1.25, 1.4), (3.4, .3, 2.0), 'stone2', bevel=.15)
finish('WallSegment')
# Pilar de esquina
fresh('Pillar')
cyl((0, 0, 2.2), 1.6, 4.4, 'wall', v=16, bevel=.25); cyl((0, 0, 4.7), 2.1, .9, 'cap', v=16, bevel=.2); ico((0, 0, 5.7), .8, 'lamp')
finish('Pillar')
# Puerta de sala (arco)
fresh('Gate')
for s in (-1, 1): cyl((s * 3.4, 0, 3), 1.2, 6, 'wall', v=14, bevel=.2)
box((0, 0, 6.3), (9.4, 2, 1.6), 'cap', bevel=.4); box((0, 0, 3), (5.4, .6, 5.6), 'teal', bevel=.2)
finish('Gate')
# Roca redondeada baja (obstaculo)
fresh('RockObstacle')
for p, s in [((0, 0, 1.4), (3.2, 2.8, 1.5)), ((2.4, 1.2, 1.0), (2, 1.8, 1.1)), ((-2.2, -1, .9), (1.8, 1.6, 1.0))]:
    ico(p, 1, 'stone', s, 2)
ico((0, 0, 2.7), 1, 'moss', (2.2, 1.9, .45), 2)
finish('RockObstacle')
# Pilar de piedra con runa
fresh('Totem')
box((0, 0, 1.3), (2.4, 2.4, 2.6), 'stone2', bevel=.4); box((0, 0, 3.3), (2.0, 2.0, 1.4), 'stone', bevel=.35); ico((0, 0, 4.5), .6, 'teal')
finish('Totem')
# Arbol redondo pequeño para decorar bordes
fresh('BorderTree')
cyl((0, 0, 1.6), .6, 3.2, 'trunk', v=10, bevel=.08)
for p, r in [((0, 0, 4.2), 2.3), ((-1.4, .6, 3.4), 1.6), ((1.4, -.4, 3.5), 1.7)]: ico(p, r, 'leaf', (1, 1, .9), 2)
finish('BorderTree')
for i, n in enumerate(['FloorTile', 'WallSegment', 'Pillar', 'Gate', 'RockObstacle', 'Totem', 'BorderTree']):
    for o in bpy.data.collections[n].objects: o.location.x += i * 22
result = ['FloorTile', 'WallSegment', 'Pillar', 'Gate', 'RockObstacle', 'Totem', 'BorderTree']
