#!/bin/bash

output_file="shell_test_nnodes001.txt"

# Write the header
printf "Number_of_cores \t Number_of_nodes \t Runtime_sec \n" > "$output_file"

for f in fesom2_dist*.out; do
    cores=$(tail -5 "$f" | head -1 | awk '{print $NF}') # NF: number of fields (NF: last field, NF-1: second-to-last...)
    runtime=$(tail -4 "$f" | head -1 | awk '{print $(NF-1)}')
    
    # Extract number of nodes from filename
    # Split name by underscore and find the part after "dist"

    IFS='_' read -ra parts <<< "$f"
    nodes=-1
    found_dist=false
    for i in "${!parts[@]}"; do
        if [[ "${parts[$i]}" == *"dist"* ]]; then
            found_dist=true
        elif $found_dist; then
            # This is the part after "dist"
            if [[ "${parts[$i]}" =~ ^n([0-9]+) ]]; then
                # Extract number after 'n' and remove leading zeros
                nodes=$((10#${BASH_REMATCH[1]}))
            fi
            break
        fi
    done

    # Sanity check: cores must be a positive integer, runtime a positive float
    if [[ "$cores" =~ ^[1-9][0-9]*$ ]] && [[ "$runtime" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        printf "%s\t%s\t%s\n" "$cores" "$nodes" "$runtime" >> "$output_file"
    else
        echo "Skipping $f: invalid values (cores='$cores', runtime='$runtime')"
    fi

done

echo "Done. Result written to $output_file."