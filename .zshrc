# ╔══════════════════════════════════════════════════════════════════╗
# ║                              ZSHRC                               ║
# ╚══════════════════════════════════════════════════════════════════╝
# Machine-specific settings and secrets go in ~/.zshrc.local (gitignored).

# ── Environment ──────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL="$EDITOR"

# Keep PATH free of duplicates no matter how often it's prepended to
typeset -U path PATH
export PATH="$HOME/.local/bin:$PATH"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"

# ── History ──────────────────────────────────────────────────────
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY         # store timestamps + durations
setopt HIST_IGNORE_ALL_DUPS     # keep only the newest copy of a command
setopt HIST_IGNORE_SPACE        # " cmd" is not saved (secrets, one-offs)
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY              # show !!/!$ expansions before running them
setopt SHARE_HISTORY

# ── Shell options ────────────────────────────────────────────────
setopt AUTO_CD                  # type a directory name to cd into it
setopt AUTO_PUSHD               # cd keeps a stack: `cd -<TAB>` / `d` to jump back
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# ── Oh My Zsh ────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""                    # prompt is drawn by starship (see bottom)
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Suggest from history first, then completion; skip huge pasted buffers
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40

plugins=(
  git
  sudo                          # Esc Esc to prefix the last command with sudo
  npm
  docker
  docker-compose
  extract                       # `x file.tar.gz` / `extract file.zip`
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting       # must stay last
)

source $ZSH/oh-my-zsh.sh

bindkey '^ ' autosuggest-accept  # Ctrl+Space accepts the grey suggestion

# ── fzf ──────────────────────────────────────────────────────────
# File lists include dotfiles/dirs (.config, …) and respect .gitignore so
# node_modules/dist stay out. A second pass adds back .env* files, which are
# usually gitignored but are exactly what you want to open.
_fzf_fd='fd --hidden --follow --exclude .git --exclude "*.{png,jpg,jpeg,ico}"'
_fzf_env='fd --type f --hidden --no-ignore --exclude .git --exclude node_modules --glob ".env*"'
export FZF_DEFAULT_COMMAND="{ $_fzf_fd --type f; $_fzf_env; } 2>/dev/null | awk '!s[\$0]++'"
export FZF_CTRL_T_COMMAND="{ $_fzf_fd; $_fzf_env; } 2>/dev/null | awk '!s[\$0]++'"   # files + dirs
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# `**<Tab>` completion: fzf's built-in walker skips hidden dirs for `cd **`,
# so use fd for both (same rules as above).
_fzf_compgen_path() { { eval "$_fzf_fd . ${(q)1}"; eval "$_fzf_env . ${(q)1}"; } 2>/dev/null | awk '!s[$0]++'; }
_fzf_compgen_dir()  { fd --type d --hidden --follow --exclude .git . "$1"; }

# Colors use ANSI names so fzf follows the terminal (Noctalia) palette.
export FZF_DEFAULT_OPTS="
--height=40%
--layout=reverse
--border=rounded
--info=inline-right
--prompt='❯ '
--pointer='▌'
--marker='┃'
--color=fg:-1,bg:-1,hl:blue:bold,fg+:bright-white,bg+:black,hl+:bright-blue:bold
--color=info:bright-black,prompt:magenta,pointer:blue,marker:green,spinner:magenta,header:cyan
--color=border:bright-black,separator:bright-black,scrollbar:bright-black,gutter:-1
--bind 'ctrl-p:toggle-preview'
"
# Shared previews: files get bat, directories get a tree
_fzf_dir_preview="eza --tree --icons --color=always --level=2 {} | head -200"
_fzf_file_preview="if [ -d {} ]; then $_fzf_dir_preview; else bat --style=numbers --color=always --line-range=:300 {} 2>/dev/null || file {}; fi"

# Previews per widget. History shows the full command on `?` instead of a
# side pane, so long one-liners stay readable.
export FZF_CTRL_T_OPTS="--preview '$_fzf_file_preview' --preview-window=right:60%:wrap"
export FZF_ALT_C_OPTS="--preview '$_fzf_dir_preview'"
export FZF_CTRL_R_OPTS="--preview 'echo {2..}' --preview-window=down:3:hidden:wrap --bind '?:toggle-preview'"

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh 2>/dev/null) || {
    [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
    [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
  }
fi

# ── Aliases ──────────────────────────────────────────────────────
# Files
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --paging=never'  # highlighted, but never drops into a pager
alias mkdir='mkdir -pv'
alias ..='cd ..'
alias ...='cd ../..'

# System
alias df='df -h'
alias du='du -h'                # was `du -sh`, which broke `du -d1` / `du -a`
alias dus='du -sh'              # size of each arg: `dus *`
alias free='free -h'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
alias battery-health="awk 'NR==FNR{a=\$1; next} {printf \"%.1f%%\n\", a*100/\$1}' /sys/class/power_supply/BAT1/charge_full /sys/class/power_supply/BAT1/charge_full_design"

# Tools
alias lg='lazygit'
alias zshrc='$EDITOR ~/.zshrc'
alias reload='exec zsh'         # fresh shell; `source ~/.zshrc` stacks state
alias nd='killall -q -9 noctalia; sleep 2; noctalia >/dev/null 2>&1 & disown'

# ── Functions ────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }

serve() { python3 -m http.server "${1:-8000}"; }

# Copy the current directory path to the clipboard
cpwd() { pwd | tr -d '\n' | wl-copy && echo "Copied: $PWD"; }

# Fuzzy cd into any subdirectory
fcd() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf --preview "$_fzf_dir_preview") && cd "$dir"
}

