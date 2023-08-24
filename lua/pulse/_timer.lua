--- @class VimTimer
--- @field start function
--- @field stop function
--- @field again function
--- @field get_due_in function
--- @field set_repeat function
--- @field get_repeat function

--- @class Timer
--- @field name string The name used to refer to this timer
--- @field message string The timer message which will be displayed when the timer ends
--- @field _enabled boolean Whether the timer is enabled or not
--- @field _timer VimTimer The vim timer which is used to keep this timer going
--- @field _timer_cb function The callback function which is executed when the timer ends
--- @field __index Timer The vim timer which is used to keep this timer going
--- @field enable fun(): nil Enables the timer
--- @field disable fun(): nil Disables the timer
--- @field change_interval fun(interval: integer): nil Changes the timer interval
--- @field remaining fun(): integer Returns the remaining time in minutes
--- @field teardown fun(): nil Tears down the timer
--- @field enabled fun(): boolean Returns the state of the timer (enabled/disabled)
--- @field toggle fun(): boolean Toggles the timer to be enabled or disabled depending on its current state

--- Creates a new timer with the specified name, minute interval and timer message.
--- @param name string The name used to refer to this timer
--- @param interval integer The timer interval in minutes
--- @param message string The timer message which will be displayed when the timer ends
--- @param level string | nil The log level of the notification produced when the timer ends
--- @return Timer
function Timer(name, interval, message, level)
    local self = {}
    self.name = name
    self.message = message
    self._level = level or vim.log.levels.INFO
    self._enabled = true
    self._timer = vim.loop.new_timer()
    self._timer_cb = function() vim.api.nvim_notify(self.message, self._level, {}) end

    self._timer:start(interval * 60000, interval * 60000, vim.schedule_wrap(self._timer_cb))

    --- Returns the state of the timer (enabled/disabled).
    --- @return boolean
    self.enabled = function() return self._enabled end

    --- Enables the timer.
    --- @return nil
    self.enable = function()
        if self._enabled then
            vim.print("Timer " .. self.name .. " already enabled.")
            return
        end
        self._timer:again()
        self._enabled = true
        vim.print("Timer " .. self.name .. "enabled.")
    end

    --- Disables the timer.
    --- @return nil
    self.disable = function()
        if not self._enabled then
            vim.print("Timer " .. self.name .. " already disabled.")
            return
        end
        self._timer:stop()
        self._enabled = false
        vim.print("Timer " .. self.name .. " disabled.")
    end

    --- Toggles the timer to be enabled or disabled depending on its current state
    --- @return boolean enabled The timer's current state (true for enabled, false for disabled).
    self.toggle = function()
        if self._enabled then
            self.disable()
            return self._enabled
        end
        self.enable()
        return self._enabled
    end

    --- Changes the timer interval. Applies to next timer iteration.
    --- @param intvl integer The new interval in minutes
    --- @return nil
    self.change_interval = function(intvl) self._timer:set_repeat(intvl * 60000) end

    --- Gets the remaining time left on the timer in minutes
    --- @return integer time_remaining The remaining time in minutes before the timer ends
    self.remaining = function() return math.ceil(self._timer:get_repeat() / 60000) end

    --- Prepares the timer for deletion
    --- @return nil
    self.teardown = function()
        self._timer:stop()
        self._timer = nil
        self._enabled = false
    end
    return self
end
