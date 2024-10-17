#!/bin/bash

####################################
SKIN=skin.carpc
Ver=-1.0.4
REPOSITORY=repository.maltsev_kodi
BaseSkin=skin.estuary
KODI=/home/pi/.kodi/addons/
####################################

PI=$(cat /proc/device-tree/model)

# if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  # if grep -q 'Raspberry Pi 4\|Raspberry Pi 5' /proc/device-tree/model; then 
      # whiptail --title "ABORT INSTALLATION" --msgbox "YOU ARE USING A VERY OLD SYSTEM.\nYOUR BOARD $PI\nIS NOT SUPPORTED\nUSE BOOKWORM AND A NEW OPERATING SYSTEM!" 10 60
      # exit 0
  # fi
# fi


ping -c1 -w1 google.de 2>/dev/null 1>/dev/null
if [ "$?" = 0 ]; then
  echo "---------------------------------------------------------"
  echo "Internet connection OK"
  echo "---------------------------------------------------------"
else
  whiptail --title "Inernet Connection" --msgbox "Inernet Connection is Missing \nPlease make sure a internet connection is available \nand than restart installer!" 10 60
  exit 0
fi

if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  apt-get update --allow-releaseinfo-change
fi

echo "---------------------------------------------------------"
echo "Update System"
echo "---------------------------------------------------------"
apt update -y > /dev/null 2>&1
if [ ! $? = 0 ]; then
  whiptail --title "UPDATE SYSTEM ERROR" --msgbox "PLEASE RESTART THE INSTALLER!" 10 60
  exit 0
fi

if (whiptail --title "FULL UPGRADE SYSTEM" --yesno "This task, will take a long time." 10 60) then
  echo "---------------------------------------------------------"
  echo "FULL UPGRADE SYSTEM"
  echo "---------------------------------------------------------"
  apt upgrade -y > /dev/null 2>&1
  apt autoremove -y > /dev/null 2>&1
else
  echo "---------------------------------------------------------"
  echo "YOU CANCELED UPGRADE SYSTEM"
  echo "---------------------------------------------------------"
fi

echo "---------------------------------------------------------"
echo "Installing SAMBA"
echo "---------------------------------------------------------"
if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  echo "samba-common samba-common/workgroup string  WORKGROUP" | debconf-set-selections
  echo "samba-common samba-common/dhcp boolean true" | debconf-set-selections
  echo "samba-common samba-common/do_debconf boolean true" | debconf-set-selections
fi
apt install -y samba > /dev/null 2>&1
if [ ! $? = 0 ]; then
  whiptail --title "SAMBA INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER!" 10 60
  exit 0
fi

if ! grep -q "/home/pi/" /etc/samba/smb.conf; then
  echo "---------------------------------------------------------"
  echo "config samba"
  echo "---------------------------------------------------------"
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
echo "Installing KODI"
echo "---------------------------------------------------------"
apt install -y kodi > /dev/null 2>&1
if [ ! $? = 0 ]; then
  whiptail --title "KODI INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER!" 10 60
  exit 0
fi
sed -i '/service.xbmc.versioncheck/d' /usr/share/kodi/system/addon-manifest.xml #Disable versioncheck

echo "---------------------------------------------------------"
echo "Installing KODI PVR IPTV"
echo "---------------------------------------------------------"
apt install -y kodi-pvr-iptvsimple > /dev/null 2>&1
if [ ! $? = 0 ]; then
  whiptail --title "KODI PVR IPTV INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER!" 10 60
  exit 0
fi
if ! grep -q "/usr/bin/kodi-standalone" /etc/systemd/system/kodi.service; then
  echo "---------------------------------------------------------"
  echo "config upstart kodi"
  echo "---------------------------------------------------------"
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
  systemctl enable kodi
  systemctl start kodi 
fi

