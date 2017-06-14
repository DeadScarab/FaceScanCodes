from skimage import transform as tf
import numpy as np
import cv2
import matplotlib.pyplot as plt
import os
import sys


def get_warped_pwa(img_file, pts_file, used_idx, text_pts):
    n = 68
    img = cv2.imread(img_file)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    width, height, _ = img.shape

    # read img points
    with open(pts_file, 'r') as f:
        tmp = [float(r) for r in f.read().split()]
        img_pts = np.dstack((tmp[:n], tmp[n:]))[0]
        img_pts[:, 0] *= width
        img_pts[:, 1] *= height
        # move eyebrows a bit lower
        idx_eyebrows = list(range(17,27))
        img_pts[idx_eyebrows, 1] += 5

    # add forehead points to end
    for i in [21,22,18,25]:
        d = -166
        img_pts = np.append(img_pts, [img_pts[i, :] + [0, d]], axis=0)

    # add 4 pts to the mouth center line
    x = np.mean([img_pts[49], img_pts[59]], axis=0)[0]
    y = np.mean(img_pts[60:62], axis=0)[1]
    img_pts = np.append(img_pts, [[x, y]], axis=0)

    x = np.mean([img_pts[53], img_pts[55]], axis=0)[0]
    y = np.mean(img_pts[63:65], axis=0)[1]
    img_pts = np.append(img_pts, [[x, y]], axis=0)

    x = np.mean([img_pts[53], img_pts[55]], axis=0)[0]
    y = np.mean(img_pts[64:66], axis=0)[1]
    img_pts = np.append(img_pts, [[x, y]], axis=0)

    x = np.mean([img_pts[49], img_pts[59]], axis=0)[0]
    y = np.mean([img_pts[60], img_pts[67]], axis=0)[1]
    img_pts = np.append(img_pts, [[x, y]], axis=0)

    # select only used points
    img_pts = img_pts[used_idx, :]
    text_pts_cur = text_pts[used_idx, :]

    # find piecewise affine transform from img to texture
    tform = tf.PiecewiseAffineTransform()
    tform.estimate(img_pts, text_pts_cur)

    return tf.warp(img, tform.inverse, output_shape=(2048, 2048), order=3), img_pts, img


def get_front_weights(img_front):
    # for each row, find count of non-zero pixels
    mask = img_front != 0
    # row_lens = np.sum(mask, axis=1)
    weights = np.ones(img_front.shape) * mask
    weights = cv2.dilate(weights, np.ones((201, 201)), iterations=1)
    weights = cv2.erode(weights, np.ones((11, 151)), iterations=1)
    weights = cv2.GaussianBlur(weights, (601, 21), 0)
    weights = cv2.erode(weights, np.ones((191, 251)), iterations=1)
    weights *= mask

    return weights**2


def combine_areas(img_front, img_left, img_right, weights_front):
    mask_overlap = (img_left != 0) * (img_right != 0)
    mask_left_only = (img_left != 0) * (1-mask_overlap)
    mask_right_only = (img_right != 0) * (1-mask_overlap)
    img_combined = mask_left_only * img_left + mask_right_only * img_right + mask_overlap * (img_left*0.5 + img_right*0.5)
    # img_combined = np.maximum(img_left, img_right)
    img_combined = img_front*weights_front + img_combined * (1-weights_front)
    return img_combined
	

def enhance_eyes(img_combined,img_file,pts_file,text_pts):
    idx_eyes = list(range(36,48))
    warped_eyes,eye_pts,img = get_warped_pwa(img_file, pts_file, idx_eyes, text_pts)
    mask_eyes = get_convex_hull_mask(eye_pts,img_combined)
    mask1 = np.zeros((2048, 2048, 3))
    mask1[:, :, 0] = mask_eyes
    mask1[:, :, 1] = mask_eyes
    mask1[:, :, 2] = mask_eyes
    mask2 = warped_eyes!=0
    kernel = np.ones((10, 10), np.float32) / 100
    mask1 = cv2.erode(mask1, np.ones((10, 10), np.uint8))
    mask1 = cv2.filter2D(mask1, -1, kernel)
    mask = mask1 * mask2
    enhanced_eyes = img_combined -0.5*(img_combined*mask+warped_eyes*mask)
    return enhanced_eyes


def combine_average_texture(img_combined, texture_file):
    img_avg_texture = cv2.imread(texture_file)
    img_avg_texture = cv2.cvtColor(img_avg_texture, cv2.COLOR_BGR2RGB)
    mask = img_combined != 0

    img_avg_texture = img_avg_texture / 255.0
    avg_skin_med = np.median(img_avg_texture[653:780, 814:1242, :], axis=[0, 1])
    skin_med = np.median(img_combined[653:780, 814:1242, :], axis=[0, 1])
    img_avg_texture = img_avg_texture +skin_med-avg_skin_med
    img_avg_texture = np.clip(img_avg_texture, 0, 1)

    weights = np.ones(img_combined.shape) * mask
    weights = cv2.dilate(weights, np.ones((11, 11)), iterations=1)
    weights = cv2.erode(weights, np.ones((65, 111)), iterations=1)
    # weights = cv2.GaussianBlur(weights, (101, 101), 0)
    weights = cv2.blur(weights, (101, 41))
    weights *= mask
    # weights **= 2

    img_combined_texture = img_combined*weights + img_avg_texture * (1-weights)

    return img_combined_texture


