# ESP8266 NodeMCU experiments

This repository contains various ESP8266 experiments.

## Mac Os setup

* Install drivers
* Reboot
* Find serial port

## Get firmware
nodemcu-build.com

Don't include everything, there is not enough memory in ESP8266.

## Update firmware
```bash
PORT=/dev/cu.wchusbserial1420
esptool.py -p ${PORT} write_flash 0x00000 firmware/nodemcu-dev-11-modules-2016-05-22-11-07-57-integer.bin 0x3fc000 firmware/esp_init_data_default.bin
./luatool/luatool/luatool.py --port ${PORT} --src scripts/ping-http.lua --dest init.lua --verbose --baud 115200
```

## MQTT

Lightweight protocol for IoT devices.

### Mosquitto

Install and run the server.

Subscribe to all topics From command line:

`mosquitto_sub -h 192.168.0.40 -p 1883 -v -t '#' -u esp -P passwrd`


