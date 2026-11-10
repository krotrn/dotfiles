import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "lock"

// The lock screen: its own process (`rice lock` runs qs -p …/glyph/lock.qml), so a crash of the shell never unlocks the session.
// It quits once the password is accepted. While the session is locked and drawn it keeps a marker file in $XDG_RUNTIME_DIR:
// gpu-wake-before-sleep waits for it before it lets a suspend go on, so the desktop never shows on wake.
ShellRoot {
    id: shell
    // hot reload would recreate WlSessionLock: the old one dies and the process hangs without a screen
    settings.watchFiles: false

    readonly property string marker: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/glyph-lock.secure"

    // everything the surfaces need about the password and the keyboard
    QtObject {
        id: gate
        property string buffer: ""
        property bool fail: false
        property int fails: 0
        property string note: ""      // PAM's own error text, e.g. the faillock lockout
        property bool leaving: false  // accepted: the surfaces play the exit, then unlockT releases the lock
        property bool caps: false
        property bool num: false
        property string layout: ""
        readonly property double since: Date.now()
        readonly property bool busy: pam.active

        function submit() {
            if (!buffer || pam.active || leaving) return;
            note = "";
            pam.start();
        }
        function type(s) { buffer += s; fail = false; }
        function refreshKeys() { kbdT.restart(); }
    }

    PamContext {
        id: pam
        config: "lock"
        configDirectory: Quickshell.shellPath("pam")
        onResponseRequiredChanged: if (pam.responseRequired) pam.respond(gate.buffer)
        onPamMessage: if (pam.messageIsError) gate.note = pam.message.trim()
        onCompleted: res => {
            gate.buffer = "";
            if (res === PamResult.Success) {
                gate.leaving = true;
                unlockT.start();
            } else {
                gate.fail = true;
                gate.fails++;
            }
        }
    }
    // the surfaces rev the needle to the stop and fade out (~800 ms), then the session is unlocked
    Timer { id: unlockT; interval: 850; onTriggered: lock.locked = false }

    // caps lock and layout come from Hyprland; read after a key changes them, and on every layout switch
    Process {
        id: kbd
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const ks = JSON.parse(text).keyboards;
                    const k = ks.find(x => x.main) ?? ks[0];
                    gate.caps = ks.some(x => x.capsLock);
                    gate.num = ks.some(x => x.numLock);
                    if (k) gate.layout = k.active_keymap.slice(0, 2).toLowerCase();
                } catch (e) {}
            }
        }
    }
    Timer { id: kbdT; interval: 60; onTriggered: kbd.running = true }
    Component.onCompleted: kbd.running = true
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "activelayout") gate.refreshKeys(); }
    }

    // After suspend Hyprland re-adds the keyboard but never sends keyboard enter to a surface that stayed mapped, so the field
    // would be drawn and get no keys. A surface created after resume gets focus again. Only the surface is rebuilt: the process
    // and the session lock stay up, so the screen never shows Hyprland's "lock died" fallback.
    function makeSurface() {
        return Qt.createQmlObject('import QtQuick; import "lock"; Component { LockSurface { auth: gate } }',
                                  shell, Qt.resolvedUrl("lock.qml"));
    }
    property Component surfaceComp: makeSurface()

    // timers do not tick while suspended but the wall clock keeps going: a jump between ticks means the machine just woke up
    property double lastTick: Date.now()
    Timer {
        running: true; repeat: true; interval: 1000
        onTriggered: {
            const now = Date.now();
            if (now - shell.lastTick > 4000) rebuildT.restart();
            shell.lastTick = now;
        }
    }
    Timer {
        id: rebuildT
        interval: 1500 // give the keyboard time to come back before the new surface asks for focus
        onTriggered: {
            shell.surfaceComp = shell.makeSurface();
            gate.refreshKeys();
        }
    }

    WlSessionLock {
        id: lock
        locked: true
        surface: shell.surfaceComp

        // secure: the compositor shows our surfaces on every output. It drops after locked = false, and then we are done
        property bool wasSecure: false
        onSecureChanged: {
            if (secure) {
                wasSecure = true;
                Quickshell.execDetached(["touch", shell.marker]);
            } else if (wasSecure) {
                Quickshell.execDetached(["rm", "-f", shell.marker]);
                Qt.quit();
            }
        }
    }
}
