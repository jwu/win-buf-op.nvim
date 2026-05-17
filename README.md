# last-win-jump.nvim

A tiny Neovim plugin for jumping back to the last visited window.

It tracks normal windows and focusable floating windows, so it works with UI surfaces like `snacks.nvim` explorer while ignoring non-focusable popup windows.

## Features

- Toggle between the current window and the last visited window
- Tracks focusable floating windows such as `snacks.nvim` explorer
- Skips closed windows and falls back to the previous valid window
- Ignores non-focusable popups such as transient hover/completion windows
- Provides a `<Plug>` mapping for user-defined keybindings
- Provides `:checkhealth last-win-jump`

## Requirements

- Neovim 0.10+

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'jwu/last-win-jump.nvim',
  lazy = false,
  config = function()
    vim.keymap.set('n', '<leader><Tab>', '<Plug>(last-win-jump-toggle)', {
      desc = 'Toggle to last window',
    })
  end,
}
```

For local development:

```lua
{
  dir = '~/dev/jwu/last-win-jump.nvim',
  name = 'last-win-jump.nvim',
  lazy = false,
  config = function()
    vim.keymap.set('n', '<leader><Tab>', '<Plug>(last-win-jump-toggle)', {
      desc = 'Toggle to last window',
    })
  end,
}
```

## Usage

The plugin does not create a default keybinding. It exposes one `<Plug>` mapping for you to map:

```lua
vim.keymap.set('n', '<leader><Tab>', '<Plug>(last-win-jump-toggle)')
```

You can also call the Lua API directly:

```vim
:lua require('last-win-jump').jump()
```

## Health check

```vim
:checkhealth last-win-jump
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
