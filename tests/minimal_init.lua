-- minimal_init.lua — minimal Neovim config for headless acceptance tests.

-- Add the plugin root to runtimepath.
vim.cmd('set rtp+=' .. vim.fn.getcwd())
