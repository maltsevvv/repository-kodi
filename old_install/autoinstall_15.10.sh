#!/bin/bash


ping -c1 -w1 google.de 2>/dev/null 1>/dev/null
if [ "$?" = 0 ]; then
  echo "---------------------------------------------------------"
  echo "Internet connection OK"
  echo "---------------------------------------------------------"
else
  whiptail --title "Inernet Connection" --msgbox "Inernet Connection is Missing \nPlease make sure a internet connection is available \nand than restart installer!" 10 60
  exit 0
fi

echo "---------------------------------------------------------"
echo "Update & Upgrade"
echo "---------------------------------------------------------"
apt update -y
apt upgrade -y
apt autoremove -y

echo "---------------------------------------------------------"
echo "Installing samba"
echo "---------------------------------------------------------"
if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
echo "samba-common samba-common/workgroup string  WORKGROUP" | debconf-set-selections
echo "samba-common samba-common/dhcp boolean true" | debconf-set-selections
echo "samba-common samba-common/do_debconf boolean true" | debconf-set-selections
fi
apt install -y samba
if [ ! $? = 0 ]; then
  whiptail --title "SAMBA INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER!" 10 60
  exit 0
fi

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

echo "---------------------------------------------------------"
echo "Installing kodi"
echo "---------------------------------------------------------"
apt install -y kodi
if [ ! $? = 0 ]; then
  whiptail --title "KODI INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER!" 10 60
  exit 0
fi
sed -i '/service.xbmc.versioncheck/d' /usr/share/kodi/system/addon-manifest.xml #Disable versioncheck
apt install -y kodi-pvr-iptvsimple
if ! grep -q "/usr/bin/kodi-standalone" /etc/systemd/system/kodi.service; then
  cat <<'EOF' > /etc/systemd/system/kodi.service
[Unit]
Description=Kodi Media Center
[Service]
User=pi
Group=pi
Type=simple
ExecStart=/usr/bin/kodi-standalone
Restart=always
RestartSec=15
[Install]
WantedBy=multi-user.target
EOF
  systemctl enable kodi.service
  systemctl start kodi.service
fi

echo "---------------------------------------------------------"
echo "Installing can-utils"
echo "---------------------------------------------------------"
apt install -y can-utils
if [ ! $? = 0 ]; then
  whiptail --title "CAN-UTILS INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER!" 10 60
  exit 0
fi

if ! grep -q "auto can0" /etc/network/interfaces; then
  cat <<'EOF' >> /etc/network/interfaces
auto can0
  iface can0 inet manual
  pre-up /sbin/ip link set can0 type can bitrate 100000
  up /sbin/ifconfig can0 up
  down /sbin/ifconfig can0 down
EOF
fi

# echo "---------------------------------------------------------"
# echo "Installing Python-pip"
# echo "---------------------------------------------------------"
# if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  # apt install -y python-pip
  # if [ ! $? = 0 ]; then
    # whiptail --title "PYTHON-PIP INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    # exit 0
  # fi
# elif grep -q 'VERSION="11 (bullseye)"' /etc/os-release; then
  # apt install -y python3-pip
  # if [ ! $? = 0 ]; then
    # whiptail --title "PYTHON3-PIP INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    # exit 0
  # fi
# fi

#VERSION="12 (bookworm)

echo "---------------------------------------------------------"
echo "Installing Python-can"
echo "---------------------------------------------------------"
if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  apt install -y python-can
  if [ ! $? = 0 ]; then
    whiptail --title "PYTHON-CAN INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
else
  apt install -y python3-can
  if [ ! $? = 0 ]; then
    whiptail --title "PYTHON3-CAN INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
fi

if grep -q 'VERSION="12 (bookworm)"' /etc/os-release; then
  echo "---------------------------------------------------------"
  echo "Installing OverlayFS"
  echo "---------------------------------------------------------"
  apt-get install -y overlayroot
fi

if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  echo "---------------------------------------------------------"
  echo "Installing usbmount"
  echo "---------------------------------------------------------"
  apt install -y usbmount
  if [ $? = 0 ]; then
    mkdir /home/pi/tmpu && cd /home/pi/tmpu
    wget https://github.com/nicokaiser/usbmount/releases/download/0.0.24/usbmount_0.0.24_all.deb
    if [ $? = 0 ]; then
      dpkg -i usbmount_0.0.24_all.deb
      cd /home/pi && rm -Rf /home/pi/tmpu
    fi
    #echo "Add Cirilic and UTF-8"
    sed -i 's/FS_MOUNTOPTIONS=""/FS_MOUNTOPTIONS="-fstype=vfat,iocharset=utf8,gid=1000,dmask=0007,fmask=0007"/' /etc/usbmount/usbmount.conf
    sed -i 's/FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus"/FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus ntfs fuseblk"/' /etc/usbmount/usbmount.conf
  fi
  if [ ! $? = 0 ]; then
    whiptail --title "USBMOUNT INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
