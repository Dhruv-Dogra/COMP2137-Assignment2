#!/bin/bash

# Ensure script runs with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

echo "Starting server configuration..."

# Step 1: Configure network interface
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
TARGET_IP="192.168.16.21/24"

# Check and update netplan
if ! grep -q "$TARGET_IP" "$NETPLAN_FILE"; then
    echo "Configuring network interface..."
    cat <<EOF > "$NETPLAN_FILE"
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - $TARGET_IP
EOF
    netplan apply
else
    echo "Network already configured."
fi

# Step 2: Update /etc/hosts
if ! grep -q "192.168.16.21 server1" /etc/hosts; then
    echo "Updating /etc/hosts..."
    sed -i '/server1/d' /etc/hosts
    echo "192.168.16.21 server1" >> /etc/hosts
else
    echo "/etc/hosts already configured."
fi

# Step 3: Install required software
for pkg in apache2 squid; do
    if ! dpkg -l | grep -qw $pkg; then
        echo "Installing $pkg..."
        apt-get install -y $pkg
        systemctl enable $pkg
    else
        echo "$pkg already installed."
    fi
done

# Step 4: Create user accounts
USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
for user in "${USERS[@]}"; do
    if ! id "$user" &>/dev/null; then
        echo "Creating user $user..."
        useradd -m -s /bin/bash "$user"
        mkdir -p /home/$user/.ssh
        chown -R $user:$user /home/$user
    else
        echo "User $user already exists."
    fi
done

# Add sudo access for 'dennis'
usermod -aG sudo dennis

# Add SSH keys for 'dennis'
echo "Adding SSH keys for dennis..."
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> /home/dennis/.ssh/authorized_keys

echo "Configuration complete."
