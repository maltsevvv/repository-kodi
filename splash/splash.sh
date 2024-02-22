#!/bin/bash


# if ! grep -q "disable_splash=1" /boot/config.txt; then
  # cat <<'EOF' >> /boot/config.txt

# disable_splash=1
# EOF
# fi

sed -i 's/console=tty1/console=tty3/' /boot/cmdline.txt

apt install -y plymouth plymouth-themes
apt install -y pix-plym-splash
plymouth-set-default-theme pix

if [ -e /home/pi/splash.png ]; then
  echo "FIND YOU splash.png"
  rm /usr/share/plymouth/themes/pix/splash.png
  cp /home/pi/splash.png /usr/share/plymouth/themes/pix/
else
  echo "Download splash.png"
  rm /usr/share/plymouth/themes/pix/splash.png
  wget -P /usr/share/plymouth/themes/pix/ https://raw.githubusercontent.com/maltsevvv/maltsev-Kodi-Repo/master/splash/splash.png
fi

if (systemctl -q is-active kodi.service); then
  systemctl stop kodi.service
  sleep 10
elif (systemctl -q is-active kodi.service); then
  systemctl stop kodi.service
  sleep 10
exit 1
fi

# if [ ! -e /usr/share/kodi/media/original_splash.jpg ]; then
  # mv /usr/share/kodi/media/splash.jpg /usr/share/kodi/media/original_splash.jpg
# fi

# if [ -e /home/pi/splash.jpg ]; then
  # echo "FIND YOU splash.jpg"
  # rm /usr/share/kodi/media/splash.jpg
  # cp /home/pi/splash.jpg /usr/share/kodi/media/
# else
  # echo "Download splash.jpg"
  # rm /usr/share/kodi/media/splash.jpg
  # wget -P /usr/share/kodi/media/ https://raw.githubusercontent.com/maltsevvv/maltsev-Kodi-Repo/master/splash/splash.jpg
# fi

##############################################
#                SETTINGS KODI               #
##############################################
echo "---------------------------------------------------------"
echo "DISABLE SPLASH KODI"
echo "---------------------------------------------------------"
cat <<'EOF' > /home/pi/.kodi/userdata/advancedsettings.xml
	
<advancedsettings version="1.0">
    <splash>false</splash>
</advancedsettings>
EOF
chown pi:pi /home/pi/.kodi/userdata/advancedsettings.xml

reboot
