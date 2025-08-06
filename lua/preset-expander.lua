-- Save this file as: ~/.config/nvim/lua/preset_expander.lua

local M = {}

--[[
  ==============================================================================
  Configuration
  ==============================================================================
  You can change the directory where your presets are stored.
  The default is '~/.config/nvim/presets'.
--]]
local config = {
  -- VIM-PATCH: Explicitly expand the path to handle '~' correctly.
  -- This makes path resolution more robust.
  presets_dir = vim.fn.expand(vim.fn.stdpath('config') .. '/presets')
}

--- Reads the content of a file.
--- @param path string The full path to the file.
--- @return string|nil The file content, or nil if an error occurs.
local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  io.close(file)
  return content
end

--- Splits a string into a table of lines, handling various line endings.
--- @param str string The input string.
--- @return table A table of strings, one for each line.
local function split_into_lines(str)
  local lines = {}
  -- Normalize line endings to \n
  str = str:gsub('\r\n', '\n'):gsub('\r', '\n')
  str = str:gsub('\n$', '')
  for line in str:gmatch("([^\n]*)") do
    line:sub(1, -3)
    --print(line)
    table.insert(lines, line)
  end
  return lines
end

--- Main function to expand the preset.
function M.expand()
  -- 1. Get the keyword under the cursor.
  local keyword = vim.fn.expand('<cword>')
  if keyword == '' then
    vim.notify("PresetExpand: No keyword under cursor.", vim.log.levels.WARN)
    return
  end

  -- 2. Ensure the presets directory exists.
  local preset_dir = config.presets_dir
  if vim.fn.isdirectory(preset_dir) == 0 then
    vim.notify("PresetExpand: Presets directory not found at: " .. preset_dir, vim.log.levels.ERROR)
    local choice = vim.fn.input("Presets directory does not exist. Create it? [y/N]: ")
    if choice:lower() == 'y' then
      vim.fn.mkdir(preset_dir, 'p')
      vim.notify("PresetExpand: Created directory: " .. preset_dir, vim.log.levels.INFO)
    else
      vim.notify("PresetExpand: Aborted.", vim.log.levels.WARN)
      return
    end
  end

  -- 3. Find the preset file. The filename must match the keyword exactly.
  local preset_path = preset_dir .. '/' .. keyword
  if vim.fn.filereadable(preset_path) ~= 1 then
    vim.notify("PresetExpand: Preset not found for keyword: '" .. keyword .. "'", vim.log.levels.WARN)
    vim.notify("PresetExpand: Looked for: " .. preset_path, vim.log.levels.INFO)
    return
  end

  -- 4. Read the preset file content.
  local content = read_file(preset_path)
  if not content then
    vim.notify("PresetExpand: Could not read preset file: " .. preset_path, vim.log.levels.ERROR)
    return
  end

  -- 5. Get the position of the keyword to replace it.
  local lnum, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  lnum = lnum - 1 -- convert to 0-indexed
  local line_content = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1]

  -- Find the specific instance of the keyword the cursor is on using word boundaries.
  local start_col, end_col
  local pattern = vim.pesc(keyword)
  local current_pos = math.max(1, cursor_col+1-#keyword)
  local flag = true
  while #line_content >= current_pos+#keyword-1 do
    temp = match(keyword, string.sub(line_content, current_pos, current_pos+#keyword-1))
    if temp then
      if #keyword == #temp then
        flag = true
        break
      end
    end
  end

  --local s, e = string.find(line_content, pattern, current_pos)

  if not flag then
    vim.notify("PresetExpand: Could not locate keyword '" .. keyword .. "' under cursor.", vim.log.levels.ERROR)
    return
  end
  start_col = current_pos - 1 -- 0-indexed start
  end_col = current_pos+#keyword-1       -- 0-indexed end

  -- 6. Prepare the replacement text, preserving indentation.
  local new_lines = split_into_lines(content)
  local indent = string.match(line_content, "^%s*") or ""

  -- The first line of the snippet replaces the keyword and should not get extra indent.
  -- Subsequent lines should be indented relative to the keyword's line.
  if #new_lines > 1 then
    for i = 2, #new_lines do
      if new_lines[i] ~= '' then
        new_lines[i] = indent .. new_lines[i]
      end
    end
  end

  -- 7. Perform the replacement in the buffer.
  vim.api.nvim_buf_set_text(
    0,           -- buffer handle (0 for current)
    lnum,        -- start row (0-indexed)
    start_col,   -- start col (0-indexed)
    lnum,        -- end row
    end_col,     -- end col
    new_lines    -- table of replacement lines
  )

  vim.notify("PresetExpand: Expanded '" .. keyword .. "'", vim.log.levels.INFO)
end

return M

