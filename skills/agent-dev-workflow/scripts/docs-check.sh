#!/usr/bin/env bash
# Keeps an Obsidian vault honest. Exit 1 with a list on any failure. Needs bash + python3 (+ git for drift).
#   docs-check.sh [docs_dir]            default docs; working tree vs HEAD
#   docs-check.sh [docs_dir] --staged   drift against what is staged (the commit hook)
#   docs-check.sh [docs_dir] --vault    structure only, no drift
# Vault: every note has `summary:` and `updated: YYYY-MM-DD` front matter; every [[wikilink]]
# resolves (alias, #heading, attachments ok); every note is linked from <docs_dir>/index.md.
# Drift (opt-in): if the map exists (DOCS_MAP, default <docs_dir>/docs-map.txt; lines
# `code/path/prefix  note,other/note`, notes relative to docs_dir, no .md, longest prefix wins),
# a changed code path must come with a change to one of its notes.
# DOCS_CHECK_SKIP_DRIFT=1 skips drift, visibly, for a change that alters nothing a note says.
set -uo pipefail
DIR="docs"; MODE="tree"
for a in "$@"; do case "$a" in --staged) MODE=staged;; --vault) MODE=vault;; *) DIR="$a";; esac; done
[ -d "$DIR" ] || { echo "docs-check: no such dir: $DIR" >&2; exit 1; }
python3 - "$DIR" "$MODE" "${DOCS_MAP:-$DIR/docs-map.txt}" <<'PY'
import os, re, subprocess, sys
d, mode, mapf = sys.argv[1].rstrip("/"), sys.argv[2], sys.argv[3]
fail, notes, files = [], {}, set()
for root, dirs, fs in os.walk(d):
    dirs[:] = [x for x in dirs if not x.startswith((".", "_"))]  # _templates etc. are not notes
    for f in fs:
        rel = os.path.relpath(os.path.join(root, f), d)
        files.add(rel)
        if f.endswith(".md"): notes[rel[:-3]] = os.path.join(root, f)
bases = {}
for p in files: bases.setdefault(os.path.basename(p), []).append(p)

def resolve(t):
    """Obsidian-style: full path or bare name; notes without .md, other files with extension."""
    t = t.strip().strip("/")
    if t in notes or t in files: return t
    for k in notes:
        if os.path.basename(k) == t: return k
    return bases[t][0] if t in bases else None

index = notes.get("index"); listed = set()
if not index: fail.append(f"{d}/index.md is missing")
for n, p in sorted(notes.items()):
    text = open(p, encoding="utf-8", errors="replace").read()
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    fm = m.group(1) if m else ""
    if not re.search(r"^summary:\s*\S", fm, re.M): fail.append(f"{p}: no `summary:` front matter")
    if not re.search(r"^updated:\s*\d{4}-\d{2}-\d{2}\s*$", fm, re.M): fail.append(f"{p}: no `updated: YYYY-MM-DD` front matter")
    body = re.sub(r"```.*?```|~~~.*?~~~|`[^`\n]*`", "", text, flags=re.S)
    for t in re.findall(r"\[\[([^\]\n]*)\]\]", body):
        t = re.split(r"[|#]", t)[0].strip()
        if not t or "{{" in t or "<%" in t: continue
        r = resolve(t)
        if r is None: fail.append(f"{p}: wikilink [[{t}]] resolves to nothing")
        elif n == "index": listed.add(r)
if index:
    for n in sorted(notes):
        if n != "index" and n not in listed: fail.append(f"{d}/index.md does not link [[{n}]]")

def git(*a): return subprocess.run(["git", *a], capture_output=True, text=True).stdout.split("\n")
if mode != "vault" and os.environ.get("DOCS_CHECK_SKIP_DRIFT") != "1" and os.path.exists(mapf):
    if mode == "staged": changed = git("diff", "--cached", "--name-only", "--diff-filter=ACMRD")
    else: changed = git("diff", "HEAD", "--name-only", "--diff-filter=ACMRD") + git("ls-files", "--others", "--exclude-standard")
    changed = {c for c in changed if c}
    top = git("rev-parse", "--show-toplevel")[0]
    pre = os.path.relpath(os.path.abspath(d), top).rstrip("/") + "/" if top else d + "/"
    cn = {c[len(pre):-3] for c in changed if c.startswith(pre) and c.endswith(".md")}
    mp = []
    for line in open(mapf):
        line = line.strip()
        if line and not line.startswith("#"):
            a = line.split()
            if len(a) == 2: mp.append((a[0], a[1].split(",")))
    miss = {}
    for c in sorted(changed):
        if c.startswith(pre) or c == os.path.relpath(mapf, top): continue
        best = max((m for m in mp if c.startswith(m[0])), key=lambda m: len(m[0]), default=None)
        if best and not any(n in cn for n in best[1]):
            miss.setdefault(",".join(best[1]), []).append(c)
    for ns, fs in miss.items(): fail.append(f"{', '.join(fs)} changed, but none of its notes did: {ns}")
    if miss: fail.append("update the note (and its `updated:`), or set DOCS_CHECK_SKIP_DRIFT=1 if nothing a note says changed")

if fail:
    print("docs-check: FAIL", file=sys.stderr)
    for f in fail: print("  - " + f, file=sys.stderr)
    sys.exit(1)
print(f"docs-check: ok ({len(notes)} notes)")
PY
