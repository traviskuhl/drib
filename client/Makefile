DRIB=./src/bin/drib
all:
	@$(DRIB) --check-install --bin=/usr/local/bin

install:
	@$(DRIB) create pkg/drib.dpf  --install --cleanup --var src=./src --var bin=/usr/local/bin --var lib=/usr/local/bin/../lib

symlink:
	@$(DRIB) create pkg/drib.dpf  --install --cleanup --var src=./src --var bin=/usr/local/bin --var lib=/usr/local/bin/../lib --type=symlink