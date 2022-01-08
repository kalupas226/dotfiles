.PHONY: all
all:
	make clone-dotfiles
	make bundle-brew-file
	make link

.PHONY: clone-dotfiles
clone-dotfiles:
	if [ ! -d ~/dotfiles ]; then \
		cd ~; \
		git clone https://github.com/kalupas226/dotfiles.git; \
	fi

.PHONY: brew-bundle
bundle-brew-file:
	which brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	brew bundle -v --file=~/dotfiles/Brewfile

.PHONY: link
link:
	if [ ! -d ~/.config ]; then \
		cd ~; \
		mkdir .config; \
	fi

	which stow >/dev/null 2>&1 || stow -v -d ~/dotfiles/packages -t ~ "$(ls ~/dotfiles/packages)"
