#!/bin/bash

BGreen="\033[1;32m"     # Green
BRed="\033[1;31m"       # Red
BBlue="\033[1;34m"      # Blue
NC="\033[0m"            # No Color


####################################
SKIN=skin.carpc
Ver=-1.0.5
REPOSITORY=repository.maltsev_kodi
BaseSkin=skin.estuary
KODI=/home/pi/.kodi/addons/
####################################

ModelPI=/proc/device-tree/model



network() {
  ping -c1 -w1 google.de 2>/dev/null 1>/dev/null
}

update() {
  echo ${BGreen}"Update Packets"${NC}
  if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    #apt-get update --allow-releaseinfo-change && > /dev/null 2>&1
	apt-get update -y
  else
    apt update -y #> /dev/null 2>&1
  fi
}

is_installed() {
  dpkg -s "$1" > /dev/null 2>&1
}

samba() {
  if is_installed "samba"; then
    echo ${BGreen}"Installed SAMBA"${NC};
  else
    echo ${BGreen}"Installing SAMBA"${NC}
    if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
      echo "samba-common samba-common/workgroup string  WORKGROUP" | debconf-set-selections
      echo "samba-common samba-common/dhcp boolean true" | debconf-set-selections
      echo "samba-common samba-common/do_debconf boolean true" | debconf-set-selections
    fi
    apt-get install -y samba && > /dev/null 2>&1
    service smbd restart
fi
}

samba_conf() {
  if ! grep -q "/home/pi/" /etc/samba/smb.conf; then
    echo ${BGreen}"Added config"${NC}
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
  else
    echo ${BGreen}"Correct config"${NC}
  fi
}

kodi() {
  if is_installed "kodi"; then
    echo ${BGreen}"Installed KODI"${NC}
  else
    echo ${BGreen}"Installing KODI"${NC} &&
    apt-get install -y kodi && > /dev/null 2>&1
    sed -i '/service.xbmc.versioncheck/d' /usr/share/kodi/system/addon-manifest.xml #Disable versioncheck
  fi
}

kodi_pvr() {
  if is_installed "kodi-pvr-iptvsimple"; then
    echo ${BGreen}"Installed IPTV for KODI IPTV"${NC}
  else
    echo ${BGreen}"Installing IPTV for KODI"${NC}
    apt-get install -y kodi-pvr-iptvsimple > /dev/null 2>&1
  fi
}

kodi_conf() {
  if ! grep -q "/usr/bin/kodi-standalone" /etc/systemd/system/kodi.service; then
    echo ${BGreen}"Added config upstart "${NC}
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
    systemctl enable kodi &&
    systemctl start kodi
  else
    echo ${BGreen}"Correct config upstart"${NC}
  fi
}

kodi_status() {
  if (systemctl -q is-active kodi.service); then
    echo ${BGreen}"STOP KODI"${NC}
    systemctl stop kodi.service
    sleep 5
  elif (systemctl -q is-active kodi.service); then
    echo ${BGreen}"wait +5 sec."${NC}
    systemctl stop kodi.service
    sleep 5
    exit 1
  # else
    # echo ${BGreen}"Run KODI"${NC}
    # systemctl enable kodi
    # systemctl start kodi
  fi
}

kodi_settings() {
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
  echo ${BGreen}"Disable Screensaver"${NC}
  sed -i 's/id="screensaver.mode" default="true">screensaver.xbmc.builtin.dim/id="screensaver.mode">/' /home/pi/.kodi/userdata/guisettings.xml
  sed -i 's/id="screensaver.mode" default="true">default/id="screensaver.mode">/' /home/pi/.kodi/userdata/guisettings.xml

  echo ${BGreen}"Auto play next video"${NC}
  sed -i 's/id="videoplayer.autoplaynextitem" default="true">/id="videoplayer.autoplaynextitem">0,1,2,3,4/' /home/pi/.kodi/userdata/guisettings.xml

  echo ${BGreen}"Amplifi volume up to 30.0dB"${NC}
  sed -i 's/volumeamplification>0.000000/volumeamplification>30.000000/' /home/pi/.kodi/userdata/guisettings.xml

  echo ${BGreen}"Enable web-server (WEB-control)"${NC}
  sed -i 's/id="services.webserverauthentication" default="true">true/id="services.webserverauthentication">false/' /home/pi/.kodi/userdata/guisettings.xml
  sed -i 's/id="services.webserver" default="true">false/id="services.webserver">true/' /home/pi/.kodi/userdata/guisettings.xml

chown -R pi:pi /home/pi/

}

