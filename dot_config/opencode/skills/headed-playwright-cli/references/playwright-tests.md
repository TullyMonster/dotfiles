# Running Playwright Tests

Use this reference only in a project that already has Playwright tests. Do not bootstrap Playwright, install browsers, or download dependencies unless the user explicitly asks.

To run existing Playwright tests, use the project's command or `npx --no-install playwright test`. To avoid opening the interactive HTML report, set `PLAYWRIGHT_HTML_OPEN=never`.

```bash
# Run all tests
PLAYWRIGHT_HTML_OPEN=never npx --no-install playwright test

# Run all tests through a custom npm script when that script already exists
PLAYWRIGHT_HTML_OPEN=never npm run special-test-command
```

# Debugging Playwright Tests

To debug a failing Playwright test, run it with `--debug=cli`. This creates a temporary CLI debug session printed in the test output.

**IMPORTANT**: run the test command in the background and check the output until "Debugging Instructions" is printed. Stop the command after you have finished debugging.

```bash
# Run the test
PLAYWRIGHT_HTML_OPEN=never npx --no-install playwright test --debug=cli
# ...
# ... debugging instructions for "tw-abcdef" session ...
# ...

# Attach to the test debug session
playwright-cli attach tw-abcdef
```

This debug attach flow is separate from the configured headed browser endpoint. Keep the test running while you inspect the page. After fixing the test, stop the background test run and rerun the relevant test normally.
