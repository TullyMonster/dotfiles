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
   ~/.config/headed-playwright-service/build-service-image.sh
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
