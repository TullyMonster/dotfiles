# Inspecting Element Attributes

When the snapshot doesn't show an element's `id`, `class`, `data-*` attributes, or other DOM properties, use `eval` to inspect them. These examples assume a session is already attached with `--session <workflow-label>`.

## Examples

```bash
playwright-cli --session <workflow-label> snapshot
# snapshot shows a button as e7 but doesn't reveal its id or data attributes

# get the element's id
playwright-cli --session <workflow-label> eval 'el => el.id' e7

# get all CSS classes
playwright-cli --session <workflow-label> eval 'el => el.className' e7

# get a specific attribute
playwright-cli --session <workflow-label> eval 'el => el.getAttribute("data-testid")' e7
playwright-cli --session <workflow-label> eval 'el => el.getAttribute("aria-label")' e7

# get a computed style property
playwright-cli --session <workflow-label> eval 'el => getComputedStyle(el).display' e7
```

Prefer snapshot refs, roles, labels, and test IDs before brittle selectors.
