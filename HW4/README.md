# HW4 Atrous Convolution

## 運行方式

1.	創建 conda environment，並且安裝必要的套件

	```bash
	$ conda create -n [環境名稱] --file [spec-file]
	$ # e.g conda create -n test_env --file ./"utils"/spec-file.txt
	```

2.	activate conda environment

	```bash
	$ conda activate [環境名稱]
	$ # e.g conda activate test_env
	```

3.	路徑切至根目錄，執行 **main.py**，並附上必要參數
	
	```bash
	$ python [main.py路徑] -img_path [目標影像路徑] -target_dat_dir [存放dat file的資料夾路徑] -target_img_dir [存放軟體驗證的影像資料夾路徑]
	$ # e.g python ./"Software category"/main.py -img_path ./pic.png -target_dat_dir ./my_data/ -target_img_dir ./my_imgs/
	```

4.	finish. 完成上述 command 之後，就可以在 root，看到新增的兩個資料夾 **my_data** 和 **my_imgs**