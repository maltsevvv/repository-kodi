#!/bin/bash

BGreen="\033[1;32m"       # Green
BRed="\033[1;31m"       # Red
NC="\033[0m"              # No Color


echo $(update)
echo $(upgrade)

echo '---------------------------------------------------------'
echo $(samba)
echo $(samba_conf)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
echo $(kodi)
echo $(kodi_pvr)
echo $(kodi_conf)
echo $(kodi_status)
echo '---------------------------------------------------------'

echo '---------------------------------------------------------'
if ! grep -q 'VERSION="10 (buster)"' /etc/os-release; then
  echo $(usbmount)
  echo $(usbmount_update)
# echo $(usbmount_conf)
fi
echo '---------------------------------------------------------'


update() {
  apt update
  #apt -y upgrade
}

upgrade() {
  #apt update
  apt -y upgrade
}




is_installed() {
  dpkg --verify "$1" > /dev/null 2>&1
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
    apt-get install -y samba > /dev/null 2>&1
fi
}

samba_conf() {
  if ! grep -q "/home/pi/" /etc/samba/smb.conf; then
    echo ${BGreen}"Added confшп"${NC}
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
    echo ${BGreen}"Installing KODI"${NC}
    apt-get install -y kodi && > /dev/null 2>&1
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
  else
    echo ${BGreen}"Run KODI"${NC}
    systemctl enable kodi
    systemctl start kodi
  fi
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
  if [ "$version" = '0.0.25' ]; then
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



# if is_installed "usbmount"; then
    # echo "usbmount installed";
	# version="$(dpkg-query --showformat="\${Version}" --show usbmount 2>&1)"
	# echo $version
	# if [ "$Version" = 0.0.34 ]; then
	  # echo 'ok'
    # fi
# else
    # echo "usbmount not installed";
# fi


