#!/bin/bash

BGreen="\033[1;32m"     # Green
NC="\033[0m"            # No Color

ModelPI=/proc/device-tree/model

$(network)
$(pi_version)
$(pi_can0)
$(samba)
$(dash)
$(dash_set)
$(pi_ap)
$(pi_version2)

network() {
  ping -c1 -w1 raspberrypi.org 2>/dev/null 1>/dev/null
  if [ "$?" = 0 ]; then
    echo ${BGreen}'Successfully'${NC}
  else
    whiptail --title "ERROR" --msgbox "Inernet Connection is Missing \nRestart installer!" 10 60
    exit 0
  fi
}


pi_version() {
  echo ${BGreen} $ModelPI ${NC}
  if grep -q 'Raspberry Pi 2\|Raspberry Pi 3' $ModelPI; then
    if ! grep -q 'CONF_SWAPSIZE=1024' /etc/dphys-swapfile; then
	  sed -i '/CONF_SWAPSIZE=512/a\CONF_SWAPSIZE=1024' /etc/dphys-swapfile
	  sed -i 's/^#\?CONF_SWAPSIZE=512/#CONF_SWAPSIZE=512/' /etc/dphys-swapfile
    fi
	reboot
  fi
}

pi_version2() {
  echo ${BGreen} $ModelPI ${NC}
  if grep -q 'Raspberry Pi 2\|Raspberry Pi 3' $ModelPI; then
    if grep -q 'CONF_SWAPSIZE=1024' /etc/dphys-swapfile; then
	  sed -i "/CONF_SWAPSIZE=1024/d" $CONFIG
	  sed -i 's/^#\?CONF_SWAPSIZE=512/CONF_SWAPSIZE=512/' /etc/dphys-swapfile
    fi
	reboot
  fi
}


pi_can0() {
  apt install -y can-utils python3-can
  pip3 install keyboard --break-system-packages
  if ! grep -q 'MCP2515-can0' /boot/firmware/config.txt; then
    sed -i 's/^#\?dtparam=spi=on/dtparam=spi=on/' /boot/firmware/config.txt
    cat <<'EOF' >> /boot/firmware/config.txt

# MCP2515-can0 oscillator=8000000 or 16000000 and GPIO=25
dtoverlay=mcp2515-can0,oscillator=8000000,interrupt=25
dtoverlay=spi-bcm2837
#dtoverlay=spi-bcm2835-overlay
EOF
    if grep -q 'Raspberry Pi 2\|Raspberry Pi 3' $ModelPI; then
	  sed -i 's/^#\?dtoverlay=spi-bcm2835-overlay/dtoverlay=spi-bcm2835-overlay/' /boot/firmware/config.txt
	  sed -i 's/^#\?dtoverlay=spi-bcm2837/#dtoverlay=spi-bcm2837/' /boot/firmware/config.txt
	fi
  fi
  cat <<'EOF' > /etc/systemd/network/80-can.network
[Match]
Name=can0

[CAN]
BitRate=100K
EOF
  systemctl restart systemd-networkd && 
  systemctl enable systemd-networkd
}


samba() {
  echo ${BGreen}'Installing SAMBA'${NC}
  apt-get install -y samba
  if [ "$?" = 0 ]; then
    if ! grep -q "/home/pi/" /etc/samba/smb.conf; then
      cat <<'EOF' >> /etc/samba/smb.conf
[rns]
path = /home/pi/
create mask = 0775
directory mask = 0775
writeable = yes
browseable = yes
public = yes
force user = pi
guest ok = yes
EOF
    fi
  fi
}


dash() {
  echo ${BGreen}'Installing OpenAuto'${NC}
  echo ${BGreen}'PI4 (2GB) = 70min. takes a long time'${NC}
  git clone https://github.com/openDsh/dash
  cd dash
  ./install.sh 
}

dash_set() {
  echo ${BGreen}'Create shortcut on dashboard'${NC}
  cp -v ~/dash/assets/icons/opendash.xpm /usr/share/pixmaps/opendash.xpm
  cat <<'EOF' > /home/pi/Desktop/dash.desktop
[Desktop Entry]
Name=Dash
Comment=Open Dash
Icon=/usr/share/pixmaps/opendash.xpm
Exec=/home/pi/dash/bin/dash
Type=Application
Encoding=UTF-8
Terminal=true
Categories=None;
EOF
  chmod +x ~/Desktop/dash.desktop

  # UPStart
  cat <<'EOF' > /etc/systemd/system/dash.service
[Unit]
Description=Dash

[Service]
Type=idle
User=pi
StandardOutput=inherit
StandardError=inherit
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
Environment=XDG_RUNTIME_DIR=/run/user/1000
WorkingDirectory=/home/pi/dash/
ExecStart=/home/pi/dash/bin/dash
Restart=on-failure
RestartSec=10s
KillMode=process
TimeoutSec=infinity

[Install]
WantedBy=graphical.target
EOF
  systemctl enable dash
  #systemctl start dash

  echo ${BGreen}'Copy button_control_rns.py to /home/pi/dash'${NC}
  cat <<'EOF' > /home/pi/.config/openDsh/dash.conf
[Core]
Action\0=NONE 
Action\1=Return
Action\2=NONE
Action\3=LEFT
Action\4=RIGHT
Action\5=Backspace
Action\6=H
Action\7=C
Action\8=E
Action\9=G
Action\10=S
Action\11=B
Action\12=N
Action\13=P
Action\14=V
Action\15=DOWN
Action\16=UP
Action\17=D
Action\22=F
Action\23=1
Action\24=2
Action\25=3
Action\26=4
Action\27=5
Action\28=6
Action\29=7

[System]
Brightness\value=251
volume=100

EOF
  chown -R pi:pi /home/pi/.config/openDsh/
  
  cat <<'EOF' > /etc/systemd/system/button.service
[Unit]
Description=button
[Service]
Type=simple
ExecStart=/usr/bin/python /home/pi/dash/button_controls.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF

  systemctl enable button.service
  systemctl start button.service
}

pi_ap() {
  echo ${BGreen}'Create an access point'${NC}
  nmcli con add type wifi ifname wlan0 mode ap con-name RPI-AP ssid AOwireless autoconnect true
  # 2.4GHz
  #nmcli con modify RPI-AP wifi.band bg
  #nmcli con modify RPI-AP wifi.channel 3
  # 5GHz
  nmcli con modify RPI-AP wifi.band a
  nmcli con modify RPI-AP wifi.channel 36
  #
  nmcli con modify RPI-AP wifi.cloned-mac-address 00:12:34:56:78:9a
  nmcli con modify RPI-AP wifi-sec.key-mgmt wpa-psk
  nmcli con modify RPI-AP wifi-sec.psk "AOwireless1234"
  nmcli con modify RPI-AP ipv4.method shared ipv4.address 192.168.4.1/24
  nmcli con modify RPI-AP ipv6.method disabled
  #nmcli con modify preconfigured autoconnect false
  nmcli con up RPI-AP
  echo ${BGreen}'Be careful!!!!!!!! and do not enter the password for the created access point on your phone. And dont connect to her'${NC}

  cat <<'EOF' > /home/pi/openauto.ini
[WiFi]
SSID=AOwireless
Password=AOwireless1234
EOF
  chown -R pi:pi /home/pi/openauto.ini
}

