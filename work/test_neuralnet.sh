#!/bin/bash

# Change to the working directory
cd /albedo/home/rjuhrban/fesom2/work || exit 1

# Create results folder
echo "Creating results folder..."
/albedo/home/rjuhrban/fesom2/work/create_results_folder_neuralnet.sh

# Submit the SLURM job and capture the job ID
echo "Submitting job..."
job_output=$(sbatch job_albedo)
job_id=$(echo "$job_output" | grep -oP 'Submitted batch job \K\d+')

if [ -z "$job_id" ]; then
    echo "Failed to capture job ID!"
    exit 1
fi

echo "Job submitted with ID: $job_id"

# Wait for the job to finish by checking squeue
echo "Waiting for job to complete..."
counter=0
while squeue -j "$job_id" 2>/dev/null | grep -q "$job_id"; do
    sleep 1
    counter=$((counter + 1))
    
    # Every 60 seconds, print the status
    if [ $((counter % 60)) -eq 0 ]; then
        echo "--- Status at $((counter / 60)) minute(s) ---"
        squeue -j "$job_id"
        echo "---"
    fi
done

echo "Job finished!"

# Find the file containing the job ID
output_file=$(ls fesom2_*${job_id}.out 2>/dev/null)
# Copy output file to FINAL_FOLDER

# Function to extract value from namelist file
# Handles format: variable = 'value' or variable = value
extract_value() {
    local var_name="$1"
    local file="$2"

    # Search for the variable and extract its value
    # This handles both quoted strings and unquoted values
    grep -i "^[[:space:]]*${var_name}[[:space:]]*=" "$file" | \
        sed -E "s/^[[:space:]]*${var_name}[[:space:]]*=[[:space:]]*//i" | \
        sed -E "s/[[:space:]]*!.*$//" | \
        sed -E "s/^'(.*)'[[:space:]]*$/\1/" | \
        sed -E 's/^"(.*)"[[:space:]]*$/\1/' | \
        sed -E 's/[[:space:]]*$//' | \
        head -n 1
}
CONFIG_FILE="/albedo/home/rjuhrban/fesom2/work/namelist.config"
# Extract ResultPath from config file
RESULT_PATH=$(extract_value "ResultPath" "$CONFIG_FILE")
cp "$output_file" "$RESULT_PATH"
echo "Copied output file to $RESULT_PATH!"

if [ -n "$output_file" ]; then
    echo "Opening $output_file in vim..."
    vim +7855 "$output_file"
else
    echo "No output file found for job ID $job_id!"
    exit 1
fi