echo "---------------------------------------------------------"
echo "Installing CAN-UTILS"
echo "---------------------------------------------------------"
apt install -y can-utils > /dev/null 2>&1
if [ ! $? = 0 ]; then
  whiptail --title "CAN-UTILS INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER!" 10 60
  exit 0
fi

echo "---------------------------------------------------------"
echo "upstart can0 interface"
echo "---------------------------------------------------------"
if ! grep -q "auto can0" /etc/network/interfaces; then
  cat <<'EOF' >> /etc/network/interfaces
auto can0
  iface can0 inet manual
  pre-up /sbin/ip link set can0 type can bitrate 100000
  up /sbin/ifconfig can0 up
  down /sbin/ifconfig can0 down
EOF
fi

echo "---------------------------------------------------------"
echo "Installing PYTHON-CAN"
echo "---------------------------------------------------------"
if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  apt install -y python-can > /dev/null 2>&1
  if [ ! $? = 0 ]; then
    whiptail --title "PYTHON-CAN INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
else
  apt install -y python3-can > /dev/null 2>&1
  if [ ! $? = 0 ]; then
    whiptail --title "PYTHON3-CAN INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
fi
#
##############################################
#              INSTALL OVERLAY SD            #
##############################################
if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  echo "---------------------------------------------------------"
  echo "Installing Overlay SD card"
  echo "---------------------------------------------------------"
  apt-get install -y overlayroot > /dev/null 2>&1
  if [ ! $? = 0 ]; then
    whiptail --title "OVERLAY SD CARD INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
fi
#
##############################################
#           INSTALL AUTOMOUNT USB            #
##############################################
if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  echo "---------------------------------------------------------"
  echo "Installing USB AUTOMOUNT"
  echo "---------------------------------------------------------"
 # apt-cache policy usbmount
  
  
  
  apt install -y usbmount > /dev/null 2>&1
  if [ $? = 0 ]; then
    mkdir /home/pi/tmpu && cd /home/pi/tmpu
	if ! [ -e /home/pi/tmpu/usbmount_0.0.24_all.deb ] ; then
      wget -t 100 https://github.com/nicokaiser/usbmount/releases/download/0.0.24/usbmount_0.0.24_all.deb > /dev/null 2>&1
	fi
    if [ -e /home/pi/tmpu/usbmount_0.0.24_all.deb ] ; then
      dpkg -i usbmount_0.0.24_all.deb > /dev/null 2>&1
      cd /home/pi && rm -Rf /home/pi/tmpu
    fi
    echo 'edit config usbmount '
    sed -i 's/FS_MOUNTOPTIONS=""/FS_MOUNTOPTIONS="-fstype=vfat,iocharset=utf8,gid=1000,dmask=0007,fmask=0007"/' /etc/usbmount/usbmount.conf
    sed -i 's/FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus"/FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus ntfs fuseblk"/' /etc/usbmount/usbmount.conf
  fi
  if [ ! $? = 0 ]; then
    whiptail --title "USBMOUNT INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
fi
#
##############################################
#         INSTALL BLUETOOTHE RECIEVER        #
##############################################
if (whiptail --title "Bluetooth audio receiver installer" --yesno "Install Bluetooth Audio Receive." 10 60) then
  echo "---------------------------------------------------------"
  echo "Installing BLUETOOTHE RECIEVER"
  echo "---------------------------------------------------------"
  hostnamectl set-hostname --pretty "rns"
  apt install -y --no-install-recommends pulseaudio > /dev/null 2>&1
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
  apt install -y --no-install-recommends bluez-tools pulseaudio-module-bluetooth > /dev/null 2>&1
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
  echo "---------------------------------------------------------"
  echo "DOWNLOAD" $SKIN$Ver
  echo "---------------------------------------------------------"
  if ! [ -e /tmp/$SKIN$Ver.zip ] ; then
    wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi18/$SKIN/$SKIN$Ver.zip > /dev/null 2>&1
  fi

