local builtin = require('git_status.builtin')

return require('telescope').register_extension {
  exports = {
    git_status = builtin.git_status,
  },
}
