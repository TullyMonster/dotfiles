# Tully's Dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 跨设备地管理配置文件，使用 age 作为 chezmoi 的加密后端。

## 新设备的初始化

1. **私钥 (private key) 恢复**：

   > 最初的 age 私钥已由 `chezmoi age-keygen -o key.txt` 命令创建，已备份至 Bitwarden 中，形如 `AGE-SECRET-KEY-...`。

   ```shell
   mkdir -p ~/.config/chezmoi
   $EDITOR ~/.config/chezmoi/key.txt  # 写入 Bitwarden 中的私钥
   chmod 600 ~/.config/chezmoi/key.txt
   ```

2. **应用配置文件**：

   > 下载安装 chezmoi 并立即初始化源仓库、应用到用户目录。

   ```shell
   sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:TullyMonster/dotfiles.git
   ```

## Headed Playwright Service

该服务提供三类能力：面向 AI Agent 的 MCP Streamable HTTP 端点；供 `playwright-cli attach` 使用的 wsEndpoint（MCP 与 CLI 连接同一个持久浏览器上下文）；以及面向用户观察和接管浏览器会话的 noVNC 入口。
为减少暴露面，MCP、wsEndpoint 与 VNC 默认仅监听 `127.0.0.1`。

1. **构建镜像、运行服务**：

   > 仅在修改 Containerfile、容器内脚本或 supervisor 配置后，需重建本地服务镜像。若服务已在运行，使用 `restart` 生效。

   ```shell
   build-headed-playwright-service-image
   systemctl --user daemon-reload
   systemctl --user start headed-playwright-service.service
   ```

2. **配置 MCP**：

   > 以 OpenCode 为例。

   ```json
   {
     "mcp": {
       "playwright": {
         "enabled": true,
         "type": "remote",
         "url": "http://127.0.0.1:8931/mcp"
       }
     }
   }
   ```

3. **playwright-cli**：

   AI Agent （如 OpenCode）可通过 `headed-playwright-cli` skill 使用宿主机 `playwright-cli` 连接同一个持久浏览器上下文。

4. **从其他 tailnet 设备访问浏览器 GUI（可选）**：

   > 通过 `https://<host>.<tailnet>.ts.net:6080/vnc.html` 访问。
   > 亦可用 SSH 本地端口转发（`ssh -N -L 6080:127.0.0.1:6080 <user>@<host>`），并通过 `http://127.0.0.1:6080/vnc.html` 访问。

   ```shell
   tailscale serve --bg --https=6080 http://127.0.0.1:6080
   ```

## Ghidra Headless MCP（可选）

可选地提供了 `ghidra-manager`、`ghidra-mcp-build` 和 `ghidra-mcp-headless` 命令分别用于管理 Ghidra 本体、准备 GhidraMCP 组件，以及在 OpenCode 中提供 headless Ghidra MCP 分析能力。

## IDA Pro MCP

由 IDA Pro 和 `ida-pro-mcp.service` 通过 Streamable HTTP 为 OpenCode 提供静态分析与动态调试能力。

静态分析以及无界面的 IDB 会话不依赖预先启动的 IDA Pro GUI。
当前的 `ida-pro` MCP 不支持自动选用调试器、配置 Process options、附加到已有进程或枚举目标进程中已加载的模块。
因此，在调用 `dbg_start` 工具前，必须由用户先在对应的 IDA 会话中完成相关配置。
MCP 可以对已经完成配置的调试目标执行启动、继续运行、单步执行和终止等操作。

跨平台调试时，需配置对应平台的远程调试器，或直接在目标操作系统上运行 IDA Pro 和 MCP。
调试由宿主程序加载的动态库时，应根据实际需求在 Process options 中设置宿主程序 (Application) 和目标动态库 (Input file)，
并在程序启动后确认宿主程序按预期加载了目标动态库。

对于同一组 IDA 数据库（或会话）与调试目标，所有的 `dbg_*` 工具调用，包括调试状态、寄存器和内存读取，都必须由唯一的控制方串行执行。
控制权转移前，需合理交接当前的调试状态；未完成交接时，其他代理或人工 GUI 操作不应干预该调试会话。

