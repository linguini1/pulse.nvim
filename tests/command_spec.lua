assert = require("luassert")

local function unload_pulse() package.loaded["pulse"] = nil end
local last_printed = nil
local function disable_vimprint()
    vim.print = function(str) last_printed = str end
end
local function disable_notify()
    vim.notify = function() end
end

describe("PulseEnable", function()
    before_each(function()
        unload_pulse()
        disable_vimprint()
    end)

    it("enables a disabled timer", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "disabled-timer"
        assert.is_true(pulse.add(timer_name, {
            interval = 10,
            enabled = false,
        }))

        assert.is_false(pulse._timers[timer_name].enabled())
        vim.cmd("PulseEnable " .. timer_name)
        assert.is_true(pulse._timers[timer_name].enabled())
    end)

    it("does not affect an enabled timer", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "enabled-timer"
        assert.is_true(pulse.add(timer_name, {
            interval = 10,
            enabled = true,
        }))

        assert.is_true(pulse._timers[timer_name].enabled())
        vim.cmd("PulseEnable " .. timer_name)
        assert.is_true(pulse._timers[timer_name].enabled())
    end)

    it("gracefully fails when the timer does not exist", function()
        require("pulse").setup()
        vim.cmd("PulseEnable dne-timer")
    end)

    it("enables multiple timers", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_names = { "disabled-timer", "disabled-timer-2", "disabled-timer-3" }
        for _, timer_name in ipairs(timer_names) do
            assert.is_true(pulse.add(timer_name, {
                interval = 10,
                enabled = false,
            }))
        end

        for _, timer_name in ipairs(timer_names) do
            assert.is_false(pulse._timers[timer_name].enabled())
        end
        vim.cmd("PulseEnable " .. table.concat(timer_names, " "))
        for _, timer_name in ipairs(timer_names) do
            assert.is_true(pulse._timers[timer_name].enabled())
        end
    end)

    it("enables some timers even if one is already enabled", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_settings = {
            { name = "disabled-timer", enabled = false },
            { name = "enabled-timer", enabled = true },
            { name = "disabled-timer-2", enabled = false },
        }
        for _, timer in ipairs(timer_settings) do
            assert.is_true(pulse.add(timer.name, {
                interval = 10,
                enabled = timer.enabled,
            }))
        end

        for _, timer in ipairs(timer_settings) do
            assert.equal(timer.enabled, pulse._timers[timer.name].enabled())
        end

        vim.cmd("PulseEnable " .. table.concat(vim.tbl_map(function(timer) return timer.name end, timer_settings), " "))

        for _, timer in ipairs(timer_settings) do
            assert.is_true(pulse._timers[timer.name].enabled())
        end
    end)

    it("enables some timers even if one does not exist", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_settings = {
            { name = "disabled-timer", enabled = false, dne = false },
            { name = "disabled-timer-2", enabled = false, dne = false },
            { name = "dne-timer", enabled = false, dne = true },
        }
        for _, timer in ipairs(timer_settings) do
            if not timer.dne then -- Only add timers that should exist
                assert.is_true(pulse.add(timer.name, {
                    interval = 10,
                    enabled = timer.enabled,
                }))
            end
        end

        for _, timer in ipairs(timer_settings) do
            if not timer.dne then
                assert.equal(timer.enabled, pulse._timers[timer.name].enabled())
            else
                assert.equal(nil, pulse._timers[timer.name])
            end
        end

        vim.cmd("PulseEnable " .. table.concat(vim.tbl_map(function(timer) return timer.name end, timer_settings), " "))

        for _, timer in ipairs(timer_settings) do
            if not timer.dne then
                assert.is_true(pulse._timers[timer.name].enabled())
            else
                assert.equal(nil, pulse._timers[timer.name])
            end
        end
    end)
end)

