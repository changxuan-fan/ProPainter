#!/bin/bash

# Parent directory containing subdirectories with videos
PARENT_DIR="results_extracted"
# Directory to store combined videos
OUTPUT_DIR="results_combined"
# Temporary file to store file list
TEMP_FILE="file_list.txt"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through each subdirectory in the parent directory
for SUBDIR in "$PARENT_DIR"/*; do
    if [ -d "$SUBDIR" ]; then
        # Clear the temporary file list
        > "$TEMP_FILE"
        # List all video files in the subdirectory
        for VIDEO_FILE in "$SUBDIR"/*; do
            echo "file '$VIDEO_FILE'" >> "$TEMP_FILE"
        done

        # Get the name of the subdirectory
        SUBDIR_NAME=$(basename "$SUBDIR")

        # Combine the videos in the subdirectory with GPU acceleration and overwrite
        ffmpeg -y -vsync 0 -hwaccel nvdec -hwaccel_output_format cuda -f concat -safe 0 -i "$TEMP_FILE" -c:v h264_nvenc "$OUTPUT_DIR/$SUBDIR_NAME.mp4"
    fi
done

# Remove the temporary file list
rm "$TEMP_FILE"

echo "All videos have been combined and stored in $OUTPUT_DIR."
