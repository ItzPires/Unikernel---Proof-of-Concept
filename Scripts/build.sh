#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_binary> [additional_parameters]"
    exit 1
fi

BINARY="$1"
shift # Shift the arguments to have the parameters to start the binary

# Check if the file exists
if [ ! -f "$BINARY" ]; then
    echo "Error: The file '$BINARY' does not exist."
    exit 1
fi

FILE=$(file "$BINARY")

# Check if the file is static
if ! echo "$FILE" | grep -q "statically linked"; then
    echo "The file '$BINARY' cannot be used because it has not been statically compiled.
Compile the executable with the -static flag."
    exit 1
fi

# Go to kernel folder
if ! cd ../kernel 2>/dev/null; then
        echo "Error: Could not access the 'kernel' directory. Please check if the submodules are initialized."
        exit 1
fi

# Compiling the kernel
echo "Compiling the kernel now..."
#make defconfig
#make -j$(nproc)

# Test - Execute Binary
echo "Starting the binary with parameters: $@"
"$BINARY" "$@"