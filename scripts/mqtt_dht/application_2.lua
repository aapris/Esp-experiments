-- file : application.lua
dallas = require("ds18b20")
sda = 5 -- SDA Pin
scl = 6 -- SCL Pin

SYS_PROTOCOL = '1.0.3'
SYS_MAC = wifi.sta.getmac()
SYS_CHIPID = node.chipid()
SYS_LOCATION = 'Suutarila'
PIN_DHT22 = 1   -- this is D1 in NodeMCU dev board
PIN_DS = 2      -- this is D2 in NodeMCU dev board
PIN_BUTTON = 6  -- this is D6 in NodeMCU dev board
PIN_MOTION = 7  -- this is D7 in NodeMCU dev board

local module = {}  
m = nil
temp = 0
humi = 0
data = {}
data["protocol"] = SYS_PROTOCOL
data["mac"] = wifi.sta.getmac()
data["chipid"] = node.chipid()


-- to recover from cjson memory alloc issues?
-- node.egc.setmode(node.egc.ON_ALLOC_FAILURE)


function init_OLED(sda, scl) --Set up the u8glib lib
     local sla = 0x3C
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     disp:setFont(u8g.font_8x13B)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
     --disp:setRot180()           -- Rotate Display if needed
end

function print_OLED(str1, str2, str3, str4)
   disp:firstPage()
   repeat
     -- disp:drawFrame(2,2,126,62)
     disp:drawStr(0, 0, str1)
     disp:drawStr(0, 15, str2)
     disp:drawStr(0, 30, str3)
     disp:drawStr(0, 45, str4)
     -- disp:drawCircle(18, 47, 14)
   until disp:nextPage() == false
end


str1="School"
str2="IoT"
str3="Box"
str4="Suutarila"

function print_hb()
  print_OLED(str1, str2, str3, str4)
end


local function get_system_info(data)
    -- Hardcoded values
    data["protocol"] = SYS_PROTOCOL
    data["mac"] = SYS_MAC
    data["chipid"] = SYS_CHIPID
    data["ssid"] = config.WIFI_SSID
    -- System info
    data["rssi"] = wifi.sta.getrssi()
    data["uptime"] = tmr.time()
    data["node_heap"] = node.heap() -- Current available heap size in bytes.
    -- Send boot reason for first 100 seconds
    if data["uptime"] < 100 then
        local _, bootreason = node.bootreason()
        data["bootreason"] = bootreason
    end
    -- Send this on first pub?
    -- majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
end

-- Sends a simple ping to the broker
local function send_ping()  
    m:publish(config.ENDPOINT .. "ping","id=" .. config.ID,0,0)
end

local function read_dht22(pin, data)
--    local data = {}
    local status,temp,hum,temp_decimial,humi_decimial = dht.read(pin)
    data["status"] = status
    if( status == dht.OK ) then
        data["dht22_temp"] = temp
        data["dht22_humi"] = hum
    elseif( status == dht.ERROR_CHECKSUM ) then
        print( "DHT Checksum error" )
    elseif( status == dht.ERROR_TIMEOUT ) then
        print( "DHT Time out" )
    end
    return data
end

-- Send DHT22 temp + hum and Dallas temperatures
local function send_sensordata()
    local data = {}
    get_system_info(data)
    -- Sensors
    -- DHT22
    read_dht22(PIN_DHT22, data) -- read the only DHT22
    -- Dallas 18b20
    local ds_data = dallas.read_all(PIN_DS)  -- read all 18b20 sensors
    local ds_temp = 0
    for key,value in pairs(ds_data) do
        data[key] = value
        ds_temp = value
    end

    print_OLED("Temp: "..ds_temp.."'C",
               "Temp: "..data["dht22_temp"].."'C",
               "Humi: "..data["dht22_humi"].."%",
               SYS_LOCATION)
    local ok, msg = pcall(cjson.encode, data)
    print(msg)
    m:publish(config.ENDPOINT .. "sensor",msg,0,0)
end

-- Send button press
local function send_buttonpress(direction)
    local data = {}
    get_system_info(data)
    if direction == nil then
        direction = "button_press"
    end

    data["event"] = direction
    local ok, msg = pcall(cjson.encode, data)
    print(msg)
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
        gpio.trig(PIN_MOTION, "up", motion_on)
        send_ping()
        send_sensordata()
        -- And then pings each 10 000 milliseconds
        tmr.stop(6)
        tmr.alarm(6, config.PING_INTERVAL, 1, send_ping)
        -- And then temps each 30 000 milliseconds
        tmr.stop(5)
        tmr.alarm(5, config.SENSOR_INTERVAL, 1, send_sensordata)
--        tmr.stop(4)
--        tmr.alarm(4, 11000, 1, print_hb)
    end)
end

--button.lua
local debounceDelay = 50
local debounceAlarmId = 1
--gpio.mode(PIN_BUTTON,gpio.INT,gpio.PULLUP)

function buttonPressed()
    -- don't react to any interupts from now on and wait 50ms until the interrupt for the up event is enabled
    -- within that 50ms the switch may bounce to its heart's content
    gpio.trig(PIN_BUTTON, "none")
    tmr.alarm(debounceAlarmId, debounceDelay, tmr.ALARM_SINGLE, function()
        gpio.trig(PIN_BUTTON, "up", buttonReleased)
    end)
    -- finally react to the down event
    print("Button pressed")
    send_buttonpress("close_".. PIN_BUTTON)
end

function buttonReleased()
    -- don't react to any interupts from now on and wait 50ms until the interrupt for the down event is enabled
    -- within that 50ms the switch may bounce to its heart's content
    gpio.trig(PIN_BUTTON, "none")
    tmr.alarm(debounceAlarmId, debounceDelay, tmr.ALARM_SINGLE, function()
        gpio.trig(PIN_BUTTON, "down", buttonPressed)
    end)
    -- finally react to the up event
    print("Button released")
    send_buttonpress("open_".. PIN_BUTTON)
end

-- PIR sensor
gpio.mode(PIN_MOTION,gpio.INT,gpio.PULLDOWN)  -- attach interrupt to inpin

function motion_on()
    print(tmr.time() .. " Motion Detected!")
    gpio.trig(PIN_MOTION, "down", motion_off)
    send_buttonpress("motion_on_".. PIN_MOTION)
    print_OLED("MOTION",
               "DETECTED!",
               "",
               SYS_LOCATION)

end

function motion_off()
    print(tmr.time() .. " Motion OFF!")
    gpio.trig(PIN_MOTION, "up", motion_on)
    send_buttonpress("motion_off_".. PIN_MOTION)
end

function module.start()
--  gpio.trig(PIN_BUTTON, "down", buttonPressed)
--  gpio.trig(PIN_MOTION, "up", motion_on)
  print("mqtt_start()")
  init_OLED(sda,scl)
  print_hb()
  mqtt_start()
end

return module
