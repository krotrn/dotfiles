import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components

// the menu of an app's tray icon (bar, apps), drawn by the shell like the bar cards: quickshell can show the app's own menu only as a
// Qt widget menu, which needs QApplication mode. Entries — the app's dbusmenu: checks and radios as a dot, a submenu opens in place
// with a back row on top. A click outside (focus grab), a click on an entry or Esc closes it.
PopupWindow {
    id: root

    required property Item anchorItem
    property bool vert: false
    property point at              // the icon's corner in anchorItem coordinates: bottom-left (top bar) or top-right (left bar)
    property var item: null        // SystemTrayItem
    property bool open: false
    property var stack: []         // opened submenus, QsMenuEntry; empty — the top menu

    function show(it, p) {
        stack = [];
        item = it;
        at = p;
        open = true;
    }
    function close() { open = false; }

    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
    visible: t > 0
    onVisibleChanged: if (!visible) { item = null; stack = []; }

    anchor.item: anchorItem
    anchor.rect: vert ? Qt.rect(anchorItem.width + 8, at.y, 1, 1) : Qt.rect(at.x, anchorItem.height + 8, 1, 1)
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: vert ? Edges.Bottom | Edges.Right : Edges.Bottom | Edges.Left
    implicitWidth: Math.ceil(card.width * Theme.s)
    implicitHeight: Math.ceil(card.height * Theme.s)
    color: "transparent"

    HyprlandFocusGrab {
        windows: [root]
        active: root.open
        onCleared: root.close()
    }

    QsMenuOpener {
        id: menu
        menu: root.stack.length ? root.stack[root.stack.length - 1] : root.item?.menu ?? null
    }

    Stage {
        Rectangle {
            id: card
            width: 300
            height: Math.min(list.contentHeight, 560) + 24
            radius: Theme.corner(24)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
            opacity: root.t
            transform: Translate { y: root.vert ? 0 : -12 * (1 - root.t); x: root.vert ? -12 * (1 - root.t) : 0 }
            focus: root.open
            Keys.onEscapePressed: root.stack.length ? root.stack = root.stack.slice(0, -1) : root.close()

            ListView {
                id: list
                x: 12
                y: 12
                width: card.width - 24
                height: card.height - 24
                clip: true
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                header: Item {
                    width: list.width
                    height: root.stack.length ? 40 : 0
                    visible: root.stack.length > 0
                    Rectangle { anchors.fill: parent; radius: Theme.corner(12); color: backHov.hovered ? Theme.s2 : "transparent" }
                    Row {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Icon { anchors.verticalCenter: parent.verticalCenter; text: "\u{F0141}"; font.pixelSize: 16; color: Theme.grey }
                        Lb { anchors.verticalCenter: parent.verticalCenter; text: root.stack.length ? root.stack[root.stack.length - 1].text.replace(/_/g, "") : ""; px: 10 }
                    }
                    HoverHandler { id: backHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.stack = root.stack.slice(0, -1) }
                }
                model: menu.children

                delegate: Item {
                    id: row
                    required property QsMenuEntry modelData
                    readonly property bool check: modelData.buttonType !== QsMenuButtonType.None
                    width: list.width
                    height: modelData.isSeparator ? 13 : 40

                    Rectangle {
                        visible: row.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 24
                        height: 1
                        color: Theme.s2
                    }
                    Rectangle {
                        visible: !row.modelData.isSeparator
                        anchors.fill: parent
                        radius: Theme.corner(12)
                        color: hov.hovered && row.modelData.enabled ? Theme.s2 : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.t } }
                    }
                    Row {
                        visible: !row.modelData.isSeparator
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        // check / radio: a ring, filled when on
                        Rectangle {
                            visible: row.check
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10
                            height: 10
                            radius: row.modelData.buttonType === QsMenuButtonType.RadioButton ? 5 : 2
                            color: row.modelData.checkState === Qt.Checked ? Theme.fg : "transparent"
                            border { width: 1.5; color: row.modelData.checkState === Qt.Checked ? Theme.fg : Theme.grey }
                        }
                        Image {
                            visible: !row.check && row.modelData.icon !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            sourceSize: Qt.size(32, 32)
                            source: row.modelData.icon
                            asynchronous: true
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: list.width - 24 - (row.check || row.modelData.icon !== "" ? 26 : 0) - (row.modelData.hasChildren ? 20 : 0)
                            elide: Text.ElideRight
                            // dbusmenu marks the mnemonic with "_"
                            text: row.modelData.text.replace(/_(?!_)/g, "")
                            font { family: Theme.mono; pixelSize: 13 }
                            color: row.modelData.enabled ? Theme.fg : Theme.grey
                        }
                    }
                    Icon {
                        visible: row.modelData.hasChildren
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        text: "\u{F0142}"
                        font.pixelSize: 16
                        color: Theme.grey
                    }
                    HoverHandler { id: hov; enabled: !row.modelData.isSeparator; cursorShape: row.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    TapHandler {
                        enabled: !row.modelData.isSeparator && row.modelData.enabled
                        onTapped: {
                            if (row.modelData.hasChildren) {
                                root.stack = root.stack.concat([row.modelData]);
                                return;
                            }
                            row.modelData.triggered();
                            root.close();
                        }
                    }
                }
            }
        }
    }
}
