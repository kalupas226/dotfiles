SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
CONFIG_HOME = $(HOME)/.config

all: macos	

macos: install-manager packages link

install-manager: install-brew install-asdf

packages: brew-packages npm-packages

install-brew:
	which brew || \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

install-asdf:
	if [ ! -d ~/.asdf ]; then \
		git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0;  \
	fi

install-node: install-asdf
	. "${HOME}/.asdf/asdf.sh"
	if [ -z "$$(asdf plugin list | grep nodejs)" ]; then \
		asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git; \
	fi
	asdf install nodejs latest
	asdf global nodejs latest

brew-packages: install-brew
	brew bundle -v --file=${DOTFILES_DIR}/install/Brewfile

npm-packages: install-node
	npm install -g $(shell cat ${DOTFILES_DIR}/install/npmfile)

link: brew-packages
	mkdir -p $(CONFIG_HOME)
	stow -v -d ${DOTFILES_DIR}/packages -t ~ $$(find "${DOTFILES_DIR}"/packages/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

