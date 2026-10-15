# NextPing plugin for Claude Code

Phone notifications, questions, reports, remote approvals and nudges for Claude Code sessions,
end-to-end encrypted. Needs the NextPing app (App Store, Google Play).

## Install

```
/plugin marketplace add nextping/nextping
/plugin install nextping@nextping
```

Start a new session. The first one downloads `nextping` for your computer from this
repository's releases and checks its SHA-256 against `scripts/binary.env` (the plugin, not the
download server, is what you trust), registers a per-user background service, and opens a
pairing page. Scan its QR code in the app (**Add computer**). Later sessions start in
milliseconds and need nothing.

Windows needs Git for Windows: Claude Code runs the plugin's hooks with its `sh`.

## What it adds

- **MCP tools:** `notify`, `ask` (with a default and a timeout; long questions keep running in the
  background), `report`, `set_session_title`, `check_inbox`, `watch_start`, `watch_stop`,
  `watch_list`, `pair_phone`.
- **Hooks:** permission prompts go to your phone when you are away from the keyboard (the local
  dialog stays open, and whichever answers first wins; nothing is ever approved on its own);
  messages from your phone reach Claude after its next tool call; session state and "Claude
  finished" notifications.
- **Skill:** tells Claude when to use NextPing and how to write a phone-friendly report.

## Settings

`<NextPing home>/config.json`. The NextPing home is `$NEXTPING_HOME` when that is set, otherwise macOS
`~/Library/Application Support/NextPing`, Linux `$XDG_STATE_HOME/nextping` (`~/.local/state/nextping`
when `XDG_STATE_HOME` is unset or not an absolute path), Windows `%LOCALAPPDATA%\NextPing`:

```json
{ "permissions": { "relay": "when_idle", "idleAfterSec": 120, "neverRemote": ["^npm\\s+publish"] } }
```

`relay` is `when_idle` (the default: only after `idleAfterSec`, default 60, without keyboard or
mouse input), `always` or `never`. Force pushes, production deploys, `terraform apply` and
`kubectl` against production are always answered at the terminal; `neverRemote` adds your own
regular expressions (case-insensitive).

## Troubleshooting

- `/mcp` shows the server failed on the very first session: the binary was still downloading;
  reconnect it from `/mcp` a minute later.
- Nothing arrives: in the app, Settings → Notifications and alarms; then <https://nextping.dev/support/>.
- Remove: in the app, Settings → Computers → Forget (removes this computer from your account, so
  its dead-man alerts never fire), then `/plugin uninstall nextping@nextping`.
