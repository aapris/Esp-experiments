-- file : application.lua
local module = {}  
m = nil
temp = 0
humi = 0
data = {}
data["protocol"] = '1.0.2'
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
        data["dht22_temp"] = temp
        data["dht22_humi"] = hum
        -- print("dht22_temp" .. temp)
        -- print("dht22_humi" .. humi)
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
    data["dht22_temp"] = dht_data["dht22_temp"]
    data["dht22_humi"] = dht_data["dht22_humi"]
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
local function send_buttonpress(direction)
    data["rssi"] = wifi.sta.getrssi()
    data["uptime"] = tmr.time()
    data["node_heap"] = node.heap() -- Returns the current available heap size in bytes.
    if direction == nil then
        direction = "button_press"
    end

    data["event"] = direction
    local ok, msg = pcall(cjson.encode, data)
    print(msg)
    data["rssi"] = nil
    data["uptime"] = nil
    data["event"] = nil
    -- this should be really event endpoint or something
    m:publish(config.ENDPOINT .. "event",msg,0,0)
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
buttonPin = 6 -- this is D6 in NodeMCU dev board
local debounceDelay = 50
local debounceAlarmId = 1
gpio.mode(buttonPin,gpio.INT,gpio.PULLUP)

function buttonPressed()
    -- don't react to any interupts from now on and wait 50ms until the interrupt for the up event is enabled
    -- within that 50ms the switch may bounce to its heart's content
    gpio.trig(buttonPin, "none")
    tmr.alarm(debounceAlarmId, debounceDelay, tmr.ALARM_SINGLE, function()
        gpio.trig(buttonPin, "up", buttonReleased)
    end)
    -- finally react to the down event
    print("Button pressed")
    send_buttonpress("close_"..buttonPin)
end

function buttonReleased()
    -- don't react to any interupts from now on and wait 50ms until the interrupt for the down event is enabled
    -- within that 50ms the switch may bounce to its heart's content
    gpio.trig(buttonPin, "none")
    tmr.alarm(debounceAlarmId, debounceDelay, tmr.ALARM_SINGLE, function()
        gpio.trig(buttonPin, "down", buttonPressed)
    end)
    -- finally react to the up event
    print("Button released")
    send_buttonpress("open_"..buttonPin)
end


function module.start()
  gpio.trig(buttonPin, "down", buttonPressed)
  print("mqtt_start()")
  mqtt_start()
end

return module
