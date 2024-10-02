#!/bin/bash

ERROR_FOUND=false

KERNEL="../kernel/arch/x86_64/boot/bzImage"
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
    qemu-system-x86_64 -kernel "$KERNEL" -initrd "$IMAGE" -append "console=ttyS0" -nographic

elif [ "$TARGET" = "vmware" ]; then
echo "Building Unikernel to VMWare"
IMAGE_SIZE_MB=100
IMAGE_NAME="disk"
IMAGE_DNAME="$IMAGE_NAME.img"
MOUNT_DIR="/mnt/disk"

echo "Criando imagem vazia de $IMAGE_SIZE_MB MB..."
dd if=/dev/zero of=$IMAGE_DNAME bs=1M count=$IMAGE_SIZE_MB

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
sudo grub-install --boot-directory=$MOUNT_DIR/boot $LOOP_DEVICE

echo "Copiando arquivos de kernel e imagem para o diretório de boot..."
sudo cp $KERNEL $MOUNT_DIR/boot/
sudo cp $IMAGE $MOUNT_DIR/boot/

echo "Criando o arquivo grub.cfg..."
cat <<EOF > $MOUNT_DIR/boot/grub/grub.cfg
menuentry "Unikernel" {
    linux /boot/bzImage
    initrd /boot/image.img
}
EOF

sudo umount /mnt/disk

qemu-img convert -f raw -O vmdk $IMAGE_DNAME "../Output/$IMAGE_NAME".vmdk

rm -r $IMAGE_DNAME
fi
