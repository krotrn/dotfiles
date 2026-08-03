 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#000000',
    base01 = '#141920',
    base02 = '#1c232c',
    base03 = '#555c63',
    base04 = '#8b949e',
    base05 = '#c9d1d9',
    base06 = '#c9d1d9',
    base07 = '#c9d1d9',
    base08 = '#f85149',
    base09 = '#bc8cff',
    base0A = '#bc8cff',
    base0B = '#58a6ff',
    base0C = '#b580ff',
    base0D = '#80bbff',
    base0E = '#b580ff',
    base0F = '#8f0700',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#c9d1d9',          bg = '#000000' })
  hi('TelescopeBorder',         { fg = '#555c63',             bg = '#000000' })
  hi('TelescopePromptNormal',   { fg = '#c9d1d9',          bg = '#000000' })
  hi('TelescopePromptBorder',   { fg = '#555c63',             bg = '#000000' })
  hi('TelescopePromptPrefix',   { fg = '#58a6ff',             bg = '#000000' })
  hi('TelescopePromptCounter',  { fg = '#8b949e',  bg = '#000000' })
  hi('TelescopePromptTitle',    { fg = '#000000',             bg = '#58a6ff' })
  hi('TelescopePreviewTitle',   { fg = '#000000',             bg = '#bc8cff' })
  hi('TelescopeResultsTitle',   { fg = '#000000',             bg = '#bc8cff' })
  hi('TelescopeSelection',      { fg = '#c9d1d9',          bg = '#1c232c' })
  hi('TelescopeSelectionCaret', { fg = '#58a6ff',             bg = '#1c232c' })
  hi('TelescopeMatching',       { fg = '#58a6ff',             bold = true })
end

 -- Register a signal handler for SIGUSR1 (matugen updates)
 local signal = vim.uv.new_signal()
 signal:start(
   'sigusr1',
   vim.schedule_wrap(function()
     package.loaded['matugen'] = nil
     require('matugen').setup()
   end)
 )

 return M
