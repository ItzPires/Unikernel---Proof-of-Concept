#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 <path_to_binary> [additional_parameters]"
    exit 1
fi

BINARY="$1"
BINARY_BIN="/bin/$(basename "$BINARY")"
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
if ! cd $SCRIPT_DIR/../kernel 2>/dev/null; then
        echo "Error: Could not access the 'kernel' directory. Please check if the submodules are initialized."
        exit 1
fi

# Compiling the kernel
echo "Compiling the kernel now..."
make defconfig
make -j$(nproc)

# Image creation
echo "Preparing the image..."
mkdir -p $SCRIPT_DIR/../Output/RAW/initramfs/{bin,sbin,etc,proc,sys,newroot}
cp "$BINARY" $SCRIPT_DIR/../Output/RAW/initramfs/bin/

# Program initiation file in unikernel
cat << EOF > $SCRIPT_DIR/../Output/RAW/initramfs/init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
echo "[Unikernel Proof of Concept]"
$BINARY_BIN $@
poweroff -f
EOF

chmod +x $SCRIPT_DIR/../Output/RAW/initramfs/init

# Image compilation
cp -a /bin/busybox $SCRIPT_DIR/../Output/RAW/initramfs/bin/
cd $SCRIPT_DIR/../Output/RAW/initramfs/bin
for i in $(./busybox --list); do ln -s busybox $i; done
cd ../
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../image.img
cd ..

# Remove aux files
rm -r initramfs

# Done
echo "Unikernel Compiled"
