-- file : application.lua
local module = {}  
m = nil
temp = 0
humi = 0
data = {}
data["protocol"] = '1.0'
data["mac"] = wifi.sta.getmac()
data["chipid"] = node.chipid()

-- to recover from cjson memory alloc issues?
-- node.egc.setmode(node.egc.ON_ALLOC_FAILURE)

-- Sends a simple ping to the broker
local function send_ping()  
    m:publish(config.ENDPOINT .. "ping","id=" .. config.ID,0,0)
end

local function read_dht22(pin)
    local data = {}
    local status,temp,hum,temp_decimial,humi_decimial = dht.read(pin)
    data["status"] = status
    if( status == dht.OK ) then
        data["temp"] = temp
        data["humi"] = hum
    elseif( status == dht.ERROR_CHECKSUM ) then
        print( "DHT Checksum error" )
    elseif( status == dht.ERROR_TIMEOUT ) then
        print( "DHT Time out" )
    end
    return data
end

function read_ds18b20(pin)
    local t = require("ds18b20")
    t.setup(pin)
    local addrs = t.addrs()
    local data = {}
    if (addrs ~= nil) then
      print("Total DS18B20 sensors: "..table.getn(addrs))
    end

    for i=1,table.getn(addrs) do
        local addr = addrs[i]
        local s = string.format("DS%02x-%02x%02x%02x%02x%02x%02x%02x",
            addr:byte(1),addr:byte(2),addr:byte(3),addr:byte(4),
            addr:byte(5),addr:byte(6),addr:byte(7),addr:byte(8))
        local temp = t.read(addrs[i],t.C)
        print("Sensor ("..s.."): "..temp.."'C")
        data[s] = temp
    end
    -- Release modile after use
    t = nil
    package.loaded["ds18b20"]=nil
    return data
end


-- Send DHT22 temp + hum and Dallas temperatures
local function send_sensordata()
    local dht_data = read_dht22(1) -- read the only DHT22
    data["temp"] = dht_data["temp"]
    data["humi"] = dht_data["humi"]
    local ds_data = read_ds18b20(2)  -- read all 18b20 sensors
    for key,value in pairs(ds_data) do
        data[key] = value
    end
    data["rssi"] = wifi.sta.getrssi()
    data["uptime"] = tmr.time()
    -- Send boot reason for first 100 seconds
    if data["uptime"] < 100 then
        local _, bootreason = node.bootreason()
        data["bootreason"] = bootreason
    else
        data["bootreason"] = nil
    end
    -- Send this rarely?
    data["node_heap"] = node.heap() -- Returns the current available heap size in bytes.
    -- Send this on first pub?
    -- node.info()
    local ok, msg = pcall(cjson.encode, data)
    print(msg)
    -- remove sensor keys from global data variable
    data["temp"] = nil
    data["humi"] = nil
    data["rssi"] = nil
    data["uptime"] = nil
    for key,value in pairs(ds_data) do
        data[key] = nil
    end
    m:publish(config.ENDPOINT .. "sensor",msg,0,0)
end


-- Send button press
local function send_buttonpress()
    data["rssi"] = wifi.sta.getrssi()
    data["uptime"] = tmr.time()
    data["node_heap"] = node.heap() -- Returns the current available heap size in bytes.
    data["event"] = "button_press"
    local ok, msg = pcall(cjson.encode, data)
    print(msg)
    data["rssi"] = nil
    data["uptime"] = nil
    data["event"] = nil
    -- this should be really event endpoint or something
    m:publish(config.ENDPOINT .. "sensor",msg,0,0)
end


-- Sends my id to the broker for registration
local function register_myself()  
    m:subscribe(config.ENDPOINT .. config.ID,0,function(conn)
        print("Successfully subscribed to data endpoint")
    end)
end

local function mqtt_start()  
    m = mqtt.Client(config.ID, 120, config.USER, config.PASSWORD)
    data["ssid"] = config.WIFI_SSID
    -- register message callback beforehand
    m:on("message", function(conn, topic, data) 
      if data ~= nil then
        print(topic .. ": " .. data)
        -- do something, we have received a message
      end
    end)
    -- Connect to broker
    m:connect(config.HOST, config.PORT, 0, 1, function(con) 
        register_myself()
        send_ping()
        send_sensordata()
        -- And then pings each 10 000 milliseconds
        tmr.stop(6)
        tmr.alarm(6, config.PING_INTERVAL, 1, send_ping)
        -- And then temps each 30 000 milliseconds
        tmr.stop(5)
        tmr.alarm(5, config.SENSOR_INTERVAL, 1, send_sensordata)
    end)
end

--button.lua
buttonPin = 4 -- this is ESP-01 pin GPIO02 and D4 in NodeMCU dev board
gpio.mode(buttonPin,gpio.INT,gpio.PULLUP)

function debounce (func)
    local last = 0
    local delay = 200000

    return function (...)
        local now = tmr.now()
        if now - last < delay then return end

        last = now
        return func(...)
    end
end

function onChange()
    if gpio.read(buttonPin) == 0 then
        print("Button pressed!")
        send_buttonpress()
        tmr.delay(500000)
    end
end


function module.start()
  gpio.trig(buttonPin,"down", debounce(onChange))
  print("mqtt_start()")
  mqtt_start()
end

return module
