-- Save this file as: ~/.config/nvim/plugin/preset_expand.lua

-- This file is loaded automatically by Neovim and sets up the command.

vim.api.nvim_create_user_command(
  'PresetExpand',
  function()
    -- Calls the main function from your lua module
    require('preset_expander').expand()
  end,
  {
    nargs = 0,
    desc = 'Expands the keyword under the cursor using a preset file.'
  }
)

