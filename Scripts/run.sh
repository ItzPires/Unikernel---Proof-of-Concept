#!/bin/bash

ERROR_FOUND=false

KERNEL="../kernel/arch/x86_64/boot/bzImage"
IMAGE="../Output/image.img"

if [ ! -f "$KERNEL" ]; then
    echo "Error: The Kernel does not exist."
    ERROR_FOUND=true
fi

if [ ! -f "$IMAGE" ]; then
    echo "Error: The Image file does not exist."
    ERROR_FOUND=true
fi

if [ "$ERROR_FOUND" = true ]; then
    echo "Run build.sh"
    exit 1
fi

echo "Running Unikernel"
qemu-system-x86_64 -kernel "$KERNEL" -initrd "$IMAGE" -append "console=ttyS0" -nographic
