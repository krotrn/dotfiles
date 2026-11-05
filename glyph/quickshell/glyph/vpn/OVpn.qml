import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components

// vpn: NetworkManager (OpenVPN, WireGuard) instead of Clash Verge. Panel in the style of the other glyph panels:
// a ring that lights up while a tunnel is up, and the list of saved VPN connections. Enter or click connects / disconnects.
// Passwords come from the connection itself (NetworkManager keeps them), so nothing is asked here.
PanelWindow {
    id: root

    // ---- connections: [{ name, on }] ----
    property var ways: []
    property int cur: 0
    property string busyName: ""   // connecting / disconnecting right now
    property string error: ""
    readonly property var active: ways.find(w => w.on) ?? null
    readonly property bool connected: !!active

    function refresh() { if (!listP.running) listP.running = true; }
    function parse(text) {
        const out = [];
        for (const l of text.split("\n")) {
            const i = l.indexOf("|");
            if (i < 0) continue;
            out.push({ on: l.slice(0, i) === "1", name: l.slice(i + 1) });
        }
        ways = out;
        cur = Math.min(cur, Math.max(0, out.length - 1));
    }
    function go(i) {
        const w = ways[i];
        if (!w || busyName) return;
        error = "";
        busyName = w.name;
        act.command = ["nmcli", "connection", w.on ? "down" : "up", w.name];
        act.running = true;
    }
    function flip() { go(active ? ways.indexOf(active) : cur); }

    Process {
        id: listP
        // type vpn / wireguard; 1|name when active
        command: ["sh", "-c",
            'a=$(nmcli -t -f NAME,TYPE connection show --active); ' +
            'nmcli -t -f NAME,TYPE connection show | while IFS= read -r l; do ' +
            'case "$l" in *:vpn|*:wireguard) n=${l%:*}; ' +
            'if printf "%s\\n" "$a" | grep -qxF "$l"; then echo "1|$n"; else echo "0|$n"; fi;; esac; done']
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Process {
        id: act
        stderr: StdioCollector { id: actErr }
        onExited: code => {
            root.error = code === 0 ? "" : (actErr.text.trim().split("\n").pop() || "failed");
            root.busyName = "";
            root.refresh();
        }
    }
    Timer { interval: 3000; repeat: true; running: root.shown; onTriggered: root.refresh() }

    // ---- open / close: own animation (glyph layers have no hypr animations) ----
    property bool shown: false
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    function open() {
        error = "";
        refresh();
        shown = true;
        panel.forceActiveFocus();
    }
    function close() { shown = false; }
    function toggle() { shown ? close() : open(); }

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glyph-ovpn"

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.t
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Stage {
        id: stage

        Rectangle {
            id: panel
            x: (stage.width - width) / 2
            y: (stage.height - height) / 2 - 20 + 24 * (1 - root.t)
            width: 860
            height: 480
            opacity: root.t
            radius: Theme.corner(44)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
            focus: true
            MouseArea { anchors.fill: parent } // a click on the panel does not close it

            Keys.onPressed: e => {
                const n = root.ways.length;
                if ((e.key === Qt.Key_Up || e.key === Qt.Key_K) && n) root.cur = (root.cur + n - 1) % n;
                else if ((e.key === Qt.Key_Down || e.key === Qt.Key_J) && n) root.cur = (root.cur + 1) % n;
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.go(root.cur);
                else if (e.key === Qt.Key_E) { Quickshell.execDetached(["nm-connection-editor"]); root.close(); }
                else if (e.key === Qt.Key_Escape) root.close();
                else return;
                list.positionViewAtIndex(root.cur, ListView.Contain);
                e.accepted = true;
            }

            // ---- left: ring ----
            Item {
                id: left
                x: 36
                y: 36
                width: 300
                height: 300
                Ring { anchors.fill: parent; n: 60; dot: 9; f: root.shown && root.connected ? 1 : 0 }
                Column {
                    anchors.centerIn: parent
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: root.connected ? Theme.accent : Theme.s3
                        Behavior on color { ColorAnimation { duration: Theme.t } }
                    }
                    Num {
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: lead + 18
                        bottomPadding: lead + 12
                        text: root.busyName ? "..." : root.connected ? "ON" : "OFF"
                        font.pixelSize: 100
                        color: root.connected ? Theme.fg : Theme.mute
                        Behavior on color { ColorAnimation { duration: Theme.t } }
                    }
                    Lb {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.busyName ? "working" : root.connected ? "connected" : "tap to connect"
                    }
                }
                TapHandler { onTapped: root.flip() }
            }

            Lb {
                x: 36
                y: 360
                width: 300
                wrapMode: Text.WordWrap
                visible: !!root.error
                text: root.error
                color: Theme.accent
                px: 10
            }

            // ---- right: connections ----
            Column {
                x: 376
                y: 40
                width: panel.width - 376 - 40
                spacing: 18
                Lb { text: "vpn · networkmanager"; px: 11 }
                Lb { visible: !root.ways.length; text: "no vpn connections saved"; px: 11 }

                ListView {
                    id: list
                    width: parent.width
                    height: Math.min(contentHeight, 300)
                    clip: true
                    spacing: 10
                    model: root.ways
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool cursor: root.cur === index
                        width: list.width
                        height: 72
                        radius: Theme.corner(36)
                        color: modelData.on ? Theme.fg : cursor ? Theme.s3 : Theme.s2
                        Behavior on color { ColorAnimation { duration: Theme.t } }
                        Rectangle {
                            id: dot
                            x: 26
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: row.modelData.on ? Theme.accent : Theme.grey
                        }
                        Column {
                            anchors { left: dot.right; leftMargin: 18; right: state.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: row.modelData.name
                                font { family: Theme.ui; pixelSize: 17; weight: Font.DemiBold }
                                color: row.modelData.on ? Theme.ink : Theme.fg
                            }
                        }
                        Lb {
                            id: state
                            anchors { right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }
                            px: 10
                            text: root.busyName === row.modelData.name ? "working" : row.modelData.on ? "disconnect" : "connect"
                            color: row.modelData.on ? Theme.ink : Theme.grey
                        }
                        TapHandler { onTapped: { root.cur = row.index; root.go(row.index); } }
                    }
                }
            }

            Row {
                x: 376
                anchors { bottom: parent.bottom; bottomMargin: 34 }
                spacing: 30
                Lb { text: "↑↓ select"; px: 10 }
                Lb { text: "↵ connect / disconnect"; px: 10 }
                Lb { text: "e edit"; px: 10 }
                Lb { text: "esc close"; px: 10; TapHandler { onTapped: root.close() } }
            }
        }
    }
}
