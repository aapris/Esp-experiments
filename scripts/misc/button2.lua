-- inspired by: http://www.esp8266-projects.com/2015/03/buttons-pushbuttons-and-debouncing-story.html

--buttonPin = 4 -- this is ESP-01 pin GPIO02 and D4 in NodeMCU dev board
buttonPin = 6 -- this is ESP-01 pin GPIO02 and D4 in NodeMCU dev board
local debounceDelay = 50
local debounceAlarmId = 1
gpio.mode(buttonPin, gpio.INT, gpio.PULLUP)

function buttonPressed()
    -- don't react to any interupts from now on and wait 50ms until the interrupt for the up event is enabled
    -- within that 50ms the switch may bounce to its heart's content
    gpio.trig(buttonPin, "none")
    tmr.alarm(debounceAlarmId, debounceDelay, tmr.ALARM_SINGLE, function()
        gpio.trig(buttonPin, "up", buttonReleased)
    end)
    -- finally react to the down event
    print("Button press")
end

function buttonReleased()
    -- don't react to any interupts from now on and wait 50ms until the interrupt for the down event is enabled
    -- within that 50ms the switch may bounce to its heart's content
    gpio.trig(buttonPin, "none")
    tmr.alarm(debounceAlarmId, debounceDelay, tmr.ALARM_SINGLE, function()
        gpio.trig(buttonPin, "down", buttonPressed)
    end)
    -- finally react to the up event
    print("Button release")
end

gpio.trig(buttonPin, "down", buttonPressed)
print("Started. Now press the button")
