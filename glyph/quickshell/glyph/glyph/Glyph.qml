import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services
import qs.settings
import "battery.js" as Battery

// Glyph: the screen edges as LEDs on the back, instead of OSD and popups in the middle of the screen.
// On top — a flash for a notification (red for critical ones) and an "island" with it, on the right — volume/brightness from the bottom up,
// at the bottom — progress of long tasks (notifications with a value hint) or the focus timer (Focus). They go out after 3 s
Scope {
    id: root

    // ---- right: volume and brightness ----
    property string kind: "vol"
    property real value: 0
    property bool armed: false // we do not show the first values at startup
    Timer { running: true; interval: 1500; onTriggered: { root.armed = true; root.toast("config", "config", "Config loaded", "\u{F0493}"); } }
    function level(k, v) {
        if (!armed || !Theme.state.edges) return;
        kind = k;
        value = v;
        side.shown = true;
        sideT.restart();
    }
    Connections {
        target: Sys.sink?.audio ?? null
        function onVolumeChanged() { root.level("vol", Sys.muted ? 0 : Sys.vol); }
        function onMutedChanged() { root.level("vol", Sys.muted ? 0 : Sys.vol); }
    }
    Connections {
        target: Sys
        function onBriChanged() { root.level("bri", Sys.bri); }
    }
    Timer { id: sideT; interval: 3000; onTriggered: side.shown = false }

    // ---- top: a new notification — a strip flash and a card in the island stack ----
    property var note: null // the last one, for the flash
    // stack: snapshots of the fields (a notification can be closed while the card leaves — the object will be gone), the object itself — in refs for the action
    ListModel { id: stack }
    property var refs: ({})
    property int seq: 0
    readonly property int most: 4
    // a card in the stack: c — { app, summary, body, icon (icon theme), glyph (nerd font), crit }; ref — the notification, for the action
    function push(c, ref) {
        root.note = { urgency: c.crit ? NotificationUrgency.Critical : NotificationUrgency.Normal };
        noteT.restart();
        const key = String(++root.seq);
        if (ref) root.refs[key] = ref;
        stack.insert(0, Object.assign({ key, app: "", summary: "", body: "", icon: "", glyph: "", crit: false, leaving: false }, c));
        // more than most — the oldest of the living ones leaves
        let live = 0;
        for (let i = 0; i < stack.count; i++) if (!stack.get(i).leaving && ++live > root.most) stack.setProperty(i, "leaving", true);
    }
    Connections {
        target: Notes
        function onArrived(n) {
            root.push({ app: n.appName || "app", summary: n.summary ?? "", body: n.body ?? "", icon: n.appIcon ?? "",
                        crit: n.urgency === NotificationUrgency.Critical }, n);
        }
    }

    // ---- power: charging plugged in/unplugged, charged, running low (Rules batWarn — warn, batCrit — in red). As a card into the island,
    // bypassing the notification history. armed — not at startup ----
    readonly property var bat: UPower.displayDevice
    readonly property int pct: Math.round((bat?.percentage ?? 0) * 100)
    property int warned: 100
    function hm(s) { const m = Math.round(s / 60); return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} m` : `${m} m`; }
    // key — the toast switch (toasts.js); empty — always shown
    function power(key, summary, glyph, crit, time) {
        if (key && !Rules.toastOn(key)) return;
        if (root.armed && root.bat?.isLaptopBattery) root.push({ app: "power", summary, body: `${root.pct}%` + (time ? ` · ${time}` : ""), glyph, crit: !!crit });
    }
    // a toast for an event: shown only when its switch is on (Rules.toastOn) and not at startup
    function toast(key, app, summary, glyph, body) {
        if (root.armed && Rules.toastOn(key)) root.push({ app, summary, body: body ?? "", glyph });
    }
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            root.warned = 100;
            if (!Rules.store.batToasts) return;
            if (UPower.onBattery) root.power("charging", "On battery", "\u{F0079}", false, root.bat.timeToEmpty ? `${root.hm(root.bat.timeToEmpty)} left` : "");
            else root.power("charging", "Charging", "\u{F0084}", false, root.bat.timeToFull ? `full in ${root.hm(root.bat.timeToFull)}` : "");
        }
    }
    Connections {
        target: root.bat
        function onStateChanged() { if (root.bat.state === UPowerDeviceState.FullyCharged && !UPower.onBattery) root.power("charged", "Fully charged", "\u{F0079}"); }
        function onPercentageChanged() {
            if (!UPower.onBattery) return;
            const w = Battery.nextWarning(root.pct, root.warned, Rules.store.batWarn, Rules.store.batCrit);
            root.warned = w.warned;
            if (w.level === "crit") root.power("", "Battery critical", "\u{F0083}", true, "plug in now");
            else if (w.level === "warn") root.power("", "Battery low", "\u{F0083}", false, "plug in soon");
        }
    }
    // ---- toasts for events: game mode, do not disturb, sound, keyboard, vpn, music. Each has its own switch ----
    Connections {
        target: Rules.store
        function onGameChanged() { root.toast("game", "game", Rules.store.game ? "Game mode on" : "Game mode off", "\u{F0297}"); }
    }
    Connections {
        target: Theme.state
        function onDndChanged() { root.toast("dnd", "notifications", Theme.state.dnd ? "Do not disturb on" : "Do not disturb off", Theme.state.dnd ? "\u{F009B}" : "\u{F009A}"); }
    }
    // the audio object of the device itself: a switch of the default device is not a mute
    Connections {
        target: Sys.sink?.audio ?? null
        function onMutedChanged() { root.toast("audioOut", "sound", Sys.muted ? "Sound muted" : "Sound on", Sys.muted ? "\u{F0581}" : "\u{F057E}"); }
    }
    Connections {
        target: Sys.mic?.audio ?? null
        function onMutedChanged() {
            if (!root.micSettled) { micSettle.restart(); return; }
            root.toast("audioIn", "microphone", Sys.micOn ? "Microphone on" : "Microphone muted", Sys.micOn ? "\u{F036C}" : "\u{F036D}");
        }
    }
    // The microphone and the vpn are derived from objects that appear some time after the shell starts (pipewire node, the tray item and its
    // menu): what they report while that goes on is the state that was already there, not a change. Each source is settled after its
    // window passes without a change; a change inside the window only prolongs it
    property bool micSettled: false
    property bool vpnSettled: false
    Timer { id: micSettle; running: true; interval: 1500; onTriggered: root.micSettled = true }
    Timer { id: vpnSettle; running: true; interval: 2500; onTriggered: root.vpnSettled = true }
    function deviceName(n) { return n ? (n.description || n.nickname || n.name) : ""; }
    Connections {
        target: Sys
        function onSinkChanged() { if (Sys.sink) root.toast("audioOut", "sound", "Output", "\u{F04C3}", root.deviceName(Sys.sink)); }
        function onMicChanged() {
            const was = root.micSettled;
            root.micSettled = false;
            micSettle.restart();
            if (was && Sys.mic) root.toast("audioIn", "microphone", "Input", "\u{F036C}", root.deviceName(Sys.mic));
        }
        function onVergeChanged() { root.vpnSettled = false; vpnSettle.restart(); }
        function onVpnChanged() {
            if (!root.vpnSettled) { vpnSettle.restart(); return; }
            root.toast("vpn", "vpn", Sys.vpn ? "VPN on" : "VPN off", "\u{F0582}");
        }
        function onLayoutChanged() {
            const first = !root.lastLayout;
            root.lastLayout = Sys.layout;
            if (!first) root.toast("layout", "keyboard", Sys.layout.toUpperCase(), "\u{F030C}", "layout");
        }
    }
    property string lastLayout: Sys.layout // the first answer of hyprctl is not a switch
    Connections {
        target: Media.player
        function onTrackTitleChanged() {
            const p = Media.player;
            if (p?.trackTitle) root.toast("nowPlaying", "music", p.trackTitle, "\u{F075A}", p.trackArtist);
        }
    }

    // caps and num lock: the keyboard LEDs in sysfs, read twice a second only while one of the two toasts is on. "01" — caps off, num on;
    // the first reading after the poll starts is only remembered
    readonly property bool ledsWanted: Rules.toastOn("caps") || Rules.toastOn("num")
    property string leds: ""
    onLedsWantedChanged: if (!ledsWanted) leds = ""
    Timer { running: root.ledsWanted; repeat: true; triggeredOnStart: true; interval: 500; onTriggered: ledProc.running = true }
    Process {
        id: ledProc
        command: ["sh", "-c", 'for t in capslock numlock; do v=0; for f in /sys/class/leds/*::$t/brightness; do [ "$(cat "$f" 2>/dev/null)" = 1 ] && v=1; done; printf %s "$v"; done']
        stdout: StdioCollector {
            onStreamFinished: {
                const was = root.leds, now = text.trim();
                if (!root.ledsWanted || now.length !== 2) return;
                root.leds = now;
                if (!was) return;
                if (was[0] !== now[0]) root.toast("caps", "keyboard", now[0] === "1" ? "Caps lock on" : "Caps lock off", "\u{F030C}");
                if (was[1] !== now[1]) root.toast("num", "keyboard", now[1] === "1" ? "Num lock on" : "Num lock off", "\u{F030C}");
            }
        }
    }

    function dismiss(key) { for (let i = 0; i < stack.count; i++) if (stack.get(i).key === key) return stack.setProperty(i, "leaving", true); }
    function forget(key) {
        delete refs[key];
        for (let i = 0; i < stack.count; i++) if (stack.get(i).key === key) return stack.remove(i);
    }
    Timer { id: noteT; interval: 3000; onTriggered: root.note = null }
    readonly property bool crit: note?.urgency === NotificationUrgency.Critical

    Edge {
        id: top
        shown: !!root.note && Theme.state.edges
        anchors.top: true
        margins.top: Theme.state.barAt === "top" ? Math.ceil(30 * Theme.bs) : 0 // under the bar
        implicitWidth: Math.ceil(640 * Theme.s)
        implicitHeight: Math.ceil(30 * Theme.s)
        Seg {
            x: 20
            y: 4
            width: 600
            height: 4
            n: 12
            f: 1
            on: root.crit ? Theme.red : Theme.fg
            layer.enabled: true
            layer.effect: Glow {}
            SequentialAnimation on opacity {
                running: top.shown
                loops: Animation.Infinite
                NumberAnimation { from: 0.15; to: 1; duration: 720; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1; to: 0.15; duration: 1680; easing.type: Easing.InOutSine }
            }
        }
    }

    // island: a stack of cards at the top center, new ones on top. A white outline (critical — red), an icon in a circle, a red dot.
    // Each is like a dynamic island: drops as a pill, spreads into a card, the text appears last; leaves backwards, and its place
    // collapses — the lower ones move up. Each has its own life of 4 s, hovering the stack keeps all of them.
    // A constant-size window (for most cards), the mouse is caught only by the stack itself
    PanelWindow {
        visible: stack.count > 0
        anchors.top: true
        margins.top: Theme.state.barAt === "top" ? Math.ceil(30 * Theme.bs) : 0 // under the bar
        implicitWidth: Math.ceil(600 * Theme.s)
        implicitHeight: Math.ceil((24 + root.most * 132) * Theme.s)
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region { item: col }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "glyph-island"

        Stage {
            Column {
                id: col
                y: 24
                width: 600
                HoverHandler { id: hov }

                Repeater {
                    model: stack

                    Item {
                        id: c
                        required property int index
                        required property string key
                        required property string app
                        required property string summary
                        required property string body
                        required property string icon
                        required property string glyph
                        required property bool crit
                        required property bool leaving

                        // p 0…1 linear, each phase has its own ease-out-quart (like glide)
                        property real p: 0
                        Component.onCompleted: p = Qt.binding(() => leaving ? 0 : 1)
                        Behavior on p { NumberAnimation { duration: c.leaving ? 450 : 700 } }
                        onPChanged: if (leaving && p <= 0) Qt.callLater(root.forget, key)
                        function ph(a, b) { const x = Math.max(0, Math.min(1, (p - a) / (b - a))); return 1 - Math.pow(1 - x, 4); }
                        readonly property real drop: ph(0, 0.3)   // the pill drops
                        readonly property real grow: ph(0.25, 0.8) // and spreads into a card
                        readonly property real full: Math.max(86, txt.height + 32)

                        width: 600
                        height: (40 + (full - 40) * grow + 12) * drop // the place in the stack grows and collapses together with the card
                        Timer { running: !c.leaving && !hov.hovered; interval: 4000; onTriggered: root.dismiss(c.key) }

                        Rectangle {
                            width: 140 + (600 - 140) * c.grow
                            height: 40 + (c.full - 40) * c.grow
                            x: (600 - width) / 2
                            y: -24 * (1 - c.drop)
                            opacity: c.drop
                            radius: Theme.corner(Math.min(34, height / 2))
                            clip: true
                            color: Theme.s1
                            border { width: 1; color: c.crit ? Theme.red : Theme.fg }

                            // content — at full size in the center: the text width does not change while the card grows
                            Item {
                                anchors.centerIn: parent
                                width: 600
                                height: c.full
                                opacity: c.ph(0.7, 1)

                                Rectangle {
                                    id: ic
                                    x: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 54
                                    height: 54
                                    radius: 27
                                    color: Theme.s2
                                    Icon { anchors.centerIn: parent; visible: !img.visible; text: c.glyph || "\u{F009A}"; font.pixelSize: 24 }
                                    Image {
                                        id: img
                                        anchors.centerIn: parent
                                        width: 28
                                        height: 28
                                        visible: status === Image.Ready
                                        source: c.icon ? Quickshell.iconPath(c.icon, true) : ""
                                        sourceSize: Qt.size(28, 28)
                                        layer.enabled: true
                                        layer.effect: Dm { step: 2 }
                                    }
                                }
                                Column {
                                    id: txt
                                    anchors { left: ic.right; leftMargin: 16; right: dot.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
                                    Lb { width: parent.width; elide: Text.ElideRight; text: `${c.app} · now` }
                                    Text {
                                        width: parent.width
                                        topPadding: 2
                                        elide: Text.ElideRight
                                        text: c.summary
                                        font { family: Theme.ui; pixelSize: 17; weight: Font.DemiBold }
                                        color: Theme.fg
                                    }
                                    Text {
                                        width: parent.width
                                        visible: !!c.body
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                        wrapMode: Text.Wrap
                                        textFormat: Text.PlainText
                                        text: c.body
                                        font { family: Theme.ui; pixelSize: 14 }
                                        color: Theme.grey
                                    }
                                }
                                // a red dot — only on the newest: there is one red thing on the screen
                                Rectangle { id: dot; visible: c.index === 0; anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter } width: 12; height: 12; radius: 6; color: Theme.accent }
                            }

                            // click — the default action; the card leaves, stays in the history. The notification may already be closed —
                            // an empty wrapper without actions remains of the object
                            TapHandler {
                                onTapped: {
                                    root.refs[c.key]?.actions?.find(a => a.identifier === "default")?.invoke();
                                    root.dismiss(c.key);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- right ----
    Edge {
        id: side
        anchors.right: true
        implicitWidth: Math.ceil(160 * Theme.s)
        implicitHeight: Math.ceil(520 * Theme.s)
        Lit {
            x: 160 - 5 - 5
            y: 10
            width: 5
            height: 500
            n: 20
            vertical: true
            f: root.value
        }
        Tag {
            vertical: true // a vertical strip also has a capsule standing: the icon above the number
            anchors { right: parent.right; rightMargin: 26; verticalCenter: parent.verticalCenter }
            Icon { text: root.kind === "bri" ? "\u{F00E0}" : Sys.muted ? "\u{F075F}" : "\u{F057E}" }
            Num { text: Math.round(root.value * 100); font.pixelSize: 30 }
        }
    }

    // ---- bottom: task progress, without it — a running focus timer (as one strip, without a capsule: it hangs for tens of minutes) ----
    readonly property var task: Notes.task
    readonly property real progress: task ? Math.max(0, Math.min(100, task.hints.value ?? 0)) / 100 : Focus.f
    Connections {
        target: Focus
        function onDone() { root.push({ app: "focus", summary: "Focus done", body: `${Focus.minutes} min`, glyph: "\u{F13AB}" }); }
    }
    Edge {
        shown: (!!root.task || Focus.running) && Theme.state.edges
        anchors.bottom: true
        implicitWidth: Math.ceil(1100 * Theme.s)
        implicitHeight: Math.ceil(110 * Theme.s)
        Lit {
            x: 10
            y: 110 - 5 - 5
            width: 1080
            height: 5
            n: 40
            f: root.progress
        }
        Tag {
            visible: !!root.task
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 26 }
            Icon { text: "\u{F01DA}" }
            Lb { text: root.task?.summary ?? ""; color: Theme.fg }
            Num { text: Math.round(root.progress * 100) + "%"; font.pixelSize: 26 }
        }
    }

    // strip at the edge: transparent to the mouse, drawn in layout pixels
    component Edge: PanelWindow {
        property bool shown
        default property alias content: st.data
        visible: shown
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "glyph-edge"
        Stage { id: st }
    }
    // value capsule next to the strip; vertical — the content as a column
    component Tag: Rectangle {
        default property alias content: box.data
        property bool vertical
        width: vertical ? Math.max(52, box.width + 24) : box.width + 32
        height: vertical ? box.height + 36 : 52
        radius: Theme.corner(Math.min(width, height) / 2)
        color: Theme.s1
        border { width: 1; color: Theme.s2 }
        Grid {
            id: box
            anchors.centerIn: parent
            columns: parent.vertical ? 1 : 99
            spacing: parent.vertical ? 10 : 12
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
        }
    }
    // the glow of the lit segments — the only "shadow" in the whole shell
    component Glow: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.glow
        shadowBlur: 0.7
        blurMax: 20
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }
}