usbmount() {
  if is_installed "usbmount"; then
    echo ${BGreen}"Installed USBMOUNT"${NC}
  else
    echo ${BGreen}"Installing USBMOUNT"${NC}
    apt-get install -y usbmount > /dev/null 2>&1
  fi
}

usbmount_update() {
  version="$(dpkg-query --showformat="\${Version}" --show usbmount 2>&1)"
  if [ "$version" = '0.0.24' ]; then
    echo ${BGreen}$version${NC}
  else
    echo ${BRed}$version${NC}
    mkdir /home/pi/tmpu && cd /home/pi/tmpu
    if ! [ -e /home/pi/tmpu/usbmount_0.0.24_all.deb ] ; then
      wget -t 100 https://github.com/nicokaiser/usbmount/releases/download/0.0.24/usbmount_0.0.24_all.deb > /dev/null 2>&1
    fi
    if [ -e /home/pi/tmpu/usbmount_0.0.24_all.deb ] ; then
      dpkg -i usbmount_0.0.24_all.deb > /dev/null 2>&1
      cd /home/pi && rm -Rf /home/pi/tmpu
    fi
    sed -i 's/FS_MOUNTOPTIONS=""/FS_MOUNTOPTIONS="-fstype=vfat,iocharset=utf8,gid=1000,dmask=0007,fmask=0007"/' /etc/usbmount/usbmount.conf &&
    sed -i 's/FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus"/FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus ntfs fuseblk"/' /etc/usbmount/usbmount.conf
    echo ${BGreen}$version${NC}
  fi
}

can_utils() {
  if is_installed "can-utils"; then
    echo ${BGreen}"Installed CAN-UTILS"${NC}
  else
    echo ${BGreen}"Installing CAN-UTILS"${NC}
    apt install -y can-utils > /dev/null 2>&1
  fi
}

can0_upstart() {
  if ! grep -q "auto can0" /etc/network/interfaces; then
    echo ${BGreen}"Added config CAN0"${NC}
    cat <<'EOF' >> /etc/network/interfaces
auto can0
  iface can0 inet manual
  pre-up /sbin/ip link set can0 type can bitrate 100000
  up /sbin/ifconfig can0 up
  down /sbin/ifconfig can0 down
EOF
  else
    echo ${BGreen}"Correct config CAN0"${NC}
  fi
}

python_can() {
  if is_installed "python-can"; then
    echo ${BGreen}"Installed PYTHON-CAN"${NC}
  else
    echo ${BGreen}"Installing PYTHON-CAN"${NC}
    if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
      apt install -y python-can > /dev/null 2>&1
    else
      apt install -y python3-can > /dev/null 2>&1
    fi
  fi
}

overlay_sd() {
  if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    if is_installed "overlayroot"; then
      ${BGreen}"Installed Overlay SD card"${NC}
    else
      echo ${BGreen}"Installing Overlay SD card"${NC}
      apt-get install -y overlayroot > /dev/null 2>&1
    fi
  fi
}
#######################################################


bluetooth() {
  #hostnamectl set-hostname --pretty "rns" 
  if is_installed "pulseaudio"; then
    echo ${BGreen}"PulseAudio"${NC}
  else
    echo ${BGreen}"PulseAudio"${NC}
    apt install -y --no-install-recommends pulseaudio && > /dev/null 2>&1
  fi
  if is_installed bluez-tools; then
    echo ${BGreen}"Bluez-tools"${NC}
  else
    echo ${BGreen}"Bluez-tools"${NC}
    apt install -y --no-install-recommends bluez-tools && > /dev/null 2>&1
  fi
  if is_installed "pulseaudio-module-bluetooth"; then
    echo ${BGreen}"PulseAudio-Module-Bluetooth"${NC}
  else
    echo ${BGreen}"PulseAudio-Module-Bluetooth"${NC}
    apt install -y --no-install-recommends pulseaudio-module-bluetooth > /dev/null 2>&1
  fi
}


