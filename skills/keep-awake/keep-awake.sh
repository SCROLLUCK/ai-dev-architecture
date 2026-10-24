#!/usr/bin/env bash
# Keep the laptop from suspending while long work runs, and put the settings back after.
#
#   keep-awake.sh on  <holder> [hours]   take or renew a lease (default 4 h)
#   keep-awake.sh off <holder>           release it; the last release restores the settings
#   keep-awake.sh status
#   keep-awake.sh recover                after a reboot: restore or re-arm (run it at login)
#
# Suspend here comes from Cinnamon's idle timer, requested by the same uid, and logind ignores
# an inhibitor from that uid, so systemd-inhibit alone does not hold it: the idle and lid
# actions are set to 'nothing' while any lease is live. A watchdog (run under systemd-inhibit,
# which still covers other requests) drops expired leases and restores the saved values when
# none remain, so a session that dies without "off" still gives the machine back.
set -euo pipefail

SCHEMA=org.cinnamon.settings-daemon.plugins.power
KEYS=(sleep-inactive-ac-type sleep-inactive-battery-type lid-close-battery-action)
DIR="$HOME/.claude/state/keep-awake"
HOLDERS="$DIR/holders"
SAVED="$DIR/saved"
PIDFILE="$DIR/watchdog.pid"
EVENTS="$DIR/events.jsonl"
mkdir -p "$HOLDERS"

with_lock() { exec 9>"$DIR/lock"; flock 9; }

json_str() { local s=${1//\\/\\\\}; printf '"%s"' "${s//\"/\\\"}"; }

# One JSON line per lease event, read by dashboards for a timeline.
# project = main checkout of the git repo the caller runs in (worktrees map to their repo).
log_event() {
  local event=$1 holder=$2 expires=${3:-} project=""
  if [ "$event" = on ] || [ "$event" = renew ]; then
    project=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && project=${project%/.git} || project=$PWD
  fi
  {
    printf '{"ts":%s,"event":"%s","holder":%s' "$(date +%s)" "$event" "$(json_str "$holder")"
    [ -n "$expires" ] && printf ',"expires":%s' "$expires"
    [ -n "$project" ] && printf ',"project":%s' "$(json_str "$project")"
    printf '}\n'
  } >>"$EVENTS"
}

drop_expired() {
  local f now
  now=$(date +%s)
  for f in "$HOLDERS"/*; do
    [ -e "$f" ] || continue
    [ "$(cat "$f")" -gt "$now" ] || { rm -f "$f"; log_event expire "$(basename "$f")"; }
  done
}

has_holders() { compgen -G "$HOLDERS/*" >/dev/null; }

# A pid file left by a reboot can name an unrelated process, so check what it runs.
watchdog_alive() {
  [ -f "$PIDFILE" ] && grep -qa keep-awake "/proc/$(cat "$PIDFILE")/cmdline" 2>/dev/null
}

start_watchdog() {
  watchdog_alive && return 0
  # 9>&- : the watchdog must not inherit the lock fd, or it holds the lock forever.
  nohup systemd-inhibit --what=sleep:idle:handle-lid-switch --mode=block \
    --why="keep-awake: long work running" "$0" _watch >/dev/null 2>&1 9>&- &
}

restore() {
  [ -f "$SAVED" ] || return 0
  while read -r key value; do
    gsettings set "$SCHEMA" "$key" "$value"
  done <"$SAVED"
  rm -f "$SAVED"
}

case "${1:-status}" in
  on)
    holder=${2:?holder name required}
    hours=${3:-4}
    [[ $hours =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "hours must be a number: $hours" >&2; exit 2; }
    with_lock
    if [ ! -f "$SAVED" ]; then
      for key in "${KEYS[@]}"; do
        echo "$key $(gsettings get "$SCHEMA" "$key")"
      done >"$SAVED"
      for key in "${KEYS[@]}"; do gsettings set "$SCHEMA" "$key" "'nothing'"; done
    fi
    event=on; [ -f "$HOLDERS/$holder" ] && event=renew
    expires=$(($(date +%s) + $(awk -v h="$hours" 'BEGIN { printf "%d", h * 3600 }')))
    echo "$expires" >"$HOLDERS/$holder"
    log_event "$event" "$holder" "$expires"
    start_watchdog
    echo "awake: lease '$holder' for ${hours} h"
    ;;
  off)
    holder=${2:?holder name required}
    with_lock
    [ -f "$HOLDERS/$holder" ] && { rm -f "$HOLDERS/$holder"; log_event off "$holder"; }
    drop_expired
    if has_holders; then
      echo "released '$holder'; still held by: $(ls "$HOLDERS" | tr '\n' ' ')"
    else
      restore
      watchdog_alive && kill "$(cat "$PIDFILE")" 2>/dev/null || true
      rm -f "$PIDFILE"
      echo "released '$holder'; suspend settings restored"
    fi
    ;;
  recover)
    # A reboot kills the watchdog but keeps the 'nothing' settings and the leases.
    with_lock
    drop_expired
    if has_holders; then
      start_watchdog
      echo "leases still live; watchdog running"
    else
      restore
      rm -f "$PIDFILE"
      echo "no live lease; suspend settings restored"
    fi
    ;;
  _watch)
    echo $$ >"$PIDFILE"
    while true; do
      sleep 30
      with_lock
      drop_expired
      if ! has_holders; then
        restore
        rm -f "$PIDFILE"
        exit 0
      fi
      exec 9>&-
    done
    ;;
  status)
    now=$(date +%s)
    for key in "${KEYS[@]}"; do echo "$key = $(gsettings get "$SCHEMA" "$key")"; done
    for f in "$HOLDERS"/*; do
      [ -e "$f" ] || continue
      echo "lease $(basename "$f"): $((($(cat "$f") - now) / 60)) min left"
    done
    watchdog_alive && echo "watchdog pid $(cat "$PIDFILE")" || echo "watchdog not running"
    [ -f "$SAVED" ] && echo "saved originals:" && cat "$SAVED" || true
    ;;
  *)
    echo "usage: $0 on <holder> [hours] | off <holder> | status | recover" >&2
    exit 2
    ;;
esac
