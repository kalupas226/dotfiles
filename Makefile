SHELL = /bin/zsh
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
CONFIG_HOME = $(HOME)/.config
.SHELLFLAGS := -e -c

all: macos	

macos: install-manager packages link

install-manager: install-brew install-mise

packages: brew-packages npm-packages

install-brew:
	which brew || \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

install-mise:
	curl https://mise.run | sh
	@if ! grep -q "mise activate" ~/.zshrc; then \
		echo 'eval "$$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc; \
	fi

install-node: install-mise
	. ~/.zshrc && mise use --global node@latest

brew-packages: install-brew
	brew bundle -v --file=${DOTFILES_DIR}/install/Brewfile

npm-packages: install-node
	npm install -g $(shell cat ${DOTFILES_DIR}/install/npmfile)

link: brew-packages
	mkdir -p $(CONFIG_HOME)
	stow -v -d ${DOTFILES_DIR}/packages -t ~ $$(find "${DOTFILES_DIR}"/packages/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

