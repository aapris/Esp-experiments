# ESP8266 NodeMCU experiments

This repository contains various ESP8266 experiments.

# NOTE to databusiness.fi event (2016-09-14) participants:

You can find the visualization from here:
https://github.com/terotic/databusiness-iot

If you want to use your Sensor Box (tm) you won, you need to know some programming.
To get started:
https://www.google.fi/#q=getting+started+esp8266

## Mac Os setup

* Install drivers
* Reboot
* Find serial port

## Get firmware
nodemcu-build.com

Don't include everything, there is not enough memory in ESP8266.

## Update firmware
```bash
export PORT=/dev/cu.wchusbserial1410
esptool.py -p ${PORT} write_flash 0x00000 firmware/nodemcu-master-17-modules-2016-07-10-07-51-53-float.bin 0x3fc000 firmware/esp_init_data_default.bin
./luatool/luatool/luatool.py --port ${PORT} --src scripts/ping-http.lua --dest init.lua --verbose --baud 115200
```

## Esp Easy firmware

```bash
export PORT=/dev/cu.wchusbserial1410

#esptool.py -p ${PORT} write_flash 0x00000 ~/Downloads/ESPEasy_R147_RC8/ESPEasy_R147_4096.bin 

# This might flash Wemos D1 Mini Pro?
esptool.py -p ${PORT} write_flash -ff 80m -fm qio -fs 4m 0x00000 ~/Downloads/ESPEasy_R147_RC8/ESPEasy_R147_512.bin  0x7c000  firmware/esp_init_data_default.bin

```

Remove power cable and plug it back. Then follow configuration instructions here:
http://www.letscontrolit.com/wiki/index.php/ESPEasy#Configuration

## MQTT

Lightweight protocol for IoT devices.

### Mosquitto

Install and run the server.

Subscribe to all topics From command line:

`mosquitto_sub -h 192.168.0.40 -p 1883 -v -t '#' -u esp -P passwrd`


