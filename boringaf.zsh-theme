# boringaf: a colorful, fast-ish Oh My Zsh dashboard prompt.
#
# Install:
#   cp boringaf.zsh-theme "$ZSH_CUSTOM/themes/boringaf.zsh-theme"
#   ZSH_THEME="boringaf"
#

setopt prompt_subst
autoload -U colors && colors
autoload -Uz add-zsh-hook
zmodload zsh/datetime 2>/dev/null

BORINGAF_USER_COLOR="%F{111}"
BORINGAF_PATH_COLOR="%F{5}"
BORINGAF_GIT_COLOR="%F{224}"
BORINGAF_BRANCH_COLOR="%F{156}"
BORINGAF_TAG_COLOR="%F{111}"
BORINGAF_DIRTY_COLOR="%F{228}"
BORINGAF_CLEAN_COLOR="%F{156}"
BORINGAF_MUTED_COLOR="%F{6}"
BORINGAF_ERROR_COLOR="%F{red}"
BORINGAF_RESET="%f"
BORINGAF_BOLD="%B"
BORINGAF_UNBOLD="%b"
BORINGAF_BRANCH_ICON=$'\ue0a0'
: ${BORINGAF_DURATION_THRESHOLD:=5}

boringaf_context_prompt() {
  local user host

  user="%n"
  host="%m"

  if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || ( -n "$DEFAULT_USER" && "$USER" != "$DEFAULT_USER" ) ]]; then
    print -r -- "${BORINGAF_USER_COLOR}${user}@${host}${BORINGAF_RESET}"
  else
    print -r -- "${BORINGAF_USER_COLOR}${user}${BORINGAF_RESET}"
  fi
}

boringaf_git_operation() {
  local git_dir operation

  git_dir="$(command git rev-parse --git-dir 2>/dev/null)" || return

  if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
    operation="rebase"
  elif [[ -f "$git_dir/MERGE_HEAD" ]]; then
    operation="merge"
  elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
    operation="cherry-pick"
  elif [[ -f "$git_dir/REVERT_HEAD" ]]; then
    operation="revert"
  elif [[ -f "$git_dir/BISECT_LOG" ]]; then
    operation="bisect"
  fi

  [[ -n "$operation" ]] && print -r -- "${BORINGAF_ERROR_COLOR}[${operation}]${BORINGAF_RESET}"
}

boringaf_git_prompt() {
  local git_status line value branch tag ahead behind stash operation
  local staged unstaged untracked conflicts dirty
  local x y

  git_status="$(command git status --porcelain=v2 --branch --show-stash 2>/dev/null)" || return

  branch=""
  tag=""
  ahead=0
  behind=0
  stash=0
  staged=0
  unstaged=0
  untracked=0
  conflicts=0

  while IFS= read -r line; do
    case "$line" in
      "# branch.head "*)
        branch="${line#"# branch.head "}"
        ;;
      "# branch.ab "*)
        value="${line#"# branch.ab "}"
        ahead="${value%% *}"
        behind="${value##* }"
        ahead="${ahead#+}"
        behind="${behind#-}"
        ;;
      "# stash "*)
        stash="${line#"# stash "}"
        ;;
      "1 "*|"2 "*)
        x="${line[3,3]}"
        y="${line[4,4]}"
        [[ "$x" != "." ]] && (( staged++ ))
        [[ "$y" != "." ]] && (( unstaged++ ))
        ;;
      "u "*)
        (( conflicts++ ))
        ;;
      "? "*)
        (( untracked++ ))
        ;;
    esac
  done <<< "$git_status"

  [[ -z "$branch" ]] && branch="detached"

  tag="$(command git describe --tags --exact-match 2>/dev/null)"

  dirty=$(( staged + unstaged + untracked + conflicts ))

  operation="$(boringaf_git_operation)"

  local git_line="${BORINGAF_GIT_COLOR}[git ${BORINGAF_BRANCH_ICON}${BORINGAF_RESET} ${BORINGAF_BRANCH_COLOR}${branch}${BORINGAF_RESET}${BORINGAF_GIT_COLOR}]${BORINGAF_RESET}"

  [[ -n "$tag" ]] && git_line+=" ${BORINGAF_TAG_COLOR}[tag ${tag}]${BORINGAF_RESET}"
  [[ -n "$operation" ]] && git_line+=" $operation"

  if (( dirty > 0 )); then
    git_line+=" ${BORINGAF_DIRTY_COLOR}[+${staged} ~${unstaged} ?${untracked}"
    (( conflicts > 0 )) && git_line+=" !${conflicts}"
    git_line+="]${BORINGAF_RESET}"
  else
    git_line+=" ${BORINGAF_CLEAN_COLOR}[clean]${BORINGAF_RESET}"
  fi

  (( ahead > 0 || behind > 0 )) && git_line+=" ${BORINGAF_MUTED_COLOR}[ahead ${ahead} behind ${behind}]${BORINGAF_RESET}"
  (( stash > 0 )) && git_line+=" ${BORINGAF_MUTED_COLOR}[stash ${stash}]${BORINGAF_RESET}"

  print -r -- "$git_line"
}

boringaf_status_prompt() {
  local code="${1:-$?}"
  local duration="${BORINGAF_LAST_DURATION:-}"
  local prefix=""

  if [[ -n "$duration" ]]; then
    prefix="${BORINGAF_MUTED_COLOR}[${duration}]${BORINGAF_RESET} "
  fi

  if (( code == 0 )); then
    print -r -- "${prefix}${BORINGAF_CLEAN_COLOR}${BORINGAF_BOLD}λ${BORINGAF_UNBOLD}${BORINGAF_RESET}"
  else
    print -r -- "${prefix}${BORINGAF_ERROR_COLOR}${BORINGAF_BOLD}λ${BORINGAF_UNBOLD}${BORINGAF_RESET}"
  fi
}

boringaf_prompt() {
  local last_code="$?"
  local context_info git_info

  context_info="$(boringaf_context_prompt)"
  git_info="$(boringaf_git_prompt)"

  print -r -- "${context_info} ${BORINGAF_PATH_COLOR}%~${BORINGAF_RESET}${git_info:+ $git_info}"
  print -r -- "$(boringaf_status_prompt "$last_code") "
}

boringaf_preexec() {
  BORINGAF_COMMAND_START="$EPOCHREALTIME"
}

boringaf_precmd() {
  local elapsed seconds millis

  BORINGAF_LAST_DURATION=""

  [[ -z "$BORINGAF_COMMAND_START" || -z "$EPOCHREALTIME" ]] && return

  elapsed=$(( EPOCHREALTIME - BORINGAF_COMMAND_START ))

  if (( elapsed >= BORINGAF_DURATION_THRESHOLD )); then
    seconds=${elapsed%.*}
    millis=${${elapsed#*.}[1,3]}
    BORINGAF_LAST_DURATION="${seconds}.${millis}s"
  fi

  BORINGAF_COMMAND_START=""
}

add-zsh-hook -d preexec boringaf_preexec 2>/dev/null
add-zsh-hook -d precmd boringaf_precmd 2>/dev/null
add-zsh-hook preexec boringaf_preexec
add-zsh-hook precmd boringaf_precmd

PROMPT='$(boringaf_prompt)'
