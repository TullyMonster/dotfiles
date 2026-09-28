# Git 配置

## config.tmpl 要点

- 显示与合并：delta、`zdiff3`；`user.useConfigOnly = true`（提交身份只在各仓库的本地配置里设置）。
- **SSH 提交签名**：
  - `gpg.format = ssh`；`commit.gpgsign` / `tag.gpgsign` 默认开启（fail-closed：密钥未就绪的设备上提交会直接失败，临时跳过用 `git commit --no-gpg-sign`）。
  - `user.signingkey` 的值取自本机 chezmoi 配置的 `[data.git] user_signing_key`。
  - 设备约定：签名密钥复用 GitHub 认证密钥，如 `~/.ssh/github-key`；新设备把该公钥以 signing 类型注册到 GitHub：

    ```shell
    gh auth refresh -h github.com -s admin:ssh_signing_key
    gh ssh-key add ~/.ssh/github-key.pub --type signing --title "$(hostname)"
    ```

- **GitHub HTTPS 凭据助手**：`credential.https://github.com.helper` 指向 mise shim 的 `gh auth git-credential`。

## allowed_signers

`gpg.ssh.allowedSignersFile` 指向 `~/.config/git/allowed_signers`；该文件未由 chezmoi 管理，需自行生成：

```shell
printf '* %s\n' "$(cat ~/.ssh/github-key.pub)" > ~/.config/git/allowed_signers
```

没有它时，仅本机 `git log --show-signature` / `git verify-commit` 不可用；GitHub 侧的 Verified 徽标不受影响。
