assert = require("luassert")

local Timer = nil
local DEFAULTS = {
    name = "test-timer",
    interval = 30,
    message = "This is a test message.",
    enabled = true,
    level = vim.log.levels.INFO,
    cb = function() end,
}

local function create_timer(params)
    params = vim.tbl_deep_extend("force", DEFAULTS, params or {})
    return Timer(params.name, params.interval, params.message, params.enabled, params.level, params.cb)
end

describe("PulseTimer", function()
    Timer = require("pulse._timer")

    it("can be created", function()
        local timer = create_timer()
        assert.is_not.Nil(timer)
    end)

    it("has a property 'name'", function()
        local timer = create_timer()
        assert.equal(DEFAULTS.name, timer.name)
    end)

    it("has a property 'message'", function()
        local timer = create_timer()
        assert.equal(DEFAULTS.message, timer.message)
    end)
end)

describe("PulseTimer.enabled()", function()
    it("returns timer state", function()
        local timer_e = create_timer({ enabled = true })
        local timer_d = create_timer({ enabled = false })
        assert.is_true(timer_e.enabled())
        assert.is_false(timer_d.enabled())
    end)
end)

describe("PulseTimer.enable()", function()
    it("enables the timer when it's disabled", function()
        local timer = create_timer({ enabled = false })
        assert.is_false(timer.enabled())
        assert.is_true(timer.enable())
        assert.is_true(timer.enabled())
    end)

    it("does nothing when the timer is enabled", function()
        local timer = create_timer({ enabled = true })
        assert.is_true(timer.enabled())
        assert.is_false(timer.enable())
        assert.is_true(timer.enabled())
    end)
end)

describe("PulseTimer.disable()", function()
    it("disables the timer when it's enabled", function()
        local timer = create_timer({ enabled = true })
        assert.is_true(timer.enabled())
        assert.is_true(timer.disable())
        assert.is_false(timer.enabled())
    end)

    it("does nothing when the timer is disabled", function()
        local timer = create_timer({ enabled = false })
        assert.is_false(timer.enabled())
        assert.is_false(timer.disable())
        assert.is_false(timer.enabled())
    end)
end)

describe("PulseTimer.toggle()", function()
    it("toggles the timer's enabled state", function()
        local timer_e = create_timer({ enabled = true })
        local timer_d = create_timer({ enabled = false })

        timer_e.toggle()
        assert.is_false(timer_e.enabled())

        timer_d.toggle()
        assert.is_true(timer_d.enabled())
    end)

    it("returns the timer's enabled state", function()
        local timer_e = create_timer({ enabled = true })
        local timer_d = create_timer({ enabled = false })
        assert.is_false(timer_e.toggle())
        assert.is_true(timer_d.toggle())
    end)
end)

describe("PulseTimer.remaining()", function()
    it("returns the correct remaining time when it is under 1 hour", function()
        local timer = create_timer({ interval = 3 })
        local hours, minutes = timer.remaining()
        assert.equal(3, minutes)
        assert.equal(0, hours)
    end)

    it("returns the correct remaining time when it is over 1 hour", function()
        local timer = create_timer({ interval = 69 })
        local hours, minutes = timer.remaining()
        assert.equal(9, minutes)
        assert.equal(1, hours)
    end)
end)

describe("PulseTimer.change_interval()", function()
    it("changes the timer's repeat interval", function()
        local timer = create_timer()

        local new_interval = 5
        timer.change_interval(new_interval)
        assert.equal(new_interval * 60000, timer._timer:get_repeat())
    end)

    it("does not affect the timer's current remaining time", function()
        local timer = create_timer()
        timer.change_interval(5)
        local hours, minutes = timer.remaining()
        assert.equal(0, hours)
        assert.equal(30, minutes)
    end)
end)

describe("PulseTimer.teardown()", function()
    it("disables the timer", function()
        local timer = create_timer()
        timer.teardown()
        assert.is_false(timer.enabled())
    end)

    it("deletes the internal timer", function()
        local timer = create_timer()
        timer.teardown()
        assert.equal(nil, timer._timer)
    end)
end)
