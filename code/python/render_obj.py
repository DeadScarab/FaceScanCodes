# run from cmd "c:\Program Files\Blender Foundation\Blender\blender.exe" --background --python render_obj.py
import bpy
import os
from math import radians


nbr_obj = 218  # specify max model nr, starts from 0
models_path = os.path.abspath("../../assets/wrapped_models")
render_path = os.path.abspath("../../assets/renders1")

models = ["male%03d.obj" % i for i in range(nbr_obj + 1)]

context = bpy.context
# create a scene
scene = bpy.data.scenes.new("Scene")
# environment light
world = bpy.data.worlds['World']
world.light_settings.use_environment_light = True
world.light_settings.environment_energy = 0.5

# front
camera_data1 = bpy.data.cameras.new("front")
camera1 = bpy.data.objects.new("front", camera_data1)
camera1.location = (0.0, -45.0, 15.0) # front
camera1.rotation_euler = (radians(90), 0, radians(0))
scene.objects.link(camera1)

# right - now at 30 deg angle
camera_data2 = bpy.data.cameras.new("right")
camera2 = bpy.data.objects.new("right", camera_data2)
# camera2.location = (-45.0, 0.0, 15.0)
camera2.location = (-22.5, -39.0, 15.0)
# camera2.rotation_euler = (radians(90), 0, radians(-90))
camera2.rotation_euler = (radians(90), 0, radians(-30))
scene.objects.link(camera2)

# left - 90 deg angle, not used
camera_data3 = bpy.data.cameras.new("left")
camera3 = bpy.data.objects.new("left", camera_data3)
camera3.location = (45.0, 0.0, 15.0)
camera3.rotation_euler = (radians(90), 0, radians(90))
scene.objects.link(camera3)

# sun front
sun_data = bpy.data.lamps.new(name="sun1", type='SUN')
sun = bpy.data.objects.new(name="sun1", object_data=sun_data)
sun.location = (0, 0, 0)
sun.rotation_euler = (radians(45), 0, 0)
sun_data.energy = 0.5
scene.objects.link(sun)
# front bottom
sun11_data = bpy.data.lamps.new(name="sun11", type='SUN')
sun11 = bpy.data.objects.new(name="sun11", object_data=sun11_data)
sun11.location = (0, 0, 0)
sun11.rotation_euler = (radians(120), 0, 0)
sun11_data.energy = 0.25
scene.objects.link(sun11)

# sun back
sun2_data = bpy.data.lamps.new(name="sun2", type='SUN')
sun2 = bpy.data.objects.new(name="sun2", object_data=sun2_data)
sun2.location = (0, 0, 0)
sun2.rotation_euler = (radians(-45), 0, 0)
sun2_data.energy = 0.5
scene.objects.link(sun2)

# sun left
sun3_data = bpy.data.lamps.new(name="sun3", type='SUN')
sun3 = bpy.data.objects.new(name="sun3", object_data=sun3_data)
sun3.location = (0, 0, 0)
sun3.rotation_euler = (0, radians(45), 0)
sun3_data.energy = 0.5
scene.objects.link(sun3)

# sun right
sun4_data = bpy.data.lamps.new(name="sun4", type='SUN')
sun4 = bpy.data.objects.new(name="sun4", object_data=sun4_data)
sun4.location = (0, 0, 0)
sun4.rotation_euler = (0, radians(-45), 0)
sun4_data.energy = 0.5
scene.objects.link(sun4)

scene.render.resolution_x = 1080
scene.render.resolution_y = 1920
scene.render.resolution_percentage = 100
# do the same for lights etc
scene.update()

for model_nr, model_path in enumerate(models):
    # scene.camera = camera
    path = os.path.join(models_path, model_path)
    # make a new scene with cam and lights linked
    context.screen.scene = scene
    bpy.ops.scene.new(type='LINK_OBJECTS')
    context.scene.name = model_path
    cams = [c for c in context.scene.objects if c.type == 'CAMERA']
    #import model
    # bpy.ops.import_scene.obj(filepath=path, axis_forward='-Z', axis_up='Y', filter_glob="*.obj;*.mtl")
    bpy.ops.import_scene.obj(filepath=path, axis_forward='-Z', axis_up='Y', filter_glob="*.obj;*.mtl", split_mode='OFF', use_groups_as_vgroups=True)
    obj_name = 'male%03d' % model_nr

    # texture
    img_path = os.path.join(models_path, obj_name + '.jpg')
    # img_path = os.path.join('C:\\Users\\v\\Desktop', 'average_texture.jpg')  # use same texture for all
    img = bpy.data.images.load(img_path)
    # Create image texture from image
    cTex = bpy.data.textures.new('ColorTex', type='IMAGE')
    cTex.image = img
    slot = bpy.data.objects[obj_name].material_slots[0].material.texture_slots.add()
    slot.texture = cTex

    # if model_nr == 0:
    #     face_name, head_name, eyes_name = 'Face', 'Head', 'Eyes'
    # else:
    #     face_name = 'Face.%03d' % model_nr
    #     head_name = 'Head.%03d' % model_nr
    #     eyes_name = 'Eyes.%03d' % model_nr
    #
    # for p in bpy.data.objects[face_name].data.polygons:
    #     p.use_smooth = True
    # for p in bpy.data.objects[head_name].data.polygons:
    #     p.use_smooth = True
    # for p in bpy.data.objects[eyes_name].data.polygons:
    #     p.use_smooth = True

    for p in bpy.data.objects[obj_name].data.polygons:
        p.use_smooth = True
    # lighting
    # bpy.data.materials["defaultMat.002"].specular_intensity = 0.1
    # bpy.data.objects[face_name].material_slots[0].material.specular_intensity = 0.1
    # bpy.data.objects[head_name].material_slots[0].material.specular_intensity = 0.1
    bpy.data.objects[obj_name].material_slots[0].material.specular_intensity = 0
    bpy.data.objects[obj_name].material_slots[0].material.diffuse_intensity = 1
    for i, c in enumerate(cams):
        # atm only frontal
        if c.name in ('front'):   # 'right' not used atm
            context.scene.camera = c
            print("Render ", model_path, context.scene.name, c.name)
            r_path = model_path[:-4] + "_" + c.name
            context.scene.render.filepath = os.path.join(render_path, r_path)
            bpy.ops.render.render(write_still=True)

            # bpy.ops.render.render()
            # bpy.data.images['Render Result'].save_render(filepath=context.scene.render.filepath+'.png')