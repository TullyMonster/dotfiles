# Video Recording

Capture browser automation sessions as video for debugging, documentation, or verification. Produces WebM files and can expose sensitive page content.

## Basic Recording

```bash
# Start recording after attaching
playwright-cli --session <workflow-label> video-start /tmp/opencode/playwright-cli/demo.webm

# Add a chapter marker for section transitions
playwright-cli --session <workflow-label> video-chapter "Getting Started" --description="Opening the homepage" --duration=2000

# Navigate and perform actions
playwright-cli --session <workflow-label> goto https://example.com
playwright-cli --session <workflow-label> snapshot

# Stop and save
playwright-cli --session <workflow-label> video-stop
```

## Best Practices

### 1. Use Descriptive Filenames

```bash
# Include context in filename
playwright-cli --session <workflow-label> video-start /tmp/opencode/playwright-cli/login-flow.webm
```

### 2. Record entire hero scripts.

When recording a polished proof-of-work video, first rehearse the flow with normal CLI commands. For scripted pauses or overlays, use `run-code --filename` from a temp path.

```bash
playwright-cli --session <workflow-label> run-code --filename=/tmp/opencode/playwright-cli/video-script.js
```

Only use video recording when the user requests video evidence or visual review.

### Overlay API Summary

| Method | Use Case |
|--------|----------|
| `page.screencast.showChapter(title, { description?, duration?, styleSheet? })` | Full-screen chapter card |
| `page.screencast.showOverlay(html, { duration? })` | Custom HTML overlay |
| `disposable.dispose()` | Remove a sticky overlay |
| `page.screencast.hideOverlays()` / `page.screencast.showOverlays()` | Temporarily hide/show overlays |

## Tracing vs Video

| Feature | Video | Tracing |
|---------|-------|---------|
| Output | WebM file | Trace file |
| Shows | Visual recording | DOM snapshots, network, console, actions |
| Use case | Demos, documentation | Debugging, analysis |
| Size | Larger | Smaller |

## Limitations

- Recording adds overhead.
- Large recordings consume disk space.
- Videos can capture private content.
