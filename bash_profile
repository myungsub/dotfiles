# Login shells (e.g. new tmux sessions) read this instead of ~/.profile,
# so load ~/.profile (which sources ~/.bashrc on Ubuntu), or ~/.bashrc directly
if [ -f ~/.profile ]; then
    . ~/.profile
elif [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
