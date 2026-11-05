import QtQuick
import qs

// canvas in layout pixels 1920×1080: stretched to the parent, everything inside is measured as in concept.html
Item {
    property real k: Theme.s // the bar overrides it with Theme.bs to stay out of the global ui scale
    width: parent.width / k
    height: parent.height / k
    scale: k
    transformOrigin: Item.TopLeft
}
