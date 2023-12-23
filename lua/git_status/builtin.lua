local pickers = require('telescope.pickers')
local config = require('telescope.config').values

local finders = require('git_status.finders')
local previewers = require('git_status.previewers')

local B = {}

B.git_status = function(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = '<CR>:jump',
    results_title = '',
    finder = finders.finder(opts),
    previewer = previewers.previewer(opts),
    sorter = config.generic_sorter(opts),
    attach_mappings = function(_, _)
      -- TODO: it's nice to have stage hunk
      return true
    end,
  }):find()
end

return B
