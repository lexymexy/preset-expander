local M = {}

local config = {
  presets_dir = vim.fn.expand(vim.fn.stdpath('config') .. '/presets')
}

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  io.close(file)
  return content
end

local function split_into_lines(str)
  local lines = {}
  str = str:gsub('\r\n', '\n'):gsub('\r', '\n')
  str = str:gsub('\n$', '')
  for line in str:gmatch("([^\n]*)") do
    line:sub(1, -3)
    if not (#line == 0) then
      table.insert(lines, line)
    end
  end
  return lines
end

--- Main function to expand the preset.
function M.expand()
  local keyword = vim.fn.expand('<cword>')
  if keyword == '' then
    vim.notify("PresetExpand: No keyword under cursor.", vim.log.levels.WARN)
    return
  end

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

  local preset_path = preset_dir .. '/' .. keyword
  if vim.fn.filereadable(preset_path) ~= 1 then
    vim.notify("PresetExpand: Preset not found for keyword: '" .. keyword .. "'", vim.log.levels.WARN)
    vim.notify("PresetExpand: Looked for: " .. preset_path, vim.log.levels.INFO)
    return
  end

  local content = read_file(preset_path)
  if not content then
    vim.notify("PresetExpand: Could not read preset file: " .. preset_path, vim.log.levels.ERROR)
    return
  end

  local lnum, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  lnum = lnum - 1 -- convert to 0-indexed
  local line_content = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1]

  -- Find the specific instance of the keyword the cursor is on using word boundaries.
  local start_col, end_col
  local pattern = vim.pesc(keyword)
  local current_pos = math.max(1, cursor_col+1-#keyword)
  local flag = true
  while #line_content >= current_pos+#keyword-1 do
    temp = string.match(keyword, string.sub(line_content, current_pos, current_pos+#keyword-1))
    if temp then
      if #keyword == #temp then
        flag = true
        break
      end
    end
    current_pos = current_pos + 1
  end

  if not flag then
    vim.notify("PresetExpand: Could not locate keyword '" .. keyword .. "' under cursor.", vim.log.levels.ERROR)
    return
  end
  start_col = current_pos - 1 -- 0-indexed start
  end_col = current_pos+#keyword-1       -- 0-indexed end

  local new_lines = split_into_lines(content)
  local indent = string.match(line_content, "^%s*") or ""

  if #new_lines > 1 then
    for i = 2, #new_lines do
      if new_lines[i] ~= '' then
        new_lines[i] = indent .. new_lines[i]
      end
    end
  end

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

