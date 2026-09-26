#!/usr/bin/env bash
# bin/lib/install.sh - bootstrap, diagnostics, and version helpers.
# Sourced by bin/mymate after bin/lib/herdr.sh. Keep this file POSIX-ish Bash:
# Git Bash on Windows and the system Bash on macOS/Linux are both supported.

MM_FORCE=0
MM_DRY_RUN=0
MM_DOCTOR_FAILURES=0

mm_is_windows() {
  case "${OS:-}" in
    Windows_NT) return 0 ;;
  esac
  case "$(uname -s 2>/dev/null || printf unknown)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
  esac
  return 1
}

mm_native_path() {
  local path="${1:-}"
  if mm_is_windows && command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$path" 2>/dev/null || printf '%s\n' "$path"
  else
    printf '%s\n' "$path"
  fi
}

mm_path_equivalent() {
  local left right
  if mm_is_windows && command -v cygpath >/dev/null 2>&1; then
    left="$(cygpath -u "$1" 2>/dev/null || printf '%s' "$1")"
    right="$(cygpath -u "$2" 2>/dev/null || printf '%s' "$2")"
  else
    left="$1"
    right="$2"
  fi
  left="$(printf '%s' "$left" | tr '\\' '/' | tr '[:upper:]' '[:lower:]' | sed 's#/*$##')"
  right="$(printf '%s' "$right" | tr '\\' '/' | tr '[:upper:]' '[:lower:]' | sed 's#/*$##')"
  [ "$left" = "$right" ]
}

mm_bin_on_path() {
  local target entry rest
  target="$(cd "$MM_ROOT/bin" && pwd -P)"
  rest="${PATH:-}"
  while :; do
    entry="${rest%%:*}"
    if [ "$entry" = "$rest" ]; then
      rest=""
    else
      rest="${rest#*:}"
    fi
    if [ -n "$entry" ] && mm_path_equivalent "$entry" "$target"; then
      return 0
    fi
    [ -n "$rest" ] || break
  done
  return 1
}

mm_print_path_hint() {
  local windows_bin
  windows_bin="$(mm_native_path "$MM_ROOT/bin")"
  printf '%s\n' "PATH is missing: $MM_ROOT/bin"
  if mm_is_windows; then
    printf '%s\n' "  Git Bash (current shell):"
    printf '    export PATH="%s:$PATH"\n' "$MM_ROOT/bin"
    printf '%s\n' "  PowerShell (current session):"
    printf "    \$env:Path = '%s;' + \$env:Path\n" "$windows_bin"
    printf '%s\n' "  PowerShell (persist for future terminals):"
    printf "    [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path','User') + ';%s', 'User')\n" "$windows_bin"
  else
    printf '%s\n' "  POSIX shell (current shell):"
    printf '    export PATH="%s:$PATH"\n' "$MM_ROOT/bin"
    printf '%s\n' "  Persist it by adding that export to your shell profile."
  fi
}

mm_herdr_version() {
  local line
  line="$(herdr --version 2>/dev/null | head -n 1 || true)"
  line="${line//$'\r'/}"
  if [ -n "$line" ]; then
    printf '%s\n' "$line" | awk '{print $NF}'
    return 0
  fi
  herdr status client 2>/dev/null | awk -F': ' '/^version:/{print $2; exit}'
}

mm_version_core() {
  local version="${1:-}"
  version="${version#v}"
  printf '%s\n' "$version" | awk -F'[.-]' '{
    patch = ($3 ~ /^[0-9]+$/ ? $3 : 0)
    printf "%s.%s.%s\n", $1, $2, patch
  }'
}

