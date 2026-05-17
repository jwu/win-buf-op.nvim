-- Auto-load: track the last window and expose <Plug> mapping.

local group = vim.api.nvim_create_augroup('LastWinJump', { clear = true })

---Record the previous window when leaving a trackable window.
---Focusable floating windows, such as snacks.nvim explorer, are tracked.
---Non-focusable popups are ignored to avoid disrupting workflows.
vim.api.nvim_create_autocmd('WinLeave', {
  group = group,
  desc = 'Record last trackable window for last-win-jump.nvim',
  callback = function()
    require('last-win-jump')._record(vim.api.nvim_get_current_win())
  end,
})

---<Plug> mapping: toggle between the current window and the last-window.
---Map it in your config, e.g.:
---  vim.keymap.set('n', '<leader><Tab>', '<Plug>(last-win-jump-toggle)')
vim.keymap.set('n', '<Plug>(last-win-jump-toggle)', function()
  require('last-win-jump').jump()
end, { desc = 'last-win-jump: toggle between current and last window' })
