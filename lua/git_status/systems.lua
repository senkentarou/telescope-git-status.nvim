local Job = require('plenary.job')

local S = {}

S.create_job = function(opts)
  opts = opts or {}

  local command = opts.command or opts[1]
  local args = opts.args or {}
  local writer = opts.writer or nil

  return Job:new({
    command = command,
    args = args,
    writer = writer,
  })
end

return S
