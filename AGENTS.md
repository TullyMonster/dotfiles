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

- `.chezmoiscripts/` 中的脚本必须使用 **POSIX sh**（`#!/usr/bin/env sh`），即便用户日常 shell 是 zsh。
- `dot_local/bin/` 中的命令按问题复杂度选择语言。
- 使用其他语言时，运行时应由 mise 管理，并使用明确的 shebang。

### Shell 风格

- 不含 Go 模板的 Shell 脚本使用 `shfmt -i 2 -ci -bn -w <file>` 格式化。
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

当 `dot_config/systemd/user/` 下的 Unit 模板文件发生新增、删除或重命名时，必须同步更新 `.chezmoiscripts/run_onchange_after_50-user-systemd-daemon-reload.sh.tmpl` 中由 `includeTemplate ... | sha256sum` 构成的显式依赖列表。此举旨在确保 Unit 集合的结构性变更能正确触发 `systemctl --user daemon-reload`；仅修改现有 Unit 模板的内容无需手动调整该列表。

所有会因设备或部署而变化的数据，都应以 `.chezmoi.toml.tmpl` 的 `[data]` 段为单一来源，避免在多个脚本中重复定义或二次包装。

### 克隆外部仓库

脚本如果只是直接克隆外部仓库用于本地使用、构建或运行，默认使用 `git clone --depth 1`。
只有后续流程明确依赖完整 Git 历史、tags、release/tag 操作或历史查询时，才使用完整 clone。

### Python 脚本

仓库内维护的 Python 脚本以 Python 3.12 为最低支持版本。
包含 PEP 723 内联脚本元数据的文件必须声明 `requires-python = ">=3.12"`。
新增或修改代码时，推荐直接使用 Python 3.12 的语法特性。
检查 Python 文件时直接运行 `pyqa <file>`；它会依次执行 Ruff 修复检查、Ruff 格式化和 Pyright，并保留全部步骤的综合失败状态。

外部项目或上游脚本则遵循其自身的 Python 版本约束。

## 工具管理

全局工具优先由 mise 管理（`dot_config/mise/config.toml`）。
被 mise 管理的工具，仓库内脚本可直接调用，无需检查是否安装。
将工具纳入 mise 时需评估必要性——仅在确实多设备共用且跨项目依赖时才纳入。

修改 `dot_config/mise/config.toml` 中需要自动应用的 bootstrap 节时，同步维护 `.chezmoiscripts/run_onchange_after_10-apply-mise-config.sh.tmpl` 的 `mise bootstrap --only` 范围。

## 编辑器格式化

- 新增文件类型、格式化工具或扩展名与实际语法不一致的文件时，同步维护 `.vscode/settings.json`。
- 格式化工具须通过 stdin/stdout 工作并由 mise 管理；`*.tmpl` 含 Go 模板，不使用普通语言格式化器。

## 纳入原则

chezmoi 管理的文件应具备跨设备可复用性。
仅在某台设备上有意义的配置或一次性脚本**不要** `chezmoi add`（或通过 `.chezmoiignore` 排除）。

## Git 提交方案

仅在用户明确要求时生成提交方案。修改范围依次取自用户指定内容、当前对话完成的修改；仅当用户要求处理整个工作区时，才检查全部未提交修改。范围不明确时先询问。

只用 `git status`、`git diff`、`git log` 等只读操作分析修改。不得暂存、取消暂存、提交或改写历史。

每个提交包含一组共同完成同一行为、可独立理解、验证和回退的修改：

- 不按文件数量、目录或类型机械拆分。
- 同一行为所需的实现、配置等放在一起；可独立回退的不同行为应拆分。
- 纯格式化、重命名等机械修改不与行为变更混合。
- 同一文件仅按明确且互不重叠的区块拆分；无法安全拆分时合并。

按建议执行顺序输出各提交：

```text
## 提交 1

变更范围：
- `path/new-file`：整个文件（新增）
- `path/deleted-file`：整个文件（删除）
- `path/existing-file:42-67`：修改内容摘要

提交消息：

<type>: <中文描述>

- 正文内容
```

标题使用 `<type>: <描述>`；`type` 是符合 Conventional Commits 语义的小写英文词，描述用简洁的中文祈使短语概括结果。

正文使用 Markdown 列表，每项表达一个必要事实，说明行为变化及必要的原因、约束或影响；不得重复标题、罗列文件路径或描述编辑和暂存过程。列表项不限数量，但至少一项。

## 与本仓库其他文件的关系

- **README.md**：人类阅读的项目说明。
- **AGENTS.md**（本文件）：给操作本仓库的 AI agent 看的操作约束。
- **`dot_config/opencode/AGENTS.md`**：会被 apply 到 `~/.config/opencode/AGENTS.md`，作为 OpenCode 在所有项目中的全局编码规范。与本文件受众完全不同。

## 安全红线

- 不对加密文件（`encrypted_*.age`）直接编辑，这些只能通过 chezmoi 命令间接操作。
- `promptStringOnce` 的值来自用户交互输入，AI 不能也不应绕过。
- 不执行 `chezmoi init` 或 `chezmoi apply`。
