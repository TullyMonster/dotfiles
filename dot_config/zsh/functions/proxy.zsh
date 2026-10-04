typeset -ga _proxy_managed_vars=(http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY)
typeset -ga _proxy_result
typeset -gA _proxy_original_bypass_values
typeset -gA _proxy_original_bypass_exported
typeset -g _proxy_host='127.0.0.1'
typeset -g _proxy_active_port
typeset -gi _proxy_rc_runtime=1
typeset -gi _proxy_rc_usage=2

_proxy_validate_port() {
  emulate -L zsh
  local port="${1}"
  [[ ${port} == <1-65535> ]] || {
    print -u2 -- "Invalid port: ${1:-<empty>} (expected 1..65535)"
    return ${_proxy_rc_usage}
  }
  _proxy_result=("$((10#${port}))")
}

_proxy_discover() {
  emulate -L zsh
  local ss_output socket_record listen_address
  local -A seen_ports
  ss_output=$(command ss -H -ltnp 2> /dev/null) || {
    print -u2 -- 'Failed to query TCP listening sockets'
    return ${_proxy_rc_runtime}
  }
  while read -r socket_record; do
    [[ ${socket_record} == *'users:(("sshd"'* || ${socket_record} == *'users:(("sshd-session"'* ]] || continue
    listen_address=${${(z)socket_record}[4]}
    [[ -n ${listen_address} ]] || continue
    [[ ${listen_address} == 127.0.0.1:<-> || ${listen_address} == \[::1\]:<-> ]] || continue
    _proxy_validate_port "${listen_address##*:}" > /dev/null 2>&1 || continue

    seen_ports[${_proxy_result[1]}]=
  done <<< "${ss_output}"
  _proxy_result=("${(@kon)seen_ports}")
}

_proxy_probe() {
  emulate -L zsh
  local port="${1}" result url='https://www.gstatic.com/generate_204'
  local -i http=0 socks=0
  local -a args=(--silent --output /dev/null --write-out '%{http_code}' --connect-timeout 2 --max-time 5 --location --noproxy '')
  result=$(command curl "${args[@]}" --proxy "http://${_proxy_host}:${port}" "${url}" 2> /dev/null) && [[ ${result} == 204 ]] && http=1
  result=$(command curl "${args[@]}" --proxy "socks5h://${_proxy_host}:${port}" "${url}" 2> /dev/null) && [[ ${result} == 204 ]] && socks=1
  _proxy_result=("${http}" "${socks}")
  ((http || socks))
}

