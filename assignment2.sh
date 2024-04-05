update_netplan() {
  echo "Updating Netplan configuration..."
  local netplan_file="/etc/netplan/00-installer-config.yaml"
  cat >"$netplan_file" <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    eth1:
      dhcp4: no
      addresses: [192.168.16.21/24]
      gateway4: 192.168.16.2
      nameservers:
        addresses: [192.168.16.2]
        search: [home.arpa, localdomain]
EOL
  netplan apply
  echo "Netplan configuration updated."
}

update_hosts_file() {
  echo "Updating /etc/hosts..."
  local hosts_entry="192.168.16.21 server1"
  if ! grep -q "$hosts_entry" /etc/hosts; then
    sed -i "/server1/d" /etc/hosts  # Remove any existing entry for server1
    echo "$hosts_entry" >> /etc/hosts
  fi
  echo "/etc/hosts updated."
}

install_software() {
  echo "Installing Apache2 and Squid..."
  apt-get update
  apt-get install -y apache2 squid
  systemctl enable --now apache2
  systemctl enable --now squid
  echo "Apache2 and Squid installed and started."
}

configure_firewall() {
  echo "Configuring UFW firewall..."
  ufw allow from 192.168.16.0/24 to any port 22
  ufw allow 80/tcp
  ufw allow 3128/tcp  # Default Squid port
  ufw --force enable
  echo "UFW configuration completed."
}


create_user_accounts() {
  echo "Creating user accounts..."
  local users=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)
  local dennis_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

  for user in "${users[@]}"; do
    if ! id "$user" &>/dev/null; then
      adduser --disabled-password --gecos "" "$user"
      mkdir -p /home/"$user"/.ssh
      chmod 700 /home/"$user"/.ssh

      if [ "$user" = "dennis" ]; then
        echo "$dennis_key" > /home/"$user"/.ssh/authorized_keys
        echo "$user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$user"
      else
        touch /home/"$user"/.ssh/authorized_keys
      fi

      chmod 600 /home/"$user"/.ssh/authorized_keys
      chown -R "$user":"$user" /home/"$user"/.ssh
    fi
  done

  echo "User accounts created and configured."

}

