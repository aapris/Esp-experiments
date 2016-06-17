DS_PIN = 2 -- 2 == D2 in NodeMCU

function read_ds18b20()
    local t = require("ds18b20")
    t.setup(DS_PIN)
    local addrs = t.addrs()
    local data = {}
    if (addrs ~= nil) then
      print("Total DS18B20 sensors: "..table.getn(addrs))
    end

    for i=1,table.getn(addrs) do
        local addr = addrs[i]
        local s = string.format("Addr:%02x%02x%02x%02x%02x%02x%02x%02x",
            addr:byte(1),addr:byte(2),addr:byte(3),addr:byte(4),
            addr:byte(5),addr:byte(6),addr:byte(7),addr:byte(8))
        local temp = t.read(addrs[i],t.C)
        print(s)
        print("Sensor ("..i.."): "..temp.."'C")
        data[s] = temp
    end
    -- Release modile after use
    t = nil
    package.loaded["ds18b20"]=nil
    return data
end

tmr.stop(0)
tmr.alarm(0, 10*1000, 1, read_ds18b20)
