#!/bin/bash
# benchmark_fesom2.sh - Tests various node/task configurations

# Configuration matrix to test
# With 389 vertices, test configurations that balance work distribution
NODES_TO_TEST="1"
TASKS_PER_NODE_TO_TEST="8"

# Create results directory
BENCH_DIR="benchmark_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BENCH_DIR"

echo "Starting FESOM2 benchmark suite"
echo "Results will be stored in: $BENCH_DIR"
echo "Configuration matrix:"
echo "  Nodes: $NODES_TO_TEST"
echo "  Tasks per node: $TASKS_PER_NODE_TO_TEST"
echo ""

# Track submitted jobs
job_list=""

for nodes in $NODES_TO_TEST; do
    for tasks in $TASKS_PER_NODE_TO_TEST; do
        total_mpi=$((nodes * tasks))
        
        # Skip if total MPI ranks exceeds reasonable limit
        if [ $total_mpi -gt 512 ]; then
            echo "Skipping ${nodes}n × ${tasks}t (${total_mpi} total ranks - too many)"
            continue
        fi
        
        # Create unique job name
        job_name="bench_${nodes}n_${tasks}t"
        
        echo "Submitting: $nodes nodes × $tasks tasks/node = $total_mpi MPI ranks ($(echo "scale=1; 389/$total_mpi" | bc) vertices/rank avg)"
        
        # Submit job with modified parameters
        jobid=$(sbatch --parsable <<EOF
#!/bin/bash
#SBATCH --account=clidyn.p_clidyn_work
#SBATCH --job-name=${job_name}
#SBATCH --partition=mpp
#SBATCH --time=00:30:00
#SBATCH --qos=30min
#SBATCH --nodes=${nodes}
#SBATCH --tasks-per-node=${tasks}
#SBATCH --cpus-per-task=1
#SBATCH -o ${BENCH_DIR}/fesom2_${job_name}_%j.out
#SBATCH -e ${BENCH_DIR}/fesom2_${job_name}_%j.out
#SBATCH --hint=nomultithread

module purge 
source ../env/albedo/shell
export OMP_NUM_THREADS=2
ulimit -s unlimited

# Determine JOBID
JOBID=\$(echo \$SLURM_JOB_ID | cut -d"." -f1)

ln -s ../bin/fesom.x .
cp -n ../config/namelist.config  .
cp -n ../config/namelist.forcing .
cp -n ../config/namelist.oce     .
cp -n ../config/namelist.dyn     .
cp -n ../config/namelist.tra     .
cp -n ../config/namelist.ice     .
cp -n ../config/namelist.io      .
cp -n ../config/namelist.icepack .

# Copy namelist files
RESULT_PATH=\$(grep "ResultPath" ./namelist.config \\
    | tr -d ' \t' \\
    | cut -d'=' -f2- \\
    | cut -d'!' -f1 \\
    | tr -d " '")
cp ./namelist.config "\$RESULT_PATH"
cp ./namelist.oce "\$RESULT_PATH"
cp ./namelist.dyn "\$RESULT_PATH"
cp ./namelist.tra "\$RESULT_PATH"
cp ./namelist.io "\$RESULT_PATH"

# Log configuration
echo "========================================" 
echo "BENCHMARK CONFIGURATION"
echo "Nodes: ${nodes}"
echo "Tasks per node: ${tasks}"
echo "Total MPI ranks: ${total_mpi}"
echo "OMP threads per task: \$OMP_NUM_THREADS"
echo "Total cores: \$((${total_mpi} * 2))"
echo "Vertices per rank (avg): \$(echo 'scale=2; 389/${total_mpi}' | bc)"
echo "========================================"
echo ""

# Record start time
echo "START_TIME: \$(date +%s)"
START_TIME=\$(date +%s)

date
srun --mpi=pmi2 ./fesom.x

# Record end time
END_TIME=\$(date +%s)
echo "END_TIME: \$END_TIME"
ELAPSED=\$((END_TIME - START_TIME))
echo "ELAPSED_SECONDS: \$ELAPSED"
echo "ELAPSED_TIME: \$(date -ud "@\$ELAPSED" +%H:%M:%S)"
date

# Log to summary file
echo "${nodes},${tasks},${total_mpi},\$ELAPSED" >> ${BENCH_DIR}/timing_summary.csv
EOF
)
        
        if [ -n "$jobid" ]; then
            job_list="$job_list $jobid"
            echo "  Submitted as job $jobid"
        else
            echo "  ERROR: Failed to submit"
        fi
        
        # Small delay to avoid overwhelming scheduler
        sleep 0.5
    done
done

echo ""
echo "All jobs submitted!"
echo "Job IDs: $job_list"
echo ""
echo "Monitor with: squeue -u \$USER"
echo "Or track specific jobs: squeue -j $(echo $job_list | tr ' ' ',')"
echo ""
echo "Results directory: $BENCH_DIR"