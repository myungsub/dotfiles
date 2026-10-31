#!/usr/bin/env python3
"""PreToolUse:Bash guard for every project (registered in ~/.claude/settings.json).

The project-independent part of the trust-layer hooks (.claude/hooks/git_guard.py
and bash_guard.py). PreToolUse hooks run in every permission mode, so under
--dangerously-skip-permissions this is the only check these commands meet.
stdlib-only. Exit 0 = allow, exit 2 = block (stderr is fed back to the model).

  push   `git push` needs an explicit remote and branch, never targets
         main/master/dev, never uses --all/--mirror, and forces only with
         --force-with-lease.
  merge  `gh pr merge --admin` bypasses branch protection; that is a human's call.
  sql    TRUNCATE, DROP TABLE|SCHEMA|DATABASE, or DELETE FROM without WHERE sent
         through psql to a database whose name does not contain `test`.

    python3 ~/.claude/hooks/agent_guard.py --selftest
"""

from __future__ import annotations

import json
import re
import shlex
import sys

PROTECTED_BRANCHES = {"main", "master", "dev"}
WRAPPERS = {
    "sudo", "time", "nohup", "setsid", "env", "command", "exec", "caffeinate", "stdbuf", "xargs",
    "do", "then", "else", "elif", "eval", "until", "while", "if",
}
GIT_OPTIONS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}
PUSH_OPTIONS_WITH_VALUE = {"-o", "--push-option", "--repo", "--receive-pack", "--exec"}


# ── git / gh ─────────────────────────────────────────────────────────────────

def statements(command: str) -> list[str]:
    """Split on ; & | newlines, backticks and `(`, outside quotes."""
    parts: list[str] = []
    current: list[str] = []
    quote: str | None = None
    for ch in command:
        if quote:
            current.append(ch)
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
            current.append(ch)
        elif ch in ";&|\n`(":
            parts.append("".join(current))
            current = []
        else:
            current.append(ch)
    parts.append("".join(current))
    return [p for p in parts if p.strip()]


def tokenize(stmt: str) -> list[str]:
    try:
        tokens = shlex.split(stmt)
    except ValueError:
        tokens = stmt.split()
    while tokens:
        tok = tokens[0]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", tok) or tok in WRAPPERS or tok.startswith("-"):
            tokens = tokens[1:]
        elif tok == "timeout":
            tokens = tokens[1:]
            while tokens and (tokens[0].startswith("-") or re.match(r"^\d+[smhd]?$", tokens[0])):
                tokens = tokens[1:]
        else:
            break
    return tokens


def shell_inline_script(tokens: list[str]) -> str | None:
    if not tokens or tokens[0].rsplit("/", 1)[-1] not in {"bash", "sh", "zsh"}:
        return None
    for i, tok in enumerate(tokens[1:], start=1):
        if re.fullmatch(r"-[A-Za-z]*c[A-Za-z]*", tok) and i + 1 < len(tokens):
            return tokens[i + 1]
    return None


def short_flags(args: list[str]) -> set[str]:
    return {ch for a in args if re.fullmatch(r"-[A-Za-z]+", a) for ch in a[1:]}


def push_destination(refspec: str) -> str:
    dst = refspec.split(":", 1)[1] if ":" in refspec else refspec
    return dst.lstrip("+").removeprefix("refs/heads/")


def check_push(args: list[str]) -> str | None:
    if any(a in {"--all", "--mirror"} for a in args):
        return "`git push --all/--mirror` is refused; push one explicit branch."
    if "--force" in args or "f" in short_flags(args) or any(a.startswith("+") for a in args):
        return "plain force pushes are refused; use `--force-with-lease` on your own branch."
    positional: list[str] = []
    skip = False
    for a in args:
        if skip:
            skip = False
        elif a in PUSH_OPTIONS_WITH_VALUE:
            skip = True
        elif not a.startswith("-"):
            positional.append(a)
    if len(positional) < 2:
        return "`git push` needs an explicit remote and branch: `git push origin <branch>`."
    for refspec in positional[1:]:
        if refspec == "HEAD":
            return "push an explicit branch name, not `HEAD`: `git push origin <branch>`."
        dst = push_destination(refspec)
        if dst in PROTECTED_BRANCHES:
            return f"pushing to `{dst}` is refused; main, master and dev change only through pull requests."
    return None


