import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// The lock as a combination dial — the login screen's language (knurl, text on arcs, LED glyphs, a red tip, a staged power-up),
// seen face-on in the middle of the wallpaper. Every letter turns the dial a notch and lights the next dot of the ring; Enter
// runs a wave around the ring while PAM thinks; a wrong one flashes red and spins the dial back to zero; a right one spins it open.
// It powers up again after every wake (the surface is rebuilt then): the knurl lights around, the ring fills and empties, the face appears.
// ↑ — the power arcs on the right: ←→ select, Enter run, ↓ or Esc back, a letter goes back to the password. Tab held — peek, Esc — clear.
WlSessionLockSurface {
    id: root

    required property var auth // gate from lock.qml: buffer, fail, fails, note, busy, leaving, caps, num, layout, since, submit(), type(), refreshKeys()

    color: Theme.bg

    SystemClock { id: clock; precision: SystemClock.Seconds }
    property bool blink: true
    Timer { running: true; repeat: true; interval: 500; onTriggered: root.blink = !root.blink }

    FileView { id: hostFile; path: "/etc/hostname"; blockLoading: true }
    readonly property string host: hostFile.text().trim()
    readonly property var bat: UPower.displayDevice
    readonly property bool charging: bat.state === UPowerDeviceState.Charging || bat.state === UPowerDeviceState.FullyCharged
    readonly property bool lowBat: bat.isLaptopBattery && !charging && bat.percentage <= 0.15
    readonly property int lockedMin: Math.floor((clock.date.getTime() - auth.since) / 60000)

    // ---- power-up ----
    property real knurl: 0 // share of the circle the knurl front has run
    property real test: 0  // self-test: the ring fills and empties
    property real face: 0  // clock, labels, arcs
    property int step: 0   // power-up steps finished
    SequentialAnimation {
        running: true
        PauseAnimation { duration: 100 }
        NumberAnimation { target: root; property: "knurl"; to: 1; duration: 480; easing.type: Easing.InOutSine }
        PropertyAction { target: root; property: "step"; value: 1 }
        NumberAnimation { target: root; property: "test"; to: 1; duration: 320; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "test"; to: 0; duration: 320; easing.type: Easing.InOutCubic }
        PropertyAction { target: root; property: "step"; value: 2 }
        NumberAnimation { target: root; property: "face"; to: 1; duration: 340; easing.type: Easing.OutQuart }
        PropertyAction { target: root; property: "step"; value: 3 }
    }

    // ---- the dial ----
    readonly property int n: 32           // dots on the ring, one per letter
    readonly property real notch: 360 / 40 // the dial turns this much per letter
    readonly property bool busy: auth.busy
    readonly property bool ok: auth.leaving
    readonly property int typed: auth.buffer.length
    property bool flash: false
    property real wave: 0
    NumberAnimation on wave { running: root.busy; from: 0; to: 1; duration: 700; loops: Animation.Infinite }

    // how far the dial is turned: a notch per letter, back to zero when cleared or denied, a full spin when it opens
    readonly property real target: ok ? -540 : -typed * notch
    property real rot: target
    Behavior on rot { SpringAnimation { spring: root.ok ? 1.6 : 4; damping: root.ok ? 0.5 : 0.3; epsilon: 0.05 } }
    // the ring: lit up to the letters typed, or the self-test
    readonly property real fill: ok ? 1 : Math.max(test, Math.min(typed / n, 1))

    SequentialAnimation {
        id: denied
        loops: 3
        PropertyAction { target: root; property: "flash"; value: true }
        PauseAnimation { duration: 110 }
        PropertyAction { target: root; property: "flash"; value: false }
        PauseAnimation { duration: 90 }
    }
    Connections {
        target: root.auth
        function onFailChanged() { if (root.auth.fail) denied.restart(); }
    }

    // Enter during the power-up: unlock as soon as it ends
    property bool queued: false
    function submit() {
        if (step < 3) { queued = true; return; }
        queued = false;
        auth.submit();
    }
    onStepChanged: if (step === 3 && queued) submit()

    // ---- power arcs. pm — selected from the keyboard, -1 — none ----
    readonly property var power: [
        { t: "sleep", a: 48, go: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { t: "reboot", a: 64, go: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { t: "power off", a: 82, go: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
    ]
    property int pm: -1
    // true — the key is consumed by the power arcs, the password does not see it
    function key(e) {
        if (pm >= 0) {
            if (e.key === Qt.Key_Left) pm = Math.max(0, pm - 1);
            else if (e.key === Qt.Key_Right) pm = Math.min(power.length - 1, pm + 1);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { const p = power[pm]; pm = -1; p.go(); }
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_Escape) pm = -1;
            else if (e.key !== Qt.Key_Up) { pm = -1; return false; } // typing — back, the letter goes to the password
            return true;
        }
        if (e.key === Qt.Key_Up) { pm = 0; return true; }
        return false;
    }

    property bool peek: false // Tab held: the typed text in the status line

    readonly property string status: ok ? "open"
        : busy ? "checking…"
        : auth.fail ? (auth.note ? auth.note.replace(/\s*\n\s*/g, " · ") : auth.fails > 1 ? `denied · ${auth.fails} tries` : "denied · try again")
        : pm >= 0 ? `enter · ${power[pm].t}   ↓ · back`
        : peek && auth.buffer ? auth.buffer
        : auth.buffer ? `${typed} · enter to open`
        : auth.caps ? "caps lock is on"
        : "type password"

    // text along an arc: letters on a circle of radius r, the middle at angle a (degrees from 12 o'clock). button — clickable
    component Arc: Item {
        id: arc
        property string text
        property real r
        property real a
        property real px: 12
        property color color: Theme.grey
        property bool button: false
        property int hov: 0 // letters under the mouse: leaving one and entering the next arrive in any order
        signal hit
        readonly property string up: text.toUpperCase()
        FontMetrics { id: fm; font { family: Theme.mono; pixelSize: arc.px } }
        readonly property real adv: fm.advanceWidth("M") + px * 0.14
        Repeater {
            model: arc.up.split("")
            Text {
                required property string modelData
                required property int index
                readonly property real b: arc.a + (index + 0.5 - arc.up.length / 2) * arc.adv / arc.r * 180 / Math.PI
                x: arc.r * Math.sin(b * Math.PI / 180) - width / 2
                y: -arc.r * Math.cos(b * Math.PI / 180) - height / 2
                rotation: b
                text: modelData
                font { family: Theme.mono; pixelSize: arc.px }
                color: arc.button && arc.hov > 0 ? Theme.fg : arc.color
                MouseArea {
                    x: (parent.width - arc.adv) / 2
                    y: -8
                    width: arc.adv
                    height: parent.height + 16
                    enabled: arc.button
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: arc.hov += containsMouse ? 1 : -1
                    onClicked: arc.hit()
                }
            }
        }
    }
    // a part on a circle of radius r at angle a, rotated along the radius
    component Polar: Rectangle {
        property real a
        property real r
        x: r * Math.sin(a * Math.PI / 180) - width / 2
        y: -r * Math.cos(a * Math.PI / 180) - height / 2
        rotation: a
    }

    // 1920×1080 canvas, stretched to the screen like the login one
    Item {
        id: stage
        readonly property real s: Math.min(root.width / 1920, root.height / 1080)
        width: root.width / s
        height: root.height / s
        scale: s
        transformOrigin: Item.TopLeft
        focus: true

        Keys.onPressed: e => {
            if (root.ok) return;
            const ctrl = e.modifiers & Qt.ControlModifier;
            if (root.key(e)) e.accepted = true;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.submit(); e.accepted = true; }
            else if (e.key === Qt.Key_Escape) { root.auth.buffer = ""; root.auth.fail = false; e.accepted = true; }
            else if (e.key === Qt.Key_Backspace) { root.auth.buffer = ctrl ? "" : root.auth.buffer.slice(0, -1); e.accepted = true; }
            else if (ctrl && e.key === Qt.Key_U) { root.auth.buffer = ""; e.accepted = true; }
            else if (e.key === Qt.Key_Tab) { if (!e.isAutoRepeat) root.peek = true; e.accepted = true; }
            else if (e.key === Qt.Key_CapsLock || e.key === Qt.Key_NumLock) root.auth.refreshKeys();
            else if (!ctrl && e.text && e.text.charCodeAt(0) >= 32) { root.auth.type(e.text); e.accepted = true; }
        }
        Keys.onReleased: e => {
            if (e.key === Qt.Key_Tab && !e.isAutoRepeat) { root.peek = false; e.accepted = true; }
        }

        MouseArea { anchors.fill: parent; onClicked: stage.forceActiveFocus() }

        // ---- the theme behind it: wallpaper (or the dot grid without one), darkened so the dial reads
        Image {
            anchors.fill: parent
            fillMode: Image.Tile
            source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><circle cx="16" cy="16" r="1.5" fill="${Theme.s2}"/></svg>`)
        }
        Wall {
            width: stage.width
            height: stage.height
            path: Theme.wallSrc(Theme.state.wall)
            opacity: root.knurl
        }
        Rectangle { anchors.fill: parent; color: Theme.bg; opacity: 0.62 }

        // ---- the dial: everything is measured from its centre
        Item {
            id: dial
            x: stage.width / 2
            y: stage.height / 2
            opacity: root.ok ? 0 : 1
            scale: root.ok ? 1.12 : 1
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 280 } NumberAnimation { duration: 480 } } }
            Behavior on scale { SequentialAnimation { PauseAnimation { duration: 280 } NumberAnimation { duration: 480; easing.type: Easing.InCubic } } }

            // the disc face
            Rectangle {
                x: -400; y: -400; width: 800; height: 800; radius: 400
                color: Theme.fade(Theme.s1, 0.9)
                border { width: 1; color: Theme.s3 }
                opacity: root.knurl
            }

            // turns with the letters: the knurl at the rim and the numbers inside it
            Item {
                rotation: root.rot
                Repeater {
                    model: 180
                    Polar {
                        required property int index
                        // the power-up front runs once around from 12 o'clock
                        readonly property real d: root.knurl - index / 180
                        a: index * 2
                        r: 382
                        width: index % 5 === 0 ? 3 : 2
                        height: index % 5 === 0 ? 26 : 16
                        visible: d >= 0 || root.knurl >= 1
                        color: d < 0.05 && root.knurl < 1 ? Theme.fg : index % 5 === 0 ? Theme.grey : Theme.mute
                    }
                }
                Repeater {
                    model: 20
                    Lb {
                        required property int index
                        readonly property real a: index * 18 * Math.PI / 180
                        x: 338 * Math.sin(a) - width / 2
                        y: -338 * Math.cos(a) - height / 2
                        rotation: index * 18
                        px: 12
                        text: String(index * 5).padStart(2, "0")
                        color: Theme.mute
                        opacity: root.face
                    }
                }
            }

            // the index: a fixed notch at 12 o'clock, outside the rim, red like the tip of the needle
            Rectangle { x: -3; y: -430; width: 6; height: 30; radius: 3; color: Theme.red; opacity: root.knurl }

            // the ring of 32 dots: lit clockwise up to the letters, the newest red. While PAM thinks a dip runs around
            Repeater {
                model: root.n
                Polar {
                    required property int index
                    readonly property bool lit: index < Math.round(root.fill * root.n)
                    readonly property bool tip: !root.ok && !root.busy && root.typed > 0 && index === Math.min(root.typed, root.n) - 1
                    readonly property bool dip: root.busy && Math.abs(index - root.wave * root.n) < 2.2
                    a: index * 360 / root.n
                    r: 292
                    width: 12
                    height: 12
                    radius: 6
                    visible: root.step >= 1 || root.test > 0
                    color: root.flash ? Theme.red : tip ? Theme.red : lit && !dip ? Theme.fg : Theme.s3
                    Behavior on color { ColorAnimation { duration: 90 } }
                }
            }

            // seconds: one dot orbiting inside the ring, a faint track under it
            Rectangle {
                x: -262; y: -262; width: 524; height: 524; radius: 262
                color: "transparent"
                border { width: 1; color: Theme.s2 }
                opacity: root.face
            }
            Polar {
                a: clock.date.getSeconds() * 6
                r: 262
                width: 7; height: 7; radius: 3.5
                color: Theme.fg
                opacity: root.face
                Behavior on a { enabled: clock.date.getSeconds() !== 0; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }

            // the first thing to light up
            Rectangle {
                x: -8; y: -8; width: 16; height: 16; radius: 8
                color: Theme.red
                opacity: 1 - root.face
                NumberAnimation on scale { from: 0; to: 1; duration: 300; easing.type: Easing.OutBack }
            }

            // the face: clock, date, name, what is happening
            Column {
                x: -width / 2
                y: -128
                spacing: 14
                opacity: root.face
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: [Theme.hh(clock.date), ":", Qt.formatTime(clock.date, "mm")]
                        Num {
                            required property string modelData
                            required property int index
                            text: modelData
                            font.pixelSize: 140
                            opacity: index === 1 && !root.blink && Theme.state.blink ? 0.2 : 1
                        }
                    }
                }
                Lb {
                    anchors.horizontalCenter: parent.horizontalCenter
                    px: 13
                    text: Qt.locale("en_US").toString(clock.date, "dddd · d MMM")
                }
                Item { width: 1; height: 6 }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Quickshell.env("USER")
                    font { family: Theme.ui; pixelSize: 24 }
                    color: Theme.fg
                }
                Lb {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(implicitWidth, 420)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    px: 12
                    color: root.flash || root.auth.fail ? Theme.red : root.peek && root.auth.buffer ? Theme.fg : Theme.grey
                    font.capitalization: root.peek && root.auth.buffer && !root.auth.fail && root.pm < 0 ? Font.MixedCase : Font.AllUppercase
                    text: root.status
                }
            }

            // ---- outside the rim: hints on top, the lock on the left, power on the right
            Arc {
                r: 462; a: 0; px: 11
                color: Theme.mute
                opacity: root.face
                text: "↑ · power    tab · peek    esc · clear    enter · open"
            }
            Repeater {
                model: [
                    { a: -46, t: root.lockedMin < 1 ? "locked" : `locked · ${root.lockedMin} min`, c: Theme.fg, on: true },
                    { a: -64, t: Weather.ok ? `${Math.round(Weather.now.temp)}° ${Weather.name(Weather.now.code)}` : "", c: Theme.grey, on: Weather.ok },
                    { a: -82, t: `${Math.round(root.bat.percentage * 100)}%${root.charging ? " · charging" : ""}`, c: root.lowBat ? Theme.red : Theme.grey, on: root.bat.isLaptopBattery }
                ]
                Arc {
                    required property var modelData
                    visible: modelData.on
                    r: 462
                    a: modelData.a
                    px: 12
                    color: modelData.c
                    opacity: root.face
                    text: modelData.t
                }
            }
            Repeater {
                model: root.power
                Arc {
                    required property var modelData
                    required property int index
                    r: 462
                    a: modelData.a
                    px: 12
                    button: true
                    color: root.pm === index ? Theme.fg : Theme.grey
                    opacity: root.face
                    text: modelData.t
                    onHit: modelData.go()
                }
            }
            // the mark of the power arcs: outside the selected one
            Polar {
                a: root.power[Math.max(0, root.pm)].a
                r: 494
                width: 4
                height: 14
                radius: 2
                color: Theme.fg
                opacity: root.pm >= 0 ? 1 : 0
                Behavior on a { SpringAnimation { spring: 5; damping: 0.35 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // under the dial: what is playing (click — play / pause) and the machine
            Column {
                x: -width / 2
                y: 432
                spacing: 8
                opacity: root.face
                Lb {
                    readonly property var p: Media.player
                    readonly property string title: p?.trackTitle ?? ""
                    visible: title !== ""
                    anchors.horizontalCenter: parent.horizontalCenter
                    px: 11
                    color: playArea.containsMouse ? Theme.fg : Media.playing ? Theme.grey : Theme.mute
                    text: `${Media.playing ? "▮▮" : "▶"}  ${title}${p?.trackArtist ? " · " + p.trackArtist : ""}`
                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (parent.p?.canTogglePlaying) parent.p.togglePlaying()
                    }
                }
                Lb { anchors.horizontalCenter: parent.horizontalCenter; px: 10; color: Theme.mute; text: `${root.host}${root.auth.layout ? " · " + root.auth.layout : ""}` }
            }
        }

        // corners: on the left the mark, on the right the lock keys — the dot is lit while the key is on
        Column {
            x: 44
            y: 36
            spacing: 6
            opacity: root.face
            Num { text: "DOTS"; font.pixelSize: 34 }
            Lb { px: 11; text: "locked" }
        }
        Row {
            anchors { right: parent.right; rightMargin: 44 }
            y: 40
            spacing: 28
            opacity: root.face
            Repeater {
                model: [["caps", root.auth.caps], ["num", root.auth.num]]
                Row {
                    required property var modelData
                    spacing: 10
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: parent.modelData[1] ? Theme.fg : Theme.s3 }
                    Lb { px: 11; text: parent.modelData[0]; color: parent.modelData[1] ? Theme.fg : Theme.grey }
                }
            }
        }
    }
}
