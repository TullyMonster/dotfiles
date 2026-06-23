# Spec-driven testing (plan -> generate -> heal)

End-to-end workflow for authoring and maintaining Playwright tests using `playwright-cli`. Use this only when the user asks for test planning, generation, or healing. For ordinary browser inspection, use the main skill workflow instead.

The three sections below can be used independently:

- **Planning** - explore the app, produce a spec file describing what to test.
- **Generate** - turn a spec into Playwright test files. Update the spec if it is vague or stale.
- **Heal** - diagnose failing tests, fix the code, reconcile the spec with reality.

When working with existing Playwright tests, debug sessions may be launched with `npx --no-install playwright test --debug=cli`, then attached with the generated `tw-...` session. Do not install Playwright or browsers unless the user explicitly asks.

---

## 1. Planning

Goal: produce a spec file such as `specs/<feature>.plan.md` that enumerates scenarios to test. **Always** write the spec to a file only when the user requested test planning.

### 1.1 Prerequisite: workspace

Check that the project already has Playwright before using test-specific workflows:

```bash
# Either of these confirms a workspace:
test -f playwright.config.ts || test -f playwright.config.js
npx --no-install playwright --version
```

If there is no Playwright install, stop and ask the user. Do not run `npm init playwright`, `playwright-cli install-browser`, or dependency installation automatically.

### 1.2 Prerequisite: seed test

A seed test is a minimal test that lands the page in the state every scenario starts from: navigation, login, feature flags, fixtures, or app setup. If the project already has seed/fixture conventions, follow them.

Minimum viable seed:

```ts
// tests/seed.spec.ts
import { test } from '@playwright/test';

test('seed', async ({ page }) => {
  await page.goto('https://example.com/');
});
```

Preferred: use existing project fixtures when present.

### 1.3 Explore the app

For pure exploration through the configured browser, attach once using the standard workflow from SKILL.md, then inspect:

```bash
playwright-cli --session <workflow-label> snapshot
playwright-cli --session <workflow-label> click e5
playwright-cli --session <workflow-label> eval '() => location.href'
```

For test-specific debugging, launch the existing seed test in the background and attach to the generated debug session:

```bash
PLAYWRIGHT_HTML_OPEN=never npx --no-install playwright test tests/seed.spec.ts --debug=cli
# wait for "Debugging Instructions" and the session name tw-XXXX
playwright-cli attach tw-XXXX
```

Map out:

- Interactive surfaces: forms, buttons, lists, filters, modals.
- Primary user journeys end-to-end.
- Edge cases: empty states, validation errors, long input, boundary values.
- Persistence: reload, local/session storage, URL fragments.
- Navigation: controls that change URL, back/forward behavior.

Stop any background test process when done.

### 1.4 Write the spec file

Save under `specs/<feature>.plan.md`. Use this structure:

```markdown
# <Feature> Test Plan

## Application Overview

<One paragraph describing what the feature does and why it matters.>

## Test Scenarios

### 1. <Group Name>

**Seed:** `tests/seed.spec.ts`

#### 1.1. <kebab-case-scenario-name>

**File:** `tests/<group>/<kebab-case-scenario-name>.spec.ts`

**Steps:**
1. <Concrete user step>
   - expect: <observable outcome>
   - expect: <another observable outcome>
2. <Next step>
   - expect: <outcome>

#### 1.2. <next-scenario>
...

### 2. <Next Group>
...
```

Guidelines:

- Each scenario is independent and starts from the seed's fresh state.
- Scenario names are kebab-case and match the test file name.
- Cover happy path, edge cases, validation, negative flows, persistence.
- Write steps at the user level, not the API level.
- Put observable outcomes in `- expect:` bullets.

---

## 2. Generate

Goal: take a spec file and produce Playwright test files. Optionally update the spec if it has drifted.

### 2.1 Inputs

- **Spec file**, e.g. `specs/basic-operations.plan.md`.
- **Target**, e.g. a single scenario, a group, or all.
- **Seed file**, read from the `**Seed:**` line of the scenario's group.

### 2.2 Generate one scenario

For each target scenario, work sequentially. If the project has Playwright tests, prefer the seed/debug workflow:

```bash
PLAYWRIGHT_HTML_OPEN=never npx --no-install playwright test <seed-file> --debug=cli
playwright-cli attach tw-XXXX
# resume if needed
```

Walk the scenario steps with `playwright-cli`, treating the spec as the plan and the live app as the source of truth. If a step is vague, stale, or contradicts the app, update the spec before continuing.

Every action prints equivalent Playwright TypeScript:

```bash
playwright-cli snapshot
playwright-cli fill e3 "John Doe"
playwright-cli press Enter
playwright-cli click e7
```

For each `- expect:` bullet, add an explicit assertion. See [test-generation.md](test-generation.md).

### 2.3 Generate multiple scenarios

Loop over targeted scenarios one at a time. Do not assume parallel generation is safe when scenarios share app state, browser state, or a seed session.

### 2.4 Run generated tests

After generation, run the new tests once if the project has Playwright installed:

```bash
PLAYWRIGHT_HTML_OPEN=never npx --no-install playwright test tests/<group>/<scenario>.spec.ts
```

Any failure goes to Section 3.

---

## 3. Heal

Goal: fix failing tests and update the spec if intended behavior changed.

### 3.1 Find failing tests

```bash
PLAYWRIGHT_HTML_OPEN=never npx --no-install playwright test
```

Record failing file/line entries and process them one at a time.

### 3.2 Debug one failure

Run the single failing test in debug mode in the background, then attach:

```bash
PLAYWRIGHT_HTML_OPEN=never npx --no-install playwright test tests/<group>/<scenario>.spec.ts:<line> --debug=cli
# wait for "Debugging Instructions" and the tw-XXXX session name
playwright-cli attach tw-XXXX
```

Diagnose with:

```bash
playwright-cli snapshot
playwright-cli console
playwright-cli requests --static
playwright-cli show --annotate
```

Common causes: selector drift, wrapper changes, ARIA rename, timing, assertion text updates, or leaked test data.

### 3.3 Apply the fix

Edit the test file to update locators, assertions, steps, or inputs. Stop the background debug run. Rerun the single test to confirm green.

Never skip tests or add arbitrary sleeps as a fix.

### 3.4 Reconcile with the spec

Open the spec referenced by the test and update it only if user-visible behavior changed. If it is unclear whether the app or spec is wrong, stop and ask the user with concrete observed behavior.

### 3.5 Iteration and giving up

- Fix failures one at a time.
- Rerun after each fix.
- If the app appears wrong and the user confirms it is a bug, record that clearly rather than silently weakening tests.

---

## Cross-references

| For... | See |
|---|---|
| Debug attach mechanics | [playwright-tests.md](playwright-tests.md) |
| How CLI actions become TypeScript | [test-generation.md](test-generation.md) |
| Mocking requests during exploration/generation | [request-mocking.md](request-mocking.md) |
| Managing CLI browser sessions | [session-management.md](session-management.md) |
