#!/bin/bash
# Initial setup

# Make backup files if already exist
if [ -f ~/.bashrc ]; then
    mv ~/.bashrc ~/.bashrc.backup
fi
if [ -f ~/.bash_aliases ]; then
    mv ~/.bash_aliases ~/.bash_aliases.backup
fi
if [ -f ~/.vimrc ]; then
    mv ~/.vimrc ~/.vimrc.backup
fi
if [ -f ~/.tmux.conf ]; then
	mv ~/.tmux.conf ~/.tmux.conf.backup
fi

# Make symbolic links to the home directory
ln -s ~/dotfiles/bashrc ~/.bashrc
ln -s ~/dotfiles/bash_aliases ~/.bash_aliases
ln -s ~/dotfiles/vimrc ~/.vimrc
ln -s ~/dotfiles/tmux.conf ~/.tmux.conf
