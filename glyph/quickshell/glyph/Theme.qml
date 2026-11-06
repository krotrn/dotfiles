pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.settings
import "schemes.js" as Schemes

// glyph: black, white dots, one red. Palette, fonts, motion, state (theme, quiet) and the look of hypr/kitty live here
Singleton {
    id: root

    // state survives a restart and is also read by the lock (a separate process)
    readonly property alias state: st
    // color source (launcher → style, settings → STYLE), like scheme in caelestia: nothing — black, white and red; wall —
    // from a wallpaper tone by variant, like dynamic in caelestia (tonal spot, fruit salad… — schemes.js); scheme — a ready palette, the theme
    // comes with it; custom — one colour typed by hand, through the same variants as a wallpaper tone. A palette is { light, c: greys by the roles below, accent, red, ansi: 16 kitty colors }
    readonly property var pal: make({})
    readonly property bool light: pal.light

    // light theme — same layout, greys inverted; red does not change
    readonly property var glyphDark: ["#000000", "#0E0E0E", "#1A1A1A", "#2A2A2A", "#4A4A4A", "#8C8C8C", "#F2F2F2"]
    readonly property var glyphLight: ["#E9E9E9", "#FFFFFF", "#F1F1F1", "#D9D9D9", "#B8B8B8", "#6E6E6E", "#0B0B0B"]
    readonly property var greys: pal.c
    readonly property color bg: greys[0]   // background, wallpaper
    readonly property color s1: greys[1]   // bar, panels
    readonly property color s2: greys[2]   // tiles, off
    readonly property color s3: greys[3]   // lines, unlit dots
    readonly property color mute: greys[4] // inactive
    readonly property color grey: greys[5] // labels, secondary
    readonly property color fg: greys[6]   // text, on, focus
    readonly property color ink: light ? s1 : bg // text on a white tile
    readonly property color accent: pal.accent // at most one thing on screen, and only something "live"
    readonly property color red: pal.red       // alarm: battery, critical, wrong password
    readonly property color nothingRed: "#D71921"
    readonly property color glow: light ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(1, 1, 1, 0.6)
    readonly property color scrim: fade(bg, light ? 0.8 : 0.74)

    readonly property string dot: "Doto"                   // digits and short words, never smaller than 26px
    readonly property string ui: "Space Grotesk"
    readonly property string mono: "Space Mono"            // all-caps labels
    readonly property string nf: "JetBrainsMono Nerd Font" // icons

    // 1920×1080 layout canvas → screen. ponytail: based on the first screen; for monitors of different sizes, compute from the window's screen
    // uiScale — the ONE global size of everything except the bar: 1 = the original glyph size, 0.8 = a compact size.
    // Change this number and every panel follows (settings, quick settings, launcher, vpn, cheatsheet, calendar, ...).
    readonly property real uiScale: 0.8
    // bs — screen scale only, no uiScale: the bar uses it so it keeps its own size
    readonly property real bs: {
        const sc = Quickshell.screens[0];
        return sc ? Math.min(sc.width / 1920, sc.height / 1080) : 1;
    }
    readonly property real s: bs * uiScale

    // glide: ease-out-quart, no overshoot — like the glide bezier in hypr
    readonly property var glide: [0.25, 1, 0.5, 1, 1, 1]
    readonly property int t: 350

    // wallpapers are drawn from a screen-sized copy (made by the picker, magick): the original can be a 40 MB png and would take seconds to load.
    // ponytail: no copy (cache wiped, path typed by hand) — empty, grid and orb until the picker is opened
    readonly property string wallCache: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/glyph/walls"
    function wallSrc(p) { return p ? `${wallCache}/${p.slice(p.lastIndexOf("/") + 1)}.jpg` : ""; }
    function url(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : ""; }

    // ---- wallpaper tones: up to maxTones to choose from, like android. They are in glyph.json: the lock (a separate process) takes them ready-made and does not flash
    // red ----
    readonly property int maxTones: 8
    readonly property var tones: st.wall ? st.tones : []
    function hueName(c) {
        const h = Qt.color(c).hslHue * 360;
        return ["red", "orange", "yellow", "green", "teal", "blue", "violet", "pink", "red"][[15, 40, 65, 160, 195, 250, 290, 335, 361].findIndex(x => h < x)];
    }
    // the palette as it would be with st overridden by o ({ paint, scheme, at, variant, light }): the shell lives by it (o empty), the STYLE swatches
    // show it. No tones (grey wallpaper, no picture) — nothing
    function make(o) {
        const k = Object.assign({ paint: st.paint, scheme: st.scheme, at: st.paintAt, variant: st.variant, light: st.light }, o);
        if (k.paint === "scheme") return Schemes.ALL.find(p => p.id === k.scheme) ?? Schemes.ALL[0];
        // 16 ANSI glyph: in the light theme 0↔15 and 7↔8, so white is not lost on white
        const base = { light: k.light, c: k.light ? glyphLight : glyphDark, accent: nothingRed, red: nothingRed,
                       ansi: k.light ? [15, 1, 2, 3, 4, 5, 6, 8, 7, 9, 10, 11, 12, 13, 14, 0].map(i => ansi[i]) : ansi };
        const src = k.paint === "custom" ? st.customColor : tones[Math.min(k.at, tones.length - 1)];
        return (k.paint === "wall" || k.paint === "custom") && src ? Schemes.dynamic(src, k.variant, base) : base;
    }
    // theme: a palette's own, or the pair from its group (mocha → latte, dawn → main); no pair (nord, dracula…) — the theme is
    // not changed, otherwise st.light would diverge from the screen and surface when the source changes
    function pair(l) { return st.paint !== "scheme" ? null : pal.light === l ? pal : Schemes.ALL.find(x => x.group === pal.group && x.light === l) ?? null; }
    function setLight(l) {
        const p = pair(l);
        if (st.paint === "scheme" && !p) return;
        if (p) st.scheme = p.id;
        st.light = l;
    }
    // choice for the launcher (style) and settings (STYLE): blocks { head, items: [{ name, pal, fill, dot, now, run }] }; pal — the palette
    // if chosen, fill — the swatch circle, dot — a smaller circle inside it (accent), now — the current one. First where the color comes from, under it —
    // what that source has: wallpaper tones and variants, or palettes by group; the theme at the end
    readonly property var styles: {
        const set = (k, v) => () => st[k] = v, at = Math.min(st.paintAt, tones.length - 1);
        const it = (name, p, now, run, fill) => ({ name, pal: p, fill: fill ?? p.c[1], dot: p.accent, now, run });
        // the circle is the variant's grey mute (shows which color the greys went to), with the accent inside; amount — the share of color, in order
        const variants = () => Schemes.VARIANTS.map((v, i) => {
            const p = make({ variant: v.id });
            return Object.assign(it(v.name, p, st.variant === v.id, set("variant", v.id), p.c[4]), { amount: i / (Schemes.VARIANTS.length - 1) });
        });
        const own = st.paint === "wall" ? [
            { head: "tones", items: tones.map((t, i) => it(hueName(t), make({ at: i }), at === i, set("paintAt", i), t)) },
            { head: "variant", items: tones.length ? variants() : [] }
        ] : st.paint === "custom" ? [
            { head: "variant", items: st.customColor ? variants() : [] }
        ] : st.paint === "scheme" ? Schemes.GROUPS.map(g => ({ head: g, items: Schemes.ALL.filter(p => p.group === g).map(p =>
            Object.assign(it(p.name, p, st.scheme === p.id, () => { st.scheme = p.id; st.light = p.light; }), { extra: g })) })) : [];
        return [{ head: "source", items: [
            it("nothing", make({ paint: "" }), !st.paint || st.paint === "wall" && !tones.length, set("paint", ""), nothingRed),
            it("wallpaper", make({ paint: "wall" }), st.paint === "wall" && !!tones.length, set("paint", "wall"), tones[0]),
            it("palette", make({ paint: "scheme" }), st.paint === "scheme", set("paint", "scheme")),
            it("custom", make({ paint: "custom" }), st.paint === "custom" && !!st.customColor, () => { if (st.customColor) st.paint = "custom"; }, st.customColor || nothingRed)
        ] }].concat(own.filter(b => b.items.length), [
            { head: "theme", items: [["dark", false], ["light", true]].map(([n, l]) => it(n, make({ light: l, scheme: pair(l)?.id ?? st.scheme }),
                light === l, () => setLight(l))) }
        ]);
    }
    // like score in material you, only simpler: the quantizer cuts the picture into 16 equal-area pieces and returns the average color
    // of each. The vivid ones vote (chroma — max − min of the channels — above 0.12; below that large dull fills win, not the color
    // of the picture): the hue with more votes goes first (±15°), and among its own the most vivid. Then up to maxTones − 1 others, no closer than 30°
    // to each other. No vivid ones — no tones, red remains. Called by the quantizer in shell.qml (not here: Theme is also loaded by the lock)
    function pick(cols) {
        const ch = c => c.hsvSaturation * c.hsvValue, d = (a, b) => Math.abs((a.hsvHue - b.hsvHue + 1.5) % 1 - 0.5);
        const all = Array.from(cols), live = all.filter(c => ch(c) > 0.12);
        const score = c => 0.7 * live.filter(o => d(o, c) < 1 / 24).length / all.length + 0.3 * ch(c);
        const out = [];
        for (const c of live.sort((a, b) => score(b) - score(a)))
            if (out.length < maxTones && out.every(o => d(o, c) >= 1 / 12)) out.push(c);
        return out.map(c => c.toString());
    }
    // luminance, relative, as in WCAG
    function lum(c) { c = Qt.lighter(c, 1); const f = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b); }
    // what to write over color c: black or white, whichever has more contrast (luminance threshold 0.18 — per WCAG)
    function on(c) { return lum(c) > 0.18 ? "#000000" : "#FFFFFF"; }

    function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    // corner radius of panels, tiles, pills — by the corners setting (prefs → WINDOWS → panels): 0 straight, 100 as designed
    function corner(px) { return px * st.corners / 100; }
    // clock by the 12/24 setting: "09" or "9"
    function hh(d) { const h = d.getHours(); return st.clock24 ? String(h).padStart(2, "0") : String(h % 12 || 12); }
    function hex(c) { return c.toString().slice(1, 7).toUpperCase(); }

    readonly property string riceState: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/rice"
    // as in Rules: apply() at startup must see glyph.json, not the defaults
    Component.onCompleted: stateFile.waitForJob()

    FileView {
        id: stateFile
        path: root.riceState + "/glyph.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        // write once at the end of the turn: writeAdapter() on every field in a row mixes up neighbors
        onAdapterUpdated: Qt.callLater(stateFile.writeAdapter)
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: st
            property bool light: false
            property string paint: ""     // where the color comes from: empty — nothing, wall — wallpaper, scheme — palette, custom — customColor
            property string scheme: "mocha" // which palette, an id from schemes.js
            property int paintAt: 0       // which of the wallpaper tones
            property var tones: []        // wallpaper tones, written by the quantizer; empty — grey wallpaper or no picture
            property string customColor: "" // "#RRGGBB" typed by hand, the tone of paint custom; empty — none yet
            property string variant: "tonalspot" // how a wallpaper tone becomes a palette, an id from schemes.js (VARIANTS)
            property bool dnd: false  // new ones are not shown, critical ones always are
            property int unread: 0    // for the lock
            // ---- what the settings (prefs) turn ----
            property var widgets: ["weather", "calendar", "cpu", "player", "buds", "system"] // home bento in order, see kinds
            property bool clock24: true
            property bool blink: true      // the clock colon blinks
            property string name: ""       // in the greeting; empty — $USER
            property bool grid: true       // dot grid on the wallpaper
            property bool orb: true        // halftone orb
            // wallpaper (picker wall/Walls, drawn by components/Wall): path to the picture; empty — grid and orb. The picker folder can be changed here
            property string wall: ""
            property string wallDir: ""    // empty — ~/Pictures/Wallpapers
            property int wallLook: 0       // 0 dots, 1 grey photo, 2 color
            property int wallPitch: 10     // dot pitch, px
            property int wallBright: 85    // %, from the background to the picture
            property string gif: ""        // gif of the cat tile (services/Gifs), path; empty — the first in the folder
            property string gifDir: ""     // empty — ~/Pictures/Gifs
            property int rounding: 20      // hypr windows
            property int corners: 100      // corners of the shell panels, % of their own; circles stay circles (Theme.corner)
            property bool edges: true      // Glyph strips along the edges (volume/brightness, flashes, progress)
            property int briSteps: 20      // brightness from the keys: steps per scale, 40/20/10 — step 2.5/5/10 %
            property bool quickHover: false // quick settings on hovering the right edge
            property bool deckHover: true  // deck — a panel at the bottom center, slides out on hovering the edge
            property var deck: ["clock", "weather", "perf", "net", "media"] // its sections in order, see decks
            property var bar: ["layout", "wifi", "bluetooth", "sound", "notes", "battery", "mode", "power"] // bar tray from top to bottom, see bars
            property bool barTitle: true   // window title as a column in the bar
            property string barAt: "left" // left or top; the calendar, battery card, home, island and Glyph flash follow the bar
            // recording (quick/Rec, Sys.recArgs)
            property int recArea: 0        // 0 whole monitor, 1 area (slurp)
            property int recAudio: 0       // 0 no sound, 1 system, 2 microphone, 3 both on one track
            property int recFps: 60
            property int recQuality: 2     // medium, high, very_high, ultra
            property bool recCursor: true
        }
    }

    // bento widgets: id → width in cells (grid 3 columns × 3 rows of 220). If it does not fit — it is not shown
    readonly property var kinds: ({ weather: 1, calendar: 1, cpu: 1, ram: 1, gpu: 1, disk: 1, battery: 1, buds: 1, player: 2, system: 3, cat: 1, cava: 1, projects: 2, git: 1, docker: 1, ports: 1, commits: 2, heat: 2, focus: 1, launch: 2, tools: 1, prs: 1 })
    // the home bento: homeCols × homeRows cells per page (a cell is 220, the gap 20). Each widget goes to the first free spot that is wide enough
    // (so a small one fills a hole left by a wide one); if the page is full — to the next page. Used by home and the settings editor
    readonly property int homeCols: 4
    readonly property int homeRows: 4
    function pack(ids) {
        const pages = [];
        return ids.map((id, i) => {
            const span = Math.min(kinds[id] ?? 1, homeCols);
            for (let pg = 0; ; pg++) {
                if (!pages[pg]) pages[pg] = new Array(homeCols * homeRows).fill(false);
                const occ = pages[pg];
                for (let r = 0; r < homeRows; r++) {
                    for (let c = 0; c + span <= homeCols; c++) {
                        let free = true;
                        for (let k = 0; k < span; k++) if (occ[r * homeCols + c + k]) { free = false; break; }
                        if (!free) continue;
                        for (let k = 0; k < span; k++) occ[r * homeCols + c + k] = true;
                        return { id, i, page: pg, row: r, col: c, span, fits: true };
                    }
                }
            }
        });
    }
    // deck sections
    readonly property var decks: ["clock", "weather", "perf", "net", "media"]
    // bar tray
    readonly property var bars: ["layout", "wifi", "bluetooth", "sound", "notes", "battery", "mode", "power", "cat"]

    // ---- the look of everything outside the shell. Called only by shell.qml: at startup, on theme and color change ----
    // hypr inherits demonshot: monitor, input, idle, night light and motion are set by its own Rules (shell.qml), animations — from the
    // hypr config. From here — gaps/border/blur/shadows from its rules.json, and glyph's own — border colors, shadows, groups, background and
    // rounding 20 (without them demonshot's red glow and groups from hypr/variables.lua would remain).
    // Back to demonshot: `rice switch` runs hyprctl reload, its applyAll will recolor
    function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", lua]); }

    // kitty includes this file after its own colors (include in kitty.conf); demonshot writes its palette to the same place
    FileView { id: kitty; path: Quickshell.env("HOME") + "/.config/demonshot/kitty.conf"; printErrors: false }
    // 16 ANSI from the concept: pastels only for the terminal. The light theme rearranges them (make)
    readonly property var ansi: ["#0E0E0E", "#D71921", "#9BB59A", "#D9C38A", "#8EA3C2", "#B79BC2", "#8FB8B8", "#C9C9C9",
                                 "#4A4A4A", "#F0434B", "#B5CCB4", "#E8D6A8", "#AABBD4", "#CDB6D6", "#ABCDCD", "#F2F2F2"]

    function apply() {
        // game mode (Rules.store.game) — on top of the settings, like ultra: border 1, no gaps or rounding, tearing for
        // windows with immediate (games, hyprland/rules.lua). On exit — own values return, allow_tearing — false, as in general.lua
        const r = Rules.store, g = r.game;
        const c = x => `"rgb(${hex(x)})"`;
        // shadow: in dark — a barely visible white glow, in light — a soft black
        const shadow = light ? "rgba(0000002E)" : `rgba(${hex(fg)}1A)`;
        hypr(`hl.config({ general = { gaps_in = ${g ? 0 : r.gapsIn}, gaps_out = ${g ? 0 : r.gapsOut}, border_size = ${g ? 1 : r.border}, allow_tearing = ${g}, `
           + `col = { active_border = ${c(fg)}, inactive_border = ${c(s3)} } }, `
           + `decoration = { rounding = ${g ? 0 : st.rounding}, blur = { enabled = ${Rules.blurOn} }, shadow = { enabled = ${Rules.shadowOn}, color = "${shadow}" } }, `
           + `group = { col = { border_active = ${c(fg)}, border_inactive = ${c(s3)}, border_locked_active = ${c(fg)}, border_locked_inactive = ${c(mute)} }, `
           + `groupbar = { font_family = "${mono}", text_color = ${c(fg)}, col = { active = ${c(s3)}, inactive = ${c(s1)}, locked_active = ${c(s3)}, locked_inactive = ${c(s1)} } } }, `
           + `misc = { background_color = ${c(bg)} } })`);

        kitty.setText("# glyph: written by Theme.apply(), do not edit by hand\n" + [
            ["font_family", "Space Mono"], ["window_padding_width", "26 30"], ["cursor_trail", "0"],
            ["foreground", fg], ["background", s1], ["cursor", fg], ["cursor_text_color", s1],
            ["selection_foreground", fg], ["selection_background", s3], ["url_color", grey],
            ["active_border_color", fg], ["inactive_border_color", s3],
            ["active_tab_foreground", ink], ["active_tab_background", fg],
            ["inactive_tab_foreground", grey], ["inactive_tab_background", s1], ["tab_bar_background", bg]
        ].concat(pal.ansi.map((c, i) => ["color" + i, c])).map(([k, v]) => `${k} ${typeof v === "string" ? v : v.toString().slice(0, 7).toUpperCase()}`).join("\n") + "\n");
        Quickshell.execDetached(["pkill", "-USR1", "-x", "kitty"]);
    }

    // gtk and qt — only on color change (shell.qml): apply() is also called on every step of the rounding ring. Templates — glyph's own term/
    // (dark glyph palette): its colors in them are replaced with the colors of the same roles in the palette (greys, red, for qt also
    // green/yellow/blue… from ansi), copies — in riceState/glyph, the ~/.config/… links — to the copies. Nothing to change — back to
    // term/, as rice installs it. A real file (not a link) is left alone, like rice. Substitution in two passes via @n@: a palette color
    // may coincide with a glyph color, which gets replaced next. gtk and qt take colors on the next launch: gtk reads its own gtk.css
    // once, poking the theme does not help (checked on gtk 3 and 4).
    // ponytail: the light theme here is dark — the gtk base is dark (adw-gtk3-dark): for wallpapers — the same variant in dark, for palettes —
    // the dark pair (latte → mocha), for nothing — glyph; for light — also change gtk-theme and color-scheme. btop is not recolored — its folder is
    // a link as a whole into the repo, there is nowhere to put a copy; if needed — color_theme with a path to the copy
    function apps() {
        const from = glyphDark.concat(ansi.slice(1, 7));
        const p = pal.light ? pair(false) ?? make({ light: false }) : pal;
        const to = p.c.concat([p.red], p.ansi.slice(2, 7));
        const pairs = from.map((c, i) => [c, "#" + hex(Qt.lighter(to[i], 1))]).filter(([a, b]) => a !== b);
        const sed = pairs.map(([a], i) => ["-e", `s/${a}/@${i}@/gI`]).concat(pairs.map(([, b], i) => ["-e", `s/@${i}@/${b}/g`])).reduce((x, y) => x.concat(y), []);
        Quickshell.execDetached(["bash", "-c", `t=$1 o=$2; shift 2
for f in gtk-3.0/gtk.css gtk-4.0/gtk.css qtengine.colors; do
    l=$HOME/.config/$f
    [ -L "$l" ] || [ ! -e "$l" ] || continue
    if [ $# -gt 0 ]; then mkdir -p "$(dirname "$o/$f")" && sed "$@" "$t/$f" > "$o/$f" && ln -sfn "$o/$f" "$l"; else ln -sfn "$t/$f" "$l"; fi
done`,
            "bash", Quickshell.shellPath("term"), riceState + "/glyph"].concat(sed));
    }
}
