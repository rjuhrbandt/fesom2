#!/bin/bash

# Fixed location for namelist.config
CONFIG_FILE="/albedo/home/rjuhrban/fesom2/work/namelist.config"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found"
    exit 1
fi

echo "Reading configuration from: $CONFIG_FILE"
echo ""

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

# Extract ResultPath from config file
RESULT_PATH=$(extract_value "ResultPath" "$CONFIG_FILE")
YEAR_NEW=2008 # hard-coded: spinup starts at 1958, then +50y
YEAR_OLD=2007

# Validate inputs
if [ -z "$RESULT_PATH" ]; then
    echo "Error: ResultPath not found in config file"
    exit 1
fi

echo "Extracted values:"
echo "  ResultPath: $RESULT_PATH"
echo "  yearnew: $YEAR_NEW"
echo ""

# Extract neuralnet run id from namelist.oce
CONFIG_FILE="/albedo/home/rjuhrban/fesom2/work/namelist.oce"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found"
    exit 1
fi

echo "Reading neuralnet run id from: $CONFIG_FILE"
echo ""

WHICH_NN=$(extract_value "which_NN" "$CONFIG_FILE")

# Validate inputs
if [ -z "$WHICH_NN" ]; then
    echo "Error: which_NN not found in config file"
    exit 1
fi

echo "Extracted values:"
echo "  which_NN: $WHICH_NN"
echo ""

# Determine the final folder path to use
FINAL_FOLDER="$RESULT_PATH"

# Check if folder exists and contains files
if [ -d "$RESULT_PATH" ]; then
    # Check if folder contains any files (including hidden files)
    if [ -n "$(ls -A "$RESULT_PATH" 2>/dev/null)" ]; then
        echo "Warning: Folder '$RESULT_PATH' exists and contains files"
        echo "Deleting contents of '$RESULT_PATH'..."
        rm -rf "${RESULT_PATH}"/*
        rm -rf "${RESULT_PATH}"/.[!.]*
        echo "Contents deleted"
    fi
fi

# Create the folder if it doesn't exist
if [ ! -d "$FINAL_FOLDER" ]; then
    mkdir -p "$FINAL_FOLDER"
    echo "Created folder: $FINAL_FOLDER"
else
    echo "Using existing empty folder: $FINAL_FOLDER"
fi

# Create fesom.clock file for restart
CLOCK_FILE="$FINAL_FOLDER/fesom.clock"
echo "85200 365 $YEAR_OLD" > "$CLOCK_FILE"
echo "0 1 $YEAR_NEW" >> "$CLOCK_FILE"

echo "Created file: $CLOCK_FILE"
echo "Contents:"
cat "$CLOCK_FILE"

# Copy 2007 restart file from two directory levels above
cd $FINAL_FOLDER
cp -r ../../fesom.2007.oce.restart "$FINAL_FOLDER"
echo "Copied 2007 restart file into $FINAL_FOLDER"

echo ""
echo "Done!"