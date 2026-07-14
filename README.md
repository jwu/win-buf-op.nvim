# win-buf-op.nvim

A Neovim plugin for switching between editing windows and extended windows.

It tracks normal windows and focusable floating windows, such as a
`snacks.nvim` explorer, while ignoring non-focusable popup windows. A buffer
with an empty `buftype` is an editing window; any other buffer is an extended
window.

## Features

- Toggle to the most recently visited window of the opposite type
- Close the current extended window, or the most recently visited one
- Navigate listed buffers from an extended window through the last edit window
- Switch to the alternate edit buffer and restore its recorded cursor position
- Track focusable floating windows and ignore transient non-focusable popups
- Skip closed windows and fall back to a previous valid target
- `<Plug>` mappings for custom keybindings
- `:checkhealth win-buf-op` support

## Requirements

- Neovim 0.10+

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'jwu/win-buf-op.nvim',
  lazy = false,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use { 'jwu/win-buf-op.nvim' }
```

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'jwu/win-buf-op.nvim'
```

For local development with lazy.nvim:

```lua
{
  dir = '~/dev/jwu/win-buf-op.nvim',
  name = 'win-buf-op.nvim',
  lazy = false,
}
```

## Usage

The plugin has no required `setup()` call and defines no default keybindings.
Use its `<Plug>` mappings to choose your own keys.

### Toggle windows

`<Plug>(win-buf-op-jump)` switches to the latest visited window with the
opposite buffer type. Repeating it toggles back. Closed windows, the current
window, and non-focusable popups are skipped.

### Close an extended window

`<Plug>(win-buf-op-close-ext)` closes the current extended window. From an
editing window, it closes the latest valid extended window instead. It does not
force-close modified buffers.

### Navigate buffers

`<Plug>(win-buf-op-bnext)` and `<Plug>(win-buf-op-bprev)` navigate Vim's listed
buffers with `:bnext!` and `:bprevious!`. From an extended window, they first
move to the latest editing window.

`<Plug>(win-buf-op-balt)` switches to the native alternate edit buffer and
restores its last recorded cursor position. It is available only from an editing
window; if no native alternate buffer is available, it wraps through listed
buffers.

## Custom keybindings

```lua
vim.keymap.set('n', '<leader><Tab>', '<Plug>(win-buf-op-jump)')
vim.keymap.set('n', '<leader><Esc>', '<Plug>(win-buf-op-close-ext)')
vim.keymap.set('n', '<C-l>', '<Plug>(win-buf-op-bnext)')
vim.keymap.set('n', '<C-h>', '<Plug>(win-buf-op-bprev)')
vim.keymap.set('n', '<C-Tab>', '<Plug>(win-buf-op-balt)')
```

Available `<Plug>` mappings:

| Mapping | Mode | Description |
|---------|------|-------------|
| `<Plug>(win-buf-op-jump)` | Normal | Toggle to the latest window of the opposite type |
| `<Plug>(win-buf-op-close-ext)` | Normal | Close the current or latest extended window |
| `<Plug>(win-buf-op-bnext)` | Normal | Go to the next listed buffer |
| `<Plug>(win-buf-op-bprev)` | Normal | Go to the previous listed buffer |
| `<Plug>(win-buf-op-balt)` | Normal | Go to the alternate edit buffer |

## Lua API

```lua
local win_buf_op = require('win-buf-op')

win_buf_op.jump()
win_buf_op.close_extended_window()
win_buf_op.next_buffer()
win_buf_op.previous_buffer()
win_buf_op.alternate_buffer()

local last_edit_win = win_buf_op.last_edit_window()
local last_extended_win = win_buf_op.last_extended_window()
local recorded_wins = win_buf_op.history() -- oldest to newest
```

API notes:

- `last_edit_window()` records the current trackable editing window, then returns the latest valid recorded editing window ID.
- `last_extended_window()` returns the latest valid recorded extended window ID, or `nil`.
- `history()` returns an independent snapshot of valid recorded window IDs, ordered from oldest to newest.

## Health check

Run:

```vim
:checkhealth win-buf-op
```

## Development

Development tasks are defined in `justfile`. They expect `just`, `selene`, and
`stylua` to be installed.

```sh
just test      # headless Neovim acceptance tests
just lint      # selene + Lua syntax checks
just check     # fmt-check + lint + test
just fmt       # format Lua files
```

## Documentation

See `:help win-buf-op` for full vimdoc.
