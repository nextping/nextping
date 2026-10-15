#!/bin/sh
# NextPing plugin launcher (Plan 4, Decision 4). Runs nextping from the plugin data dir and
# installs it there on first use, in the background. Hooks must never break the agent: every hook
# path exits 0 with no output (except the "installing" message). `mcp` exits 1 when there is no
# binary yet, so Claude Code shows the server as failed and /mcp can reconnect it later.
#
# Env: CLAUDE_PLUGIN_DATA (set by Claude Code), NEXTPING_AGENT_BIN (use this binary; development),
# NEXTPING_DOWNLOAD_BASE (release base URL), NEXTPING_MCP_INSTALL_WAIT (half-seconds, default 40).
# Sets NEXTPING_AGENT_PID (this launcher's parent) for the binary.
set -u

# The agent that started this launcher (Claude Code), for the session anchor. The binary is exec'd,
# so on POSIX its parent pid is the same. Under Git Bash on Windows $PPID is an MSYS pid, not a
# Windows one: unset it there, and the binary walks up past this sh.exe itself (agentParentPid).
# OSTYPE is read instead of running uname: this runs on every hook, PostToolUse included.
# The background installer is started by this script, so it keeps the value it inherited.
if [ "${1:-}" != __install ]; then
  # shellcheck disable=SC3028 # set by bash (Git Bash's sh is bash); empty under dash: the POSIX branch
  case "${OSTYPE:-}" in
    msys* | cygwin*) unset NEXTPING_AGENT_PID ;;
    *)
      NEXTPING_AGENT_PID=$PPID
      export NEXTPING_AGENT_PID
      ;;
  esac
fi

DATA=${CLAUDE_PLUGIN_DATA:-${HOME:-.}/.nextping-plugin}
BIN_DIR="$DATA/bin"
if [ -x "$BIN_DIR/nextping.exe" ]; then BIN="$BIN_DIR/nextping.exe"; else BIN="$BIN_DIR/nextping"; fi

present() { [ -n "${NEXTPING_AGENT_BIN:-}" ] || [ -x "$BIN" ]; }

run_bin() {
  if [ -n "${NEXTPING_AGENT_BIN:-}" ]; then exec "$NEXTPING_AGENT_BIN" "$@"; fi
  exec "$BIN" "$@"
}

# Hot path (Decision 3): PostToolUse runs after every tool call. Without an inbox marker for this
# session there is nothing to deliver, so exit before starting the binary (shell builtins and one
# `cat`). The SessionStart hook writes `nextping-home`; without it, the binary decides (slower).
# The marker name is markerName("claude:<session_id>") from src/surfaces/markers.ts. Only ids it
# keeps unchanged (safe characters, at most 193 so its 200-character cut never applies) are checked
# here; for any other id, or a second "session_id" key in the input, the binary parses the JSON.
if [ "${1:-}" = hook ] && [ "${2:-}" = post-tool-use ]; then
  present || exit 0
  input=$(cat)
  if [ -r "$DATA/nextping-home" ] && IFS= read -r THOME < "$DATA/nextping-home" && [ -n "$THOME" ]; then
    case "$input" in *'"agent_id":"'?*) exit 0 ;; esac
    rest=${input#*\"session_id\":\"}
    if [ "$rest" != "$input" ]; then
      sid=${rest%%\"*}
      case "$rest" in
        *'"session_id":"'*) ;;
        *)
          case "$sid" in
            '' | *[!A-Za-z0-9_.-]*) ;;
            *) [ "${#sid}" -gt 193 ] || [ -e "$THOME/pending/claude_$sid" ] || exit 0 ;;
          esac
          ;;
      esac
    fi
  fi
  run_bin "$@" <<EOF
$input
EOF
fi

# Other hooks never install anything; they only need the binary.
if [ "${1:-}" = hook ] && [ "${2:-}" != session-start ]; then
  present && run_bin "$@"
  exit 0
fi
if [ "${1:-}" = mcp ] && present; then run_bin "$@"; fi

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
NEXTPING_VERSION=
# shellcheck source=/dev/null
[ -f "$ROOT/scripts/binary.env" ] && . "$ROOT/scripts/binary.env"

case "$(uname -s 2>/dev/null)" in
  Darwin) OS=darwin ;;
  Linux) OS=linux ;;
  MINGW* | MSYS* | CYGWIN*) OS=windows ;;
  *) OS=unknown ;;
esac
case "$(uname -m 2>/dev/null)" in
  arm64 | aarch64) ARCH=arm64 ;;
  x86_64 | amd64) ARCH=x64 ;;
  *) ARCH=unknown ;;
esac
EXT=
[ "$OS" = windows ] && EXT=.exe
BIN="$BIN_DIR/nextping$EXT"
ASSET="nextping-$OS-$ARCH$EXT"
LOG="$DATA/install.log"

# Never recreates a data dir that was removed (uninstall) while an install ran in the background.
log() {
  [ -d "$DATA" ] && printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG" 2>/dev/null
}

