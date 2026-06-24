# Request Mocking

Intercept, mock, modify, and block network requests. These commands change behavior for the attached session, so use them only for explicit testing or debugging and clean routes up before detaching.

## CLI Route Commands

```bash
# Mock with custom status
playwright-cli --session <workflow-label> route "**/*.jpg" --status=404

# Mock with JSON body
playwright-cli --session <workflow-label> route "**/api/users" --body='[{"id":1,"name":"Alice"}]' --content-type=application/json

# Mock with custom headers
playwright-cli --session <workflow-label> route "**/api/data" --body='{"ok":true}' --header="X-Custom: value"

# Remove headers from requests
playwright-cli --session <workflow-label> route "**/*" --remove-header=cookie,authorization

# List active routes
playwright-cli --session <workflow-label> route-list

# Remove a route or all routes
playwright-cli --session <workflow-label> unroute "**/*.jpg"
playwright-cli --session <workflow-label> unroute
```

## URL Patterns

```text
**/api/users           - Exact path match
**/api/*/details       - Wildcard in path
**/*.{png,jpg,jpeg}    - Match file extensions
**/search?q=*          - Match query parameters
```

## Advanced Mocking with run-code

For conditional responses, request body inspection, response modification, or delays, use `run-code`.

### Conditional Response Based on Request

```bash
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.route("**/api/login", route => {
    const body = route.request().postDataJSON();
    if (body.username === "admin") {
      route.fulfill({ body: JSON.stringify({ token: "mock-token" }) });
    } else {
      route.fulfill({ status: 401, body: JSON.stringify({ error: "Invalid" }) });
    }
  });
}'
```

### Modify Real Response

```bash
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.route("**/api/user", async route => {
    const response = await route.fetch();
    const json = await response.json();
    json.isPremium = true;
    await route.fulfill({ response, json });
  });
}'
```

### Simulate Network Failures

```bash
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.route("**/api/offline", route => route.abort("internetdisconnected"));
}'
# Options: connectionrefused, timedout, connectionreset, internetdisconnected
```

### Delayed Response

```bash
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.route("**/api/slow", async route => {
    await new Promise(r => setTimeout(r, 3000));
    route.fulfill({ body: JSON.stringify({ data: "loaded" }) });
  });
}'
```
