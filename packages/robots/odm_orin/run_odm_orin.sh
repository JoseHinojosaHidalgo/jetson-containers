#!/bin/bash

# Script parameters - can be overridden by command line arguments
DIRECTORY_NAME="${1:-svl}"
ORTHOPHOTO_RESOLUTION="${2:-0.1}"
MESH_SIZE="${3:-4000}"
TARGET_FACE_NUM="${4:-8000}"

# Display usage information
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [DIRECTORY_NAME] [ORTHOPHOTO_RESOLUTION] [MESH_SIZE] [TARGET_FACE_NUM]"
    echo "Default values:"
    echo "  DIRECTORY_NAME: svl"
    echo "  ORTHOPHOTO_RESOLUTION: 0.1"
    echo "  MESH_SIZE: 4000"
    echo "  TARGET_FACE_NUM: 8000"
    echo ""
    echo "Example: $0 my_project 0.05 2000 4000"
    exit 0
fi

echo "Starting ODM processing with parameters:"
echo "  Directory: $DIRECTORY_NAME"
echo "  Orthophoto Resolution: $ORTHOPHOTO_RESOLUTION"
echo "  Initial Mesh Size: $MESH_SIZE"
echo "  Initial Target Face Number: $TARGET_FACE_NUM"
echo "---"

# Function to run the command with real-time output and error capture
run_command() {
    local mesh_size=$1
    local target_face_num=$2
    local directory=$3
    local ortho_res=$4
    
    echo "Running command with MESH_SIZE=${mesh_size} and TARGET_FACE_NUM=${target_face_num}"
    echo "Command starting at: $(date)"
    
    # Build the command with current parameters
    local bash_command="bash -c 'rm -rf /datasets/${directory}/cameras.json /datasets/${directory}/images.json /datasets/${directory}/benchmark.txt /datasets/${directory}/options.json /datasets/${directory}/img_list.txt /datasets/${directory}/log.json /datasets/${directory}/odm* /datasets/${directory}/opensfm/ && \
python3 /code/run.py --project-path /datasets ${directory} --orthophoto-resolution=${ortho_res} --fast-orthophoto --skip-band-alignment --skip-report --mesh-size=${mesh_size} --matcher-type=flann || \
valgrind -s --tool=memcheck --leak-check=full --show-leak-kinds=all /code/SuperBuild/install/bin/OpenMVS/ReconstructMesh -i \"/datasets/${directory}/odm_meshing/odm_25dmesh.dirty.ply\" -o \"/datasets/${directory}/odm_meshing/odm_25dmesh.ply\" --archive-type 3 --remove-spikes 0 --remove-spurious 20 --smooth 0 --target-face-num ${target_face_num} -v 0 && \
python3 /code/run.py --project-path /datasets ${directory} --orthophoto-resolution=${ortho_res} --fast-orthophoto --skip-band-alignment --skip-report --mesh-size=${mesh_size} --matcher-type=flann'"
    
    # Create a temporary file to capture output for error checking
    local temp_output_file=$(mktemp)
    
    # Execute the command with tee to show real-time output AND capture it
    eval "$bash_command" 2>&1 | tee "$temp_output_file"
    local exit_status=${PIPESTATUS[0]}
    
    # Read the captured output for error checking
    COMMAND_OUTPUT=$(cat "$temp_output_file")
    rm "$temp_output_file"
    
    echo "Command finished at: $(date) with exit status: $exit_status"
    return $exit_status
}

# Loop until odm_orthophoto.tif is created
while [ ! -f "/datasets/${DIRECTORY_NAME}/odm_orthophoto/odm_orthophoto.tif" ]; do
    echo "Checking for output file: /datasets/${DIRECTORY_NAME}/odm_orthophoto/odm_orthophoto.tif"
    
    # Run the command (output will be shown in real-time)
    run_command "$MESH_SIZE" "$TARGET_FACE_NUM" "$DIRECTORY_NAME" "$ORTHOPHOTO_RESOLUTION"
    command_exit_status=$?
    
    # Check for corrupted size error in the captured output
    if echo "$COMMAND_OUTPUT" | grep -q "corrupted size"; then
        echo "---"
        echo "Corrupted size change detected. Dividing mesh_size and target-face-num by two."
        MESH_SIZE=$((MESH_SIZE / 2))
        TARGET_FACE_NUM=$((TARGET_FACE_NUM / 2))
        
        # Ensure values don't go below 1
        if [ "$MESH_SIZE" -lt 1 ]; then
            MESH_SIZE=1
        fi
        if [ "$TARGET_FACE_NUM" -lt 1 ]; then
            TARGET_FACE_NUM=1
        fi
        
        echo "New MESH_SIZE: $MESH_SIZE, New TARGET_FACE_NUM: $TARGET_FACE_NUM"
        echo "---"
    elif [ $command_exit_status -ne 0 ]; then
        echo "---"
        echo "Command failed with exit status $command_exit_status. Retrying..."
        echo "---"
    else
        echo "---"
        echo "Command completed successfully. Waiting 1 second before checking for the file."
        echo "---"
    fi
    
    sleep 1
done

echo "---"
echo "SUCCESS: /datasets/${DIRECTORY_NAME}/odm_orthophoto/odm_orthophoto.tif has been created!"
echo "Final parameters used:"
echo "  Directory: $DIRECTORY_NAME"
echo "  Orthophoto Resolution: $ORTHOPHOTO_RESOLUTION"
echo "  Final Mesh Size: $MESH_SIZE"
echo "  Final Target Face Number: $TARGET_FACE_NUM"
echo "Script finished at: $(date)"
echo "---"