bluetooth_conf() {
  usermod -a -G pulse-access root &&
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
  systemctl enable --now pulseaudio.service &&
  systemctl --global mask pulseaudio.socket &&

  cat <<'EOF' > /etc/bluetooth/main.conf
[General]
Class = 0x200414
DiscoverableTimeout = 0

[Policy]
AutoEnable=true
EOF
  mkdir -p /etc/systemd/system/bthelper@.service.d &&
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
  systemctl daemon-reload &&
  systemctl enable bt-agent@hci0.service
  if ! grep -q 'module-bluetooth-discover' /etc/pulse/system.pa; then
    echo "load-module module-bluetooth-policy" >> /etc/pulse/system.pa &&
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
  chmod 755 /usr/local/bin/bluetooth-udev &&
  cat <<'EOF' > /etc/udev/rules.d/99-bluetooth-udev.rules
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluetooth-udev"
EOF
  fi
}


bluetooth_conf_asound() {
  if ! grep -q 'defaults.ctl.card 0' /etc/asound.conf; then
    echo ${BGreen}"Added config asound"${NC}
    cat <<'EOF' > /etc/asound.conf
defaults.ctl.card 0
defaults.ctl.card 0
EOF
  else
    echo ${BGreen}"Correct config asound.conf"${NC}
  fi
}




##############################################
#               INSTALL SKIN                 #
##############################################
skin_download() {
  if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    if ! [ -e /tmp/$SKIN$Ver.zip ] ; then
      echo ${BGreen}"DOWNLOADING" $SKIN$Ver${NC}
      wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi18/$SKIN/$SKIN$Ver.zip > /dev/null 2>&1
    elif [ -e /tmp/$SKIN$Ver.zip ] ; then
      echo ${BGreen}"DOWNLOADED" $SKIN$Ver.zip${NC}
    fi

  elif grep -q 'VERSION="11 (bullseye)"' /etc/os-release; then
    if ! [ -e /tmp/$SKIN$Ver.zip ] ; then
      echo ${BGreen}"DOWNLOADING" $SKIN$Ver${NC}
      wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi19/$SKIN/$SKIN$Ver.zip > /dev/null 2>&1
    elif [ -e /tmp/$SKIN$Ver.zip ] ; then
      echo ${BGreen}"DOWNLOADED" $SKIN$Ver.zip${NC}
    fi

  elif grep -q 'VERSION="12 (bookworm)"' /etc/os-release; then
    if ! [ -e /tmp/$SKIN$Ver.zip ] ; then
      echo ${BGreen}"DOWNLOADING" $SKIN$Ver${NC}
      wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi20/$SKIN/$SKIN$Ver.zip > /dev/null 2>&1
    elif [ -e /tmp/$SKIN$Ver.zip ] ; then
      echo ${BGreen}"DOWNLOADED" $SKIN$Ver.zip${NC}
    fi
  else 
    if ! [ -e /tmp/$SKIN$Ver.zip ] ; then
      echo ${BRed}"ERROR DOWNLOADS" $SKIN$Ver${NC} &&
      exit 0
    fi
  fi
}

skin_repo_download() {
  if ! [ -e /tmp/$REPOSITORY.zip ] ; then
    echo ${BGreen}"DOWNLOADING" $REPOSITORY.zip${NC}
    wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/$REPOSITORY.zip > /dev/null 2>&1
  elif [ -e /tmp/$REPOSITORY.zip ] ; then
    echo ${BGreen}"DOWNLOADED" $REPOSITORY.zip${NC}
  else
    echo ${BRed}"ERROR DOWNLOADS" $REPOSITORY.zip${NC}
    #exit 0
  fi
}

