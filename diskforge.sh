#!/bin/bash
set -e

clear
echo "=== Setup HD v4.3 ==="
echo

USER_NAME=$(whoami)
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Garante que o script NÃO foi rodado como root diretamente
if [ "$USER_ID" -eq 0 ]; then
  echo "Erro: Execute o script com seu usuário normal (sem sudo)."
  exit 1
fi

echo "Discos disponíveis:"
lsblk -d -e 7,11 -o NAME,SIZE,MODEL
echo

read -p "Disco (ex: sda ou nvme0n1): " DISK

if [ ! -b "/dev/$DISK" ]; then
  echo "Erro: disco inválido"
  exit 1
fi

# Detecta disco do sistema (raiz) ignorando subvolumes BTRFS
ROOT_PART=$(findmnt -n -o SOURCE / | cut -d '[' -f 1)
ROOT_DISK=$(lsblk -no PKNAME "$ROOT_PART")

if [ "$DISK" == "$ROOT_DISK" ]; then
  echo "Erro: você está tentando apagar o disco do sistema principal ($DISK)"
  exit 1
fi

echo
echo "Informações do disco selecionado:"
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINT /dev/$DISK
echo

read -p "Apagar completamente /dev/$DISK? (digite 'sim'): " CONFIRM
[ "$CONFIRM" != "sim" ] && exit 0

echo
echo "Sistema de arquivos:"
echo "1) EXT4 (Linux)"
echo "2) NTFS (Windows + Linux)"
read -p "Escolha: " FS

if [ "$FS" == "1" ]; then
  FS_TYPE="ext4"
  MKFS="mkfs.ext4 -F -L"
  MOUNT_OPTS="defaults"
elif [ "$FS" == "2" ]; then
  FS_TYPE="ntfs3"
  MKFS="mkfs.ntfs -f -L"
  MOUNT_OPTS="defaults,uid=$USER_ID,gid=$GROUP_ID"
else
  echo "Opção inválida"
  exit 1
fi

echo
read -p "Nome do HD/Partição (ex: Files): " NAME
MOUNT_POINT="/home/$USER_NAME/$NAME"

echo
echo "Confirmação final: digite o disco novamente ($DISK):"
read CONFIRM2
[ "$CONFIRM2" != "$DISK" ] && exit 1

echo
echo "Limpando disco..."
sudo wipefs -a /dev/$DISK

echo "Criando tabela GPT..."
sudo parted -s /dev/$DISK mklabel gpt

echo "Criando partição..."
sudo parted -s /dev/$DISK mkpart primary 0% 100%

echo "Atualizando kernel..."
sudo partprobe /dev/$DISK
sleep 2

# Lógica para discos NVMe ou eMMC
if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
  PART="/dev/${DISK}p1"
else
  PART="/dev/${DISK}1"
fi

if [ ! -b "$PART" ]; then
  echo "Erro: partição $PART não foi encontrada/criada."
  exit 1
fi

echo "Formatando..."
sudo $MKFS "$NAME" "$PART"

# Força o kernel a processar os novos eventos (evita cache antigo)
sudo udevadm settle

echo "Criando pasta do ponto de montagem..."
mkdir -p "$MOUNT_POINT"

echo "Montando partição provisoriamente..."
sudo mount -t $FS_TYPE "$PART" "$MOUNT_POINT"

echo "Ajustando permissões..."
sudo chown -R $USER_NAME:$USER_NAME "$MOUNT_POINT"

# CORREÇÃO: blkid com sudo e ignorando cache (-c /dev/null)
echo "Obtendo UUID..."
UUID=$(sudo blkid -c /dev/null -s UUID -o value "$PART")

if grep -q "$UUID" /etc/fstab; then
  echo "Entrada já existe no fstab."
else
  echo "Fazendo backup e salvando no fstab..."
  sudo cp /etc/fstab /etc/fstab.bak
  echo "UUID=$UUID $MOUNT_POINT $FS_TYPE $MOUNT_OPTS 0 2" | sudo tee -a /etc/fstab > /dev/null
fi

echo "Recarregando systemd e testando montagem automática..."
sudo umount "$MOUNT_POINT"
sudo systemctl daemon-reload
sudo mount -a

echo
echo "=== Concluído ==="
echo "Disco montado e configurado em: $MOUNT_POINT"
