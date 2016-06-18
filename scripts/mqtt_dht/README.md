# How to upload this stuff to ESP8266/NodeMCU unit

## In this directory
```
../../luatool/luatool/luatool.py --port ${PORT} --src config_hima.lua --dest config.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --port ${PORT} --src application.lua --dest application.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --port ${PORT} --src setup.lua --dest setup.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --port ${PORT} --src ../dht/dht22.lua --dest dht22.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --port ${PORT} --src ../ds18b20/ds18b20.lua --dest ds18b20.lua --verbose --baud 115200
../../luatool/luatool/luatool.py --port ${PORT} --src init.lua --dest test.lua --verbose --baud 115200
```

## In nodemcu console
```
node.compile('config.lua');
node.compile('application.lua');
node.compile('setup.lua');
node.compile('dht22.lua');
node.compile('ds18b20.lua');
```

## Run script
```
dofile('test.lua');
```

## Finally upload init.lua
```
../../luatool/luatool/luatool.py --port ${PORT} --src init.lua --dest init.lua --verbose --baud 115200
```