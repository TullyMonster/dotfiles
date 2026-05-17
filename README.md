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
