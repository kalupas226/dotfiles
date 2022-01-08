SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/bin:$(PATH)
CONFIG_HOME = $(HOME)/.config

all: macos	

macos: core-macos packages link

core-macos: brew npm

packages: brew-packages npm-packages

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

brew-packages: brew
	brew bundle -v --file=${DOTFILES_DIR}/install/Brewfile

npm: brew-packages
	is-executable nodebrew || nodebrew install-binary latest

npm-packages: npm
	npm install -g $(shell cat ${DOTFILES_DIR}/install/npmfile)

link:
	mkdir -p $(CONFIG_HOME)
	is-executable stow || stow -v -d ${DOTFILES_DIR}/packages -t ~ "$(ls ${DOTFILES_DIR}/packages)"
