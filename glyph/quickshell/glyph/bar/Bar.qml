import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services
import qs.settings

// bar: a pill at the left edge or on top — Theme.state.barAt. First the mark (a ring of 16 dots) — the launcher, the center turns red
// while recording or the microphone is on. Workspaces as dots, the window title, a Doto clock in the center, the tray last — a click opens quick settings.
// On the side everything is a column, on top — a row. What is in the tray and in which order, whether there is a title — Theme.state (settings, the BAR section)
PanelWindow {
    id: root

    signal markClicked
    signal trayClicked
    signal powerClicked
    signal clockClicked

    readonly property bool vert: Theme.state.barAt !== "top" // everything except top (and anything unknown) — on the left
    anchors { left: true; right: !vert; top: true; bottom: vert }
    implicitWidth: Math.ceil(78 * Theme.bs)  // on the side
    implicitHeight: Math.ceil(30 * Theme.bs) // on top
    color: "transparent"
    WlrLayershell.namespace: "glyph-bar"

    readonly property int active: Hyprland.focusedWorkspace?.id ?? 0
    // six dots, more — if one far away is occupied or open
    readonly property int count: Math.min(10, Math.max(6, active, ...Hyprland.workspaces.values.filter(w => w.toplevels.values.length).map(w => w.id)))
    readonly property var top: ToplevelManager.activeToplevel
    readonly property var bat: UPower.displayDevice
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    // hyprland 0.56 with lua: dispatch takes a lua expression
    function go(ws) { Hyprland.dispatch(`hl.dsp.focus({ workspace = "${ws}" })`); }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Stage {
        k: Theme.bs
        Rectangle {
            id: pill
            x: root.vert ? 14 : 0 // on top — flush with the screen edge
            y: root.vert ? 14 : 0
            width: root.vert ? 64 : parent.width
            height: root.vert ? parent.height - 28 : 30
            radius: Theme.corner(root.vert ? 32 : 0)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }

            WheelHandler { onWheel: e => root.go(e.angleDelta.y > 0 ? "-1" : "+1") }

            // mark: a ring of dots, the center is red while something is writing
            Item {
                id: mark
                x: root.vert ? (parent.width - width) / 2 : 12
                y: root.vert ? 18 : (parent.height - height) / 2
                width: root.vert ? 34 : 20
                height: root.vert ? 34 : 20
                Ring { anchors.fill: parent; n: 16; dot: root.vert ? 3 : 2 }
                Rectangle {
                    anchors.centerIn: parent
                    width: root.vert ? 9 : 6
                    height: root.vert ? 9 : 6
                    radius: width / 2
                    color: !Sys.live ? Theme.fg : Qt.colorEqual(Theme.accent, Theme.fg) ? Theme.red : Theme.accent // monochrome: accent = fg
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.markClicked() }
            }

            // workspaces: the current one stretches into a white pill, occupied ones grey, empty ones a line
            Pile {
                id: ws
                x: root.vert ? (parent.width - width) / 2 : mark.x + mark.width + 24
                y: root.vert ? mark.y + mark.height + 24 : (parent.height - height) / 2
                spacing: 8

                Repeater {
                    model: root.count

                    Rectangle {
                        required property int index
                        readonly property int n: index + 1
                        readonly property bool occ: (Hyprland.workspaces.values.find(w => w.id === n)?.toplevels.values.length ?? 0) > 0
                        readonly property bool on: root.active === n
                        property real len: on ? 28 : 8
                        width: root.vert ? 8 : len
                        height: root.vert ? len : 8
                        radius: 4
                        color: on ? Theme.fg : occ ? Theme.grey : Theme.s3
                        Behavior on len { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                        Behavior on color { ColorAnimation { duration: Theme.t } }
                        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.go(parent.n) }
                    }
                }
            }

            // window title: from the workspaces to the clock, on the side — rotated
            Item {
                id: title
                x: root.vert ? (parent.width - width) / 2 : ws.x + ws.width + 24
                y: root.vert ? ws.y + ws.height + 24 : (parent.height - height) / 2
                width: root.vert ? 20 : Math.max(0, clk.x - 24 - x)
                height: root.vert ? Math.max(0, clk.y - 24 - y) : 20
                clip: true
                visible: Theme.state.barTitle
                Lb {
                    x: (parent.width - width) / 2
                    y: (parent.height - height) / 2
                    width: root.vert ? parent.height : parent.width
                    rotation: root.vert ? 90 : 0
                    elide: Text.ElideRight
                    visible: (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) > 0
                    text: root.top ? `${root.top.appId.split(".").pop()} · ${root.top.title}` : ""
                    px: 11
                }
            }

            // clock: on the side a column 14 over 32 and the day, on top a row. Click — calendar and focus timer (cal/Cal)
            Pile {
                id: clk
                anchors.centerIn: parent
                TapHandler { onTapped: root.clockClicked() }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Num { text: Theme.hh(clock.date); font.pixelSize: root.vert ? 30 : 20 }
                Num { visible: !root.vert; text: ":"; font.pixelSize: 20 }
                Num { text: Qt.formatTime(clock.date, "mm"); font.pixelSize: root.vert ? 30 : 20 }
                Lb {
                    topPadding: root.vert ? 8 : 0
                    leftPadding: root.vert ? 0 : 12
                    text: Qt.locale("en_US").toString(clock.date, "ddd d")
                    px: 10
                }
            }

            // tray — Theme.state.bar in order (settings, the BAR section). Layout, network, bluetooth, sound (wheel — volume),
            // notifications, battery, the running cat: a click opens quick settings. Power mode and power — their own clicks
            // the quick settings button: the far right end of the bar (the bottom end when the bar is on the left)
            Item {
                id: qbtn
                x: root.vert ? (parent.width - width) / 2 : parent.width - width - 10
                y: root.vert ? parent.height - height - 10 : (parent.height - height) / 2
                width: 32
                height: 32
                Icon { anchors.centerIn: parent; text: "\u{F035C}"; font.pixelSize: 20; color: Theme.fg }
                TapHandler { onTapped: root.trayClicked() }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
            Pile {
                x: root.vert ? (parent.width - width) / 2 : parent.width - width - 22 - qbtn.width
                y: root.vert ? parent.height - height - 22 - qbtn.height : (parent.height - height) / 2
                spacing: 20

                Repeater {
                    model: Theme.state.bar
                    Loader {
                        id: part
                        required property string modelData
                        readonly property bool quick: modelData !== "mode" && modelData !== "power"
                        // these buttons have their own card (bar/Tip): it opens on hover or click and goes out when the pointer leaves
                        readonly property bool hasTip: ["wifi", "bluetooth", "sound", "notes", "layout"].includes(modelData)
                        sourceComponent: root.parts[modelData] ?? null
                        visible: !!sourceComponent && (modelData !== "battery" || root.bat.isLaptopBattery)
                        TapHandler { enabled: part.hasTip; onTapped: root.tipShow(part) }
                        HoverHandler {
                            enabled: part.quick
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: {
                                if (!part.hasTip) return;
                                if (hovered) root.tipShow(part);
                                else if (root.tipId === part.modelData) root.tipBar = false;
                            }
                        }
                    }
                }
            }
        }
    }
    readonly property var parts: ({ layout: layoutC, wifi: wifiC, bluetooth: btC, sound: soundC, notes: notesC, battery: batC, mode: modeC, power: powerC, cat: catC })
    Component { id: layoutC; Lb { text: Sys.layout; px: 10 } }
    // RunCat cat: the more cpu, the faster it runs (250 ms per frame idle, 50 at full load). cpu is polled while it is in the tray;
    // a Binding is not in the delegate — a destroyed one returns no value. Grey as is, in the light theme it is lost on white — black, like buds
    Component {
        id: catC
        AnimatedImage {
            width: 44
            height: 26
            source: "runcat.gif"
            mipmap: true
            speed: 1 + 4 * SysStats.cpu
            layer.enabled: Theme.light
            layer.effect: MultiEffect { brightness: -1 }
        }
    }
    Binding { target: SysStats; property: "cat"; value: Theme.state.bar.includes("cat") }
    // network: two arcs and a dot, round ends, like the battery; off — a slash
    Component {
        id: wifiC
        Shape {
            id: wf
            width: 20
            height: 18
            preferredRendererType: Shape.CurveRenderer
            readonly property color ink: root.wifi?.connected ? Theme.fg : Theme.grey
            ShapePath {
                strokeColor: wf.ink; strokeWidth: 2.2; capStyle: ShapePath.RoundCap; fillColor: "transparent"
                PathAngleArc { centerX: 10; centerY: 15; radiusX: 5.5; radiusY: 5.5; startAngle: 220; sweepAngle: 100 }
                PathAngleArc { centerX: 10; centerY: 15; radiusX: 10.5; radiusY: 10.5; startAngle: 220; sweepAngle: 100 }
            }
            ShapePath {
                strokeColor: Networking.wifiEnabled ? "transparent" : wf.ink; strokeWidth: 2.2; capStyle: ShapePath.RoundCap
                startX: 3; startY: 2
                PathLine { x: 17; y: 17 }
            }
            ShapePath {
                strokeWidth: -1; fillColor: wf.ink
                PathAngleArc { centerX: 10; centerY: 15; radiusX: 1.9; radiusY: 1.9; startAngle: 0; sweepAngle: 360 }
            }
        }
    }
    Component {
        id: btC
        Icon {
            text: Bluetooth.defaultAdapter?.enabled ? "\u{F00AF}" : "\u{F00B2}"
            color: Bluetooth.devices.values.some(d => d.connected) ? Theme.fg : Theme.grey
        }
    }
    Component {
        id: soundC
        Icon {
            text: Sys.muted ? "\u{F075F}" : "\u{F057E}"
            WheelHandler { onWheel: e => Sys.setVol(Sys.vol + (e.angleDelta.y > 0 ? 0.05 : -0.05)) }
        }
    }
    Component {
        id: notesC
        Icon {
            text: Theme.state.dnd ? "\u{F009B}" : "\u{F009A}"
            color: Notes.list.length ? Theme.fg : Theme.grey
        }
    }
    // on the left the battery stands, the charge grows from the bottom; on top — it lies, grows from the left. On charge — the bolt first, the fill breathes while charging
    Component {
        id: batC
        Pile {
            id: batc
            HoverHandler { onHoveredChanged: { root.batHot = hovered; root.peek(batc); } Component.onDestruction: root.batHot = false }
            spacing: 8
            readonly property bool ac: !UPower.onBattery
            readonly property bool charging: root.bat.state === UPowerDeviceState.Charging
            // breathing at 20 frames/s, like the orb in home/Back: an animation would drive the bar on every vsync (120 Hz) the whole time
            // of charging. Cosine with a 2.2 s period — the same two InOutSine of 1.1 s
            property real phase: 0
            readonly property real pulse: charging ? 0.675 + 0.325 * Math.cos(phase * Math.PI / 1.1) : 1
            Timer { running: batc.charging; interval: 50; repeat: true; onTriggered: batc.phase = (batc.phase + 0.05) % 2.2; onRunningChanged: batc.phase = 0 }
            Icon { visible: batc.ac; text: "\u{F140B}"; font.pixelSize: 14 }
            Rectangle {
                width: root.vert ? 14 : 26
                height: root.vert ? 26 : 14
                radius: 7
                color: "transparent"
                border { width: 1.5; color: Theme.grey }
                Rectangle {
                    x: 3
                    y: parent.height - 3 - height
                    width: root.vert ? parent.width - 6 : (parent.width - 6) * root.bat.percentage
                    height: root.vert ? (parent.height - 6) * root.bat.percentage : parent.height - 6
                    radius: 4
                    color: root.batLow ? Theme.red : Theme.fg
                    opacity: batc.pulse
                }
            }
            // width — for "100": on top the tray is pressed to the right, 99 → 100 would shift everything left
            Lb { width: full.implicitWidth; horizontalAlignment: Text.AlignHCenter; text: Math.round(root.bat.percentage * 100); px: 10 }
            Lb { id: full; visible: false; text: "100"; px: 10 }
        }
    }
    // power mode as ticks (Rules.modes): ultra — one, performance — all; click — next,
    // hover (also on the battery) — a card with a choice
    Component {
        id: modeC
        Item {
            id: ticks
            width: 40
            height: 22
            Row {
                anchors.centerIn: parent
                spacing: 2
                Repeater {
                    model: Rules.modeCount
                    Rectangle {
                        required property int index
                        anchors.bottom: parent.bottom
                        width: 3
                        height: 5 + index * 3
                        radius: 1.5
                        color: index <= Rules.mode ? Theme.fg : Theme.s3
                    }
                }
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor; onHoveredChanged: { root.tickHot = hovered; root.peek(ticks); } Component.onDestruction: root.tickHot = false }
            TapHandler { onTapped: Rules.setMode((Rules.mode + 1) % Rules.modeCount) }
        }
    }
    Component {
        id: powerC
        Icon {
            text: "\u{F0425}"
            color: pwr.hovered ? Theme.fg : Theme.grey
            HoverHandler { id: pwr; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.powerClicked() }
        }
    }

    // ---- battery and power mode: hover the battery or the ticks — a card beside the bar (on the screen side), like a caelestia popover.
    // Doto charge, status, a scale; below the modes as circles with ticks — click selects, under the cursor — what it does.
    // Left both the bar and the card — it goes out ----
    property bool batHot: false
    property bool tickHot: false
    readonly property bool powHot: batHot || tickHot || popHov.hovered
    readonly property bool batLow: UPower.onBattery && root.bat.percentage < 0.15
    // the card is placed by what was hovered (battery or ticks): on the side — its bottom to its bottom, on top — its right edge to its right edge;
    // while visible — it does not jump
    property point popAt
    function peek(it) { if (!pop.visible) popAt = it.mapToItem(pill, it.width, it.height); }
    property bool powOpen: false
    property int powPeek: -1
    onPowHotChanged: powHot ? powOpenT.restart() : powCloseT.restart()
    Timer { id: powOpenT; interval: 180; onTriggered: if (root.powHot) root.powOpen = true }
    Timer { id: powCloseT; interval: 300; onTriggered: if (!root.powHot) root.powOpen = false }
    function hm(sec) { const m = Math.round(sec / 60); return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} m` : `${m} m`; }
    readonly property string batState: root.bat.state === UPowerDeviceState.Charging
        ? "charging" + (root.bat.timeToFull ? ` · full in ${hm(root.bat.timeToFull)}` : "")
        : !UPower.onBattery ? "on ac · full"
        : "on battery" + (root.bat.timeToEmpty ? ` · ${hm(root.bat.timeToEmpty)} left` : "")

    // ---- the card of a tray button (wifi, bluetooth, sound, notifications, layout): bar/Tip. Same timing as the battery card ----
    property string tipId: ""
    property point tipAt
    property bool tipBar: false     // the pointer is on the button
    property bool tipOpen: false
    readonly property bool tipHot: tipBar || tip.hot
    function tipShow(it) {
        if (tipId !== it.modelData) tipOpen = false; // another button: the card starts again at its place
        tipId = it.modelData;
        tipAt = root.vert ? it.mapToItem(pill, 0, it.height) : it.mapToItem(pill, it.width, 0);
        tipBar = true;
        tipOpen = true;
    }
    onTipHotChanged: if (!tipHot) tipCloseT.restart()
    Timer { id: tipCloseT; interval: 350; onTriggered: if (!root.tipHot) root.tipOpen = false }
    Tip { id: tip; anchorItem: pill; vert: root.vert; at: root.tipAt; tipId: root.tipId; open: root.tipOpen }

    PopupWindow {
        id: pop
        property real t: root.powOpen ? 1 : 0
        Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        visible: t > 0
        // from the inner edge of the bar pill with a gap of 14; on the side it grows up from popAt, on top — down and to the left
        anchor.item: pill
        anchor.rect: root.vert ? Qt.rect(pill.width + 14, root.popAt.y, 1, 1) : Qt.rect(root.popAt.x, pill.height + 14, 1, 1)
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: root.vert ? Edges.Top | Edges.Right : Edges.Bottom | Edges.Left
        implicitWidth: Math.ceil(440 * Theme.s)
        implicitHeight: Math.ceil(card.height * Theme.s)
        color: "transparent"

        Stage {
            Rectangle {
                id: card
                width: 440
                height: body.height + 52
                radius: Theme.corner(36)
                color: Theme.s1
                border { width: 1; color: Theme.s2 }
                opacity: pop.t
                transform: Translate { x: root.vert ? -16 * (1 - pop.t) : 0; y: root.vert ? 0 : -16 * (1 - pop.t) }
                HoverHandler { id: popHov }

                Column {
                    id: body
                    x: 26
                    y: 26
                    width: parent.width - 52
                    spacing: 18

                    Row {
                        spacing: 14
                        Num { text: Math.round(root.bat.percentage * 100); font.pixelSize: 72 }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Lb { text: "% battery"; color: Theme.fg }
                            Lb { text: root.batState }
                        }
                    }
                    Seg { width: parent.width; height: 6; n: 24; f: root.bat.percentage; on: root.batLow ? Theme.red : Theme.fg }

                    Lb { topPadding: 6; text: "power mode" }
                    Row {
                        spacing: (body.width - Rules.modeCount * 80) / Math.max(1, Rules.modeCount - 1)
                        Repeater {
                            model: Rules.modeCount
                            Column {
                                id: mo
                                required property int index
                                readonly property bool on: Rules.mode === index
                                spacing: 10
                                Rectangle {
                                    width: 80
                                    height: 80
                                    radius: 40
                                    color: mo.on ? Theme.fg : moHov.hovered ? Theme.s3 : Theme.s2
                                    Behavior on color { ColorAnimation { duration: Theme.t } }
                                    // ticks: how many are lit — that much power
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Repeater {
                                            model: 4
                                            Rectangle {
                                                required property int index
                                                anchors.bottom: parent.bottom
                                                width: 5
                                                height: 8 + index * 6
                                                radius: 2.5
                                                color: index <= mo.index ? (mo.on ? Theme.ink : Theme.fg) : (mo.on ? Theme.mute : Theme.s3)
                                            }
                                        }
                                    }
                                    HoverHandler {
                                        id: moHov
                                        cursorShape: Qt.PointingHandCursor
                                        onHoveredChanged: if (hovered) root.powPeek = mo.index; else if (root.powPeek === mo.index) root.powPeek = -1
                                    }
                                    TapHandler { onTapped: Rules.setMode(mo.index) }
                                }
                                Lb { anchors.horizontalCenter: parent.horizontalCenter; text: mo.index === 3 ? "max" : Rules.modes[mo.index].name; color: mo.on ? Theme.fg : Theme.grey }
                            }
                        }
                    }
                    Lb {
                        readonly property int i: root.powPeek >= 0 ? root.powPeek : Rules.mode
                        width: parent.width
                        elide: Text.ElideRight
                        text: `${Rules.modes[i].what} · ${i === 0 ? Rules.rates[0] : Rules.refreshHz} hz`
                    }
                }
            }
        }
    }
}
