#!/bin/bash
# ~/.bash_aliases — sourced by ~/.bashrc in interactive shells

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"

# Shortcuts
alias d="cd ~/Documents/Dropbox"
alias dl="cd ~/Downloads"
alias w="cd ~/workspace"
alias g="git"
alias h="history"
alias brc="vi ~/.bashrc"
alias balias="vi ~/.bash_aliases"

# Shell
alias reload="exec \$SHELL -l"            # restart as a login shell
alias path='echo -e ${PATH//:/\\n}'      # one PATH entry per line
alias ips="command ip -o addr show | awk '{ sub(/\/.*/, \"\", \$4); print \$4 }'"
alias browse="python3 -m http.server 8080"

# Docker
alias drm="docker rm"
alias dps="docker ps"

# Conda. `deactivate` itself is left alone: venv and uv environments define it.
alias anaconda="source ~/conda.bashrc"
alias deac="conda deactivate"

# Claude Code. Not `cc`, which is the C compiler.
alias c="claude"                                  # auto mode, per ~/.claude/settings.json
alias cy="claude --dangerously-skip-permissions"  # no prompts; only deny rules and hooks still apply

# Usage: gdrive_download <file_id> <output>
gdrive_download() {
    wget "https://drive.usercontent.google.com/download?id=$1&export=download&confirm=t" -O "$2"
}