> 在 oh-my-openagent 的工作流中，Prometheus 制定的动态调试计划，应在正式执行前明确说明目标 IDA 数据库或会话、Process options 等配置，供用户提前手动设置。
> 同一个连续的动态调试阶段不应依赖这些配置自动变更。如需切换调试目标或调整配置，应先结束当前阶段并完成控制权交接，再开始新的阶段。
> Atlas 执行计划时，可按需并行地派发静态分析等离线任务，但同一个调试会话中所有的实时 `dbg_*` 工具调用必须仅归属于一个明确的控制方，并通过任务依赖组织为单一的串行调用链，派发的其他代理不得同时调用这些工具。

### 安装 OpenCode idapython skill

为保证 OpenCode 在调用该 MCP 的 `py_eval` 或 `py_exec_file` 工具时优先使用现代的 `ida_*` 模块而避免旧式的 `idc` API，
可在项目目录中执行 `opencode-ida-pro-mcp-skill` 命令，安装、更新或移除 `mrexodia/ida-pro-mcp` 的 OpenCode `idapython` skill：

```shell
opencode-ida-pro-mcp-skill install
opencode-ida-pro-mcp-skill update
opencode-ida-pro-mcp-skill uninstall
```

### 安装 IDA Pro

> IDA Pro 的版本号至少为 8.3，推荐使用 9.0 及以上的版本。

1. 获取 IDA Pro 许可证文件 `ida.hexlic`，并将其复制到 `~/.idapro/`

2. 下载 IDA Pro 的 Linux 安装包并执行安装（以 x64 架构为例）：
   - 同意最终用户许可协议 (End User License Agreement, EULA)
   - 确认或修改安装目录，建议安装在 `~/.local/opt/ida-pro-*.*`
   ```shell
   chmod +x ida-pro_*_x64linux.run
   ./ida-pro_*_x64linux.run
   ```

### 通过 VNC 服务端打开 IDA Pro GUI

在无头 Linux 上使用 IDA Pro 的动态调试功能时，需为其提供可操作的图形界面。本方案推荐使用 KasmVNC（原生的浏览器访问支持，现代的 Web 传输与安全机制）。

- 参考 [kasmtech/KasmVNC](https://github.com/kasmtech/KasmVNC) 完成安装与配置
- 常用命令：
  ```shell
  vncserver                         # 启动新会话
  vncserver -list                   # 查看运行中的会话
  vncserver -kill :1                # 停止 :1 会话
  vncpasswd -u <user_name> -w -r    # 创建可查看、操作远程桌面的 KasmVNC 用户，再次执行该命令可重设该用户的密码
  ```

### 在目标系统上启动远程调试服务器

IDA Pro 安装目录的 `dbgsrv/` 中包含适用于不同操作系统和处理器架构的远程调试服务器。这些服务器用于在目标机器上启动或附加目标进程，接收并处理 IDA Pro 的调试指令。

1. 确保待调试程序及其运行依赖已存在于目标机器，并将与目标系统及架构匹配的远程调试服务器复制到目标机器
2. 启动远程调试服务器，配置监听地址、端口和密码
   > 如，调试 Windows x64 程序：
   > `.\win64_remote.exe --ip-address <ip> --port-number 23946 --password '<pswd>' --verbose`
   > 默认绑定并监听所有可用的网络接口（`0.0.0.0`）的 `23946` 端口，无密码并关闭详细输出。建议绑定到 Tailscale IP。
3. 启动 vncserver 并打开 IDA Pro
4. 选择合适的调试器。如：Debugger -> Switch debugger -> Remote Windows debugger
5. 在 IDA Pro 的 Debugger 菜单中配置 Process options：
   - Application：需在目标机器上启动的主程序
   - Input file：由当前 IDA 数据库所分析并希望在目标机器上运行时调试的二进制文件
   - Directory：主程序在目标机器启动时的工作目录
   - Parameters：为主程序传递的命令行参数
   - Environment：为目标进程设置的额外环境变量
   - Hostname：远程调试服务器所在目标机器的 IP 地址或主机名
   - Port：远程调试服务器监听的端口号
   - Password：远程调试服务器的密码

### 适时启停 ida-pro-mcp.service

启动 `ida-pro-mcp.service` 是成功启用 OpenCode 中的 `ida-pro` MCP 的前提。

```shell
systemctl --user start   ida-pro-mcp.service
systemctl --user stop    ida-pro-mcp.service
systemctl --user restart ida-pro-mcp.service
```

> 停止或重启该服务会终止 MCP 服务器及当前用户的全部 IDALib 工作进程；正在执行的 MCP 请求会中断，不会终止 IDA Pro GUI 进程。
