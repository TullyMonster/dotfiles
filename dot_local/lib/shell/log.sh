# shellcheck shell=sh

info() {
  printf 'INFO: %s\n' "${*}"
}

warn() {
  printf 'WARN: %s\n' "${*}" >&2
}

error() {
  printf 'ERROR: %s\n' "${*}" >&2
}

fatal() {
  printf 'FATAL: %s\n' "${*}" >&2
  exit 1
}
