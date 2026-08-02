# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  sudo
  npm
  zsh-autosuggestions
  zsh-syntax-highlighting
  docker
  docker-compose
  extract
  colored-man-pages
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"



alias battery-health="awk 'NR==FNR{a=\$1; next} {printf \"%.1f%%\n\", a*100/\$1}' /sys/class/power_supply/BAT1/charge_full /sys/class/power_supply/BAT1/charge_full_design"
alias connect-db='ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L 5433:localhost:5433 REDACTED_HOST "docker run --rm -d --network campus-connect_campus_connect_net --name pg_proxy -p 127.0.0.1:5433:5432 alpine/socat TCP-LISTEN:5432,fork,reuseaddr TCP:campus_connect_db:5432 2>/dev/null || true"'
alias connect-db-stop='ssh REDACTED_HOST "docker stop pg_proxy"'

alias nitap-db='ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L 5434:localhost:5434 REDACTED_HOST "docker stop pg_proxy 2>/dev/null; docker run --rm -d --network nitapacin_nitap_net --name pg_proxy -p 127.0.0.1:5434:5432 alpine/socat TCP-LISTEN:5432,fork,reuseaddr TCP:nitap_postgres:5432 2>/dev/null || true"'

alias nitap-db-stop='ssh REDACTED_HOST "docker stop pg_proxy"'
export PATH="$HOME/.local/bin:$PATH"

# fzf keybindings
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh

# fzf completion
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git" --glob "!*.png" --glob "!*.jpg" --glob "!*.jpeg" --glob "!*.ico"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_DEFAULT_OPTS="
--height=40%
--layout=reverse
--border
--preview 'bat --style=numbers --color=always {} 2>/dev/null || file {}'
--preview-window=right:60%:wrap
--bind 'ctrl-p:toggle-preview'
"

alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'

alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -pv'

alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
# make dir and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

fcd() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf) && cd "$dir"
}

fo() {
    local file
    file=$(fzf) || return
    [[ -n "$file" ]] || return
    command nvim -- "$file"
}
# quick HTTP server in current dir
serve() { python3 -m http.server "${1:-8000}"; }
# Search inside file contents with rg + fzf
fsearch() {
  rg --color=always --line-number --no-heading "$1" . \
    | fzf --ansi \
          --delimiter=: \
          --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null' \
          --preview-window 'right:60%:wrap:+{2}+3/3' \
    | awk -F: '{print $1 ":" $2}'
}
# Live grep inside files, interactive
flive() {
  local dir="${1:-.}"
  local RG_PREFIX="rg --color=always --line-number --no-heading --smart-case"
  fzf --ansi \
      --disabled \
      --query "${2:-}" \
      --bind "start:reload:$RG_PREFIX '' $dir" \
      --bind "change:reload:$RG_PREFIX {q} $dir || true" \
      --delimiter=: \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null' \
      --preview-window 'right:60%:wrap:+{2}+3/3'
}

flive-full() {
  local dir="${1:-.}"
  local RG_PREFIX="rg --color=always --line-number --no-heading --smart-case"
  fzf --ansi \
      --disabled \
      --query "${2:-}" \
      --bind "start:reload:$RG_PREFIX '' $dir" \
      --bind "change:reload:$RG_PREFIX {q} $dir || true" \
      --delimiter=: \
      --height=100% \
      --border=none \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null' \
      --preview-window 'right:65%:wrap:+{2}+3/3' \
      --bind 'ctrl-p:toggle-preview'
}

alias zshrc='$EDITOR ~/.zshrc'        # quickly edit this file
alias reload='source ~/.zshrc'        # reload without restarting terminal
alias df='df -h'                      # human readable disk usage
alias du='du -sh'                     # human readable dir size
alias free='free -h'                  # human readable memory

export EDITOR='nvim'
export VISUAL="$EDITOR"

# bun completions
[ -s "/home/krotrn/.bun/_bun" ] && source "/home/krotrn/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/home/krotrn/.local/bin:$PATH"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(fnm env --use-on-cd)"
eval "$(direnv hook zsh)"
# pnpm
export PNPM_HOME="/home/krotrn/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
alias nd='killall -q -9 noctalia; sleep 2; noctalia >/dev/null 2>&1 & disown'
