# AGENTS.md

## Project

This repository is `win-buf-op.nvim`, a small Neovim plugin written in Lua for toggling between the current window and the last visited window.

The project targets:

- Neovim Lua plugin conventions
- small, focused changes
- no required `setup()` call
- `<Plug>` mappings for user keybindings

## Key structure

- `plugin/win-buf-op.lua`
  - auto-loaded plugin entry
  - tracks windows via `WinLeave`
  - registers `<Plug>(win-buf-op-jump)`
- `lua/win-buf-op/init.lua`
  - public Lua API and window history state
- `lua/win-buf-op/health.lua`
  - `:checkhealth win-buf-op`
- `doc/win-buf-op.txt`
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

- normal: `<Plug>(win-buf-op-jump)`

Lua API:

- `require('win-buf-op').jump()`

Internal/test-facing API:

- `_record(win)`

## Working rules

- Use 2 spaces for indentation.
- Keep edits minimal and targeted.
- Do not add default user mappings; expose `<Plug>` mappings only.
- Keep plugin startup light.
- If changing user-visible behavior, update both:
  - `README.md`
  - `doc/win-buf-op.txt`
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
