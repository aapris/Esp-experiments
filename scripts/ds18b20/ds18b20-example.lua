DS_PIN = 2 -- 2 == D2 in NodeMCU

function read_ds18b20()
    local t = require("ds18b20")
    local data = {}
    local ds_data = t.read_all(DS_PIN)  -- read all 18b20 sensors
    for key,value in pairs(ds_data) do
        data[key] = value
        print(key..": "..value.." 'C")
    end
    return data
end

tmr.stop(0)
tmr.alarm(0, 10*300, 1, read_ds18b20)
