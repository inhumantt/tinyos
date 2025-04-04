# tinyos
official windows server 2022 datacenter

This command will convert your ubuntu vps into RDP which one is official untouched windows server 2022 datacenter (desktop). All drivers included. So, dont worry to find disk while setup and ethernet.

Run the following commands on your VPS:

apt install git -y
git clone https://github.com/TasikIslam/windows-contabo.git
cd windows-contabo
chmod +x windows-install.sh
./windows-install.sh
The process takes approximately 15 minutes and completes when the ssh session disconnects due to the machine rebooting.
