# boringaf: a colorful, fast-ish Oh My Zsh dashboard prompt.
#
# Install:
#   cp boringaf.zsh-theme "$ZSH_CUSTOM/themes/boringaf.zsh-theme"
#   ZSH_THEME="boringaf"
#

setopt prompt_subst
autoload -U colors && colors

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

boringaf_git_prompt() {
  local git_status line value branch tag ahead behind stash
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

  local git_line="${BORINGAF_GIT_COLOR}[git ${BORINGAF_BRANCH_ICON}${BORINGAF_RESET} ${BORINGAF_BRANCH_COLOR}${branch}${BORINGAF_RESET}${BORINGAF_GIT_COLOR}]${BORINGAF_RESET}"

  [[ -n "$tag" ]] && git_line+=" ${BORINGAF_TAG_COLOR}[tag ${tag}]${BORINGAF_RESET}"

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

  if (( code == 0 )); then
    print -r -- "${BORINGAF_CLEAN_COLOR}OK${BORINGAF_RESET} ${BORINGAF_BOLD}λ${BORINGAF_UNBOLD}"
  else
    print -r -- "${BORINGAF_ERROR_COLOR}ERR ${code}${BORINGAF_RESET} ${BORINGAF_BOLD}λ${BORINGAF_UNBOLD}"
  fi
}

boringaf_prompt() {
  local last_code="$?"
  local git_info

  git_info="$(boringaf_git_prompt)"

  print -r -- "${BORINGAF_USER_COLOR}%n${BORINGAF_RESET} ${BORINGAF_PATH_COLOR}%~${BORINGAF_RESET}${git_info:+ $git_info}"
  print -r -- "$(boringaf_status_prompt "$last_code") "
}

PROMPT='$(boringaf_prompt)'