mm_version_ge() {
  local have="${1:-0.0.0}" need="${2:-0.0.0}"
  local hmajor hrest hminor hrest2 hpatch nmajor nrest nminor nrest2 npatch
  have="$(mm_version_core "$have")"
  need="$(mm_version_core "$need")"
  hmajor="${have%%.*}"; hrest="${have#*.}"
  hminor="${hrest%%.*}"; hrest2="${hrest#*.}"
  hpatch="${hrest2%%.*}"
  nmajor="${need%%.*}"; nrest="${need#*.}"
  nminor="${nrest%%.*}"; nrest2="${nrest#*.}"
  npatch="${nrest2%%.*}"
  [ "$hmajor" -gt "$nmajor" ] && return 0
  [ "$hmajor" -lt "$nmajor" ] && return 1
  [ "$hminor" -gt "$nminor" ] && return 0
  [ "$hminor" -lt "$nminor" ] && return 1
  [ "$hpatch" -ge "$npatch" ]
}

mm_manifest_field() {
  local key="${1:-}" file="${2:-}"
  [ -n "$key" ] && [ -f "$file" ] || return 1
  awk -F'"' -v key="$key" '$1 ~ "^[[:space:]]*" key "[[:space:]]*=" { print $2; exit }' "$file"
}

mm_server_running() {
  herdr status server 2>/dev/null | grep -q '^status: running'
}

mm_plugin_line() {
  local listing
  listing="$(herdr plugin list 2>/dev/null || true)"
  printf '%s\n' "$listing" | grep -F 'mymate.herdr-status' | head -n 1 || true
}

mm_plugin_path() {
  local line="${1:-}" path
  case "$line" in
    *"local:"*) ;;
    *) return 1 ;;
  esac
  path="${line#*local:}"
  path="${path%%]*}"
  path="$(printf '%s' "$path" | sed 's#^\\\\?\\##')"
  [ -n "$path" ] || return 1
  printf '%s\n' "$path"
}

mm_plugin_enabled() {
  case "${1:-}" in
    *" enabled"*) return 0 ;;
    *) return 1 ;;
  esac
}

mm_herdr_check() {
  local version minimum
  if ! command -v herdr >/dev/null 2>&1; then
    printf '%s\n' "[FAIL] herdr is not on PATH"
    return 1
  fi
  version="$(mm_herdr_version 2>/dev/null || true)"
  minimum="$(mm_manifest_field min_herdr_version "$MM_ROOT/herdr-status-plugin/herdr-plugin.toml" 2>/dev/null || printf '0.8.0')"
  if [ -z "$version" ]; then
    printf '%s\n' "[FAIL] herdr is present but its version could not be read"
    return 1
  fi
  if ! mm_version_ge "$version" "$minimum"; then
    printf '%s\n' "[FAIL] herdr $version is older than the plugin minimum $minimum"
    return 1
  fi
  printf '%s\n' "[ok] herdr $version (minimum $minimum)"
  if ! mm_server_running; then
    printf '%s\n' "[warn] herdr server is not running; start herdr before linking/enabling the plugin"
  fi
  return 0
}

mm_skill_dir() {
  if [ -n "${MM_SKILLS_DIR:-}" ]; then
    printf '%s\n' "$MM_SKILLS_DIR"
  elif [ -n "${HOME:-}" ]; then
    printf '%s/.agents/skills\n' "$HOME"
  elif [ -n "${USERPROFILE:-}" ] && command -v cygpath >/dev/null 2>&1; then
    printf '%s/.agents/skills\n' "$(cygpath -u "$USERPROFILE")"
  else
    printf '%s/.agents/skills\n' "$MM_ROOT"
  fi
}

mm_skill_target() {
  printf '%s/mymate/SKILL.md\n' "$(mm_skill_dir)"
}

mm_skill_status() {
  local source="$MM_ROOT/mymate.skill.md" target
  target="$(mm_skill_target)"
  [ -f "$source" ] || { printf '%s\n' missing-source; return 0; }
  [ -f "$target" ] || { printf '%s\n' missing; return 0; }
  if cmp -s "$source" "$target"; then
    printf '%s\n' current
  else
    printf '%s\n' stale
  fi
}

