local finders = require('telescope.finders')

local systems = require('git_status.systems')

local function run_git(args)
  local job = systems.create_job({
    command = 'git',
    args = args,
  })
  job:sync()

  return job:result()
end

local function create_hunk(old_start, old_count, new_start, new_count)
  local old_hunk_str = old_count > 0 and ',' .. old_count or ''
  local new_hunk_str = new_count > 0 and ',' .. new_count or ''

  return {
    deleted = {
      start = old_start,
      count = old_count,
      lines = {},
    },
    added = {
      start = new_start,
      count = new_count,
      lines = {},
    },
    diff_head = ('@@ -%d%s +%d%s @@'):format(old_start, old_hunk_str, new_start, new_hunk_str),
    start = new_start,
    end_ = new_start + math.max(new_count - 1, 0),
    type = new_count == 0 and 'delete' or old_count == 0 and 'add' or 'change',
  }
end

local function parse_diff(line)
  local diffkey = vim.trim(vim.split(line, '@@', {
    plain = true,
  })[2])

  local pre, now = unpack(vim.tbl_map(function(s)
    return vim.split(string.sub(s, 2), ',')
  end, vim.split(diffkey, ' ')))

  return create_hunk(tonumber(pre[1]), (tonumber(pre[2]) or 1), tonumber(now[1]), (tonumber(now[2]) or 1))
end

local function make_results()
  local results = {}
  for _, filename in ipairs(run_git({
    'diff',
    '--name-only',
  })) do
    local hunk_diffs = {}
    for _, line in ipairs(run_git({
      'diff',
      '--unified=0',
      '--no-color',
      '--indent-heuristic',
      '--histogram',
      filename,
    })) do
      if vim.startswith(line, '@@') then
        -- make new hunk holder
        table.insert(hunk_diffs, parse_diff(line))
      elseif #hunk_diffs > 0 then
        -- set diff line to hunk holder
        local latest_holder = hunk_diffs[#hunk_diffs]
        local sign = string.sub(line, 1, 1)
        if sign == '-' then
          table.insert(latest_holder.deleted.lines, string.sub(line, 2))
        elseif sign == '+' then
          table.insert(latest_holder.added.lines, string.sub(line, 2))
        end
      end
    end

    for _, hd in ipairs(hunk_diffs) do
      table.insert(results, {
        filename = filename,
        hunk_diffs = hd,
      })
    end
  end

  return results
end

local function make_entry(entry)
  local display = entry.filename .. ':' .. entry.hunk_diffs.start
  return {
    value = entry,
    display = display,
    ordinal = display,
    opts = {
      filename = entry.filename,
      hunk_diffs = entry.hunk_diffs,
    },
  }
end

local F = {}

F.finder = function(opts)
  opts = opts or {}

  return finders.new_table({
    results = make_results(),
    entry_maker = make_entry,
  })
end

return F
