# pulse.nvim

Pulse.nvim is a plugin for creating and managing personal timers. If you have
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) installed, pulse will also make use of its features
for managing your timers.

## Getting Started

### Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "linguini1/pulse.nvim" }
```

### Configuration

The configuration for pulse.nvim is very simple. Below is the default configuration. See `:h pulse.setup()` for more
information.

```lua
local pulse = require("pulse")
pulse.setup({
    level = vim.log.levels.INFO,
})
```

Once you have `setup` pulse.nvim, you can add timers using the below format. See `:h pulse.add()` for more information.

```lua
--- Parameters: name, interval, message, enabled
pulse.add("break-timer", 60, "Take a break!", true)
```

## Documentation

See `:h pulse.nvim` for documentation.
