# preset-expander
Nvim plugin that allows you to write and reuse snippets of code (Presets)

## Usage
1. Add preset files in your-nvim-config-dir/presets (You can change the directory in config.presets_dir)
   The file functions as a keyword for it.
2. Hover your cursor over a keyword in neovim and call :PresetExpand
   It will expand the keyword into the contets of a respecting file
