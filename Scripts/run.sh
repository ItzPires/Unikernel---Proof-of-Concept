#!/bin/bash

ERROR_FOUND=false

KERNEL="../kernel/arch/x86_64/boot/bzImage"
KERNEL=$(readlink -f "$KERNEL")
IMAGE="../Output/image.img"

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
BOOT_DIR_TEMP="../Output/boot_contents_temp"
GRUB_DIR="/usr/lib/grub/i386-pc"

# Create a temporary directory for boot contents
mkdir -p "$BOOT_DIR_TEMP"
cp "$KERNEL" "$BOOT_DIR_TEMP/" # Copy the kernel
cp "$IMAGE" "$BOOT_DIR_TEMP/" # Copy the image
cp -r "$GRUB_DIR" "$BOOT_DIR_TEMP/grub/i386-pc" # Copy the grub files

# Calculate the size of the image in KB
TOTAL_SIZE_KB=$(du -sk "$BOOT_DIR_TEMP" | awk '{print $1}')
TOTAL_SIZE_KB=$((TOTAL_SIZE_KB + 2048)) # 2 MB for extra space

echo "Criando imagem vazia de $TOTAL_SIZE_KB KB..."
dd if=/dev/zero of=$IMAGE_DNAME bs=1K count=$TOTAL_SIZE_KB

echo "Associando imagem ao dispositivo loop..."
LOOP_DEVICE=$(sudo losetup -fP --show $IMAGE_DNAME)

echo "Dispositivo associado: $LOOP_DEVICE"

echo "Criando partição na imagem usando fdisk..."
(
echo n   # Adiciona uma nova partição
echo p   # Partição primária
echo 1   # Número da partição
echo     # Primeiro setor (padrão)
echo     # Último setor (padrão)
echo w   # Escreve as alterações
) | sudo fdisk $LOOP_DEVICE

echo "Formatando a partição em ext4..."
sudo mkfs.ext4 ${LOOP_DEVICE}p1

echo "Criando diretório de montagem em $MOUNT_DIR..."
sudo mkdir -p $MOUNT_DIR

echo "Montando a partição ${LOOP_DEVICE}p1 em $MOUNT_DIR..."
sudo mount ${LOOP_DEVICE}p1 $MOUNT_DIR

echo "Instalando o GRUB no dispositivo loop..."
sudo grub-install --boot-directory=$MOUNT_DIR/boot --target=i386-pc $LOOP_DEVICE

echo "Copiando arquivos de kernel e imagem para o diretório de boot..."
sudo cp $KERNEL $MOUNT_DIR/boot/
sudo cp $IMAGE $MOUNT_DIR/boot/

echo "Criando o arquivo grub.cfg..."
cat <<EOF > $MOUNT_DIR/boot/grub/grub.cfg
set default=0
set timeout=0

menuentry "Unikernel" {
    linux /boot/bzImage
    initrd /boot/image.img
}
EOF

sudo umount $MOUNT_DIR

qemu-img convert -f raw -O vmdk $IMAGE_DNAME "../Output/$IMAGE_NAME".vmdk

rm -r $IMAGE_DNAME
rm -r $BOOT_DIR_TEMP
fi
