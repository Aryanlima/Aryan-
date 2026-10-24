# arrow-rogue: arco en media luna y 6 animaciones de Nara (acciones Nara_Idle, Nara_Run, Nara_Shoot, Nara_Hit, Nara_Die, Nara_Celebrate), 24 fps.
# Requiere blender-nara.py ya ejecutado. Luego: ropilot_blender_import_animation.
import bpy, bmesh, math
from math import radians as R
from mathutils import Matrix, Vector
arm = bpy.data.objects['__RopilotDummy_Armature']
# --- arco: quitar la mitad trasera del aro y ponerlo con la cuerda hacia Nara
bow = bpy.data.objects['Nara_bow']; bow.modifiers.clear()
me = bow.data; bm = bmesh.new(); bm.from_mesh(me)
cy = bow.matrix_world.translation.y
bmesh.ops.delete(bm, geom=[v for v in bm.verts if (bow.matrix_world @ v.co).y < cy - .02], context='VERTS'); bm.to_mesh(me); bm.free()
bpy.context.scene.frame_start, bpy.context.scene.frame_end = 1, 24
bpy.context.scene.render.fps = 24
BONES = [b.name for b in arm.data.bones]
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
for pb in arm.pose.bones: pb.rotation_mode = 'QUATERNION'
def reset():
    for pb in arm.pose.bones: pb.matrix_basis = Matrix()
    bpy.context.view_layer.update()
def rot(bone, axis, deg):
    pb = arm.pose.bones[bone]; bpy.context.view_layer.update(); h = pb.head.copy()
    pb.matrix = Matrix.Translation(h) @ Matrix.Rotation(R(deg), 4, axis) @ Matrix.Translation(-h) @ pb.matrix
    bpy.context.view_layer.update()
def move(bone, v):
    pb = arm.pose.bones[bone]; pb.matrix = Matrix.Translation(Vector(v)) @ pb.matrix; bpy.context.view_layer.update()
ORDER = ['HumanoidRootPart', 'LowerTorso', 'UpperTorso', 'Head', 'RightUpperArm', 'RightLowerArm', 'RightHand', 'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
         'RightUpperLeg', 'RightLowerLeg', 'RightFoot', 'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot']
def key(frame):
    for b in BONES:
        pb = arm.pose.bones[b]
        pb.keyframe_insert('rotation_quaternion', frame=frame); pb.keyframe_insert('location', frame=frame)
def pose(frame, spec):  # spec: lista (hueso, eje, grados) o ('move', hueso, vector); los padres primero
    reset()
    for item in sorted(spec, key=lambda s: ORDER.index(s[1] if s[0] == 'move' else s[0])):
        if item[0] == 'move': move(item[1], item[2])
        else: rot(*item)
    key(frame)
def new_action(name):
    act = bpy.data.actions.new(name); arm.animation_data_create(); arm.animation_data.action = act
    bpy.context.scene.frame_end = 24
    return act
HOLD = [('RightUpperArm', 'X', 82), ('RightLowerArm', 'X', 8), ('LeftUpperArm', 'X', 78), ('LeftLowerArm', 'X', 12)]  # sostiene el arco al frente
def stride(a): return [('RightUpperLeg', 'X', a), ('RightLowerLeg', 'X', -abs(a) * .5 if a < 0 else 0), ('LeftUpperLeg', 'X', -a), ('LeftLowerLeg', 'X', -abs(a) * .5 if -a < 0 else 0)]
acts = {}
# Idle: respirar con el arco listo
a = new_action('Nara_Idle'); acts['Nara_Idle'] = a
pose(1, HOLD); pose(12, HOLD + [('UpperTorso', 'X', 2), ('Head', 'X', -2), ('move', 'LowerTorso', (0, 0, .06))]); pose(24, HOLD)
# Run: 24 cuadros, zancada con brazos que llevan el arco
a = new_action('Nara_Run'); acts['Nara_Run'] = a
S = 38
pose(1, HOLD + stride(S) + [('UpperTorso', 'X', -8), ('move', 'LowerTorso', (0, 0, .12))])
pose(7, HOLD + stride(0) + [('UpperTorso', 'X', -8)])
pose(13, HOLD + stride(-S) + [('UpperTorso', 'X', -8), ('move', 'LowerTorso', (0, 0, .12))])
pose(19, HOLD + stride(0) + [('UpperTorso', 'X', -8)])
pose(24, HOLD + stride(S) + [('UpperTorso', 'X', -8), ('move', 'LowerTorso', (0, 0, .12))])
# Shoot: tensar (brazo izq adelante, derecho atras) y soltar
a = new_action('Nara_Shoot'); acts['Nara_Shoot'] = a
pose(1, HOLD); pose(10, [('RightUpperArm', 'X', 70), ('RightLowerArm', 'X', 60), ('LeftUpperArm', 'X', 88), ('UpperTorso', 'Z', 10)])
pose(14, [('RightUpperArm', 'X', 70), ('RightLowerArm', 'X', 62), ('LeftUpperArm', 'X', 88), ('UpperTorso', 'Z', 10), ('move', 'LowerTorso', (0, -.04, 0))])
pose(17, [('RightUpperArm', 'X', 82), ('RightLowerArm', 'X', 6), ('LeftUpperArm', 'X', 84), ('UpperTorso', 'X', -4)]); pose(24, HOLD)
# Hit: retroceso del torso y brazos hacia atras
a = new_action('Nara_Hit'); acts['Nara_Hit'] = a
pose(1, HOLD); pose(5, [('UpperTorso', 'X', -22), ('Head', 'X', -16), ('RightUpperArm', 'X', 30), ('LeftUpperArm', 'X', 30), ('move', 'LowerTorso', (0, -.35, -.05))])
pose(12, [('UpperTorso', 'X', -8), ('RightUpperArm', 'X', 60), ('LeftUpperArm', 'X', 60)]); pose(24, HOLD)
# Die: cae de espaldas
a = new_action('Nara_Die'); acts['Nara_Die'] = a
pose(1, HOLD); pose(10, [('UpperTorso', 'X', -35), ('Head', 'X', -25), ('RightUpperArm', 'X', 20), ('LeftUpperArm', 'X', 20), ('move', 'HumanoidRootPart', (0, -.5, -1.4))])
pose(24, [('HumanoidRootPart', 'X', -88), ('RightUpperArm', 'X', 10), ('LeftUpperArm', 'Z', -50), ('RightUpperArm', 'Z', 50), ('move', 'HumanoidRootPart', (0, -2.2, -2.2))])
# Celebrate: brazos arriba, saltito
a = new_action('Nara_Celebrate'); acts['Nara_Celebrate'] = a
UP = [('RightUpperArm', 'X', 170), ('LeftUpperArm', 'X', 170), ('RightLowerArm', 'X', 10), ('LeftLowerArm', 'X', 10)]
pose(1, HOLD); pose(6, UP + [('move', 'HumanoidRootPart', (0, 0, .8))]); pose(12, UP); pose(18, UP + [('move', 'HumanoidRootPart', (0, 0, .8))]); pose(24, UP)
bpy.ops.object.mode_set(mode='OBJECT')
arm.animation_data.action = acts['Nara_Idle']
for act in acts.values(): act.use_fake_user = True
result = {n: (len(a.fcurves), tuple(a.frame_range)) for n, a in acts.items()}
