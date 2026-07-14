# win-buf-op.nvim

A tiny Neovim plugin for toggling between normal editing windows and extended windows.

It tracks normal windows and focusable floating windows, so it works with UI surfaces like `snacks.nvim` explorer while ignoring non-focusable popup windows. A buffer with an empty `buftype` is an editing window; every non-empty `buftype`, including `help`, `nofile`, `prompt`, `quickfix`, and `terminal`, is an extended window.

## Features

- Toggle between the current window and the most recently visited window of the opposite type
- Close the current extended window, or the most recently visited extended window
- Navigate listed buffers from an extended window through the last edit window
- Treats empty `buftype` buffers as editing windows and non-empty `buftype` buffers as extended windows
- Tracks focusable floating windows such as `snacks.nvim` explorer
- Skips closed windows and falls back to the previous valid window of the opposite type
- Ignores non-focusable popups such as transient hover/completion windows
- Provides a `<Plug>` mapping for user-defined keybindings
- Provides `:checkhealth win-buf-op`

## Requirements

- Neovim 0.10+

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'jwu/win-buf-op.nvim',
  lazy = false,
  config = function()
    vim.keymap.set('n', '<leader><Tab>', '<Plug>(win-buf-op-jump)', {
      desc = 'Toggle to last window',
    })
  end,
}
```

For local development:

```lua
{
  dir = '~/dev/jwu/win-buf-op.nvim',
  name = 'win-buf-op.nvim',
  lazy = false,
  config = function()
    vim.keymap.set('n', '<leader><Tab>', '<Plug>(win-buf-op-jump)', {
      desc = 'Toggle to last window',
    })
  end,
}
```

## Usage

The plugin does not create a default keybinding. It exposes one `<Plug>` mapping for you to map:

```lua
vim.keymap.set('n', '<leader><Tab>', '<Plug>(win-buf-op-jump)')
vim.keymap.set('n', '<leader><Esc>', '<Plug>(win-buf-op-close-ext)')
vim.keymap.set('n', '<C-l>', '<Plug>(win-buf-op-bnext)')
vim.keymap.set('n', '<C-h>', '<Plug>(win-buf-op-bprev)')
```

You can also call the Lua API directly:

```lua
local win_buf_op = require 'win-buf-op'

win_buf_op.jump()
win_buf_op.close_extended_window()
win_buf_op.next_buffer()
win_buf_op.previous_buffer()
local last_edit_win = win_buf_op.last_edit_window()
local last_extended_win = win_buf_op.last_extended_window()
local recorded_wins = win_buf_op.history() -- oldest to newest
```

`last_edit_window()` records the current trackable editing window, then returns
the latest valid recorded editing window ID. From another window type, it returns
the latest recorded editing window ID, or `nil` when none exists.
`last_extended_window()` returns the latest valid recorded extended window ID, or
`nil`. `close_extended_window()` closes the current trackable extended window,
or the latest valid recorded extended window when the current window is an edit
window. It does not force-close modified buffers. `next_buffer()` and
`previous_buffer()` use `:bnext!` and `:bprevious!`; from an extended window,
they first move to the latest edit window. `history()` returns an independent
snapshot of valid recorded window IDs, ordered from oldest to newest.

## Health check

```vim
:checkhealth win-buf-op
```

## Development

Development tasks are defined in `justfile`. Development commands expect `just`, `selene`, and `stylua` to be installed.

```sh
just test      # headless Neovim acceptance tests
just lint      # selene + Lua syntax checks
just check     # fmt-check + lint + test
```

Format Lua files with StyLua:

```sh
just fmt
```
