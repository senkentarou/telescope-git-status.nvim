local action_state = require('telescope.actions.state')

local systems = require('git_status.systems')
local finders = require('git_status.finders')

local function create_patch(filename, hunk_diffs)
  local results = {
    string.format('diff --git a/%s b/%s', filename, filename),
    'index 000000..000000 100644',
    '--- a/' .. filename,
    '+++ b/' .. filename,
  }

  local start, old_count, now_count = hunk_diffs.deleted.start, hunk_diffs.deleted.count, hunk_diffs.added.count

  if hunk_diffs.type == 'add' then
    start = start + 1
  end

  table.insert(results, string.format('@@ -%s,%s +%s,%s @@', start, old_count, start, now_count))
  for _, l in ipairs(hunk_diffs.deleted.lines) do
    table.insert(results, '-' .. l)
  end
  for _, l in ipairs(hunk_diffs.added.lines) do
    table.insert(results, '+' .. l)
  end

  return results
end

local A = {}

A.stage_hunk = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)

  current_picker:delete_selection(function(selection)
    local value = selection.value

    local command = 'git'
    local command_args = {
      'apply',
      '--whitespace=nowarn',
      '--cached',
      '--unidiff-zero',
      '-',
    }
    local stdin_writer_string = table.concat(create_patch(value.filename, value.hunk_diffs), '\n') .. '\n'

    systems.create_job({
      command = command,
      args = command_args,
      writer = stdin_writer_string,
    }):start()
  end)
end

A.reset = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)

  systems.create_job({
    command = 'git',
    args = { 'reset' },
  }):start()

  current_picker:refresh(finders.finder(), {
    reset_prompt = true,
  })
end

return A