mm_install_skill() {
  local source="$MM_ROOT/mymate.skill.md" target status backup
  target="$(mm_skill_target)"
  if [ ! -f "$source" ]; then
    printf '%s\n' "[FAIL] conductor skill source is missing: $source"
    return 1
  fi
  status="$(mm_skill_status)"
  case "$status" in
    current)
      printf '%s\n' "[ok] conductor skill is current: $target"
      return 0
      ;;
    missing)
      if [ "$MM_DRY_RUN" = 1 ]; then
        printf '%s\n' "[plan] would install conductor skill: $target"
      else
        mkdir -p "$(dirname "$target")"
        cp "$source" "$target"
        printf '%s\n' "[ok] installed conductor skill: $target"
      fi
      return 0
      ;;
    stale)
      if [ "$MM_FORCE" != 1 ]; then
        printf '%s\n' "[warn] conductor skill is STALE and was not overwritten: $target"
        printf '%s\n' "       run: mymate install --force"
        return 1
      fi
      if [ "$MM_DRY_RUN" = 1 ]; then
        printf '%s\n' "[plan] would replace stale conductor skill: $target"
      else
        backup="${target}.bak.$(date +%Y%m%d-%H%M%S).$$"
        cp -p "$target" "$backup"
        cp "$source" "$target"
        printf '%s\n' "[ok] replaced stale conductor skill; backup: $backup"
      fi
      return 0
      ;;
    *)
      printf '%s\n' "[FAIL] could not compare conductor skill: $target"
      return 1
      ;;
  esac
}

mm_install_plugin() {
  local plugin_dir="$MM_ROOT/herdr-status-plugin" line linked native_dir
  native_dir="$(mm_native_path "$plugin_dir")"
  if ! mm_is_windows; then
    printf '%s\n' "[skip] native herdr-status plugin is Windows-only on this platform"
    return 0
  fi
  if [ ! -f "$plugin_dir/herdr-plugin.toml" ]; then
    printf '%s\n' "[FAIL] plugin manifest is missing: $plugin_dir/herdr-plugin.toml"
    return 1
  fi
  if ! mm_server_running; then
    printf '%s\n' "[FAIL] herdr server is not running; start herdr, then rerun mymate install"
    return 1
  fi

  line="$(mm_plugin_line)"
  if [ -n "$line" ]; then
    linked="$(mm_plugin_path "$line" || true)"
    if [ -n "$linked" ] && mm_path_equivalent "$linked" "$plugin_dir"; then
      printf '%s\n' "[ok] herdr-status plugin is linked to this checkout"
    elif [ "$MM_FORCE" != 1 ]; then
      printf '%s\n' "[warn] herdr-status plugin is linked to a different checkout: ${linked:-unknown}"
      printf '%s\n' "       run herdr plugin unlink mymate.herdr-status, then mymate install --force"
      return 1
    elif [ "$MM_DRY_RUN" = 1 ]; then
      printf '%s\n' "[plan] would relink herdr-status plugin to: $native_dir"
    else
      herdr plugin unlink mymate.herdr-status >/dev/null
      herdr plugin link "$native_dir" >/dev/null || {
        printf '%s\n' "[FAIL] herdr plugin link failed"
        return 1
      }
      printf '%s\n' "[ok] relinked herdr-status plugin"
    fi
  else
    if [ "$MM_DRY_RUN" = 1 ]; then
      printf '%s\n' "[plan] would link herdr-status plugin: $native_dir"
    else
      herdr plugin link "$native_dir" >/dev/null || {
        printf '%s\n' "[FAIL] herdr plugin link failed"
        return 1
      }
      printf '%s\n' "[ok] linked herdr-status plugin"
    fi
  fi

  line="$(mm_plugin_line)"
  if mm_plugin_enabled "$line"; then
    printf '%s\n' "[ok] herdr-status plugin is enabled"
    return 0
  fi
  if [ "$MM_DRY_RUN" = 1 ]; then
    printf '%s\n' "[plan] would enable mymate.herdr-status"
    return 0
  fi
  herdr plugin enable mymate.herdr-status >/dev/null || {
    printf '%s\n' "[FAIL] herdr plugin enable failed"
    return 1
  }
  printf '%s\n' "[ok] enabled mymate.herdr-status"
}

