-- health.lua — :checkhealth integration for last-win-jump.nvim

local M = {}

local health = vim.health or {}
local health_start = health.start or health.report_start
local health_ok = health.ok or health.report_ok
local health_warn = health.warn or health.report_warn

function M.check()
  health_start('last-win-jump.nvim')

  local ok, mod = pcall(require, 'last-win-jump')
  if not ok then
    health_warn('failed to load last-win-jump module: ' .. tostring(mod))
    return
  end

  if type(mod.jump) == 'function' and type(mod._record) == 'function' then
    health_ok('module loaded: jump() and _record() available')
  else
    health_warn('module loaded but API mismatch')
  end

  -- Check if <Plug> mapping exists
  local map = vim.fn.maparg('<Plug>(last-win-jump-toggle)', 'n')
  if map and map ~= '' then
    health_ok('<Plug>(last-win-jump-toggle) mapping is registered')
  else
    health_warn('<Plug>(last-win-jump-toggle) mapping not found — is plugin loaded?')
  end

  -- Check if augroup exists
  if vim.fn.exists('#LastWinJump#WinLeave') == 1 then
    health_ok('LastWinJump autocommand is active')
  else
    health_warn('LastWinJump augroup not found')
  end
end

return M
