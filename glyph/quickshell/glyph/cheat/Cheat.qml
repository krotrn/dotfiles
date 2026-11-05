import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components

// keybind cheatsheet: Super+H. The live binds from `hyprctl binds -j` that have a description, as "keys — what it does".
// Typing filters, ↑↓ / wheel scroll, esc closes. Reads nothing from the config files, so it always matches what is bound now.
PanelWindow {
    id: root

    property var rows: []
    property string query: ""
    readonly property var shown_: rows.filter(r => !query || (r.keys + " " + r.what).toLowerCase().includes(query.toLowerCase()))

    // modmask bits: shift 1, ctrl 4, alt 8, super 64
    function combo(b) {
        const m = [];
        if (b.modmask & 64) m.push("Super");
        if (b.modmask & 4) m.push("Ctrl");
        if (b.modmask & 8) m.push("Alt");
        if (b.modmask & 1) m.push("Shift");
        m.push(b.key.length === 1 ? b.key.toUpperCase() : b.key);
        return m.join(" + ");
    }
    function parse(text) {
        let list = [];
        try { list = JSON.parse(text); } catch (e) { list = []; }
        const seen = {};
        const out = [];
        for (const b of list) {
            if (!b.has_description || !b.description) continue;
            const keys = combo(b);
            const id = keys + "|" + b.description;
            if (seen[id]) continue;
            seen[id] = true;
            out.push({ keys, what: b.description });
        }
        out.sort((a, c) => a.keys.localeCompare(c.keys));
        rows = out;
        list.contentY = 0;
    }
    onQueryChanged: list.contentY = 0

    Process {
        id: binds
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    // ---- open / close: own animation (glyph layers have no hypr animations) ----
    property bool shown: false
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    function open() {
        query = "";
        field.text = "";
        binds.running = true;
        shown = true;
        field.forceActiveFocus();
    }
    function close() { shown = false; }
    function toggle() { shown ? close() : open(); }

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glyph-cheat"

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
            width: 900
            height: 760
            opacity: root.t
            radius: Theme.corner(44)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
            MouseArea { anchors.fill: parent } // a click on the panel does not close it

            // search pill
            Rectangle {
                id: pill
                x: 36
                y: 36
                width: panel.width - 72
                height: 64
                radius: Theme.corner(32)
                color: Theme.s2
                Lb { x: 28; anchors.verticalCenter: parent.verticalCenter; text: "keys"; px: 11 }
                TextInput {
                    id: field
                    anchors { left: parent.left; leftMargin: 100; right: count.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    color: Theme.fg
                    selectionColor: Theme.fg
                    selectedTextColor: Theme.ink
                    clip: true
                    font { family: Theme.mono; pixelSize: 18 }
                    onTextChanged: root.query = text
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Escape) root.close();
                        else if (e.key === Qt.Key_Down) list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, list.contentY + 120));
                        else if (e.key === Qt.Key_Up) list.contentY = Math.max(0, list.contentY - 120);
                        else if (e.key === Qt.Key_PageDown) list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, list.contentY + list.height));
                        else if (e.key === Qt.Key_PageUp) list.contentY = Math.max(0, list.contentY - list.height);
                        else return;
                        e.accepted = true;
                    }
                    cursorDelegate: Rectangle { width: 2; color: Theme.accent }
                }
                Lb {
                    id: count
                    anchors { right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }
                    text: root.shown_.length + " binds"
                    px: 10
                }
            }

            ListView {
                id: list
                x: 36
                y: 120
                width: panel.width - 72
                height: panel.height - 120 - 70
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.shown_
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 46
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 1
                        color: Theme.s2
                    }
                    Text {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 360
                        elide: Text.ElideRight
                        text: row.modelData.keys
                        color: Theme.fg
                        font { family: Theme.mono; pixelSize: 15; weight: Font.DemiBold }
                    }
                    Text {
                        x: 392
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 392 - 12
                        elide: Text.ElideRight
                        text: row.modelData.what
                        color: Theme.grey
                        font { family: Theme.ui; pixelSize: 16 }
                    }
                }
            }

            Lb { visible: !root.shown_.length; x: 48; y: 140; text: root.rows.length ? "nothing matches" : "no binds with a description"; px: 11 }

            Row {
                x: 36
                anchors { bottom: parent.bottom; bottomMargin: 28 }
                spacing: 30
                Lb { text: "type to filter"; px: 10 }
                Lb { text: "↑↓ scroll"; px: 10 }
                Lb { text: "esc close"; px: 10; TapHandler { onTapped: root.close() } }
            }
        }
    }
}
