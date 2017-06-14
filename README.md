# FaceScan_ICV
Code &amp; things developed by ICV

Download and extract as assets folder: https://drive.google.com/open?id=0B2sQ-paXlXusT243M3c1TGJ5YW8.
Advisable to create: __output__ and __input__ folders also. __input__ for videos.

## Requirements
* Matlab, newest version is advisable. Might work on some older versions also.
* OpenFace - included in the assets
* Python 3 - for texture creation
* Blender - for rendering database objects.

## Assets
* openface  
  Openface binaries folder, https://github.com/TadasBaltrusaitis/OpenFace/wiki/Windows-Installation
* wrapped_models  
  Currently assumed to be named __male###.obj__ starting from 0.
* renders  
  2d frontal renders from models with diffuse top down lighting
* regions_db  
  Normalised images from renders - heads are scaled approximately same size using OpenFace features. Then cutouts of regions are saved into separate folders.
* texture  
  Folder containing average texture and manually mapped feature points location on the texture.

## Code
Files to change/use

* python/render_obj.py  

  Creates renders from models using also texture. It uses Blender python api: https://docs.blender.org/api/blender_python_api_2_59_0/contents.html  
  It requires specifying wrapped models directory and desired output directory, also number of models - in the script file. Currently it only renders frontal images although cameras are set up also for side views. NB! atleast on my computer, it didn't apply the texture on the objects always - usually simply running it again, possibly few times, fixed the issue.  
  As it uses Blender api, it needs to be run using Blender python distribution, so from command line from the script directory: ```"c:\Program Files\Blender Foundation\Blender\blender.exe" --background --python render_obj.py```
  
* createRegionsDatabase.m  

  Extracts regions from the renders using OpenFace. It requires path to rendered images folder and an output folder path, also databse size. Relative paths should work.
  
* functions/features/runFeatureDetection.m  

  Here, path to openface should be set. Located under __assets/openface__. The default relative path set should work, if you don't change openface loc.
  
* blendshape_setup  

  Run this after creating/adding models to database. It reads in .obj files and saves them into Matlab friendly format so afterwards reading data would be fast.
  
* main  

  This creates untextured model from input video. Requires a video file input path and outputfolder where model and images for texture are saved. RotateAngle specifies which way video should be rotated before feeding to OpenFace - it really depends on the phone/input, sometimes not needed at all. Output is saved to the specified folder, .obj and 3 images with corresponding feature locations.
  
* python/createTexture.py  

  As name said, it combines the images into texture using feature points. Requires the folder with .obj and images and texture folder location (assets/texture) - specify within the script. Creates texture file, combining three views and average texture. Requires 3rd party libs: skimage, numpy, matplotlib. Tested with Python 3.5.2. Run within the file folder: ```python createTexture.py```
  
* make_video.m  

  Simple script that combines images to video, for __main__ the input should be video.
  
  
## Logic
Super high level flow:  
1. Find feature points from video (features/open_face_feats_normalised.m)  
2. Find frames where face is -20, 0, 20 degrees  
3. Extract and normalise faces from those images (features/extractNormalisedFrame.m)  
4. Extract regions from frontal (0 degrees) image (features/extractRegion)  
5. Find 2 closest matches for each region. Also relative weights (features/getClosestFaces)  
6. Blend together the closest matches, using defined region vertices from found models (belndshape_morph.m)  
7. Blend together the regions to whole model  
8. Morph the model based on frontal feature points  
9. Save .obj  
10. Using feature points from the 3 images, find piecewise affine transformation to the texture (python/createTexture.py)  
11. Transform all images to texture and blend them together.  
12. Blend the result with average texture and save.  


## Code modules explanation
* blendshape_morph.m

  Contains a few parameters which can be tweaked based on the input base model.
  First the input feature point .txt file is read in (feature_func/readfeats.m) along with a refrence base model (obj_IO/readobj.m) and the point cloud is reshaped (feature_func/equalizefeats.m) and adjusted to fit the basemodel.  
  Next all of the vertex groups for the model regions are imported as face arrays (obj_IO/findregion.m) and converted to index arrays (obj_morph/findpointsfromregions.m) 
  corresponding to the base models vertex indices. Based on the input weight arrays, 4 blended models are generated (obj_morph/blendshape.m) which correspond to the 4 selected face regions. 
  The regions are then translated in relation to one-another (obj_morph/frankenblend.m) and the input feature points to decrease sharp transitions between regions and the regions are then blended together (obj_morph/smoothpointblend.m) using a distance based weight function.   
  After the blended model has been generated, the predefined feature point vertices in the model are moved towards the given feature points and the surrounding vertices are dragged along based on a Gaussian curve and their distance from the vertices (obj_morph/gaussallmove3D.m). The morphing is done 3 times with different effect ranges to get the basic shape and then the finer details.

