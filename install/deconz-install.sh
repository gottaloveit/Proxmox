#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.phoscon.de/en/conbee2/software#deconz

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y wget
$STD apt-get install -y openssh-server
msg_ok "Installed Dependencies"

msg_info "Setting Phoscon Repository"
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
curl -fsSL http://phoscon.de/apt/deconz.pub.key >/etc/apt/trusted.gpg.d/deconz.pub.asc
echo "deb [arch=arm64] http://phoscon.de/apt/deconz $VERSION main" >/etc/apt/sources.list.d/deconz.list
msg_ok "Setup Phoscon Repository"

msg_info "Installing deConz"
wget -qL http://ports.ubuntu.com/pool/main/o/openssl/libssl1.0.0_1.0.2g-1ubuntu4.20_arm64.deb
$STD dpkg -i libssl1.0.0_1.0.2g-1ubuntu4.20_arm64.deb
$STD apt-get update
$STD apt-get install -y deconz
msg_ok "Installed deConz"

msg_info "Creating Service"
cat <<EOF >/lib/systemd/system/deconz.service
[Unit]
Description=deCONZ: ZigBee gateway -- REST API
Wants=deconz-init.service deconz-update.service
StartLimitIntervalSec=0

[Service]
User=root
ExecStart=/usr/bin/deCONZ -platform minimal --http-port=80
Restart=on-failure
RestartSec=30
AmbientCapabilities=CAP_NET_BIND_SERVICE CAP_KILL CAP_SYS_BOOT CAP_SYS_TIME

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now deconz
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf libssl1.0.0_1.0.2g-1ubuntu4.20_arm64.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
