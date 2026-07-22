#!/usr/bin/env -S uv run --script
# ruff: noqa: D100,D103
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "psutil>=7.2.2,<8",
#   "tomli-w>=1.2,<2",
# ]
# ///
from __future__ import annotations

import argparse
import ipaddress
import os
import subprocess
import sys
import time
import tomllib
from collections.abc import Mapping
from pathlib import Path
from typing import Final

import psutil
import tomli_w

type SettingValue = str | int
type Settings = dict[str, SettingValue]
type Server = tuple[str, int, Path]

ROOT: Final = Path(__file__).resolve().parent
CONFIG_PATH: Final = ROOT / 'ida-dbgsrv.toml'
LOG_PATH: Final = ROOT / 'ida-dbgsrv.log'
SERVER_BINARIES: Final[dict[str, str]] = {'x86': 'win32_remote32.exe', 'x64': 'win64_remote.exe'}
DEFAULT_SETTINGS: Final[Settings] = {'host': '127.0.0.1', 'port': 23946, 'password': ''}
PSUTIL_PATH_ERRORS: Final = (psutil.AccessDenied, psutil.NoSuchProcess, psutil.ZombieProcess)


def main(argv: list[str] | None = None) -> int:
    try:
        args = _parse_args(argv)
        if args.command == 'start':
            return _cmd_start(args)
        if args.command == 'stop':
            return _cmd_stop()
        return _cmd_log()
    except (ValueError, OSError, psutil.Error, tomllib.TOMLDecodeError) as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print('', file=sys.stderr)
        return 130


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Manage one IDA Windows remote debug server.', allow_abbrev=False)
    subcommands = parser.add_subparsers(dest='command', required=True)
    start = subcommands.add_parser('start', help='start one debugger server', allow_abbrev=False)
    start.add_argument('--arch', choices=tuple(SERVER_BINARIES), required=True)
    for option in ('--host', '--password'):
        start.add_argument(option)
    start.add_argument('--port', type=int)
    subcommands.add_parser('stop', help='stop exact-path debugger servers', allow_abbrev=False)
    subcommands.add_parser('log', help=f'show {LOG_PATH.name} from the beginning and follow while an exact-path server runs', allow_abbrev=False)
    return parser.parse_args(argv)


def _cmd_start(args: argparse.Namespace) -> int:
    _require_windows()
    config = _load_settings(CONFIG_PATH)
    cli = {key: value for key in DEFAULT_SETTINGS if (value := getattr(args, key)) is not None}
    settings = _validated_settings(_merge_settings(DEFAULT_SETTINGS, config, cli))

    running = _find_servers()
    if running:
        detail = ', '.join(f'{arch} PID {pid}' for arch, pid, _ in running)
        persisted = _validated_settings(_merge_settings(DEFAULT_SETTINGS, config, {}))
        print(f'Existing exact-path server found: {detail}.', file=sys.stderr)
        print(f'{CONFIG_PATH.name} contains last successful settings: {_settings_status(persisted)}', file=sys.stderr)
        return 1

    exe = (ROOT / SERVER_BINARIES[args.arch]).resolve()
    if not exe.is_file():
        raise ValueError(f'Selected {args.arch} executable is missing: {exe}')
    if not _is_loopback(str(settings['host'])) and settings['password'] == '':
        print('Warning: non-loopback host with empty password.', file=sys.stderr)

    command = [str(exe), f'-i{settings["host"]}', '-p', str(settings['port']), '-v']
    if settings['password'] != '':
        command.append(f'-P{settings["password"]}')
    with LOG_PATH.open('w', encoding='utf-8', errors='replace') as log_file:
        proc = subprocess.Popen(
            command,
            cwd=str(ROOT),
            stdin=subprocess.DEVNULL,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            creationflags=0x00000008,
        )
    try:
        time.sleep(0.3)
    except KeyboardInterrupt:
        _kill_exact(('interrupted child', proc.pid, exe))
        print('Start interrupted.', file=sys.stderr)
        return 130

    if proc.poll() is not None:
        raise ValueError(f'{args.arch} server exited immediately (code {proc.returncode}). See log: {LOG_PATH}')
    _write_settings(CONFIG_PATH, settings)
    print(f'Started {args.arch} server PID {proc.pid}.')
    print(f'Settings saved: {_settings_status(settings)}')
    print(f'Log: {LOG_PATH}')
    return 0


def _cmd_stop() -> int:
    _require_windows()
    running = _find_servers()
    if not running:
        print('No exact-path IDA debug server found.')
        return 0
    failures = [not _kill_exact(server) for server in running]
    return 1 if any(failures) else 0


def _cmd_log() -> int:
    if not LOG_PATH.is_file():
        print(f'No log yet: {LOG_PATH}')
        return 0
    is_running = bool(_find_servers())
    print(f'{"Following log" if is_running else "No exact-path IDA debug server is running; showing existing log"}: {LOG_PATH}')
    with LOG_PATH.open('r', encoding='utf-8', errors='replace') as fh:
        while True:
            if chunk := fh.read():
                sys.stdout.write(chunk)
                sys.stdout.flush()
            elif is_running and _find_servers():
                time.sleep(0.5)
            elif is_running:
                is_running = False
            else:
                return 0


