# The canonical install block

One install story, one wording. `README.md` and `.changeset/*` must say **this** and nothing else. Change it here first, then propagate.

This repo is a **fork** of [mattpocock/skills](https://github.com/mattpocock/skills), renamed to `robert-skills`. It is not published to any marketplace, and it is not served by `skills.sh`. The only install route is a local clone of this repo, which `.claude-plugin/marketplace.json` turns into a single-plugin marketplace named `robert`.

## Claude Code: the plugin

<canonical-block name="claude-code">

```bash
git clone https://github.com/RobertG-H/skills.git
claude plugin marketplace add ./skills
claude plugin install robert-skills@robert
```

After you edit a skill or pull new commits, pick the changes up with:

```bash
claude plugin marketplace update robert
claude plugin update robert-skills
```

</canonical-block>

## Don't stack it on upstream

Upstream ships the same skills as `mattpocock-skills`, listed in Claude Code's official marketplace, and `skills.sh` copies them into a project as editable files. Either one installed next to this fork leaves you with two copies of every skill, differing only in the names of `ask-robert` and `setup-robert-skills`. Pick one.

<canonical-block name="upstream-warning">

Don't also install upstream's `mattpocock-skills`: you would end up with two copies of every skill.

</canonical-block>

## Not the install story

`claude plugin marketplace add` also accepts a GitHub repo, so `claude plugin marketplace add RobertG-H/skills` works once the fork is pushed. The local-clone form stays canonical because it is the one that picks up uncommitted work, which is the point of running your own fork.

A native Codex route is still open: the skills carry `agents/openai.yaml`, and `scripts/link-skills.sh` symlinks every skill outside `deprecated/` and `misc/` into `~/.claude/skills` and `~/.agents/skills`. That script is a maintainer tool, not a supported installer, and it is not this block. Why a Claude plugin but not (yet) a Codex one lives in [adr/0002-ship-as-a-claude-code-plugin.md](./adr/0002-ship-as-a-claude-code-plugin.md).
