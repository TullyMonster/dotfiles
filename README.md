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

此服务暴露两类能力：一方面，用于 AI Agent 的 MCP 浏览器控制端点；另一方面，用于用户观察和手动接管的 noVNC 浏览器界面。该服务默认（推荐）监听 127.0.0.1。

1. **构建镜像**：

   > 首次使用，或更新 `Containerfile` / 启动脚本后，需要先构建本地服务镜像；Quadlet 会使用这个镜像启动容器。

   ```shell
   ~/.config/headed-playwright-service/build-service-image.sh
   ```

2. **启动服务**：

   > 先确保已执行 `systemctl --user daemon-reload`。

   ```shell
   systemctl --user start headed-playwright-service.service
   ```

3. **配置 MCP**：

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

4. **从其他 tailnet 设备访问浏览器 GUI（可选）**：

   > 通过 `https://<host>.<tailnet>.ts.net:6080/vnc.html` 访问。
   > 亦可用 SSH 本地端口转发（`ssh -N -L 6080:127.0.0.1:6080 <user>@<host>`），并通过 `http://127.0.0.1:6080/vnc.html` 访问。

   ```shell
   tailscale serve --bg --https=6080 http://127.0.0.1:6080
   ```
