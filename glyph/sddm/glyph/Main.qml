import QtQuick

// glyph for SDDM: a dot-matrix departure board. Doto is a dot-matrix face, so the board is written in it: split-flap cells
// that roll through letters and settle one after another, left to right.
//   the clock — five flaps, they roll when the minute turns
//   USER    — Tab: next user, Shift+Tab or a click on it: type one (anyone, including a hidden user)
//   SESSION — ←→ or the mouse wheel flips it, like a destination changing
//   STATUS  — what is happening, and what PAM says (faillock and the like)
//   the password lane — 32 square cells lit per letter, the newest red; a scan runs along it while PAM thinks,
//                       a wrong password flashes it red, a right one flips the board to WELCOME and fades into the session
// The strip at the bottom: key hints on the left, power on the right (↑ — select, ←→, Enter run, ↓ or Esc back, a letter — back).
// Alt held — peek. On start the frame draws itself and the rows switch on one by one, with a log in the corner.
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: bg

    readonly property color bg: "#000000"
    readonly property color s1: "#0E0E0E"
    readonly property color s2: "#1A1A1A"
    readonly property color s3: "#2A2A2A"
    readonly property color mute: "#4A4A4A"
    readonly property color grey: "#8C8C8C"
    readonly property color fg: "#F2F2F2"
    readonly property color red: "#D71921"

    FontLoader { id: doto; source: "fonts/Doto[ROND,wght].ttf" }
    FontLoader { id: grotesk; source: "fonts/SpaceGrotesk-Regular.otf" }
    FontLoader { id: mono; source: "fonts/SpaceMono-Regular.ttf" }

    property date now: new Date()
    property bool blink: true
    Timer { running: true; repeat: true; interval: 500; onTriggered: { root.blink = !root.blink; root.now = new Date(); } }
    readonly property string hhmm: (config.boolValue("clock24") ? Qt.formatTime(now, "hh") : String(now.getHours() % 12 || 12).padStart(2, "0"))
        + ":" + Qt.formatTime(now, "mm")

    // ---- power-up: the frame, then the rows one by one ----
    property real frame: 0 // the board outline drawn from the middle out
    property int rows: 0   // rows switched on
    property int step: 0   // log steps finished
    SequentialAnimation {
        running: true
        PauseAnimation { duration: 250 }
        NumberAnimation { target: root; property: "frame"; to: 1; duration: 600; easing.type: Easing.InOutCubic }
        PropertyAction { target: root; property: "step"; value: 1 }
        PropertyAction { target: root; property: "rows"; value: 1 }
        PauseAnimation { duration: 160 }
        PropertyAction { target: root; property: "rows"; value: 2 }
        PauseAnimation { duration: 160 }
        PropertyAction { target: root; property: "rows"; value: 3 }
        PropertyAction { target: root; property: "step"; value: 2 }
        PauseAnimation { duration: 160 }
        PropertyAction { target: root; property: "rows"; value: 4 }
        PauseAnimation { duration: 160 }
        PropertyAction { target: root; property: "rows"; value: 5 }
        PropertyAction { target: root; property: "step"; value: 3 }
        PauseAnimation { duration: 300 }
        PropertyAction { target: root; property: "step"; value: 4 }
    }

    // ---- the password lane ----
    readonly property int n: 32
    readonly property int typed: pwd.text.length
    property bool busy: false
    property bool ok: false
    property bool flash: false
    property bool fail: false
    property real scan: 0
    NumberAnimation on scan { running: root.busy; from: 0; to: 1; duration: 650; loops: Animation.Infinite }

    SequentialAnimation {
        id: denied
        loops: 3
        PropertyAction { target: root; property: "flash"; value: true }
        PauseAnimation { duration: 110 }
        PropertyAction { target: root; property: "flash"; value: false }
        PauseAnimation { duration: 90 }
    }

    // ---- session ----
    property int si: Math.max(0, sessionModel.lastIndex)
    function turn(d) { if (sessions.count) si = (si + d + sessions.count) % sessions.count; }
    readonly property string session: sessions.count && sessions.itemAt(si) ? sessions.itemAt(si).name : ""
    Repeater { id: sessions; model: sessionModel; Item { required property string name } }

    // ---- power on the strip. pm — selected from the keyboard, -1 — none ----
    readonly property var power: [
        { t: "sleep", can: sddm.canSuspend, go: () => sddm.suspend() },
        { t: "reboot", can: sddm.canReboot, go: () => sddm.reboot() },
        { t: "power off", can: sddm.canPowerOff, go: () => sddm.powerOff() }
    ]
    property int pm: -1
    property bool denyPower: false // Enter on one the system does not allow (always so in --test-mode, where there is no daemon)
    // arrows and Enter on the board — shared by both fields. true — the key is consumed.
    // Every power item can be selected; one that is not allowed says so instead of running
    function key(e) {
        if (pm >= 0) {
            if (e.key === Qt.Key_Left || e.key === Qt.Key_Right) { pm = Math.max(0, Math.min(power.length - 1, pm + (e.key === Qt.Key_Right ? 1 : -1))); denyPower = false; }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                const p = power[pm];
                if (!p.can) { denyPower = true; return true; }
                pm = -1;
                p.go();
            }
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_Escape) { pm = -1; denyPower = false; }
            else if (e.key !== Qt.Key_Up) { pm = -1; denyPower = false; return false; } // typing — back, the letter goes to the field
            return true;
        }
        if (e.key === Qt.Key_Up) { pm = 0; denyPower = false; return true; }
        if (e.key === Qt.Key_Left || e.key === Qt.Key_Right) { turn(e.key === Qt.Key_Right ? 1 : -1); return true; }
        return false;
    }

    // ---- who logs in: the name is a field, the user list only fills it in (Tab) ----
    property int ui: Math.max(0, userModel.lastIndex)
    function pick(d) {
        if (!names.count) return;
        ui = (ui + d + names.count) % names.count;
        user.text = names.itemAt(ui).name;
    }
    Repeater { id: names; model: userModel; Item { required property string name } }
    Component.onCompleted: {
        if (!user.text && names.count) user.text = names.itemAt(ui).name;
        (user.text ? pwd : user).forceActiveFocus();
    }

    property bool queued: false
    property string msg // what PAM said, e.g. the faillock lockout
    function login() {
        if (busy || ok) return;
        const who = user.text.trim();
        if (!who) { user.forceActiveFocus(); return; }
        if (step < 4) { queued = true; return; } // Enter during the power-up — log in as soon as it ends
        queued = false;
        busy = true;
        fail = false;
        msg = "";
        sddm.login(who, pwd.text, si);
    }
    onStepChanged: if (step === 4 && queued) login()
    Connections {
        target: sddm
        function onLoginFailed() { root.busy = false; root.fail = true; pwd.text = ""; denied.restart(); }
        function onLoginSucceeded() { root.busy = false; root.ok = true; }
        function onInformationMessage(m) { root.msg = m; }
    }

    property bool peek: false // Alt held: the typed text in the status row (Tab picks users here)
    readonly property string status: ok ? "boarding · welcome"
        : busy ? "checking…"
        : fail ? (msg || "denied · try again")
        : pm >= 0 && denyPower ? `${power[pm].t} · not available here`
        : pm >= 0 ? `enter · ${power[pm].t}    ↓ · back`
        : user.activeFocus ? "type user · tab"
        : peek && pwd.text ? pwd.text
        : pwd.text ? `${typed} · enter to start`
        : keyboard.capsLock ? "caps lock is on"
        : "type password"

    // label: Space Mono all caps, tracking .14em, grey
    component Lb: Text {
        property real px: 12
        font { family: mono.name; pixelSize: px; letterSpacing: px * 0.14; capitalization: Font.AllUppercase }
        color: root.grey
    }
    // split-flap cells: a fixed number of cells; a new text rolls through letters and settles cell by cell, left to right
    component Flap: Row {
        id: flap
        property string text
        property int cells: 12
        property real px: 40
        property color color: root.fg
        property bool on: true // off — the cells are blank
        property string shown: ""
        property int tick: 0
        readonly property string pool: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        readonly property string target: (on ? text.toUpperCase() : "").padEnd(cells, " ").slice(0, cells)
        spacing: Math.round(px * 0.1)
        onTargetChanged: { tick = 0; roll.restart(); }
        Component.onCompleted: { shown = " ".repeat(cells); roll.restart(); }
        Timer {
            id: roll
            interval: 32
            repeat: true
            onTriggered: {
                flap.tick++;
                let s = "";
                for (let i = 0; i < flap.cells; i++) {
                    const t = flap.target[i];
                    const settled = flap.tick >= 3 + i * 1.3;
                    s += settled || t === " " ? t : flap.pool[Math.floor(Math.random() * flap.pool.length)];
                }
                flap.shown = s;
                if (flap.tick >= 3 + flap.cells * 1.3) stop();
            }
        }
        Repeater {
            model: flap.cells
            Rectangle {
                required property int index
                width: Math.round(flap.px * 0.74)
                height: Math.round(flap.px * 1.12)
                radius: Math.max(2, flap.px * 0.08)
                color: root.s2
                Text {
                    anchors.centerIn: parent
                    text: flap.shown[parent.index] ?? " "
                    font { family: doto.name; pixelSize: flap.px; weight: Font.Black; variableAxes: ({ "ROND": 100, "wght": 900 }) }
                    color: flap.color
                }
                // the split of the flap
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 2; color: root.bg; opacity: 0.85 }
            }
        }
    }

    // 1920×1080 canvas, stretched to the screen
    Item {
        id: stage
        readonly property real s: Math.min(root.width / 1920, root.height / 1080)
        width: root.width / s
        height: root.height / s
        scale: s
        transformOrigin: Item.TopLeft

        MouseArea {
            anchors.fill: parent
            property real acc: 0 // a touchpad sends small steps — accumulate up to a click
            onClicked: pwd.forceActiveFocus()
            onWheel: w => {
                acc += w.angleDelta.y;
                if (Math.abs(acc) < 120) return;
                root.turn(acc < 0 ? 1 : -1);
                acc = 0;
            }
        }

        Image {
            visible: config.boolValue("grid")
            anchors.fill: parent
            opacity: root.frame
            fillMode: Image.Tile
            source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><circle cx="16" cy="16" r="1.5" fill="${root.s2}"/></svg>`)
        }

        // ---- the board
        Item {
            id: board
            readonly property real w: 1360
            readonly property real h: 720
            x: (stage.width - w) / 2
            y: (stage.height - h) / 2
            width: w
            height: h
            opacity: root.ok ? 0 : 1
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 700 } NumberAnimation { duration: 500 } } }

            // the panel and its outline, drawn from the middle out
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * root.frame
                height: parent.height
                radius: 18
                color: root.s1
                border { width: 1; color: root.s3 }
                opacity: Math.min(1, root.frame * 2)
            }
            // rivets in the corners
            Repeater {
                model: [[22, 22], [board.w - 30, 22], [22, board.h - 30], [board.w - 30, board.h - 30]]
                Rectangle { required property var modelData; x: modelData[0]; y: modelData[1]; width: 8; height: 8; radius: 4; color: root.s3; opacity: root.frame }
            }

            // row 1: the clock and the date
            Item {
                x: 64; y: 56
                width: board.w - 128; height: 150
                opacity: root.rows >= 1 ? 1 : 0
                Flap {
                    id: clockFlap
                    px: 112
                    cells: 5
                    text: root.hhmm
                    on: root.rows >= 1
                }
                Column {
                    anchors { right: parent.right; verticalCenter: clockFlap.verticalCenter }
                    spacing: 10
                    Lb { anchors.right: parent.right; px: 15; color: root.fg; text: Qt.locale("en_US").toString(root.now, "dddd") }
                    Lb { anchors.right: parent.right; px: 13; text: Qt.locale("en_US").toString(root.now, "d MMMM yyyy") }
                    Lb { anchors.right: parent.right; px: 11; color: root.mute; text: `${sddm.hostName}${keyboard.layouts[keyboard.currentLayout]?.shortName ? " · " + keyboard.layouts[keyboard.currentLayout].shortName : ""}` }
                }
            }

            Rectangle { x: 64; y: 240; width: (board.w - 128) * root.frame; height: 1; color: root.s3 }

            // rows 2–4: label and value, like a board's columns
            Column {
                x: 64; y: 276
                spacing: 22

                // USER
                Row {
                    spacing: 40
                    opacity: root.rows >= 2 ? 1 : 0
                    Lb { width: 180; anchors.verticalCenter: parent.verticalCenter; px: 13; text: "user"; color: user.activeFocus ? root.red : root.grey }
                    Item {
                        width: userFlap.width; height: userFlap.height
                        Flap {
                            id: userFlap
                            px: 40
                            cells: 18
                            text: user.text
                            on: root.rows >= 2
                            opacity: user.activeFocus ? 0 : 1
                        }
                        // typing a name: the field itself on the board, with a red underline
                        TextInput {
                            id: user
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            width: parent.width - 16
                            visible: activeFocus
                            text: userModel.lastUser
                            font { family: grotesk.name; pixelSize: 34; capitalization: Font.AllUppercase }
                            color: root.fg
                            selectionColor: root.s3
                            selectedTextColor: root.fg
                            Rectangle { anchors { left: parent.left; top: parent.bottom; topMargin: 4 } width: Math.max(40, parent.contentWidth); height: 2; color: root.red }
                            onActiveFocusChanged: if (activeFocus) selectAll() // started typing — the name is replaced as a whole
                            onAccepted: pwd.forceActiveFocus()
                            Keys.onPressed: e => {
                                if (root.pm < 0 && (e.key === Qt.Key_Left || e.key === Qt.Key_Right)) return; // arrows move the cursor here
                                if (root.key(e)) e.accepted = true;
                                else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab || e.key === Qt.Key_Escape) { pwd.forceActiveFocus(); e.accepted = true; }
                            }
                        }
                        MouseArea { anchors.fill: parent; enabled: !user.activeFocus; cursorShape: Qt.IBeamCursor; onClicked: user.forceActiveFocus() }
                    }
                    Lb { anchors.verticalCenter: parent.verticalCenter; px: 11; color: root.mute; visible: names.count > 1; text: `${root.ui + 1}/${names.count} · tab` }
                }

                // SESSION
                Row {
                    spacing: 40
                    opacity: root.rows >= 3 ? 1 : 0
                    Lb { width: 180; anchors.verticalCenter: parent.verticalCenter; px: 13; text: "session" }
                    Flap { px: 40; cells: 18; text: root.session; on: root.rows >= 3 }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14
                        Repeater {
                            model: [["‹", -1], ["›", 1]]
                            Text {
                                required property var modelData
                                text: modelData[0]
                                font { family: mono.name; pixelSize: 30 }
                                color: arrowArea.containsMouse ? root.fg : root.grey
                                MouseArea { id: arrowArea; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.turn(parent.modelData[1]) }
                            }
                        }
                        Lb { anchors.verticalCenter: parent.verticalCenter; px: 11; color: root.mute; text: `${root.si + 1}/${sessions.count}` }
                    }
                }

                // STATUS: plain text — a flap would roll on every letter typed
                Row {
                    spacing: 40
                    opacity: root.rows >= 4 ? 1 : 0
                    Lb { width: 180; anchors.verticalCenter: parent.verticalCenter; px: 13; text: "status" }
                    Item {
                        width: 860; height: 44
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10; height: 10; radius: 5
                            color: root.flash || root.fail ? root.red : root.busy ? (root.blink ? root.fg : root.mute) : root.ok ? root.fg : root.mute
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: 26; right: parent.right; verticalCenter: parent.verticalCenter }
                            elide: Text.ElideMiddle
                            text: root.status
                            font {
                                family: mono.name; pixelSize: 20; letterSpacing: 2.8
                                capitalization: root.peek && pwd.text && !root.fail && root.pm < 0 ? Font.MixedCase : Font.AllUppercase
                            }
                            color: root.flash || root.fail ? root.red : root.peek && pwd.text ? root.fg : root.grey
                        }
                    }
                }
            }

            // row 5: the password lane — square cells, lit per letter, the newest red
            Row {
                x: 64; y: 560
                spacing: 40
                opacity: root.rows >= 5 ? 1 : 0
                Lb { width: 180; anchors.verticalCenter: parent.verticalCenter; px: 13; text: "pass"; color: pwd.activeFocus && !root.busy ? root.fg : root.grey }
                Row {
                    spacing: 9
                    Repeater {
                        model: root.n
                        Rectangle {
                            required property int index
                            readonly property bool lit: root.ok || index < root.typed
                            readonly property bool tip: !root.ok && !root.busy && index === Math.min(root.typed, root.n) - 1
                            readonly property bool scanned: root.busy && Math.abs(index - root.scan * root.n) < 1.6
                            width: 22; height: 22; radius: 4
                            color: root.flash ? root.red : scanned ? root.fg : tip ? root.red : lit ? (root.busy ? root.grey : root.fg) : root.s2
                            Behavior on color { ColorAnimation { duration: 80 } }
                            // a typed cell pops in
                            scale: lit ? 1 : 0.82
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                        }
                    }
                }
            }

            Rectangle { x: 64; y: 620; width: (board.w - 128) * root.frame; height: 1; color: root.s3 }

            // the strip: hints on the left, power on the right
            Lb {
                x: 64; y: 652
                px: 11
                color: root.mute
                opacity: root.step >= 3 ? 1 : 0
                text: "tab · user    ←→ · session    ↑ · power    alt · peek    enter · start"
            }
            Row {
                anchors { right: parent.right; rightMargin: 64 }
                y: 646
                spacing: 32
                opacity: root.step >= 3 ? 1 : 0
                Repeater {
                    model: root.power
                    Row {
                        id: pw
                        required property var modelData
                        required property int index
                        readonly property bool sel: root.pm === index
                        spacing: 10
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8; height: 8; radius: 4
                            color: pw.sel ? (pw.modelData.can ? root.fg : root.red) : root.s3
                        }
                        Lb {
                            px: 12
                            text: pw.modelData.t
                            color: pw.sel ? (pw.modelData.can ? root.fg : root.red) : pwArea.containsMouse && pw.modelData.can ? root.fg : pw.modelData.can ? root.grey : root.mute
                            MouseArea {
                                id: pwArea
                                anchors { fill: parent; margins: -8 }
                                hoverEnabled: true
                                enabled: pw.modelData.can
                                cursorShape: Qt.PointingHandCursor
                                onClicked: pw.modelData.go()
                            }
                        }
                    }
                }
            }
        }

        // input — a real TextInput (layouts, IME), only invisible
        TextInput {
            id: pwd
            width: 1
            height: 1
            opacity: 0
            focus: true
            echoMode: TextInput.Password
            onTextEdited: root.fail = false
            onAccepted: root.login()
            Keys.onPressed: e => {
                if (root.key(e)) e.accepted = true;
                else if (e.key === Qt.Key_Escape) { text = ""; e.accepted = true; }
                else if (e.key === Qt.Key_Alt) { if (!e.isAutoRepeat) root.peek = true; }
                else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
                    if (e.key === Qt.Key_Tab && names.count > 1) root.pick(1);
                    else user.forceActiveFocus(); // one in the list or Shift+Tab — type a name
                    e.accepted = true;
                }
            }
            Keys.onReleased: e => { if (e.key === Qt.Key_Alt && !e.isAutoRepeat) root.peek = false; }
        }

        // corners: on the left the mark and the power-up log, on the right the lock keys — the dot is lit while the key is on
        Column {
            x: 44
            y: 36
            spacing: 6
            Text {
                text: "DOTS"
                font { family: doto.name; pixelSize: 34; weight: Font.Black; variableAxes: ({ "ROND": 100, "wght": 900 }) }
                topPadding: -0.175 * font.pixelSize
                bottomPadding: topPadding
                color: root.fg
            }
            Lb { px: 11; text: "login" }
            Item { width: 1; height: 10 }
            Repeater {
                model: ["board", "rows", "lane", "auth"]
                Lb {
                    required property string modelData
                    required property int index
                    readonly property bool done: root.step > index
                    visible: root.step >= index
                    px: 10
                    color: done ? root.mute : root.grey
                    opacity: done || root.blink ? 1 : 0.4
                    text: `0${index + 1} ${modelData} · ${done ? (index === 3 ? "ready" : "ok") : "··"}`
                }
            }
        }
        Row {
            anchors { right: parent.right; rightMargin: 44 }
            y: 40
            spacing: 28
            opacity: root.frame
            Repeater {
                model: [["caps", keyboard.capsLock], ["num", keyboard.numLock]]
                Row {
                    required property var modelData
                    spacing: 10
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: parent.modelData[1] ? root.fg : root.s3 }
                    Lb { px: 11; text: parent.modelData[0]; color: parent.modelData[1] ? root.fg : root.grey }
                }
            }
        }
    }
}
