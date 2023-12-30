# telescope-git-status
* This is a git integration plugin with [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
* It provides a `git diff` picker that lists all the hunks of the files in the current git repository.

# Installation
* [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
-- or tag = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'senkentarou/telescope-git-status.nvim',
    },
  },
}
```

# Setup
* Please setup as telescope extension on `init.lua` as below:
```lua
local telescope = require("telescope")

telescope.setup {
  -- ...
}

telescope.load_extension("git_status")
```

# Usage
* example:
```
:lua require("telescope").extensions.git_status.git_status()
```
* `<Tab>`: stage hunks
* `<C-r>`: reset all hunks
* `<CR>`: open file and move cursor to the hunk

# UNDER DEVELOPMENT
* Operation confirmation is insufficient at:
  * hunks in delete files
  * hunks in rename files
  * new files
