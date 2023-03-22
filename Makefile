SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
CONFIG_HOME = $(HOME)/.config

all: macos	

macos: core-macos packages link

core-macos: install-brew install-node

packages: brew-packages npm-packages

install-brew:
	which brew || \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

brew-packages: install-brew
	brew bundle -v --file=${DOTFILES_DIR}/install/Brewfile

install-nvm:
	if [ ! -d ~/.nvm ]; then \
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash ; \
	fi

install-node: install-nvm
	. ~/.nvm/nvm.sh && nvm install node

npm-packages: install-node
	npm install -g $(shell cat ${DOTFILES_DIR}/install/npmfile)

link: brew-packages
	mkdir -p $(CONFIG_HOME)
	stow -v -d ${DOTFILES_DIR}/packages -t ~ $$(find "${DOTFILES_DIR}"/packages/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