describe("PulseDisable", function()
    before_each(function()
        unload_pulse()
        disable_vimprint()
    end)

    it("disables an enabled timer", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "enabled_timer"
        assert.is_true(pulse.add(timer_name, {
            interval = 10,
            enabled = true,
        }))

        assert.is_true(pulse._timers[timer_name].enabled())
        vim.cmd("PulseDisable " .. timer_name)
        assert.is_false(pulse._timers[timer_name].enabled())
    end)

    it("does not affect a disabled timer", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "disabled-timer"
        assert.is_true(pulse.add(timer_name, {
            interval = 10,
            enabled = false,
        }))

        assert.is_false(pulse._timers[timer_name].enabled())
        vim.cmd("PulseDisable " .. timer_name)
        assert.is_false(pulse._timers[timer_name].enabled())
    end)

    it("gracefully fails when the timer does not exist", function()
        require("pulse").setup()
        vim.cmd("PulseDisable dne-timer")
    end)

    it("disables multiple timers", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_names = { "enabled-timer", "enabled-timer-2", "enabled-timer-3" }
        for _, timer_name in ipairs(timer_names) do
            assert.is_true(pulse.add(timer_name, {
                interval = 10,
                enabled = true,
            }))
        end

        for _, timer_name in ipairs(timer_names) do
            assert.is_true(pulse._timers[timer_name].enabled())
        end
        vim.cmd("PulseDisable " .. table.concat(timer_names, " "))
        for _, timer_name in ipairs(timer_names) do
            assert.is_false(pulse._timers[timer_name].enabled())
        end
    end)

    it("disables some timers even if one is already disabled", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_settings = {
            { name = "enabled-timer", enabled = true },
            { name = "disabled-timer", enabled = false },
            { name = "enabled-timer-2", enabled = true },
        }
        for _, timer in ipairs(timer_settings) do
            assert.is_true(pulse.add(timer.name, {
                interval = 10,
                enabled = timer.enabled,
            }))
        end

        for _, timer in ipairs(timer_settings) do
            assert.equal(timer.enabled, pulse._timers[timer.name].enabled())
        end

        vim.cmd(
            "PulseDisable " .. table.concat(vim.tbl_map(function(timer) return timer.name end, timer_settings), " ")
        )

        for _, timer in ipairs(timer_settings) do
            assert.is_false(pulse._timers[timer.name].enabled())
        end
    end)

    it("disables some timers even if one does not exist", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_settings = {
            { name = "enabled-timer", enabled = true, dne = false },
            { name = "enabled-timer-2", enabled = true, dne = false },
            { name = "dne-timer", enabled = false, dne = true },
        }
        for _, timer in ipairs(timer_settings) do
            if not timer.dne then -- Only add timers that should exist
                assert.is_true(pulse.add(timer.name, {
                    interval = 10,
                    enabled = timer.enabled,
                }))
            end
        end

        for _, timer in ipairs(timer_settings) do
            if not timer.dne then
                assert.equal(timer.enabled, pulse._timers[timer.name].enabled())
            else
                assert.equal(nil, pulse._timers[timer.name])
            end
        end

        vim.cmd(
            "PulseDisable " .. table.concat(vim.tbl_map(function(timer) return timer.name end, timer_settings), " ")
        )

        for _, timer in ipairs(timer_settings) do
            if not timer.dne then
                assert.is_false(pulse._timers[timer.name].enabled())
            else
                assert.equal(nil, pulse._timers[timer.name])
            end
        end
    end)
end)

describe("PulseStatus", function()
    local timer_format = "%d%d:%d%d"

    before_each(function()
        unload_pulse()
        disable_vimprint()
    end)

    it("returns the correct time when it is under 1 hour", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "short-timer"
        assert.is_true(pulse.add(timer_name, {
            interval = 10,
            enabled = false,
        }))

        vim.cmd("PulseStatus " .. timer_name)
        assert.equal("00:10", string.match(last_printed, timer_format))
    end)

    it("returns the correct time when it is over 1 hour", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "long-timer"
        assert.is_true(pulse.add(timer_name, {
            interval = 69,
            enabled = false,
        }))

        vim.cmd("PulseStatus " .. timer_name)
        assert.equal("01:09", string.match(last_printed, timer_format))
    end)

    it("fails gracefully when the timer does not exist", function()
        local pulse = require("pulse")
        pulse.setup()
        vim.cmd("PulseStatus dne-timer")
    end)
end)

describe("PulseSetTimer", function()
    before_each(function()
        unload_pulse()
        disable_vimprint()
        disable_notify()
    end)

    it("creates a single use timer", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "temp-timer"
        vim.cmd("PulseSetTimer " .. timer_name .. " 1")
        assert.is_not.Nil(pulse._timers[timer_name])
        pulse._timers[timer_name]._timer_cb(pulse._timers[timer_name])
        assert.equal(nil, pulse._timers[timer_name])
    end)

    it("fails to create a second timer with the same name", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "temp-timer"
        assert.is_true(pulse.add(timer_name, {
            interval = 10,
            enabled = false,
        }))
        vim.cmd("PulseSetTimer " .. timer_name .. " 20")
        local hours, minutes = pulse._timers[timer_name].remaining()
        assert.equal(0, hours)
        assert.equal(10, minutes)
    end)

    it("fails when given less than 2 arguments", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "test-timer"
        assert.is_false(pcall(vim.cmd, "PulseSetTimer " .. timer_name))
    end)

    it("fails when given more than 2 arguments", function()
        local pulse = require("pulse")
        pulse.setup()

        local timer_name = "test-timer"
        assert.is_false(pcall(vim.cmd, "PulseSetTimer " .. timer_name .. " 10 some-message"))
    end)
end)
