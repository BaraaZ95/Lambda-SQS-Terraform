#!/bin/bash
set -ex  # Add -x for verbose output

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Create a temporary directory for the layer
LAYER_DIR=$(mktemp -d)
echo "Created temporary directory: ${LAYER_DIR}"

# Install the requirements into the temporary directory
pip install --platform=manylinux2014_x86_64 --implementation=cp --only-binary=:all: -r "${SCRIPT_DIR}/lambda/requirements.txt" -t "${LAYER_DIR}/python"

# List contents of the temporary directory
echo "Contents of ${LAYER_DIR}/python:"
ls -R "${LAYER_DIR}/python"

# Create the zip file in the script directory
cd "${LAYER_DIR}"
zip -r "${SCRIPT_DIR}/layer/lambda-layer.zip" python

# List contents of the zip file
echo "Contents of lambda-layer.zip:"
unzip -l "${SCRIPT_DIR}/layer/lambda-layer.zip"

# Clean up
cd "${SCRIPT_DIR}"
rm -rf "${LAYER_DIR}"

echo "Lambda layer created: ${SCRIPT_DIR}/layer/lambda-layer.zip"
ls -l "${SCRIPT_DIR}/layer/lambda-layer.zip"  # List the created zip file
echo "Size of lambda-layer.zip: $(du -h ${SCRIPT_DIR}/layer/lambda-layer.zip | cut -f1)"#!/bin/bash
set -ex  # Add -x for verbose output

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Create a temporary directory for the layer
LAYER_DIR=$(mktemp -d)
echo "Created temporary directory: ${LAYER_DIR}"

# Install the requirements into the temporary directory
pip install --platform=manylinux2014_x86_64 --implementation=cp --only-binary=:all: -r "${SCRIPT_DIR}/lambda/requirements.txt" -t "${LAYER_DIR}/python"

# List contents of the temporary directory
echo "Contents of ${LAYER_DIR}/python:"
ls -R "${LAYER_DIR}/python"

# Create the zip file in the script directory
cd "${LAYER_DIR}"
zip -r "${SCRIPT_DIR}/layer/lambda-layer.zip" python

# List contents of the zip file
echo "Contents of lambda-layer.zip:"
unzip -l "${SCRIPT_DIR}/layer/lambda-layer.zip"

# Clean up
cd "${SCRIPT_DIR}"
rm -rf "${LAYER_DIR}"

echo "Lambda layer created: ${SCRIPT_DIR}/layer/lambda-layer.zip"
ls -l "${SCRIPT_DIR}/layer/lambda-layer.zip"  # List the created zip file
echo "Size of lambda-layer.zip: $(du -h ${SCRIPT_DIR}/layer/lambda-layer.zip | cut -f1)"