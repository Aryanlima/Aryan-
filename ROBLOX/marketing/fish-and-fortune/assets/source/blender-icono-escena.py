# Fish & Fortune: escena del icono (avatar R15 de Ropilot + caña + pez dorado). Antes: ropilot_blender_import_rig y blender-pez-3d.py.
# Despues: ropilot_blender_render(items=['IconScene']) y componer el fondo con compose-icono.py.
import bpy, math
from math import radians as R
from mathutils import Matrix, Vector
SRC = 'C:/Users/Administrator/Desktop/Aryan-/ROBLOX/marketing/fish-and-fortune/assets/source/'
exec(open(SRC + 'blender-pez-3d.py').read())
arm = bpy.data.objects['__RopilotDummy_Armature']
rig = arm.users_collection[0]
parts = [o for o in bpy.data.objects if o.type == 'MESH' and o.name.startswith('RopilotDummy.model/')]
rigparts = parts[0].users_collection[0]
for c in ('Props', 'IconScene'):
    old = bpy.data.collections.get(c)
    if old:
        for o in list(old.objects): bpy.data.objects.remove(o)
        bpy.data.collections.remove(old)
scene = bpy.data.collections.new('IconScene'); bpy.context.scene.collection.children.link(scene)
props = bpy.data.collections.new('Props'); scene.children.link(props)
for c in (rig, rigparts, bpy.data.collections['FishIcon']):
    if c.name in rig.children: continue
    if c.name not in scene.children: scene.children.link(c)
    if c.name in bpy.context.scene.collection.children: bpy.context.scene.collection.children.unlink(c)
bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children['IconScene'].children['Props']
C.update(skin=(1, .8, .6), shirt=(1, .35, .37), pants=(.12, .16, .27), hat=(.79, .54, .29), hatband=(.12, .16, .27), rod=(.12, .16, .27),
  cork=(.79, .54, .29), line=(.95, .97, 1), foam=(.92, .98, 1), wood=(.79, .54, .29), wood2=(.55, .34, .16), brow=(.25, .12, .05))
def setmat(o, n):
    o.data.materials.clear(); o.data.materials.append(mat(n))
def bonechild(o, bone):
    w = o.matrix_world.copy(); o.parent = arm; o.parent_type = 'BONE'; o.parent_bone = bone; o.matrix_world = w
def prop(o, m):
    o.data.materials.append(mat(m))
    for p in o.data.polygons: p.use_smooth = True
    return o
def ball(loc, r, m, sc=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=r, location=loc); o = bpy.context.object; o.scale = sc; return prop(o, m)
def cyl(loc, r, d, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=r, depth=d, location=loc, rotation=rot); return prop(bpy.context.object, m)
# pose de reposo, colores del avatar
arm.location = (0, 0, 0); arm.rotation_euler = (0, 0, 0); arm.scale = (1, 1, 1)
for pb in arm.pose.bones: pb.matrix_basis = Matrix()
bpy.context.view_layer.update()
for o in parts:
    n = o.name
    setmat(o, 'shirt' if 'Torso' in n and 'Lower' not in n else 'pants' if ('Leg' in n or 'Foot' in n or 'LowerTorso' in n) else 'skin')
head = next(o for o in parts if 'Head' in o.name)
bb = [head.matrix_world @ Vector(v) for v in head.bound_box]
hx, hy, hz = (sum(v[i] for v in bb) / 8 for i in range(3)); fy = max(v.y for v in bb); top = max(v.z for v in bb)
# cara de sorpresa (mira al frente +Y) y sombrero de pescador
face = []
for s in (-1, 1):
    face += [ball((hx + s * .26, fy - .04, hz + .12), .2, 'white', (1, .6, 1.15)), ball((hx + s * .24, fy + .06, hz + .16), .1, 'black', (1, .5, 1.1)),
      ball((hx + s * .21, fy + .1, hz + .22), .035, 'white')]
    bpy.ops.mesh.primitive_cube_add(size=1, location=(hx + s * .27, fy - .02, hz + .42), rotation=(0, R(s * -18), 0)); b = prop(bpy.context.object, 'brow'); b.scale = (.26, .08, .07); face.append(b)
face += [ball((hx, fy - .02, hz - .3), .17, 'mouth', (1, .5, 1.35)), ball((hx, fy + .02, hz - .4), .08, 'tongue', (1.2, .5, .6)),
  ball((hx - .42, fy - .1, hz - .1), .09, 'blush', (1, .4, .7)), ball((hx + .42, fy - .1, hz - .1), .09, 'blush', (1, .4, .7)),
  cyl((hx, hy, top - .02), .95, .08, 'hat'), cyl((hx, hy, top + .2), .6, .42, 'hat'), cyl((hx, hy, top + .08), .62, .12, 'hatband')]
