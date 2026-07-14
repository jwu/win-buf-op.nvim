-- Acceptance test: plugin autoload, public API, <Plug> mapping, and user mapping work together.

local function assert_equal(actual, expected, message)
  local error_message = string.format('%s: expected %s, got %s', message, expected, actual)
  assert(actual == expected, error_message)
end

local function reset_module()
  package.loaded['win-buf-op'] = nil
  return require 'win-buf-op'
end

local jump_plug_map = vim.fn.maparg('<Plug>(win-buf-op-jump)', 'n')
assert(jump_plug_map ~= '', '<Plug>(win-buf-op-jump) should be registered')

local close_ext_plug_map = vim.fn.maparg('<Plug>(win-buf-op-close-ext)', 'n')
assert(close_ext_plug_map ~= '', '<Plug>(win-buf-op-close-ext) should be registered')

local bnext_plug_map = vim.fn.maparg('<Plug>(win-buf-op-bnext)', 'n')
assert(bnext_plug_map ~= '', '<Plug>(win-buf-op-bnext) should be registered')

local bprev_plug_map = vim.fn.maparg('<Plug>(win-buf-op-bprev)', 'n')
assert(bprev_plug_map ~= '', '<Plug>(win-buf-op-bprev) should be registered')

local win_buf_op = reset_module()
vim.cmd 'silent! only'
local current = vim.api.nvim_get_current_win()
win_buf_op.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  current,
  'jump should do nothing when no window has been recorded'
)

vim.keymap.set('n', '<leader><Tab>', '<Plug>(win-buf-op-jump)')

win_buf_op = reset_module()
vim.cmd 'silent! only'
local api_edit_win = vim.api.nvim_get_current_win()
local api_extended_buf = vim.api.nvim_create_buf(false, true)
vim.bo[api_extended_buf].buftype = 'nofile'
local api_extended_win = vim.api.nvim_open_win(api_extended_buf, false, {
  relative = 'editor',
  row = 1,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
})
win_buf_op._record(api_extended_win)
assert_equal(
  win_buf_op.last_edit_window(),
  api_edit_win,
  'last_edit_window should record and return the current edit window'
)
assert_equal(
  win_buf_op.last_extended_window(),
  api_extended_win,
  'last_extended_window should return the most recent valid extended window'
)

