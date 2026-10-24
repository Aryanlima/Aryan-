# arrow-rogue: Nara (exploradora original) sobre el rig R15 de Ropilot. Antes: ropilot_blender_import_rig (sin argumentos).
# Despues: ropilot_blender_render(items=['NaraScene']) para revisar. Paleta: coral FF6F59, turquesa 2EC4B6, jade 3DA35D, amarillo FFC857, violeta 7B5EA7, noche 1B2A41.
import bpy, math
from math import radians as R
from mathutils import Matrix, Vector
def hexc(h): return tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
C = dict(skin=(1, .78, .6), coral=hexc('#FF6F59'), teal=hexc('#2EC4B6'), jade=hexc('#3DA35D'), gold=hexc('#FFC857'), violet=hexc('#7B5EA7'), night=hexc('#1B2A41'),
  hair=(.16, .1, .2), white=(1, 1, 1), wood=(.72, .46, .2), string=(.95, .95, .85), black=(.03, .02, .06), blush=(1, .5, .5))
M = {}
def mat(n):
    if n not in M:
        m = bpy.data.materials.new('nr_' + n); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
        b.inputs['Base Color'].default_value = (*[c ** 2.2 for c in C[n]], 1); b.inputs['Roughness'].default_value = .5
        m.diffuse_color = b.inputs['Base Color'].default_value; M[n] = m
    return M[n]
arm = bpy.data.objects['__RopilotDummy_Armature']
parts = {o.name.split('/')[-1].replace('.MeshPart', ''): o for o in bpy.data.objects if o.type == 'MESH' and o.name.startswith('RopilotDummy.model/')}
paint = {'Head': 'skin', 'UpperTorso': 'teal', 'LowerTorso': 'night', 'LeftUpperArm': 'teal', 'RightUpperArm': 'teal', 'LeftLowerArm': 'skin', 'RightLowerArm': 'skin',
         'LeftHand': 'skin', 'RightHand': 'skin', 'LeftUpperLeg': 'night', 'RightUpperLeg': 'night', 'LeftLowerLeg': 'night', 'RightLowerLeg': 'night', 'LeftFoot': 'coral', 'RightFoot': 'coral'}
for n, o in parts.items():
    o.data.materials.clear(); o.data.materials.append(mat(paint[n]))
for p in list(bpy.data.objects):
    if p.name.startswith('Nara_'): bpy.data.objects.remove(p)
col = bpy.data.collections.get('NaraScene') or bpy.data.collections.new('NaraScene')
if col.name not in bpy.context.scene.collection.children: bpy.context.scene.collection.children.link(col)
bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children['NaraScene']
for c in {parts['Head'].users_collection[0], arm.users_collection[0]}:
    if c.name not in col.children and c.name != 'NaraScene':
        try: col.children.link(c)
        except Exception: pass
def sm(o, m):
    o.data.materials.append(mat(m))
    for p in o.data.polygons: p.use_smooth = True
    return o
def ball(loc, r, m, sc=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=r, location=loc); o = bpy.context.object; o.scale = sc; o.name = 'Nara_' + m; return sm(o, m)
def cyl(loc, r, d, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=r, depth=d, location=loc, rotation=rot); o = bpy.context.object; o.name = 'Nara_' + m; return sm(o, m)
def bone(o, name):
    w = o.matrix_world.copy(); o.parent = arm; o.parent_type = 'BONE'; o.parent_bone = name; o.matrix_world = w
def wp(name): return parts[name].matrix_world @ Vector((0, 0, 0))
hb = [parts['Head'].matrix_world @ Vector(v) for v in parts['Head'].bound_box]
hx, hy, hz = (sum(v[i] for v in hb) / 8 for i in range(3)); top = max(v.z for v in hb); front = max(v.y for v in hb); w = max(v.x for v in hb) - min(v.x for v in hb)
acc = []
# cabello: casquete + flequillo + coleta
acc += [ball((hx, hy - .02, top - .28), w * .6, 'hair', (1, 1.02, .66)), ball((hx, front - .1, top - .5), w * .5, 'hair', (1, .3, .42))]
acc += [ball((hx - .05, hy - w * .6, top - .6), .3, 'hair', (.9, .9, 1.4)), ball((hx - .05, hy - w * .75, top - 1.2), .24, 'hair', (.8, .8, 1.5))]
# cinta turquesa y adorno
acc += [cyl((hx, hy, top - .72), w * .56, .22, 'teal'), ball((hx + w * .46, front - .15, top - .72), .16, 'gold')]
# cara: ojos grandes con brillo, mejillas, sonrisa
for s in (-1, 1):
    acc += [ball((hx + s * .26, front - .05, hz + .1), .15, 'black', (1, .5, 1.3)), ball((hx + s * .22, front + .02, hz + .17), .05, 'white'), ball((hx + s * .42, front - .08, hz - .1), .09, 'blush', (1, .3, .6))]
acc += [ball((hx, front - .03, hz - .22), .1, 'black', (1.6, .3, .5))]
for o in acc: bone(o, 'Head')
# bufanda coral y carcaj
tb = [parts['UpperTorso'].matrix_world @ Vector(v) for v in parts['UpperTorso'].bound_box]
tx, ty, tz = (sum(v[i] for v in tb) / 8 for i in range(3)); ttop = max(v.z for v in tb); tw = max(v.x for v in tb) - min(v.x for v in tb)
sc = [cyl((tx, ty, ttop - .12), tw * .52, .42, 'coral'), ball((tx + .4, ty - .5, ttop - .55), .26, 'coral', (.9, .5, 1.8))]
q = [cyl((tx - .4, ty - .62, tz + .1), .3, 1.6, 'wood', (R(18), R(16), 0))]
for k in range(3): q.append(cyl((tx - .55 + k * .17, ty - .78, tz + 1.05), .06, .7, 'gold', (R(18), R(16), 0)))
for o in sc + q: bone(o, 'UpperTorso')
# arco en la mano derecha: curva + cuerda + marca turquesa
rh = wp('RightHand')
bow = []
bpy.ops.mesh.primitive_torus_add(major_radius=1.25, minor_radius=.09, major_segments=24, minor_segments=8, location=(rh.x, rh.y + .15, rh.z), rotation=(R(90), 0, R(90)))
b = bpy.context.object; b.name = 'Nara_bow'; sm(b, 'wood'); b.scale = (1, 1, 1); bow.append(b)
bm_cut = b.modifiers.new('cut', 'BOOLEAN')
bpy.ops.mesh.primitive_cube_add(size=1, location=(rh.x - .8, rh.y + .15, rh.z)); cut = bpy.context.object; cut.scale = (1.4, 3, 3.2); cut.name = 'Nara_cut'
bm_cut.object = cut; bm_cut.operation = 'DIFFERENCE'
bpy.context.view_layer.objects.active = b; bpy.ops.object.modifier_apply(modifier='cut'); bpy.data.objects.remove(cut)
bow.append(cyl((rh.x + 1.22, rh.y + .15, rh.z), .018, 2.5, 'string')); bow[-1].rotation_euler = (R(0), 0, 0)
bow.append(ball((rh.x + .1, rh.y + .15, rh.z), .16, 'teal'))
for o in bow: bone(o, 'RightHand')
result = [p.name for p in bpy.data.objects if p.name.startswith('Nara_')]
