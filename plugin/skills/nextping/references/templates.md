# NextPing templates

Give `template` and `data` instead of `blocks` on `notify`, `report` or `set_status`. The
background service turns them into blocks, a title and a plain body; your own `title` and `body`
win when you give them. A field that is wrong is named, for example
`data.failures has 51 items; the limit is 50`.

## `test_results`

`{ passed, failed, skipped?, durationMs?, failures?: [{ name, file?, message? }] (≤ 50) }` gives
stats tiles, a table of the failures, and a `bad` callout when `failed > 0`. The title reads
`Tests: 2 failed, 410 passed` or `Tests passed: 412`.

```json
{ "passed": 410, "failed": 2, "skipped": 3, "durationMs": 41960, "failures": [{ "name": "rounds half-even", "file": "test/vat.test.ts", "message": "expected 10.02, got 10.03" }] }
```

## `deploy`

`{ env, version?, status: running|succeeded|failed|rolled_back, steps?: [{ label, state }] (2–12), url? (https) }`
gives the steps as progress (or a callout without steps), and an Open link. The title reads
`Deploy v1.4.2 to prod: failed`. Send it with a `card_id` to follow one deploy in one card.

```json
{ "env": "prod", "version": "v1.4.2", "status": "running", "steps": [{ "label": "Build", "state": "done" }, { "label": "Migrate", "state": "running" }, { "label": "Smoke test", "state": "pending" }], "url": "https://ci.example.com/run/9" }
```

## `pr_ready`

`{ title, url (https), number?, branch?, additions?, deletions?, files?: [{ path, added, removed }] (≤ 100), checks?: [{ name, state }] (≤ 50) }`
gives stats, the changed files, the checks and an Open link. The title reads
`PR #7 ready: Fix VAT rounding`.

```json
{ "title": "Fix VAT rounding", "url": "https://github.com/acme/shop/pull/7", "number": 7, "branch": "bugfix/vat", "additions": 120, "deletions": 4, "files": [{ "path": "src/vat.ts", "added": 100, "removed": 4 }], "checks": [{ "name": "lint", "state": "done" }, { "name": "tests", "state": "running" }] }
```

## `incident`

`{ title, severity: low|high|critical, startedAt (epoch ms), impact?, events?: [{ at, label }] (≤ 50), links?: [{ label, url }] (≤ 4) }`
gives a callout with the impact, a timeline and links. The title reads
`Critical incident: 5xx on checkout`. Only a real incident is worth the notify severity `critical`.

```json
{ "title": "5xx on checkout", "severity": "high", "startedAt": 1760000000000, "impact": "Card payments fail for about 30% of users.", "events": [{ "at": 1760000000000, "label": "Alarm" }], "links": [{ "label": "Dashboard", "url": "https://grafana.example.com/d/1" }] }
```

## `build_progress`

`{ label, value? (0–1), steps?: [{ label, state }] (2–12) }`, with exactly one of `value` and
`steps`, gives one progress block. It is meant for a living card: send it again with the same
`card_id` as the build moves on, with `live: true` to show it live while it runs.

```json
{ "label": "Release build", "value": 0.4 }
```
