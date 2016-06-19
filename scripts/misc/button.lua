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
        print("That was easy! ")
        -- dofile("ifttt.lua") 
        tmr.delay(500000)
    end
end

gpio.trig(buttonPin,"down", debounce(onChange))

