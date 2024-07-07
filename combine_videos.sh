#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -i <input_dir>"
    exit 1
}

# Parse command line options using getopts
while getopts ":i:" opt; do
    case $opt in
        i) input_dir="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if the required option is provided
if [ -z "$input_dir" ]; then
    usage
fi

combine_videos() {
    local PARENT_DIR="$1"

    # Check if the parent directory exists
    if [ ! -d "$PARENT_DIR" ]; then
        echo "The directory $PARENT_DIR does not exist."
        exit 1
    fi

    # Create a combined directory
    local COMBINED_DIR="${PARENT_DIR}_combined"
    mkdir -p "$COMBINED_DIR"

    # Loop through each video directory
    for VIDEO_DIR in "$PARENT_DIR"/*; do
        if [ -d "$VIDEO_DIR" ]; then
            local OUTPUT_VIDEO="$COMBINED_DIR/$(basename "$VIDEO_DIR").mp4"
            local TEMP_LIST=$(mktemp)

            # Collect all subvideo files ending with .mp4
            for SUBVIDEO in "$VIDEO_DIR"/*.mp4; do
                if [ -f "$SUBVIDEO" ]; then
                    echo "file '$SUBVIDEO'" >> "$TEMP_LIST"
                fi
            done

            # Combine videos using GPU-accelerated ffmpeg if there are any mp4 files
            if [ -s "$TEMP_LIST" ]; then
                ffmpeg -hwaccel cuda -f concat -safe 0 -i "$TEMP_LIST" -c:v h264_nvenc -crf 18 "$OUTPUT_VIDEO"
            else
                echo "No .mp4 files found in $VIDEO_DIR"
            fi

            # Remove the temporary file list
            rm "$TEMP_LIST"
        fi
    done

    # Remove the original parent directory
    rm -rf "$PARENT_DIR"

    # Rename the combined directory to the original parent directory name
    mv "$COMBINED_DIR" "$PARENT_DIR"

    echo "All videos combined and stored in $PARENT_DIR"
}

# Call the function with the provided input directory
combine_videos "$input_dir"
