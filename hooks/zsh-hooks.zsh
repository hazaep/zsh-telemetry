CMD_START_TIME=0
CMD_EXEC=""
TELEMETRY_DB="$SHELL_TELEMETRY/db/telemetry.db"
TELEMETRY_BIN="$SHELL_TELEMETRY/bin/telemetry-insert"

preexec() {
  CMD_START_TIME=$(date +%s%3N)
  CMD_EXEC="$1"
}

precmd() {
  [[ -z "$CMD_EXEC" ]] && return

  local exit_code=$?
  local end=$(date +%s%3N)
  local duration=$((end - CMD_START_TIME))

  "$TELEMETRY_BIN" \
    "$CMD_EXEC" \
    "$exit_code" \
    "$duration" \
    "$PWD" \
    "$(date +%s)"

  CMD_EXEC=""
}

telemetry-query() {
  sqlite3 -header -column "$TELEMETRY_DB" "$1"
}

hist-top() {
  telemetry-query "
  SELECT base_cmd, COUNT(*) as count
  FROM commands
  GROUP BY base_cmd
  ORDER BY count DESC
  LIMIT 30;
  "
}

hist-slow() {
  telemetry-query "
  SELECT command, duration_ms
  FROM commands
  ORDER BY duration_ms DESC
  LIMIT 20;
  "
}

hist-fail() {
  telemetry-query "
  SELECT command, COUNT(*) as errors
  FROM commands
  WHERE exit_code != 0
  GROUP BY command
  ORDER BY errors DESC
  LIMIT 30;
  "
}

hist-last() {
  telemetry-query "
  SELECT datetime(timestamp, 'unixepoch') as time,
         command,
         exit_code
  FROM commands
  ORDER BY timestamp DESC
  LIMIT 30;
  "
}

hist-here() {
  telemetry-query "
  SELECT command, COUNT(*) as count
  FROM commands
  WHERE cwd = '$PWD'
  GROUP BY command
  ORDER BY count DESC
  LIMIT 30;
  "
}

hist-search() {
  local term="$1"
  local escaped=${term//\'/\'\'}
  escaped=${escaped//%/\\%}
  escaped=${escaped//_/\\_}

  telemetry-query "
  SELECT datetime(timestamp,'unixepoch') as time,
         command
  FROM commands
  WHERE command LIKE '%$escaped%' ESCAPE '\'
  ORDER BY timestamp DESC
  LIMIT 30;
  "
}

hist-stats() {
  telemetry-query "
  SELECT
    COUNT(*) as total_commands,
    COUNT(DISTINCT base_cmd) as unique_commands,
    SUM(duration_ms)/1000 as total_seconds
  FROM commands;
  "
}

