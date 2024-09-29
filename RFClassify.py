#!/usr/bin/env python
# encoding: utf-8
#!/usr/bin/env python
# encoding: utf-8
import os,numpy
import osgeo.gdal as gdal
from osgeo.gdalconst import *
# import gdal
from sklearn.ensemble import RandomForestClassifier

features_filepath=r'E:\fenlei\features.tif'
train_filepath=r'E:\fenlei\td.txt'
label_filepath=r'E:\fenlei\RF_Classification.tif'
# 栅格数据读取
def readRater(filepath):
    gdal.AllRegister()
    ds = gdal.Open(filepath, GA_ReadOnly)  # 打开文件获取文件id
    dataset_ns = ds.RasterXSize
    dataset_nl = ds.RasterYSize
    dataset_proj = ds.GetProjection()
    dataset_geotrans = ds.GetGeoTransform()
    im_data = ds.ReadAsArray(0, 0, dataset_ns, dataset_nl)  # 将数据写成数组，对应栅格矩阵
    del (ds)
    return im_data, dataset_proj, dataset_geotrans
#写文件，以写成tif为例
def writeRaster(filename,im_proj,im_geotrans,im_data):
    #判断栅格数据的数据类型
    if 'int8' in im_data.dtype.name:
        datatype = gdal.GDT_Byte
    elif 'int16' in im_data.dtype.name:
        datatype = gdal.GDT_Int16
    else:
        datatype = gdal.GDT_Float64
    #判读数组维数
    if len(im_data.shape) == 3:
        im_bands, im_height, im_width = im_data.shape
    else:
        im_bands, (im_height, im_width) = 1,im_data.shape

    #创建文件
    driver = gdal.GetDriverByName("GTiff")            #数据类型必须有，因为要计算需要多大内存空间
    if not os.path.exists(os.path.dirname(filename)): os.mkdir(os.path.dirname(filename))
    dataset= driver.Create(filename, im_width, im_height,im_bands,datatype)
    dataset.SetGeoTransform(im_geotrans)              #写入仿射变换参数
    dataset.SetProjection(im_proj)                    #写入投影
    if im_bands == 1:
        dataset.GetRasterBand(1).WriteArray(im_data)  #写入数组数据
    else:
        for i in range(im_bands):
            bandData=im_data[i,:,:]
            dataset.GetRasterBand(i+1).WriteArray(bandData)
    del dataset

if __name__ =='__main__':
    aero_data,aero_proj,aero_trans=readRater(features_filepath)
    train_data=numpy.loadtxt(train_filepath,skiprows=30).astype(int)
    train_spect=aero_data[:,train_data[:,2],train_data[:,1]]
    train_label=train_data[:,3]
    RF_classifier=RandomForestClassifier(n_estimators=100,oob_score=True,n_jobs=1);  #树的数量越大执行效率越低，如果设置为10棵树应该很快计算完了，但推荐100棵树的设定
    RF_classifier.fit(numpy.transpose(train_spect),train_label)

    aero_Tdata=numpy.transpose(aero_data)
    aero_Tdims=aero_Tdata.shape
    aero_Tdata=numpy.reshape(aero_Tdata,(aero_Tdims[0]*aero_Tdims[1],aero_Tdims[2]))
    RF_label=RF_classifier.predict(aero_Tdata)
    RF_label=numpy.reshape(RF_label,(aero_Tdims[0],aero_Tdims[1])).astype(numpy.uint8)
    writeRaster(label_filepath,aero_proj,aero_trans,numpy.transpose(RF_label))
