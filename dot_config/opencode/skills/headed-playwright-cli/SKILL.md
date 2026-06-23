---
name: headed-playwright-cli
description: Use host playwright-cli with the configured headed browser endpoint. Prefer this for browser automation, page inspection, snapshots, console/network checks, and evidence collection through the shared persistent headed browser.
allowed-tools: Bash(mkdir:*) Bash(podman:*) Bash(playwright-cli:*)
---

# Browser Automation with headed playwright-cli

Use this skill when browser work should happen through the preconfigured headed browser available to the host `playwright-cli` command.

The normal workflow is to attach to the existing browser endpoint, operate the page, then detach. Do not install browsers, launch a separate local browser, or close shared browser sessions unless the user explicitly asks.

## Quick start

Attach inline when the endpoint is only needed for the attach command:

```bash
playwright-cli --session <workflow-label> attach "$(podman exec headed-playwright-service sh -lc 'cat "${ENDPOINT_FILE:-/run/headed-playwright-service/ws-endpoint}"')"
playwright-cli --session <workflow-label> goto 'data:text/html,<title>headed-ok</title><h1>headed-ok</h1>'
playwright-cli --session <workflow-label> snapshot
playwright-cli --session <workflow-label> eval '() => ({ title: document.title, url: location.href })'
playwright-cli --session <workflow-label> detach
```

Use a meaningful session label for the task, for example `page-check`, `login-flow`, or `visual-review`. `<workflow-label>` is not a literal required name.

If multiple commands need the endpoint, assigning it to a variable is also fine:

```bash
endpoint=$(podman exec headed-playwright-service sh -lc 'cat "${ENDPOINT_FILE:-/run/headed-playwright-service/ws-endpoint}"')
playwright-cli --session <workflow-label> attach "$endpoint"
```

Do not print the endpoint value. Treat it like a bearer token.

## Working directory and artifacts

`playwright-cli` writes `.playwright-cli/` snapshots and some evidence files in the current directory. Use a temporary directory when artifacts are incidental or should not appear in the current project:

```bash
mkdir -p /tmp/opencode/playwright-cli
cd /tmp/opencode/playwright-cli
```

Using the current directory is acceptable when the user wants generated snapshots, screenshots, traces, videos, or state files saved there. Otherwise prefer `/tmp/opencode/playwright-cli` for hygiene.

## Commands

### Core

```bash
playwright-cli --session <workflow-label> goto https://example.com/
playwright-cli --session <workflow-label> type "search query"
playwright-cli --session <workflow-label> click e3
playwright-cli --session <workflow-label> dblclick e7
playwright-cli --session <workflow-label> fill e5 "user@example.com" --submit
playwright-cli --session <workflow-label> drag e2 e8
playwright-cli --session <workflow-label> drop e4 --path=./image.png
playwright-cli --session <workflow-label> drop e4 --data="text/plain=hello world"
playwright-cli --session <workflow-label> hover e4
playwright-cli --session <workflow-label> select e9 "option-value"
playwright-cli --session <workflow-label> upload ./document.pdf
playwright-cli --session <workflow-label> check e12
playwright-cli --session <workflow-label> uncheck e12
playwright-cli --session <workflow-label> snapshot
playwright-cli --session <workflow-label> eval '() => document.title'
playwright-cli --session <workflow-label> eval 'el => el.textContent' e5
playwright-cli --session <workflow-label> dialog-accept
playwright-cli --session <workflow-label> dialog-dismiss
playwright-cli --session <workflow-label> resize 1920 1080
playwright-cli --session <workflow-label> detach
```

Do not use `open` as the default entry point for this workflow. It starts a CLI-owned browser instead of attaching to the configured headed browser.

### Navigation

```bash
playwright-cli --session <workflow-label> go-back
playwright-cli --session <workflow-label> go-forward
playwright-cli --session <workflow-label> reload
```

### Keyboard

