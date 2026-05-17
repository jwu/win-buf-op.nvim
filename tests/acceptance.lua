-- Acceptance test: plugin autoload, <Plug> mapping, and user mapping all work together.

local function assert_equal(actual, expected, message)
  local error_message = string.format('%s: expected %s, got %s', message, expected, actual)
  assert(actual == expected, error_message)
end

local function reset_module()
  package.loaded['last-win-jump'] = nil
  return require('last-win-jump')
end

local plug_map = vim.fn.maparg('<Plug>(last-win-jump-toggle)', 'n')
assert(plug_map ~= '', '<Plug>(last-win-jump-toggle) should be registered')

local last_win_jump = reset_module()
vim.cmd('silent! only')
local current = vim.api.nvim_get_current_win()
last_win_jump.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  current,
  'jump should do nothing when no window has been recorded'
)

vim.keymap.set('n', '<leader><Tab>', '<Plug>(last-win-jump-toggle)')

vim.cmd('silent! tabonly')
vim.cmd('vsplit')

local wins = vim.api.nvim_list_wins()
local last_win = wins[1]
local current_win = wins[2]

vim.api.nvim_set_current_win(current_win)
vim.fn.feedkeys('\\\t', 'xt')

assert_equal(
  vim.api.nvim_get_current_win(),
  last_win,
  '<leader><Tab> should jump to last window'
)

vim.cmd('silent! only')

local normal_win = vim.api.nvim_get_current_win()
local buf = vim.api.nvim_create_buf(false, true)
local floating_win = vim.api.nvim_open_win(buf, true, {
  relative = 'editor',
  row = 1,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
})

-- Simulate selecting a file from a focusable floating explorer: focus moves back
-- to the edit window without invoking last-win-jump directly.
vim.api.nvim_set_current_win(normal_win)
vim.fn.feedkeys('\\\t', 'xt')
assert_equal(
  vim.api.nvim_get_current_win(),
  floating_win,
  '<leader><Tab> should jump back to focusable floating window'
)

vim.fn.feedkeys('\\\t', 'xt')
assert_equal(
  vim.api.nvim_get_current_win(),
  normal_win,
  '<leader><Tab> should jump from floating window to normal window'
)

if vim.api.nvim_win_is_valid(floating_win) then
  vim.api.nvim_win_close(floating_win, true)
end

last_win_jump = reset_module()
vim.cmd('silent! only')
vim.cmd('vsplit')
local closed_win = vim.api.nvim_get_current_win()
last_win_jump._record(closed_win)
vim.api.nvim_win_close(closed_win, true)
current = vim.api.nvim_get_current_win()
last_win_jump.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  current,
  'jump should do nothing when only the recorded window has been closed'
)

last_win_jump = reset_module()
vim.cmd('silent! only')
normal_win = vim.api.nvim_get_current_win()
buf = vim.api.nvim_create_buf(false, true)
floating_win = vim.api.nvim_open_win(buf, false, {
  relative = 'editor',
  row = 1,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
  focusable = false,
})
last_win_jump._record(floating_win)
last_win_jump.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  normal_win,
  'jump should ignore non-focusable floating windows'
)

if vim.api.nvim_win_is_valid(floating_win) then
  vim.api.nvim_win_close(floating_win, true)
end

-- A transient focusable picker may be recorded and then close itself. In that
-- case, jump should skip the closed window and use the previous valid target.
last_win_jump = reset_module()

vim.cmd('silent! only')
vim.cmd('vsplit')
local split_wins = vim.api.nvim_list_wins()
local fallback_win = split_wins[1]
local current_split_win = split_wins[2]
vim.api.nvim_set_current_win(current_split_win)

last_win_jump._record(fallback_win)
local transient_buf = vim.api.nvim_create_buf(false, true)
local transient_win = vim.api.nvim_open_win(transient_buf, true, {
  relative = 'editor',
  row = 1,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
})
last_win_jump._record(transient_win)
vim.api.nvim_win_close(transient_win, true)
vim.api.nvim_set_current_win(current_split_win)

last_win_jump.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  fallback_win,
  'jump should skip closed transient windows and use previous valid target'
)

print('ACCEPTANCE CHECKS PASSED')
