## age 加密

本仓库使用 age 作为 chezmoi 的加密后端。`chezmoi age-keygen` 生成的 age 密钥数据额外保存在 Bitwarden 中。

### 私钥 (private key)

形如 `AGE-SECRET-KEY-...`，用于解密。永远不要不由 chezmoi 管理，需在 `chezmoi init` 前手动创建。

```shell
mkdir -p ~/.config/chezmoi
$EDITOR ~/.config/chezmoi/key.txt  # 将 Bitwarden 中的私钥文件内容写入
chmod 600 ~/.config/chezmoi/key.txt
```

### 公钥 (public key)

形如 `age1...`，用于加密。在执行 `chezmoi init` 时交互式写入 `chezmoi.toml` 文件。

```shell
# 获取公钥
chezmoi age-keygen -y ~/.config/chezmoi/key.txt
```

## OpenCode 的 exa-pool MCP 配置

`exa-pool` 是本机 OpenCode 使用的本地 MCP 服务。新机器恢复时，需要先仓库克隆到约定路径：

```shell
mkdir -p ~/mcp-servers
git clone https://github.com/TullyMonster/exa-pool-mcp.git ~/mcp-servers/exa-pool-mcp
```