elif grep -q 'VERSION="11 (bullseye)"' /etc/os-release; then
  echo "---------------------------------------------------------"
  echo "DOWNLOAD" $SKIN$Ver
  echo "---------------------------------------------------------"
  if ! [ -e /tmp/$SKIN$Ver.zip ] ; then
    wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi19/$SKIN/$SKIN$Ver.zip > /dev/null 2>&1
  fi

elif grep -q 'VERSION="12 (bookworm)"' /etc/os-release; then
  echo "---------------------------------------------------------"
  echo "DOWNLOAD" $SKIN$Ver
  echo "---------------------------------------------------------"
  if ! [ -e /tmp/$SKIN$Ver.zip ] ; then
    wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi20/$SKIN/$SKIN$Ver.zip > /dev/null 2>&1
  fi
elif ! [ -e /tmp/$SKIN$Ver.zip ] ; then
  whiptail --title "ERROR DOWNLOADS" --msgbox "restart installer!" 10 60
  exit 0
fi

if [ -e /tmp/$SKIN$Ver.zip ] ; then
  echo "---------------------------------------------------------"
  echo "DOWNLOAD" $REPOSITORY
  echo "---------------------------------------------------------"
  if ! [ -e /tmp/$REPOSITORY.zip ] ; then
    wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/$REPOSITORY.zip > /dev/null 2>&1
  fi
else
  whiptail --title "ERROR DOWNLOADS REPOSITORY" --msgbox "Not FIND SKIN /tmp \nrestart installer!" 10 60
  exit 0
fi
#remove old skin
if [ -d $KODI$SKIN ] ; then
  echo "---------------------------------------------------------"
  echo "REMOVE OLD INSTALL FOLDER"
  echo $KODI$SKIN
  echo "---------------------------------------------------------"
  systemctl stop kodi && rm -r $KODI$SKIN
fi
if [ -d $KODI$REPOSITORY ] ; then
  echo "---------------------------------------------------------"
  echo "REMOVE OLD INSTALL FOLDER"
  echo  $KODI$REPOSITORY
  echo "---------------------------------------------------------"
  systemctl stop kodi
  rm -r $KODI$REPOSITORY
fi
#Install Skin
if [ -e /tmp/$SKIN$Ver.zip ] ; then
  echo "---------------------------------------------------------"
  echo "UNZIP" $SKIN$Ver
  echo "---------------------------------------------------------"
  unzip /tmp/$SKIN$Ver.zip -d $KODI > /dev/null 2>&1
fi
if [ -e /tmp/$REPOSITORY.zip ] ; then
  echo "---------------------------------------------------------"
  echo "UNZIP" $REPOSITORY
  echo "---------------------------------------------------------"
  unzip /tmp/$REPOSITORY.zip -d $KODI > /dev/null 2>&1
fi
#add autoload
if ! grep -q $SKIN /usr/share/kodi/system/addon-manifest.xml; then
  echo $SKIN "add in addon-manifest.xml"
  sed -i -e '$i \  <addon optional="true">'$SKIN'</addon>' /usr/share/kodi/system/addon-manifest.xml
fi
if ! grep -q $REPOSITORY /usr/share/kodi/system/addon-manifest.xml; then
  echo "---------------------------------------------------------"
  echo $REPOSITORY "add in addon-manifest.xml"
  echo "---------------------------------------------------------"
  sed -i -e '$i \  <addon optional="true">'$REPOSITORY'</addon>' /usr/share/kodi/system/addon-manifest.xml
fi
if ! grep -q $SKIN  /home/pi/.kodi/userdata/guisettings.xml; then
  echo "---------------------------------------------------------"
  echo $SKIN "add in guisettings.xml"
  echo "---------------------------------------------------------"
  sed -i -e 's/lookandfeel.skin" default="true">'$BaseSkin'/lookandfeel.skin">'$SKIN'/' /home/pi/.kodi/userdata/guisettings.xml
