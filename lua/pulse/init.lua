local Timer = require("pulse._timer")

--- @class TimerOpts
--- @field interval integer | nil The timer interval in milliseconds
--- @field message string | nil The timer message which will be displayed when the timer ends
--- @field level number | nil The vim.log.levels level to use for the notification callbacks
--- @field enabled boolean | nil True if the timer should start on creation, false otherwise
--- @field one_shot boolean | nil True if the timer should destroy itself on completion
--- @field cb fun(timer: Timer) | nil The callback to be executed when the timer expires

--- Returns a string formatted as 'HH:MM'
--- @param minutes integer The minutes.
--- @param hours integer The hours.
--- @return string time The time formatted as 'HH:MM'
local function timer_format(hours, minutes) return string.format("%02d:%02d", hours, minutes) end

local M = {}

--- @type Timer[]
M._timers = {}

--- @class Options
--- @field level number The log level of the notifications timers produce when they go off.

--- Initializes the pulse.nvim plugin
--- @param opts Options | nil The configuration options for pulse.nvim
--- @return nil
M.setup = function(opts)
    --- @type Options
    M.config = vim.tbl_deep_extend("force", {
        level = vim.log.levels.INFO,
    }, opts or {})

    -- User commands for interacting with the pulse module
    vim.api.nvim_create_user_command("PulseEnable", function(args)
        for _, timer in ipairs(args.fargs) do
            local success = M.enable(timer)
            if success then
                vim.print("Timer '" .. timer .. "' enabled.")
                goto continue
            end

            if not success and not M._timers[timer] then
                vim.print("Timer '" .. timer .. "' does not exist.")
                goto continue
            end
            vim.print("Timer '" .. timer .. "' is already enabled.")
            ::continue::
        end
    end, {
        nargs = "+",
        desc = "Enables the timers with the matching name.",
        complete = function(_, _, _)
            local timer_names = {}
            for k, v in pairs(M._timers) do
                if not v.enabled() then table.insert(timer_names, k) end
            end
            return timer_names
        end,
    })

    vim.api.nvim_create_user_command("PulseDisable", function(args)
        for _, timer in ipairs(args.fargs) do
            local success = M.disable(timer)

            if success then
                vim.print("Timer '" .. timer .. "' disabled.")
                goto continue
            end

            if not success and not M._timers[timer] then
                vim.print("Timer '" .. timer .. "' does not exist.")
                goto continue
            end
            vim.print("Timer '" .. timer .. "' is already disabled.")
            ::continue::
        end
    end, {
        nargs = "+",
        desc = "Disables the timers with the matching name.",
        complete = function(_, _, _)
            local timer_names = {}
            for k, v in pairs(M._timers) do
                if v.enabled() then table.insert(timer_names, k) end
            end
            return timer_names
        end,
    })

    vim.api.nvim_create_user_command("PulseStatus", function(args)
        local r_hours, r_minutes = M.status(args.args)
        if r_hours == -1 then
            vim.print("No timer named '" .. args.args .. "'.")
            return
        end
        vim.print(timer_format(r_hours, r_minutes) .. " remaining on '" .. args.args .. "' timer.")
    end, {
        nargs = 1,
        desc = "Prints the remaining time left on the specified timer.",
        complete = function(_, _, _)
            local timer_names = {}
            for k, _ in pairs(M._timers) do
                table.insert(timer_names, k)
            end
            return timer_names
        end,
    })

    vim.api.nvim_create_user_command("PulseSetTimer", function(args)
        local arguments = vim.split(args.args, " ")
        if #arguments ~= 2 then error("PulseSetTimer takes 2 arguments.") end

        if M.add(arguments[1], { interval = tonumber(arguments[2]), one_shot = true }) then
            vim.print("Timer " .. arguments[1] .. " created.")
        else
            vim.print("Timer " .. arguments[1] .. " already exists.")
        end
    end, { nargs = "+", desc = "Set a single-use timer." })

    -- Command to view all timers (otherwise telescope picker)
    local has_telescope, _ = pcall(require, "telescope")

    if has_telescope then
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local config = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local entry_display = require("telescope.pickers.entry_display")
        M.pick_timers = function(options)
            options = options or {}

            local displayer = entry_display.create({
                separator = " ",
                items = {
                    { remaining = true },
                    { width = 5 },
                },
            })

            local make_display = function(entry)
                local hl = "TelescopeResultsComment"
                local time_hl = "TelescopeResultsComment"
                if entry.value[2] then
                    hl = "TelescopeResultsIdentifier"
                    time_hl = "TelescopeResultsNormal"
                end
                return displayer({
                    { entry.value[1], hl },
                    { string.format("%02d:%02d", entry.value[3], entry.value[4]), time_hl },
                })
            end

            local timer_results = {}
            for name, _ in pairs(M._timers) do
                table.insert(timer_results, { name, M._timers[name].enabled(), M._timers[name].remaining() })
            end

            pickers
                .new(options, {
                    prompt_title = "Pulses",
                    finder = finders.new_table({
                        results = timer_results,
                        entry_maker = function(entry)
                            return {
                                value = entry,
                                display = make_display,
                                ordinal = entry[3],
                            }
                        end,
                    }),
                    sorter = config.generic_sorter(options),
                    attach_mappings = function(prompt_bufnr, _)
                        actions.select_default:replace(function()
                            actions.close(prompt_bufnr)
                            local selection = action_state.get_selected_entry()
                            M._timers[selection.value[1]].toggle()
                        end)
                        return true
                    end,
                })
                :find()
        end
    end

    vim.api.nvim_create_user_command("PulseList", M.pick_timers, { desc = "Displays a list of all the added timers." })
