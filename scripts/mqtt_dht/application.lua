-- file : application.lua
local module = {}  
m = nil
temp = 0
humi = 0
data = {}
data["ssid"] = wifi_SSID
data["mac"] = wifi.sta.getmac()
data["chipid"] = node.chipid()

-- to recover from cjson memory alloc issues?
-- node.egc.setmode(node.egc.ON_ALLOC_FAILURE)

-- Sends a simple ping to the broker
local function send_ping()  
    m:publish(config.ENDPOINT .. "ping","id=" .. config.ID,0,0)
end

-- Sends temp + hum
local function send_sensordata()
    status,temp,humi,temp_decimial,humi_decimial = dht.read(2)
    if( status == dht.OK ) then
        print("temp: "..temp.." deg C")
        print("humi: "..humi.."%")
    elseif( status == dht.ERROR_CHECKSUM ) then
        print( "DHT Checksum error" )
        temp = -1000 --TEST
    elseif( status == dht.ERROR_TIMEOUT ) then
        print( "DHT Time out" )
        temp = -2000 --TEST
    end
    data["rssi"] = wifi.sta.getrssi()
    data["temp"] = temp
    data["humi"] = humi
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
    m:publish(config.ENDPOINT .. "sensor",msg,0,0)
end

-- Sends my id to the broker for registration
local function register_myself()  
    m:subscribe(config.ENDPOINT .. config.ID,0,function(conn)
        print("Successfully subscribed to data endpoint")
    end)
end

local function mqtt_start()  
    m = mqtt.Client(config.ID, 120)
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
        -- And then pings each 10 000 milliseconds
        tmr.stop(6)
        tmr.alarm(6, config.PING_INTERVAL, 1, send_ping)
        -- And then temps each 30 000 milliseconds
        tmr.stop(5)
        tmr.alarm(5, config.SENSOR_INTERVAL, 1, send_sensordata)
    end)
end


function module.start()
  print("mqtt_start()")
  mqtt_start()
end

return module

