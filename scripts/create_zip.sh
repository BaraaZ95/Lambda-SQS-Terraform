#!/bin/bash

# Clean up previous builds
rm -f lambda_function.zip
rm -rf package


# Create a directory to install dependencies
mkdir -p package

# Install dependencies
pip install --target ./package -r lambda/requirements.txt

# Copy the lambda_function.py to the package directory
cp lambda/lambda_function.py package/

# Move to the package directory and zip everything up
cd package
zip -r ../lambda_function.zip .

# Go back to the original directory
cd ..