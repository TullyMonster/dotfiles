# Browser Session Management

Use named CLI sessions to keep workflows separate while attached to the configured headed browser. A session label is arbitrary; choose a task-oriented name such as `page-check`, `login-flow`, or `visual-review`.

## Named Browser Sessions

Attach to the configured endpoint with a meaningful session name:

```bash
# Browser workflow 1: Authentication flow
# Browser workflow 1: Authentication flow
# attach auth-flow once using the standard attach command from SKILL.md

# Browser workflow 2: Public browsing
# attach public-check once using the standard attach command from SKILL.md

# Commands are routed by session label
playwright-cli --session auth-flow snapshot
playwright-cli --session public-check goto https://example.com/
```

The configured browser is shared and persistent. The CLI session label separates CLI state, not the underlying persistent profile.

## Browser Session Isolation Properties

For CLI-owned browsers, sessions can have independent cookies, storage, history, tabs, and profiles. In this attached headed-browser workflow, assume the persistent browser profile may be shared. Do not rely on isolation unless you explicitly create separate pages/tabs or the user asks for a separate browser workflow.

## Browser Session Commands

```bash
# List browser sessions
playwright-cli list
playwright-cli list --all

# Correct cleanup for attached sessions
playwright-cli --session <workflow-label> detach
```

Avoid by default:

```bash
# These can affect browser/session lifecycle or data and require explicit user authorization.
playwright-cli close
playwright-cli close-all
playwright-cli kill-all
playwright-cli delete-data
```

## Environment Variable

`PLAYWRIGHT_CLI_SESSION` can set a default session name, but explicit `--session <workflow-label>` is clearer for agents and logs.

```bash
export PLAYWRIGHT_CLI_SESSION=page-check
playwright-cli snapshot
```

## Common Patterns

### Concurrent Scraping

Concurrent workflows may share the same persistent browser. Use unique session labels and avoid destructive commands.

```bash
# attach site1 and site2 once using the standard attach command from SKILL.md
playwright-cli --session site1 goto https://example.com/
playwright-cli --session site2 goto https://example.org/
playwright-cli --session site1 snapshot
playwright-cli --session site2 snapshot
playwright-cli --session site1 detach
playwright-cli --session site2 detach
```

### A/B Testing Sessions

```bash
playwright-cli --session variant-a goto "https://app.example.com?variant=a"
playwright-cli --session variant-b goto "https://app.example.com?variant=b"
playwright-cli --session variant-a screenshot --filename=/tmp/opencode/playwright-cli/variant-a.png
playwright-cli --session variant-b screenshot --filename=/tmp/opencode/playwright-cli/variant-b.png
```

### Persistent Profile

The configured headed browser already uses persistent browser state. Do not create or delete profiles from this skill unless the user asks for local CLI-owned browser work.

## Attaching to a Running Browser

Use `attach` to connect to the configured browser that is already running, instead of launching a new one.

```bash
playwright-cli --session <workflow-label> attach "$(podman exec headed-playwright-service sh -lc 'cat "${ENDPOINT_FILE:-/run/headed-playwright-service/ws-endpoint}"')"
```

### Attach by channel name

Generic channel-name attach is not the default here. Do not use channel/CDP attach for the configured headed browser workflow.

### Attach via CDP endpoint

Do not use CDP for this workflow. The configured endpoint is a Playwright protocol endpoint.

### Attach via browser extension

Browser extension attach is a separate workflow and is not the default here.

### Detach

Tear down an attached session without affecting the external browser:

```bash
# Detach a specific attached session
playwright-cli --session <workflow-label> detach
```

`detach` is the normal cleanup command for this skill.

## Default Browser Session

When `--session` is omitted, commands use the default CLI session. Prefer an explicit task label so concurrent agents do not collide.

## Browser Session Configuration

Generic `open --browser`, `open --profile`, and `open --persistent` configuration is for CLI-owned browsers. It is not the default path for this skill.

## Best Practices

### 1. Name Browser Sessions Semantically

```bash
# GOOD: Clear purpose
playwright-cli --session github-auth snapshot
playwright-cli --session docs-scrape snapshot

# AVOID: Generic names in concurrent work
playwright-cli --session s1 snapshot
```

### 2. Always Clean Up

```bash
# Detach when done
playwright-cli --session <workflow-label> detach
```

Do not use `close-all` or `kill-all` unless the user explicitly asks to clean stale local CLI sessions.

### 3. Delete Stale Browser Data

Do not delete browser data by default. Persistent browser state may be valuable to the user.
