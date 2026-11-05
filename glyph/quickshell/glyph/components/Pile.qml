import QtQuick
import qs

// bar: a column at the left edge, a row on top (Theme.state.barAt); centered across. Only columns — Grid computes rows itself,
// otherwise on an edge change columns and rows change in turn and for a moment it comes out 1×1 ("more visible items than rows*columns" in the log).
// A separate file, not an inline component: a new inline component breaks hot reload ("is not a type") until qs is restarted.
Grid {
    readonly property bool vert: Theme.state.barAt !== "top"
    columns: vert ? 1 : 99
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
}