for o in face: bonechild(o, 'Head')
# pose: echado hacia atras tirando de la caña
def rot(bone, axis, deg):
    pb = arm.pose.bones[bone]; bpy.context.view_layer.update(); h = pb.head.copy()
    pb.matrix = Matrix.Translation(h) @ Matrix.Rotation(R(deg), 4, axis) @ Matrix.Translation(-h) @ pb.matrix
    bpy.context.view_layer.update()
for b, ax, d in [('HumanoidRootPart', 'X', 10), ('RightUpperArm', 'X', 62), ('RightUpperArm', 'Z', 38), ('LeftUpperArm', 'X', 55), ('LeftUpperArm', 'Z', -38),
                 ('RightLowerArm', 'X', 40), ('LeftLowerArm', 'X', 40), ('Head', 'X', 16), ('RightUpperLeg', 'X', 32), ('RightLowerLeg', 'X', -24), ('LeftUpperLeg', 'X', -12)]:
    rot(b, ax, d)
arm.location = (-4.6, 0, 0); arm.rotation_euler = (0, 0, R(-140)); arm.scale = (1.25,) * 3; bpy.context.view_layer.update()
fish = bpy.data.objects['FishRoot']; fish.location = (3.0, .6, 5.2); fish.scale = (1.8,) * 3; fish.rotation_euler = (0, R(-30), R(216))
bpy.context.view_layer.update()
for o in bpy.data.collections['FishIcon'].objects:
    if o.active_material and o.active_material.name.startswith('coin'):
        o.matrix_world = Matrix.Translation(o.matrix_world.translation) @ Matrix.Rotation(R(12), 4, 'Z') @ Matrix.Rotation(R(90), 4, 'X') @ Matrix.Scale(1.8, 4)
bpy.context.view_layer.update()
W = lambda pb, attr: arm.matrix_world @ getattr(arm.pose.bones[pb], attr)
grip = (W('RightHand', 'tail') + W('LeftHand', 'tail')) / 2
mouth = next(o for o in bpy.data.collections['FishIcon'].objects if o.active_material and o.active_material.name.startswith('mouth')).matrix_world.translation
to = (mouth - grip).normalized(); tip = grip + 6.8 * (to + Vector((0, 0, 1.3))).normalized()
tip = tip + (mouth - tip).normalized() * .9
def tube(pts, r0, r1, m, name):
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = 1; cu.bevel_resolution = 4
    sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(pts) - 1)
    for i, (p, bp) in enumerate(zip(pts, sp.bezier_points)):
        bp.co = p; bp.handle_left_type = bp.handle_right_type = 'AUTO'; bp.radius = r0 + (r1 - r0) * i / (len(pts) - 1)
    o = bpy.data.objects.new(name, cu); props.objects.link(o); bpy.context.view_layer.update()
    me = bpy.data.meshes.new_from_object(o.evaluated_get(bpy.context.evaluated_depsgraph_get())); bpy.data.objects.remove(o)
    o = bpy.data.objects.new(name, me); props.objects.link(o); return prop(o, m)
butt = grip - (tip - grip).normalized() * 1.1
mid = grip + (tip - grip) * .55 + Vector((0, 0, .9))
tube([butt, grip, mid, tip], .14, .05, 'rod', 'Rod')
tube([butt, butt + (grip - butt) * .9], .17, .16, 'cork', 'Grip')
cyl(grip + (tip - grip).normalized() * .35 + Vector((0, 0, -.25)), .28, .25, 'hat', (R(90), 0, R(-40)))
tube([tip, tip + (mouth - tip) * .5, mouth], .035, .035, 'line', 'Line')
# salpicadura donde el pez sale del agua y muelle bajo el avatar
sx, sy = fish.matrix_world @ Vector((-2.4, 0, -.6)), None
cx, cy, cz = sx.x, sx.y, -.55
ball((cx, cy, cz), 1, 'foam', (2.4, 1.3, .5))
for i in range(14):
    a = i * 2 * math.pi / 14
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=.36, depth=1.4 + .6 * (i % 2), location=(cx + 2.2 * math.cos(a), cy + 1.1 * math.sin(a), cz + .7),
      rotation=(R(-22) * math.sin(a), R(22) * math.cos(a), 0)); prop(bpy.context.object, 'foam')
    ball((cx + 2.9 * math.cos(a), cy + 1.4 * math.sin(a), cz + 1.6 + .5 * (i % 3)), .15 + .06 * (i % 3), 'foam')
for i in range(5):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-4.6, -1.6 + i * .8, -.62)); o = prop(bpy.context.object, 'wood' if i % 2 else 'wood2'); o.scale = (4.6, .74, .45)
result = [tuple(round(v, 2) for v in p) for p in (grip, tip, mouth, sx)]
