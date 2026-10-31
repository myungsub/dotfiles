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
| `agents/AGENTS.md`     | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` | Instructions Claude Code and Codex follow in every project |
| `claude/settings.json` | `~/.claude/settings.json` | Auto mode by default, permission allow/deny rules, guard hook |
| `claude/hooks/agent_guard.py` | `~/.claude/hooks/agent_guard.py` | Blocks unsafe pushes, `gh pr merge --admin`, destructive SQL |

`setup.sh` also puts `project_doc_fallback_filenames = ["CLAUDE.md"]` at the
top of `~/.codex/config.toml`, so Codex reads a directory's `CLAUDE.md` when it
has no `AGENTS.md`. Codex writes to that file itself (project trust, for
example), so it is edited in place rather than linked, and an existing value
for the key is left alone.

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

## Claude Code notes

- `c` starts Claude Code in auto mode (`permissions.defaultMode`), which only
  user settings can choose. Where auto mode is unavailable a session starts in
  manual mode. `cy` skips every prompt.
- `agent_guard.py` runs before every Bash command in every project and every
  permission mode, `cy` included. It refuses a bare `git push`, pushes to
  `main`/`master`/`dev`, `--all`/`--mirror`, force pushes without
  `--force-with-lease`, `gh pr merge --admin`, and `TRUNCATE`/`DROP`/unbounded
  `DELETE` through psql to a non-test database. Check it with
  `python3 ~/.claude/hooks/agent_guard.py --selftest`. Project hooks (such as
  trust-layer's `git_guard.py`) run alongside it.
- Read-only commands (`ls`, `cat`, `grep`, read-only `git`, ...) never prompt,
  so `allow` lists only the extra commands worth skipping a prompt for.
- `deny` rules hold in every permission mode, including `cy`
  (`--dangerously-skip-permissions`), where `allow` rules have no effect.
  A `Read` deny also covers Edit/Write and shell reads such as `cat`, but not
  a program that opens the file itself.
- `/config` and `/model` write to `~/.claude/settings.json`. If
  `git status` here shows a change you did not make, that is where it came
  from; if `~/.claude/settings.json` is no longer a link, re-run `setup.sh`.
