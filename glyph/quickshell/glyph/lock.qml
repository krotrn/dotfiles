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
        property int keyed: 0         // surfaces whose window has keyboard focus

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

    // After suspend Hyprland re-adds the keyboard but sometimes never sends keyboard enter to the lock surface that stayed
    // mapped, so the field is drawn and gets no keys (a VT switch does not bring them back either). Quickshell cannot replace a
    // surface while locked, so the whole lock exits with 75 and `rice lock` starts it again: Hyprland keeps the session locked
    // in between (allow_session_lock_restore) with the screen off, and the new surface gets the keyboard.
    // The surfaces count themselves in gate.keyed while their window has keyboard focus.
    property double lastTick: Date.now()
    Timer {
        running: true; repeat: true; interval: 1000
        onTriggered: {
            const now = Date.now();
            // timers do not tick while suspended but the wall clock keeps going: a jump means the machine just woke up
            if (now - shell.lastTick > 4000) {
                console.info(`lock: woke up, ${gate.keyed} surface(s) have the keyboard`);
                keysT.restart();
            }
            shell.lastTick = now;
        }
    }
    Timer {
        id: keysT
        interval: 4000 // the keyboard comes back within ~1 s of the wake; leave it time to send keyboard enter
        onTriggered: {
            if (gate.keyed > 0 || gate.leaving) {
                console.info("lock: keyboard is back after wake");
                gate.refreshKeys();
                return;
            }
            console.warn("lock: no keyboard 4 s after wake, restarting the lock");
            // screen off first, so Hyprland's "lock died" screen is never seen; `rice lock` turns it on with the new lock
            Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.dpms({ action = "off" })']);
            Quickshell.execDetached(["rm", "-f", shell.marker]);
            exitT.start();
        }
    }
    // DPMS off takes a moment to reach the panel, and the frame after this exit is Hyprland's "lock died" screen
    Timer { id: exitT; interval: 600; onTriggered: Qt.exit(75) }

    WlSessionLock {
        id: lock
        locked: true
        LockSurface { auth: gate }

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
