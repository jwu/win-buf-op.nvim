-- Auto-load: track the last window and expose <Plug> mapping.

local group = vim.api.nvim_create_augroup('WinBufOp', { clear = true })

---Record the previous window when leaving a trackable window.
---Focusable floating windows, such as snacks.nvim explorer, are tracked.
---Non-focusable popups are ignored to avoid disrupting workflows.
vim.api.nvim_create_autocmd('WinLeave', {
  group = group,
  desc = 'Record last trackable window for win-buf-op.nvim',
  callback = function()
    require('win-buf-op')._record(vim.api.nvim_get_current_win())
  end,
})

---<Plug> mapping: toggle between the current window and the latest opposite type.
---Map it in your config, e.g.:
---  vim.keymap.set('n', '<leader><Tab>', '<Plug>(win-buf-op-jump)')
vim.keymap.set('n', '<Plug>(win-buf-op-jump)', function()
  require('win-buf-op').jump()
end, { desc = 'win-buf-op: toggle to latest opposite window type' })