```bash
playwright-cli --session <workflow-label> press Enter
playwright-cli --session <workflow-label> press ArrowDown
playwright-cli --session <workflow-label> keydown Shift
playwright-cli --session <workflow-label> keyup Shift
```

### Mouse

```bash
playwright-cli --session <workflow-label> mousemove 150 300
playwright-cli --session <workflow-label> mousedown
playwright-cli --session <workflow-label> mousedown right
playwright-cli --session <workflow-label> mouseup
playwright-cli --session <workflow-label> mouseup right
playwright-cli --session <workflow-label> mousewheel 0 100
```

### Save as

```bash
playwright-cli --session <workflow-label> screenshot
playwright-cli --session <workflow-label> screenshot e5
playwright-cli --session <workflow-label> screenshot --filename=/tmp/opencode/playwright-cli/page.png
playwright-cli --session <workflow-label> pdf --filename=/tmp/opencode/playwright-cli/page.pdf
```

### Tabs

```bash
playwright-cli --session <workflow-label> tab-list
playwright-cli --session <workflow-label> tab-new
playwright-cli --session <workflow-label> tab-new https://example.com/page
playwright-cli --session <workflow-label> tab-close 2
playwright-cli --session <workflow-label> tab-select 0
```

Only close tabs that the current workflow created or that the user explicitly asked to close.

### Storage

Storage commands operate on persistent browser state. Prefer read-only inspection unless mutation is requested.

```bash
playwright-cli --session <workflow-label> state-save /tmp/opencode/playwright-cli/state.json
playwright-cli --session <workflow-label> cookie-list
playwright-cli --session <workflow-label> cookie-get session_id
playwright-cli --session <workflow-label> localstorage-list
playwright-cli --session <workflow-label> localstorage-get theme
playwright-cli --session <workflow-label> sessionstorage-list
playwright-cli --session <workflow-label> sessionstorage-get step
```

### Network

```bash
playwright-cli --session <workflow-label> requests
playwright-cli --session <workflow-label> requests --static
playwright-cli --session <workflow-label> request 5
playwright-cli --session <workflow-label> request-headers 5
playwright-cli --session <workflow-label> response-headers 5
playwright-cli --session <workflow-label> response-body 5
```

`requests` hides static requests by default. Use `requests --static` when validating basic navigations such as `https://example.com/`.

Route/mocking commands are powerful and should be used only for explicit testing:

```bash
playwright-cli --session <workflow-label> route "**/*.jpg" --status=404
playwright-cli --session <workflow-label> route-list
playwright-cli --session <workflow-label> unroute "**/*.jpg"
playwright-cli --session <workflow-label> unroute
```

### DevTools

```bash
playwright-cli --session <workflow-label> console
playwright-cli --session <workflow-label> console warning
playwright-cli --session <workflow-label> run-code 'async page => ({ title: await page.title(), url: page.url() })'
playwright-cli --session <workflow-label> tracing-start
playwright-cli --session <workflow-label> tracing-stop
playwright-cli --session <workflow-label> video-start /tmp/opencode/playwright-cli/video.webm
playwright-cli --session <workflow-label> video-stop
playwright-cli --session <workflow-label> show --annotate
playwright-cli --session <workflow-label> generate-locator e5 --raw
playwright-cli --session <workflow-label> highlight e5
playwright-cli --session <workflow-label> highlight --hide
```

## Raw output

The global `--raw` option strips page status, generated code, and snapshot sections from the output, returning only the result value. Use it to pipe command output into other tools.

```bash
playwright-cli --session <workflow-label> --raw eval '() => JSON.stringify(performance.timing)' | jq '.loadEventEnd - .navigationStart'
playwright-cli --session <workflow-label> --raw snapshot > /tmp/opencode/playwright-cli/snapshot.yml
playwright-cli --session <workflow-label> --raw cookie-get session_id
```

Avoid printing secrets from cookies, storage, or endpoint values.

## Open parameters

Generic `playwright-cli open` parameters are not the default for this skill because the browser already exists. Use `attach` for the configured headed browser.

