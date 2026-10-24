---
name: keep-awake
description: Keep the laptop (Linux, Cinnamon desktop; adapt the settings keys to your desktop) from suspending while long work runs — builds, image push, deploys, full test suites, background tasks, a Maestri team working on a demand, or the user stepping away mid-task. Use before starting any work expected to take more than a few minutes or to run unattended, and release it when the work ends. Also use when a log stalls or the clock jumps (check for a suspend before blaming the network).
---

# Keep the machine awake during long work

> Machine-specific paths, habits and notes: read `local.md` next to this file if it exists.
> It is yours and never versioned; this file stays generic.

Suspend here comes from Cinnamon's idle timer (`sleep-inactive-*-type 'suspend'` after 600 s).
It is requested by the user's own uid, and logind ignores inhibitors from that uid, so
**`systemd-inhibit` alone does not hold it** — it failed once in the middle of a release build.
The script below sets the idle and lid-on-battery actions to `'nothing'` while any lease is
live, keeps a `systemd-inhibit` for other requests, and restores the saved values when the
last lease ends. `critical-battery-action` (hibernate) is never touched.

```bash
K=<skills-dir>/keep-awake/keep-awake.sh
$K on  <holder> [hours]   # take or renew a lease; default 4 h
$K off <holder>           # release; the last release restores the settings
$K status                 # current values, live leases, watchdog
$K recover                # after a reboot: restore the settings or re-arm the watchdog
```

A reboot during a lease kills the watchdog and leaves suspend off. Run `recover` at login
so the machine gets its settings back, e.g. `~/.config/autostart/keep-awake-recover.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=keep-awake recover
Exec=<skills-dir>/keep-awake/keep-awake.sh recover
X-GNOME-Autostart-enabled=true
```

## How to use it

- **Holder** = who needs the machine: the session id or the demand's name
  (`deploy-v2.8.0`, `demand-filters`). Several sessions and Maestri recruits run at once;
  each takes its own lease, and the settings only come back when the last one releases.
- **Hours** = an honest estimate with slack (fractions work: `0.5`). The lease is the safety net: if a session dies
  without `off`, a watchdog restores the settings when the lease expires. Long work → renew
  with `on` again at each stage instead of asking for 12 h up front.
- **Always `off` when the work ends**, in the same turn — including when it ends in failure.
- Leave the lease on while a background task runs; release it when the task-completed
  notification arrives.
- A stalled log or a jumped clock: `journalctl --since "-2h" | grep -iE "suspend|resume"`
  before blaming the network.

Never edit the power keys by hand while a lease is live — the script saved the originals
and will write them back over any manual change.
