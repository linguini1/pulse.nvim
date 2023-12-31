--- @class VimTimer
--- @field start function
--- @field stop function
--- @field again function
--- @field close function
--- @field get_due_in function
--- @field set_repeat function
--- @field get_repeat function

--- Returns the hours and minutes from just minutes.
--- @param minutes integer The minutes to be converted.
--- @return integer hours The hours.
--- @return integer minutes The minutes.
local function hh_mm(minutes) return math.floor(minutes / 60), minutes % 60 end

--- @class Timer
--- @field name string The name used to refer to this timer
--- @field message string The timer message which will be displayed when the timer ends
--- @field _enabled boolean Whether the timer is enabled or not
--- @field _level number The log level of the notification produced when the timer ends
--- @field _timer VimTimer The vim timer which is used to keep this timer going
--- @field _timer_cb function The callback function which is executed when the timer ends
--- @field __index Timer The vim timer which is used to keep this timer going
--- @field enabled fun(): boolean Returns the state of the timer (enabled/disabled)
--- @field enable fun(): boolean Enables the timer
--- @field disable fun(): boolean Disables the timer
--- @field change_interval fun(interval: integer): nil Changes the timer interval
--- @field remaining fun(): integer, integer Returns the remaining time in hours & minutes
--- @field teardown fun(): nil Tears down the timer
--- @field toggle fun(): boolean Toggles the timer to be enabled or disabled depending on its current state

--- Creates a new timer with the specified name, minute interval and timer message.
--- @param name string The name used to refer to this timer
--- @param interval integer The timer interval in minutes
--- @param message string The timer message which will be displayed when the timer ends
--- @param enabled boolean True if the timer should start on creation, false otherwise
--- @param level number The log level of the notification produced when the timer ends
--- @param cb fun(timer: Timer) | nil The callback executed when the timer expires. If nil, uses a default notification
--- @return Timer
local function Timer(name, interval, message, enabled, level, cb)
    local self = {}
    self.name = name
    self.message = message
    self._level = level
    self._enabled = true
    self._timer = vim.loop.new_timer()
    self._timer_cb = cb

    self._timer:start(interval * 60000, interval * 60000, vim.schedule_wrap(function() self._timer_cb(self) end))

    --- Fetches the timer's current enabled state
    --- @return boolean state True if the timer is enabled, false otherwise
    self.enabled = function() return self._enabled end

    --- Enables the timer
    --- @return boolean success True if the timer was enabled successfully
    self.enable = function()
        if self._enabled then return false end
        self._timer:again()
        self._enabled = true
        return true
    end

    --- Disables the timer
    --- @return boolean success True if the timer was disabled successfully
    self.disable = function()
        if not self._enabled then return false end
        self._timer:stop()
        self._enabled = false
        return true
    end

    --- Toggle the timer on or off depending on current state
    --- @return boolean enabled The enabled status of the timer
    self.toggle = function()
        if self._enabled then
            self.disable()
            return self._enabled
        end
        self.enable()
        return self._enabled
    end

    --- Change the timer interval to a new value
    --- @param intvl integer The new interval in minutes
    self.change_interval = function(intvl) self._timer:set_repeat(intvl * 60000) end

    --- Get the remaining time until the timer expires in minutes, hours
    --- @return integer minutes_remaining The odd minutes left before the timer ends
    --- @return integer hours_remaining The hours - minutes left before the timer ends
    self.remaining = function()
        local minutes = math.ceil(self._timer:get_due_in() / 60000)
        return hh_mm(minutes)
    end

    --- Teardown the timer
    --- @return nil
    self.teardown = function()
        self._timer:close()
        self._timer = nil
        self._enabled = false
    end

    if not enabled then self.disable() end -- Start disabled
    return self
end

return Timer
