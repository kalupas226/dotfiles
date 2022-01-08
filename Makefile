SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: clone-dotfiles macos	

macos: core-macos packages link

core-macos: brew npm

packages: brew-packages npm-packages

clone-dotfiles:
	if [ ! -d ~/dotfiles ]; then \
		cd ~; \
		git clone https://github.com/kalupas226/dotfiles.git; \
	fi

brew:
	which brew >/dev/null 2>&1 || "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \

brew-packages: brew
	brew bundle -v --file=${DOTFILES_DIR}/install/Brewfile

npm: brew-packages
	which nodebrew >/dev/null 2>&1 || nodebrew install-binary latest

npm-packages: npm
	npm install -g $(shell cat ${DOTFILES_DIR}/install/npmfile)

link:
	if [ ! -d ~/.config ]; then \
		cd ~; \
		mkdir .config; \
	fi

	which stow >/dev/null 2>&1 || stow -v -d ${DOTFILES_DIR}/packages -t ~ "$(ls ${DOTFILES_DIR}/packages)"
