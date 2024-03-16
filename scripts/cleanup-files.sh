#!/bin/sh

echo "==== cleanup files ==="

cd $HOME
find ./ScreenShot -mtime +7 -type f -print0 | xargs -0 rm
find ./Downloads -mtime +7 -type f -print0 | xargs -0 rm