skin_remove() {
  echo $(kodi_status) &&
  echo ${BRed}"Remove"
  if [ -d $KODI$SKIN ] ; then
    echo ${BRed}$KODI$SKIN${NC}
    rm -r $KODI$SKIN
  fi
  if [ -d $KODI$REPOSITORY ] ; then
    echo ${BRed}$KODI$SKIN${NC}
    rm -r $KODI$REPOSITORY
  fi
}

skin_install() {
  echo $(kodi_status)
  if [ -e /tmp/$SKIN$Ver.zip ] ; then
    echo ${BGreen}"UNZIP" $SKIN$Ver${NC}
    unzip /tmp/$SKIN$Ver.zip -d $KODI > /dev/null 2>&1
  fi
  if [ -e /tmp/$REPOSITORY.zip ] ; then
    echo ${BGreen}"UNZIP" $REPOSITORY${NC}
    unzip /tmp/$REPOSITORY.zip -d $KODI > /dev/null 2>&1
  fi
}
skin_config() {
#add autoload
  echo $(kodi_status)
  if ! grep -q $SKIN /usr/share/kodi/system/addon-manifest.xml; then
    echo ${BGreen}$SKIN "to addon-manifest.xml"${NC}
    sed -i -e '$i \  <addon optional="true">'$SKIN'</addon>' /usr/share/kodi/system/addon-manifest.xml
  fi
  if ! grep -q $REPOSITORY /usr/share/kodi/system/addon-manifest.xml; then
    echo ${BGreen}$REPOSITORY "to addon-manifest.xml"${NC}
    sed -i -e '$i \  <addon optional="true">'$REPOSITORY'</addon>' /usr/share/kodi/system/addon-manifest.xml
  fi
  if ! grep -q $SKIN  /home/pi/.kodi/userdata/guisettings.xml; then
    echo ${BGreen}$SKIN "to guisettings.xml"${NC}
    sed -i -e 's/lookandfeel.skin" default="true">'$BaseSkin'/lookandfeel.skin">'$SKIN'/' /home/pi/.kodi/userdata/guisettings.xml
  fi
}


##############################################
#        CREATING FOLDER FOR MEDIA           #
##############################################
folder() {
  if ! [ -d /home/pi/movies ] ; then
    echo ${BGreen}"movies"${NC}
    mkdir /home/pi/movies && chmod -R 0777 /home/pi/movies
  else
    echo ${BGreen}"movies"${NC}
  fi
  if ! [ -d /home/pi/tvshows ] ; then
    echo ${BGreen}"tvshows"${NC}
    mkdir /home/pi/tvshows && chmod -R 0777 /home/pi/tvshows
  else
    echo ${BGreen}"tvshows"${NC}
  fi
  if ! [ -d /home/pi/clips ] ; then
    echo ${BGreen}"clips"${NC}
    mkdir /home/pi/clips && chmod -R 0777 /home/pi/clips
  else
    echo ${BGreen}"clips"${NC}
  fi
  if ! [ -d /home/pi/music ] ; then
    echo ${BGreen}"music"${NC}
    mkdir /home/pi/music && chmod -R 0777 /home/pi/music
  else
    echo ${BGreen}"music"${NC}
  fi
}

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


config_rpi() {
  if ! [ -e $CONFIG'_original.txt' ] ; then
    cp $CONFIG $CONFIG'_original.txt'
  fi
  if ! [ -e $CMDLINE'_original.txt' ] ; then
    cp $CMDLINE $CMDLINE'_original.txt'
  fi
}