mm_install_state_dir() {
  if [ "$MM_DRY_RUN" = 1 ]; then
    printf '%s\n' "[plan] would create state directory: $MM_DATA_DIR"
    return 0
  fi
  if mkdir -p "$MM_DATA_DIR" 2>/dev/null && [ -w "$MM_DATA_DIR" ]; then
    printf '%s\n' "[ok] state directory is ready: $MM_DATA_DIR"
    return 0
  fi
  printf '%s\n' "[FAIL] state directory is not writable: $MM_DATA_DIR"
  return 1
}

mm_install_policy() {
  local target="${MM_POLICY_TARGET:-$MM_ROOT/conductor-policy.md}"
  local template="$MM_ROOT/templates/conductor-policy.md"
  if [ -e "$target" ]; then
    printf '%s\n' "[ok] conductor policy already exists (not overwritten): $target"
    return 0
  fi
  if [ ! -f "$template" ]; then
    printf '%s\n' "[FAIL] policy template is missing: $template"
    return 1
  fi
  if [ "$MM_DRY_RUN" = 1 ]; then
    printf '%s\n' "[plan] would seed conductor policy: $target"
    return 0
  fi
  mkdir -p "$(dirname "$target")"
  cp "$template" "$target"
  printf '%s\n' "[ok] seeded conductor policy: $target"
}

mm_print_crew_board() {
  printf '\n%s\n' '=== crew board ==='
  if ! command -v herdr >/dev/null 2>&1 || ! mm_server_running; then
    printf '%s\n' '[warn] crew board unavailable: start herdr and rerun mymate status'
    return 0
  fi
  if declare -F cmd_status >/dev/null 2>&1; then
    cmd_status || printf '%s\n' '[warn] crew board could not be read'
  else
    printf '%s\n' '[warn] crew board command is unavailable'
  fi
}

cmd_install() {
  local failures=0
  MM_FORCE=0
  MM_DRY_RUN=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --force) MM_FORCE=1 ;;
      --dry-run) MM_DRY_RUN=1 ;;
      *) printf '%s\n' "usage: mymate install [--force] [--dry-run]"; return 2 ;;
    esac
    shift
  done

  printf '%s\n' "mymate install (version $VERSION; plugin $PLUGIN_VERSION)"
  if [ "$MM_DRY_RUN" = 1 ]; then
    printf '%s\n' '[dry-run] no files, links, or environment variables will be changed'
  fi

  mm_herdr_check || failures=$((failures + 1))
  mm_install_plugin || failures=$((failures + 1))
  mm_install_skill || failures=$((failures + 1))

  if mm_bin_on_path; then
    printf '%s\n' "[ok] bin is on PATH: $MM_ROOT/bin"
  else
    mm_print_path_hint
  fi

  mm_install_state_dir || failures=$((failures + 1))
  mm_install_policy || failures=$((failures + 1))

  if [ "$MM_DRY_RUN" = 1 ]; then
    printf '%s\n' '[dry-run] crew board skipped'
  else
    mm_print_crew_board
  fi

  if [ "$failures" -gt 0 ]; then
    printf '\ninstall finished with %d issue(s); resolve them and rerun safely.\n' "$failures"
    return 1
  fi
  printf '\n%s\n' 'install complete'
  return 0
}

doctor_pass() { printf '[ok] %-20s %s\n' "$1" "$2"; }
doctor_warn() { printf '[warn] %-20s %s\n' "$1" "$2"; }
doctor_fail() {
  printf '[FAIL] %-20s %s\n' "$1" "$2"
  MM_DOCTOR_FAILURES=$((MM_DOCTOR_FAILURES + 1))
}

