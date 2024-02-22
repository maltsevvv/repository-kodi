Maltsev-Kodi-Repo  
### Full Auto Install script  
```
wget -P /tmp https://raw.githubusercontent.com/maltsevvv/maltsev-Kodi-Repo/master/autoinstall.sh
sudo sh /tmp/autoinstall.sh
```

### change image on load system. ONLY BUSTER
```
wget -P /tmp https://raw.githubusercontent.com/maltsevvv/maltsev-Kodi-Repo/master/splash/splash.sh
sudo sh /tmp/splash.sh
```

## USB Bluetoothe модуль V5 for Buster
```
hciconfig
```
```
hci0:   Type: Primary  Bus: USB
        BD Address: 00:1A:7D:DA:71:13  ACL MTU: 679:8  SCO MTU: 48:16
        DOWN
        RX bytes:706 acl:0 sco:0 events:22 errors:0
        TX bytes:68 acl:0 sco:0 commands:22 errors:0
```
```
uname -a
```
`Linux rns 4.19.97-v7+`

```
#sudo rmmod btusb
#sudo modprobe btusb
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y

sudo rpi-update

sudo reboot


sudo rpi-update
```
```
sudo nano /boot/config.txt
```
```
dtoverlay=disable-bt
```

sudo reboot

sudo bluetoothctl

pair mac

sudo bluetoothctl
