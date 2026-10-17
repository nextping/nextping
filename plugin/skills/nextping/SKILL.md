---
name: nextping
description: How to use NextPing, which connects this coding session to the user's phone (push alerts, questions, reports, remote approvals, watchers). NextPing stays off until the user asks for it. Use this skill when the user asks for phone notifications, questions or approvals, asks to be told, asked or woken about something, or says they are stepping away - "tell me when it's done", "ping me", "notify me", "ask me before you", "check with me", "watch the logs and ping me", "keep an eye on it while I'm away", "wake me up if", "send me a summary", "I'm stepping away", "I'll be on my phone" - and when a message tagged [NextPing] from the user's phone appears in your context (pause, status, wrap up, stop, free text, late answers, report replies, watch alerts, card button replies, update level changes). Also use it when a NextPing tool says the machine is not paired, or the user asks to pair or connect their phone ("pair my phone", "set up NextPing"). Covers the start, notify, ask, report, set_status, check_inbox, set_session_title, watch_start, watch_stop, watch_list and pair_phone tools, update levels (every update or only important), native card blocks (tables, charts, stats, progress, checklists) and templates, living cards that update in place, multi-select and text questions, a pinned session status, picking a severity, ask defaults and timeouts, the report HTML component kit, and pairing.
---

# NextPing: this session, on the user's phone

NextPing sends what matters from this session to the user's phone, end to end encrypted, and brings
their answers back. It stays off until the user wants it: a session that never started NextPing
never appears on the phone, and its permission prompts stay at the terminal. Once started, the
session is a thread on the phone (default title `repo · branch · Claude`). The tools are on the
`nextping` MCP server: `start`, `notify`, `ask`, `report`, `set_status`, `check_inbox`,
`set_session_title`, `watch_start`, `watch_stop`, `watch_list`, `pair_phone`.

## When to reach for it

Work normally and do not use NextPing unless the user asks for phone notifications, questions or approvals, asks to be told, asked or woken about something, or says they are stepping away. Then call start (or the tool you need) and follow the level the result gives.

Once NextPing has started in this session:

- A long task finished or failed, or you hit something only the user can unblock: tell them.
- You are about to do something with a real blast radius (deploy, migration, deleting data,
  force-push) and the user is not watching: `ask` first.
- After deploys and migrations, offer a `watch_start` instead of polling with your own tokens.

Do not narrate routine steps. One good message beats ten small ones.

## Levels: what reaches the phone

When NextPing starts, the phone asks the user how much of this session they want. Their app's
default applies until they answer, and they can change it later from the session's menu. The start
result tells you the level, and a `[NextPing]` message tells you when the user chooses or changes it.

| Level | Pushes to the phone |
|---|---|
| every update | everything but `info` notifications and session bookkeeping |
| only important | `ask`, permission requests, `notify` with `action_needed` or `critical`, the report sent with `final: true`, and a notable `notify` sent with `important: true` |

Under "only important", keep sending what you would send under "every update": NextPing decides
what pushes, and the quiet entries are still the session's record on the phone. Set
`important: true` only on the rare `notable` the user must not miss, and `final: true` on the
end-of-task report.

## notify: pick the severity by what the user should feel

| Severity | Use for | Phone behaviour |
|---|---|---|
| `info` | FYI, nothing to do | quiet entry in the thread |
| `notable` (default) | done, milestone, result worth seeing | normal push |
| `action_needed` | the user has to do something | push with actions |
| `critical` | production down, data loss, security incident, or something the user explicitly asked to be woken for | one alarm of at most a minute, even at night |

Never use `critical` for "tests failed" or "build broke" on a branch.
If the user asked you to wake them for something ("wake me if the migration fails"), that event is critical.

Title: one line, the outcome first ("Deploy to staging finished: 2 warnings"). Body: the details
they need to decide.

## ask: decisions with a safe default

- 2–5 options with short stable ids (`yes`, `rollback`, `skip`), labels the user can tap.
- `default_option` is what you will do if nobody answers. Choose the safe or reversible one.
- `timeout_sec` defaults to 30 minutes (max 24 h). Only set `on_timeout: "wait"` when the user
  told you to wait for them (or asked you to pause).
