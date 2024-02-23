### Скрипт для автоматической установки  
#### Full Auto Install script  
```
wget -P /tmp https://raw.githubusercontent.com/maltsevvv/repository-kodi/master/autoinstall.sh
sudo sh /tmp/autoinstall.sh
```

### change image on load system. ONLY BUSTER
```
wget -P /tmp https://raw.githubusercontent.com/maltsevvv/maltsev-Kodi-Repo/master/splash/splash.sh
sudo sh /tmp/splash.sh
```

## USB Bluetoothe модуль V5 for Buster
#### Прверяем определила ли система на BT модуль.  
```
hciconfig
```
`hci0:   Type: Primary  Bus: USB`  
`        BD Address: 00:1A:7D:DA:71:13  ACL MTU: 679:8  SCO MTU: 48:16`  
`  если  DOWN` `значит не работает. Необходимо обновить ядро.`  
`        RX bytes:706 acl:0 sco:0 events:22 errors:0`  
`        TX bytes:68 acl:0 sco:0 commands:22 errors:0`  

```
uname -a
```
`Linux rns 4.19.97-v7+`

```
sudo apt update -y
sudo rpi-update

sudo reboot
```
#### Проверяем статкс USB BT адаптера.
```
hciconfig
```
`hci0:   Type: Primary  Bus: USB`  
`        BD Address: 00:1A:7D:DA:71:13  ACL MTU: 679:8  SCO MTU: 48:16`  
`  видим UP` `Работает, и к нему можно подключиться.`  
`        RX bytes:706 acl:0 sco:0 events:22 errors:0`  
`        TX bytes:68 acl:0 sco:0 commands:22 errors:0`  

#### Отключить встроенный BT в raspberry pi  
```
sudo nano /boot/config.txt
```
`dtoverlay=disable-bt`
```
sudo reboot
```

sudo bluetoothctl

pair mac

sudo bluetoothctl
