<div align="center">
    <h1>
        <img style="margin: 0 0 -15px 0;" src="https://cdn-icons-png.flaticon.com/512/5523/5523525.png" width="50px" />
        pulse.nvim
    </h1>
    <h5>Easily manageable timers to keep on track while coding.</h5>
</div>

Pulse.nvim is a plugin for creating and managing personal timers. If you have
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) installed, pulse will also make use of its features
for managing your timers.

## Getting Started

### Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "linguini1/pulse.nvim",
    config = function() require("pulse").setup() end -- Call setup to get the basic config
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "linguini1/pulse.nvim",
    version = "*", -- Latest stable release
    config = function() require("pulse").setup() end -- Call setup to get the basic config
}
```

You must call `pulse.setup()` in order to get access to the editor commands and default functionality.

### Configuration

The configuration for pulse.nvim is very simple. Below is the default configuration. See `:h pulse.setup()` for more
information.

```lua
local pulse = require("pulse")
--- Default configuration settings
pulse.setup({
    level = vim.log.levels.INFO,
})
```

Once you have `setup` pulse.nvim, you can add timers using the below format. See `:h pulse.add()` for more information.

```lua
--- Parameters: name, interval, message, enabled
pulse.add("break-timer", {
    interval = 60,
    message = "Take a break!",
    enabled = true
})
```

## Documentation

See `:h pulse.nvim` for documentation.

## Attribution

This plugin was inspired by [stand.nvim](https://github.com/mvllow/stand.nvim), a plugin which reminds you to stand.
