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
  ping -c1 -w1 raspberrypi.org 2>/dev/null 1>/dev/null
  if [ "$?" = 0 ]; then
    echo ${BGreen}'Successfully'${NC}
  else
    whiptail --title "ERROR" --msgbox "Inernet Connection is Missing \nRestart installer!" 10 60
    exit 0
  fi
}

update() {
  apt-get update --allow-releaseinfo-change && 2>/dev/null 1>/dev/null
  apt-get update -y 2>/dev/null 1>/dev/null
  if [ "$?" = 0 ]; then
    echo ${BGreen}'\\nSuccessfully'${NC}
  else
    whiptail --title "ERROR" --msgbox "Update Packets \nRestart installer!" 10 60
	exit 0
  fi
}

upgrade() {
  apt-get upgrade -y 2>/dev/null 1>/dev/null
  if [ "$?" = 0 ]; then
    echo ${BGreen}'\\nSuccessfully'${NC}
  else
    whiptail --title "ERROR" --msgbox "Update Packets \nRestart installer!" 10 60
    exit 0
  fi
}

is_installed() {
  dpkg -s "$1" > /dev/null 2>&1
}

samba() {
  if is_installed "samba"; then
    echo ${BGreen}'Successfully'${NC}
  else
    apt-get install -y samba 2>/dev/null 1>/dev/null
    if [ "$?" = 0 ]; then
      echo ${BGreen}'Successfully'${NC}
    else
      whiptail --title "SAMBA" --msgbox "ERROR Installing \nRestart installer!" 10 60
      exit 0
    fi
  fi
  if is_installed "samba"; then
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

kodi() {
  if is_installed "kodi"; then
    echo ${BGreen}'Successfully'${NC}
  else
    echo ${BGreen}'Installing'${NC}
    apt-get install -y kodi 2>/dev/null 1>/dev/null
    if [ "$?" = 0 ]; then
      echo ${BGreen}'Successfully'${NC}
    else
      whiptail --title "KODI" --msgbox "ERROR Installing \nRestart installer!" 10 60
      exit 0
    fi
  fi
  if is_installed "kodi"; then
    apt-get install -y kodi-pvr-iptvsimple 2>/dev/null 1>/dev/null
    sed -i '/service.xbmc.versioncheck/d' /usr/share/kodi/system/addon-manifest.xml #Disable versioncheck
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
    fi
  fi
  if grep -q "/usr/bin/kodi-standalone" /etc/systemd/system/kodi.service; then
    systemctl enable kodi && systemctl start kodi
  fi
}

kodi_status() {
  if is_installed "kodi"; then
    if (systemctl -q is-active kodi.service); then
      systemctl stop kodi.service
      sleep 5
    fi
    if (systemctl -q is-active kodi.service); then
      systemctl stop kodi.service
      sleep 10
	fi
  else
    whiptail --title "KODI" --msgbox "ERROR Installing \nRestart installer!" 10 60
    exit 0
  fi
}

canutils() {
  if is_installed "can-utils"; then
    echo ${BGreen}'Successfully'${NC}
  else
    echo ${BGreen}'Installing'${NC}
    apt install -y can-utils 2>/dev/null 1>/dev/null
    if [ "$?" = 0 ]; then
      echo ${BGreen}'Successfully'${NC}
    else
      whiptail --title "CAN-UTILS" --msgbox "ERROR Installing \nRestart installer!" 10 60
      exit 0
    fi
  fi
  if is_installed "can-utils"; then
    if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
      if ! grep -q "auto can0" /etc/network/interfaces; then
        cat <<'EOF' >> /etc/network/interfaces
auto can0
  iface can0 inet manual
  pre-up /sbin/ip link set can0 type can bitrate 100000
  up /sbin/ifconfig can0 up
  down /sbin/ifconfig can0 down
EOF
      fi
    else
      cat <<'EOF' > /etc/systemd/network/80-can.network
[Match]
Name=can0

[CAN]
BitRate=100K
EOF
      systemctl restart systemd-networkd && 
      systemctl enable systemd-networkd
    fi
  fi
}

pythoncan() {
  if is_installed "python-can"; then
    echo ${BGreen}'Successfully'${NC}
  else
    echo ${BGreen}'Installing'${NC}
    if grep -q 'VERSION="10 (buster)"' /etc/os-release; then
      apt install -y python-can 2>/dev/null 1>/dev/null
      if [ "$?" = 0 ]; then
        echo ${BGreen}'Successfully'${NC}
      else
        whiptail --title "PYTHON-CAN" --msgbox "ERROR Installing \nRestart installer!" 10 60
        exit 0
      fi
    else
      apt install -y python3-can 2>/dev/null 1>/dev/null
      if [ "$?" = 0 ]; then
        echo ${BGreen}'Successfully'${NC}
      else
        whiptail --title "PYTHON-CAN" --msgbox "ERROR Installing \nRestart installer!" 10 60
        exit 0
      fi
    fi
  fi
}

overlay() {
  if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
    if is_installed "overlayroot"; then
      echo ${BGreen}'Successfully'${NC}
    else
      echo ${BGreen}'Installing Overlay SD card'${NC}
      apt-get install -y overlayroot 2>/dev/null 1>/dev/null
      if [ "$?" = 0 ]; then
        echo ${BGreen}'Successfully'${NC}
      else
        whiptail --title "Overlay SD card" --msgbox "ERROR Installing \nRestart installer!" 10 60
        exit 0
      fi
    fi
  fi
}


bluetooth() {
  if is_installed "pulseaudio"; then
    echo ${BGreen}'Pulseaudio Successfully'${NC}
  else
    hostnamectl set-hostname --pretty "rns"
    apt install -y --no-install-recommends pulseaudio 2>/dev/null 1>/dev/null
    if [ $? -eq 0 ]; then
      echo ${BGreen}'Pulseaudio Successfully'${NC}
    else
      whiptail --title "PULSE AUDIO" --msgbox "ERROR Installing \nRestart installer!" 10 60
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
  fi
  if is_installed "bluez-tools"; then
    echo ${BGreen}'\\nBluez-Tools Successfully'${NC}
  else
    echo ${BGreen}'\\nInstalling Bluez-Tools'${NC}
    apt install -y --no-install-recommends bluez-tools 2>/dev/null 1>/dev/null
    if [ $? -eq 0 ]; then
      echo ${BGreen}'\\nSuccessfully'${NC}
    else
      whiptail --title "bluez-tools" --msgbox "ERROR Installing \nRestart installer!" 10 60
      exit 0
    fi
  fi
  if is_installed "pulseaudio-module-bluetooth"; then
    echo ${BGreen}'\\nPulseaudio-Module-Bluetooth Successfully'${NC}
  else
    echo ${BGreen}'\\nInstalling Pulseaudio-Module-Bluetooth'${NC}
    apt install -y --no-install-recommends pulseaudio-module-bluetooth 2>/dev/null 1>/dev/null
    if [ ! $? -eq 0 ]; then
      whiptail --title "pulseaudio-module-bluetooth" --msgbox "ERROR Installing \nRestart installer!" 10 60
      exit 0
    fi
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
  if ! grep -q 'defaults.ctl.card 0' /etc/asound.conf; then
    cat <<'EOF' > /etc/asound.conf
defaults.ctl.card 0
defaults.ctl.card 0
EOF
  fi
}

skin_download() {
  if ! [ -e /tmp/$SKIN$Ver.zip ] ; then
    echo ${BGreen}'DOWNLOADING' $SKIN$Ver${NC}
    wget -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/kodi20/$SKIN/$SKIN$Ver.zip > /dev/null 2>&1
	unzip -o /tmp/$SKIN$Ver.zip -d $KODI > /dev/null 2>&1
  fi

  if ! [ -e /tmp/$REPOSITORY.zip ] ; then
    echo ${BGreen}'\\nDOWNLOADING' $REPOSITORY.zip${NC}
    wget -P /tmp https://github.com/maltsevvv/repository-kodi/raw/master/$REPOSITORY.zip > /dev/null 2>&1
	unzip -o /tmp/$REPOSITORY.zip -d $KODI > /dev/null 2>&1
  fi
}


kodi_set() {
  if ! grep -q $SKIN /usr/share/kodi/system/addon-manifest.xml; then
    echo ${BGreen}$SKIN '\\nto addon-manifest.xml'${NC}
    sed -i -e '$i \  <addon optional="true">'$SKIN'</addon>' /usr/share/kodi/system/addon-manifest.xml
  fi
  if ! grep -q $REPOSITORY /usr/share/kodi/system/addon-manifest.xml; then
    echo ${BGreen}$REPOSITORY '\\nto addon-manifest.xml'${NC}
    sed -i -e '$i \  <addon optional="true">'$REPOSITORY'</addon>' /usr/share/kodi/system/addon-manifest.xml
  fi
  if ! grep -q $SKIN  /home/pi/.kodi/userdata/guisettings.xml; then
    echo ${BGreen}$SKIN '\\nto guisettings.xml'${NC}
    sed -i -e 's/lookandfeel.skin" default="true">'$BaseSkin'/lookandfeel.skin">'$SKIN'/' /home/pi/.kodi/userdata/guisettings.xml
  fi


  echo ${BGreen}'Presettings KODI'${NC}
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
  sed -i 's/default="true">screensaver.xbmc.builtin.dim<\/setting/\//' /home/pi/.kodi/userdata/guisettings.xml
# Enable auto play next video
  sed -i 's/id="videoplayer.autoplaynextitem" default="true" \/>id="videoplayer.autoplaynextitem">0,1,2,3,4<\/setting>/' /home/pi/.kodi/userdata/guisettings.xml

# Amplifi volume up to 30.0dB
  sed -i 's/volumeamplification>0.000000/volumeamplification>30.000000/' /home/pi/.kodi/userdata/guisettings.xml

# Enable web-server
  sed -i 's/id="services.webserverauthentication" default="true">true/id="services.webserverauthentication">false/' /home/pi/.kodi/userdata/guisettings.xml
  sed -i 's/id="services.webserver" default="true">false/id="services.webserver">true/' /home/pi/.kodi/userdata/guisettings.xml
}

folder() {
  echo ${BGreen}'Media Folder: '${NC}
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
  chown -R pi:pi /home/pi/
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


rpi_conf() {
  if ! [ -e $CONFIG'_original.txt' ] ; then
    cp $CONFIG $CONFIG'_original.txt'
  fi
  if ! [ -e $CMDLINE'_original.txt' ] ; then
    cp $CMDLINE $CMDLINE'_original.txt'
  fi
}



rpi_vga() {
  echo $(rpi_conf)
  if grep -q 'VERSION="12 (bookworm)"' /etc/os-release; then
    sed -i -r 's/.+(console=serial0)/\1/' $CMDLINE  # Del Analog Video
    sed -i -r 's/(.+) vc4.tv_norm.+/\1/' $CMDLINE  # Del Analog Video
    if grep -q 'Raspberry Pi 4\|Raspberry Pi 5' $ModelPI; then
      if ! [ -e /usr/lib/firmware/Rpi480i_EDID.bin ] ; then
        echo ${BGreen}'Downloads Rpi480i'${NC}
        wget -P /usr/lib/firmware/ https://github.com/maltsevvv/repository-kodi/raw/refs/heads/master/old_install/Rpi480i_EDID.bin && > /dev/null 2>&1
      fi
      if ! [ -e /usr/lib/firmware/Rpi240p_EDID_EDID.bin ] ; then
        echo ${BGreen}'Downloads Rpi240p'${NC}
        wget -P /usr/lib/firmware/ https://github.com/maltsevvv/repository-kodi/raw/refs/heads/master/old_install/Rpi240p_EDID.bin && > /dev/null 2>&1
      fi	  
      if ! grep -q 'video=HDMI-A-1:NTSC' $CMDLINE; then
        sed -i 's/^/video=HDMI-A-1:NTSC,margin_left=39,margin_right=21,margin_top=17,margin_bottom=27 /' $CMDLINE  #rnse
      fi
      if ! grep -q 'Rpi480i_EDID.bin' $CMDLINE; then
        sed -i 's/$/ drm.edid_firmware=HDMI-A-1:Rpi480i_EDID.bin/' $CMDLINE
		#sed -i 's/$/ drm.edid_firmware=HDMI-A-1:Rpi240p_EDID.bin/' $CMDLINE 
      fi
      if ! grep -q 'hdmi_timings=' $CONFIG; then                         # Add For HDMI
        sed -i '/disable_overscan=1/a\hdmi_timings=640 0 16 88 64 480 0 6 5 13 0 0 0 60 1 12700000 3' $CONFIG # Add load serial For HDMI
      fi
    fi
    if ! grep -q 'hdmi_mode=87' $CONFIG; then                         # Add For HDMI
      sed -i '/disable_overscan=1/a\hdmi_mode=87' $CONFIG             # Add load serial For HDMI
    fi
    if ! grep -q 'hdmi_group=2' $CONFIG; then                         # Add For HDMI
      sed -i '/disable_overscan=1/a\hdmi_group=2' $CONFIG             # Add load serial For HDMI
    fi

  fi
  sed -i 's/^#\?#disable_overscan=1/disable_overscan=1/' $CONFIG     # Edit For HDMI
  sed -i 's/^#\?hdmi_force_hotplug=1/hdmi_force_hotplug=1/' $CONFIG  # Edit For HDMI
  sed -i 's/^#\?hdmi_group=.*/hdmi_group=2/' $CONFIG                 # Edit For HDMI
  sed -i 's/^#\?hdmi_mode=.*/hdmi_mode=87/' $CONFIG                  # Edit For HDMI
  sed -i 's/^#\?enable_tvout=.*/#enable_tvout=1/' $CONFIG            # Del Analog Video
  sed -i -r 's/(.+),composite/\1/' $CONFIG                           # Del Analog Video
  if ! grep -q 'hdmi_timings=' $CONFIG; then                         # Add For HDMI
    #if grep -q 'Raspberry Pi 4\|Raspberry Pi 5' $ModelPI; then
    sed -i '/hdmi_mode=/a\hdmi_timings=640 0 16 88 64 480 0 6 5 13 0 0 0 60 1 12700000 3' $CONFIG
    # sed -i '/hdmi_mode=/a\hdmi_timings=800 0 51 44 121 460 0 10 9 14 0 0 0 32 1 16000000 3' $CONFIG
    #fi
  fi
}

rpi_composite() {
  echo $(rpi_conf)
  sed -i 's/^#\?disable_overscan=1/#disable_overscan=1/' $CONFIG        # Edit For Analog
  sed -i 's/^#\?hdmi_force_hotplug=1/#hdmi_force_hotplug=1/' $CONFIG    # Edit For Analog
  sed -i 's/^#\?hdmi_group=.*/#hdmi_group=1/' $CONFIG                   # Edit For Analog
  sed -i 's/^#\?hdmi_mode=.*/#hdmi_mode=1/' $CONFIG                     # Edit For Analog
  sed -i "/.*hdmi_timings=.*/d" $CONFIG                                 # Del HDMI
  sed -i -r 's/.+(console=serial0)/\1/' $CMDLINE                        # Del HDMI
  sed -i -r 's/(.+) drm.edid.+/\1/' $CMDLINE                            # Del HDMI
  if grep -q 'VERSION="12 (bookworm)"' /etc/os-release; then
    if ! grep -q 'Composite-1' $CMDLINE; then
      sed -i "s/^/video=Composite-1:720x576@50ie /" $CMDLINE
                 #video=Composite-1:720x480@60ie
    fi
    if ! grep -q 'vc4.tv_norm=' $CMDLINE; then
      sed -i "s/$/ vc4.tv_norm=PAL/" $CMDLINE
                  #vc4.tv_norm=NTSC
    fi
    sed -i 's/^#\?dtoverlay=vc4-kms-v3d.*/dtoverlay=vc4-kms-v3d,composite/' $CONFIG
    if ! grep -q 'enable_tvout' $CMDLINE; then
      sed -i '/dtoverlay=vc4-kms-v3d/a\enable_tvout=1' $CONFIG
    fi
  fi
}

rpi_audio() {
  echo $(rpi_conf)
  sed -i 's/^#\?dtparam=audio=on/dtparam=audio=on/' $CONFIG
  sed -i "/.*hifiberry-dac.*/d" $CONFIG
}

rpi_pcm() {
  echo $(rpi_conf)
  sed -i 's/^#\?dtparam=audio=on/#dtparam=audio=on/' $CONFIG
  if ! grep -q 'hifiberry-dac' $CONFIG; then
    sed -i '/dtparam=audio/a\dtoverlay=hifiberry-dac' $CONFIG
  fi
}

rpi_can0() {
  echo $(rpi_conf)
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


rpi_ir() {
  apt purge lirc > /dev/null 2>&1
  rm -r /etc/lirc > /dev/null 2>&1
  if is_installed "ir-keytable"; then
    echo ${BGreen}'\\nSuccessfully'${NC}
  else
    echo ${BGreen}'Installing ir-keytable'${NC}
    apt install -y ir-keytable > /dev/null 2>&1
    if [ ! $? -eq 0 ]; then
      whiptail --title "IR-Keytable" --msgbox "ERROR Installing \nRestart installer!" 10 60
      exit 0
    fi
  fi
  if [ -e /etc/rc_keymaps/nec_rnsjp3.toml ] ; then
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










echo '---------------------------------------------------------'
echo ${BBlue}'Internet connection'${NC}
echo $(network)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo ${BBlue}'Update Packets'${NC}
echo $(update)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
if (whiptail --title "FULL UPGRADE SYSTEM" --yesno "Installation is Recommended.\nBut it will take a long time" 10 60); then
  echo ${BBlue}'Upgrade System'${NC}
  echo $(upgrade)
else
  echo ${BRed}'YOU CANCELED UPGRADE SYSTEM'${NC}
fi
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo ${BBlue}'SAMBA Installed'${NC}
echo $(samba)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo ${BBlue}'Installed KODI'${NC}
echo $(kodi)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo ${BBlue}'Installed CAN-UTILS'${NC}
echo $(canutils)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo ${BBlue}'Installed PYTHON-CAN'${NC}
echo $(pythoncan)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo ${BBlue}'Installed Overlay SD card'${NC}
echo $(overlay)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
if (whiptail --title "Bluetooth audio receiver installer" --yesno "Install Bluetooth Audio Receive." 10 60) then
  echo ${BBlue}'Installing BLUETOOTHE RECIEVER'${NC}
  echo $(bluetooth)
else
  echo ${BRed}'YOU CANCELED THE INSTALLATION BLUETOOTH RECIEVER'${NC}
fi
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo $(kodi_status)
echo $(skin_download)
echo $(kodi_set)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo $(folder)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
if (whiptail --title "Video Output" --yes-button " HDMI-VGA " --no-button " ANALOG VIDEO " --yesno "Select video output source" 10 60); then
  echo ${BGreen}"Use HDMI-VGA Adapter For Video Output"${NC}
  echo $(rpi_vga)
else
  echo ${BGreen}"Use Analog Video Output Jack 3,5mm"${NC}
  $(rpi_composite)
  echo ${BRed}$CMDLINE${NC} '\nvc4.tv_norm='${BBlue}'PAL'${NC} ${BBlue}'\nNTSC'${NC} '|' ${BBlue}'PAL\n'${NC}
  echo ${BRed}$CMDLINE${NC} '\nvideo=Composite-1:'${BBlue}'720x576@50ie'${NC} ${BBlue}'\n720x576@50ie'${NC} 'for' ${BGreen}'PAL'${NC} ${BBlue}'\n720x480@60ie'${NC} 'for' ${BGreen}'NTSC\n'${NC}
fi
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
if (whiptail --title "AUDIO Output" --yes-button " PCM5102 " --no-button " ANALOG " --yesno "Select Audio output source" 10 60); then
  echo ${BGreen}'Use Digital (PCM5102) Audio Output Jack 3,5mm'${NC}
  echo $(rpi_pcm)
else
  echo ${BGreen}'Use Analog Audio Output Jack 3,5mm'${NC}
  echo $(rpi_audio)
fi
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo ${BGreen}'Enable mcp2515-can0'${NC}
echo $(rpi_can0)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo ${BGreen}'Installed IR-Keytable'${NC}
if (whiptail --title "IR Remote Control" --yesno "Enable IR-Receiver? \nfor Control Kodi, FOR RNS-JP3 \nWARNING!!!! ONLY FOR RNS-JP3 (Asian)" 10 60); then
  echo $(rpi_ir)
  sed -i 's/^#\?dtoverlay=gpio-ir,gpio_pin=17/dtoverlay=gpio-ir,gpio_pin=17/' $CONFIG
  if ! grep -q 'dtoverlay=gpio-ir' $CONFIG; then
    cat <<'EOF' >> $CONFIG

dtoverlay=gpio-ir,gpio_pin=17
EOF
  fi
else
  sed -i 's/^#\?dtoverlay=gpio-ir,gpio_pin=17/#dtoverlay=gpio-ir,gpio_pin=17/' $CONFIG
fi
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo '\\\\'$(hostname -I | awk '{print $1}')'\\''rns'
echo '\\\\'$(hostname -I | awk '{print $2}')'\\''rns'
echo '---------------------------------------------------------'

chown -R pi:pi /home/pi/

echo '---------------------------------------------------------'
if (whiptail --title "Installation Completed" --yesno "Reboot System Now\nIf everything is fine, then after the reboot \nyou will see a window for entering the activation code" 10 60); then
  echo "Reboot System"

  reboot
fi
echo '---------------------------------------------------------'
