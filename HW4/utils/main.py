from PIL import Image
import argparse
from pathlib import Path
import numpy as np
import os

def rgb2gray(rgb):
    return np.dot(rgb[...,:3], [0.29, 0.58, 0.11])

class generate_dat:
    def __init__(self, dat_path) -> None:
        self.data_cnt = 0
        self.dat_path = dat_path

    def iter_elements(self, img_array):
        with open(self.dat_path, 'w') as img_dat:
            for y in range(img_array.shape[0]):
                for x in range(img_array.shape[1]):
                    img_dat.write(f"{self.float_bin(float(img_array[y,x]))} //data {self.data_cnt}: {str(float(img_array[y,x]))}\n")
                    self.data_cnt += 1

    def float_bin(self, number, places = 4):
        whole, dec = str(number).split(".")
        whole = int(whole)
        div_num = len(dec)
        dec = int(dec)
        res = bin(whole).lstrip("0b")
        res = '0'*(9 - len(res)) + res

        for _ in range(places):
            if(dec > 0):
                whole, dec = str((self.decimal_converter(dec, div_num)) * 2).split(".")
                div_num = len(dec)
                dec = int(dec)
            else:
                whole = '0'
            res += whole
        return res

    def decimal_converter(self, num, div_num):
        for _ in range(div_num):
            num /= 10
        return num

def conv(input_matrix: np.ndarray, kernel_matrix: np.ndarray, bias) -> np.ndarray:

    # dilation is set as 2 and stride is set as 1
    kernel_shape = np.shape(kernel_matrix)

    shape_i = np.shape(input_matrix)
    shape_k = (kernel_shape[0] * 2 - 1, kernel_shape[1] * 2 -1)

    output_matrix = np.zeros((shape_i[0] - shape_k[0] + 1, shape_i[1] - shape_k[1] + 1))

    for i in range(0, shape_i[0] - shape_k[0] + 1):
        for j in range(0, shape_i[1] - shape_k[1] + 1):
            output_matrix[i,j] = np.sum(np.multiply(input_matrix[i:i+shape_k[0]:2, j:j+shape_k[1]:2], kernel_matrix))
            
    output_matrix = output_matrix + bias
    
    return output_matrix

def maxpool(input_matrxi: np.ndarray) -> np.ndarray:
    shape = np.shape(input_matrxi)
    output_matrix = np.zeros((shape[0]//2, shape[1]//2))
    for i in range(0, shape[0], 2):
        for j in range(0, shape[1], 2):
            output_matrix[i//2,j//2] = np.amax(input_matrxi[i:i+2,j:j+2])

    return output_matrix

def relu(input_matrix: np.ndarray) -> np.ndarray:
    shape = np.shape(input_matrix)
    output_matrix = np.zeros(shape)
    for i in range(0, shape[0]):
        for j in range(0, shape[1]):
            output_matrix[i, j] = input_matrix[i, j] if input_matrix[i, j] > 0 else 0

    return output_matrix

def padding(input_matrix: np.ndarray, padding = 2) -> np.ndarray:
    output_matrix = np.pad(input_matrix, ((padding, padding), (padding, padding)), 'edge')
    return output_matrix

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Software Verification')
    parser.add_argument('-img_path', type=str, required=True)
    parser.add_argument('-target_dat_dir', type=str, default='.')
    parser.add_argument('-target_img_dir', type=str, default='.')
    args = parser.parse_args()

    os.makedirs(args.target_dat_dir, exist_ok=True)
    os.makedirs(args.target_img_dir, exist_ok=True)

    img_dat_path = os.path.join(args.target_dat_dir,"img.dat")
    golden0_path = os.path.join(args.target_dat_dir,"layer0_golden.dat")
    golden1_path = os.path.join(args.target_dat_dir,"layer1_golden.dat")
    
    resizedImg = os.path.join(args.target_img_dir,"resizedImg.png")
    layer0_outputImg = os.path.join(args.target_img_dir,"layer0_outputImg.png")
    layer1_outputImg = os.path.join(args.target_img_dir,"layer1_outputImg.png")

    if Path(args.img_path).suffix != '.jpg' and Path(args.img_path).suffix != '.png':
        print("Please make sure that the format of the input image is PNG or JPG.")
        exit()
    else:
        # resize = transforms.Resize(, antialias=True)
        img = Image.open(args.img_path).convert('L').resize([64,64])
        # img = resize(img)
        img_array = np.array(img)
        Image.fromarray(img_array).save(resizedImg)
        # np.savetxt('./file/img_array.txt', img_array, delimiter=',', fmt='%3.5f')

    gen_img_dat = generate_dat(img_dat_path).iter_elements(img_array)

    # ====================== Layer0 ======================
    kernel = np.array([[-0.0625 ,-0.125 ,-0.0625],
                       [-0.25   ,   1   ,-0.25  ],
                       [-0.0625 ,-0.125 ,-0.0625]])
    bias = -0.75
    
    img_array = padding(img_array)
    img_array = conv(img_array, kernel, bias)
    img_array = relu(img_array)
    gen_layer0_golden_dat = generate_dat(golden0_path).iter_elements(img_array)
    Image.fromarray(np.around(img_array).astype(np.uint8)).save(layer0_outputImg)

    # ====================== Layer1 ======================
    img_array = maxpool(img_array)
    img_array = np.ceil(img_array)
    gen_layer1_golden_dat = generate_dat(golden1_path).iter_elements(img_array)
    Image.fromarray(np.around(img_array).astype(np.uint8)).save(layer1_outputImg)
