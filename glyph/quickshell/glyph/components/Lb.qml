import QtQuick
import qs

// label: Space Mono all caps, tracking .14em, grey. Size — px (not font.pixelSize: tracking is computed from it)
Text {
    property real px: 12
    font { family: Theme.mono; pixelSize: px; letterSpacing: px * 0.14; capitalization: Font.AllUppercase }
    color: Theme.grey
}