def _load_settings(path: Path) -> Settings:
    if not path.exists():
        return {}
    with path.open('rb') as fh:
        raw = tomllib.load(fh)
    loaded: Settings = {}
    for key, value in raw.items():
        if key not in DEFAULT_SETTINGS:
            raise ValueError(f'Unknown TOML key: {key}')
        if isinstance(value, bool):
            raise ValueError(f'{key} must not be boolean')
        if not isinstance(value, str | int):
            raise ValueError(f'{key} must be a string or integer')
        loaded[key] = value
    return loaded


def _merge_settings(defaults: Mapping[str, SettingValue], config: Mapping[str, SettingValue], cli: Mapping[str, SettingValue]) -> Settings:
    return {key: cli.get(key, config.get(key, defaults[key])) for key in defaults}


def _write_settings(path: Path, settings: Mapping[str, SettingValue]) -> None:
    final = _validated_settings(settings)
    tmp = path.with_name(f'.{path.name}.{os.getpid()}.tmp')
    tmp.write_text(tomli_w.dumps(final), encoding='utf-8')
    tmp.replace(path)


def _validated_settings(settings: Mapping[str, SettingValue]) -> Settings:
    host = settings.get('host', DEFAULT_SETTINGS['host'])
    port = settings.get('port', DEFAULT_SETTINGS['port'])
    password = settings.get('password', DEFAULT_SETTINGS['password'])
    if not isinstance(host, str) or not _valid_host(host):
        raise ValueError('host must be an IP literal or valid DNS hostname')
    if isinstance(port, bool) or not isinstance(port, int) or not 1 <= port <= 65535:
        raise ValueError('port must be an integer from 1 through 65535')
    if not isinstance(password, str) or '\x00' in password:
        raise ValueError('password must be a string without NUL bytes')
    return {'host': host, 'port': port, 'password': password}


def _settings_status(settings: Mapping[str, SettingValue]) -> str:
    password = 'empty' if settings['password'] == '' else 'configured'
    return f'host={settings["host"]}, port={settings["port"]}, password={password}'


def _valid_host(host: str) -> bool:
    try:
        ipaddress.ip_address(host)
        return True
    except ValueError:
        name = host.removesuffix('.')
    if len(name) > 253 or not name.isascii():
        return False
    return all(
        label and len(label) <= 63 and label[0].isalnum() and label[-1].isalnum() and all(c.isalnum() or c == '-' for c in label) for label in name.split('.')
    )


def _is_loopback(host: str) -> bool:
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return host.rstrip('.').lower() == 'localhost'


def _require_windows() -> None:
    if sys.platform != 'win32':
        raise ValueError('This command must run on Windows.')


def _find_servers() -> list[Server]:
    expected_by_name = {name.lower(): (arch, (ROOT / name).resolve()) for arch, name in SERVER_BINARIES.items()}
    found: list[Server] = []
    for process in psutil.process_iter(['name']):
        # 按文件名筛选候选进程
        try:
            exe_name = process.name().lower()
        except PSUTIL_PATH_ERRORS:
            continue
        if exe_name not in expected_by_name:
            continue
        arch, expected_path = expected_by_name[exe_name]
        # 按完整可执行路径确认归属
        actual_path = _get_process_executable_path(process.pid)
        if actual_path is None:
            print(f'Warning: PID {process.pid} is named {exe_name}, but its full path could not be read; not killing it.', file=sys.stderr)
        elif _norm(actual_path) == _norm(expected_path):
            found.append((arch, process.pid, expected_path))
    return found


def _kill_exact(server: Server) -> bool:
    arch, pid, expected = server
    current = _get_process_executable_path(pid)
    if current is None:
        print(f'Warning: PID {pid} path could not be verified; not killing it.', file=sys.stderr)
        return False
    if _norm(current) != _norm(expected):
        print(f'Warning: PID {pid} path mismatch; not killing it.', file=sys.stderr)
        return False
    result = subprocess.run(['taskkill', '/PID', str(pid), '/T', '/F'], check=False, capture_output=True, text=True)
    if result.returncode == 0:
        print(f'Stopped {arch} server PID {pid}.')
        return True
    print(f'Failed to stop {arch} server PID {pid} (exit {result.returncode}).', file=sys.stderr)
    for output in (result.stdout, result.stderr):
        if output:
            print(output.strip(), file=sys.stderr)
    return False


def _get_process_executable_path(pid: int) -> Path | None:
    try:
        reported_path = psutil.Process(pid).exe()
        return Path(reported_path).resolve() if reported_path else None
    except (OSError, *PSUTIL_PATH_ERRORS):
        return None


def _norm(path: Path | str) -> str:
    return os.path.normcase(Path(path).resolve())


if __name__ == '__main__':
    raise SystemExit(main())