config_video_hdmi() {
  echo ${BGreen}"Use HDMI-VGA Adapter For Video Output"${NC}
  if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    sed -i -r 's/.+(console=serial0)/\1/' $CMDLINE  # Del Analog Video
    sed -i -r 's/(.+) vc4.tv_norm.+/\1/' $CMDLINE  # Del Analog Video
    if ! [ -e /usr/lib/firmware/Rpi480i_EDID.bin ] ; then
      echo ${BGreen}'Downloads Rpi480i'${NC}
      wget -t 100 -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/old_install/Rpi480i_EDID.bin && > /dev/null 2>&1
      cp /tmp/Rpi480i_EDID.bin /usr/lib/firmware/Rpi480i_EDID.bin
    fi
    if ! grep -q 'video=HDMI-A-1:NTSC' $CMDLINE; then
      sed -i 's/^/video=HDMI-A-1:NTSC,margin_left=29,margin_right=10,margin_top=0,margin_bottom=15 /' $CMDLINE
    fi
    if ! grep -q 'Rpi480i_EDID.bin' $CMDLINE; then
      sed -i 's/$/ drm.edid_firmware=HDMI-A-1:Rpi480i_EDID.bin/' $CMDLINE
    fi
  fi
  sed -i 's/^#\?#disable_overscan=1/disable_overscan=1/' $CONFIG     # Edit For HDMI
  sed -i 's/^#\?hdmi_force_hotplug=1/hdmi_force_hotplug=1/' $CONFIG  # Edit For HDMI
  sed -i 's/^#\?hdmi_group=.*/hdmi_group=2/' $CONFIG                # Edit For HDMI
  sed -i 's/^#\?hdmi_mode=.*/hdmi_mode=87/' $CONFIG                # Edit For HDMI
  sed -i 's/^#\?enable_tvout=.*/#enable_tvout=1/' $CONFIG           # Del Analog Video
  sed -i -r 's/(.+),composite/\1/' $CONFIG                           # Del Analog Video
  if ! grep -q 'hdmi_timings=' $CONFIG; then                         # Add For HDMI
    sed -i '/hdmi_mode=/a\hdmi_timings=640 0 16 88 64 480 0 6 5 13 0 0 0 60 1 12700000 3' $CONFIG
    #sed -i '/hdmi_mode=/a\hdmi_timings=800 0 51 44 121 460 0 10 9 14 0 0 0 32 1 16000000 3' $CONFIG
  fi
}

config_video_analog() {
  echo ${BGreen}"Use Analog Video Output Jack 3,5mm"${NC}
  sed -i 's/^#\?disable_overscan=1/#disable_overscan=1/' $CONFIG        # Edit For Analog
  sed -i 's/^#\?hdmi_force_hotplug=1/#hdmi_force_hotplug=1/' $CONFIG    # Edit For Analog
  sed -i 's/^#\?hdmi_group=.*/#hdmi_group=1/' $CONFIG                 # Edit For Analog
  sed -i 's/^#\?hdmi_mode=.*/#hdmi_mode=1/' $CONFIG                   # Edit For Analog
  sed -i "/.*hdmi_timings=.*/d" $CONFIG                                 # Del HDMI
  sed -i -r 's/.+(console=serial0)/\1/' $CMDLINE                        # Del HDMI
  sed -i -r 's/(.+) drm.edid.+/\1/' $CMDLINE                            # Del HDMI
  if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    if ! grep -q 'Composite-1' $CMDLINE; then
      sed -i "s/^/video=Composite-1:720x576@50ie /" $CMDLINE
                 #video=Composite-1:720x480@60ie
    fi
    if ! grep -q 'vc4.tv_norm=' $CMDLINE; then
      sed -i "s/$/ vc4.tv_norm=NTSC/" $CMDLINE
    fi
    sed -i 's/^#\?dtoverlay=vc4-kms-v3d.*/dtoverlay=vc4-kms-v3d,composite/' $CONFIG
    if ! grep -q 'enable_tvout' $CMDLINE; then
      sed -i '/dtoverlay=vc4-kms-v3d/a\enable_tvout=1' $CONFIG
    fi
  fi
  if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    sed -i 's/^#\?sdtv_mode=.*/sdtv_mode=2/' $CONFIG
    if ! grep -q 'sdtv_aspect' $CMDLINE; then
      sed -i '/sdtv_mode=/a\sdtv_aspect=1' $CONFIG
    fi
  fi
}

config_audio_analog() {
  echo ${BGreen}"Use Analog Audio Output Jack 3,5mm"${NC}
  sed -i 's/^#\?dtparam=audio=on/dtparam=audio=on/' $CONFIG
  sed -i "/.*hifiberry-dac.*/d" $CONFIG
}

