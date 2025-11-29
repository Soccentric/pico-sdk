#!/bin/bash

# Parse command line options
while getopts "p:b:" opt; do
  case $opt in
    p) PROJECT="$OPTARG" ;;
    b) BOARD="$OPTARG" ;;
    *) echo "Usage: $0 -p <project_path> -b <board>" >&2; exit 1 ;;
  esac
done

# Check if PROJECT and BOARD are provided
if [ -z "$PROJECT" ] || [ -z "$BOARD" ]; then
  echo "Error: Both -p <project_path> and -b <board> must be provided" >&2
  exit 1
fi

# Source Zephyr environment
source /workspace/zephyrproject/zephyr/zephyr-env.sh

# Change to project directory
cd "$PROJECT" || { echo "Error: Cannot change to directory $PROJECT" >&2; exit 1; }

# Build the project
west build -b "$BOARD" .