#!/bin/bash

# Fetch AWS_ACCESS_KEY_ID from environment
AWS_ACCESS_KEY_ID=$(printenv AWS_ACCESS_KEY_ID)

# Check if AWS_ACCESS_KEY_ID is set
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID is not set in the environment."
  exit 1
fi

# Write to .env file
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> .env

echo "AWS_ACCESS_KEY_ID has been added to .env file."