_proxy_resolve() {
  emulate -L zsh
  local requested_port="${1:-}" candidate_port no_usable_message
  local -a candidate_ports usable_ports proxy_capabilities
  if [[ -n ${requested_port} ]]; then
    _proxy_validate_port "${requested_port}" || return
    candidate_ports=("${_proxy_result[1]}")
    no_usable_message="Port ${_proxy_result[1]} is not a working proxy for the target site"
  else
    _proxy_discover || return
    candidate_ports=("${_proxy_result[@]}")
    no_usable_message='No usable sshd loopback proxy port found'
  fi
  for candidate_port in "${candidate_ports[@]}"; do
    _proxy_probe "${candidate_port}" || continue
    usable_ports+=("${candidate_port}")
    proxy_capabilities=("${_proxy_result[@]}")
  done
  if ((${#usable_ports} == 0)); then
    print -u2 -- "${no_usable_message}"
    return ${_proxy_rc_runtime}
  elif ((${#usable_ports} > 1)); then
    print -u2 -- "Multiple usable proxy ports found: ${(j:, :)usable_ports}; use proxy on <port> or pass --port <port> for a one-off command"
    return ${_proxy_rc_runtime}
  else
    _proxy_result=("${usable_ports[1]}" "${proxy_capabilities[@]}")
  fi
}

_proxy_merge_bypass() {
  emulate -L zsh
  local bypass_value bypass_entry
  local -A bypass_set=(localhost '' 127.0.0.1 '' ::1 '')
  for bypass_value in "${@}"; do
    for bypass_entry in "${(@s:,:)bypass_value}"; do
      [[ -n ${bypass_entry} ]] || continue
      bypass_set[(e)${bypass_entry}]=
    done
  done
  _proxy_result=("${(j:,:)${(@k)bypass_set}}")
}

_proxy_apply() {
  emulate -L zsh
  local port="${1}" http_supported="${2}" socks_supported="${3}" bypass_list="${4}"
  unset "${_proxy_managed_vars[@]}"
  ((http_supported)) && export http_proxy="http://${_proxy_host}:${port}" https_proxy="http://${_proxy_host}:${port}" HTTPS_PROXY="http://${_proxy_host}:${port}"
  ((socks_supported)) && export all_proxy="socks5h://${_proxy_host}:${port}" ALL_PROXY="socks5h://${_proxy_host}:${port}"
  export no_proxy="${bypass_list}" NO_PROXY="${bypass_list}"
}

_proxy_on() {
  emulate -L zsh
  local env_var selected_port protocol_label='SOCKS'
  local -i http_supported socks_supported
  if [[ -z ${_proxy_active_port} ]]; then
    for env_var in "${_proxy_managed_vars[@]}"; do
      ((${+parameters[${env_var}]})) || continue
      print -u2 -- "Existing proxy variable ${env_var}; clear it before enabling proxy"
      return ${_proxy_rc_runtime}
    done
    _proxy_original_bypass_values=()
    _proxy_original_bypass_exported=()
    for env_var in no_proxy NO_PROXY; do
      ((${+parameters[${env_var}]})) || continue
      _proxy_original_bypass_values[${env_var}]=${(P)env_var}
      [[ ${parameters[${env_var}]} == *-export* ]] && _proxy_original_bypass_exported[${env_var}]=
    done
  fi
  _proxy_resolve "${1:-}" || return
  selected_port=${_proxy_result[1]}
  http_supported=${_proxy_result[2]}
  socks_supported=${_proxy_result[3]}
  _proxy_merge_bypass "${_proxy_original_bypass_values[no_proxy]-}" "${_proxy_original_bypass_values[NO_PROXY]-}"
  _proxy_apply "${selected_port}" "${http_supported}" "${socks_supported}" "${_proxy_result[1]}"
  _proxy_active_port=${selected_port}
  ((http_supported)) && protocol_label='HTTP/HTTPS'
  ((http_supported && socks_supported)) && protocol_label='HTTP/HTTPS and SOCKS'
  print -- "Proxy enabled: ${_proxy_host}:${selected_port} (${protocol_label})"
}

_proxy_off() {
  emulate -L zsh
  local env_var
  [[ -n ${_proxy_active_port} ]] || {
    print -- 'Proxy not enabled'
    return
  }
  unset "${_proxy_managed_vars[@]}" no_proxy NO_PROXY
  for env_var in no_proxy NO_PROXY; do
    ((${+_proxy_original_bypass_values[${env_var}]})) || continue
    typeset -g "${env_var}=${_proxy_original_bypass_values[${env_var}]}"
    ((${+_proxy_original_bypass_exported[${env_var}]})) && export "${env_var}" # shuck: ignore=C105
  done
  _proxy_active_port=''
  _proxy_original_bypass_values=()
  _proxy_original_bypass_exported=()
  print -- 'Proxy disabled; original environment restored'
}

_proxy_status() {
  emulate -L zsh
  local protocol_label='SOCKS'
  [[ -n ${_proxy_active_port} ]] || {
    print -- 'Proxy not enabled'
    return
  }
  _proxy_probe "${_proxy_active_port}" || {
    print -- "Proxy enabled: ${_proxy_host}:${_proxy_active_port} (currently unreachable)"
    return ${_proxy_rc_runtime}
  }
  ((_proxy_result[1])) && protocol_label='HTTP/HTTPS'
  ((_proxy_result[1] && _proxy_result[2])) && protocol_label='HTTP/HTTPS and SOCKS'
  print -- "Proxy enabled: ${_proxy_host}:${_proxy_active_port} (${protocol_label}; reachable)"
}

_proxy_select() {
  emulate -L zsh
  if [[ -n ${1:-} || -z ${_proxy_active_port} ]]; then
    _proxy_resolve "${1:-}"
    return
  fi
  _proxy_probe "${_proxy_active_port}" || {
    print -u2 -- "Current proxy port ${_proxy_active_port} is unreachable"
    return ${_proxy_rc_runtime}
  }
  _proxy_result=("${_proxy_active_port}" "${_proxy_result[@]}")
}

_proxy_run() (
  emulate -L zsh
  local requested_port='' selected_port command_name adapter_function
  local -i http_supported socks_supported target_command_index=1
  local -a command_args
  if [[ ${1:-} == --port ]]; then
    ((${#} >= 2)) || {
      print -u2 -- 'proxy run: --port requires a port'
      return ${_proxy_rc_usage}
    }
    requested_port=${2}
    shift 2
  fi
  if [[ ${1:-} != -- ]] || ((${#} < 2)); then
    print -u2 -- 'Usage: proxy run [--port PORT] -- COMMAND...'
    return ${_proxy_rc_usage}
  fi
  shift
  command_args=("${@}")
  _proxy_select "${requested_port}" || return
  selected_port=${_proxy_result[1]}
  http_supported=${_proxy_result[2]}
  socks_supported=${_proxy_result[3]}
  _proxy_merge_bypass "${no_proxy-}" "${NO_PROXY-}"
  _proxy_apply "${selected_port}" "${http_supported}" "${socks_supported}" "${_proxy_result[1]}"
  case ${command_args[1]} in
    sudo | /usr/bin/sudo)
      case ${command_args[2]-} in
        --)
          ((${#command_args} >= 3)) && target_command_index=3
          ;;
        -* | *=* | '') ;;
        *)
          target_command_index=2
          ;;
      esac
      ;;
  esac
  command_name=${command_args[target_command_index]:t}
  adapter_function="_proxy_run_adapter_${command_name}"
  if ((${+functions[(e)${adapter_function}]})); then
    print -u2 -- "INFO: Using command-specific proxy handling for ${command_name}"
    _proxy_result=()
    "${adapter_function}" "${selected_port}" "${http_supported}" "${socks_supported}" || return ${?}
    command_args=(
      "${(@)command_args[1,target_command_index]}"
      "${_proxy_result[@]}"
      "${(@)command_args[target_command_index+1,-1]}"
    )
  elif [[ ${command_args[1]:t} == sudo ]]; then
    print -u2 -- 'WARN: No command-specific handling for this sudo invocation; sudo may discard proxy environment variables'
  else
    print -u2 -- "INFO: Command-specific proxy handling not applied to ${command_args[target_command_index]}; using proxy environment only"
  fi
  command "${command_args[@]}"
)

_proxy_run_adapter_apt() {
  emulate -L zsh
  local selected_port="${1}" http_supported="${2}" socks_supported="${3}" proxy_uri
  if ((http_supported)); then
    proxy_uri="http://${_proxy_host}:${selected_port}"
  elif ((socks_supported)); then
    proxy_uri="socks5h://${_proxy_host}:${selected_port}"
  else
    print -u2 -- 'No supported proxy protocol available for apt'
    return ${_proxy_rc_runtime}
  fi
  _proxy_result=(-o "Acquire::http::Proxy=${proxy_uri}" -o "Acquire::https::Proxy=${proxy_uri}")
}

_proxy_usage() {
  print -u2 -- 'Usage:'
  print -u2 -- $'  proxy\n  proxy on [PORT]\n  proxy off\n  proxy run [--port PORT] -- COMMAND...\n'
  print -u2 -- 'Commands:'
  print -u2 -- '  proxy              Show current proxy status.'
  print -u2 -- '  proxy on           Enable a proxy, automatically discovering a usable port.'
  print -u2 -- '  proxy on PORT      Enable a proxy using the specified port.'
  print -u2 -- '  proxy off          Disable the proxy and restore the original environment.'
  print -u2 -- '  proxy run ...      Run one command with temporary proxy settings.'
}

proxy() {
  emulate -L zsh
  local subcommand
  ((${#})) || {
    _proxy_status
    return
  }
  subcommand=${1}
  shift
  case ${subcommand} in
    on)
      ((${#} <= 1)) || {
        _proxy_usage
        return ${_proxy_rc_usage}
      }
      _proxy_on "${1:-}"
      ;;
    off)
      ((${#} == 0)) || {
        _proxy_usage
        return ${_proxy_rc_usage}
      }
      _proxy_off
      ;;
    run)
      _proxy_run "${@}"
      ;;
    *)
      _proxy_usage
      return ${_proxy_rc_usage}
      ;;
  esac
}
