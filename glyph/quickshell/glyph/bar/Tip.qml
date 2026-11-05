import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import "../quick"

// a card for one bar button, like the battery card: wifi and bluetooth — the lists, sound — volume, notifications — the list,
// layout — the current layout. It opens under the button (or beside it when the bar is on the left); the bar decides when
// (hover or click) and keeps it open while the pointer is on the button or on the card (hot).
PopupWindow {
    id: root

    required property Item anchorItem
    property bool vert: false
    property point at          // the button's right edge (top bar) or bottom edge (left bar), in anchorItem coordinates
    property string tipId: ""
    property bool open: false
    readonly property bool hot: hov.hovered

    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
    visible: t > 0

    anchor.item: anchorItem
    anchor.rect: vert ? Qt.rect(anchorItem.width + 8, at.y, 1, 1) : Qt.rect(at.x, anchorItem.height + 8, 1, 1)
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: vert ? Edges.Top | Edges.Right : Edges.Bottom | Edges.Left
    implicitWidth: Math.ceil(card.width * Theme.s)
    implicitHeight: Math.ceil(card.height * Theme.s)
    color: "transparent"

    Stage {
        Rectangle {
            id: card
            width: 380
            height: content.item ? content.item.implicitHeight + 36 : 60
            radius: Theme.corner(30)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
            opacity: root.t
            transform: Translate { y: root.vert ? 0 : -12 * (1 - root.t); x: root.vert ? -12 * (1 - root.t) : 0 }
            HoverHandler { id: hov }

            Loader {
                id: content
                x: 18
                y: 18
                width: card.width - 36
                sourceComponent: ({ wifi: wifiC, bluetooth: btC, sound: soundC, notes: notesC, layout: layoutC })[root.tipId] ?? null
            }
        }
    }

    // ---- wifi / bluetooth: the same lists as in quick settings ----
    Component {
        id: wifiC
        Item {
            implicitHeight: wl.height
            Picker { id: wl; width: parent.width; kind: root.open && root.tipId === "wifi" ? "wifi" : "" }
        }
    }
    Component {
        id: btC
        Item {
            implicitHeight: bl.height
            Picker { id: bl; width: parent.width; kind: root.open && root.tipId === "bluetooth" ? "bt" : "" }
        }
    }

    // ---- sound: a big number, a slider, mute ----
    Component {
        id: soundC
        Column {
            spacing: 16
            Row {
                width: parent.width
                Lb { anchors.verticalCenter: parent.verticalCenter; text: "volume"; width: parent.width - pct.width }
                Num { id: pct; text: Sys.muted ? "off" : Math.round(Sys.vol * 100); font.pixelSize: 44 }
            }
            Rectangle {
                id: track
                width: parent.width
                height: 44
                radius: 22
                color: Theme.s2
                Rectangle {
                    width: Math.max(height, track.width * (Sys.muted ? 0 : Sys.vol))
                    height: parent.height
                    radius: 22
                    color: Theme.fg
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: m => Sys.setVol(m.x / width)
                    onPositionChanged: m => { if (pressed) Sys.setVol(m.x / width); }
                }
            }
            Rectangle {
                width: parent.width
                height: 48
                radius: 24
                color: Sys.muted ? Theme.fg : Theme.s2
                Lb { anchors.centerIn: parent; text: Sys.muted ? "unmute" : "mute"; px: 11; color: Sys.muted ? Theme.ink : Theme.fg }
                TapHandler { onTapped: if (Sys.sink?.audio) Sys.sink.audio.muted = !Sys.muted }
            }
        }
    }

    // ---- notifications: the history, a tap dismisses one ----
    Component {
        id: notesC
        Column {
            spacing: 12
            Item {
                width: parent.width
                height: 24
                Lb { anchors.verticalCenter: parent.verticalCenter; text: `notifications · ${Notes.list.length}`; px: 11 }
                Lb {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    visible: Notes.list.length > 0
                    text: "clear all"
                    color: Theme.fg
                    px: 11
                    TapHandler { onTapped: Notes.clear() }
                }
            }
            Lb { visible: !Notes.list.length; text: "nothing new"; px: 11 }
            ListView {
                id: nl
                width: parent.width
                height: Math.min(contentHeight, 320)
                clip: true
                spacing: 8
                model: Notes.list.slice().reverse()
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    required property var modelData
                    width: nl.width
                    height: tx.height + 24
                    radius: Theme.corner(22)
                    color: Theme.s2
                    Column {
                        id: tx
                        x: 18
                        y: 12
                        width: parent.width - 36
                        Lb { width: parent.width; elide: Text.ElideRight; text: `${modelData.appName} · ${Notes.ago(modelData, Date.now())}`; px: 9 }
                        Text { width: parent.width; elide: Text.ElideRight; text: modelData.summary; color: Theme.fg; font { family: Theme.ui; pixelSize: 15; weight: Font.DemiBold } }
                        Text { width: parent.width; elide: Text.ElideRight; visible: !!modelData.body; text: modelData.body; color: Theme.grey; font { family: Theme.ui; pixelSize: 13 } }
                    }
                    TapHandler { onTapped: modelData.dismiss() }
                }
            }
        }
    }

    // ---- layout: the current one, and a button for the next ----
    Component {
        id: layoutC
        Column {
            spacing: 14
            Lb { text: "keyboard layout"; px: 11 }
            Num { text: Sys.layout || "--"; font.pixelSize: 64 }
            Lb { width: parent.width; elide: Text.ElideRight; text: Sys.kbd; px: 10 }
            Rectangle {
                width: parent.width
                height: 48
                radius: 24
                color: Theme.s2
                Lb { anchors.centerIn: parent; text: "next layout"; px: 11; color: Theme.fg }
                TapHandler { onTapped: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]) }
            }
        }
    }
}
