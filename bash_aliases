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

# SSH
alias cmshome="ssh -X -p 8022 myungsub@panicmonster.hopto.org" # registered w/ noip2 (www.no-ip.com)

# Get week number
alias week='date +%V'

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec $SHELL -l"

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# Start Python Environments (tensorflow / pytorch)
alias anaconda="source ~/conda.bashrc"
alias tf="conda activate tf"
alias pytorch="conda activate pytorch"
alias deactivate="conda deactivate"
alias deac="conda deactivate"
alias compression="conda activate compression"
alias frame="conda activate frame"
alias action="conda activate action"

alias browse="python -m http.server 8080"

function gdrive_download () {
  CONFIRM=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$1" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')
  wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$CONFIRM&id=$1" -O $2
  rm -rf /tmp/cookies.txt
}
