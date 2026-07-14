---@class win-buf-op
---@field _record fun(win: integer)
---@field close_extended_window fun()
---@field history fun(): integer[]
---@field jump fun()
---@field last_edit_window fun(): integer|nil
---@field last_extended_window fun(): integer|nil
---@field next_buffer fun()
---@field previous_buffer fun()
local M = {}

local HISTORY_LIMIT = 20

---Most recently visited jump candidates.
---@type integer[]
local history = {}

---@param win integer
local function remove_from_history(win)
  for i = #history, 1, -1 do
    if history[i] == win then
      table.remove(history, i)
    end
  end
end

---Return whether a window should be tracked as a jump target.
---@param win integer
---@return boolean
local function should_track(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local cfg = vim.api.nvim_win_get_config(win)
  if not cfg.relative or cfg.relative == '' then
    return true
  end

  -- Focusable floating windows are intentional UI surfaces, such as
  -- snacks.nvim explorer. Non-focusable popups should not affect jump history.
  return cfg.focusable ~= false
end

---Record a window as the last-window, called from the WinLeave autocommand.
---@param win integer
function M._record(win)
  if not should_track(win) then
    return
  end

  remove_from_history(win)
  history[#history + 1] = win

  while #history > HISTORY_LIMIT do
    table.remove(history, 1)
  end
end

---Return whether a window contains an extended buffer.
---@param win integer
---@return boolean
local function is_extended(win)
  return vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= ''
end

local function remove_invalid_windows()
  for i = #history, 1, -1 do
    if not vim.api.nvim_win_is_valid(history[i]) then
      table.remove(history, i)
    end
  end
end

---@param extended boolean
---@return integer|nil
local function last_window_of_type(extended)
  for i = #history, 1, -1 do
    local win = history[i]
    if not vim.api.nvim_win_is_valid(win) then
      table.remove(history, i)
    elseif is_extended(win) == extended then
      return win
    end
  end
end

---Return a copy of the valid recorded window history, ordered oldest to newest.
---@return integer[]
function M.history()
  remove_invalid_windows()

  local snapshot = {}
  for i, win in ipairs(history) do
    snapshot[i] = win
  end
  return snapshot
end

---Record the current editing window when applicable, then return the latest one.
---@return integer|nil
function M.last_edit_window()
  local current_win = vim.api.nvim_get_current_win()
  if should_track(current_win) and not is_extended(current_win) then
    M._record(current_win)
  end
  return last_window_of_type(false)
end

---Return the most recently recorded valid extended window.
---@return integer|nil
function M.last_extended_window()
  return last_window_of_type(true)
end

---Close the current extended window, or the most recently recorded one.
function M.close_extended_window()
  local current_win = vim.api.nvim_get_current_win()
  local target_win

  if should_track(current_win) and is_extended(current_win) then
    target_win = current_win
  else
    target_win = last_window_of_type(true)
  end

  if not target_win then
    return
  end

  local ok = pcall(vim.api.nvim_win_close, target_win, false)
  if ok or not vim.api.nvim_win_is_valid(target_win) then
    remove_from_history(target_win)
  end
end

local function goto_edit_window()
  local target_win = M.last_edit_window()
  if target_win and pcall(vim.api.nvim_set_current_win, target_win) then
    return
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if should_track(win) and not is_extended(win) then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  vim.cmd 'rightbelow vsplit'
  vim.cmd 'enew'
end

---@param command string
local function navigate_buffer(command)
  local current_win = vim.api.nvim_get_current_win()
  if should_track(current_win) and is_extended(current_win) then
    goto_edit_window()
  end

  local ok, err = pcall(vim.cmd, command .. '!')
  if not ok then
    if tostring(err):match 'E85' then
      vim.notify('win-buf-op: no listed buffer', vim.log.levels.WARN)
      return
    end
    error(err)
  end
end

---Switch to the next listed buffer, leaving an extended window first.
function M.next_buffer()
  navigate_buffer 'bnext'
end

---Switch to the previous listed buffer, leaving an extended window first.
function M.previous_buffer()
  navigate_buffer 'bprevious'
end

---@param current_win integer
---@return integer|nil
local function next_target(current_win)
  local current_is_extended = is_extended(current_win)

  for i = #history, 1, -1 do
    local win = history[i]
    if not vim.api.nvim_win_is_valid(win) or win == current_win then
      table.remove(history, i)
    elseif is_extended(win) ~= current_is_extended then
      return win
    end
  end
end

---Jump to the most recently visited window with the opposing buffer type.
---Closed windows and the current window are skipped.
function M.jump()
  local current_win = vim.api.nvim_get_current_win()
  local target_win = next_target(current_win)

  if not target_win then
    return
  end

  -- Record the current window before jumping. This makes explicit toggles work
  -- from focusable floating windows such as snacks.nvim explorer, while the
  -- history fallback still skips transient pickers that have already closed.
  M._record(current_win)

  local ok = pcall(vim.api.nvim_set_current_win, target_win)
  if not ok then
    remove_from_history(target_win)
  end
end

return M
