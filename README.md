# dotfiles

## Installation
If macOS:

```
sudo softwareupdate -i -a
xcode-select --install
```

Install dotfiles repo with `curl` available:

```
bash -c "`curl -fsSL https://raw.githubusercontent.com/kalupas226/dotfiles/master/remote-install.sh`"
```

Alternatively, clone manually into the desired location:

```
git clone https://github.com/kalupas226/dotfiles.git ~/.dotfiles
```

Use the Makefile to install everything and symlink with stow.

```
cd ~/.dotfiles
make
```

