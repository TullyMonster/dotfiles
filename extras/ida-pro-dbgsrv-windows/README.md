# IDA Pro Windows 远程调试服务器

使用时，将 `ida_dbgsrv.py` 放至与 `win32_remote32.exe` 和 `win64_remote.exe` 同级的 IDA 调试服务器目录中。确保 [`uv`](https://docs.astral.sh/uv/) 命令可用。

该脚本同一时间只管理一个服务器实例，日志写入至 `ida-dbgsrv.log`。

## 示例

可用 `--host`、`--port` 和 `--password` 参数配置连接。

```shell
uv run --script ida_dbgsrv.py start --arch x64
uv run --script ida_dbgsrv.py start --arch x86
uv run --script ida_dbgsrv.py stop
uv run --script ida_dbgsrv.py log
```

## 配置

连接配置将在服务成功启动后写入 `ida-dbgsrv.toml`，也可预先手动创建。默认为：

```toml
host = "127.0.0.1"
port = 23946
password = ""
```

## 注意

- 密码会在配置文件中明文保存；
- `stop` 子命令将强制终止服务器及其子进程，可能影响正在调试的程序。
