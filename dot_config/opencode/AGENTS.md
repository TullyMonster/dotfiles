# Language Policy

Unless explicitly stated otherwise, system-level communication (including tools, sub-agents, and skills) MUST be conducted in English, while human-facing communication MUST be conducted in Simplified Chinese.

1. Tool Calls: All parameters, search queries, identifiers, and arguments passed to MCP tools MUST be written in English to ensure tool compatibility, deterministic behavior, and search accuracy.
2. Communication: All internal reasoning, planning, analysis, and all final responses to the user MUST be expressed in Simplified Chinese, including any human-readable explanations shown in tool permission prompts and command confirmation dialogs.
3. Code: All identifiers MUST be in English. Comments SHOULD be written in Simplified Chinese, using English only for established technical terms or unavoidable domain-specific terminology.
4. Sub-Agent and Skill Prompt Injection: Injected instructions provided to sub-agents, as well as skill descriptions, names, parameters, and internal instructions provided to skills, MUST be written in English.

# Coding & Tooling Conventions

These conventions apply to all new code and modifications unless they conflict with established project standards (in which case the existing codebase takes precedence).

## Python Coding Rules

- Python code MUST use Google-style docstrings.
- Python code MUST include accurate and explicit type annotations.
- Prefer single-quoted strings in Python unless double quotes improve clarity.
- Prefer list/set/dict comprehensions, generator expressions, and conditional expressions when they improve readability and complexity remains moderate.
- Use comments intentionally:
  - Use standalone single-line comments to separate logical blocks of code.
  - Use end-of-line comments only when explaining non-obvious implementation details.

## Code Quality Expectations

- Favor clarity and correctness over cleverness.
- Avoid introducing new abstractions unless they reduce duplication or improve testability.
- Keep functions small and single-purpose; keep modules cohesive.
- Prefer explicit interfaces/contracts across architecture layers.

## Scripting & One-liner Style

- For scripting languages, you SHOULD leverage advanced language features (e.g., comprehensions, pipelines, lambdas) to write concise, one-liner-style code, as long as readability is preserved.
- Avoid overly clever or cryptic expressions that harm maintainability.

## Resource Safety for Agent-Executed Shell Commands

Most shell commands should run normally without extra wrappers.

Apply safeguards only when a command may realistically exhaust host resources, such as when it installs or resolves dependencies, builds software, starts unknown third-party CLIs/MCP servers/language runtimes, scans large directory trees, spawns workers, or when multiple similar risky commands may run concurrently.

For risky commands, prefer using a timeout, avoid unnecessary concurrency, keep scans scoped to the current project, and use temporary directories or caches when helpful. Temporary isolation is not a memory limit.

On Linux with systemd, use a resource-limited user scope when a risky command combines dependency installation, runtime startup, broad scanning, or concurrency:

```sh
systemd-run --user --scope
  -p MemoryMax=<reasonable-memory-limit> \
  -p MemorySwapMax=<reasonable-swap-limit> \
  timeout <reasonable-duration> zsh -lc '<command>'
```

Do not wrap commands that manage SSH, networking, disks, login sessions, system services, or system package transactions unless known safe.

## Tooling Preferences

### Shell

- Prefer Z Shell (`zsh`) over `bash`.
- On Windows, prefer `pwsh7` over legacy `powershell`.

### Python Tooling

- Prefer `uv` over `pip` for dependency management.
- Prefer `pyright` over `mypy` for type checking.
- Prefer `ruff` over `black` for formatting and linting.

### JavaScript / Node.js Tooling

- Prefer `pnpm` over other package managers.
- Prefer `nvm` for Node.js version management.

### Data Processing

- Prefer `jq` for querying and transforming JSON data over text-based tools like `grep`.
- Prefer `yq` for querying, transforming, and editing YAML or mixed structured data formats.