fi
####
##############################################
#         INSTALL BLUETOOTHE RECIEVER        #
##############################################
if (whiptail --title "Bluetooth audio receiver installer" --yesno "Install Bluetooth Audio Receive." 10 60) then
  echo "---------------------------------------------------------"
  echo "Installing BLUETOOTHE RECIEVER"
  echo "---------------------------------------------------------"
  hostnamectl set-hostname --pretty "rns"
  apt install -y --no-install-recommends pulseaudio
  if [ ! $? -eq 0 ]; then
    whiptail --title "PULSEAUDIO INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
  usermod -a -G pulse-access root
  usermod -a -G bluetooth pulse
  if ! grep -q '/run/pulse/native' /etc/pulse/client.conf; then
    mv /etc/pulse/client.conf /etc/pulse/client.conf.orig
    cat <<'EOF' >> /etc/pulse/client.conf
default-server = /run/pulse/native
autospawn = no
EOF
  fi
  sed -i '/^load-module module-native-protocol-unix$/s/$/ auth-cookie-enabled=0 auth-anonymous=1/' /etc/pulse/system.pa
  cat <<'EOF' > /etc/systemd/system/pulseaudio.service
[Unit]
Description=Sound Service
[Install]
WantedBy=multi-user.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/bin/pulseaudio --daemonize=no --system --disallow-exit --disable-shm --exit-idle-time=-1 --log-target=journal --realtime --no-cpu-limit
Restart=on-failure
EOF
  systemctl enable --now pulseaudio.service
  systemctl --global mask pulseaudio.socket
  apt install -y --no-install-recommends bluez-tools pulseaudio-module-bluetooth
  if [ ! $? -eq 0 ]; then
    whiptail --title "BLUETOOTH BLUEZ-TOOLS INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
  echo "---------------------------------------------------------"
  echo "BLUETOOTHE SETTINGS"
  echo "---------------------------------------------------------"
  cat <<'EOF' > /etc/bluetooth/main.conf
[General]
Class = 0x200414
DiscoverableTimeout = 0

[Policy]
AutoEnable=true
EOF
  mkdir -p /etc/systemd/system/bthelper@.service.d
  cat <<'EOF' > /etc/systemd/system/bthelper@.service.d/override.conf
[Service]
Type=oneshot
EOF

  cat <<'EOF' > /etc/systemd/system/bt-agent@.service
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.service

[Service]
ExecStartPre=/usr/bin/bluetoothctl discoverable on
ExecStartPre=/bin/hciconfig %I piscan
ExecStartPre=/bin/hciconfig %I sspmode 1
ExecStart=/usr/bin/bt-agent --capability=NoInputNoOutput
RestartSec=5
Restart=always
KillSignal=SIGUSR1

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable bt-agent@hci0.service
  usermod -a -G bluetooth pulse
  if ! grep -q 'module-bluetooth-discover' /etc/pulse/system.pa; then
    echo "load-module module-bluetooth-policy" >> /etc/pulse/system.pa
    echo "load-module module-bluetooth-discover" >> /etc/pulse/system.pa
  fi
  if ! grep -q 'bluetoothctl discoverable on' /usr/local/bin/bluetooth-udev; then
    cat <<'EOF' > /usr/local/bin/bluetooth-udev
