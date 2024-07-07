import os
import shutil

def move_and_rename_files(base_dir, target_dir):
    # Create the target directory if it doesn't exist
    os.makedirs(target_dir, exist_ok=True)

    # Loop through each subdirectory in the base directory
    for sub_dir in os.listdir(base_dir):
        sub_dir_path = os.path.join(base_dir, sub_dir)
        if os.path.isdir(sub_dir_path) and sub_dir.isdigit():
            # Define the path to the inpaint_out.mp4 file
            inpaint_out_file = os.path.join(sub_dir_path, "inpaint_out.mp4")

            # Check if the inpaint_out.mp4 file exists
            if os.path.isfile(inpaint_out_file):
                # Define the new name for the file
                new_name = f"{sub_dir}.mp4"
                target_file_path = os.path.join(target_dir, new_name)

                # Copy and rename the file to the target directory
                shutil.copy(inpaint_out_file, target_file_path)
            else:
                print(f"File {inpaint_out_file} does not exist.")

    print("All files have been processed and moved to", target_dir)

# Example usage
base_dir = "results"  # Change this to your base directory
target_dir = base_dir  # Change this to your target directory
move_and_rename_files(base_dir, target_dir)
