import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// hot edge: the cursor lingered at the right edge — quick settings slide out (Quick.peek). A 2px strip over the top 30%
// of the right edge: from the top right corner down
PanelWindow {
    id: root

    signal triggered

    visible: Theme.state.quickHover
    anchors { right: true; top: true }
    implicitWidth: 2
    implicitHeight: Math.round(screen.height * 0.3)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glyph-hot"

    HoverHandler { id: hov; onHoveredChanged: hovered ? dwell.restart() : dwell.stop() }
    Timer { id: dwell; interval: 150; onTriggered: if (hov.hovered) root.triggered() }
}
