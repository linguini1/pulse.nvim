test:
	nvim --headless -c "PlenaryBustedDirectory tests/ {sequential = true}" -c "qa"
