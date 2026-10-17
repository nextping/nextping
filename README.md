# NextPing

Your coding agent, on your phone. NextPing sends what matters from Claude Code, Codex, Cursor and
your own scripts to your phone — alerts that can wake you, questions with a default, reports,
permission prompts — and carries your answers, approvals and nudges back. Everything between your
computers and your phones is end-to-end encrypted. Free, no ads, no tracking.

- **App:** NextPing on the App Store and Google Play.
- **Website:** <https://nextping.dev/>
- **Privacy policy:** [nextping.dev/privacy](https://nextping.dev/privacy/) ·
  **Terms:** [nextping.dev/terms](https://nextping.dev/terms/) ·
  **Support:** [nextping.dev/support](https://nextping.dev/support/) or `support@nextping.dev`

This repository holds the Claude Code plugin (`plugin/`, `.claude-plugin/`) and, under
[Releases](https://github.com/nextping/nextping/releases), the `nextping` program and its install
scripts. The source code is not published.

## Install

One command sets up everything: the background service, your phone, and every coding agent it finds.

```sh
npx nextping init
```

It asks before changing each agent (`--yes` sets them all up) and is safe to run again. Claude Code
gets the plugin; Codex and Cursor get the MCP server (and Codex the hooks) in their config files;
GitHub Copilot CLI, Gemini CLI and Grok CLI get the `nextping` MCP server through their own
`mcp add`. Agents run the copy kept in NextPing's own folder, never the one `npx` downloaded.

No Node? Use the install script instead; it checks the download against the checksum in the release:

```sh
curl -fsSL https://nextping.dev/install | sh          # macOS, Linux
irm https://nextping.dev/install.ps1 | iex            # Windows PowerShell
```

### Claude Code: the plugin

```
/plugin marketplace add nextping/nextping
/plugin install nextping@nextping
```

Start a new session. The plugin downloads the `nextping` program for your computer, checks
its SHA-256 against the value pinned in the plugin, starts a small background service and opens a
pairing page. In the app: sign in (Apple or Google on iPhone, Google on Android), tap **Add
computer**, scan the code. A test notification confirms it.

Claude then has these tools: `start`, `notify`, `ask`, `report`, `set_status`,
`set_session_title`, `check_inbox`, `watch_start`, `watch_stop`, `watch_list`, `guide` and `pair_phone`. NextPing stays off in a
session until you ask Claude for it ("tell me when it's done", "I'm stepping away"); from then on
the session is on your phone, which asks how much of it you want (every update, or only important
ones), and the plugin's hooks send its permission prompts to your phone and your nudges to Claude
after each tool call. Nothing else to set up (macOS, Linux and Windows with Git for Windows).

### Codex, Cursor and other agents, by hand

1. Download the program for your computer from the
   [latest release](https://github.com/nextping/nextping/releases/latest)
   (`nextping-darwin-arm64`, `-darwin-x64`, `-linux-x64`, `-linux-arm64` or
   `-windows-x64.exe`), check it against `SHA256SUMS`, make it executable and put it on your
   `PATH` as `nextping` (`nextping.exe` on Windows).
2. `nextping service install` — runs the background service at login.
3. `nextping pair --open` — shows the pairing code; scan it in the app.
4. `nextping setup codex` adds the `nextping` MCP server to `~/.codex/config.toml` (or
   `$CODEX_HOME/config.toml`) and NextPing's hooks to `hooks.json` next to it; Codex runs the hooks
   only after you trust them, so open Codex and approve them in `/hooks`.
   `nextping setup cursor` adds the MCP server to `~/.cursor/mcp.json` (Cursor has no hooks:
   phone messages reach it when it calls `check_inbox`). `nextping setup copilot|gemini|grok` runs
   that agent's own `mcp add`, and `nextping setup claude` installs the plugin. Add `--dry-run` to
   see the change first; each changed file's original is kept as `<file>.before-nextping`. For any
   other MCP client, run `nextping mcp` as a stdio server.

### Scripts and the command line

```sh
nextping notify --severity critical Production deploy failed
answer=$(nextping ask "Roll out to production?" --option yes --option no --default no --timeout 30m)
nextping report --title "Nightly import" --file report.html
nextping watch start --name "prod errors" --every 1m --shell "curl -fsS https://example.com/health" --regex "DOWN" --until 1h
```

`nextping help` lists every command; each takes `--help`.

## Privacy in one paragraph

Each phone and each computer has its own keys, made on the device. A computer encrypts every
message for each phone it was paired with by QR code; the relay in between stores messages only
as ciphertext plus routing data (ids, recipients, time, size, priority), deletes them once your
phones have them (7 days at most), and keeps
each device's name, public keys and push token and a hash of your sign-in id. The [privacy policy](https://nextping.dev/privacy/) has the full list.

## Remove

- A computer: `nextping reset --yes` (removes it from your account and deletes its keys), then
  `nextping service uninstall`. Then undo what `init`, `setup` and the install scripts added:
  - Claude Code: `claude plugin uninstall nextping@nextping` (or `/plugin uninstall nextping@nextping`).
  - Codex: delete the `[mcp_servers.nextping]` and `[mcp_servers.nextping.env]` tables from
    `~/.codex/config.toml` and NextPing's entries from `hooks.json` next to it. Cursor: delete
    `nextping` from `mcpServers` in `~/.cursor/mcp.json`. Each file's original from before the
    first change is next to it as `<file>.before-nextping`; delete that too once you are done.
  - GitHub Copilot CLI: `copilot mcp remove nextping`; Gemini CLI: `gemini mcp remove -s user nextping`;
    Grok CLI: `grok mcp remove nextping`.
  - The install script: delete `~/.local/bin/nextping` and the line ending in
    `# added by the NextPing installer` in the shell profile the installer named when it ran
    (`~/.zshrc` or `$ZDOTDIR/.zshrc`, `~/.bashrc`, `~/.bash_profile`, `~/.bash_login` or
    `~/.profile`; for fish, the file `~/.config/fish/conf.d/nextping.fish`).
    On Windows, delete `%LOCALAPPDATA%\Programs\NextPing` and remove that folder from your user
    `Path` (Settings → System → About → Advanced system settings → Environment Variables).
  - A global npm install: `npm rm -g nextping`.
  - Last, NextPing's own folder, which holds the copy agents run: `~/Library/Application
    Support/NextPing` (macOS), `~/.local/state/nextping` (Linux) or `%LOCALAPPDATA%\NextPing`
    (Windows).
- A phone: Settings → Sign out, or Reset this phone.
- Your account: Settings → Account → Delete account… on each phone removes it and the computers it
  is paired with, then resets it. [Deleting your account](https://nextping.dev/delete-account/) has
  the details and the email route (Settings → Account → Account id shows the id it needs).

## Licence

All rights reserved; the program and the plugin are free to use under the
[terms](https://nextping.dev/terms/). See [LICENSE](LICENSE).
