#!/usr/bin/env bash

SRC="$(find parts/ -type f -iname '*.scad')"

if [ -z "$SRC" ]; then
    echo "No .scad files found in $(pwd)/parts/"
    exit 1
fi

# Create output directories
mkdir -p output/images output/cam output/cad

# Function to download and unzip BOSL2 library
download_bosl2() {
    if [ ! -d "parts/BOSL2" ]; then
        wget "https://github.com/BelfrySCAD/BOSL2/archive/refs/heads/master.zip" -O master.zip
        if [ $? -ne 0 ]; then
            echo "Failed to download BOSL2 library"
            exit 1
        fi
        unzip -q master.zip -d parts
        mv parts/BOSL2-master parts/BOSL2
        rm -f master.zip
    fi
}

# Function to render files
render_files() {
    for FILE in $SRC; do
        STL_FILE=output/cam/$(basename -s .scad $FILE).stl
        SRC_FILE=output/cad/$(basename $FILE)
        
        for FPRZ in 40 130 220; do
            IMG_FILE=output/images/$(basename -s .scad $FILE)_$FPRZ.png
            echo "Rendering $(basename $FILE) into $(basename $IMG_FILE)..."
            docker run \
                --init \
                -v $(pwd):/openscad \
                -u $(id -u ${USER}):$(id -g ${USER}) \
                openscad/openscad:latest \
                xvfb-run -a \
                    openscad --render --autocenter \
                    --camera=0,0,0,70,0,$FPRZ,300 --projection=ortho \
                    -o $IMG_FILE -o $STL_FILE $FILE && cp $FILE $SRC_FILE
        done
    done
}

# Download BOSL2 library
download_bosl2

# Render files to PNG and generate STL
render_files

# Remove temporary BOSL2 library
rm -rf parts/BOSL2/