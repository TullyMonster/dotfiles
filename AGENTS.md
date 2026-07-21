# Chezmoi Source 仓库

这是 chezmoi 的 source 目录（`~/.local/share/chezmoi`）。
这里的所有文件和目录通过命名约定映射到 `$HOME`。
**永远不要替用户执行 `chezmoi init` 或 `chezmoi apply`。** 这会直接修改用户 home 目录下的实际文件。

---

## 文件属性

chezmoi 通过文件名前缀和后缀编码 target 行为，前缀顺序有严格要求。
不要在 source 仓库中直接 `chmod` 修改权限。

| 属性          | 作用                                   | 本项目常见用法                              |
| ------------- | -------------------------------------- | ------------------------------------------- |
| `dot_`        | target 加前导点                        | `dot_config/nvim` → `~/.config/nvim`        |
| `executable_` | target 添加执行权限                    | `executable_ghidra-manager`                 |
| `encrypted_`  | source 中 age 加密存储                 | `encrypted_secret` → `encrypted_secret.age` |
| `private_`    | target 清除 group/world 权限           | `private_dot_ssh/config` → 0600             |
| `.tmpl`       | Go 模板，渲染后写入 target             | `dot_gitconfig.tmpl`                        |
| `.age`        | age 加密自动附加，加密文件不可直接编辑 | —                                           |

## 脚本

面向用户的脚本使用 **POSIX sh**（`#!/usr/bin/env sh`），即便用户日常 shell 是 zsh。
这适用于 `dot_local/bin/` 和 `.chezmoiscripts/` 中的所有脚本。

### Shell 风格

- 严格模式：`set -eu`。POSIX sh 不支持 `pipefail`，无需添加。
- 变量展开始终加引号：`"${var}"`，带默认值时用 `"${var:-default}"`。
- 日志函数统一使用以下命名，不再引入其他命名的日志函数：
  - `info()`：正常流程、状态变化、关键步骤
  - `warn()`：可继续运行，但有潜在问题
  - `error()`：明确出错，但不一定立刻退出
  - `fatal()`：严重错误，报告并退出

脚本执行权限通过 `executable_` 前缀声明，不对 source 文件手动 `chmod`。

`.chezmoiscripts/` 中的脚本命名固定为：
`run_` + (`once_` | `onchange_`) + (`before_` | `after_`) + `序号-描述`。
例如 `run_once_before_00-bootstrap-tools.sh.tmpl` 表示「首次应用前运行一次」。

当 `dot_config/systemd/user/` 下的 Unit 模板文件发生新增、删除或重命名时，必须同步更新 `.chezmoiscripts/run_onchange_after_40-user-systemd-daemon-reload.sh.tmpl` 中由 `includeTemplate ... | sha256sum` 构成的显式依赖列表。此举旨在确保 Unit 集合的结构性变更能正确触发 `systemctl --user daemon-reload`；仅修改现有 Unit 模板的内容无需手动调整该列表。

脚本中用到的配置变量，以 `.chezmoi.toml.tmpl` 的 `[data]` 段为单一来源，避免在多个脚本中重复定义或二次包装。

### 克隆外部仓库

脚本如果只是直接克隆外部仓库用于本地使用、构建或运行，默认使用 `git clone --depth 1`。
只有后续流程明确依赖完整 Git 历史、tags、release/tag 操作或历史查询时，才使用完整 clone。

### Python 脚本

仓库内维护的 Python 脚本以 Python 3.12 为最低支持版本。
包含 PEP 723 内联脚本元数据的文件必须声明 `requires-python = ">=3.12"`。
新增或修改代码时，推荐直接使用 Python 3.12 的语法特性。

外部项目或上游脚本则遵循其自身的 Python 版本约束。

## 工具管理

全局工具优先由 mise 管理（`dot_config/mise/config.toml`）。
被 mise 管理的工具，仓库内脚本可直接调用，无需检查是否安装。
将工具纳入 mise 时需评估必要性——仅在确实多设备共用且跨项目依赖时才纳入。

## 纳入原则

chezmoi 管理的文件应具备跨设备可复用性。
仅在某台设备上有意义的配置或一次性脚本**不要** `chezmoi add`（或通过 `.chezmoiignore` 排除）。

## Git 提交

遵循约定式提交（Conventional Commits），描述使用中文，清晰声明做了哪些修改。

标题 (header)：`<type>: <描述>`

| type       | 用途                               |
| ---------- | ---------------------------------- |
| `feat`     | 新功能、新配置、新工具             |
| `fix`      | 修复问题                           |
| `chore`    | 维护性工作（清理、调整、依赖更新） |
| `docs`     | 文档变更                           |
| `refactor` | 重构（不改变行为的代码调整）       |

描述使用祈使语气，直接说明变更内容，每行不超过 72 字符。

正文（body）使用 `- ` 无序列表逐条列出具体变更，每条一项改动。提交标题给出摘要，正文给出细节。

## 与本仓库其他文件的关系

- **README.md**：人类阅读的项目说明。
- **AGENTS.md**（本文件）：给操作本仓库的 AI agent 看的操作约束。
- **`dot_config/opencode/AGENTS.md`**：会被 apply 到 `~/.config/opencode/AGENTS.md`，作为 OpenCode 在所有项目中的全局编码规范。与本文件受众完全不同。

## 安全红线

- 不对加密文件（`encrypted_*.age`）直接编辑，这些只能通过 chezmoi 命令间接操作。
- `promptStringOnce` 的值来自用户交互输入，AI 不能也不应绕过。
- 不执行 `chezmoi init` 或 `chezmoi apply`。
