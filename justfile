lua_dirs := 'lua plugin tests'

_default:
  @just --list

fmt:
  @command -v stylua >/dev/null || { echo 'stylua is required'; exit 127; }
  stylua {{lua_dirs}}

fmt-check:
  @command -v stylua >/dev/null || { echo 'stylua is required'; exit 127; }
  stylua --check {{lua_dirs}}

lint:
  @command -v selene >/dev/null || { echo 'selene is required'; exit 127; }
  selene {{lua_dirs}}
  lua -e "assert(loadfile('lua/win-buf-op/init.lua')); assert(loadfile('plugin/win-buf-op.lua'))"

test:
  nvim --headless -u NONE -c "set rtp+=." -c "lua require('win-buf-op').jump()" -c "qa!"
  nvim --headless -u tests/minimal_init.lua -c "runtime plugin/win-buf-op.lua" -c "luafile tests/acceptance.lua" -c "qa!"

check: fmt-check lint test
