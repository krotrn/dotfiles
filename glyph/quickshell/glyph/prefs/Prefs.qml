import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.control
import qs.services
import qs.settings

// glyph settings: Super+I. Not a form, but objects. On the left a column of Doto words, like the power menu — the selected one large, with a red
// dot. On the right the section live: home — a bento mock-up (Theme.homeCols × Theme.homeRows), deck — a screen with the panel at the edge, windows — a desktop with gaps,
// idle — a minutes scale by which the screen goes dark. Numbers are rings of dots (drag around, wheel), toggles are pills,
// where the white slides out. ↑↓ — sections, Tab — through the objects, ←→ — change, esc — close.
// Everything takes effect at once: Theme.state (glyph.json) and Rules.store (rules.json, shared with demonshot) + the needed apply.
// Gaps/border/blur/shadows — via Theme.apply: Rules.windows() would give windows the demonshot look
PanelWindow {
    id: root

    property int sel: 0
    signal wallRequested // wallpaper — its own screen (wall/Walls), opened by shell.qml
    readonly property var sections: ["HOME", "DECK", "BAR", "LOOK", "STYLE", "WINDOWS", "DISPLAY", "POWER", "INPUT", "IDLE", "TOASTS", "SHELL"]
    readonly property string moves: "shift ←→ move · ↵ swap · del drop · drag"
    readonly property string rings: "drag round the rings · scroll"
    readonly property var hints: [moves, moves, moves, "", "hover to preview · ↵ or click sets it", rings, rings, "↵ or click a mode", rings, "drag the marks", "which events show a card at the top", ""]
    readonly property var r: Rules.store

    // glyphs of the home kinds, deck sections and bar tray
    readonly property var icons: ({
        weather: "\u{F0595}", calendar: "\u{F00ED}", cpu: "\u{F061A}", ram: "\u{F035B}", gpu: "\u{F08AE}", disk: "\u{F02CA}",
        battery: "\u{F0079}", buds: "\u{F02CB}", player: "\u{F040A}", system: "\u{F0128}", cat: "\u{F011B}", cava: "\u{F0EA2}",
        projects: "\u{F024B}", git: "\u{F02A2}", docker: "\u{F0868}", ports: "\u{F0200}",
        commits: "\u{F0718}", heat: "\u{F0628}", focus: "\u{F051B}", launch: "\u{F0463}", tools: "\u{F05B7}", prs: "\u{F062C}",
        clock: "\u{F0150}", perf: "\u{F04C5}", net: "\u{F05A9}", media: "\u{F075A}",
        layout: "\u{F030C}", wifi: "\u{F05A9}", bluetooth: "\u{F00AF}", sound: "\u{F057E}", notes: "\u{F009A}",
        mode: "\u{F04C5}", power: "\u{F0425}"
    })
    // round home widgets, the rest are a 40 square. ponytail: ram/gpu/disk/battery — a guess (rings); Home will decide — fix then
    readonly property var rounds: ["weather", "cpu", "ram", "gpu", "disk", "battery", "buds", "cava", "focus"]

    // ---- opening: its own animation (glyph layers in hypr have no_anim). The section is remembered between openings ----
    property bool shown: false
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
    function open() {
        shown = true;
        stage.forceActiveFocus();
    }
    function close() { shown = false; }
    function toggle() { shown ? close() : open(); }
    function go(i) {
        sel = (i + sections.length) % sections.length;
        stage.forceActiveFocus(); // focus in a hidden section would be lost
    }

    // ---- id lists in Theme.state: home widgets, deck sections, bar tray. We edit a copy — JsonAdapter writes the file on assignment.
    // All return a new cursor ----
    function edit(key, f) {
        const a = Theme.state[key].slice();
        f(a);
        Theme.state[key] = a;
    }
    function move(key, i, to) {
        if (to < 0 || to >= Theme.state[key].length || to === i) return i;
        edit(key, a => a.splice(to, 0, a.splice(i, 1)[0]));
        return to;
    }
    function cut(key, i) {
        const n = Theme.state[key].length;
        if (i >= n) return i;
        edit(key, a => a.splice(i, 1));
        return Math.max(0, Math.min(i, n - 2));
    }
    // ↵ on the selected one: the next one from all that is not there yet. In an empty list — the first free one
    function cycle(key, i, all) {
        const a = Theme.state[key];
        if (all.every(k => a.includes(k))) return i;
        i = Math.min(i, a.length);
        let j = all.indexOf(a[i]);
        do j = (j + 1) % all.length; while (a.includes(all[j]));
        edit(key, b => b[i] = all[j]);
        return i;
    }
    // tray: present — remove, absent — insert after the selected one
    function flip(key, w, cur) {
        const a = Theme.state[key], i = a.indexOf(w);
        if (i >= 0) {
            edit(key, b => b.splice(i, 1));
            return Math.max(0, Math.min(i < cur ? cur - 1 : cur, a.length - 2));
        }
        const at = Math.min(cur + 1, a.length);
        edit(key, b => b.splice(at, 0, w));
        return at;
    }
    // list keys in focus: ←→ select, shift ←→ reorder, ↵/space — change the kind, del — remove. -1 — the key is not ours
    function nav(e, key, cur, all) {
        const n = Theme.state[key].length, d = e.key === Qt.Key_Left ? -1 : e.key === Qt.Key_Right ? 1 : 0;
        if (d && (e.modifiers & Qt.ShiftModifier)) return move(key, cur, cur + d);
        if (d) return n ? (cur + d + n) % n : 0;
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) return cycle(key, cur, all);
        if (e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace) return cut(key, cur);
        return -1;
    }
    // bento layout: the same as home (Theme.pack) — homeCols × homeRows per page, a widget takes the first free spot, then the next page
    function pack(ids) { return Theme.pack(ids); }

    SystemClock { id: clock; enabled: root.visible; precision: SystemClock.Minutes }
    readonly property string hello: { const h = clock.date.getHours(); return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"; }
    readonly property string who: (Theme.state.name || Quickshell.env("USER")).replace(/&/g, "&amp;").replace(/</g, "&lt;")

    // name and caption of the current shell — from its rice.json (the same one the Rice app draws)
    property var meta: ({})
    FileView { path: Quickshell.shellPath("rice.json"); onLoaded: try { root.meta = JSON.parse(text()); } catch (e) {} }
    // "switch shell" — only when there is something to choose from: other shells, folders with rice.json alongside (Demon's Shot…)
    property int shells: 1
    Process {
        running: root.visible
        command: [Quickshell.env("HOME") + "/.config/quickshell/rice/rice", "list"]
        stdout: StdioCollector { onStreamFinished: root.shells = text.trim().split("\n").length }
    }

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glyph-prefs"

    Rectangle {
        anchors.fill: parent
        color: Theme.bg // solid: bright pieces of the windows behind showed through at 5%
        opacity: root.t
        MouseArea { anchors.fill: parent; onClicked: stage.forceActiveFocus() } // a click outside — only drops focus; esc closes
    }

    Stage {
        id: stage
        opacity: root.t
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Up || e.key === Qt.Key_K) root.go(root.sel - 1);
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) root.go(root.sel + 1);
            else if (e.key === Qt.Key_Right && stage.activeFocus) stage.nextItemInFocusChain(true)?.forceActiveFocus();
            else if (e.key === Qt.Key_Escape) root.close();
            else return;
            e.accepted = true;
        }

        // sections: the selected one large with a red dot (while the name is typed, red is the caret, the dot turns white)
        Column {
            x: 150 - 30 * (1 - root.t)
            anchors { top: parent.top; topMargin: 60 }
            spacing: 12
            Repeater {
                model: root.sections
                Row {
                    id: word
                    required property string modelData
                    required property int index
                    readonly property bool on: root.sel === index
                    spacing: 26
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: word.on
                        width: 16
                        height: 16
                        radius: 8
                        color: name.activeFocus ? Theme.fg : Theme.accent
                    }
                    Num {
                        text: word.modelData
                        font.pixelSize: word.on ? 64 : 30
                        color: word.on ? Theme.fg : Theme.mute
                        Behavior on font.pixelSize { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                        Behavior on color { ColorAnimation { duration: Theme.t } }
                    }
                    TapHandler { onTapped: root.go(word.index) }
                }
            }
        }

        Row {
            x: 150
            anchors { bottom: parent.bottom; bottomMargin: 70 }
            spacing: 34
            Lb { text: "↑↓ section" }
            Lb { text: "tab · ←→ change" }
            Lb { visible: !!text; text: root.hints[root.sel] }
            Lb { text: "esc close"; TapHandler { onTapped: root.close() } }
        }

        // ---- HOME: home at 168/220 scale — the same kinds, order and layout. Click — select, another click or ↵ — next kind,
        // drag — take the place of the one dropped on. What does not fit on a page — on the next page ----
        Page {
            id: home
            k: 0
            caption: `home · bento ${Theme.homeCols} × ${Theme.homeRows} · page ${shownPage + 1} of ${pages} · ${used} of ${Theme.homeCols * Theme.homeRows} cells`
            readonly property var cells: root.pack(Theme.state.widgets)
            readonly property int pages: Math.max(1, ...cells.map(c => c.page + 1))
            property int pg: 0 // the page being edited; follows the selected widget
            readonly property int shownPage: Math.min(pg, pages - 1)
            readonly property var placed: cells.filter(c => c.page === shownPage)
            readonly property var off: cells.filter(c => !c.fits)
            readonly property int used: placed.reduce((a, c) => a + c.span, 0)
            readonly property var cur_: cells[cur] ?? null
            property int cur: 0
            onCurChanged: { const c = cells[cur]; if (c) pg = c.page; }

            function tap(i) {
                grid.forceActiveFocus();
                cur = cur === i ? root.cycle("widgets", i, Object.keys(Theme.kinds)) : i;
            }
            // dropped at grid point p: on a widget — its place, on an empty cell — after the last one before it; outside the grid — nothing
            function land(i, p) {
                if (p.x < 0 || p.y < 0 || p.x > grid.width || p.y > grid.height) return;
                const cols = Theme.homeCols;
                const at = Math.min(Theme.homeRows - 1, Math.floor(p.y / 136)) * cols + Math.min(cols - 1, Math.floor(p.x / 136));
                const hit = placed.find(c => c.row * cols + c.col <= at && at < c.row * cols + c.col + c.span);
                const n = cells.filter(c => c.page < shownPage).length + placed.filter(c => c.row * cols + c.col < at).length; // earlier pages come first in the list
                cur = root.move("widgets", i, hit ? hit.i : i < n ? n - 1 : n);
            }

            Row {
                spacing: 60

                Item {
                    id: grid
                    width: Theme.homeCols * 136 - 12
                    height: Theme.homeRows * 136 - 12
                    activeFocusOnTab: true
                    Keys.onPressed: e => {
                        const c = root.nav(e, "widgets", home.cur, Object.keys(Theme.kinds));
                        if (c < 0) return;
                        home.cur = c;
                        e.accepted = true;
                    }
                    Repeater {
                        model: Theme.homeCols * Theme.homeRows
                        Dots {
                            required property int index
                            x: index % Theme.homeCols * 136
                            y: Math.floor(index / Theme.homeCols) * 136
                        }
                    }
                    Repeater {
                        model: home.placed
                        Tile {
                            x: modelData.col * 136
                            y: modelData.row * 136
                        }
                    }
                    // pages: a click shows the page and selects its first widget
                    Row {
                        visible: home.pages > 1
                        x: (grid.width - width) / 2
                        y: grid.height + 14
                        spacing: 12
                        Repeater {
                            model: home.pages
                            Rectangle {
                                required property int index
                                width: index === home.shownPage ? 28 : 8
                                height: 8
                                radius: 4
                                color: index === home.shownPage ? Theme.fg : Theme.s3
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    onClicked: { home.pg = parent.index; const f = home.cells.find(c => c.page === parent.index); if (f) home.cur = f.i; }
                                }
                            }
                        }
                    }
                }

                Column {
                    width: 404
                    spacing: 12
                    Lb { text: "cells" }
                    Row {
                        spacing: 10
                        Num { id: usedN; text: home.used; font.pixelSize: 150 }
                        Num { anchors.baseline: usedN.baseline; text: `/${Theme.homeCols * Theme.homeRows}`; font.pixelSize: 54; color: Theme.mute }
                    }
                    Lb {
                        width: parent.width
                        elide: Text.ElideRight
                        text: !home.cur_ ? "empty · ↵ adds one" : `${home.cur_.id} · ${home.cur_.span} cell${home.cur_.span > 1 ? "s" : ""}${home.cur_.fits ? "" : " · off grid"}`
                    }
                    // cat gif (services/Gifs) — while the cat is selected. Click or ←→ in focus
                    Column {
                        id: gifPick
                        visible: home.cur_?.id === "cat"
                        topPadding: 28
                        spacing: 12
                        Lb {
                            width: 404
                            elide: Text.ElideRight
                            text: `gif · ${Gifs.name(Gifs.cur)} · ${Gifs.sel + 1} of ${Gifs.list.length}`
                            color: gifStrip.activeFocus ? Theme.fg : Theme.grey
                        }
                        ListView {
                            id: gifStrip
                            width: 404
                            height: 58
                            orientation: ListView.Horizontal
                            spacing: (width - 6 * 58) / 5 // exactly six per row
                            clip: true
                            snapMode: ListView.SnapToItem
                            boundsBehavior: Flickable.StopAtBounds
                            keyNavigationEnabled: false
                            activeFocusOnTab: true
                            model: Gifs.list
                            currentIndex: Gifs.sel
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                            Keys.onPressed: e => {
                                if (e.key === Qt.Key_Left) Gifs.step(-1);
                                else if (e.key === Qt.Key_Right) Gifs.step(1);
                                else return;
                                e.accepted = true;
                            }
                            delegate: Rectangle {
                                id: th
                                required property string modelData
                                required property int index
                                readonly property bool on: index === Gifs.sel
                                width: 58
                                height: 58
                                radius: Theme.corner(width * 0.18)
                                color: Theme.s1
                                border { width: on ? 2 : 1; color: on ? Theme.fg : Theme.s2 }
                                GifDots { anchors { fill: parent; margins: 6 } path: th.modelData; bg: th.color; playing: gifPick.visible && root.visible }
                                TapHandler {
                                    onTapped: {
                                        Gifs.pick(th.modelData);
                                        gifStrip.forceActiveFocus();
                                    }
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                    Item { width: 1; height: 40 }
                    Lb { text: home.off.length ? `off grid · ${home.off.length}` : "everything fits" }
                    Flow {
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: home.off
                            Tile { cell: 84; gap: 8 }
                        }
                    }
                }
            }

            Tray {
                ids: Object.keys(Theme.kinds)
                icons: root.icons
                used: Theme.state.widgets
                dim: home.off.map(c => c.id)
                widths: Theme.kinds
                onToggled: key => home.cur = root.flip("widgets", key, home.cur)
            }
        }

        // ---- DECK: screen, deck at the bottom center, quick settings on the right; both slide out on hovering their edge.
        // Deck sections in order, as in the panel; tray — which ones exist ----
        Page {
            id: deck
            k: 1
            caption: `deck · ${Theme.state.deck.length} of ${Theme.decks.length} sections · bottom edge`
            property int cur: 0
            // section from is dragged (-1 — nobody): dx — cursor shift in layout px, at — where it is in the strip, to — where it will land
            property int from: -1
            property real dx: 0
            readonly property real at: Math.max(10, Math.min(10 + (Theme.state.deck.length - 1) * 104, 10 + from * 104 + dx))
            readonly property int to: Math.round((at - 10) / 104)

            Row {
                spacing: 40

                Mini {
                    // edges that catch the cursor: bottom — deck, right — quick settings
                    Seg {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                        width: 320
                        height: 4
                        n: 24
                        f: Theme.state.deckHover ? 1 : 0
                    }
                    Seg {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 4
                        height: 240
                        n: 16
                        vertical: true
                        f: Theme.state.quickHover ? 1 : 0
                    }

                    Rectangle {
                        id: strip
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 30 }
                        width: Math.max(1, Theme.state.deck.length) * 104 + 20
                        height: 116
                        radius: Theme.corner(40)
                        color: Theme.s1
                        border { width: 1; color: strip.activeFocus ? Theme.fg : Theme.s2 }
                        Behavior on width { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                        activeFocusOnTab: true
                        Keys.onPressed: e => {
                            const c = root.nav(e, "deck", deck.cur, Theme.decks);
                            if (c < 0) return;
                            deck.cur = c;
                            e.accepted = true;
                        }

                        Lb { visible: !Theme.state.deck.length; anchors.centerIn: parent; text: "empty" }
                        Repeater {
                            model: Theme.state.deck
                            Item {
                                id: ds
                                required property string modelData
                                required property int index
                                readonly property bool on: deck.cur === index
                                readonly property bool hot: on && strip.activeFocus
                                // while dragging: this one follows the cursor, those between it and the drop spot shift a step toward its place
                                readonly property int slot: deck.from < 0 ? index
                                    : index > deck.from && index <= deck.to ? index - 1
                                    : index < deck.from && index >= deck.to ? index + 1 : index
                                x: dd.active ? deck.at : 10 + slot * 104
                                width: 104
                                height: strip.height
                                z: dd.active ? 1 : 0
                                Behavior on x {
                                    enabled: !dd.active
                                    NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 56
                                        height: 56
                                        radius: 28
                                        color: ds.hot ? Theme.fg : Theme.s2
                                        border { width: ds.on && !ds.hot ? 1 : 0; color: Theme.fg }
                                        Icon { anchors.centerIn: parent; text: root.icons[ds.modelData] ?? ""; font.pixelSize: 24; color: ds.hot ? Theme.ink : Theme.fg }
                                    }
                                    Lb { anchors.horizontalCenter: parent.horizontalCenter; text: ds.modelData; px: 10; color: ds.on ? Theme.fg : Theme.grey }
                                }
                                TapHandler {
                                    onTapped: {
                                        strip.forceActiveFocus();
                                        deck.cur = deck.cur === ds.index ? root.cycle("deck", ds.index, Theme.decks) : ds.index;
                                    }
                                }
                                DragHandler {
                                    id: dd
                                    target: null
                                    yAxis.enabled: false
                                    // without target the shift is in scene px, and Stage is scaled
                                    onActiveTranslationChanged: deck.dx = activeTranslation.x / Theme.s
                                    onActiveChanged: {
                                        if (active) {
                                            deck.cur = ds.index;
                                            deck.from = ds.index;
                                            return;
                                        }
                                        // drop — after the signal: changing the list recreates the sections, including this one
                                        const from = deck.from, to = deck.to;
                                        Qt.callLater(() => {
                                            deck.from = -1;
                                            deck.cur = root.move("deck", from, to);
                                        });
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    spacing: 14
                    Toggle { width: 200; text: "deck · hover"; on: Theme.state.deckHover; onFlip: Theme.state.deckHover = !Theme.state.deckHover }
                    Toggle { width: 200; text: "quick · hover"; on: Theme.state.quickHover; onFlip: Theme.state.quickHover = !Theme.state.quickHover }
                    Lb { topPadding: 6; text: "bottom edge · right edge"; px: 10 }
                }
            }

            Tray {
                ids: Theme.decks
                icons: root.icons
                used: Theme.state.deck
                onToggled: key => deck.cur = root.flip("deck", key, deck.cur)
            }
        }

        // ---- BAR: edge — two screens in miniature, click selects. The tray — as in the bar: on the left as a column (captions at the side), on top
        // as a row (captions under the icon), in order; drag — along the bar. Tray — which ones exist ----
        Page {
            id: bar
            k: 2
            caption: `bar · ${Theme.state.bar.length} of ${Theme.bars.length} in the tray · ${onTop ? "top" : "left"} edge`
            readonly property bool onTop: Theme.state.barAt === "top"
            readonly property real step: onTop ? 104 : 68 // slot along the bar
            property int cur: 0
            // from is dragged (-1 — nobody): d — cursor shift along the bar in layout px, at — where it is, to — where it will land
            property int from: -1
            property real d: 0
            readonly property real at: Math.max(10, Math.min(10 + (Theme.state.bar.length - 1) * step, 10 + from * step + d))
            readonly property int to: Math.round((at - 10) / step)

            Grid {
                columns: bar.onTop ? 1 : 2
                columnSpacing: 200
                rowSpacing: 40

                Rectangle {
                    id: col
                    readonly property int n: Math.max(1, Theme.state.bar.length)
                    width: bar.onTop ? n * 104 + 20 : 88
                    height: bar.onTop ? 116 : n * 68 + 20
                    radius: Theme.corner(bar.onTop ? 40 : 44)
                    color: Theme.s1
                    border { width: 1; color: col.activeFocus ? Theme.fg : Theme.s2 }
                    Behavior on width { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                    Behavior on height { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                    activeFocusOnTab: true
                    Keys.onPressed: e => {
                        const c = root.nav(e, "bar", bar.cur, Theme.bars);
                        if (c < 0) return;
                        bar.cur = c;
                        e.accepted = true;
                    }

                    Lb { visible: !Theme.state.bar.length; anchors.centerIn: parent; text: "empty"; px: 10 }
                    Repeater {
                        model: Theme.state.bar
                        Item {
                            id: bs
                            required property string modelData
                            required property int index
                            readonly property bool on: bar.cur === index
                            readonly property bool hot: on && col.activeFocus
                            readonly property int slot: bar.from < 0 ? index
                                : index > bar.from && index <= bar.to ? index - 1
                                : index < bar.from && index >= bar.to ? index + 1 : index
                            // place along the bar: follows the cursor while dragging
                            property real pos: bd.active ? bar.at : 10 + slot * bar.step
                            Behavior on pos {
                                enabled: !bd.active
                                NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide }
                            }
                            x: bar.onTop ? pos : 0
                            y: bar.onTop ? 0 : pos
                            width: bar.onTop ? 104 : col.width
                            height: bar.onTop ? col.height : 68
                            z: bd.active ? 1 : 0

                            Rectangle {
                                id: bdot
                                x: (parent.width - width) / 2
                                y: bar.onTop ? 18 : (parent.height - height) / 2
                                width: 52
                                height: 52
                                radius: 26
                                color: bs.hot ? Theme.fg : Theme.s2
                                border { width: bs.on && !bs.hot ? 1 : 0; color: Theme.fg }
                                Icon { anchors.centerIn: parent; text: root.icons[bs.modelData] ?? ""; font.pixelSize: 22; color: bs.hot ? Theme.ink : Theme.fg }
                            }
                            Lb {
                                x: bar.onTop ? (parent.width - width) / 2 : parent.width + 24
                                y: bar.onTop ? bdot.y + bdot.height + 10 : (parent.height - height) / 2
                                text: bs.modelData
                                px: 10
                                color: bs.on ? Theme.fg : Theme.grey
                            }
                            TapHandler {
                                onTapped: {
                                    col.forceActiveFocus();
                                    bar.cur = bar.cur === bs.index ? root.cycle("bar", bs.index, Theme.bars) : bs.index;
                                }
                            }
                            DragHandler {
                                id: bd
                                target: null
                                xAxis.enabled: bar.onTop
                                yAxis.enabled: !bar.onTop
                                onActiveTranslationChanged: bar.d = (bar.onTop ? activeTranslation.x : activeTranslation.y) / Theme.s
                                onActiveChanged: {
                                    if (active) {
                                        bar.cur = bs.index;
                                        bar.from = bs.index;
                                        return;
                                    }
                                    const from = bar.from, to = bar.to;
                                    Qt.callLater(() => {
                                        bar.from = -1;
                                        bar.cur = root.move("bar", from, to);
                                    });
                                }
                            }
                        }
                    }
                }

                Column {
                    spacing: 14
                    Lb { text: "edge" }
                    // screens with a pill at their own edge; ←→ — the other one
                    Row {
                        id: edges
                        spacing: 20
                        activeFocusOnTab: true
                        Keys.onPressed: e => {
                            if (e.key !== Qt.Key_Left && e.key !== Qt.Key_Right && e.key !== Qt.Key_Space && e.key !== Qt.Key_Return) return;
                            Theme.state.barAt = bar.onTop ? "left" : "top";
                            e.accepted = true;
                        }
                        Repeater {
                            model: ["left", "top"]
                            Column {
                                id: ed
                                required property string modelData
                                readonly property bool on: (modelData === "top") === bar.onTop
                                spacing: 10
                                Rectangle {
                                    width: 200
                                    height: 125
                                    radius: 18
                                    color: Theme.bg
                                    border { width: ed.on && edges.activeFocus ? 2 : 1; color: ed.on ? Theme.fg : Theme.s3 }
                                    Behavior on border.color { ColorAnimation { duration: Theme.t } }
                                    Rectangle {
                                        x: 10
                                        y: 10
                                        width: ed.modelData === "top" ? parent.width - 20 : 16
                                        height: ed.modelData === "top" ? 16 : parent.height - 20
                                        radius: Theme.corner(8)
                                        color: ed.on ? Theme.fg : Theme.s3
                                        Behavior on color { ColorAnimation { duration: Theme.t } }
                                    }
                                    TapHandler { onTapped: Theme.state.barAt = ed.modelData }
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                }
                                Lb { anchors.horizontalCenter: parent.horizontalCenter; text: ed.modelData; px: 10; color: ed.on ? Theme.fg : Theme.grey }
                            }
                        }
                    }
                    Item { width: 1; height: 12 }
                    Toggle { width: 200; text: "window title"; on: Theme.state.barTitle; onFlip: Theme.state.barTitle = !Theme.state.barTitle }
                    Lb { topPadding: 6; text: bar.onTop ? "left of the clock" : "above the clock"; px: 10 }
                }
            }

            Tray {
                ids: Theme.bars
                icons: root.icons
                used: Theme.state.bar
                onToggled: key => bar.cur = root.flip("bar", key, bar.cur)
            }
        }

        // ---- LOOK: the miniature home follows the toggles; name — into the pill ----
        Page {
            id: look
            k: 3
            caption: "look · the home screen, live"
            property bool dim: false // the colon went dark
            Timer { running: look.visible && root.visible && Theme.state.blink; interval: 500; repeat: true; onTriggered: look.dim = !look.dim }

            Row {
                spacing: 40

                Mini {
                    Orb { visible: Theme.state.orb; x: 400; y: 110; scale: 330 / 1100; transformOrigin: Item.TopLeft }
                    Row {
                        x: 60
                        y: 52
                        Num { id: hrs; text: Theme.hh(clock.date); font.pixelSize: 120 }
                        Num { text: ":"; font.pixelSize: 120; opacity: Theme.state.blink && look.dim ? 0.2 : 1 }
                        Num { text: Qt.formatTime(clock.date, "mm"); font.pixelSize: 120 }
                        Lb { visible: !Theme.state.clock24; anchors.baseline: hrs.baseline; leftPadding: 12; text: clock.date.getHours() < 12 ? "am" : "pm" }
                    }
                    Lb { x: 64; y: 172; text: Qt.locale("en_US").toString(clock.date, "dddd · d MMMM"); px: 11 }
                    Text {
                        x: 62
                        y: 232
                        textFormat: Text.StyledText
                        text: `${root.hello},<br><font color="${Theme.grey}">${root.who}.</font>`
                        font { family: Theme.ui; pixelSize: 30; weight: Font.Light }
                        lineHeight: 1.1
                        color: Theme.fg
                    }
                    // Glyph strips: volume on the right, progress at the bottom
                    Seg { visible: Theme.state.edges; x: parent.width - 12; y: 140; width: 4; height: 200; n: 12; f: 0.6; vertical: true }
                    Seg { visible: Theme.state.edges; x: 230; y: parent.height - 10; width: 300; height: 4; n: 24; f: 0.4 }
                }

                Column {
                    spacing: 14
                    Toggle { width: 200; text: "light"; on: Theme.light; onFlip: Theme.setLight(!Theme.light) }
                    Toggle { width: 200; text: "dot grid"; on: Theme.state.grid; onFlip: Theme.state.grid = !Theme.state.grid }
                    Toggle { width: 200; text: "orb"; on: Theme.state.orb; onFlip: Theme.state.orb = !Theme.state.orb }
                    Toggle { width: 200; text: "24 hours"; on: Theme.state.clock24; onFlip: Theme.state.clock24 = !Theme.state.clock24 }
                    Toggle { width: 200; text: "blink"; on: Theme.state.blink; onFlip: Theme.state.blink = !Theme.state.blink }
                    Toggle { width: 200; text: "edges"; on: Theme.state.edges; onFlip: Theme.state.edges = !Theme.state.edges }
                    Act {
                        icon: "\u{F02E9}"
                        text: "wallpaper"
                        onHit: {
                            root.close();
                            root.wallRequested();
                        }
                    }
                }
            }

            // name in the greeting; empty — $USER
            Rectangle {
                width: 760
                height: 72
                radius: Theme.corner(36)
                color: Theme.s2
                border { width: name.activeFocus ? 1 : 0; color: Theme.fg }
                Lb { id: nameL; x: 30; anchors.verticalCenter: parent.verticalCenter; text: "name"; color: name.activeFocus ? Theme.fg : Theme.grey }
                TextInput {
                    id: name
                    anchors { left: nameL.right; leftMargin: 24; right: parent.right; rightMargin: 30; verticalCenter: parent.verticalCenter }
                    text: Theme.state.name
                    maximumLength: 24
                    activeFocusOnTab: true
                    font { family: Theme.ui; pixelSize: 24 }
                    color: Theme.fg
                    selectionColor: Theme.s3
                    clip: true
                    onTextEdited: Theme.state.name = text
                    cursorDelegate: Rectangle {
                        width: 2
                        color: name.activeFocus ? Theme.accent : "transparent"
                        Timer { running: name.activeFocus; interval: 500; repeat: true; onTriggered: parent.opacity = 1 - parent.opacity }
                    }
                    Text { visible: !name.text; text: Quickshell.env("USER"); font: name.font; color: Theme.mute }
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Up || e.key === Qt.Key_Down) root.go(root.sel + (e.key === Qt.Key_Up ? -1 : 1));
                        else if (e.key === Qt.Key_Escape || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) stage.forceActiveFocus();
                        else return;
                        e.accepted = true;
                    }
                }
            }
        }

        // ---- STYLE: where the color comes from and where it goes. On top — a desktop in the palette of the swatch under the cursor or in focus (none —
        // the current one): bar, quick settings, kitty, player, Glyph strip; to the right of it — roles as callouts, as on a
        // drawing: which color where. Under it where the color comes from and the theme; then what the source has: wallpaper as dots (click — picker), its tones
        // and variants (a ring — how much color) or palettes by group. The choice is the same as style in the launcher (Theme.styles).
        // Swatches by index: a new Theme.styles on every choice does not recreate the circles, and focus stays where it was ----
        Page {
            id: tint
            k: 4
            property Item hot: null // swatch under the cursor or in focus
            readonly property var p: hot?.item.pal ?? Theme.pal
            readonly property string src: Theme.state.paint === "scheme" ? (Theme.pal.group === "more" ? "" : Theme.pal.group + " ") + Theme.pal.name
                : Theme.state.paint === "wall" && Theme.tones.length ? `wallpaper · ${Theme.pal.name}` : "nothing"
            caption: `style · ${src} · ${Theme.light ? "light" : "dark"}` + (hot && !hot.item.now ? `   →   ${hot.item.name} · ↵ sets it` : "")
            function block(h) { return Theme.styles.find(b => b.head === h)?.items ?? []; }
            function peek(sw) {
                if (sw.peek) hot = sw;
                else if (hot === sw) hot = null;
            }

            Desk { p: tint.p }

            Row {
                spacing: 24
                Pick {
                    label: "from"
                    opts: ["nothing", "wall", "palette"]
                    cur: ["", "wall", "scheme"].indexOf(Theme.state.paint)
                    onPicked: i => Theme.state.paint = ["", "wall", "scheme"][i]
                }
                Pick { label: "theme"; opts: ["dark", "light"]; cur: Theme.light ? 1 : 0; onPicked: i => Theme.setLight(i === 1) }
            }

            // what the source has. One height for all: Page is centered, and the layout would not jump when the source changes. ponytail: 300 — by
            // eye, palettes in two rows; if it grows — the Item grows with it
            Item {
                width: 1040
                height: Math.max(300, own.height)
                Column {
                    id: own
                    spacing: 28
                    Lb { visible: !Theme.state.paint; text: "black · white dots · one red — nothing to pick"; color: Theme.mute }
                    Row {
                        visible: Theme.state.paint === "wall"
                        spacing: 34
                        // wallpaper as dots; click — picker
                        Rectangle {
                            width: 168
                            height: 105
                            radius: Theme.corner(14)
                            color: "transparent"
                            border { width: Theme.state.wall ? 0 : 1; color: Theme.s3 }
                            Image {
                                anchors.fill: parent
                                source: visible ? Theme.url(Theme.wallSrc(Theme.state.wall)) : "" // not visible — no texture
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(336, 210)
                                asynchronous: true
                                layer.enabled: true
                                layer.effect: Dm { step: 4 }
                            }
                            Lb { visible: !Theme.state.wall; anchors.centerIn: parent; px: 10; text: "no wallpaper" }
                            TapHandler {
                                onTapped: {
                                    root.close();
                                    root.wallRequested();
                                }
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                        Column {
                            spacing: 6
                            Lb { text: Theme.tones.length ? "tones · from the wallpaper" : "no colour in it · click it for another" }
                            Row {
                                Repeater {
                                    model: tint.block("tones").length
                                    Swatch { id: tw; item: tint.block("tones")[index] ?? ({ name: "" }); onPeekChanged: tint.peek(tw) }
                                }
                            }
                        }
                    }
                    Column {
                        visible: Theme.state.paint === "wall" && Theme.tones.length > 0
                        spacing: 6
                        Lb { text: "variant · how much colour, like material you" }
                        Row {
                            Repeater {
                                model: tint.block("variant").length
                                Swatch { id: vw; item: tint.block("variant")[index] ?? ({ name: "" }); onPeekChanged: tint.peek(vw) }
                            }
                        }
                    }
                    // palettes by group — blocks between source and theme
                    Flow {
                        visible: Theme.state.paint === "scheme"
                        width: 1040
                        spacing: 40
                        Repeater {
                            model: Theme.state.paint === "scheme" ? Theme.styles.length - 2 : 0
                            Column {
                                id: sb
                                required property int index
                                readonly property var block: Theme.styles[index + 1] ?? ({ head: "", items: [] })
                                spacing: 6
                                Lb { text: sb.block.head }
                                Row {
                                    Repeater {
                                        model: sb.block.items.length
                                        Swatch { id: pw; item: sb.block.items[index] ?? ({ name: "" }); onPeekChanged: tint.peek(pw) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- WINDOWS: a desktop with two windows driven by the live ring values. Window animation — only if motion ----
        Page {
            k: 5
            caption: `windows · hyprland · gaps ${gIn.v} / ${gOut.v} · border ${bord.v} · rounding ${rnd.v} · panels ${pan.v} %`

            Row {
                spacing: 40

                Mini {
                    id: desk
                    Repeater {
                        model: 2
                        Rectangle {
                            id: wnd
                            required property int index
                            readonly property real o: gOut.v * desk.k
                            readonly property real l: 78 * Theme.s * desk.k + o // bar 64 + gap 14, in logical px
                            readonly property real w: (desk.width - (at === "top" ? o : l) - o - 2 * gIn.v * desk.k) / 2
                            readonly property string at: Theme.state.barAt
                            x: (at !== "top" ? l : o) + (index ? w + 2 * gIn.v * desk.k : 0)
                            y: at === "top" ? l : o
                            width: w
                            height: desk.height - (at === "top" ? l : o) - o
                            radius: rnd.v * desk.k
                            color: Theme.s1
                            border { width: bord.v ? Math.max(1, bord.v * desk.k) : 0; color: index ? Theme.s3 : Theme.fg }
                            Behavior on x { enabled: root.r.motion; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            Behavior on y { enabled: root.r.motion; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            Behavior on width { enabled: root.r.motion; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            Behavior on height { enabled: root.r.motion; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

                            Column {
                                x: 20
                                y: 20
                                spacing: 9
                                Lb { text: wnd.index ? "zen" : "kitty"; px: 10; color: wnd.index ? Theme.mute : Theme.grey }
                                Repeater {
                                    model: [0.7, 0.45, 0.85, 0.3, 0.6, 0.5]
                                    Rectangle {
                                        required property real modelData
                                        width: (wnd.width - 40) * modelData
                                        height: 5
                                        radius: 2.5
                                        color: Theme.s3
                                    }
                                }
                            }
                        }
                    }
                }

                // ponytail: blur and shadows are not visible in the mock-up (flat black) — only the toggles
                Column {
                    spacing: 14
                    Toggle { width: 200; text: "blur"; on: root.r.blur; onFlip: { root.r.blur = !root.r.blur; Theme.apply(); } }
                    Toggle { width: 200; text: "shadow"; on: root.r.shadow; onFlip: { root.r.shadow = !root.r.shadow; Theme.apply(); } }
                    Toggle { width: 200; text: "motion"; on: root.r.motion; onFlip: { root.r.motion = !root.r.motion; Rules.motion(); } }
                }
            }

            Row {
                spacing: 40
                Dial { id: gIn; label: "gaps in"; to: 30; value: root.r.gapsIn; onMoved: v => { root.r.gapsIn = v; Theme.apply(); } }
                Dial { id: gOut; label: "gaps out"; to: 60; value: root.r.gapsOut; onMoved: v => { root.r.gapsOut = v; Theme.apply(); } }
                Dial { id: bord; label: "border"; to: 6; n: 24; value: root.r.border; onMoved: v => { root.r.border = v; Theme.apply(); } }
                Dial { id: rnd; label: "rounding"; to: 40; value: Theme.state.rounding; onMoved: v => Theme.state.rounding = v } // shell.qml calls Theme.apply itself
                Dial { id: pan; label: "panels"; to: 100; step: 5; value: Theme.state.corners; onMoved: v => Theme.state.corners = v } // shell corners, %
            }
        }

        // ---- DISPLAY: brightness as a big ring (live, from sysfs), the screen as dots — with scale the dots are larger and sparser ----
        Page {
            k: 6
            caption: `display · ${Rules.mon.name.toLowerCase()} · ${Rules.hz} hz`

            Row {
                spacing: 60
                Column {
                    visible: Sys.hasBri
                    spacing: 22
                    Dial { anchors.horizontalCenter: parent.horizontalCenter; size: 340; n: 60; live: true; label: "brightness"; value: Math.round(Sys.bri * 100); onMoved: v => Sys.setBri(v / 100) }
                    // brightness key step: divisions per scale (Backlight.steps)
                    Pick { anchors.horizontalCenter: parent.horizontalCenter; label: "step"; opts: ["2.5%", "5%", "10%"]; cur: [40, 20, 10].indexOf(Theme.state.briSteps); onPicked: i => Theme.state.briSteps = [40, 20, 10][i] }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 22
                    Rectangle {
                        width: 420
                        height: 262
                        radius: 24
                        color: Theme.bg
                        border { width: 1; color: Theme.s3 }
                        Image {
                            readonly property real p: 5 * Rules.scale
                            anchors { fill: parent; margins: 14 }
                            fillMode: Image.Tile
                            source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="${p}" height="${p}"><circle cx="${p / 2}" cy="${p / 2}" r="${p * 0.2}" fill="#${Theme.hex(Theme.mute)}"/></svg>`)
                        }
                    }
                    Row {
                        spacing: 14
                        Num { id: resW; text: Math.round(Rules.mon.w / Rules.scale); font.pixelSize: 72 }
                        Num { anchors.baseline: resW.baseline; text: "×"; font.pixelSize: 40; color: Theme.mute }
                        Num { anchors.baseline: resW.baseline; text: Math.round(Rules.mon.h / Rules.scale); font.pixelSize: 72 }
                    }
                    Lb { text: "logical pixels" }
                }
            }
            Row {
                spacing: 24
                Pick { label: "scale"; opts: Rules.scales; cur: Rules.scaleIdx; onPicked: i => Rules.setScale(i) }
                Pick { label: "hz"; opts: Rules.rates.map(String); cur: Rules.rates.indexOf(Rules.refreshHz); onPicked: i => { root.r.refresh = Rules.rates[i]; Rules.monitor(); } }
            }
            Row {
                spacing: 40
                Toggle { anchors.verticalCenter: parent.verticalCenter; text: "night light"; on: Sys.night; onFlip: Sys.toggleNight() }
                Dial { label: "warmth · k"; from: 2500; to: 6500; step: 100; value: root.r.warmth; onMoved: v => { root.r.warmth = v; if (root.r.night) Rules.night(); } }
            }
        }

        // ---- POWER: power modes (Rules.modes) — four circles, the ring lights by strength, the selected one white.
        // ultra — power saver plus 60 Hz, no animations, blur or shadows on top of the settings ----
        Page {
            k: 7
            caption: `power · ${Rules.modes[Rules.mode].what} · ${Rules.hz} hz`

            Row {
                spacing: 32
                Repeater {
                    model: Rules.modes.slice(0, Rules.modeCount)
                    Rectangle {
                        id: pc
                        required property var modelData
                        required property int index
                        readonly property bool on: Rules.mode === index
                        width: 230
                        height: 230
                        radius: 115
                        color: on ? Theme.fg : Theme.s1
                        border { width: activeFocus ? 2 : 1; color: activeFocus || on ? Theme.fg : Theme.s2 }
                        Behavior on color { ColorAnimation { duration: Theme.t } }
                        activeFocusOnTab: true
                        Keys.onPressed: e => {
                            if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space) return;
                            Rules.setMode(index);
                            e.accepted = true;
                        }
                        Ring { anchors { fill: parent; margins: 14 } n: 40; dot: 6; f: (pc.index + 1) / 4; on: pc.on ? Theme.ink : Theme.fg; off: pc.on ? Theme.mute : Theme.s3 }
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Num { anchors.horizontalCenter: parent.horizontalCenter; text: pc.modelData.short; font.pixelSize: 54; color: pc.on ? Theme.ink : Theme.fg }
                            Lb { anchors.horizontalCenter: parent.horizontalCenter; text: pc.modelData.name; color: pc.on ? Theme.ink : Theme.grey }
                        }
                        TapHandler { onTapped: Rules.setMode(pc.index) }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
            Lb { text: Rules.store.ultra ? `ultra · ${Rules.rates[0]} hz, no motion, no blur, no shadows — your settings come back when you leave` : "cpu profile only · hz, motion and looks stay yours" }
            Lb { visible: !PowerProfiles.hasPerformanceProfile; text: "no performance profile on this machine" }
        }

        // ---- INPUT: hold a key — first dot at once, pause delay, then rate per second; by live rings ----
        Page {
            id: inp
            k: 8
            caption: "input · keyboard · touchpad"
            property int n: 0 // how many are "typed"; 0 — the key is released
            Timer {
                running: inp.visible && root.visible
                repeat: true
                interval: inp.n === 0 ? 700 : inp.n === 1 ? delay.v : 1000 / rate.v
                onTriggered: inp.n = (inp.n + 1) % 41
            }

            Row {
                spacing: 30
                Rectangle {
                    width: 110
                    height: 110
                    radius: 30
                    color: inp.n ? Theme.fg : Theme.s1
                    border { width: 1; color: Theme.s2 }
                    Num { anchors.centerIn: parent; text: "A"; font.pixelSize: 54; color: inp.n ? Theme.ink : Theme.fg }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16
                    Row {
                        spacing: 6
                        Repeater {
                            model: 40
                            Rectangle {
                                required property int index
                                width: 14
                                height: 14
                                radius: 7
                                color: index < inp.n ? Theme.fg : Theme.s2
                            }
                        }
                    }
                    Lb { text: `hold a key · first, ${delay.v} ms, then ${rate.v} a second` }
                }
            }
            Row {
                spacing: 40
                Dial { id: delay; label: "delay · ms"; from: 150; to: 600; step: 10; value: root.r.repeatDelay; onMoved: v => { root.r.repeatDelay = v; Rules.input(); } }
                Dial { id: rate; label: "rate · /s"; from: 10; to: 60; value: root.r.repeatRate; onMoved: v => { root.r.repeatRate = v; Rules.input(); } }
                Dial { label: "scroll · %"; from: 10; to: 100; step: 5; value: root.r.scroll; onMoved: v => { root.r.scroll = v; Rules.input(); } }
                Dial { label: "pointer"; from: -100; to: 100; step: 5; value: root.r.sens; onMoved: v => { root.r.sens = v; Rules.input(); } }
            }
            Row {
                spacing: 20
                Toggle { text: "natural scroll"; on: root.r.natural; onFlip: { root.r.natural = !root.r.natural; Rules.input(); } }
                Toggle { text: "tap to click"; on: root.r.tap; onFlip: { root.r.tap = !root.r.tap; Rules.input(); } }
                Toggle { text: "off while typing"; on: root.r.typingOff; onFlip: { root.r.typingOff = !root.r.typingOff; Rules.input(); } }
                Toggle { text: "flat accel"; on: root.r.flat; onFlip: { root.r.flat = !root.r.flat; Rules.input(); } }
            }
            Pick { label: "layout switch"; opts: Rules.switches.map(s => s[0]); cur: root.r.kbSwitch; onPicked: i => { root.r.kbSwitch = i; Rules.input(); } }
        }

        // ---- IDLE: a minutes scale without input. The dots dim on every event: awake → locked → screen off → asleep.
        // The labels are dragged along, to the right of 60 — never ----
        Page {
            k: 9
            caption: "idle · minutes without input · hypridle"

            Item {
                id: line
                width: 1000
                height: 300
                readonly property var at: [lk.v, dpms.v, zz.v]

                Repeater {
                    model: 61
                    Rectangle {
                        required property int index
                        readonly property int lvl: line.at.filter(m => m && m <= index).length
                        x: index * 15 - 4
                        y: 246
                        width: 8
                        height: 8
                        radius: 4
                        color: [Theme.fg, Theme.grey, Theme.mute, Theme.s3][lvl]
                    }
                }
                // never — an empty ring past the scale
                Rectangle { x: 62 * 15 - 7; y: 243; width: 14; height: 14; radius: 7; color: "transparent"; border { width: 1; color: Theme.mute } }
                Repeater {
                    model: [0, 15, 30, 45, 60]
                    Lb { required property int modelData; x: modelData * 15 - width / 2; y: 272; text: modelData; px: 10 }
                }
                Lb { x: 62 * 15 - width / 2; y: 272; text: "never"; px: 10 }

                Mark { id: lk; row: 0; label: "lock"; value: root.r.lockAfter; onMoved: v => { root.r.lockAfter = v; Rules.idle(); } }
                Mark { id: dpms; row: 1; label: "screen off"; value: root.r.dpmsAfter; onMoved: v => { root.r.dpmsAfter = v; Rules.idle(); } }
                Mark { id: zz; row: 2; label: Rules.hibernateOn ? "sleep · hibernate" : "sleep"; value: root.r.sleepAfter; onMoved: v => { root.r.sleepAfter = v; Rules.idle(); } }
            }
            Row {
                spacing: 26
                Repeater {
                    model: [["awake", Theme.fg], ["locked", Theme.grey], ["dark", Theme.mute], ["asleep", Theme.s3]]
                    Row {
                        required property var modelData
                        spacing: 10
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: parent.modelData[1] }
                        Lb { text: parent.modelData[0]; px: 10 }
                    }
                }
            }
            Row {
                spacing: 24
                Pick { label: "sleep into"; visible: Rules.canHibernate; opts: ["suspend", "hibernate"]; cur: root.r.hibernate ? 1 : 0; onPicked: i => { root.r.hibernate = i === 1; Rules.idle(); } }
                Toggle { text: "caffeine"; on: Sys.caffeine; onFlip: Sys.caffeine = !Sys.caffeine }
            }
        }

        // ---- TOASTS: which events show a card in the island at the top; the same switches as `glyph toast` ----
        Page {
            k: 10
            caption: "toasts · top card"

            Grid {
                columns: 3
                spacing: 20
                Repeater {
                    model: [["charging", "charging"], ["charged", "fully charged"], ["game", "game mode"], ["dnd", "do not disturb"], ["audioOut", "sound out"], ["audioIn", "microphone"],
                            ["caps", "caps lock"], ["num", "num lock"], ["layout", "layout"], ["vpn", "vpn"], ["config", "config loaded"], ["nowPlaying", "now playing"]]
                    Toggle {
                        required property var modelData
                        text: modelData[1]
                        on: Rules.toastOn(modelData[0])
                        onFlip: Actions.setToast(modelData[0], !Rules.toastOn(modelData[0]))
                    }
                }
            }
            Row {
                spacing: 40
                // both go through clampLevels (Actions.setBatteryLevels): warn stays above critical
                Dial { label: "low · %"; from: 2; to: 50; value: Rules.store.batWarn; onMoved: v => Actions.setBatteryLevels(v, Rules.store.batCrit) }
                Dial { label: "critical · %"; from: 1; to: 30; value: Rules.store.batCrit; onMoved: v => Actions.setBatteryLevels(Rules.store.batWarn, v) }
                Toggle { anchors.verticalCenter: parent.verticalCenter; text: "plug in/out cards"; on: Rules.store.batToasts; onFlip: Rules.store.batToasts = !Rules.store.batToasts }
            }
        }

        // ---- SHELL: the rice mark and the name of the live shell; the switcher is the Rice app ----
        Page {
            k: 11
            caption: "shell · quickshell"

            Row {
                spacing: 50
                Item {
                    width: 260
                    height: 260
                    Ring { anchors.fill: parent; n: 16; dot: 14; f: 1 }
                    Rectangle { anchors.centerIn: parent; width: 52; height: 52; radius: 26; color: Theme.fg }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18
                    Lb { text: "running now" }
                    Num { text: root.meta.name ?? "DOTS"; font.pixelSize: 140 }
                    Lb { text: root.meta.tagline ?? "" }
                }
            }
            Row {
                spacing: 20
                Act {
                    visible: root.shells > 1
                    icon: "\u{F04E1}"
                    text: "switch shell"
                    onHit: {
                        root.close();
                        Quickshell.execDetached(["qs", "-c", "rice"]);
                    }
                }
                Act { icon: "\u{F0450}"; text: "reload"; onHit: Quickshell.reload(false) }
                Toggle { text: "do not disturb"; on: Theme.state.dnd; onFlip: Theme.state.dnd = !Theme.state.dnd }
            }
        }
    }

    // section on the right: only the selected one is visible (Tab goes only through visible ones), appears from bottom to top
    component Page: Column {
        required property int k
        property string caption
        x: 800
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: visible ? 0 : 24
        visible: root.sel === k
        opacity: visible ? 1 : 0
        spacing: 28
        Behavior on opacity { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        Lb { text: parent.caption }
    }

    // screen in miniature 16:10: wallpaper (dot grid, if enabled) and bar; k — logical px of the screen in layout px
    component Mini: Rectangle {
        readonly property real k: width / ((Rules.mon.w || 2880) / Rules.scale)
        width: 760
        height: 475
        radius: 24
        color: Theme.bg
        border { width: 1; color: Theme.s3 }
        Image {
            visible: Theme.state.grid
            anchors { fill: parent; margins: 12 }
            fillMode: Image.Tile
            source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><circle cx="8" cy="8" r="1" fill="#${Theme.hex(Theme.s2)}"/></svg>`)
        }
        // bar at its own edge: gap 14 and thickness 64 are layout px, on screen they are Theme.s logical ones
        Rectangle {
            readonly property real u: Theme.s * parent.k
            readonly property bool onTop: Theme.state.barAt === "top"
            x: 14 * u
            y: 14 * u
            width: onTop ? parent.width - 28 * u : 64 * u
            height: onTop ? 64 * u : parent.height - 28 * u
            radius: Theme.corner(Math.min(width, height) / 2)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
        }
    }

    // empty layout cell: 4 × 4 unlit dots
    component Dots: Grid {
        columns: 4
        padding: 22
        spacing: 20
        Repeater {
            model: 16
            Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.s3 }
        }
    }

    // widget in the home layout: circle or a 40 square (scaled), icon in dots, name. Selected — white outline,
    // in focus — fully white. Does not fit — pale outline
    component Tile: Rectangle {
        id: tile
        required property var modelData // { id, i, row, col, span, fits }
        property real cell: 124
        property real gap: 12
        readonly property bool on: home.cur === modelData.i
        readonly property bool hot: on && grid.activeFocus
        readonly property bool round: root.rounds.includes(modelData.id)
        width: modelData.span * cell + (modelData.span - 1) * gap
        height: cell
        radius: round ? cell / 2 : Theme.corner(cell * 0.18)
        color: hot ? Theme.fg : modelData.fits ? Theme.s1 : "transparent"
        border { width: on ? 2 : 1; color: on ? Theme.fg : modelData.fits ? Theme.s2 : Theme.mute }
        z: drag.active ? 1 : 0
        // without target the shift is in scene px, and Stage is scaled
        readonly property real dx: drag.activeTranslation.x / Theme.s
        readonly property real dy: drag.activeTranslation.y / Theme.s
        transform: Translate { x: drag.active ? tile.dx : 0; y: drag.active ? tile.dy : 0 }
        Behavior on color { ColorAnimation { duration: Theme.t } }

        Ring {
            visible: tile.round && tile.cell > 100
            anchors { fill: parent; margins: 10 }
            n: 40
            dot: 4
            f: 0.66
            on: tile.hot ? Theme.ink : Theme.fg
            off: tile.hot ? Theme.fade(Theme.ink, 0.15) : Theme.s3
        }
        Column {
            anchors.centerIn: parent
            spacing: 10
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.icons[tile.modelData.id] ?? "?"
                font.pixelSize: tile.cell * 0.26
                color: tile.hot ? Theme.ink : tile.modelData.fits ? Theme.fg : Theme.grey
                layer.enabled: true
                layer.effect: Dm { step: 3 }
            }
            Lb { visible: tile.cell > 100; anchors.horizontalCenter: parent.horizontalCenter; text: tile.modelData.id; px: 10; color: tile.hot ? Theme.ink : Theme.grey }
        }
        TapHandler { onTapped: home.tap(tile.modelData.i) }
        // drop — after the signal: changing the list recreates the tiles, including this one
        DragHandler {
            id: drag
            target: null
            onActiveChanged: {
                if (active) {
                    home.cur = tile.modelData.i;
                    return;
                }
                const p = grid.mapFromItem(tile.parent, tile.x + tile.width / 2 + tile.dx, tile.y + tile.height / 2 + tile.dy);
                Qt.callLater(home.land, tile.modelData.i, p);
            }
        }
    }

    // idle marker: a stem down to the scale, a Doto number and a name. Drag along the scale, ←→ — by a minute; to the right of 60 — never (0).
    // While dragging — its own v, in rules.json and hypridle — on release or after 400 ms of quiet
    component Mark: Item {
        id: mk
        property int row
        property string label
        property int value
        property int v: value
        signal moved(int v)
        function put(m) {
            m = m > 60.5 ? 0 : Math.max(1, Math.round(m));
            if (m === v) return;
            v = m;
            wait.restart();
        }
        onValueChanged: if (!ma.pressed && !wait.running) v = value
        Timer { id: wait; interval: 400; onTriggered: if (!ma.pressed && mk.v !== mk.value) mk.moved(mk.v) }

        x: (v || 62) * 15
        y: row * 76
        width: 160
        height: 250 - y
        activeFocusOnTab: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Left) put(v ? v - 1 : 60);
            else if (e.key === Qt.Key_Right) put(v ? v + 1 : 61);
            else return;
            e.accepted = true;
        }
        Behavior on x { NumberAnimation { duration: 120 } }

        Rectangle { width: 1; height: parent.height; color: mk.activeFocus || ma.pressed ? Theme.fg : Theme.mute }
        Column {
            x: 12
            Num { text: mk.v || "—"; font.pixelSize: 44 }
            Lb { topPadding: 6; text: mk.label; px: 10; color: mk.activeFocus ? Theme.fg : Theme.grey }
        }
        MouseArea {
            id: ma
            width: parent.width
            height: 76
            preventStealing: true
            cursorShape: Qt.SizeHorCursor
            onPressed: mk.forceActiveFocus()
            onPositionChanged: e => mk.put(mapToItem(line, e.x, 0).x / 15)
            onReleased: {
                wait.stop();
                if (mk.v !== mk.value) mk.moved(mk.v);
            }
        }
    }

    // button: a pill with an icon in a circle. Click, ↵, space
    component Act: Rectangle {
        id: act
        property string icon
        property string text
        signal hit
        width: actL.implicitWidth + 110
        height: 64
        radius: Theme.corner(32)
        color: Theme.s2
        border { width: activeFocus ? 1 : 0; color: Theme.fg }
        activeFocusOnTab: true
        Keys.onPressed: e => {
            if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space) return;
            act.hit();
            e.accepted = true;
        }
        Rectangle {
            x: 6
            y: 6
            width: 52
            height: 52
            radius: 26
            color: Theme.s3
            Icon { anchors.centerIn: parent; text: act.icon; font.pixelSize: 22 }
        }
        Lb { id: actL; x: 76; anchors.verticalCenter: parent.verticalCenter; text: act.text; color: act.activeFocus ? Theme.fg : Theme.grey }
        TapHandler { onTapped: act.hit() }
    }
}
