return require("telescope").register_extension({
    setup = function(ext_config, config) end,
    exports = {
        pulse = require("pulse").pick_timers,
    },
})
