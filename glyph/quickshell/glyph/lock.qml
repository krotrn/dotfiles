import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "lock"

// lock — a separate process, as in demonshot: qs -p …/glyph/lock.qml (called by `rice lock`). Unlocked — we exit.
// The shell crashed — the lock lives; the lock crashed — Hyprland keeps the screen closed, SUPER+ALT+L raises it again
ShellRoot {
    id: shell
    // hot-reload recreates WlSessionLock: the old one dies, the process hangs without a screen
    settings.watchFiles: false

    QtObject {
        id: gate
        property string buffer: ""
        property bool fail: false
        property bool leaving: false // password accepted: the surface finishes the exit, then unlockT releases the lock
        readonly property bool busy: pam.active
        function submit() {
            if (!buffer || pam.active || leaving) return;
            pam.start();
        }
    }

    PamContext {
        id: pam
        config: "lock"
        configDirectory: Quickshell.shellPath("pam")
        onResponseRequiredChanged: if (responseRequired) respond(gate.buffer)
        onCompleted: res => {
            gate.buffer = "";
            if (res === PamResult.Success) {
                gate.leaving = true;
                unlockT.start();
            } else gate.fail = true;
        }
    }
    Timer { id: unlockT; interval: 470; onTriggered: lock.locked = false }

    property string layout: "en"
    function short(name) { return name.slice(0, 2).toLowerCase(); }
    Process {
        running: true
        command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main) | .active_keymap'"]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) shell.layout = shell.short(text.trim()) }
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "activelayout") shell.layout = shell.short(e.data.split(",").pop()); }
    }

    // After suspend Hyprland re-adds the keyboard but never sends a keyboard enter to a surface that stayed mapped, so the field
    // is drawn and gets no keys. A surface created after resume is focused again. Only the surface is rebuilt: the process and the
    // session lock stay up, so the screen never shows the "lock died" fallback.
    function makeSurface() {
        return Qt.createQmlObject('import QtQuick; import "lock"; Component { LockSurface { auth: gate; layout: shell.layout } }',
                                  shell, Qt.resolvedUrl("lock.qml"));
    }
    property Component surfaceComp: makeSurface()

    // Timers do not tick while suspended but the wall clock keeps going, so a jump between ticks means the machine just woke up
    property double lastTick: Date.now()
    Timer {
        running: true; repeat: true; interval: 1000
        onTriggered: {
            const now = Date.now();
            if (now - shell.lastTick > 4000) rebuildT.restart();
            shell.lastTick = now;
        }
    }
    // give the keyboard time to come back before the new surface asks for focus
    Timer {
        id: rebuildT
        interval: 1500
        onTriggered: {
            shell.surfaceComp = shell.makeSurface();
            console.log("lock: surface rebuilt after resume");
        }
    }

    WlSessionLock {
        id: lock
        locked: true
        // ponytail: lockedChanged does not arrive after locked = false (quickshell 0.3.2), and secure drops — we exit on it
        onSecureChanged: if (!secure) Qt.quit()

        surface: shell.surfaceComp
    }
}