```bash
# Correct default for this skill: attach once using the Quick start command.

# Correct cleanup for an attached external browser:
playwright-cli --session <workflow-label> detach
```

Do not use CDP for this workflow. The configured browser exposes a Playwright protocol endpoint.

## URLs with `&` on Windows

On Windows shells, escape `&` in URLs. This is usually not needed on the current Linux host, but it matters if commands are adapted elsewhere.

## Snapshots

After many commands, `playwright-cli` writes a snapshot under `.playwright-cli/` in the current directory and may print a snapshot file path.

```bash
playwright-cli --session <workflow-label> snapshot
playwright-cli --session <workflow-label> snapshot --filename=/tmp/opencode/playwright-cli/after-click.yaml
playwright-cli --session <workflow-label> snapshot e34
playwright-cli --session <workflow-label> snapshot --depth=4
playwright-cli --session <workflow-label> snapshot --boxes
```

## Targeting elements

By default, use refs from the snapshot to interact with page elements.

```bash
playwright-cli --session <workflow-label> snapshot
playwright-cli --session <workflow-label> click e15
```

You can also use CSS selectors or Playwright locators:

```bash
playwright-cli --session <workflow-label> click "#main > button.submit"
playwright-cli --session <workflow-label> click "getByRole('button', { name: 'Submit' })"
playwright-cli --session <workflow-label> click "getByTestId('submit-button')"
```

## Browser Sessions

Use `--session <workflow-label>` to keep a workflow's CLI state separate. The label is arbitrary; choose a meaningful task name.

```bash
playwright-cli --session page-check snapshot
playwright-cli --session page-check detach
```

Avoid by default:

```bash
playwright-cli close
playwright-cli close-all
playwright-cli kill-all
playwright-cli delete-data
```

Use those only with explicit user authorization to clean local CLI-owned sessions or data.

## Installation

Installation is outside the default workflow for this skill. Do not run `playwright-cli install`, `playwright-cli install-browser`, `npx`, `npm`, or browser download commands unless the user explicitly asks for installation work.

## Example: Form submission

Assume `form-check` is already attached using the Quick start command.

```bash
playwright-cli --session form-check goto https://example.com/form
playwright-cli --session form-check snapshot
playwright-cli --session form-check fill e1 "user@example.com"
playwright-cli --session form-check click e3
playwright-cli --session form-check snapshot
playwright-cli --session form-check detach
```

## Example: Multi-tab workflow

Assume `tab-check` is already attached using the Quick start command.

```bash
playwright-cli --session tab-check tab-new https://example.com/other
playwright-cli --session tab-check tab-list
playwright-cli --session tab-check tab-select 0
playwright-cli --session tab-check snapshot
playwright-cli --session tab-check detach
```

## Example: Debugging with DevTools

Assume `debug-check` is already attached using the Quick start command.

```bash
playwright-cli --session debug-check goto https://example.com
playwright-cli --session debug-check console
playwright-cli --session debug-check requests --static
playwright-cli --session debug-check detach
```

## Example: Interactive session

Use `show --annotate` only when user visual feedback is needed:

```bash
# Assume `review` is already attached using the Quick start command.
playwright-cli --session review show --annotate
playwright-cli --session review detach
```

## Specific tasks

- **Running and Debugging Playwright tests** [references/playwright-tests.md](references/playwright-tests.md)
- **Request mocking** [references/request-mocking.md](references/request-mocking.md)
- **Running Playwright code** [references/running-code.md](references/running-code.md)
- **Browser session management** [references/session-management.md](references/session-management.md)
- **Spec-driven testing (plan / generate / heal)** [references/spec-driven-testing.md](references/spec-driven-testing.md)
- **Storage state (cookies, localStorage)** [references/storage-state.md](references/storage-state.md)
- **Test generation** [references/test-generation.md](references/test-generation.md)
- **Tracing** [references/tracing.md](references/tracing.md)
- **Video recording** [references/video-recording.md](references/video-recording.md)
- **Inspecting element attributes** [references/element-attributes.md](references/element-attributes.md)
