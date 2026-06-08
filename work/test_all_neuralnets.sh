#!/bin/bash

CONFIG_FILE="./namelist.config"
OCE_FILE="./namelist.oce"
JOB_FILE="./job_albedo"
CSV_FILE="./260326_wandb_test_runs.csv"

# Read strings from second column of CSV file
# Skip header if present (remove 'tail -n +2' if no header)
# Read only first 10 strings (plus 1 for header = 11 lines total)
strings=($(awk -F',' '{print $2}' "$CSV_FILE" | tail -n +2 | head -n 10))

# Loop through each string
for string in "${strings[@]}"; do
    echo "Processing: $string"
    
    # Modify ResultPath in CONFIG_FILE
    sed -i "s|ResultPath=.*|ResultPath='/albedo/work/projects/p_clidyn_work/rjuhrban/double_gyre/m100/results/spinup_online_validation_none/after_spinup_with_NN/$string/'|" "$CONFIG_FILE"
    
    # Modify which_NN in OCE_FILE
    sed -i "s|which_NN=.*|which_NN='$string'|" "$OCE_FILE"

    # Modify job_name in job_albedo
    sed -i "s|#SBATCH --job-name=.*|#SBATCH --job-name=nn_restart_$string|" "$JOB_FILE"
    
    # Run the test script
    ./test_neuralnet.sh
    
    echo "Completed: $string"
    echo "---"
done

echo "All iterations completed"