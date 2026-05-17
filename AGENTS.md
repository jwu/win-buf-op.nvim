# AGENTS.md

## Project

This repository is `last-win-jump.nvim`, a small Neovim plugin written in Lua for toggling between the current window and the last visited window.

The project targets:

- Neovim Lua plugin conventions
- small, focused changes
- no required `setup()` call
- `<Plug>` mappings for user keybindings

## Key structure

- `plugin/last-win-jump.lua`
  - auto-loaded plugin entry
  - tracks windows via `WinLeave`
  - registers `<Plug>(last-win-jump-toggle)`
- `lua/last-win-jump/init.lua`
  - public Lua API and window history state
- `lua/last-win-jump/health.lua`
  - `:checkhealth last-win-jump`
- `doc/last-win-jump.txt`
  - vim help doc; keep in sync with user-visible behavior
- `README.md`
  - user-facing overview and examples
- `tests/`
  - headless Neovim acceptance tests
- `justfile`
  - development commands for format, lint, and test
- `selene.toml` / `vim.yml`
  - Selene lint configuration and project-local Neovim globals

## Current behavior snapshot

- `WinLeave` records trackable windows.
- Trackable windows are:
  - normal windows
  - focusable floating windows, such as `snacks.nvim` explorer
- Non-focusable floating/popup windows are ignored.
- The plugin keeps a small history of recent windows.
- `jump()` skips:
  - closed windows
  - the current window
- `jump()` records the current window before jumping so repeated presses toggle back.

## Public surface

`<Plug>` mappings:

- normal: `<Plug>(last-win-jump-toggle)`

Lua API:

- `require('last-win-jump').jump()`

Internal/test-facing API:

- `_record(win)`

## Working rules

- Use 2 spaces for indentation.
- Keep edits minimal and targeted.
- Do not add default user mappings; expose `<Plug>` mappings only.
- Keep plugin startup light.
- If changing user-visible behavior, update both:
  - `README.md`
  - `doc/last-win-jump.txt`
- If changing behavior around floating windows, update tests.

## Commands

Useful validation commands. These expect `just`, `selene`, and `stylua` to be available:

```sh
just test   # headless Neovim acceptance tests
just lint   # Selene + Lua syntax checks
just check  # fmt-check + lint + test
```

Format changed Lua files:

```sh
just fmt
```

## Safety / ask first

Ask before doing any of the following:

- changing the plugin name or `<Plug>` mapping name
- adding default mappings
- introducing new runtime dependencies
- large refactors unrelated to the requested task