current() {
  [ -n "${NEXTPING_AGENT_BIN:-}" ] || { [ -x "$BIN" ] && [ "$(cat "$BIN_DIR/VERSION" 2>/dev/null)" = "$NEXTPING_VERSION" ]; }
}

# OS and ARCH come from the fixed lists above, so this eval only ever reads NEXTPING_SHA256_<os>_<arch>.
expected_sum() { eval "printf '%s' \"\${NEXTPING_SHA256_${OS}_${ARCH}:-}\""; }

# Read from stdin: given a file name with a backslash (any Windows path), sha256sum and shasum
# escape it and start the line with "\", which then never matches the pinned sum.
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum < "$1" | cut -d ' ' -f 1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 < "$1" | cut -d ' ' -f 1
  else
    return 1
  fi
}

fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 2 --connect-timeout 15 -o "$2" "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$2" "$1"
  else
    return 1
  fi
}

# Downloads the pinned binary, checks its SHA-256 and swaps it in. A second installer waits for
# the first instead of racing it; a lock older than 10 minutes is stale.
install_binary() {
  mkdir -p "$BIN_DIR" || return 1
  LOCK="$BIN_DIR/.install.lock"
  waited=0
  until mkdir "$LOCK" 2>/dev/null; do
    [ -d "$BIN_DIR" ] || return 1
    if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +10 2>/dev/null)" ]; then
      rm -rf "$LOCK"
      continue
    fi
    [ "$waited" -ge 600 ] && return 1
    sleep 1
    waited=$((waited + 1))
  done
  trap 'rm -rf "$LOCK"' EXIT
  if current; then return 0; fi
  want=$(expected_sum)
  if [ -z "$NEXTPING_VERSION" ] || [ -z "$want" ]; then
    log "no pinned checksum for $ASSET v$NEXTPING_VERSION (set NEXTPING_AGENT_BIN for development)"
    return 1
  fi
  base=${NEXTPING_DOWNLOAD_BASE:-https://github.com/nextping/nextping/releases/download}
  base=${base%/}
  tmp="$BIN_DIR/.download.$$"
  if ! fetch "$base/v$NEXTPING_VERSION/$ASSET" "$tmp"; then
    log "download failed: $ASSET v$NEXTPING_VERSION"
    rm -f "$tmp"
    return 1
  fi
  got=$(sha256_of "$tmp" || true)
  if [ "$got" != "$want" ]; then
    log "checksum mismatch: $ASSET v$NEXTPING_VERSION"
    rm -f "$tmp"
    return 1
  fi
  chmod 755 "$tmp"
  # Windows can rename a running .exe but not overwrite it.
  if [ -e "$BIN" ]; then mv -f "$BIN" "$BIN.old" 2>/dev/null; fi
  if ! mv -f "$tmp" "$BIN"; then
    log "could not place $BIN"
    return 1
  fi
  printf '%s\n' "$NEXTPING_VERSION" > "$BIN_DIR/VERSION"
  rm -f "$BIN.old" 2>/dev/null
  log "installed $ASSET v$NEXTPING_VERSION"
  return 0
}

# $1: a saved SessionStart input to replay once installed, or empty.
start_background_install() {
  mkdir -p "$DATA" 2>/dev/null || return 0
  nohup sh "$0" __install "${1:-}" >> "$LOG" 2>&1 < /dev/null &
}

INSTALLING='{"systemMessage":"NextPing is installing its background service (first run). A pairing page opens in your browser when it is ready.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"NextPing (phone notifications) is still installing; its MCP tools appear in the next session."}}'

case "${1:-}" in
  __install)
    saved=${2:-}
    if install_binary && [ -n "$saved" ] && [ -f "$saved" ] && [ -x "$BIN" ]; then
      "$BIN" hook session-start < "$saved" > /dev/null 2>&1
    fi
    [ -n "$saved" ] && rm -f "$saved"
    exit 0
    ;;
  hook)
    if [ "${2:-}" = session-start ] && ! current; then
      if present; then
        start_background_install ""
        run_bin "$@"
      fi
      mkdir -p "$DATA" 2>/dev/null || exit 0
      saved="$DATA/session-start.$$.json"
      cat > "$saved" 2>/dev/null || exit 0
      start_background_install "$saved"
      printf '%s\n' "$INSTALLING"
      exit 0
    fi
    present && run_bin "$@"
    exit 0
    ;;
  mcp)
    if ! present; then
      start_background_install ""
      i=0
      while [ "$i" -lt "${NEXTPING_MCP_INSTALL_WAIT:-40}" ] && ! present; do
        sleep 0.5
        i=$((i + 1))
      done
    fi
    present && run_bin "$@"
    echo "NextPing is still installing; run /mcp to reconnect in a minute." >&2
    exit 1
    ;;
  *)
    present && run_bin "$@"
    echo "nextping is not installed yet; start a Claude Code session to install it." >&2
    exit 1
    ;;
esac
