#!/bin/bash
# Change to the FESOM2 directory and compile
cd /albedo/home/rjuhrban/fesom2/ || exit 1
echo "Compiling FESOM..."
if bash -l ./configure.sh; then
    echo "Compilation successful!"
else
    echo "Compilation failed! Exiting."
    exit 1
fi

# Change to the working directory
cd /albedo/home/rjuhrban/fesom2/work || exit 1

# Create results folder
# echo "Creating results folder..."
# /albedo/home/rjuhrban/create_results_folder.sh

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

echo "Copying output file to results folder..."



# Find the file containing the job ID
output_file=$(ls fesom2_*${job_id}.out 2>/dev/null)
if [ -n "$output_file" ]; then
    echo "Opening $output_file in vim at line 430..."
    vim +430 "$output_file"
else
    echo "No output file found for job ID $job_id!"
    exit 1
fi
