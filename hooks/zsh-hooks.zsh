CMD_START_TIME=0
CMD_EXEC=""

preexec() {
  CMD_START_TIME=$(date +%s%3N)
  CMD_EXEC="$1"
}

precmd() {
  local exit_code=$?
  local end=$(date +%s%3N)
  local duration=$((end - CMD_START_TIME))

  ~/.local/share/shell-telemetry/bin/telemetry-insert \
    "$CMD_EXEC" \
    "$exit_code" \
    "$duration" \
    "$PWD" \
    "$(date +%s)"
}
