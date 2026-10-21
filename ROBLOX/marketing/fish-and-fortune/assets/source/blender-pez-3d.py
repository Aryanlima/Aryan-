# Fish & Fortune: pez 3D (con moneda) para renderizar con ropilot_blender_render. Uso: exec en el Blender de Ropilot.
import bpy, bmesh, math
from math import radians as R, sqrt
old = bpy.data.collections.get('FishIcon')
if old:
    for o in list(old.objects): bpy.data.objects.remove(o)
    bpy.data.collections.remove(old)
col = bpy.data.collections.new('FishIcon'); bpy.context.scene.collection.children.link(col)
bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children['FishIcon']
C = dict(gold=(1, .78, .24), orange=(1, .5, .08), cream=(1, .95, .7), spot=(1, .93, .6), white=(1, 1, 1), black=(.02, .02, .05),
  mouth=(.45, .03, .08), tongue=(1, .42, .5), coin=(1, .78, .1), coin2=(.95, .55, .02), blush=(1, .45, .5))
M = {}
def mat(n, metal=0.0):
    if n not in M:
        m = bpy.data.materials.new(n); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
        b.inputs['Base Color'].default_value = (*[c ** 2.2 for c in C[n]], 1); b.inputs['Metallic'].default_value = metal
        b.inputs['Roughness'].default_value = .35; m.diffuse_color = b.inputs['Base Color'].default_value; M[n] = m
    return M[n]
root = bpy.data.objects.new('FishRoot', None); col.objects.link(root)
def own(o, m, smooth=True, sub=0):
    o.parent = root
    if m: o.data.materials.append(mat(m))
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    if sub: o.modifiers.new('sub', 'SUBSURF').levels = sub
    return o
def sph(loc, r, m, sc=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=r, location=loc); o = bpy.context.object; o.scale = sc
    return own(o, m)
def fin(pts, m, y=0, th=.12, rot=(0, 0, 0)):
    me = bpy.data.meshes.new('fin'); me.from_pydata([(x, 0, z) for x, z in pts], [], [list(range(len(pts)))]); me.update()
    o = bpy.data.objects.new('fin', me); col.objects.link(o); o.location = (0, y, 0); o.rotation_euler = rot
    s = o.modifiers.new('s', 'SOLIDIFY'); s.thickness = th; s.offset = 0
    return own(o, m, sub=2)
# cuerpo: esfera estirada, mas fina hacia la cola
bpy.ops.mesh.primitive_uv_sphere_add(segments=64, ring_count=32, radius=1); body = bpy.context.object; body.name = 'Body'
bm = bmesh.new(); bm.from_mesh(body.data)
for v in bm.verts:
    x, y, z = v.co; t = (x + 1) / 2; s = .4 + .6 * min(1, t * 1.7)
    v.co = (2.2 * x, .85 * y * s, 1.35 * z * s + .12 * (1 - t) ** 2)
bm.to_mesh(body.data); bm.free()
own(body, 'gold', sub=1)
sph((.45, 0, -.32), 1, 'cream', (1.6, .87, 1.06))
# manchas, ojos, boca
for x, z in [(-.9, .55), (-.3, .8), (.3, .78), (-.55, .2), (.05, .35), (-1.25, .15)]:
    for sgn in (-1, 1):
        hit, p, *_ = body.ray_cast((x, sgn * 3, z), (0, -sgn, 0))
        if hit: sph((p.x, p.y * .96, p.z), .17, 'spot', (1, .35, 1))
for sgn in (-1, 1):
    e = (1.3, sgn * .34, .98); sph(e, .48, 'white')
    d = (.8, sgn * .45, .35); n = sqrt(sum(c * c for c in d)); d = [c / n for c in d]
    sph(tuple(e[i] + d[i] * .3 for i in range(3)), .25, 'black')
    sph(tuple(e[i] + d[i] * .46 + (0, 0, .14)[i] for i in range(3)), .08, 'white')
    sph((1.55, sgn * .66, -.05), .14, 'blush', (1, .3, .7))
sph((1.9, 0, -.3), .4, 'mouth', (.75, 1.25, 1.05)); sph((2.12, 0, -.55), .2, 'tongue', (.6, 1.2, .45))
# aletas
fin([(-1.75, .3), (-2.7, 1.25), (-3.45, 1.55), (-3.1, .35), (-2.95, 0), (-3.1, -.35), (-3.45, -1.45), (-2.7, -1.1), (-1.75, -.25)], 'orange', th=.16, rot=(0, 0, R(18)))
fin([(.9, .95), (.5, 1.75), (-.3, 1.95), (-1.1, 1.55), (-1.5, .7)], 'orange')
fin([(-.6, -1.0), (-1.0, -1.65), (-1.6, -1.5), (-1.3, -.85)], 'orange')
for sgn in (-1, 1):
    fin([(.55, -.15), (-.05, .1), (-.75, -.35), (-.3, -.8), (.25, -.6)], 'orange', y=sgn * .62, th=.1, rot=(0, 0, R(sgn * -25)))
# moneda en la boca y dos flotando
def coin(loc, r, rot):
    for rr, d, m in ((r, .16, 'coin2'), (r * .78, .2, 'coin')):
        bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=rr, depth=d, location=loc); o = bpy.context.object; o.rotation_euler = rot
        b = o.modifiers.new('b', 'BEVEL'); b.width = .04; b.segments = 3; own(o, m)
coin((-1.4, -.6, 2.5), .4, (R(90), R(15), R(30)))
coin((1.2, -.8, 2.4), .32, (R(90), R(-15), R(45)))
root.rotation_euler = (0, R(-22), 0)
result = len(col.objects)