### functions/features
* open_face_feats_normalised  

  Given input video/image and rotation angle, first rotates (if needed) and then calls _runFeatureDetection_ which runs OpenFace feature detection on the file. Saves the data file. Later extracts -20, 0, +20 degree normalised images from video or simply 1 normalised img from image.

* runFeatureDetection  

  Calls OpenFace feature detection exe. For 3d points, focal lenght (fx, fy) should be specified.
  
* extractNormalisedFrame  

  Given video/image and OF datafile, extracts required frame, rotates it, fits a square around facial area (using __p_scale__ from OF), crops that area and resizes the output picture. Saves also only 2d & 3d coordinates into separate files and image with markers on it. For scaling, the p_scale field from OF is used - it should ensure that output head is approximately same percentage of the output pics. For rotating img __p_rz__ is used. Currently output resolution is fixed at 1080x1080 and square size modifier k=120. The part of the code dealing with 3d points is actually not used in current version later on.

* extractRegion  

  Given image file path, 2d file path and face region id, extracts specified region from the image (using 2d points file). Output is resized for each region for doing the similarity check later. Basically, points defining a region are specified and a convex hull is fitted for the points. For eyes and mouth, bounding box is found. Areas:
    * 1 - face wo eyes&nose&mouth  
    * 2 - eyes  
    * 3 - nose  
    * 4 - mouth  
	
* getBestFrame  

  Simply finds the index thats value closest to given angle. Currently only rot around up-axis is used.

* getClosestFaces  

  Given input (normalised) image file name and regions database returns weights for all database entries using various metrics for different regions. Assumes also 2d points file is present and named properly. First, reads in database images, then extracts regions from input image, then applies metric to each region to get distances from db entries. Then the weights are calculated.

* getClosestPCA  

  First does PCA analysis on imageDB using https://se.mathworks.com/help/stats/pca.html. Secondly, finds PCA coords for testImg, and using those finds norm1 distances from all imagesDB images. Returns closest and distances.  
  NB! Calculations done on centered images - i.e. average vector (mu) is subtracted first.

* ssim_info  

  Convert images to grayscale and find SSIM index between testImg and each image in the imagesDB.  
  https://se.mathworks.com/help/images/ref/ssim.html

* getWeights  

  Currently simply select 2 smallest distances and calculates their weight based on distance from 3rd closest.

* readOFData  

  Helper f-n to read OF output.

* panorama_from_feature_points - discard


### functions/feature_func
* equalizefeats  

  Adjusts mirrored feature points(1-18) to be equal on the y axis.
  
* readfeats  

  Read OpenFace feature points and alter them.  
  Read feature points from 'filename' and add corresponding indexes for each point using 'map' translation and rotation are used to reshape the feature point data 'featurelist' is a (68,5) where (:,1) is the mapped vertex index, (:,2-4) are the XY(Z) coordinates and (:,5) is the feature points size for later morphing.

### functions/obj_IO
* attachtexture  

  Creates a MTL file 'filename' with a refence to 'texturename' as the texture.
  
* findregion  

  Finds vertex indexes of all faces defined by a 'region_name' in 'filename'.  All indecies of the faces in 'filename' that are defined by a group name of 'region_name' are written to 'face_region'.
  
* readobj  

  Read OBJ file and return ordered vertecies and oredered faces.

* writeobjfast  

  Export OBJ file. Write 'points' to OBJ file 'outfilename' using 'filename' as a refrence 'texturefile' is added as an MTL refrence.


### functions/obj_morph
* blendshape  

  Blend pointclouds based on weights for each pointcloud.
  
* findpointsfromregions  

  Finds point indexes that correspond to the given mesh faces.
  
* frankenblend  

  This function blends together different point clouds based on their corresponding regions.  

  This function takes in point clouds of the selected eyes,nose,mouth and face and their regions of interest '_idx'. The regions are then adjusted to fit together and then the overlap areas are given a smooth overlap. 'XYadjust' defines an adjustment location where the regions should be located on the final model, helps with areas with curved overlap like the nose.
  
* gaussallmove3D  

  Move all 'points' using vectors 'fromarr'->'toarr' based on their distance to 'fromarr points'.  

  For all 'points', calculate the distance from each 'fromarr' and then apply 'fromarr'->'toarr' vector to those points based on f(distance).  
    * 'gsizearr' defines each vectors effect range  
    * 'multiplier' multiplies with each vectors 'gsizearr' to adjust the gaussian strength and range  
    * 'overextend' multiplies with each vector to overexaggerate the move vector  
    * 'allmove' disables vectors with larger 'gsizearr' values for better accuracy
	
* smoothpointblend  
  
  Add 'new_region's 'new_region_idx' points to 'base_region'.  
  
  Blend 'base_region' and 'new_region' pointclouds together using 'new_region_idx' to define the 'new_region's strong influence in the blend.
