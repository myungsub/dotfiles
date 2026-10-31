#!/usr/bin/env bash
# Link the files in this repository into $HOME. Safe to re-run.
#
# Usage: ./setup.sh [--dry-run]
#
# An existing regular file is moved to <name>.backup (or .backup.<timestamp>
# when that name is taken) before it is replaced. Links are refreshed.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
case "${1-}" in
    "") ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
esac

# <path in this repository>  <path under $HOME>
LINKS=(
    "bashrc                       .bashrc"
    "bash_aliases                 .bash_aliases"
    "bash_profile                 .bash_profile"
    "vimrc                        .vimrc"
    "tmux.conf                    .tmux.conf"
    "agents/AGENTS.md             .claude/CLAUDE.md"
    "agents/AGENTS.md             .codex/AGENTS.md"
    "claude/settings.json         .claude/settings.json"
    "claude/hooks/agent_guard.py  .claude/hooks/agent_guard.py"
)

run() {
    if (( DRY_RUN )); then echo "+ $*"; else "$@"; fi
}

for entry in "${LINKS[@]}"; do
    read -r src dst <<<"$entry"
    src="$DOTFILES/$src"
    dst="$HOME/$dst"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        continue
    fi
    run mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        backup="$dst.backup"
        if [ -e "$backup" ]; then
            backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
        fi
        run mv "$dst" "$backup"
        echo "backed up $dst -> $backup"
    fi
    run ln -sfn "$src" "$dst"
    echo "linked $dst -> $src"
done

# Codex also writes ~/.codex/config.toml (project trust, ...), so instead of
# linking it, make sure it carries the one key this setup needs: read CLAUDE.md
# in directories that have no AGENTS.md. A top-level TOML key has to come
# before the first table, so it goes on the first line.
codex_config="$HOME/.codex/config.toml"
fallback_line='project_doc_fallback_filenames = ["CLAUDE.md"]'
if [ -L "$codex_config" ]; then
    echo "skipped $codex_config: it is a link; add '$fallback_line' to its target"
elif ! grep -Eq '^[[:space:]]*project_doc_fallback_filenames[[:space:]]*=' "$codex_config" 2>/dev/null; then
    if (( DRY_RUN )); then
        echo "+ prepend '$fallback_line' to $codex_config"
    else
        mkdir -p "$(dirname "$codex_config")"
        existing="$(cat "$codex_config" 2>/dev/null || true)"
        printf '%s\n%s' "$fallback_line" "${existing:+$existing$'\n'}" > "$codex_config"
    fi
    echo "set $fallback_line in $codex_config"
fi