config_audio_digital() {
  echo ${BGreen}"Use Digital (PCM5102) Audio Output Jack 3,5mm"${NC}
  sed -i 's/^#\?dtparam=audio=on/#dtparam=audio=on/' $CONFIG
  if ! grep -q 'hifiberry-dac' $CONFIG; then
    sed -i '/dtparam=audio/a\dtoverlay=hifiberry-dac' $CONFIG
  fi
}


config_can0() {
  #echo ${BGreen}'Enable mcp2515-can0'${NC}
  if ! grep -q 'mcp2515-can0' $CONFIG; then
    sed -i 's/^#\?dtparam=spi=on/dtparam=spi=on/' $CONFIG
    if grep -q 'Raspberry Pi 4\|Raspberry Pi 5' $ModelPI; then
      cat <<'EOF' >> $CONFIG

# MCP2515-Can0 oscillator=8000000 or 16000000 and GPIO=25
dtoverlay=mcp2515-can0,oscillator=8000000,interrupt=25
dtoverlay=spi-bcm2837
EOF
    else
      cat <<'EOF' >> $CONFIG

# MCP2515-can0 oscillator=8000000 or 16000000 and GPIO=25
dtoverlay=mcp2515-can0,oscillator=8000000,interrupt=25
dtoverlay=spi-bcm2835-overlay
EOF
    fi
  fi
}

config_ir() {
  echo ${BGreen}"Installing ir-keytable"${NC}
  apt purge lirc > /dev/null 2>&1
  rm -r /etc/lirc > /dev/null 2>&1
  if is_installed "ir-keytable"; then
    echo 
  else
    apt install -y ir-keytable > /dev/null 2>&1
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
  fi
}


######################
network
if [ "$?" = 0 ]; then
  echo ${BGreen}"Internet connection"${NC}
else
  whiptail --title "Inernet Connection" --msgbox "Inernet Connection is Missing \nPlease make sure a internet connection is available \nand than restart installer!" 10 60
  exit 0
fi

update
if [ "$?" = 0 ]; then
  echo ${BGreen}"Update Packets"${NC}
else
  whiptail --title "Inernet Connection" --msgbox "Inernet Connection is Missing \nPlease make sure a internet connection is available \nand than restart installer!" 10 60
  exit 0
fi


if (whiptail --title "FULL UPGRADE SYSTEM" --yesno "This task, will take a long time." 10 60); then
  echo '---------------------------------------------------------'
  echo ${BGreen}"Upgrade System"${NC}
  apt-get upgrade -y > /dev/null 2>&1
  echo '---------------------------------------------------------'
else
  echo ${BRed}"YOU CANCELED UPGRADE SYSTEM"${NC}
fi

echo '---------------------------------------------------------'
echo $(samba)
echo $(samba_conf)
echo $(hostname -I | awk '{print $1}')
echo $(hostname -I | awk '{print $2}')
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo $(kodi)
echo $(kodi_pvr)
echo $(kodi_conf) 
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
 echo $(usbmount)
 echo $(usbmount_update)
fi
echo '---------------------------------------------------------'


echo '---------------------------------------------------------'
echo $(can_utils)
echo $(can0_upstart)
echo '---------------------------------------------------------'

echo $(python_can)

echo $(overlay_sd)

if (whiptail --title "Bluetooth audio receiver installer" --yesno "Install Bluetooth Audio Receive." 10 60) then
  echo "---------------------------------------------------------"
  echo ${BGreen}"Installing BLUETOOTH"${NC}
  echo $(bluetooth) $(bluetooth_conf) $(bluetooth_conf_asound)
  echo ${BGreen}"/etc/asound.conf$"${NC}"\ndefaults.ctl.card 0\ndefaults.ctl.card 0"
  echo "---------------------------------------------------------"
else
  echo "---------------------------------------------------------"
  echo ${BRed}"YOU CANCELED THE INSTALLATION BLUETOOTH RECIEVER"${NC}
  echo "---------------------------------------------------------"
fi

