import QtQuick
import qs

// wallpaper: the picture as a dot matrix (look 0), a grey photo in the theme tone (1) or color (2) — see shaders/wall.frag.
// Two pictures: the one on screen and the incoming one. It arrived — a wave from origin, at the end they swap roles, the old one is unloaded.
// An empty path — transparent: under the wallpaper the grid and orb. opaque — the picture covered everything, what is under it need not be drawn
Item {
    id: root

    property string path
    property int look: Theme.state.wallLook
    property real pitch: Theme.state.wallPitch
    property real bright: Theme.state.wallBright / 100
    property point origin: Qt.point(width / 2, height / 2)
    property bool animate: true // false — a change at once, without the wave
    readonly property bool opaque: fx.hasA > 0 && !run.running

    property bool flip: false // who is on screen: false — ia, true — ib
    readonly property Image cur: flip ? ib : ia
    readonly property Image next: flip ? ia : ib

    function crop(img) {
        const ia = img.implicitWidth / Math.max(1, img.implicitHeight), sa = width / Math.max(1, height);
        return ia > sa ? Qt.size(sa / ia, 1) : Qt.size(1, ia / sa);
    }

    // ---- change: shown — the path on screen, coming — on its way ----
    property string shown: ""
    property string coming: ""
    property bool pending: false
    readonly property bool sized: width > 0 && height > 0 // we do not load before there is a size: sourceSize 0 — decode in full

    onSizedChanged: change()
    onPathChanged: change()
    function change() {
        if (!sized) return;
        if (run.running) { // flipping faster than the wave — the current one is finished early
            run.stop();
            swap();
        }
        if (path === shown) {
            pending = false;
            next.source = "";
            return;
        }
        coming = path;
        pending = true;
        next.source = Theme.url(path);
        check();
    }
    function check() {
        if (!pending || next.status === Image.Loading) return;
        pending = false; // Error — goes to transparent, like an empty one
        if (animate) run.restart();
        else swap();
    }
    function swap() {
        flip = !flip;
        shown = coming;
        fx.wave = 0;
        next.source = ""; // now it is the old one
    }

    NumberAnimation { id: run; target: fx; property: "wave"; from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine; onFinished: root.swap() }

    // texture sources — neighbors of the effect, not children: the effect without pictures is hidden, and the scene does not update an invisible Image's
    // texture. That is why opacity 0, not visible: false. sourceSize — in logical pixels: on DPR Qt multiplies itself
    Image { id: ia; opacity: 0; asynchronous: true; cache: false; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(root.width, root.height); onStatusChanged: if (root.next === ia) root.check() }
    Image { id: ib; opacity: 0; asynchronous: true; cache: false; fillMode: Image.PreserveAspectCrop; sourceSize: ia.sourceSize; onStatusChanged: if (root.next === ib) root.check() }

    ShaderEffect {
        id: fx
        anchors.fill: parent
        visible: hasA > 0 || hasB > 0 || run.running // nothing to draw — no full-screen pass either

        // ---- uniforms ----
        readonly property size size: Qt.size(width, height)
        readonly property point origin: root.origin
        readonly property var srcA: root.cur
        readonly property var srcB: root.next
        readonly property size cropA: root.crop(root.cur)
        readonly property size cropB: root.crop(root.next)
        readonly property real hasA: root.cur.status === Image.Ready ? 1 : 0
        readonly property real hasB: root.next.status === Image.Ready ? 1 : 0
        readonly property color lo: Theme.light ? Theme.fg : Theme.bg
        readonly property color hi: Theme.light ? Theme.bg : Theme.fg
        readonly property color bg: Theme.bg
        readonly property real pitch: root.pitch
        readonly property real bright: root.bright
        property real dots: root.look === 0 ? 1 : 0
        property real mono: root.look < 2 ? 1 : 0
        property real wave: 0
        Behavior on dots { NumberAnimation { duration: 700; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        Behavior on mono { NumberAnimation { duration: 700 } }

        fragmentShader: Qt.resolvedUrl("shaders/wall.frag.qsb")
    }
}
