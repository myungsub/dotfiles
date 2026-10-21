#!/bin/bash
# Initial setup

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for f in bashrc bash_aliases bash_profile vimrc tmux.conf; do
    target=~/.$f
    # Make backup files if already exist (skip links we created before)
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$target.backup"
    fi
    # Make symbolic links to the home directory
    ln -sfn "$DOTFILES/$f" "$target"
done