def check_merge(args: list[str]) -> str | None:
    if "--admin" in args:
        return (
            "`gh pr merge --admin` bypasses branch protection and is refused for an agent. "
            "If it is really needed, ask the human to run it with `!`."
        )
    return None


def check_git(command: str) -> str | None:
    for stmt in statements(command):
        tokens = tokenize(stmt)
        inline = shell_inline_script(tokens)
        if inline is not None:
            msg = check_git(inline)
            if msg:
                return msg
            continue
        if not tokens:
            continue
        head = tokens[0].rsplit("/", 1)[-1]
        if head == "gh" and tokens[1:3] == ["pr", "merge"]:
            msg = check_merge(tokens[3:])
        elif head == "git":
            i = 1
            while i < len(tokens) and tokens[i].startswith("-"):
                takes_value = tokens[i] in GIT_OPTIONS_WITH_VALUE
                i += 2 if takes_value else 1
            msg = check_push(tokens[i + 1 :]) if i < len(tokens) and tokens[i] == "push" else None
        else:
            msg = None
        if msg:
            return msg
    return None


# ── destructive SQL ──────────────────────────────────────────────────────────

SQL_TEST_DB = re.compile(r"test[a-z0-9_]*\b", re.IGNORECASE)
SQL_DB_TARGET = re.compile(r"(?:-d\s+|--dbname[= ]|postgres(?:ql)?://[^\s'\"]+/)(\S+)")
SQL_STDIN_FLAGS = {"-c", "--command", "-f", "--file"}
SQL_LAUNCHERS = WRAPPERS | {"docker", "docker-compose", "kubectl", "ssh", "gcloud", "az", "timeout"}


def loose_statements(command: str) -> list[str]:
    return [s for s in re.split(r"[;&|\n]+|\$\(|`", command) if s.strip()]


def is_psql(token: str) -> bool:
    return token == "psql" or token.endswith("/psql")


def sql_channel_statements(command: str) -> list[tuple[str, list[str]]]:
    """Statements that run psql. Quoted text collapses to one token, so a commit
    message or an echo that only mentions psql does not count."""
    out: list[tuple[str, list[str]]] = []
    for stmt in loose_statements(command):
        try:
            tokens = shlex.split(stmt)
        except ValueError:
            tokens = stmt.split()
        while tokens and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", tokens[0]):
            tokens = tokens[1:]
        if not tokens:
            continue
        first = tokens[0].lstrip("({'\"").rsplit("/", 1)[-1]
        if is_psql(first) or (first in SQL_LAUNCHERS and any(is_psql(t) for t in tokens[1:])):
            out.append((stmt, tokens))
    return out


def destructive_sql_in(text: str) -> list[str]:
    found = []
    if re.search(r"\bTRUNCATE\b", text, re.IGNORECASE):
        found.append("TRUNCATE")
    if re.search(r"\bDROP\s+(TABLE|DATABASE|SCHEMA)\b", text, re.IGNORECASE):
        found.append("DROP")
    for m in re.finditer(r"\bDELETE\s+FROM\b[^;]*", text, re.IGNORECASE):
        if not re.search(r"\bWHERE\b", m.group(0), re.IGNORECASE):
            found.append("DELETE FROM (no WHERE)")
    return found


