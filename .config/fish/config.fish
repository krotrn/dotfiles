fastfetch

function starship_transient_prompt_func
  starship module character
end
function starship_transient_rprompt_func
  starship module custom.transient_time
end
starship init fish | source

# fast node manager
fnm env --use-on-cd | source

# zoxide
zoxide init fish | source

# Bun
set -gx BUN_INSTALL "$HOME/.bun"
fish_add_path "$BUN_INSTALL/bin"

# Aliases
alias ls="eza --icons"
alias ll="eza -lah --icons"
alias la="eza -a --icons"
alias cat="bat"
alias g="git"
alias lg="lazygit"
alias c="clear"


# Added by Antigravity CLI installer
set -gx PATH "/home/krotrn/.local/bin" $PATH

# Locale
set -gx LANG en_IN.UTF-8
set -e LC_ALL
