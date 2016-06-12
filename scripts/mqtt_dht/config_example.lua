-- file : config.lua
-- Copy this example file to a local name, e.g.
-- config_yourlocal.lua

local module = {}

module.SSID = {}
module.SSID["myWifi"] = "12345679ABCDEF"
module.HOST = "broker.example.com"  
module.PORT = 1883
module.ID = node.chipid()
module.USER = "esp"
module.PASSWORD = "node123"
module.ENDPOINT = "nodemcu/"
module.SENSOR_INTERVAL = 60000 -- milliseconds
module.PING_INTERVAL = 30000 -- milliseconds
return module
