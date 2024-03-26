#!/bin/bash

# Configure network interface
configure_network_interface() {
    sudo tee /etc/netplan/01-netcfg.yaml <<EOF >/dev/null
network:
  version: 2
  ethernets:
    ens3:
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.2
      nameservers:
        addresses: [192.168.16.2]
        search: [home.arpa, localdomain]
EOF
    sudo netplan apply
}

# Update /etc/hosts
update_hosts_file() {
    sudo sed -i '/server1/d' /etc/hosts
    echo "192.168.16.21    server1" | sudo tee -a /etc/hosts >/dev/null
}

# Install required packages
install_packages() {
    sudo apt update || { echo "Failed to update package list"; exit 1; }
    sudo apt install -y apache2 squid || { echo "Failed to install packages"; exit 1; }
}

# Configure firewall
configure_firewall() {
    sudo ufw allow in on ens4 from 192.168.16.0/24 to any port 22 || { echo "Failed to allow SSH"; exit 1; }
    sudo ufw allow in on ens3 to any port 80 || { echo "Failed to allow HTTP on ens3"; exit 1; }
    sudo ufw allow in on ens4 to any port 80 || { echo "Failed to allow HTTP on ens4"; exit 1; }
    sudo ufw allow in on ens3 to any port 3128 || { echo "Failed to allow Squid on ens3"; exit 1; }
    sudo ufw allow in on ens4 to any port 3128 || { echo "Failed to allow Squid on ens4"; exit 1; }
    sudo ufw --force enable || { echo "Failed to enable firewall"; exit 1; }
}

# Create user accounts and configure SSH keys
configure_users() {
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in "${users[@]}"; do
        sudo useradd -m -s /bin/bash "$user" || { echo "Failed to create user '$user'"; exit 1; }
        sudo mkdir -p "/home/$user/.ssh" || { echo "Failed to create .ssh directory for '$user'"; exit 1; }
        sudo chmod 700 "/home/$user/.ssh" || { echo "Failed to set permissions for .ssh directory of '$user'"; exit 1; }
        sudo touch "/home/$user/.ssh/authorized_keys" || { echo "Failed to create authorized_keys for '$user'"; exit 1; }
        sudo chmod 600 "/home/$user/.ssh/authorized_keys" || { echo "Failed to set permissions for authorized_keys of '$user'"; exit 1; }
        sudo bash -c "echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm' >> /home/$user/.ssh/authorized_keys" || { echo "Failed to add SSH keys for '$user'"; exit 1; }
    done
}

# Main function
main() {
    configure_network_interface
    update_hosts_file
    install_packages
    configure_firewall
    configure_users
}

# Call main function
main
