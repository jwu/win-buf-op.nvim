---@class win-buf-op
---@field _record fun(win: integer)
---@field jump fun()
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

---@param current_win integer
---@return integer|nil
local function next_target(current_win)
  for i = #history, 1, -1 do
    local win = history[i]
    if not vim.api.nvim_win_is_valid(win) or win == current_win then
      table.remove(history, i)
    else
      return win
    end
  end
end

---Jump to the last-window.
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