cmd_doctor() {
  local version minimum line linked status target bash_path git_path probe
  MM_DOCTOR_FAILURES=0
  printf '%s\n' "mymate doctor (version $VERSION; plugin $PLUGIN_VERSION)"

  if command -v herdr >/dev/null 2>&1; then
    version="$(mm_herdr_version 2>/dev/null || true)"
    minimum="$(mm_manifest_field min_herdr_version "$MM_ROOT/herdr-status-plugin/herdr-plugin.toml" 2>/dev/null || printf '0.8.0')"
    if [ -n "$version" ] && mm_version_ge "$version" "$minimum"; then
      doctor_pass 'herdr' "$version (minimum $minimum)"
    else
      doctor_fail 'herdr' "present but version '$version' is unusable or below $minimum"
    fi
    if mm_server_running; then
      doctor_pass 'herdr server' 'running'
    else
      doctor_warn 'herdr server' 'not running; start herdr for plugin/crew operations'
    fi
  else
    doctor_fail 'herdr' 'not found on PATH'
  fi

  if [ "${HERDR_ENV:-}" = 1 ]; then
    doctor_pass 'inside herdr' 'HERDR_ENV=1'
  else
    doctor_warn 'inside herdr' 'HERDR_ENV is not 1; mutating commands will refuse'
  fi

  if mm_bin_on_path; then
    doctor_pass 'bin on PATH' "$MM_ROOT/bin"
  else
    doctor_warn 'bin on PATH' "missing; add $MM_ROOT/bin"
  fi

  bash_path="$(command -v bash 2>/dev/null || true)"
  git_path="$(command -v git 2>/dev/null || true)"
  if [ -n "$bash_path" ] && [ -n "$git_path" ]; then
    doctor_pass 'git bash' "bash=$bash_path; git=$git_path"
  elif mm_is_windows; then
    doctor_fail 'git bash' 'bash and/or git is missing; install Git for Windows'
  else
    doctor_fail 'git bash' 'bash and/or git is missing'
  fi

  if ! mm_is_windows; then
    doctor_warn 'plugin' 'Windows-only native bridge skipped on this platform'
  elif ! mm_server_running; then
    doctor_fail 'plugin' 'cannot inspect; herdr server is not running'
  else
    line="$(mm_plugin_line)"
    if [ -z "$line" ]; then
      doctor_fail 'plugin' 'mymate.herdr-status is not linked; run mymate install'
    else
      linked="$(mm_plugin_path "$line" || true)"
      if [ -z "$linked" ] || ! mm_path_equivalent "$linked" "$MM_ROOT/herdr-status-plugin"; then
        doctor_fail 'plugin' "linked to a different checkout: ${linked:-unknown}"
      elif ! mm_plugin_enabled "$line"; then
        doctor_fail 'plugin' 'linked but disabled; run herdr plugin enable mymate.herdr-status'
      else
        doctor_pass 'plugin' 'linked to this checkout and enabled'
      fi
    fi
  fi

  target="$(mm_skill_target)"
  status="$(mm_skill_status)"
  case "$status" in
    current) doctor_pass 'conductor skill' "current: $target" ;;
    stale)
      doctor_fail 'conductor skill' "STALE: $target (run mymate install --force)"
      ;;
    missing)
      doctor_fail 'conductor skill' "missing: $target (run mymate install)"
      ;;
    *)
      doctor_fail 'conductor skill' "source or target unreadable: $target"
      ;;
  esac

  if [ ! -d "$MM_DATA_DIR" ]; then
    doctor_fail 'state directory' "missing: $MM_DATA_DIR (run mymate install)"
  elif [ ! -w "$MM_DATA_DIR" ]; then
    doctor_fail 'state directory' "not writable: $MM_DATA_DIR"
  else
    probe="$MM_DATA_DIR/.mymate-doctor-$$"
    if : > "$probe" 2>/dev/null; then
      rm -f "$probe"
      doctor_pass 'state directory' "writable: $MM_DATA_DIR"
    else
      doctor_fail 'state directory' "write probe failed: $MM_DATA_DIR"
    fi
  fi

  if command -v jq >/dev/null 2>&1; then
    doctor_pass 'jq' "$(command -v jq) (optional)"
  else
    doctor_warn 'jq' 'not found (optional; install jq for formatted boards)'
  fi

  if [ "$MM_DOCTOR_FAILURES" -gt 0 ]; then
    printf '\ndoctor: %d hard failure(s)\n' "$MM_DOCTOR_FAILURES"
    return 1
  fi
  printf '\n%s\n' 'doctor: all required checks passed'
  return 0
}