fi
#
##############################################
#        CREATING FOLDER FOR MEDIA           #
##############################################
if ! [ -d '/home/pi/movies\|/home/pi/music\|/home/pi/mults\|/home/pi/clips\|/home/pi/tvshows' ] ; then
  echo "---------------------------------------------------------"
  echo "CREATING FOLDER FOR MEDIA"
  echo "---------------------------------------------------------"
  mkdir /home/pi/movies /home/pi/music /home/pi/mults /home/pi/clips /home/pi/tvshows
  chmod -R 0777 /home/pi/movies /home/pi/music /home/pi/mults /home/pi/clips /home/pi/tvshows
fi
#
#
##############################################
#                SETTINGS KODI               #
##############################################
echo "---------------------------------------------------------"
echo "presettings kodi"
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

if ! [ -e $CONFIG'_original.txt' ] ; then
  cp $CONFIG $CONFIG'_original.txt'
fi
if ! [ -e $CMDLINE'_original.txt' ] ; then
  cp $CMDLINE $CMDLINE'_original.txt'
fi


if (whiptail --title "Video Output" --yesno "Use HDMI-VGA Adapter For Video Output?" 10 60); then
  echo "---------------------------------------------------------"
  echo "Use HDMI-VGA Adapter For Video Output"
  echo "---------------------------------------------------------"
  sed -i -r 's/.+(console=serial0)/\1/' $CMDLINE # Delete Analog Video
  sed -i -r 's/(.+)vc4.tv_norm.+/\1/' $CMDLINE   #Delete drm.edid
  sed -i "/^enable_tvout.*/d" $CONFIG            # Delete Analog Video
  sed -i -r 's/(.+),composite/\1/' $CONFIG       # Delete Analog Video
  
  if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    echo "---------------------------------------------------------"
    echo $CMDLINE 'Default video=HDMI-A-1:NTSC'
    echo "PAL | NTSC"
    echo 'Driver drm.edid_firmware=HDMI-A-1:Rpi480i_EDID.bin'
    echo "---------------------------------------------------------"
    if ! [ -e /usr/lib/firmware/Rpi480i_EDID.bin ] ; then
      echo 'Downloads Rpi480i'
      wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/old_install/Rpi480i_EDID.bin > /dev/null 2>&1
      cp /tmp/Rpi480i_EDID.bin /usr/lib/firmware/Rpi480i_EDID.bin
    fi
    if ! grep -q 'video=HDMI-A-1:NTSC' $CMDLINE; then
      sed -i "s/^/video=HDMI-A-1:NTSC,margin_left=29,margin_right=10,margin_top=0,margin_bottom=15 /" $CMDLINE
    fi
    if ! grep -q 'Rpi480i_EDID.bin' $CMDLINE; then
      sed -i "s/$/ drm.edid_firmware=HDMI-A-1:Rpi480i_EDID.bin/" $CMDLINE
    fi
  else
    sed -i "/^sdtv_.*/d" $CONFIG # Delete Analog Video
    if ! grep -q 'hdmi_timings.*' $CONFIG; then
      if grep -q 'Raspberry Pi 4' /proc/device-tree/model; then
        cat <<'EOF' >> $CONFIG
# hdmi_vga adapter
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_timings=640 0 16 88 64 480 0 6 5 13 0 0 0 60 1 12700000 1
EOF

      else
        cat <<'EOF' >> $CONFIG

# hdmi_vga adapter
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_ignore_edid=0xa5000080
hdmi_timings=800 0 51 44 121 460 0 10 9 14 0 0 0 32 1 16000000 3
EOF
      fi
    fi
  fi
