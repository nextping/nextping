# NextPing card blocks

Blocks go in `blocks` on `notify`, `ask` (context above the question), `report` (a native page
instead of `html`) and `set_status` (at most 10, and no `html`, `image` or `actions`). A message
holds at most 30 blocks and 600 KB of JSON, images included. Every block is
`{ "type": …, "id"?: …, …fields }`; `id` (≤ 64) is optional. Strings are plain text unless marked
*markdown*: bold, italic, inline code, https links, lists and `###` headings, with no HTML and no
images. A `tone` is `ok`, `warn`, `bad`, `info` or `neutral`. A step or item `state` is `done`,
`running`, `failed`, `skipped` or `pending`.

When something is over a limit, the tool names the block and the field, for example
`blocks[2] (table): rows has 260 items; the limit is 200`. Fix it and send again.

## `markdown`

`text` (*markdown*, ≤ 8000). The default text block.

```json
{ "type": "markdown", "text": "**Deployed** v1.4.2 to production.\n- 0 errors in 10 min" }
```

## `code`

`code` (≤ 20 000), `language?` (≤ 30), `title?` (≤ 120). Long code collapses; it has a copy button.

```json
{ "type": "code", "language": "bash", "title": "Reproduce", "code": "bun test test/vat.test.ts" }
```

## `diff`

`files` (1–100) of `{ path (≤ 300), status: added|modified|deleted|renamed, added, removed, hunk? }`.
A `hunk` is a unified diff of at most 20 000 characters, and all hunks together are at most 60 000.

```json
{ "type": "diff", "files": [{ "path": "src/vat.ts", "status": "modified", "added": 1, "removed": 1, "hunk": "@@ -10 +10 @@\n-  return round(x)\n+  return roundHalfEven(x)" }] }
```

## `log`

`lines` (1–200), each a string or `{ text, tone? }` of at most 500 characters; `title?`; `collapsed?`
(default true). Monospaced; `bad` and `warn` lines stand out.

```json
{ "type": "log", "title": "deploy.log", "lines": ["migrating…", { "text": "ERROR relation \"orders\" is locked", "tone": "bad" }] }
```

## `table`

`columns` (1–8) of `{ key (≤ 40), label (≤ 60), align?: start|end, format?: text|number|percent|duration_ms|bytes }`.
`rows` (0–200) of `{ cells: { <key>: string (≤ 500) | number | null | { value, tone? } }, tone? }`;
a cell's key must be a column key. `caption?` (≤ 200). Wide tables scroll sideways; tapping a
header sorts.

```json
{ "type": "table", "caption": "Slowest tests", "columns": [{ "key": "name", "label": "Test" }, { "key": "ms", "label": "Time", "align": "end", "format": "duration_ms" }], "rows": [{ "cells": { "name": "checkout e2e", "ms": 41200 }, "tone": "warn" }] }
```

## `chart`

`kind: line|bar|sparkline`; `series` (1–4) of `{ label (≤ 60), points: number[] (1–200), tone? }`;
`xLabels?` (one per point, each ≤ 20); `unit?` (≤ 12); `title?` (≤ 120). A `sparkline` has one
series and no `xLabels`.

```json
{ "type": "chart", "kind": "line", "title": "p95 latency", "unit": "ms", "xLabels": ["10:00", "10:05", "10:10"], "series": [{ "label": "checkout", "points": [180, 240, 190] }] }
```

## `stats`

`items` (1–6) of `{ label (≤ 40), value: string (≤ 40) | number, unit? (≤ 12), delta? (≤ 20), tone? }`.
Big-number tiles.

```json
{ "type": "stats", "items": [{ "label": "Passed", "value": 412, "tone": "ok" }, { "label": "Failed", "value": 2, "tone": "bad" }, { "label": "Coverage", "value": 87.5, "unit": "%", "delta": "+1.2" }] }
```

## `progress`

`mode: "bar"` with `value` (0–1) and `label?` (≤ 120); or `mode: "steps"` with `steps` (2–12) of
`{ label (≤ 40), state }`.

```json
{ "type": "progress", "mode": "steps", "steps": [{ "label": "Build", "state": "done" }, { "label": "Migrate", "state": "running" }, { "label": "Smoke test", "state": "pending" }] }
```

## `checklist`

`items` (1–50) of `{ label (≤ 200), state, detail? (≤ 500) }`.

```json
{ "type": "checklist", "items": [{ "label": "lint", "state": "done" }, { "label": "unit tests", "state": "failed", "detail": "2 failures in vat.test.ts" }] }
```

## `timeline`

`events` (1–50) of `{ at (epoch ms), label (≤ 200), detail? (≤ 500), tone? }`, shown in time order.

```json
{ "type": "timeline", "events": [{ "at": 1760000000000, "label": "5xx alarm", "tone": "bad" }, { "at": 1760000300000, "label": "Rolled back to v1.4.1", "tone": "ok" }] }
```

## `callout`

`tone` (required), `title?` (≤ 120), `text` (*markdown*, ≤ 2000).

```json
{ "type": "callout", "tone": "warn", "title": "Heads up", "text": "One flaky test was skipped: `checkout e2e`." }
```

## `links`

`buttons` (1–4) of `{ label (≤ 40), url (https only, ≤ 2000) }`. The phone shows the host before
it opens the browser.

```json
{ "type": "links", "buttons": [{ "label": "Open PR #7", "url": "https://github.com/acme/shop/pull/7" }] }
```

## `image`

`data` (base64 PNG, JPEG or WebP, ≤ 300 KB decoded; the type is read from the bytes), `alt`
(required, ≤ 300), `caption?` (≤ 300). When the data is numbers, a `chart` or `table` is better.

```json
{ "type": "image", "alt": "Coverage by package", "data": "iVBORw0KGgoAAAAA" }
```

## `html`

`html` (≤ 100 KB), `allowNetwork?` (default false), `heightHint?: small|medium|large`. A sandboxed
web view with the report kit's CSS, collapsed until tapped; `agent.reply()` works as in reports.
This is the escape hatch: use a native block when one fits.

```json
{ "type": "html", "heightHint": "small", "html": "<div class=\"t-card\"><span class=\"t-badge t-ok\">green</span></div>" }
```

## `actions`

`buttons` (1–4) of `{ id (≤ 64), label (≤ 40), style?: primary|secondary|danger }`, with unique
ids. A tap reaches you as `[NextPing] reply on "<card title>": <button label>`.

```json
{ "type": "actions", "buttons": [{ "id": "rollback", "label": "Roll back", "style": "danger" }, { "id": "keep", "label": "Keep it" }] }
```
