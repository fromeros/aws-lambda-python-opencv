#!/bin/bash

# Setting up build env
sudo apt-get update
sudo apt-get install build-essential gcc  chrpath
sudo apt-get install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
sudo apt-get install python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev

mkdir -p lambda-package/cv2 build/numpy

# Build numpy
pip install --install-option="--prefix=$PWD/build/numpy" numpy
cp -rf build/numpy/lib64/python2.7/site-packages/numpy lambda-package

# Build OpenCV 3.1
(
	NUMPY=$PWD/lambda-package/numpy/core/include
	cd build
	git clone https://github.com/opencv/opencv.git
	cd opencv
	git checkout 3.2.0
	cmake										\
		-D CMAKE_BUILD_TYPE=RELEASE				\
		-D WITH_TBB=ON							\
		-D WITH_IPP=ON							\
		-D WITH_V4L=ON							\
		-D ENABLE_AVX=ON						\
		-D ENABLE_SSSE3=ON						\
		-D ENABLE_SSE41=ON						\
		-D ENABLE_SSE42=ON						\
		-D ENABLE_POPCNT=ON						\
		-D ENABLE_FAST_MATH=ON					\
		-D BUILD_EXAMPLES=OFF					\
		-D PYTHON2_NUMPY_INCLUDE_DIRS="$NUMPY"	\
		.
	make
)
cp build/opencv/lib/cv2.so lambda-package/cv2/__init__.so
cp -L build/opencv/lib/*.so.3.2 lambda-package/cv2
strip --strip-all lambda-package/cv2/*
chrpath -r '$ORIGIN' lambda-package/cv2/__init__.so
touch lambda-package/cv2/__init__.py

# Copy template function and zip package
cp template.py lambda-package/lambda_function.py
cd lambda-package
zip -r ../lambda-package.zip *
