# ~/.bashrc — https://github.com/myungsub/dotfiles
#
# The environment section runs in every bash, including the non-interactive
# one that `ssh host cmd` starts (scripts and AI agents run remote commands
# that way), so nothing above the interactive guard may print output.

_prepend() {  # _prepend VAR DIR: put DIR at the front of VAR exactly once
    local rest=":${!1-}:"
    rest="${rest//:$2:/:}"
    rest="${rest#:}"
    rest="${rest%:}"
    export "$1=$2${rest:+:$rest}"
}

# ── Environment (all shells) ────────────────────────────────────────────────
if [ -d /usr/local/cuda ]; then  # symlink to the installed CUDA version
    export CUDAHOME=/usr/local/cuda
    _prepend PATH "$CUDAHOME/bin"
    _prepend LD_LIBRARY_PATH "$CUDAHOME/lib64"
fi
export CUDA_DEVICE_ORDER=PCI_BUS_ID  # GPU indices match nvidia-smi
export OMP_NUM_THREADS=8             # keep PyTorch from taking every core
_prepend LD_LIBRARY_PATH /usr/local/lib
_prepend PATH "$HOME/.local/bin"

# Per-machine values that must not be committed (HF_HOME on a shared disk,
# a project's env file, ...). Read by every shell, so it must not print.
if [ -r ~/.bashrc.local ]; then
    . ~/.bashrc.local
fi
unset -f _prepend

# ── Interactive shells only ─────────────────────────────────────────────────
case $- in
    *i*) ;;
    *) return ;;
esac

HISTCONTROL=ignoreboth  # skip duplicates and lines that start with a space
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend checkwinsize

case "$TERM" in
    xterm-color|*-256color) PS1='\[\e[01;32m\]\u@\h\[\e[00m\]:\[\e[01;34m\]\w\[\e[00m\]\$ ' ;;
    *) PS1='\u@\h:\w\$ ' ;;
esac
case "$TERM" in
    xterm*|rxvt*) PS1="\[\e]0;\u@\h: \w\a\]$PS1" ;;  # window title
esac

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then eval "$(dircolors -b ~/.dircolors)"; else eval "$(dircolors -b)"; fi
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='grep -F --color=auto'
    alias egrep='grep -E --color=auto'
fi
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if ! shopt -oq posix; then
    for f in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
        if [ -r "$f" ]; then . "$f"; break; fi
    done
    unset f
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