def check_sql(command: str) -> str | None:
    destructive: list[str] = []
    scan_whole = False
    for stmt, tokens in sql_channel_statements(command):
        targets = " ".join(m.group(1) for m in SQL_DB_TARGET.finditer(stmt))
        if targets and SQL_TEST_DB.search(targets):
            continue
        destructive += destructive_sql_in(stmt)
        if not any(tok in SQL_STDIN_FLAGS for tok in tokens):
            scan_whole = True  # SQL arrives through a pipe or heredoc elsewhere in the command
    if scan_whole:
        destructive += destructive_sql_in(command)
    if destructive:
        kinds = ", ".join(dict.fromkeys(destructive))
        return (
            f"destructive SQL ({kinds}) against a non-test database. This is irreversible and "
            "reserved for a human: prepare the exact statement, show it to the user, and let them run it. "
            "If it really targets a test database, use a database name containing `test`."
        )
    return None


# ── entry points ─────────────────────────────────────────────────────────────

def check(command: str) -> str | None:
    for checker in (check_git, check_sql):
        msg = checker(command)
        if msg:
            return f"BLOCKED by ~/.claude/hooks/agent_guard.py: {msg}"
    return None


SELFTEST_CASES: list[tuple[str, bool]] = [
    ("git push origin claude/x", False),
    ("git push -u origin claude/x", False),
    ("git push --force-with-lease origin claude/x", False),
    ("git push -o ci.skip origin claude/x", False),
    ("git push origin HEAD:refs/heads/claude/x", False),
    ("git push", True),
    ("git push origin", True),
    ("git push origin main", True),
    ("git push origin master", True),
    ("git push origin dev", True),
    ("git push origin HEAD:refs/heads/main", True),
    ("git push origin HEAD", True),
    ("git push origin :main", True),
    ("git push --all origin", True),
    ("git push --force origin claude/x", True),
    ("git push -fu origin claude/x", True),
    ("git push origin +claude/x", True),
    ("git -C ../other push origin main", True),
    ("cd repo && git push origin main", True),
    ("env GIT_TRACE=1 git push origin main", True),
    ("bash -c 'git push origin main'", True),
    ('sh -lc "git push origin main"', True),
    ("if true; then git push origin main; fi", True),
    ("git commit -m 'never git push origin main'", False),
    ("echo git push origin main", False),
    ("git status && git log --oneline -3", False),
    ("gh pr merge 3 --merge", False),
    ("gh pr merge 3 --squash --admin", True),
    ("gh pr view 3 --json state", False),
    ("psql -d prod -c 'SELECT 1'", False),
    ("psql -d prod -c 'DELETE FROM users WHERE id = 1'", False),
    ("psql -d test_db -c 'TRUNCATE users'", False),
    ("psql -d prod -c 'TRUNCATE users'", True),
    ("psql -d prod -c 'DELETE FROM users'", True),
    ("echo 'DROP TABLE users' | psql -d prod", True),
    ("psql postgresql://u@h:5432/prod <<SQL\nDROP SCHEMA app CASCADE;\nSQL", True),
    ("docker exec db psql -U postgres -d prod -c 'DROP DATABASE prod'", True),
    ("psql -d test -c 'TRUNCATE a'; psql -d prod -c 'TRUNCATE b'", True),
    ("git commit -m 'psql TRUNCATE is dangerous'", False),
]


def selftest() -> int:
    failures = 0
    for command, should_block in SELFTEST_CASES:
        blocked = check(command) is not None
        if blocked != should_block:
            failures += 1
            print(f"FAIL: {command!r} blocked={blocked} expected={should_block}")
    print(f"{len(SELFTEST_CASES) - failures}/{len(SELFTEST_CASES)} agent_guard cases pass")
    return 1 if failures else 0


def main() -> int:
    if sys.argv[1:] == ["--selftest"]:
        return selftest()
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0  # never break the harness on malformed input
    command = (payload.get("tool_input") or {}).get("command") or ""
    if not isinstance(command, str) or not command:
        return 0
    msg = check(command)
    if msg:
        print(msg, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
