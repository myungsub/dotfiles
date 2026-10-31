# dotfiles

Shell, vim and tmux settings, plus user-level Claude Code configuration.

## Install

```bash
git clone https://github.com/myungsub/dotfiles ~/dotfiles
~/dotfiles/setup.sh --dry-run   # preview
~/dotfiles/setup.sh
```

`setup.sh` links each file below into `$HOME`. An existing file is moved to
`<name>.backup` first, and re-running it is safe.

| In this repository     | Linked to                 | Contents |
|------------------------|---------------------------|----------|
| `bashrc`               | `~/.bashrc`               | Environment for every shell (CUDA, `PATH`, `OMP_NUM_THREADS`), then interactive settings |
| `bash_aliases`         | `~/.bash_aliases`         | Aliases |
| `bash_profile`         | `~/.bash_profile`         | Makes login shells (new tmux panes) load `~/.profile` / `~/.bashrc` |
| `vimrc`                | `~/.vimrc`                | Works in vim, neovim and vim.tiny |
| `tmux.conf`            | `~/.tmux.conf`            | Prefix `C-a`, vi keys |
| `claude/CLAUDE.md`     | `~/.claude/CLAUDE.md`     | Instructions Claude Code follows in every project |
| `claude/settings.json` | `~/.claude/settings.json` | Permission allow/deny rules |

## Per-machine settings

Values that differ per machine or must stay out of a public repository go in
`~/.bashrc.local`, which is not tracked:

```bash
export HF_HOME=/mnt/shared/hf
```

It is read by every shell, including the non-interactive one that
`ssh host cmd` starts, so it must not print anything.

If `~/.claude/settings.json` existed before, `setup.sh` moved it to
`~/.claude/settings.json.backup`. Merge anything you still need from it into
`claude/settings.json`.
