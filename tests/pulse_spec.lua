assert = require("luassert")

describe("pulse", function()
    before_each(function() package.loaded["pulse"] = nil end) -- Unload pulse for each test

    it("can be required", function() assert.is_true(pcall(require, "pulse")) end)

    it("can be set up with default options", function()
        local pulse = require("pulse")
        pulse.setup()
    end)

    it("can be set up with notify level as WARN", function()
        local pulse = require("pulse")
        pulse.setup({ level = vim.log.levels.WARN })
        assert.is_equal(vim.log.levels.WARN, pulse.config.level)
    end)

    it("can have a timer added which is enabled", function()
        local pulse = require("pulse")
        pulse.setup()
        assert.is_true(pulse.add("test", {
            interval = 15,
            message = "This is a test timer!",
            enabled = true,
        }))
        assert.is.truthy(pulse._timers["test"])
        assert.is_true(pulse._timers["test"].enabled())
    end)

    it("can have a timer added which is disabled", function()
        local pulse = require("pulse")
        pulse.setup()
        assert.is_true(pulse.add("test", {
            interval = 15,
            message = "This is a test timer!",
            enabled = false,
        }))
        assert.is.truthy(pulse._timers["test"])
        assert.is_not_true(pulse._timers["test"].enabled())
    end)

    it("cannot have two timers with the same name added", function()
        local pulse = require("pulse")
        pulse.setup()
        assert.is_true(pulse.add("test", {
            interval = 30,
            message = "This is a test timer!",
            enabled = true,
        }))
        assert.is_not_true(pulse.add("test", {
            interval = 15,
            message = "This is another test timer!",
            enabled = false,
        }))
        assert.is_true(pulse._timers["test"].enabled())
        assert.is_equal("This is a test timer!", pulse._timers["test"].message)
    end)

    it("can remove a timer which has already been added", function()
        local pulse = require("pulse")
        pulse.setup()
        assert.is_true(pulse.add("test", {
            interval = 30,
            message = "This is a test timer!",
            enabled = true,
        }))
        assert.is_true(pulse.remove("test"))
        assert.is_equal(nil, pulse._timers["test"])
    end)

    it("cannot remove a timer which does not exist", function()
        local pulse = require("pulse")
        pulse.setup()
        assert.is_false(pulse.remove("test"))
    end)

    it("cannot remove a timer which has already been removed", function()
        local pulse = require("pulse")
        pulse.setup()
        assert.is_true(pulse.add("test", {
            interval = 30,
            message = "This is a test timer!",
            enabled = true,
        }))
        assert.is_true(pulse.remove("test"))
        assert.is_equal(nil, pulse._timers["test"])
        assert.is_false(pulse.remove("test"))
        assert.is_equal(nil, pulse._timers["test"])
    end)

    it("returns the correct remaining time for a timer that is enabled", function()
        local pulse = require("pulse")
        pulse.setup()
        assert.is_true(pulse.add("test", {
            interval = 30,
            message = "This is a test timer!",
            enabled = true,
        }))
        local hours, minutes = pulse.status("test")
        assert.equal(0, hours)
        assert.equal(30, minutes)
    end)

    it("returns the correct remaining time for a timer that is disabled", function()
        local pulse = require("pulse")
        pulse.setup()
        assert.is_true(pulse.add("test", {
            interval = 30,
            message = "This is a test timer!",
            enabled = false,
        }))
        local hours, minutes = pulse.status("test")
        assert.equal(0, hours)
        assert.equal(30, minutes)
    end)

    it("cannot get the status of a timer that does not exist", function()
        local pulse = require("pulse")
        pulse.setup()
        local hours, minutes = pulse.status("timer-that-does-not-exist")
        assert.equal(-1, hours)
        assert.equal(-1, minutes)
    end)
end)
