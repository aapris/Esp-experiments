# How to upload this stuff to ESP8266/NodeMCU unit

## In this directory
```
export PORT=/dev/cu.wchusbserial1410 # or find the right one
../../luatool/luatool/luatool.py --compile --port ${PORT} --src config_your_current_config.lua --dest config.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --compile --port ${PORT} --src application.lua --dest application.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --compile --port ${PORT} --src setup.lua --dest setup.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --compile --port ${PORT} --src ../dht/dht22.lua --dest dht22.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --compile --port ${PORT} --src ../ds18b20/ds18b20.lua --dest ds18b20.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --port ${PORT} --src init.lua --dest t.lua --verbose --baud 115200
```

## Test script
```
dofile('t.lua');
```

## Finally upload init.lua
```
../../luatool/luatool/luatool.py --port ${PORT} --src init.lua --dest init.lua --verbose --baud 115200
```