- If the result says ASSUMED, nobody answered: say so in your summary ("I went with the default,
  rollback, because nobody answered within 30 minutes"). A late answer arrives later as a
  `[NextPing]` message; if it differs, correct course.
- In Claude Code a long `ask` moves to the background; keep working on what does not depend on it.
- `kind: "multi"` lets the user pick several options (`default_option_ids`, `min_select`,
  `max_select`); `kind: "text"` lets them type the answer (`placeholder`, `default_text`). A text
  question without `default_text` that times out returns `ASSUMED: no answer`: go on without the
  value, or ask again later.
- `blocks` put context above the question, for example a `table` of failing tests above a
  multi-select of the ones to skip.

## report: the end-of-task summary

Send one when substantial work is done, or periodically on long runs. Set `final: true` on the
end-of-task report. Self-contained HTML, read on a phone: lead with the outcome, then what changed,
tests, risks, next steps. NextPing embeds its CSS kit; use its classes (`t-card`,
`t-badge t-ok|t-warn|t-bad`, `t-kv`, `t-stats`, `t-table`, `t-progress`, `t-list`, `t-diff`,
`t-actions` + `t-btn`). A report can also be a native page: `blocks` or a `template` instead of
`html`. Buttons can answer back with `onclick="agent.reply({choice: 'merge'})"`;
the reply arrives as a `[NextPing]` message. HTML up to about 600 KB, kit included (less if mostly
non-ASCII text): over that the tool refuses it with its size. Keep reports phone-sized; link to
large artifacts instead of embedding them. Leave `allow_network` off unless the report needs remote
images or scripts (it could leak content). Components and a full example:
[report kit](references/report-kit.md).

## Cards: blocks, templates and living cards

`notify`, `ask`, `report` and `set_status` take native blocks that the phone draws in its own
design: `markdown`, `code`, `diff`, `log`, `table`, `chart`, `stats`, `progress`, `checklist`,
`timeline`, `callout`, `links`, `image`, `html` (the escape hatch) and `actions` (reply buttons).
Prefer them to text dumps and to HTML. Choose a `tone` (`ok`, `warn`, `bad`, `info`, `neutral`),
never colours. The plain title and body still matter: the lock screen shows them, and a body is
written from the blocks when you leave it out. The `blocks` argument lists every block's fields.
An error names the block and the field (`blocks[2] (table): rows has 260 items; the limit is 200`),
and the block's shape when a field is missing or unknown: fix it and send again. Limits and
examples: [blocks](references/blocks.md).

When one fits, use a template instead: `test_results`, `deploy`, `pr_ready`, `incident` or
`build_progress`, given as `template` and `data` ([templates](references/templates.md)).

A **living card** updates in place. Send `notify` again with the same `card_id` as the work moves
on ("Build 25%", then "Build 100%"). The first version pushes, and updates stay quiet unless the
severity rises or you set `important: true`. Add `live: true` (with exactly one `progress` or
`checklist` block) to show a running card live, and send `live: false` when it ends. A tap on an
`actions` button arrives as `[NextPing] reply on "<card title>": <button label>`.

## set_status: the pinned status

`set_status` pins one short card at the top of the session's thread: what you are doing now
(`title`, `body`, up to 10 blocks, or a template). It never alerts. Each call replaces it, and
`clear: true` removes it. On a long run, keep it current instead of sending many notifications.

## watch_start: token-free monitoring

The NextPing background service runs a command on an interval and matches its output, with no model
calls. Prefer it to `sleep` loops. Examples:

- After a deploy: `name: "prod health"`,
  `shell: "curl -s -o /dev/null -w '%{http_code}' https://app/health"`,
  `interval_sec: 60`, `match: {regex: "^5"}`, `until_sec: 3600`, `action: "both"`.
- Error rate: `match: {threshold: {extract: "errors=(\\d+)", op: ">", value: 10}}`.
- A job that must keep succeeding: `match: {exit_code: {op: "!=", value: 0}}`.
- Overnight: add `deadman_timeout_sec` so silence (laptop asleep, network down) also alerts.

`action: "wake_agent"` puts the match in your inbox; `alert` pushes to the phone; `both` does both.
A firing watch alerts at `critical` unless you set `severity`; lower it for anything that is not an
incident.
Stop watchers you no longer need with `watch_stop`; `watch_list` shows their state (`error`: runs
fail, or the dead-man alert is not armed, e.g. dropped as stale after 7.5 days and re-arming).

Commands run inside the background service, not your shell: a login service has a minimal
environment, and a service an agent started keeps that agent's environment minus its session
variables. Use absolute paths, set what the command needs inline, and never leave an empty argv
item (it is refused). Regexes are JavaScript with only the `m` flag; one run lasts at most 1 h.

## Messages from the phone

In Claude Code they appear by themselves after a tool call, as a block starting with
`[NextPing] Messages from the user's phone`. Other agents call `check_inbox` (also do this when you
are about to wait or end a long turn). Act on them:

- **Message from the user**: treat it like a prompt typed at the terminal.
- **PAUSE**: finish the current step, then `ask` "Paused. Resume?" (options resume/stop,
  `on_timeout: "wait"`) and do nothing until it returns.
- **STATUS**: send a short `notify` (severity `info`): doing what, how far, what blocks you.
- **WRAP UP**: finish the current change, start nothing new, send a `report`, end your turn.
- **STOP**: stop at once; run no more tools; end with one line on where you left off. NextPing may
  also have interrupted the process.
- **Update level**: the user chose how much of this session reaches them; keep working as the
  Levels section says.
- **Late answer / report reply / card reply / watch fired**: re-check the decision, handle the reply, triage
  the alert.

## Session title

Once NextPing has started, call `set_session_title` when you know the task ("Fix checkout VAT
rounding"), so the user can tell threads apart. Renaming starts NextPing, so do not rename a session
the user never asked to see on their phone.

## When NextPing is not available

If a tool says the machine is not paired, call `pair_phone` once: it opens a pairing page in the
user's browser. Tell them to scan it with the NextPing app (Add computer), then carry on without
NextPing until they say they have paired. Call `pair_phone` also when the user asks to pair or connect
their phone. Do not retry other NextPing tools in a loop, and do not tell the user to run
`nextping` in your Bash tool: under the Claude Code plugin it is not on PATH. If the not-paired
message shows a `! "…" pair --open` line, the user can type that instead. If the background service
is not running, say so once.

## Outside Claude Code (CLI)

Inside Claude Code, use the MCP tools above. The same features exist as a CLI for other agents'
shells where `nextping` is on PATH (Codex or Cursor after `nextping setup`), and for
scripts: `nextping start`, `nextping notify "<title>" --severity notable`,
`nextping ask "<question>" --option y=Yes --option n=No --default n` (prints the id; exit 3
means the default was taken), `nextping notify "<title>" --blocks @blocks.json --card-id build`,
`nextping status set "<title>"`, `nextping report --title T --file r.html`,
`nextping inbox`, `nextping pair --open`, `nextping watch start …`. Run
`nextping help` for the rest.
