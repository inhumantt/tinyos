#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Check if we're running as root
if [ "$(id -u)" -ne 0 ]; then
    handle_error "You must run this script as root."
fi

# Update and install required packages
apt update -y && apt upgrade -y || handle_error "Failed to update or upgrade packages."
apt install grub2 wimtools ntfs-3g -y || handle_error "Failed to install required packages."

# Check if /dev/sda exists and is the correct disk
echo "Please verify that /dev/sda is the correct disk."
lsblk
read -p "Do you want to continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    handle_error "User aborted the operation."
fi

# Get the disk size in GB and convert to MB
disk_size_gb=$(parted /dev/sda --script print | awk '/^Disk \/dev\/sda:/ {print int($3)}')
disk_size_mb=$((disk_size_gb * 1024))
echo "Disk size: $disk_size_gb GB ($disk_size_mb MB)"

# Calculate partition size (25% of total size)
part_size_mb=$((disk_size_mb / 4))
echo "Partition size: $part_size_mb MB (25% of the total disk size)."

# Create GPT partition table
echo "Creating GPT partition table on /dev/sda..."
parted /dev/sda --script -- mklabel gpt || handle_error "Failed to create GPT partition table."

# Create two NTFS partitions
echo "Creating partitions..."
parted /dev/sda --script -- mkpart primary ntfs 1MB ${part_size_mb}MB || handle_error "Failed to create partition 1."
parted /dev/sda --script -- mkpart primary ntfs ${part_size_mb}MB $((2 * part_size_mb))MB || handle_error "Failed to create partition 2."

# Inform kernel of partition table changes
echo "Informing kernel about partition table changes..."
partprobe /dev/sda || handle_error "Failed to update kernel about partition table."
sleep 30
partprobe /dev/sda || handle_error "Failed to update kernel again."
sleep 30
partprobe /dev/sda || handle_error "Failed to update kernel third time."

# Format the partitions
echo "Formatting partitions..."
mkfs.ntfs -f /dev/sda1 || handle_error "Failed to format partition 1."
mkfs.ntfs -f /dev/sda2 || handle_error "Failed to format partition 2."

echo "NTFS partitions created."

# Run gdisk to create a new partition table
echo -e "r\ng\np\nw\nY\n" | gdisk /dev/sda || handle_error "Failed to run gdisk on /dev/sda."

# Mount the first partition
echo "Mounting /dev/sda1 to /mnt..."
mount /dev/sda1 /mnt || handle_error "Failed to mount /dev/sda1 to /mnt."

# Prepare the directory for the Windows disk
cd ~ || handle_error "Failed to change directory."
mkdir -p windisk || handle_error "Failed to create windisk directory."

# Mount the second partition
echo "Mounting /dev/sda2 to /root/windisk..."
mount /dev/sda2 windisk || handle_error "Failed to mount /dev/sda2 to windisk."

# Install GRUB bootloader
echo "Installing GRUB..."
grub-install --root-directory=/mnt /dev/sda || handle_error "Failed to install GRUB."

# Create GRUB configuration
echo "Creating GRUB configuration..."
cd /mnt/boot/grub || handle_error "Failed to change to /mnt/boot/grub."
cat <<EOF > grub.cfg
menuentry "Windows Installer" {
    insmod ntfs
    search --set=root --file=/bootmgr
    ntldr /bootmgr
    boot
}
EOF
echo "GRUB configuration created."

# Download the Windows Server 2022 ISO
echo "Downloading Windows Server 2022 ISO..."
wget -O Windows_SERVER_2022_NTLite.iso "https://www.dropbox.com/scl/fi/kjvjlmhbt8fbwa9zxmke2/Windows_SERVER_2022_NTLite.iso?rlkey=2qrb3egcnec7wnt3wqrrk50rl&st=t69g63uc&dl=1" || handle_error "Failed to download Windows Server 2022 ISO."

# Optional: Verify the checksum of the ISO (if provided)
# expected_checksum="your_checksum_here"
# actual_checksum=$(sha256sum Windows_SERVER_2022_NTLite.iso | awk '{ print $1 }')
# if [[ "$expected_checksum" != "$actual_checksum" ]]; then
#     handle_error "Checksum mismatch. The ISO file may have been tampered with."
# fi

# Mount the ISO
echo "Mounting the Windows ISO..."
mkdir -p winfile || handle_error "Failed to create mount directory."
mount -o loop Windows_SERVER_2022_NTLite.iso winfile || handle_error "Failed to mount ISO."

# Copy files from the ISO to the mounted partition
echo "Copying files from ISO to /mnt..."
rsync -avz --progress winfile/* /mnt || handle_error "Failed to copy files from ISO to /mnt."

# Unmount the ISO
umount winfile || handle_error "Failed to unmount the ISO."

# Reboot the system
echo "Rebooting system..."
reboot || handle_error "Failed to reboot the system."
