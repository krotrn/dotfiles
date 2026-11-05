pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// development state for the home widgets: recent git projects, docker containers, listening dev ports (every 30 s), and slower ones —
// the commit heatmap, your open GitHub pull requests (every 5 min) and the toolchain versions (once).
// Read-only (git, docker ps, ss, gh search). Polled only while a dev widget is on the home screen (active, set by Home).
// A value is replaced only when it really changed, so the widgets' entrance animations do not replay on every poll.
Singleton {
    id: root

    property bool active: false
    property var projects: []   // [{ name, path, branch, dirty, ts, subject }] — the most recently committed first
    property bool dockerUp: false
    property var containers: [] // [{ name, status }]
    property var ports: []      // [{ port, proc }] — listening on this machine, started by you, port 1024 and up
    property var heat: []       // 17 weeks × 7 days, column by column (Mon first): commits per day, -1 for days that have not come yet
    property int weekCommits: 0
    property var prs: []        // your open pull requests: [{ repo, title, number, url }]
    property int reviews: 0     // open pull requests waiting for your review
    property var tools: []      // [{ name, version }]
    property var hidden: []     // what is in ~/.config/glyph/dev-ignore: folder names or paths

    // where the projects live: every git repo directly inside these folders (and directly inside the home folder)
    readonly property var roots: ["coding", "Projects", "RustroverProjects", "go/src"]
    readonly property string repos: `for r in ${roots.map(r => `"$HOME/${r}"`).join(" ")} "$HOME"; do for d in "$r"/*/; do d=\${d%/}; [ -e "$d/.git" ] || continue; ig="$HOME/.config/glyph/dev-ignore"; if [ -f "$ig" ] && { grep -qxF "\${d##*/}" "$ig" || grep -qxF "$d" "$ig"; }; then continue; fi;`
    // listeners that are apps, not dev servers
    readonly property var notDev: /clash|mihomo|^code$|chrom|firefox|zen|spotify|telegram|slack|discord|kdeconnect/i

    property string _pk: ""
    property string _ck: ""
    property string _lk: ""
    property string _hk: ""

    function refresh() { if (!scan.running) scan.running = true; }
    // hide a project: its folder name goes into ~/.config/glyph/dev-ignore (the list is read by the scan; delete the line to show it again)
    function ignore(name) {
        projects = projects.filter(p => p.name !== name);
        hidden = hidden.concat([name]);
        ignoreP.command = ["sh", "-c", 'mkdir -p "$HOME/.config/glyph" && printf "%s\\n" "$1" >> "$HOME/.config/glyph/dev-ignore"', "sh", name];
        ignoreP.running = true;
    }
    // show a hidden project again: its line is removed from the file (the comment lines stay)
    function unignore(name) {
        hidden = hidden.filter(h => h !== name);
        ignoreP.command = ["sh", "-c", 'f="$HOME/.config/glyph/dev-ignore"; grep -vxF -- "$1" "$f" > "$f.tmp"; mv "$f.tmp" "$f"', "sh", name];
        ignoreP.running = true;
    }
    function refreshSlow() {
        if (!heatP.running) heatP.running = true;
        if (!prP.running) prP.running = true;
        if (!tools.length && !toolP.running) toolP.running = true;
    }
    function ago(ts) {
        const m = Math.floor((Date.now() / 1000 - ts) / 60);
        return m < 1 ? "now" : m < 60 ? `${m}m` : m < 1440 ? `${Math.floor(m / 60)}h` : m < 43200 ? `${Math.floor(m / 1440)}d` : `${Math.floor(m / 43200)}mo`;
    }
    function same(a, key) { const k = JSON.stringify(a); if (k === root[key]) return true; root[key] = k; return false; }

    function parse(text) {
        const P = [], C = [], L = {}, X = [];
        let up = false;
        for (const l of text.split("\n")) {
            const f = l.split("|");
            if (f[0] === "P") P.push({ name: f[1], path: f[2], branch: f[3] || "detached", dirty: parseInt(f[4]) || 0, ts: parseInt(f[5]) || 0, subject: f.slice(6).join("|") });
            else if (f[0] === "C") C.push({ name: f[1], status: f.slice(2).join("|") });
            else if (f[0] === "D") up = f[1] === "1";
            else if (f[0] === "X") X.push(f.slice(1).join("|"));
            else if (f[0] === "L") { const p = parseInt(f[1]); if (p >= 1024 && !L[p] && !notDev.test(f[2])) L[p] = f[2]; }
        }
        P.sort((a, b) => b.ts - a.ts);
        const ports2 = Object.keys(L).map(Number).sort((a, b) => a - b).map(p => ({ port: p, proc: L[p] }));
        if (!same(P, "_pk")) projects = P;
        if (!same(X, "_hk")) hidden = X;
        if (!same({ up, C, ports2 }, "_ck")) { dockerUp = up; containers = C; ports = ports2; }
    }

    // commits per local day from the "H|YYYY-MM-DD" lines → a 17 × 7 grid ending with this week
    function parseHeat(text) {
        const cnt = {};
        for (const l of text.split("\n")) if (l.startsWith("H|")) cnt[l.slice(2)] = (cnt[l.slice(2)] ?? 0) + 1;
        const pad = n => String(n).padStart(2, "0");
        const today = new Date();
        today.setHours(12, 0, 0, 0);
        const idx = (today.getDay() + 6) % 7; // Monday = 0
        const out = [];
        let week = 0;
        for (let c = 0; c < 17; c++) {
            for (let r = 0; r < 7; r++) {
                const d = new Date(today.getTime() - ((16 - c) * 7 + (idx - r)) * 86400000);
                const key = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
                const n = d > today ? -1 : (cnt[key] ?? 0);
                out.push(n);
                if (c === 16 && n > 0) week += n;
            }
        }
        if (!same(out, "_lk")) { heat = out; weekCommits = week; }
    }
    function parsePrs(text) {
        const parts = text.split("@@");
        try {
            const mine = JSON.parse(parts[0].trim() || "[]").map(p => ({ repo: p.repository?.nameWithOwner ?? "", title: p.title, number: p.number, url: p.url }));
            prs = mine;
        } catch (e) {}
        try { reviews = JSON.parse((parts[1] ?? "").trim() || "[]").length; } catch (e) {}
    }
    function parseTools(text) {
        tools = text.split("\n").filter(l => l.startsWith("T|")).map(l => l.split("|")).map(f => ({ name: f[1], version: f[2] })).filter(t => t.version);
    }

    Timer { interval: 30000; running: root.active; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { interval: 300000; running: root.active; repeat: true; triggeredOnStart: true; onTriggered: root.refreshSlow() }

    Process {
        id: scan
        command: ["sh", "-c", `
            ${repos}
                b=$(git -C "$d" branch --show-current 2>/dev/null)
                n=$(git -C "$d" status --porcelain 2>/dev/null | head -99 | wc -l)
                t=$(git -C "$d" log -1 --format=%ct 2>/dev/null)
                s=$(git -C "$d" log -1 --format=%s 2>/dev/null | cut -c1-70 | tr '|' '/')
                printf 'P|%s|%s|%s|%s|%s|%s\\n' "\${d##*/}" "$d" "$b" "$n" "\${t:-0}" "$s"
              done
            done
            ig="$HOME/.config/glyph/dev-ignore"
            [ -f "$ig" ] && grep -v -e '^#' -e '^$' "$ig" | sed 's/^/X|/'
            if timeout 3 docker info >/dev/null 2>&1; then
              echo "D|1"
              docker ps --format 'C|{{.Names}}|{{.Status}}' 2>/dev/null
            else
              echo "D|0"
            fi
            ss -ltnpH 2>/dev/null | awk '{ n = split($4, a, ":"); if (match($0, /users:\\(\\("[^"]+"/)) print "L|" a[n] "|" substr($0, RSTART + 9, RLENGTH - 10) }'
        `]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Process {
        id: ignoreP
        onExited: { root._pk = ""; root.refresh(); root.refreshSlow(); }
    }
    Process {
        id: heatP
        command: ["sh", "-c", `
            me=$(git config --global user.email)
            ${repos}
                git -C "$d" log --since=120.days --author="$me" --format='H|%cs' 2>/dev/null
              done
            done
        `]
        stdout: StdioCollector { onStreamFinished: root.parseHeat(text) }
    }
    Process {
        id: prP
        command: ["sh", "-c", `
            gh search prs --author @me --state open --json repository,title,number,url --limit 8 2>/dev/null
            echo "@@"
            gh search prs --review-requested @me --state open --json number --limit 30 2>/dev/null
        `]
        stdout: StdioCollector { onStreamFinished: root.parsePrs(text) }
    }
    Process {
        id: toolP
        command: ["sh", "-c", `
            export PATH="$HOME/.nvm/versions/node/$(ls "$HOME/.nvm/versions/node" 2>/dev/null | tail -1)/bin:$HOME/.local/share/pnpm/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$PATH"
            echo "T|node|$(node -v 2>/dev/null | tr -d v)"
            echo "T|pnpm|$(pnpm -v 2>/dev/null)"
            echo "T|bun|$(bun -v 2>/dev/null)"
            echo "T|rust|$(rustc --version 2>/dev/null | cut -d' ' -f2)"
            echo "T|go|$(go version 2>/dev/null | sed -E 's/.*go([0-9.]+).*/\\1/')"
        `]
        stdout: StdioCollector { onStreamFinished: root.parseTools(text) }
    }
}
