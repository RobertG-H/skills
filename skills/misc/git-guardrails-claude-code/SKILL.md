---
name: git-guardrails-claude-code
description: Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code.
---

# Setup Git Guardrails

Sets up a PreToolUse hook that intercepts and blocks dangerous git commands before Claude executes them.

## What Gets Blocked

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

When blocked, Claude sees a message telling it that it does not have authority to access these commands.

Matching tolerates the global flags that can sit before a subcommand (`git -C <path> push`, `git -c <key>=<value> push`) and any run of whitespace, so the obvious near-misses do not walk past it.

## What This Is Not

This hook is **friction, not a security boundary**. It pattern-matches a shell string, and no regex wins that game: `g=push; git $g`, a shell alias, `sh -c "..."`, or a base64-decoded command all slip past it. It guards against an agent's own mistakes, not against a determined adversary.

For a real boundary, use `permissions.deny` in `settings.json`, which the harness enforces rather than a regex. Run both if you want: the hook gives a clearer message at the moment of the mistake.

The hook **fails closed**: input it cannot parse (malformed JSON, no `jq` on the system, empty stdin) is blocked rather than waved through, so a broken environment cannot silently disable it.

## Steps

### 1. Ask scope

Ask the user: install for **this project only** (`.claude/settings.json`) or **all projects** (`~/.claude/settings.json`)?

### 2. Copy the hook script

The bundled script is at: [scripts/block-dangerous-git.sh](scripts/block-dangerous-git.sh)

Copy it to the target location based on scope:

- **Project**: `.claude/hooks/block-dangerous-git.sh`
- **Global**: `~/.claude/hooks/block-dangerous-git.sh`

Make it executable with `chmod +x`.

### 3. Add hook to settings

Add to the appropriate settings file:

**Project** (`.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

**Global** (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

If the settings file already exists, merge the hook into the existing `hooks.PreToolUse` array. Don't overwrite other settings.

### 4. Ask about customization

Ask if user wants to add or remove any patterns from the blocked list. Edit the copied script accordingly.

### 5. Verify

Run three tests, covering a block, a fail-closed, and a pass:

```bash
# 1. Blocks a dangerous command (exit 2, BLOCKED on stderr)
echo '{"tool_input":{"command":"git -C /repo push origin main"}}' | <path-to-script>

# 2. Fails closed on unparseable input (exit 2)
echo 'not-json' | <path-to-script>

# 3. Lets a safe command through (exit 0, no output)
echo '{"tool_input":{"command":"git status"}}' | <path-to-script>
```

If test 2 exits `0`, the script is the old fail-open version: replace it, since a guardrail that waves through what it cannot read is worse than none.
