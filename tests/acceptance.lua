-- Acceptance test: plugin autoload, <Plug> mapping, and user mapping all work together.

local function assert_equal(actual, expected, message)
  local error_message = string.format('%s: expected %s, got %s', message, expected, actual)
  assert(actual == expected, error_message)
end

local function reset_module()
  package.loaded['win-buf-op'] = nil
  return require 'win-buf-op'
end

local plug_map = vim.fn.maparg('<Plug>(win-buf-op-toggle)', 'n')
assert(plug_map ~= '', '<Plug>(win-buf-op-toggle) should be registered')

local win_buf_op = reset_module()
vim.cmd 'silent! only'
local current = vim.api.nvim_get_current_win()
win_buf_op.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  current,
  'jump should do nothing when no window has been recorded'
)

vim.keymap.set('n', '<leader><Tab>', '<Plug>(win-buf-op-toggle)')

vim.cmd 'silent! tabonly'
vim.cmd 'vsplit'

local wins = vim.api.nvim_list_wins()
local last_win = wins[1]
local current_win = wins[2]

vim.api.nvim_set_current_win(current_win)
vim.fn.feedkeys('\\\t', 'xt')

assert_equal(vim.api.nvim_get_current_win(), last_win, '<leader><Tab> should jump to last window')

vim.cmd 'silent! only'

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
-- to the edit window without invoking win-buf-op directly.
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

win_buf_op = reset_module()
vim.cmd 'silent! only'
vim.cmd 'vsplit'
local closed_win = vim.api.nvim_get_current_win()
win_buf_op._record(closed_win)
vim.api.nvim_win_close(closed_win, true)
current = vim.api.nvim_get_current_win()
win_buf_op.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  current,
  'jump should do nothing when only the recorded window has been closed'
)

win_buf_op = reset_module()
vim.cmd 'silent! only'
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
win_buf_op._record(floating_win)
win_buf_op.jump()
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
win_buf_op = reset_module()

vim.cmd 'silent! only'
vim.cmd 'vsplit'
local split_wins = vim.api.nvim_list_wins()
local fallback_win = split_wins[1]
local current_split_win = split_wins[2]
vim.api.nvim_set_current_win(current_split_win)

win_buf_op._record(fallback_win)
local transient_buf = vim.api.nvim_create_buf(false, true)
local transient_win = vim.api.nvim_open_win(transient_buf, true, {
  relative = 'editor',
  row = 1,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
})
win_buf_op._record(transient_win)
vim.api.nvim_win_close(transient_win, true)
vim.api.nvim_set_current_win(current_split_win)

win_buf_op.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  fallback_win,
  'jump should skip closed transient windows and use previous valid target'
)

print 'ACCEPTANCE CHECKS PASSED'
