#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_KERNEL_DIR="$SCRIPT_DIR/Kernel/"

# Function to apply PREEMPT-RT patch
apply_preempt_rt_patch() {
    echo "Checking for PREEMPT-RT patch..."
    
    # Check if the kernel already has PREEMPT-RT applied
    if ! grep -q "CONFIG_PREEMPT_RT" $SCRIPT_DIR/../kernel/.config; then
        echo "Applying PREEMPT-RT patch..."

        # Download PREEMPT-RT patch if not present
        PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/6.12/older/patch-6.12-rc1-rt1.patch.xz"
        PATCH_DIR="$SCRIPT_DIR/../kernel"

        # Download and apply the patch
        curl -L $PATCH_URL -o "$PATCH_DIR/patch-6.12-rc1-rt1.patch.xz"
        cd $PATCH_DIR && xz -d patch-6.12-rc1-rt1.patch.xz
        patch -p1 < patch-6.12-rc1-rt1.patch.xz
    else
        echo "PREEMPT-RT patch already applied."
    fi
}

# Enable CONFIG_EXPERT and CONFIG_PREEMPT_RT
enable_expert_and_rt() {
    echo "Enabling CONFIG_EXPERT and CONFIG_PREEMPT_RT..."

    # Edit the .config file to enable CONFIG_EXPERT
    #echo "CONFIG_EXPERT=y" >> $SCRIPT_DIR/../kernel/.config

    # Enable CONFIG_PREEMPT_RT if not already enabled
    #if ! grep -q "CONFIG_PREEMPT_RT" $SCRIPT_DIR/../kernel/.config; then
    #    echo "Enabling CONFIG_PREEMPT_RT..."
    #    echo "CONFIG_PREEMPT_RT=y" >> $SCRIPT_DIR/../kernel/.config
    #fi

    # Copy the config file
    cp $SCRIPT_DIR/Templates/config_kernel $SCRIPT_DIR/../kernel/.config
}

# Check if the first argument is provided
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
make defconfig # Create defconfig
apply_preempt_rt_patch # Apply the PREEMPT-RT patch
enable_expert_and_rt # Enable CONFIG_EXPERT and CONFIG_PREEMPT_RT
make -j$(nproc) # Compile the kernel

# Image creation
echo "Preparing the image..."
mkdir -p $SCRIPT_DIR/../Output/RAW/initramfs/{bin,sbin,etc,proc,sys,newroot,scripts,lib,lib64}
cp "$BINARY" $SCRIPT_DIR/../Output/RAW/initramfs/bin/
chmod 777 $SCRIPT_DIR/../Output/RAW/initramfs/$BINARY_BIN

# Copy the scripts to scripts folder
cp "$SCRIPTS_KERNEL_DIR/mount_all_disks" "$SCRIPT_DIR/../Output/RAW/initramfs/scripts/"
chmod +x $SCRIPT_DIR/../Output/RAW/initramfs/scripts/mount_all_disks

# Program initiation file in unikernel
INIT_TEMPLATE_FILE="$SCRIPTS_KERNEL_DIR/init"
INIT_FILE="$SCRIPT_DIR/../Output/RAW/initramfs/init"
BINARY_AND_ARGS="$BINARY_BIN $@"
sed "s#{{BINARY_AND_ARGS}}#$BINARY_AND_ARGS#g" "$INIT_TEMPLATE_FILE" > "$INIT_FILE"
chmod 777 $INIT_FILE

chmod +x $SCRIPT_DIR/../Output/RAW/initramfs/init

# Image compilation
cp -a /bin/busybox $SCRIPT_DIR/../Output/RAW/initramfs/bin/
cd $SCRIPT_DIR/../Output/RAW/initramfs/bin

sudo cp $(which mke2fs) $SCRIPT_DIR/../Output/RAW/initramfs/sbin/
sudo cp /lib/x86_64-linux-gnu/libext2fs.so.2 $SCRIPT_DIR/../Output/RAW/initramfs/lib/
sudo cp /lib/x86_64-linux-gnu/libcom_err.so.2 $SCRIPT_DIR/../Output/RAW/initramfs/lib/
sudo cp /lib/x86_64-linux-gnu/libblkid.so.1 $SCRIPT_DIR/../Output/RAW/initramfs/lib/
sudo cp /lib/x86_64-linux-gnu/libuuid.so.1 $SCRIPT_DIR/../Output/RAW/initramfs/lib/
sudo cp /lib/x86_64-linux-gnu/libe2p.so.2 $SCRIPT_DIR/../Output/RAW/initramfs/lib/
sudo cp /lib/x86_64-linux-gnu/libc.so.6 $SCRIPT_DIR/../Output/RAW/initramfs/lib/
sudo cp /lib64/ld-linux-x86-64.so.2 $SCRIPT_DIR/../Output/RAW/initramfs/lib64/

sudo chmod 777 $SCRIPT_DIR/../Output/RAW/initramfs/sbin/mke2fs
sudo chmod 777 $SCRIPT_DIR/../Output/RAW/initramfs/lib/*
sudo chmod 777 $SCRIPT_DIR/../Output/RAW/initramfs/lib64/*

for i in $(./busybox --list); do ln -s busybox $i; done
cd ../
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../image.img
cd ..

# Remove aux files
rm -r initramfs

# Done
echo "Unikernel Compiled"