end

--- Adds a timer to the listing.
--- @param name string The timer name
--- @param opts TimerOpts | nil The options for creating the timer (otherwise default opts will be used)
--- @return boolean success False if a timer with the same name exists, true otherwise
M.add = function(name, opts)
    -- Detect duplicate names
    if M._timers[name] then return false end

    -- Merge options with default options
    opts = vim.tbl_deep_extend("force", {
        interval = 30,
        enabled = true,
        message = name .. " went off!",
        one_shot = false,
        level = M.config.level,
        cb = function(timer)
		  require("notify")(timer.message, timer._level, {Title = "NotifyTitle"})
		  -- vim.notify(timer.message, timer._level, {Title = "Notification Title"})
		  end,
	  -- vim.api.nvim_notify(timer.message, timer._level, {}) end,
    }, opts or {})

    -- Set up one-shot callback
    if opts.one_shot then
        local stored_cb = opts.cb
        --- @param timer Timer
        opts.cb = function(timer)
            if stored_cb then stored_cb(timer) end -- Call user cb
            timer.teardown()
            M._timers[timer.name] = nil
        end
    end

    M._timers[name] = Timer(name, opts.interval, opts.message, opts.enabled, opts.level, opts.cb)
    return true
end

--- Removes a timer from the listing.
--- @param timer string The timer name
--- @return boolean success True if the timer was removed, false if the timer did not exist
M.remove = function(timer)
    local obj = M._timers[timer]
    if not obj then
        return false
    else
        obj.teardown()
        M._timers[timer] = nil
        return true
    end
end

--- Enables a timer in the listing
--- @param timer string The timer name
--- @return boolean success True if the timer was enabled successfully.
M.enable = function(timer)
    local timer_obj = M._timers[timer]
    if not timer_obj then return false end
    return timer_obj.enable()
end

--- Disables a timer in the listing
--- @param timer string The timer name
--- @return boolean success True if the timer was disabled successfully.
M.disable = function(timer)
    local timer_obj = M._timers[timer]
    if not timer_obj then return false end
    return timer_obj.disable()
end

--- Gets the remaining time of a given timer (if no such timer, returns (-1, -1))
--- @param timer string The timer name
--- @return integer minutes_remaining The odd minutes left before the timer ends
--- @return integer hours_remaining The hours - minutes left before the timer ends
M.status = function(timer)
    local timer_obj = M._timers[timer]
    if timer_obj then return timer_obj.remaining() end
    return -1, -1
end

--- Displays a list of timers
--- @return nil
M.pick_timers = function(_)
    local function enabled(name)
        if M._timers[name].enabled() then
            return "enabled"
        else
            return "disabled"
        end
    end
    for name, _ in pairs(M._timers) do
        vim.print(name .. " - " .. enabled(name) .. " - " .. timer_format(M._timers[name].remaining()))
    end
end

return M
