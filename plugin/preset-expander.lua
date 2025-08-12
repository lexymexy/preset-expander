vim.api.nvim_create_user_command(
  'PresetExpand',
  function()
    require('preset-expander').expand()
  end,
  {
    nargs = 0,
    desc = 'Expands the keyword under the cursor using a preset file.'
  }
)

