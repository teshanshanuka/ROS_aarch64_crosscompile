#!/bin/bash -e

PWD=$(pwd)
DIR_NAME=`basename ${PWD}`

# user must have access to this directory
if [ -z $INSTALL_PREFIX ]; then
  INSTALL_PREFIX="/xcompiled_aarch64"
fi
ROS_DIR="${INSTALL_PREFIX}/ros_melodic"

if [ ! $DIR_NAME == ROS_crosscompile ] ; then
  echo "Run the command from 'ROS_crosscompile' directory"
  exit
fi

mkdir -p ${ROS_DIR}
cp config/rostoolchain.cmake ${ROS_DIR}
cd ${ROS_DIR}

# catkin clean -y
catkin init
catkin config --merge-devel --merge-install --install \
--cmake-args -DCMAKE_BUILD_TYPE=Release \
-DCROSS_ROOT=${INSTALL_PREFIX} \
-DCMAKE_TOOLCHAIN_FILE=${ROS_DIR}/rostoolchain.cmake


rosinstall_generator ros_comm common_msgs sensor_msgs image_transport vision_opencv tf --rosdistro melodic --deps --wet-only --tar > ros-melodic-wet.rosinstall
if [ ! -f src/.rosinstall ]; then
  wstool init -j$(nproc) src ros-melodic-wet.rosinstall
fi

catkin build

# These were needed on jetson nano. Use with caution
echo 'export LD_LIBRARY_PATH='"${INSTALL_PREFIX}"'/lib:$LD_LIBRARY_PATH' >> ${ROS_DIR}/install/setup.bash

# Replace `/usr/aarch64-linux-gnu/lib/` with `/usr/lib/aarch64-linux-gnu/` (needed on jetson nano)
# find $INSTALL_PREFIX -type f -exec sed -i 's|/usr/aarch64-linux-gnu/lib/|/usr/lib/aarch64-linux-gnu/|g' {} \;
# Renaming original files with added extention `.libswp` just to be safe
find $INSTALL_PREFIX -type f -exec sed -i.libswp 's|/usr/aarch64-linux-gnu/lib/|/usr/lib/aarch64-linux-gnu/|g' {} \;
