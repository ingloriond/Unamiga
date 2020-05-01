#!/bin/bash

# Updates video output while simulation is in progress

if [ -e video.raw ]; then
    mkdir -p video
    rm video/*.jpg
    convert -size 256x239 \
        -depth 8 RGBA:video.raw video/video.jpg
fi