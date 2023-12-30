local pickers = require('telescope.pickers')
local config = require('telescope.config').values

local finders = require('git_status.finders')
local previewers = require('git_status.previewers')
local actions = require('git_status.actions')

local B = {}

B.git_status = function(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = 'Git Status',
    results_title = '<Tab>:stage/<C-r>:reset/<CR>:jump',
    finder = finders.finder(opts),
    previewer = previewers.previewer(opts),
    sorter = config.generic_sorter(opts),
    attach_mappings = function(_, map)
      map({ 'n',
            'i' }, '<Tab>', actions.stage_hunk)
      map({ 'n',
            'i' }, '<C-r>', actions.reset)

      return true
    end,
  }):find()
end

return B
