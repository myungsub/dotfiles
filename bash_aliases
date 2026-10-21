#!/bin/bash

# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~" # `cd` is probably faster to type though

# Shortcuts
alias d="cd ~/Documents/Dropbox"
alias dl="cd ~/Downloads"
alias w="cd ~/workspace"
alias g="git"
alias h="history"
# Bash profiles
alias brc="vi ~/.bashrc"
alias balias="vi ~/.bash_aliases"
# Docker
alias drm="docker rm"
alias dps="docker ps"

# Get week number
alias week='date +%V'

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# IP addresses
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"
alias ips="command ip -o addr show | awk '{ sub(/\/.*/, \"\", \$4); print \$4 }'"

# View HTTP traffic
alias sniff="sudo ngrep -d any -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i any -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec $SHELL -l"

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# Start Python Environments (tensorflow / pytorch)
alias anaconda="source ~/conda.bashrc"
alias deactivate="conda deactivate"
alias deac="conda deactivate"

alias browse="python3 -m http.server 8080"

alias cc="claude --dangerously-skip-permissions"

# Usage: gdrive_download <file_id> <output>
function gdrive_download () {
  wget "https://drive.usercontent.google.com/download?id=$1&export=download&confirm=t" -O "$2"
}
