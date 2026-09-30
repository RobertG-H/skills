#!/bin/bash
#
# PreToolUse hook: blocks destructive git commands before Claude runs them.
#
# This is FRICTION, NOT A SECURITY BOUNDARY. It pattern-matches a shell string,
# and no regex wins that game: `g=push; git $g`, a shell alias, `sh -c "..."`,
# or base64 all slip past it. Treat it as a guard against an agent's own
# mistakes, not against a determined adversary. For a real boundary, use
# `permissions.deny` in settings.json.
#
# It fails CLOSED: input it cannot parse is blocked rather than allowed.

set -uo pipefail

INPUT=$(cat)

if [ -z "$INPUT" ]; then
  echo "BLOCKED: empty hook input. Failing closed." >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: jq is not installed, so this hook cannot inspect the command. Failing closed." >&2
  exit 2
fi

# A parse failure means the hook cannot see what it is being asked to approve,
# so it blocks. Valid JSON with no command field is a different case: that is a
# non-Bash tool the matcher let through, and there is nothing to check.
if ! COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null); then
  echo "BLOCKED: hook input is not valid JSON. Failing closed." >&2
  exit 2
fi

[ -n "$COMMAND" ] || exit 0

# Collapse tabs, newlines (a `\`-continued command is still one command) and
# runs of spaces, so `git  push` and `git\tpush` cannot walk past a pattern
# written with single spaces.
NORMALISED=$(printf '%s' "$COMMAND" | tr '\n\t' '  ' | tr -s ' ')

# `git` plus any global flags that may sit before the subcommand: `-C <path>`,
# `-c <key>=<value>`, `--no-pager`, `--git-dir=<path>`, and so on. Without this
# prefix, `git -C /repo push` sails past a literal "git push".
GIT='git( +(-[cC] +[^ ]+|--?[a-zA-Z][^ ]*))* +'

DANGEROUS_PATTERNS=(
  "${GIT}push"
  "${GIT}reset +--hard"
  "${GIT}clean +-[a-z]*f[a-z]*"
  "${GIT}branch +-D"
  "${GIT}checkout +\."
  "${GIT}restore +\."
  "push +--force"
  "push +-f( |$)"
  "reset +--hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if printf '%s' "$NORMALISED" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

exit 0
