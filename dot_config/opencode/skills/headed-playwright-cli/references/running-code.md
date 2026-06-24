# Running Custom Playwright Code

Use `run-code` to execute arbitrary Playwright code for advanced scenarios not covered by CLI commands. Prefer simpler commands such as `eval`, `snapshot`, `click`, and `fill` when possible.

## Syntax

```bash
playwright-cli --session <workflow-label> run-code 'async page => {
  // Your Playwright code here.
  // Access page.context() for browser context operations.
}'
```

You can also load the function from a file. Put temporary scripts under `/tmp/playwright-cli` unless the user asked for a project artifact.

```bash
playwright-cli --session <workflow-label> run-code --filename=/tmp/playwright-cli/my-script.js
```

The code must be a single function expression. It is wrapped in `(...)` and evaluated. `import`, `export`, and `require` syntax is not supported.

## Geolocation

```bash
# Grant geolocation permission and set location
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.context().grantPermissions(["geolocation"]);
  await page.context().setGeolocation({ latitude: 37.7749, longitude: -122.4194 });
}'

# Set location to London
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.context().grantPermissions(["geolocation"]);
  await page.context().setGeolocation({ latitude: 51.5074, longitude: -0.1278 });
}'

# Clear geolocation override
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.context().clearPermissions();
}'
```

## Permissions

```bash
# Grant multiple permissions
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.context().grantPermissions(["geolocation", "notifications", "camera", "microphone"]);
}'

# Grant permissions for specific origin
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.context().grantPermissions(["clipboard-read"], { origin: "https://example.com" });
}'
```

## Media Emulation

```bash
# Emulate dark color scheme
playwright-cli --session <workflow-label> run-code 'async page => { await page.emulateMedia({ colorScheme: "dark" }); }'

# Emulate light color scheme
playwright-cli --session <workflow-label> run-code 'async page => { await page.emulateMedia({ colorScheme: "light" }); }'

# Emulate reduced motion
playwright-cli --session <workflow-label> run-code 'async page => { await page.emulateMedia({ reducedMotion: "reduce" }); }'

# Emulate print media
playwright-cli --session <workflow-label> run-code 'async page => { await page.emulateMedia({ media: "print" }); }'
```

## Wait Strategies

```bash
# Wait for specific element
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.locator(".loading").waitFor({ state: "hidden" });
}'

# Wait for function to return true
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.waitForFunction(() => window.appReady === true);
}'

# Wait with timeout
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.locator(".result").waitFor({ timeout: 10000 });
}'
```

Avoid using `networkidle` as a default wait strategy.

## Frames and Iframes

```bash
# Work with iframe
playwright-cli --session <workflow-label> run-code 'async page => {
  const frame = page.locator("iframe#my-iframe").contentFrame();
  await frame.locator("button").click();
}'

# Get all frames
playwright-cli --session <workflow-label> run-code 'async page => page.frames().map(frame => frame.url())'
```

## File Downloads

```bash
# Handle file download
playwright-cli --session <workflow-label> run-code 'async page => {
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("link", { name: "Download" }).click();
  const download = await downloadPromise;
  await download.saveAs("/tmp/playwright-cli/downloaded-file.pdf");
  return download.suggestedFilename();
}'
```

## Clipboard

```bash
# Read clipboard (requires permission)
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.context().grantPermissions(["clipboard-read"]);
  return await page.evaluate(() => navigator.clipboard.readText());
}'

# Write to clipboard
playwright-cli --session <workflow-label> run-code 'async page => {
  await page.evaluate(text => navigator.clipboard.writeText(text), "Hello clipboard!");
}'
```

## Page Information

```bash
# Get page title
playwright-cli --session <workflow-label> run-code 'async page => await page.title()'

# Get current URL
playwright-cli --session <workflow-label> run-code 'async page => page.url()'

# Get page content
playwright-cli --session <workflow-label> run-code 'async page => await page.content()'

# Get viewport size
playwright-cli --session <workflow-label> run-code 'async page => page.viewportSize()'
```

## JavaScript Execution

```bash
# Execute JavaScript and return result
playwright-cli --session <workflow-label> run-code 'async page => {
  return await page.evaluate(() => ({
    userAgent: navigator.userAgent,
    language: navigator.language,
    cookiesEnabled: navigator.cookieEnabled,
  }));
}'

# Pass arguments to evaluate
playwright-cli --session <workflow-label> run-code 'async page => {
  const multiplier = 5;
  return await page.evaluate(m => document.querySelectorAll("li").length * m, multiplier);
}'
```

## Error Handling

```bash
# Try-catch in run-code
playwright-cli --session <workflow-label> run-code 'async page => {
  try {
    await page.getByRole("button", { name: "Submit" }).click({ timeout: 1000 });
    return "clicked";
  } catch (error) {
    return "element not found";
  }
}'
```

## Complex Workflows

```bash
# Scrape data from multiple pages
playwright-cli --session <workflow-label> run-code 'async page => {
  const results = [];
  for (let i = 1; i <= 3; i++) {
    await page.goto(`https://example.com/page/${i}`);
    const items = await page.locator(".item").allTextContents();
    results.push(...items);
  }
  return results;
}'
```
