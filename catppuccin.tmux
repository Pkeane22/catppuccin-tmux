#!/usr/bin/env bash
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#source $current_dir/utils.sh

get_tmux_option() {
  local option value default
  option="$1"
  default="$2"
  value="$(tmux show-option -gqv "$option")"

  if [ -n "$value" ]; then
    echo "$value"
  else
    echo "$default"
  fi
}

set() {
  local option=$1
  local value=$2
  tmux_commands+=(set-option -gq "$option" "$value" ";")
}

setw() {
  local option=$1
  local value=$2
  tmux_commands+=(set-window-option -gq "$option" "$value" ";")
}

main() {
  local theme
  theme="$(get_tmux_option "@catppuccin_flavour" "mocha")"

  # Aggregate all commands in one array
  local tmux_commands=()

  # NOTE: Pulling in the selected theme by the theme that's being set as local
  # variables.
  # shellcheck source=catppuccin-frappe.tmuxtheme
  source /dev/stdin <<<"$(sed -e "/^[^#].*=/s/^/local /" "${PLUGIN_DIR}/catppuccin-${theme}.tmuxtheme")"

  # status
  set status "on"
  set status-bg "${thm_bg}"
  set status-justify "left"
  set status-left-length "100"
  set status-right-length "100"

  # messages
  set message-style "fg=${cyan},bg=${grey},align=centre"
  set message-command-style "fg=${cyan},bg=${grey},align=centre"

  # panes
  set pane-border-style "fg=${grey}"
  set pane-active-border-style "fg=${blue}"

  # windows
  setw window-status-activity-style "fg=${thm_fg},bg=${thm_bg},none"
  setw window-status-separator ""
  setw window-status-style "fg=${thm_fg},bg=${thm_bg},none"

  # --------=== Statusline

  # NOTE: Checking for the value of @catppuccin_window_tabs_enabled
  #local wt_enabled
  wt_enabled="$(get_tmux_option "@catppuccin_window_tabs_enabled" "off")"
  #readonly wt_enabled

  local right_separator
  right_separator="$(get_tmux_option "@catppuccin_right_separator" "")"
  readonly right_separator

  local left_separator
  left_separator="$(get_tmux_option "@catppuccin_left_separator" "")"
  readonly left_separator

  local user
  user="$(get_tmux_option "@catppuccin_user" "off")"
  readonly user

  local host
  host="$(get_tmux_option "@catppuccin_host" "off")"
  readonly host

  IFS=' ' read -r -a plugins <<< $(get_tmux_option "@catppuccin_plugins" "time")

  # These variables are the defaults so that the setw and set calls are easier to parse.
  local show_directory
  readonly show_directory="#[fg=$pink,bg=$thm_bg,nobold,nounderscore,noitalics]$right_separator#[fg=$thm_bg,bg=$pink,nobold,nounderscore,noitalics]  #[fg=$thm_fg,bg=$grey] #{b:pane_current_path} #{?client_prefix,#[fg=$red]"

  local show_window
  readonly show_window="#[fg=$pink,bg=$thm_bg,nobold,nounderscore,noitalics]$right_separator#[fg=$thm_bg,bg=$pink,nobold,nounderscore,noitalics] #[fg=$thm_fg,bg=$grey] #W #{?client_prefix,#[fg=$red]"

  local show_session
  readonly show_session="#[fg=$green]}#[bg=$grey]$right_separator#{?client_prefix,#[bg=$red],#[bg=$green]}#[fg=$thm_bg] #[fg=$thm_fg,bg=$grey] #S "

  local show_directory_in_window_status
  #readonly show_directory_in_window_status="#[fg=$thm_bg,bg=$blue] #I #[fg=$thm_fg,bg=$grey] #{b:pane_current_path} "
  readonly show_directory_in_window_status="#[fg=$thm_bg,bg=$blue] #I #[fg=$thm_fg,bg=$grey] #W "

  local show_directory_in_window_status_current
  readonly show_directory_in_window_status_current="#[fg=$thm_bg,bg=$orange] #I #[fg=$thm_fg,bg=$thm_bg] #{b:pane_current_path} "
  #readonly show_directory_in_window_status_current="#[fg=colour232,bg=$orange] #I #[fg=colour255,bg=colour237] #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev) "

  local show_window_in_window_status
  readonly show_window_in_window_status="#[fg=$thm_fg,bg=$thm_bg] #W #[fg=$thm_bg,bg=$blue] #I#[fg=$blue,bg=$thm_bg]$left_separator#[fg=$thm_fg,bg=$thm_bg,nobold,nounderscore,noitalics] "

  local show_window_in_window_status_current
  readonly show_window_in_window_status_current="#[fg=$thm_fg,bg=$grey] #W #[fg=$thm_bg,bg=$orange] #I#[fg=$orange,bg=$thm_bg]$left_separator#[fg=$thm_fg,bg=$thm_bg,nobold,nounderscore,noitalics] "
 #setw -g window-status-current-format "#[fg=colour232,bg=$orange] #I #[fg=colour255,bg=colour237] #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev) "


  local show_user
  readonly show_user="#[fg=$blue,bg=$grey]$right_separator#[fg=$thm_bg,bg=$blue] #[fg=$thm_fg,bg=$grey] #(whoami) "

  local show_host
  readonly show_host="#[fg=$blue,bg=$grey]$right_separator#[fg=$thm_bg,bg=$blue]󰒋 #[fg=$thm_fg,bg=$grey] #H "

  # Right column 1 by default shows the Window name.
  local right_column1=$show_window

  # Right column 2 by default shows the current Session name.
  local right_column2=$show_session

  # Window status by default shows the current directory basename.
  local window_status_format=$show_directory_in_window_status
  local window_status_current_format=$show_directory_in_window_status_current

  # NOTE: With the @catppuccin_window_tabs_enabled set to on, we're going to
  # update the right_column1 and the window_status_* variables.
  if [[ "${wt_enabled}" == "on" ]]; then
    right_column1=$show_directory
    window_status_format=$show_window_in_window_status
    window_status_current_format=$show_window_in_window_status_current
  fi

  for plugin in "${plugins[@]}"; do
    if [ $plugin = "time" ]; then
      color="$(get_tmux_option "@catppuccin_time_color" "blue")"
      icon="$(get_tmux_option "@catppuccin_time_icon" "")"
      script="$(get_tmux_option "@catppuccin_time" "%a %m/%d %H:%M")"

    elif [ $plugin = "battery" ]; then
      color="$(get_tmux_option "@catppuccin_battery_color" "pink")"
      icon="#{battery_icon_status}"
      script="#{battery_percentage}"

    elif [ $plugin = "sys_info" ]; then
      color="$(get_tmux_option "@catppuccin_sys_info_color" "orange")"
      icon="$(get_tmux_option "@catppuccin_sys_info_icon" "")"
      script="#($current_dir/scripts/tmux_ram_info.sh)|#($current_dir/scripts/cpu_info.sh)"

    elif [ $plugin = "git" ]; then
      color="$(get_tmux_option "@catppuccin_git_color" "green")"
      icon="$(get_tmux_option "@catppuccin_git_icon" "")"
      script="#($current_dir/scripts/git.sh)"

    else
      continue
    fi

    right_column2=$right_column2"#{?#{==:$script,},,#[fg=${!color},bg=$grey]$right_separator#[fg=$thm_bg,bg=${!color}]$icon #[fg=$thm_fg,bg=$grey] $script }"
    #right_column2=$right_column2"#[fg=${!color},bg=$grey]$right_separator#[fg=$thm_bg,bg=${!color}]$icon #[fg=$thm_fg,bg=$grey] $script "

  done

  if [[ "${user}" == "on" ]]; then
    right_column2=$right_column2$show_user
  fi

  if [[ "${host}" == "on" ]]; then
    right_column2=$right_column2$show_host
  fi

  set status-left ""

  set status-right "${right_column1},${right_column2}"

  setw window-status-format "${window_status_format}"
  setw window-status-current-format "${window_status_current_format}"

  # --------=== Modes
  #
  setw clock-mode-colour "${blue}"
  setw mode-style "fg=${pink} bg=${black4} bold"

  tmux "${tmux_commands[@]}"
}

main "$@"