# Fuzzy-open a file in the editor
fo() {
  local file
  file=$(fzf --preview "$_fzf_file_preview") || return
  [[ -n "$file" ]] && command "$EDITOR" -- "$file"
}

# Open an rg/fzf "file:line:..." selection in the editor at that line
_open_at_line() {
  local sel="$1"
  [[ -n "$sel" ]] || return
  command "$EDITOR" "+${${sel#*:}%%:*}" -- "${sel%%:*}"
}

# Search file contents for a pattern, pick a match, open it at that line
fsearch() {
  [[ -n "$1" ]] || { echo "usage: fsearch <pattern> [dir]"; return 1; }
  local sel
  sel=$(rg --color=always --line-number --no-heading --smart-case -- "$1" "${2:-.}" \
    | fzf --ansi --delimiter=: \
          --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null' \
          --preview-window 'right:60%:wrap:+{2}+3/3') || return
  _open_at_line "$sel"
}

# Live grep: results update as you type; Enter opens the match in the editor.
# flive [dir] [initial-query]; flive-full is the same, fullscreen.
flive() {
  local dir="${1:-.}" sel
  local RG_PREFIX="rg --color=always --line-number --no-heading --smart-case"
  sel=$(fzf --ansi --disabled \
      --query "${2:-}" \
      --bind "start:reload:$RG_PREFIX -- {q} ${(q)dir} || true" \
      --bind "change:reload:$RG_PREFIX -- {q} ${(q)dir} || true" \
      --delimiter=: \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null' \
      --preview-window 'right:60%:wrap:+{2}+3/3' \
      "${@:3}") || return
  _open_at_line "$sel"
}
flive-full() {
  flive "${1:-.}" "${2:-}" --height=100% --border=none --preview-window 'right:65%:wrap:+{2}+3/3'
}

# Fuzzy git branch switcher (local + remote), with recent log as preview
fbr() {
  local branch
  branch=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads refs/remotes \
    | grep -v -e '/HEAD$' -e '^origin$' \
    | fzf --preview 'git log --oneline --graph --color=always -n 30 {}') || return
  git switch "${branch#origin/}" 2>/dev/null || git switch --track "$branch"
}

# Fuzzy process killer: fkill [signal]  (Tab to select several)
fkill() {
  local pids
  pids=$(ps -u "$USER" -o pid=,%cpu=,%mem=,comm= --sort=-%cpu \
    | fzf --multi --header='PID  %CPU %MEM COMMAND' | awk '{print $1}') || return
  [[ -n "$pids" ]] && echo "$pids" | xargs kill -"${1:-TERM}"
}

# Remove ALL docker containers, unused networks and volumes (asks first)
unalias dcf 2>/dev/null           # older versions of this file had it as an alias
dcf() {
  local ids=(${(f)"$(docker ps -aq)"})
  read -q "?Remove ${#ids} container(s) and prune networks + volumes? [y/N] " || { echo; return 1; }
  echo
  (( ${#ids} )) && docker rm -f "${ids[@]}"
  docker network prune -f && docker volume prune -f
}

# ── Completions ──────────────────────────────────────────────────
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ── Node (nvm, lazy) ─────────────────────────────────────────────
# Sourcing nvm.sh costs ~130ms per shell. The default node is put on PATH
# directly; the full nvm loads on the first `nvm` call.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _nvm_default="$(<"$NVM_DIR/alias/default" 2>/dev/null)"
  _nvm_bin=("$NVM_DIR"/versions/node/v${_nvm_default#v}*/bin(N[-1]))
  # alias like "lts/*" or "node": fall back to the newest installed version
  [[ -z "$_nvm_bin" ]] && _nvm_bin=("$NVM_DIR"/versions/node/*/bin(Nn[-1]))
  [[ -n "$_nvm_bin" ]] && export PATH="$_nvm_bin:$PATH"
  unset _nvm_default _nvm_bin
  nvm() {
    unfunction nvm
    \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm "$@"
  }
fi

# ── Local overrides ──────────────────────────────────────────────
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# ── Hooks (keep last: they wrap the prompt and cd) ───────────────
eval "$(starship init zsh)"
eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"       # `z foo` jumps, `zi` picks interactively
