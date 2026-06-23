# Test Generation

Generate Playwright test code automatically as you interact with the browser. Treat generated code as a draft; add assertions and project-specific fixtures manually.

## How It Works

Every action you perform with `playwright-cli` generates corresponding Playwright TypeScript code. This code appears in the output and can be copied into test files when the user requested test work.

## Example Workflow

```bash
# Start an attached session

# Take a snapshot to see elements
playwright-cli --session <workflow-label> snapshot
# Output shows: e1 [textbox "Email"], e2 [textbox "Password"], e3 [button "Sign In"]

# Fill form fields - generates code automatically
playwright-cli --session <workflow-label> fill e1 "user@example.com"
# Ran Playwright code:
# await page.getByRole('textbox', { name: 'Email' }).fill('user@example.com');

playwright-cli --session <workflow-label> fill e2 "password123"
playwright-cli --session <workflow-label> click e3
```

## Building a Test File

Collect generated code into a Playwright test only when the user requested test creation. Prefer existing project fixtures and conventions.

```typescript
import { test, expect } from '@playwright/test';

test('login flow', async ({ page }) => {
  await page.goto('https://example.com/login');
  await page.getByRole('textbox', { name: 'Email' }).fill('user@example.com');
  await page.getByRole('textbox', { name: 'Password' }).fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await expect(page).toHaveURL(/.*dashboard/);
});
```

## Best Practices

### 1. Use Semantic Locators

Generated role-based locators are usually more resilient than CSS selectors:

```typescript
// Good
await page.getByRole('button', { name: 'Submit' }).click();

// Avoid unless no better locator exists
await page.locator('#submit-btn').click();
```

### 2. Explore Before Recording

```bash
playwright-cli --session <workflow-label> snapshot
playwright-cli --session <workflow-label> click e5
```

### 3. Add Assertions Manually

Generated actions are not enough. Add expectations such as `toBeVisible`, `toHaveText`, `toHaveValue`, `toBeChecked`, or `toMatchAriaSnapshot`.

```bash
# Get a stable locator for an element ref to use in the assertion
playwright-cli --session <workflow-label> --raw generate-locator e5
# getByRole('button', { name: 'Submit' })

# Capture expected text content for toHaveText
playwright-cli --session <workflow-label> --raw eval 'el => el.textContent' e5

# Capture expected input value for toHaveValue/toBeEmpty
playwright-cli --session <workflow-label> --raw eval 'el => el.value' e5

# Capture expected aria snapshot for toMatchAriaSnapshot/toBeChecked
playwright-cli --session <workflow-label> --raw snapshot
playwright-cli --session <workflow-label> --raw snapshot e5
```
