#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -i <input_dir> -o <output_dir>"
    exit 1
}

# Parse command line options using getopts
while getopts ":i:o:" opt; do
    case $opt in
        i) input_dir="$OPTARG" ;;
        o) output_dir="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if all required options are provided
if [ -z "$input_dir" ] || [ -z "$output_dir" ]; then
    usage
fi

move_and_rename_files() {
    local input_dir="$1"
    local output_dir="$2"

    # Create the parent output directory if it doesn't exist
    mkdir -p "$output_dir"

    # Loop through each video directory in the input directory
    for video_dir in "$input_dir"/*; do
        if [ -d "$video_dir" ]; then
            video_dir_name=$(basename "$video_dir")

            # Define the target directory for the video in the output structure
            target_video_dir="$output_dir/$video_dir_name"
            mkdir -p "$target_video_dir"

            # Loop through each subdirectory within the video directory
            for sub_dir in "$video_dir"/*; do
                if [ -d "$sub_dir" ]; then
                    sub_dir_name=$(basename "$sub_dir")

                    # Define the path to the inpaint_out.mp4 file
                    inpaint_out_file="$sub_dir/inpaint_out.mp4"

                    # Check if the inpaint_out.mp4 file exists and move it
                    if [ -f "$inpaint_out_file" ]; then
                        new_name="${sub_dir_name}.mp4"
                        target_file_path="$target_video_dir/$new_name"
                        mv "$inpaint_out_file" "$target_file_path"
                        echo "Moved and renamed $inpaint_out_file to $target_file_path"
                    else
                        echo "File $inpaint_out_file does not exist in $sub_dir"
                    fi
                fi
            done
        fi
    done

    echo "All files have been processed and moved to their respective video directories."
}

# Call the function with input and output directories
move_and_rename_files "$input_dir" "$output_dir"