else
  echo "---------------------------------------------------------"
  echo "Use Analog Video Output Jack 3,5mm"
  echo "---------------------------------------------------------"
  if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    sed -i -r 's/.+(console=serial0)/\1/' $CMDLINE #Delete video=
    sed -i -r 's/(.+)drm.edid.+/\1/' $CMDLINE #Delete drm.edid
    echo "---------------------------------------------------------"
    echo $CMDLINE 'Default vc4.tv_norm=NTSC and video=Composite-1:720x480@60ie'
    echo "PAL | NTSC | NTSC-J | NTSC-443 | PAL-M | PAL-N. | PAL60 | SECAM"
    echo 'video=Composite-1:720x576@50ie or video=Composite-1:720x480@60ie'
    echo "---------------------------------------------------------"
    if ! grep -q 'video=Composite.*' $CMDLINE; then
      sed -i "s/^/video=Composite-1:720x480@60ie /" $CMDLINE
    fi
    if ! grep -q 'vc4.tv.*' $CMDLINE; then #driver
      sed -i "s/$/vc4.tv_norm=NTSC /" $CMDLINE
    fi
    if ! grep -q '.*composite' $CONFIG; then
      sed -i "s/^dtoverlay=vc4-.*/dtoverlay=vc4-kms-v3d,composite/" $CONFIG
    fi
  else #BUSTER
    sed -i "/.*hdmi_.*/d" $CONFIG #Delete hdmi_
	sed -i "/.*sdtv_.*/d" $CONFIG #Delete sdtv_
    if ! grep -q 'sdtv_aspect.*' $CONFIG; then
      echo "---------------------------------------------------------"
      echo $CONFIG 'Default sdtv_aspect=1 4:3'
      echo "aspect=1 4:3 | aspect=2 14:9 | aspect=3 16:9"
      echo "---------------------------------------------------------"
      cat <<'EOF' >> $CONFIG

# sdtv_aspect=1 4:3 | sdtv_aspect=2 14:9 | sdtv_aspect=3 16:9
sdtv_aspect=1
EOF
    fi
    if ! grep -q 'sdtv_mode.*' $CONFIG; then
      echo "---------------------------------------------------------"
      echo $CONFIG 'Default sdtv_mode=0 NTSC'
      echo 'mode=0 NTSC | mode=1 NTSC JAPAN | mode=2 PAL | mode=3 PAL BRAZIL'
      echo "---------------------------------------------------------"
      cat <<'EOF' >> $CONFIG

# sdtv_mode=0 NTSC | sdtv_mode=1 NTSC JAPAN | sdtv_mode=2 PAL | sdtv_mode=3 PAL BRAZIL
sdtv_mode=0
EOF
    fi
	if ! grep -q 'enable_tvout=1' $CONFIG; then
		cat <<'EOF' >> $CONFIG

enable_tvout=1
EOF
	fi
  fi
fi



if (whiptail --title "Enable PCM5102 audio card" --yesno "Use HiFiberry. Audio Card PCM5102" 10 60) then
  echo "---------------------------------------------------------"
  echo "Enable pcm5102 audio card"
  echo "---------------------------------------------------------"
  if ! grep -q 'hifiberry-dac' $CONFIG; then
    echo "---------------------------------------------------------"
    echo "Digital Audio Card PCM5102"
    echo "---------------------------------------------------------"
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
  apt purge lirc > /dev/null 2>&1
  rm -r /etc/lirc > /dev/null 2>&1
  apt install -y ir-keytable > /dev/null 2>&1
  if [ ! $? = 0 ]; then
    whiptail --title "ir-keytable INSTALLATION ERROR" --msgbox "PLEASE RESTART THE INSTALLER! \nsudo sh install.sh" 10 60
    exit 0
  fi
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
  
  if ! grep -q 'dtoverlay=gpio-ir,.*' $CONFIG; then
    cat <<'EOF' >> $CONFIG

dtoverlay=gpio-ir,gpio_pin=17
EOF
  fi
else
  sed -i "/^dtoverlay=gpio-ir.*/d" $CONFIG
fi
#
chown -R pi:pi /home/pi/


if (whiptail --title "Installation Completed" --yesno "Reboot System Now" 10 60) then
  echo "---------------------------------------------------------"
  echo "Reboot System"
  echo "---------------------------------------------------------"
  reboot
fi
