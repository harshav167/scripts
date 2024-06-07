#!/bin/bash

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install necessary packages
sudo apt install neovim tmux btop nvtop ubuntu-drivers-common ca-certificates curl -y

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    # Set up Docker repository and install Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the Docker repository to Apt sources
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    # Update and install Docker packages
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # Add user to Docker group
    sudo usermod -aG docker $USER
fi

# Check if NVIDIA container toolkit is installed
if ! dpkg -l | grep -q nvidia-container-toolkit
then
    # Set up NVIDIA container toolkit
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
fi

# Install lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# Clean up unused packages
sudo apt autoremove -y

# Autoinstall drivers
sudo ubuntu-drivers autoinstall

# Create post-reboot script
cat << 'EOF' > /tmp/post_reboot_script.sh
#!/bin/bash
# Check if build-essential and linux-headers are installed
if dpkg -l | grep -q build-essential && dpkg -l | grep -q "linux-headers-$(uname -r)"
then
    sudo apt remove build-essential linux-headers-$(uname -r) -y
    sudo apt autoremove -y
fi
sudo apt-get install build-essential linux-headers-$(uname -r) -y
sudo reboot
EOF

# Make the post-reboot script executable
chmod +x /tmp/post_reboot_script.sh

# Schedule the post-reboot script to run after reboot using crontab
(crontab -l ; echo "@reboot /tmp/post_reboot_script.sh") | crontab -

# Reboot the system
sudo reboot