echo '---------------------------------------------------------'
echo ${BGreen}"Installing" $SKIN${NC}
echo $(skin_download)
echo $(skin_repo_download)
echo $(kodi_status)
echo $(skin_remove)
echo $(skin_install)
echo $(skin_config)
echo '---------------------------------------------------------'


echo '---------------------------------------------------------'
echo ${BGreen}"Create Media Folder"${NC}
echo $(folder)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo ${BGreen}"Settings KODI"$(kodi_status)"\nRemoteControl via WebBrowser"${NC}
echo "http://"$(hostname -I | awk '{print $1}')":8080"
echo "http://"$(hostname -I | awk '{print $2}')":8080"
echo '---------------------------------------------------------'

if (whiptail --title "Video Output" --yes-button " HDMI-VGA " --no-button " ANALOG VIDEO " --yesno "Select video output source" 10 60); then
  echo "---------------------------------------------------------"
  echo $(config_rpi) $(config_video_hdmi)
  if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    echo ${BRed}$CMDLINE${NC} '\nvideo=HDMI-A-1:'${BBlue}'NTSC\n'${NC}
    echo ${BRed}$CMDLINE${NC} '\ndrm.edid_firmware=HDMI-A-1:Rpi480i_EDID.bin'
  fi
  echo "---------------------------------------------------------"
else
  echo "---------------------------------------------------------"
  echo $(config_rpi) $(config_video_analog)
  if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    echo ${BRed}$CMDLINE${NC} '\nvc4.tv_norm='${BBlue}'PAL'${NC} ${BBlue}'\nNTSC'${NC} '|' ${BBlue}'PAL\n'${NC}
    echo ${BRed}$CMDLINE${NC} '\nvideo=Composite-1:'${BBlue}'720x576@50ie'${NC} ${BBlue}'\n720x576@50ie'${NC} 'for' ${BGreen}'PAL'${NC} ${BBlue}'\n720x480@60ie'${NC} 'for' ${BGreen}'NTSC\n'${NC}
  elif grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    echo ${BRed}$CONFIG${NC} 'sdtv_mode='${BBlue}'2'${NC} ${BBlue}'\n0'${NC} 'NTSC |' ${BBlue}'1'${NC} 'NTSC JAPAN |' ${BBlue}'2'${NC} 'PAL |' ${BBlue}'3'${NC} 'PAL BRAZIL\n'${NC}
    echo ${BRed}$CONFIG${NC} 'sdtv_aspect='${BBlue}'1'${NC} ${BBlue}'\n1'${NC} '4:3 |' ${BBlue}'2'${NC} '14:9 |' ${BBlue}'3'${NC} '16:9'
  fi
fi

if (whiptail --title "AUDIO Output" --yes-button " PCM5102 " --no-button " ANALOG " --yesno "Select Audio output source" 10 60); then
  echo "---------------------------------------------------------"
  echo $(config_rpi) $(config_audio_digital)
else
  echo $(config_rpi) $(config_audio_analog)
  echo "---------------------------------------------------------"
fi

echo "---------------------------------------------------------"
echo ${BGreen}'Enable mcp2515-can0'${NC}
echo $(config_can0)
echo "---------------------------------------------------------"

if (whiptail --title "IR Remote Control" --yesno "Enable IR-Receiver? \nfor Control Kodi, via RNS-JP3 \nWARNING!!!! ONLY FOR RNS-JP3 (Asian)" 10 60); then
  echo "---------------------------------------------------------"
  echo $(config_rpi) $(config_ir)
  sed -i 's/^#\?dtoverlay=gpio-ir,gpio_pin=17/dtoverlay=gpio-ir,gpio_pin=17/' $CONFIG
  echo "---------------------------------------------------------"
else
  sed -i 's/^#\?dtoverlay=gpio-ir,gpio_pin=17/#dtoverlay=gpio-ir,gpio_pin=17/' $CONFIG
fi


chown -R pi:pi /home/pi/


if (whiptail --title  "Installation Completed" --msgbox  "Reboot System Now" 10 60); then
  echo "---------------------------------------------------------"
  echo "Reboot System"
  echo "---------------------------------------------------------"
  reboot
fi