#!/bin/bash
if [[ ! $NAME =~ ^\"([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\"$ ]]; then exit 0; fi

action=$(expr "$ACTION" : "\([a-zA-Z]\+\).*")

if [ "$action" = "add" ]; then
    bluetoothctl discoverable off
fi

if [ "$action" = "remove" ]; then
    bluetoothctl discoverable on
fi
EOF
  chmod 755 /usr/local/bin/bluetooth-udev
  cat <<'EOF' > /etc/udev/rules.d/99-bluetooth-udev.rules
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluetooth-udev"
EOF
  fi
  echo "---------------------------------------------------------"
  echo "EDIT /etc/asound.conf"
  echo "---------------------------------------------------------"
  if ! grep -q 'defaults.ctl.card 0' /etc/asound.conf; then
    cat <<'EOF' > /etc/asound.conf
defaults.ctl.card 0
defaults.ctl.card 0
EOF
  fi
#  if (whiptail --title "USB Bluetooth Adapter" --yesno "Are you using an external usb bluetooth?." 10 60) then
#    systemctl disable hciuart
#    modprobe btusb
#    rpi-update
#  fi
else
  echo "---------------------------------------------------------"
  echo "YOU CANCELED THE INSTALLATION BLUETOOTH RECIEVER"
  echo "---------------------------------------------------------"
fi
##############################################
####
if (systemctl -q is-active kodi.service); then
  systemctl stop kodi.service
  sleep 10
elif (systemctl -q is-active kodi.service); then
  systemctl stop kodi.service
  sleep 10
exit 1
fi
####
##############################################
#        INSTALL Bluetooth Manager           #
##############################################
# if grep -q 'VERSION="11 (bullseye)"' /etc/os-release; then
	# if grep -q 'defaults.ctl.card 0' /etc/asound.conf; then
		# rm -r /home/pi/.kodi/addons/*bluetooth*
		# unzip /home/pi/.kodi/addons/skin.rns*/resources/Bluetooth*.zip -d /home/pi/.kodi/addons/ > /dev/null 2>&1
		# sed -i -e '$i \  <addon optional="true">script.bluetooth.man</addon>' /usr/share/kodi/system/addon-manifest.xml
	# fi
# fi
####
##############################################
#               INSTALL SKIN                 #
##############################################
if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  wget ––tries=100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi18/skin.carpc/skin.carpc-1.0.1.zip
elif grep -q 'VERSION="11 (bullseye)"' /etc/os-release; then
  wget ––tries=100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi19/skin.carpc/skin.carpc-19.3.1.zip
elif grep -q 'VERSION="12 (bookworm)"' /etc/os-release; then
  wget ––tries=100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi20/skin.carpc/skin.carpc-1.0.1.zip
fi
rm -r /home/pi/.kodi/addons/skin.carpc*
rm -r /home/pi/.kodi/addons/repository.maltsev*
unzip /tmp/skin.carpc*.zip -d /home/pi/.kodi/addons/ > /dev/null 2>&1
wget ––tries=100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/repository.maltsev_kodi.zip
unzip /tmp/repository.maltsev_kodi.zip -d /home/pi/.kodi/addons/ > /dev/null 2>&1
sed -i -e '$i \  <addon optional="true">skin.carpc</addon>' /usr/share/kodi/system/addon-manifest.xml
sed -i -e 's/lookandfeel.skin" default="true">skin.estuary/lookandfeel.skin">skin.carpc/' /home/pi/.kodi/userdata/guisettings.xml
sed -i -e '$i \  <addon>repository.maltsev_kodi</addon>' /usr/share/kodi/system/addon-manifest.xml

####
echo "---------------------------------------------------------"
echo "CREATING MEDIA FOLDER"
echo "---------------------------------------------------------"
mkdir /home/pi/movies /home/pi/music /home/pi/mults /home/pi/clips /home/pi/tvshows > /dev/null 2>&1
chmod -R 0777 /home/pi/movies /home/pi/music /home/pi/mults /home/pi/clips /home/pi/tvshows > /dev/null 2>&1
##############################################
#                SETTINGS KODI               #
##############################################
echo "---------------------------------------------------------"
echo "PRESETTING KODI"
echo "---------------------------------------------------------"
cat <<'EOF' > /home/pi/.kodi/userdata/sources.xml
<sources>
    <programs>
        <default pathversion="1"></default>
    </programs>
    <video>
        <default pathversion="1"></default>
        <source>
            <name>movies</name>
            <path pathversion="1">/home/pi/movies/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>tvshows</name>
            <path pathversion="1">/home/pi/tvshows/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>clips</name>
            <path pathversion="1">/home/pi/clips/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>mults</name>
            <path pathversion="1">/home/pi/mults/</path>
            <allowsharing>true</allowsharing>
        </source>
    </video>
    <music>
        <default pathversion="1"></default>
        <source>
            <name>music</name>
            <path pathversion="1">/home/pi/music/</path>
            <allowsharing>true</allowsharing>
        </source>
    </music>
    <pictures>
        <default pathversion="1"></default>
    </pictures>
    <files>
        <default pathversion="1"></default>
        <source>
            <name>192.168.1.3</name>
            <path pathversion="1">smb://192.168.1.3/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>pi</name>
            <path pathversion="1">/home/pi/</path>
            <allowsharing>true</allowsharing>
        </source>
    </files>
    <games>
        <default pathversion="1"></default>
    </games>
</sources>
EOF

# Disable Screensaver
sed -i 's/id="screensaver.mode" default="true">screensaver.xbmc.builtin.dim/id="screensaver.mode">/' /home/pi/.kodi/userdata/guisettings.xml
sed -i 's/id="screensaver.mode" default="true">default/id="screensaver.mode">/' /home/pi/.kodi/userdata/guisettings.xml

# Enable auto play next video
sed -i 's/id="videoplayer.autoplaynextitem" default="true">/id="videoplayer.autoplaynextitem">0,1,2,3,4/' /home/pi/.kodi/userdata/guisettings.xml

# Amplifi volume up to 30.0dB
sed -i 's/volumeamplification>0.000000/volumeamplification>30.000000/' /home/pi/.kodi/userdata/guisettings.xml

# Enable web-server
sed -i 's/id="services.webserverauthentication" default="true">true/id="services.webserverauthentication">false/' /home/pi/.kodi/userdata/guisettings.xml
sed -i 's/id="services.webserver" default="true">false/id="services.webserver">true/' /home/pi/.kodi/userdata/guisettings.xml

chown -R pi:pi /home/pi/
##############################################
#                EDIT config.txt             #
##############################################

echo "---------------------------------------------------------"
echo "################### EDIT /config.txt ####################" 
echo "---------------------------------------------------------"

if [ -e /boot/firmware/config.txt ] ; then
  FIRMWARE=/firmware
else
  FIRMWARE=
fi
CONFIG=/boot${FIRMWARE}/config.txt

if [ -e /boot/firmware/cmdline.txt ] ; then
  FIRMWARE=/firmware
else
  FIRMWARE=
fi
CMDLINE=/boot${FIRMWARE}/cmdline.txt

if ! [ -e /boot/config_original.txt ] ; then
  cp $CONFIG /boot/config_original.txt
fi

if (whiptail --title "Video Output" --yesno "Use HDMI-VGA Adapter For Video Output?" 10 60); then
  echo "---------------------------------------------------------"
  echo "Use HDMI-VGA Adapter For Video Output"
  echo "---------------------------------------------------------"
  sed $CONFIG -i -e "s/^dtoverlay=vc4-.*/dtoverlay=vc4-fkms-v3d/"

  if ! grep -q 'hdmi_ignore_edid=0xa5000080' $CONFIG; then
    cat <<'EOF' >> $CONFIG

# hdmi_vga adapter
framebuffer_width=400
framebuffer_height=200
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_ignore_edid=0xa5000080
hdmi_timings 800 0 51 44 121 460 0 10 9 14 0 0 0 32 1 16000000 3
EOF
  elif grep -q 'Raspberry Pi 4' /proc/device-tree/model; then 
    sed $CONFIG -i -e "s/^hdmi_force_hotplug/hdmi_force_hotplug:0/"
    sed $CONFIG -i -e "s/^hdmi_group/hdmi_group:0/"
    sed $CONFIG -i -e "s/^hdmi_mode/hdmi_mode:0/"
  elif grep -q 'Raspberry Pi 5' /proc/device-tree/model; then 
    sed $CONFIG -i -e "s/^hdmi_force_hotplug/hdmi_force_hotplug:0/"
    sed $CONFIG -i -e "s/^hdmi_group/hdmi_group:0/"
    sed $CONFIG -i -e "s/^hdmi_mode/hdmi_mode:0/"
  fi
  # Delete
  sed -i "/^enable_tvout.*/d" $CONFIG
  sed -i "/^sdtv_.*/d" $CONFIG
  sed -i "s/vc4.tv_norm=PAL //" $CMDLINE
else
  echo "---------------------------------------------------------"
  echo "Use Analog Video Output Jack 3,5mm"
  echo "---------------------------------------------------------"
  if grep -q 'VERSION="10 (buster)"' /etc/os-release && ! grep -q 'sdtv_aspect.*' $CONFIG; then
    echo "sdtv_mode=0 NTSC | sdtv_mode=1 NTSC JAPAN | sdtv_mode=2 PAL | sdtv_mode=3 PAL BRAZIL"
	echo "sdtv_aspect=1 4:3 | sdtv_aspect=2 14:9 | sdtv_aspect=3 16:9"
    cat <<'EOF' >> $CONFIG
# sdtv_mode=0 NTSC | sdtv_mode=1 NTSC JAPAN | sdtv_mode=2 PAL | sdtv_mode=3 PAL BRAZIL
sdtv_mode=0
# sdtv_aspect=1 4:3 | sdtv_aspect=2 14:9 | sdtv_aspect=3 16:9
sdtv_aspect=1
EOF
  elif ! grep -q 'VERSION="10 (buster)"' /etc/os-release && ! grep -q 'dtoverlay=vc4-kms-v3d,composite' $CONFIG; then
    sed $CONFIG -i -e "s/^dtoverlay=vc4-.*/dtoverlay=vc4-kms-v3d,composite/"
    if ! grep -q 'enable_tvout.*' $CONFIG; then
      cat <<'EOF' >> $CONFIG
enable_tvout=1
EOF
    fi
    if ! grep -q 'vc4.tv.*' $CMDLINE; then
    echo "PAL | NTSC | NTSC-J | NTSC-443 | PAL-M | PAL-N. | PAL60 | SECAM"
    echo "ADD vc4.tv_norm=PAL in "$CMDLINE
      sed $CMDLINE -i -e "s/^/vc4.tv_norm=PAL /"
    fi
  fi
  # Delete
  sed -i "/^hdmi_.*/d" $CONFIG
  sed -i "/^# hdmi_.*/d" $CONFIG
  sed -i "/^framebuffer.*/d" $CONFIG
fi

if (whiptail --title "Enable PCM5102 audio card" --yesno "Use HiFiberry. Audio Card PCM5102" 10 60) then
  echo "---------------------------------------------------------"
  echo "Enable pcm5102 audio card"
  echo "---------------------------------------------------------"
  if ! grep -q 'hifiberry-dac' $CONFIG; then
    cat <<'EOF' >> $CONFIG

# Enable audio card (hifiberry-dac HiFi pcm5102a-hifi)
dtoverlay=hifiberry-dac
EOF
    sed -i 's/^#\?dtparam=audio=on/#dtparam=audio=on/' $CONFIG
  fi
else
  echo "---------------------------------------------------------"
  echo "Use Analog Audio Output Jack 3,5mm"
  echo "---------------------------------------------------------"
  sed -i "/.*hifiberry-dac.*/d" $CONFIG
  sed -i 's/^#\?dtparam=audio=on/dtparam=audio=on/' $CONFIG
fi

if ! grep -q 'mcp2515-can0' $CONFIG; then
  echo "---------------------------------------------------------"
  echo "Enable mcp2515-can0"
  echo "---------------------------------------------------------"
  sed -i 's/^#\?dtparam=spi=on/dtparam=spi=on/' $CONFIG
  cat <<'EOF' >> $CONFIG

# Enable MCP2515-can0 oscillator=8000000 or 16000000 and GPIO=25
dtoverlay=mcp2515-can0,oscillator=8000000,interrupt=25
dtoverlay=spi-bcm2835-overlay
EOF
fi

if (whiptail --title "IR Remote Control" --yesno "Enable IR-Receiver? \nfor Control Kodi, via RNS-JP3 \nWARNING!!!! ONLY FOR RNS-JP3 (Asian)" 10 60); then
  echo "---------------------------------------------------------"
  echo "Installing ir-keytable"
  echo "---------------------------------------------------------"
  if ! grep -q 'dtoverlay=gpio-ir,.*' $CONFIG; then
    cat <<'EOF' >> $CONFIG

dtoverlay=gpio-ir,gpio_pin=17
EOF
  fi

  apt purge lirc
  rm -r /etc/lirc
  apt install -y ir-keytable
  cat <<'EOF' > /etc/rc_keymaps/nec_rnsjp3.toml
[[protocols]]
name = "nec_rnsjp3"
protocol = "nec"
[protocols.scancodes]

0x98 = "KEY_STOP"
0x89 = "KEY_ENTER"
0x8a = "KEY_BACK"
0x94 = "KEY_UP"
0x8e = "KEY_DOWN"
0x8d = "KEY_LEFT"
0x8c = "KEY_RIGHT"
0x92 = "KEY_STOP"
0x96 = "KEY_I"
0x97 = "KEY_C"
0x9b = "KEY_PREVIOUSSONG"
0x87 = "KEY_NEXTSONG"
EOF
  mv /etc/rc_maps.cfg /etc/rc_maps.cfg.orig
  cat <<'EOF' > /etc/rc_maps.cfg
#driver table                    file
*       rc-rc6-mce               nec_rnsjp3.toml
EOF
else
  sed -i "/^dtoverlay=gpio-ir.*/d" $CONFIG
fi


chown -R pi:pi /home/pi/

if (whiptail --title "Installation Completed" --yesno "Reboot System Now" 10 60) then
  cp /boot/canserial.txt /home/pi/.canserial.txt
  cp /boot/.canserial.txt /home/pi/.canserial.txt
  reboot
fi
