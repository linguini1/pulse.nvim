test:
	nvim --headless --noplugin -u scripts/minimal.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.vim', sequential = true}"
