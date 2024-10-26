[![OS - Buster](https://img.shields.io/badge/OS-Buster_(Kodi_18)-blue?logo=linux&logoColor=white)](https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/2020-02-13-raspbian-buster-lite.zip "Downloads Buster")

## Скрипт для автоматической установки  

    wget -P /tmp https://raw.githubusercontent.com/maltsevvv/repository-kodi/master/autoinstall.sh
    sudo sh /tmp/autoinstall.sh


## Raspberry Pi Audio Receiver

Через телефон передаем аудио на Raspberry, а затем звук выводится на аудио систему.

### Requirements

- Использовать USB-адаптер Bluetooth (внутренний чипсет Raspberry Pi Bluetooth оказался неподходящим для воспроизведения звука и вызывает всевозможные странные проблемы с подключением)

- Адаптер USB – Bluetooth V5.0

**Еще раз: не пытайтесь использовать внутренний чип Bluetooth.**

### Добавить устройства Bluetooth

Устройство должно быть доступно для новых подключений Bluetooth, но в некоторых случаях вам может потребоваться выполнить сопряжение вручную:

    sudo bluetoothctl

    scan on

    connect 00:00:00:00:00:00

    trust 00:00:00:00:00:00

 `Заменить 00:00:00:00:00:00 на MAC Вашего телефона`
### Вы используете USB Bluetooth модуль. Необходимо проверить определился ли он в OS.

    hciconfig

`hci0:   Type: Primary  Bus: USB`  
`        BD Address: 00:1A:7D:DA:71:13  ACL MTU: 679:8  SCO MTU: 48:16`  
`        DOWN` `Bluetooth не работает. Можно, попробовать обновить ядро Linux.`  
`        RX bytes:706 acl:0 sco:0 events:22 errors:0`  
`        TX bytes:68 acl:0 sco:0 commands:22 errors:0`  

    sudo rpi-update

    sudo reboot

### Проверяем статyс USB Bluetooth модуля.

    hciconfig

`hci0:   Type: Primary  Bus: USB`  
`        BD Address: 00:1A:7D:DA:71:13  ACL MTU: 679:8  SCO MTU: 48:16`  
`        UP RUNNING PSCAN ISCAN` `Все хорошо, работает.`  
`        RX bytes:706 acl:0 sco:0 events:22 errors:0`  
`        TX bytes:68 acl:0 sco:0 commands:22 errors:0`  

### Отключить встроенный BT в raspberry pi  

    sudo nano /boot/config.txt

`dtoverlay=disable-bt`

    sudo reboot


## Подключается, но нет звука

Проверить номер идентификатора аудио карты

    cat /proc/asound/cards

`0 [b1             ]: bcm2835_hdmi - bcm2835 HDMI 1`  
`1 [Headphones     ]: bcm2835_headpho - bcm2835 Headphones`  
`2 [sndrpihifiberry]: RPi-simple - snd_rpi_hifiberry_dac`

    sudo nano /etc/asound.conf

`defaults.pcm.card 0` `заменить цифру, на номер Вашей карты`  
`defaults.ctl.card 0` `заменить цифру, на номер Вашей карты`  

### change image on load system. ONLY BUSTER


    wget -P /tmp https://raw.githubusercontent.com/maltsevvv/maltsev-Kodi-Repo/master/splash/splash.sh
    sudo sh /tmp/splash.sh
