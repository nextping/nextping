# NextPing report kit

NextPing embeds this CSS in every `report` (unless `use_kit: false`). It follows the phone's light or
dark mode. Write plain semantic HTML and add these classes. A report holds up to about 600 KB of
HTML, this kit (about 3 KB) included; keep it phone-sized and link to large artifacts (logs, full
diffs, coverage pages) instead of embedding them.

| Class | Element | What it is |
|---|---|---|
| `t-sub` | `p` | muted subtitle under the `h1` |
| `t-card` | `div`/`section` | rounded panel |
| `t-badge` + `t-ok` / `t-warn` / `t-bad` / `t-info` | `span` | status pill |
| `t-kv` | `dl` with `dt`/`dd` | key–value grid |
| `t-stats` > `t-stat` (`<b>` value, `<span>` label) | `div` | big-number tiles |
| `t-table` | `table` | scrollable table |
| `t-progress` > `span style="width:60%"` | `div` | progress bar |
| `t-list` > `li.t-done` / `li.t-fail` / `li` | `ul` | checklist |
| `t-diff` > `span.t-add` / `span.t-del` | `pre` | inline diff lines |
| `t-actions` > `button.t-btn` (+ `t-primary` / `t-danger`) | `div` | reply buttons |

Buttons answer through the app's bridge: `onclick="agent.reply({choice: 'merge'})"`. The object
arrives in the agent's inbox as a report reply. Use small JSON values.

## Example

```html
<h1>Checkout VAT fix</h1>
<p class="t-sub">sub-orderflows · bugfix/SUBS-123 · finished 14:05</p>
<div class="t-stats">
  <div class="t-stat"><b>12</b><span>tests added</span></div>
  <div class="t-stat"><b>0</b><span>failures</span></div>
</div>
<section class="t-card">
  <h2>What changed <span class="t-badge t-ok">ready</span></h2>
  <ul class="t-list">
    <li class="t-done">Round VAT per line, not per order</li>
    <li class="t-done">Migration is backward compatible</li>
    <li>Staging deploy waits for your go</li>
  </ul>
</section>
<dl class="t-kv"><dt>Branch</dt><dd>bugfix/SUBS-123</dd><dt>Risk</dt><dd>Low: price display only</dd></dl>
<pre class="t-diff"><span class="t-del">- total = round(sum(lines) * vat)</span><span class="t-add">+ total = sum(round(l * vat) for l in lines)</span></pre>
<div class="t-actions">
  <button class="t-btn t-primary" onclick="agent.reply({choice: 'deploy_staging'})">Deploy to staging</button>
  <button class="t-btn" onclick="agent.reply({choice: 'wait'})">Wait</button>
</div>
```
