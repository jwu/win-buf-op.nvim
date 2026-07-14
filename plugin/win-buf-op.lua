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

---<Plug> mapping: close the current or most recently recorded extended window.
---Map it in your config, e.g.:
---  vim.keymap.set('n', '<leader><Esc>', '<Plug>(win-buf-op-close-ext)')
vim.keymap.set('n', '<Plug>(win-buf-op-close-ext)', function()
  require('win-buf-op').close_extended_window()
end, { desc = 'win-buf-op: close extended window' })

---<Plug> mappings: navigate listed buffers from the active edit window.
---Map them in your config, e.g.:
---  vim.keymap.set('n', '<C-l>', '<Plug>(win-buf-op-bnext)')
---  vim.keymap.set('n', '<C-h>', '<Plug>(win-buf-op-bprev)')
vim.keymap.set('n', '<Plug>(win-buf-op-bnext)', function()
  require('win-buf-op').next_buffer()
end, { desc = 'win-buf-op: next buffer' })
vim.keymap.set('n', '<Plug>(win-buf-op-bprev)', function()
  require('win-buf-op').previous_buffer()
end, { desc = 'win-buf-op: previous buffer' })
