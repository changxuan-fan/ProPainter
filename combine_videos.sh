#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -p <parent_directory> -o <output_directory> -t <temp_file>"
    exit 1
}

# Parse command line options using getopts
while getopts ":p:o:t:" opt; do
    case $opt in
        p) PARENT_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        t) TEMP_FILE="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if all required options are provided
if [ -z "$PARENT_DIR" ] || [ -z "$OUTPUT_DIR" ] || [ -z "$TEMP_FILE" ]; then
    usage
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Array to store commands for each GPU
declare -a gpu_commands

# Number of GPUs
num_gpus=$(nvidia-smi -L | wc -l)

# Initialize commands for each GPU
for ((i = 0; i < num_gpus; i++)); do
    gpu_commands[$i]=""
done

# Loop through each subdirectory in the parent directory
subdir_index=0
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

        # Assign the command to the appropriate GPU
        gpu_index=$((subdir_index % num_gpus))
        gpu_commands[$gpu_index]+="CUDA_VISIBLE_DEVICES=$gpu_index ffmpeg -y -vsync 0 -hwaccel nvdec -f concat -safe 0 -i \"$TEMP_FILE\"  \"$OUTPUT_DIR/$SUBDIR_NAME.mp4\"; "

        subdir_index=$((subdir_index + 1))
    fi
done

# Execute the commands for each GPU
for ((i = 0; i < num_gpus; i++)); do
    if [ -n "${gpu_commands[$i]}" ]; then
        eval "(${gpu_commands[$i]}) &"
    fi
done

# Wait for all background processes to finish
wait

# Remove the temporary file list
rm "$TEMP_FILE"

echo "All videos have been combined and stored in $OUTPUT_DIR."
