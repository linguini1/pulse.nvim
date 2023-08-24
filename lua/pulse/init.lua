require("pulse._timer")
local M = {}

--- @type Timer[]
M._timers = {}

--- @class TimerData
--- @field name string The name used to refer to this timer
--- @field message string The timer message which will be displayed when the timer ends
--- @field interval integer The timer interval in milliseconds

--- Initializes the pulse.nvim plugin
--- @param timers TimerData[] An array of timer data which will be used to set up the timers
--- @return nil
M.setup = function(timers)
    -- Initialize timers
    for _, timer_data in ipairs(timers) do
        M.add(timer_data)
    end

    -- User commands for interacting with the pulse module
    vim.api.nvim_create_user_command("PulseEnable", function(args)
        local timer = M._timers[args.args]
        if not timer then
            vim.print("No timer named '" .. args.args .. "'.")
            return
        end
        timer.enable()
    end, { nargs = 1, desc = "Enables the timer with the matching name." })

    vim.api.nvim_create_user_command("PulseDisable", function(args)
        local timer = M._timers[args.args]
        if not timer then
            vim.print("No timer named '" .. args.args .. "'.")
            return
        end
        timer.disable()
    end, { nargs = 1, desc = "Disables the timer with the matching name." })

    vim.api.nvim_create_user_command("PulseStatus", function(args)
        local timer = M._timers[args.args]
        if not timer then
            vim.print("No timer named '" .. args.args .. "'.")
            return
        end
        local remaining = timer.remaining()
        local plural = ""
        if remaining > 1 then plural = "s" end
        vim.print(remaining .. " minute" .. plural .. " remaining on '" .. timer.name .. "' timer.")
    end, { nargs = 1, desc = "Prints the remaining time left on the specified timer." })

    -- Command to view all timers (otherwise telescope picker)
    local has_telescope, _ = pcall(require, "telescope")

    --- Displays a list of timers
    --- @return nil
    local pick_timers = function()
        local function enabled(name)
            if M._timers[name]._enabled then
                return "enabled"
            else
                return "disabled"
            end
        end
        for name, _ in pairs(M._timers) do
            vim.print(name .. ": " .. enabled(name))
        end
    end

    if has_telescope then
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local config = require("telescope.config").values
        pick_timers = function(opts)
            local function enabled(name)
                if M._timers[name]._enabled then
                    return "ff0000"
                else
                    return "00ff00"
                end
            end

            local timer_results = {}
            for name, _ in pairs(M._timers) do
                table.insert(timer_results, name)
            end

            opts = opts or {}
            pickers
                .new(opts, {
                    prompt_title = "Pulses",
                    finder = finders.new_table({
                        results = timer_results,
                    }),
                    entry_make = function(entry)
                        return {
                            value = entry,
                            display = entry[1],
                            ordinal = entry[1],
                        }
                    end,
                    sorter = config.generic_sorter(opts),
                })
                :find()
        end
    end

    vim.api.nvim_create_user_command("PulseList", pick_timers, { desc = "Displays a list of all the added timers." })
end

--- Adds a timer to the listing.
--- @param timer TimerData
--- @return nil
M.add = function(timer) M._timers[timer.name] = Timer(timer.name, timer.interval, timer.message) end

--- Removes a timer from the listing.
--- @param timer string The timer name
--- @return nil
M.remove = function(timer)
    local timer_obj = M._timers[timer]
    if timer then
        timer_obj.teardown()
        M._timers[timer] = nil
    else
        vim.notify("Timer " .. timer .. "does not exist.", vim.log.levels.ERROR, {})
    end
end

M.setup({
    { name = "rest", interval = 45, message = "Rest your eyes!" },
    { name = "drink", interval = 15, message = "Drink water!" },
})

return M
