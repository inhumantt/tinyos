#!/bin/bash

OS_IMAGE_URL="https://www.dropbox.com/scl/fi/kjvjlmhbt8fbwa9zxmke2/Windows_SERVER_2022_NTLite.iso?rlkey=2qrb3egcnec7wnt3wqrrk50rl&st=t69g63uc&dl=1"
OS_IMAGE_PATH="/usr/local/Windows_SERVER_2022_NTLite.iso"

echo "Downloading Windows Server 2022 image..."
wget -O "$OS_IMAGE_PATH" "$OS_IMAGE_URL" || curl -L -o "$OS_IMAGE_PATH" "$OS_IMAGE_URL"

if [ ! -s "$OS_IMAGE_PATH" ]; then
    echo "Failed to download the OS image!"
    exit 1
fi

echo "Download complete: $OS_IMAGE_PATH"

# Example: If you need to write it to a USB drive (change /dev/sdX to your USB device)
# echo "Writing the OS image to USB..."
# dd if="$OS_IMAGE_PATH" of=/dev/sdX bs=4M status=progress && sync

# OR if using a VM, mount the ISO as needed.

echo "Process complete!"
