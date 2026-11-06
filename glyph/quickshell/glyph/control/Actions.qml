pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs
import qs.settings
import "../schemes.js" as Schemes
import "../glyph/toasts.js" as Toasts

// outside control: everything the IPC handlers (control/Control.qml) and the launcher's actions do. Setters return "" on success, otherwise
// the reason — and then touch nothing
Singleton {
    id: root

    signal settingsRequested()
    signal wallRequested()

    readonly property var image: /\.(jpe?g|png|webp)$/i
    readonly property string dir: Theme.state.wallDir || Quickshell.env("HOME") + "/Pictures/Wallpapers"
    // screen-sized copy size, as in the wallpaper picker
    readonly property string res: {
        const s = Quickshell.screens[0];
        return s ? `${Math.round(s.width * s.devicePixelRatio)}x${Math.round(s.height * s.devicePixelRatio)}^` : "2880x1800^";
    }

    // the wallpaper is drawn from a screen-sized copy (Theme.wallSrc): make it if it is missing or older, only then switch.
    // The file is probed by a blocking read, since an IPC call can only answer at once
    property string target: ""
    Component { id: probe; FileView { blockLoading: true } }
    function exists(path: string): bool {
        const f = probe.createObject(null, { path });
        const ok = f.text().length > 0;
        f.destroy();
        return ok;
    }
    function setWall(path: string): string {
        if (!path.startsWith("/")) return "path must be absolute";
        if (!image.test(path)) return "not an image (jpg, png, webp)";
        if (!exists(path)) return "no such file: " + path;
        target = path;
        copy.running = false;
        copy.running = true;
        return "";
    }
    Process {
        id: copy
        command: ["bash", "-c", `mkdir -p "$2"; b=\${1##*/}
[ "$2/$b.jpg" -nt "$1" ] || { magick "$1[0]" -resize "$3" -quality 90 "$2/.$b.jpg" && mv "$2/.$b.jpg" "$2/$b.jpg"; }`,
            "bash", root.target, Theme.wallCache, root.res]
        stderr: StdioCollector { id: copyErr }
        onExited: code => {
            if (code === 0) Theme.state.wall = root.target;
            else console.warn(`glyph: wallpaper ${root.target} not set (${code}) ${copyErr.text.trim()}`);
        }
    }

    // the images of the wallpaper folder, kept by a scan (also on a folder change): a random pick answers from it at once
    property var files: []
    property var found: []
    onDirChanged: Qt.callLater(() => scan.running = true)
    Process {
        id: scan
        running: true
        command: ["bash", "-c", `shopt -s nullglob nocaseglob; printf '%s\\n' "$1"/*.{jpg,jpeg,png,webp}`, "bash", root.dir]
        stdout: SplitParser { onRead: f => { if (f) root.found.push(f); } }
        onStarted: root.found = []
        onExited: root.files = root.found
    }
    function randomWall(): string {
        const f = files;
        scan.running = true;
        if (!f.length) return "no wallpapers in " + dir;
        return setWall(f[Math.floor(Math.random() * f.length)]);
    }

    function setSource(name: string): string {
        const m = { none: "", wall: "wall", scheme: "scheme" };
        if (!(name in m)) return "source: none, wall or scheme";
        Theme.state.paint = m[name];
        return "";
    }
    function setVariant(id: string): string {
        if (!Schemes.VARIANTS.some(v => v.id === id)) return "variant: " + Schemes.VARIANTS.map(v => v.id).join(", ");
        Theme.state.variant = id;
        return "";
    }
    function setScheme(id: string): string {
        const p = Schemes.ALL.find(x => x.id === id);
        if (!p) return "scheme: " + Schemes.ALL.map(x => x.id).join(", ");
        Theme.state.scheme = id;
        Theme.state.light = p.light;
        return "";
    }
    function setTone(i: int): string {
        if (i < 0 || i >= Theme.tones.length) return Theme.tones.length ? `tone: 0 to ${Theme.tones.length - 1}` : "tone: the wallpaper has no tones";
        Theme.state.paintAt = i;
        return "";
    }
    function setLight(mode: string): string {
        if (mode !== "dark" && mode !== "light" && mode !== "toggle") return "light: dark, light or toggle";
        Theme.setLight(mode === "toggle" ? !Theme.light : mode === "light");
        return "";
    }

    function setToast(key: string, on: bool): string {
        if (!Object.keys(Toasts.DEFAULTS).includes(key)) return "toast: " + Object.keys(Toasts.DEFAULTS).join(", ");
        Rules.store.toast = Object.assign({}, Rules.store.toast, { [key]: on });
        return "";
    }
    function toastList(): string { return Object.keys(Toasts.DEFAULTS).map(k => `${k}\t${Rules.toastOn(k) ? "on" : "off"}`).join("\n"); }

    // next entry of a list after the current one (ids), for the launcher's cycling actions
    function next(ids: var, cur: string): string { return ids[(ids.indexOf(cur) + 1) % ids.length]; }

    // run — what the launcher does on a click; danger — the caller confirms first
    readonly property var list: [
        { name: "scheme", hint: "next palette", danger: false, run: () => { setSource("scheme"); setScheme(next(Schemes.ALL.map(p => p.id), Theme.state.scheme)); } },
        { name: "wallpaper", hint: "pick a wallpaper", danger: false, run: () => root.wallRequested() },
        { name: "variant", hint: "next variant", danger: false, run: () => setVariant(next(Schemes.VARIANTS.map(v => v.id), Theme.state.variant)) },
        { name: "random wallpaper", hint: "from the wallpaper folder", danger: false, run: () => randomWall() },
        { name: "light / dark", hint: "switch the theme", danger: false, run: () => setLight("toggle") },
        { name: "lock", hint: "lock the screen", danger: false, run: () => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/rice/rice", "lock"]) },
        { name: "sleep", hint: "suspend", danger: false, run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { name: "reboot", hint: "restart the machine", danger: true, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { name: "shutdown", hint: "power off", danger: true, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
        { name: "logout", hint: "end the session", danger: true, run: () => Hyprland.dispatch("hl.dsp.exit()") },
        { name: "settings", hint: "open settings", danger: false, run: () => root.settingsRequested() }
    ]

    function run(name: string): string {
        const a = list.find(x => x.name === name);
        if (!a) return "actions: " + list.map(x => x.name).join(", ");
        a.run();
        return "";
    }
}