local api_history = win_buf_op.history()
assert_equal(#api_history, 2, 'history should return all valid recorded windows')
assert_equal(api_history[1], api_extended_win, 'history should be ordered from oldest to newest')
api_history[1] = api_edit_win
assert_equal(
  win_buf_op.history()[1],
  api_extended_win,
  'history should return a copy rather than the internal history table'
)

vim.api.nvim_win_close(api_extended_win, true)
assert_equal(
  win_buf_op.last_extended_window(),
  nil,
  'last_extended_window should discard closed windows'
)
assert_equal(#win_buf_op.history(), 1, 'history should discard closed windows')

win_buf_op = reset_module()
vim.cmd 'silent! only'
local edit_before_close = vim.api.nvim_get_current_win()
local fallback_extended_buf = vim.api.nvim_create_buf(false, true)
vim.bo[fallback_extended_buf].buftype = 'nofile'
local fallback_extended_win = vim.api.nvim_open_win(fallback_extended_buf, false, {
  relative = 'editor',
  row = 1,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
})
win_buf_op._record(fallback_extended_win)

local current_extended_buf = vim.api.nvim_create_buf(false, true)
vim.bo[current_extended_buf].buftype = 'nofile'
local current_extended_win = vim.api.nvim_open_win(current_extended_buf, true, {
  relative = 'editor',
  row = 5,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
})
vim.keymap.set('n', '<leader><Esc>', '<Plug>(win-buf-op-close-ext)')
vim.fn.feedkeys('\\\027', 'xt')
assert_equal(
  vim.api.nvim_win_is_valid(current_extended_win),
  false,
  '<leader><Esc> should close the current extended window first'
)
assert_equal(
  vim.api.nvim_win_is_valid(fallback_extended_win),
  true,
  'close_extended_window should preserve older extended windows when current closes'
)

vim.api.nvim_set_current_win(edit_before_close)
win_buf_op.close_extended_window()
assert_equal(
  vim.api.nvim_win_is_valid(fallback_extended_win),
  false,
  'close_extended_window should close the last recorded extension from an edit window'
)

win_buf_op = reset_module()
vim.cmd 'silent! only'
local buffer_nav_edit_win = vim.api.nvim_get_current_win()
vim.api.nvim_create_buf(true, false)
local next_extended_buf = vim.api.nvim_create_buf(false, true)
vim.bo[next_extended_buf].buftype = 'nofile'
local next_extended_win = vim.api.nvim_open_win(next_extended_buf, true, {
  relative = 'editor',
  row = 1,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
})
win_buf_op.next_buffer()
assert_equal(
  vim.api.nvim_get_current_win(),
  buffer_nav_edit_win,
  'next_buffer should return to the last edit window before navigating buffers'
)

local previous_extended_buf = vim.api.nvim_create_buf(false, true)
vim.bo[previous_extended_buf].buftype = 'nofile'
local previous_extended_win = vim.api.nvim_open_win(previous_extended_buf, true, {
  relative = 'editor',
  row = 5,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
})
win_buf_op.previous_buffer()
assert_equal(
  vim.api.nvim_get_current_win(),
  buffer_nav_edit_win,
  'previous_buffer should return to the last edit window before navigating buffers'
)

for _, win in ipairs({ next_extended_win, previous_extended_win }) do
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

win_buf_op = reset_module()
vim.cmd 'silent! tabonly'
vim.cmd 'silent! only'
local edit_win = vim.api.nvim_get_current_win()
vim.cmd 'copen'
local extended_win = vim.api.nvim_get_current_win()

vim.fn.feedkeys('\\\t', 'xt')
assert_equal(
  vim.api.nvim_get_current_win(),
  edit_win,
  '<leader><Tab> should jump from an extended window to the last edit window'
)

vim.fn.feedkeys('\\\t', 'xt')
assert_equal(
  vim.api.nvim_get_current_win(),
  extended_win,
  '<leader><Tab> should jump from an edit window to the last extended window'
)

vim.cmd 'silent! cclose'

win_buf_op = reset_module()
vim.cmd 'silent! only'
vim.cmd 'vsplit'
local normal_wins = vim.api.nvim_list_wins()
local normal_current = normal_wins[2]
win_buf_op._record(normal_wins[1])
vim.api.nvim_set_current_win(normal_current)
win_buf_op.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  normal_current,
  'jump should do nothing when history contains only edit windows'
)

vim.cmd 'silent! only'

local normal_win = vim.api.nvim_get_current_win()
local buf = vim.api.nvim_create_buf(false, true)
vim.bo[buf].buftype = 'nofile'
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

-- A transient focusable extension may be recorded and then close itself. In
-- that case, jump should skip it and use the previous valid extended window.
win_buf_op = reset_module()

vim.cmd 'silent! only'
normal_win = vim.api.nvim_get_current_win()
local fallback_buf = vim.api.nvim_create_buf(false, true)
vim.bo[fallback_buf].buftype = 'nofile'
local fallback_win = vim.api.nvim_open_win(fallback_buf, false, {
  relative = 'editor',
  row = 1,
  col = 1,
  width = 20,
  height = 3,
  style = 'minimal',
})
win_buf_op._record(fallback_win)

local transient_buf = vim.api.nvim_create_buf(false, true)
vim.bo[transient_buf].buftype = 'nofile'
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
vim.api.nvim_set_current_win(normal_win)

win_buf_op.jump()
assert_equal(
  vim.api.nvim_get_current_win(),
  fallback_win,
  'jump should skip a closed transient extension and use the previous valid extension'
)

print 'ACCEPTANCE CHECKS PASSED'
