-- health.lua - :checkhealth integration for win-buf-op.nvim

local M = {}

local health = vim.health or {}
local health_start = health.start or health.report_start
local health_ok = health.ok or health.report_ok
local health_warn = health.warn or health.report_warn

function M.check()
  health_start 'win-buf-op.nvim'

  local ok, mod = pcall(require, 'win-buf-op')
  if not ok then
    health_warn('failed to load win-buf-op module: ' .. tostring(mod))
    return
  end

  if
    type(mod.history) == 'function'
    and type(mod.jump) == 'function'
    and type(mod.last_edit_window) == 'function'
    and type(mod.last_extended_window) == 'function'
    and type(mod._record) == 'function'
  then
    health_ok 'module loaded: public API and _record() available'
  else
    health_warn 'module loaded but API mismatch'
  end

  -- Check if <Plug> mapping exists
  local map = vim.fn.maparg('<Plug>(win-buf-op-jump)', 'n')
  if map and map ~= '' then
    health_ok '<Plug>(win-buf-op-jump) mapping is registered'
  else
    health_warn '<Plug>(win-buf-op-jump) mapping not found - is plugin loaded?'
  end

  -- Check if augroup exists
  if vim.fn.exists '#WinBufOp#WinLeave' == 1 then
    health_ok 'WinBufOp autocommand is active'
  else
    health_warn 'WinBufOp augroup not found'
  end
end

return M
