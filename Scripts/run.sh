#!/bin/bash

ERROR_FOUND=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KERNEL="$SCRIPT_DIR/../kernel/arch/x86_64/boot/bzImage"
KERNEL=$(readlink -f "$KERNEL")
IMAGE="$SCRIPT_DIR/../Output/image.img"

usage() {
    echo "Usage: $0 -t <target>"
    exit 1
}

# Check number of arguments
if [ "$#" -ne 2 ]; then
    usage
fi

# Process arguments
while getopts "t:" opt; do
  case $opt in
    t) TARGET="$OPTARG" ;;
    *) usage ;;
  esac
done

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

if [ "$TARGET" = "qemu" ]; then
    echo "Running Unikernel"
    qemu-system-x86_64 -kernel "$KERNEL" -initrd "$IMAGE" -append "console=ttyS0" -enable-kvm -nographic

elif [ "$TARGET" = "vmware" ]; then
echo "Building Unikernel to VMWare"
IMAGE_NAME="disk"
IMAGE_DNAME="$IMAGE_NAME.img"
MOUNT_DIR="/mnt/disk"

# Calculate the size of the image in KB
BOOT_DIR_TEMP="$SCRIPT_DIR/../Output/boot_contents_temp"
GRUB_DIR="/usr/lib/grub/i386-pc"

# Create a temporary directory for boot contents
mkdir -p "$BOOT_DIR_TEMP"
cp "$KERNEL" "$BOOT_DIR_TEMP/" # Copy the kernel
cp "$IMAGE" "$BOOT_DIR_TEMP/" # Copy the image
cp -r "$GRUB_DIR" "$BOOT_DIR_TEMP/grub/i386-pc" # Copy the grub files

# Calculate the size of the image in KB
TOTAL_SIZE_KB=$(du -sk "$BOOT_DIR_TEMP" | awk '{print $1}')
TOTAL_SIZE_KB=$((TOTAL_SIZE_KB + 2048)) # 2 MB for extra space

echo "Creating a disk image"
dd if=/dev/zero of=$IMAGE_DNAME bs=1K count=$TOTAL_SIZE_KB

LOOP_DEVICE=$(sudo losetup -fP --show $IMAGE_DNAME)

(
echo n   # New partition
echo p   # Primary partition
echo 1   # One partition
echo     # Default start sector
echo     # Default end sector
echo w   # Write
) | sudo fdisk $LOOP_DEVICE

sudo mkfs.ext4 ${LOOP_DEVICE}p1
sudo mkdir -p $MOUNT_DIR
sudo mount ${LOOP_DEVICE}p1 $MOUNT_DIR

sudo grub-install --boot-directory=$MOUNT_DIR/boot --target=i386-pc $LOOP_DEVICE

echo "Copying files to Image"
sudo cp $KERNEL $MOUNT_DIR/boot/
sudo cp $IMAGE $MOUNT_DIR/boot/

cat <<EOF > $MOUNT_DIR/boot/grub/grub.cfg
set default=0
set timeout=0

menuentry "Unikernel" {
    linux /boot/bzImage
    initrd /boot/image.img
}
EOF

sudo umount $MOUNT_DIR

qemu-img convert -f raw -O vmdk $IMAGE_DNAME "$SCRIPT_DIR/../Output/$IMAGE_NAME".vmdk

rm -r $IMAGE_DNAME
rm -r $BOOT_DIR_TEMP
fi