def get_convex_hull_mask(points, img):
    pts = np.array(points).T
    pts.shape = (2, len(points))
    pts = pts.astype(np.int32)
    # hull = cv2.convexHull(pts.T)
    # print(hull)
    p = cv2.convexHull(pts.T, returnPoints=True)
    mask = np.zeros((img.shape[0], img.shape[1]))
    mask = cv2.fillConvexPoly(mask, p, 1)
    return mask


def overwrite_mtl(img_folder, fold_name):
    # simply fixes the .mtl, we only need ref to texture
    mtl_file = os.path.join(img_folder, '%s_1.mtl' % fold_name)
    with open(mtl_file, 'wt') as f:
        f.write('map_Kd %s.png' % fold_name)


if __name__ == '__main__':
    fold_name = 'timmu_video'  # specific folder where .obj and stuff is, probably only thing you need to spec
    if len(sys.argv) > 1:
        fold_name = sys.argv[1]
        print('Creating texture for: %s' % fold_name)

    output_folder = os.path.abspath('../../output')        # where matlab creates output folders
    text_folder = os.path.abspath('../../assets/texture')  # average text and feat points
    txt_pts_file_name = 'FeaturePointsLocationOnTexture_v01.csv'
    average_txt_file_name = 'average_texture.jpg'

    img_folder = os.path.join(output_folder, fold_name)
    dstTextureFile = os.path.join(img_folder, "%s.png" % fold_name)
    avg_texture_file = os.path.join(text_folder, average_txt_file_name)
    texture_pts_file = os.path.join(text_folder, txt_pts_file_name)

    # determine which points to use for different images
    idx = list(range(100))
    # used_idx_front = idx[7:10] + idx[17:68] + idx[68:76]
    used_idx_front = idx[0:17] + idx[17:68] + idx[68:76]
    used_idx_left = idx[8:17] + idx[22:31] + idx[33:36] + idx[42:48] + idx[51:58] + idx[62:67] + [68,69,71,73,74]
    used_idx_right = idx[0:9] + idx[17:22] + idx[27:33] + idx[36:42] + idx[48:52] + idx[57:60] + idx[60:63] + [66,67,68,69,70,72,75]

    # create filenames for images and points
    pts_file_right = os.path.join(img_folder, '%s_0_2d.txt' % fold_name)
    img_file_right = os.path.join(img_folder, '%s_0.png' % fold_name)
    pts_file_front = os.path.join(img_folder, '%s_1_2d.txt' % fold_name)
    img_file_front = os.path.join(img_folder, '%s_1.png' % fold_name)
    pts_file_left = os.path.join(img_folder, '%s_2_2d.txt' % fold_name)
    img_file_left = os.path.join(img_folder, '%s_2.png' % fold_name)

    # read texture points
    text_pts = np.genfromtxt(texture_pts_file, delimiter=";", dtype=np.uint16)[:, 1:3]

    # find transformations and resulting images
    warped_front, img_pts_front, img_front = get_warped_pwa(img_file_front, pts_file_front, used_idx_front, text_pts)
    warped_left, img_pts_left, img_left = get_warped_pwa(img_file_left, pts_file_left, used_idx_left, text_pts)
    warped_right, img_pts_right, img_right = get_warped_pwa(img_file_right, pts_file_right, used_idx_right, text_pts)

    # combine
    weights_front = get_front_weights(warped_front)
    warped_combined = combine_areas(warped_front, warped_left, warped_right, weights_front)
    warped_combined = enhance_eyes(warped_combined,img_file_front,pts_file_front,text_pts)
    warped_complete = combine_average_texture(warped_combined, avg_texture_file)

    plt.imsave(dstTextureFile, warped_complete)
    overwrite_mtl(img_folder, fold_name)

    # plotting - just for show
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(nrows=2, ncols=2)
    margins = dict(hspace=0.01, wspace=0.01, top=1, bottom=0, left=0, right=1)
    fig.subplots_adjust(**margins)
    plt.gray()
    # ax1.imshow(warped_right)
    # ax1.plot(text_pts[:, 0], text_pts[:, 1], '.r')
    # ax1.axis('off')
    ax1.imshow(img_front)
    ax1.plot(img_pts_front[:, 0], img_pts_front[:, 1], '.r')
    ax1.axis('off')
    ax2.imshow(warped_front)
    ax2.plot(text_pts[:, 0], text_pts[:, 1], '.r')
    ax2.axis('off')
    ax3.imshow(weights_front)
    ax3.plot(text_pts[:, 0], text_pts[:, 1], '.r')
    ax3.axis('off')
    ax4.imshow(warped_complete)
    ax4.plot(text_pts[:, 0], text_pts[:, 1], '.r')
    ax4.axis('off')
    plt.show()
