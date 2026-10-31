# Personal defaults for every project

A repository's own `CLAUDE.md` or `AGENTS.md` takes precedence over this file.

## Communication

- Reply in the language I write in (usually Korean). Keep technical terms in
  their original English form (`commit`, `rebase`, `race condition`) instead
  of translating them.

## Evidence before conclusions

- A string in the code (an error message, a status literal, an enum name) is
  evidence of a code path, not of a cause. Find every site that can produce it
  before attributing a failure. If the code does not settle it, report the
  ambiguity rather than picking the likely-looking answer.
- Back a claim with something observed: command output, a test, a file and
  line.

## Python

- Use `uv` (`uv run`, `uv add`, `uv pip`, `uvx`) unless the repository is set
  up for something else (conda, poetry); then follow the repository.
- Never install packages into the system Python.

## Git

- Commit messages use Conventional Commits with a scope:
  `feat(scope): ...`, `fix(scope): ...`, `docs(scope): ...`,
  `refactor(scope): ...`, `test(scope): ...`.
- Push with an explicit remote and branch (`git push origin <branch>`). Never
  push directly to `main`, `master` or `dev`.
- Rewrite pushed history only on your own branch, and only with
  `--force-with-lease`.
- Merge, approve, or bypass branch protection only when I ask for it.

## Irreversible operations need a human

- Destructive SQL against a non-test database (`TRUNCATE`, `DROP`, `DELETE`
  without `WHERE`): prepare the exact statement, show it, and let me run it.
- The same goes for deleting shared storage, cloud resources, or data outside
  the working tree.

## GPU servers

- Before choosing GPU indices, check `nvidia-smi` for memory and running
  processes. Do not infer the GPU model or count from a host name.
- Never kill a process you did not start. Confirm its owner and command line
  first.
- Keep `HF_HOME` and other large caches on persistent storage, not on a small
  home disk.
- `ssh host cmd` runs a non-interactive shell. Pass the environment the
  command needs explicitly instead of assuming the remote shell rc was loaded.
- Run long jobs inside `tmux` (or the host's persistent session mechanism) and
  log to a file.
- Copy finished artifacts (checkpoints, eval reports) to durable storage before
  starting the next run. A GPU host's disk is not an artifact registry.
