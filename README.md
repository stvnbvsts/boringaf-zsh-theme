# boringaf zsh theme

A sarcastically named Oh My Zsh theme with a colorful, compact developer dashboard prompt.

The theme uses semantic ANSI colors like `cyan`, `magenta`, `green`, and `yellow` so it adapts to your terminal theme instead of fighting it with hard-coded 256-color values.

```text
steven ~/Projects/boringaf-zsh-theme [git  main] [tag v0.1.0] [+2 ~1 ?3] [ahead 1 behind 0] [stash 1]
λ
```

On command failure:

```text
steven ~/Projects/boringaf-zsh-theme [git  main] [+2 ~1 ?3]
λ
```

## Install

Copy the theme into your Oh My Zsh custom themes directory:

```zsh
cp boringaf.zsh-theme "$ZSH_CUSTOM/themes/boringaf.zsh-theme"
```

Then set this in `~/.zshrc`:

```zsh
ZSH_THEME="boringaf"
```

Reload your shell:

```zsh
source ~/.zshrc
```

## Git segments

The Git line shows:

- branch name
- exact tag when `HEAD` is on a tag
- staged count as `+N`
- unstaged count as `~N`
- untracked count as `?N`
- conflicts as `!N`
- ahead/behind counts
- stash count
- operation state: merge, rebase, cherry-pick, revert, or bisect

The prompt does not show the time.

The branch icon is the Powerline/Nerd Font glyph ``. If your terminal font does not support it, the prompt still works, but that icon may render as a box.

## Context

The prompt always shows the username. It adds `@host` only when you are connected over SSH or when `$USER` is different from `$DEFAULT_USER`.

The second line shows command duration only when the previous command took at least `5s`:

```text
[5.231s] λ
```

You can change the threshold before loading Oh My Zsh:

```zsh
BORINGAF_DURATION_THRESHOLD=3
```
