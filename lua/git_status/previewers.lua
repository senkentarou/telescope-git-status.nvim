local config = require('telescope.config').values
local buffer_previewer = require('telescope.previewers.buffer_previewer')

local function linespec(hunk_diffs)
  local hls = {}

  for _, line in ipairs(hunk_diffs.deleted.lines) do
    table.insert(hls, {
      {
        '-' .. line,
        {
          {
            hl_group = 'DiffDelete',
            start_row = 0,
            end_row = 1,
          },
        },
      },
    })
  end

  for _, line in ipairs(hunk_diffs.added.lines) do
    table.insert(hls, {
      {
        '+' .. line,
        {
          {
            hl_group = 'DiffAdd',
            start_row = 0,
            end_row = 1,
          },
        },
      },
    })
  end

  return hls
end

local function diffs_with_linesspec(hunk_diffs)
  local diffs = {}
  local highlights = {}

  local row_no = 0
  for _, hunk in ipairs(linespec(hunk_diffs)) do
    local hunk_text = {}

    for _, part in ipairs(hunk) do
      local text, hls = part[1], part[2]

      -- set row_no on hls
      for _, h in ipairs(hls) do
        h.start_row = h.start_row + row_no
        h.end_row = h.end_row + row_no
      end

      -- add text/hls to holder
      table.insert(hunk_text, text)
      vim.list_extend(highlights, hls)

      -- move row_no indicator by count number of lines in text
      local _, lines_count = string.gsub(text, '\n', '')
      row_no = row_no + lines_count
    end

    -- convert hunk_text to string and add to diffs
    vim.list_extend(diffs, vim.split(table.concat(hunk_text), '\n', {
      plain = true,
    }))

    -- move row_no indicator by 1
    row_no = row_no + 1
  end

  return diffs, highlights
end

local function inject_hunk_diffs_highlights(bufnr, hunk_diffs)
  local diffs, highlights = diffs_with_linesspec(hunk_diffs)

  -- adjust start/end (when change type diff, start is -1 to adjust for the header)
  local start = hunk_diffs.type == 'change' and hunk_diffs.added.start - 1 or hunk_diffs.added.start
  local end_ = hunk_diffs.end_

  -- set preview buffer lines
  vim.api.nvim_buf_set_lines(bufnr, start, end_, false, diffs)

  -- create highlight namespace
  local ns = vim.api.nvim_create_namespace('telescope_git_status')

  for _, hl in ipairs(highlights) do
    local start_row = start + hl.start_row
    local end_row = start + hl.end_row

    -- set highlights
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, start_row, 0, {
      hl_group = hl.hl_group,
      end_row = end_row,
      end_col = 0,
      hl_eol = true,
    })
  end
end

local function adjust_to_middle(bufnr, winid, row)
  vim.schedule(function()
    pcall(vim.api.nvim_win_set_cursor, winid, {
      row,
      0,
    })

    vim.api.nvim_buf_call(bufnr, function()
      vim.api.nvim_exec(':norm! zz', false)
    end)
  end)
end

local P = {}

P.previewer = function(opts)
  opts = opts or {}

  return buffer_previewer.new_buffer_previewer({
    title = 'Hunk Diff',
    define_preview = function(self, entry)
      config.buffer_previewer_maker(entry.value.filename, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        preview = opts.preview,
        callback = function(bufnr)
          -- show preview
          inject_hunk_diffs_highlights(bufnr, entry.value.hunk_diffs)
          adjust_to_middle(bufnr, self.state.winid, entry.value.hunk_diffs.added.start)
        end,
      })
    end,
  })
end

return P
