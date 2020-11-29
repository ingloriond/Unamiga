#!/bin/bash
for i in scene*; do
    k=${i#scene}
    govideo.sh -s $k
done
rm video-?.jpg
rm video.raw