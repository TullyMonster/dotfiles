# Storage Management

Manage cookies, localStorage, sessionStorage, and browser storage state. The configured browser may use persistent state, so storage commands can affect later sessions.

## Storage State

Save and restore complete browser state including cookies and storage. This can write secrets to disk.

### Save Storage State

```bash
# Save to a specific temp filename
playwright-cli --session <workflow-label> state-save /tmp/playwright-cli/storage-state.json
```

### Restore Storage State

```bash
# Load storage state from file only when requested
playwright-cli --session <workflow-label> state-load /tmp/playwright-cli/storage-state.json

# Reload page to apply cookies if needed
playwright-cli --session <workflow-label> reload
```

### Storage State File Format

The saved file can contain cookies, auth tokens, and localStorage values. Never commit it or paste its full content.

## Cookies

### List All Cookies

```bash
playwright-cli --session <workflow-label> cookie-list
```

### Filter Cookies by Domain

```bash
playwright-cli --session <workflow-label> cookie-list --domain=example.com
```

### Filter Cookies by Path

```bash
playwright-cli --session <workflow-label> cookie-list --path=/api
```

### Get Specific Cookie

```bash
playwright-cli --session <workflow-label> cookie-get session_id
```

### Set a Cookie

Mutating cookies requires explicit user intent.

```bash
# Basic cookie
playwright-cli --session <workflow-label> cookie-set session abc123

# Cookie with options
playwright-cli --session <workflow-label> cookie-set session abc123 --domain=example.com --path=/ --httpOnly --secure
```

### Delete a Cookie

```bash
playwright-cli --session <workflow-label> cookie-delete session_id
```

### Clear All Cookies

```bash
playwright-cli --session <workflow-label> cookie-clear
```

### Advanced: Multiple Cookies or Custom Options

```bash
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.context().addCookies([
    { name: "session_id", value: "sess_abc123", domain: "example.com", path: "/", httpOnly: true }
  ]);
}'
```

## Local Storage

### List All localStorage Items

```bash
playwright-cli --session <workflow-label> localstorage-list
```

### Get Single Value

```bash
playwright-cli --session <workflow-label> localstorage-get token
```

### Set Value

```bash
playwright-cli --session <workflow-label> localstorage-set theme dark
```

### Set JSON Value

```bash
playwright-cli --session <workflow-label> localstorage-set user_settings '{"theme":"dark","language":"en"}'
```

### Delete Single Item

```bash
playwright-cli --session <workflow-label> localstorage-delete token
```

### Clear All localStorage

```bash
playwright-cli --session <workflow-label> localstorage-clear
```

### Advanced: Multiple Operations

```bash
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.evaluate(() => {
    localStorage.setItem("token", "jwt_abc123");
    localStorage.setItem("user_id", "12345");
  });
}'
```

## Session Storage

### List All sessionStorage Items

```bash
playwright-cli --session <workflow-label> sessionstorage-list
```

### Get Single Value

```bash
playwright-cli --session <workflow-label> sessionstorage-get step
```

### Set Value

```bash
playwright-cli --session <workflow-label> sessionstorage-set step 3
```

### Delete Single Item

```bash
playwright-cli --session <workflow-label> sessionstorage-delete step
```

### Clear sessionStorage

```bash
playwright-cli --session <workflow-label> sessionstorage-clear
```

## IndexedDB

### List Databases

```bash
playwright-cli --session <workflow-label> run-code 'async page => {
  return await page.evaluate(async () => indexedDB.databases());
}'
```

### Delete Database

```bash
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.evaluate(() => indexedDB.deleteDatabase("myDatabase"));
}'
```

## Common Patterns

### Authentication State Reuse

Only save or restore authenticated state when the user explicitly requests it. Store files under `/tmp/playwright-cli` by default.

### Save and Restore Roundtrip

Use state roundtrips for testing, not as normal cleanup. Delete temp files containing credentials when the task is done.

## Security Notes

- Never commit storage state files containing auth tokens.
- Never print full cookies, tokens, or storage dumps.
- Prefer read-only inspection unless mutation is requested.
- Do not use `delete-data` by default.
