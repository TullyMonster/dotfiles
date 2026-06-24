# Tracing

Capture detailed execution traces for debugging and analysis. Traces include DOM snapshots, screenshots, network activity, and console logs. They can contain sensitive data.

## Basic Usage

```bash
# Start trace recording
playwright-cli --session <workflow-label> tracing-start

# Perform actions
playwright-cli --session <workflow-label> goto https://example.com
playwright-cli --session <workflow-label> snapshot

# Stop trace recording
playwright-cli --session <workflow-label> tracing-stop
```

## Trace Output Files

Trace files are written under the current directory, commonly below `.playwright-cli/traces/`. Use `/tmp/playwright-cli` unless the user wants artifacts in the current project.

### `trace-{timestamp}.trace`

Main trace file containing actions, DOM snapshots, screenshots, timing, console messages, and source locations.

### `trace-{timestamp}.network`

Network log containing requests, responses, headers, bodies, timing, sizes, and failures.

### `resources/`

Cached resources needed to reconstruct trace state.

## What Traces Capture

| Category    | Details                                            |
| ----------- | -------------------------------------------------- |
| Actions     | Clicks, fills, hovers, keyboard input, navigations |
| DOM         | Full DOM snapshot before/after actions             |
| Screenshots | Visual state at each step                          |
| Network     | Requests, responses, headers, bodies, timing       |
| Console     | Console messages                                   |
| Timing      | Timing for each operation                          |

## Use Cases

### Debugging Failed Actions

```bash
playwright-cli --session <workflow-label> tracing-start
playwright-cli --session <workflow-label> click e5
playwright-cli --session <workflow-label> tracing-stop
```

### Analyzing Performance

```bash
playwright-cli --session <workflow-label> tracing-start
playwright-cli --session <workflow-label> goto https://example.com
playwright-cli --session <workflow-label> tracing-stop
```

### Capturing Evidence

```bash
playwright-cli --session <workflow-label> tracing-start
# perform the user-approved flow
playwright-cli --session <workflow-label> tracing-stop
```

## Trace vs Video vs Screenshot

| Feature             | Trace       | Video       | Screenshot       |
| ------------------- | ----------- | ----------- | ---------------- |
| Format              | .trace file | .webm video | .png/.jpeg image |
| DOM inspection      | Yes         | No          | No               |
| Network details     | Yes         | No          | No               |
| Step-by-step replay | Yes         | Continuous  | Single frame     |
| File size           | Medium      | Large       | Small            |
| Best for            | Debugging   | Demos       | Quick capture    |

## Best Practices

### 1. Start Tracing Before the Problem

Start tracing before reproducing the issue and stop as soon as evidence is captured.

### 2. Clean Up Old Traces

```bash
# Remove temporary traces only from the temp workspace you control.
find /tmp/playwright-cli/.playwright-cli/traces -mtime +7 -delete
```

## Limitations

- Traces add overhead.
- Large traces can consume disk space.
- Traces may capture sensitive page and network data.
