#!/bin/bash
set -e

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Create a temporary directory for the layer
LAYER_DIR=$(mktemp -d)

# Install the requirements into the temporary directory
pip install --platform=manylinux2014_x86_64 --implementation=cp --only-binary=:all: -r "${SCRIPT_DIR}/lambda/requirements.txt" -t "${LAYER_DIR}/python"

# Create the zip file in the script directory
cd "${LAYER_DIR}"
zip -r "${SCRIPT_DIR}/lambda-layer.zip" python

# Clean up
cd "${SCRIPT_DIR}"
rm -rf "${LAYER_DIR}"

echo "Lambda layer created: ${SCRIPT_DIR}/lambda-layer.zip"
ls -l "${SCRIPT_DIR}/lambda-layer.zip"  # List the created zip file
