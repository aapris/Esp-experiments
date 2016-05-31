
```
esptool.py -p /dev/cu.wchusbserial1420 write_flash 0x00000 firmware/nodemcu-dev-11-modules-2016-05-22-11-07-57-integer.bin 0x3fc000 firmware/esp_init_data_default.bin

./luatool/luatool/luatool.py --port /dev/cu.wchusbserial1420 --src scripts/ping-http.lua --dest init.lua --verbose --baud 115200


```

