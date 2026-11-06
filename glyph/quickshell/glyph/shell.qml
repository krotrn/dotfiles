import QtQuick
import Quickshell
import Quickshell.Hyprland
import "bar"
import "buds"
import "cal"
import "charms"
import "cheat"
import "clip"
import "control"
import "deck"
import "glyph"
import "home"
import "launcher"
import "power"
import "prefs"
import "quick"
import "settings"
import "shot"
import "vpn"
import "wall"

// glyph: a rice in the spirit of nothing os. Home on the wallpaper, bar, launcher, quick settings,
// Glyph strips at the edges instead of OSD, notification island, power menu, settings, deck (dashboard from the bottom), clipboard, charms (emoji and symbols), screenshots, vpn, wallpapers. The lock is a separate process (lock.qml).
// Switches from demonshot via `rice switch` / the Rice app — the hypr binds are shared (shell:*), each shell takes its own
ShellRoot {
    id: shell

    Launcher { id: launcher; onPowerRequested: item => power.open(item) }
    Quick { id: quick; onPowerRequested: power.open(); onSettingsRequested: prefs.open() }
    Power { id: power }
    Prefs { id: prefs; onWallRequested: walls.open() }
    Glyph {}
    Buds {}
    Cal { id: cal }
    Clip { id: clip }
    Charms { id: charms }
    Deck { id: deck }
    Shot { id: shot }
    Vpn { id: vpn }
    OVpn { id: ovpn }
    Cheat { id: cheat }
    Walls { id: walls }
    Control {}
    Connections {
        target: Actions
        function onSettingsRequested() { prefs.open(); }
        function onWallRequested() { walls.open(); }
    }

    Variants {
        model: Quickshell.screens
        Scope {
            id: s
            required property var modelData
            Back { screen: s.modelData }
            Home { screen: s.modelData }
            Hot { screen: s.modelData; onTriggered: quick.peek() }
            Bar {
                screen: s.modelData
                onMarkClicked: launcher.toggle()
                onTrayClicked: quick.toggle()
                onPowerClicked: power.visible ? power.close() : power.open()
                onClockClicked: cal.toggle()
            }
        }
    }

    // hypr as in demonshot: its Rules (settings/Rules.qml, the same ~/.config/demonshot/rules.json) set the monitor, input,
    // motion, night light and hypridle; on top Theme.apply — own border colors, rounding and kitty. We also call it when the theme changes
    Component.onCompleted: {
        hypr();
        if (Theme.state.paint) Theme.apps(); // rice start installs links to term/ — the color must be restored
        Rules.night();
        Rules.idle();
    }
    // what lives in the hypr config. Hyprland rereads it by itself: any hypr file was saved (the links are live — both git pull and a branch
    // switch), hyprctl reload — and it returns the defaults of variables.lua: demonshot borders, monitor, input, animations. We apply
    // our own again. hyprctl eval does not send configreloaded — there is no loop. Night light and hypridle are their own processes, reload does not touch them
    function hypr() {
        Rules.monitor();
        Rules.input();
        Rules.motion();
        Theme.apply();
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "configreloaded") shell.hypr(); }
    }
    Connections {
        target: Theme
        function onGreysChanged() { paint.restart(); }
    }
    // theme or color changed (style, new wallpaper) — windows, kitty, gtk and qt. After 300 ms: the tones of a new wallpaper do not arrive at once,
    // and gtk should not be poked twice
    Timer { id: paint; interval: 300; onTriggered: { Theme.apply(); Theme.apps(); } }
    // wallpaper tones (Theme.pick) — here, not in Theme: it is also loaded by the lock, which makes do with the ready ones from glyph.json. Empty — the wallpaper copy did not
    // load (greys give 16 colors): the old tones stay. A new wallpaper — from the first tone
    ColorQuantizer {
        source: Theme.url(Theme.wallSrc(Theme.state.wall))
        depth: 4
        rescaleSize: 64
        onColorsChanged: {
            if (!colors.length) return;
            const t = Theme.pick(colors);
            if (t.join() === Theme.state.tones.join()) return;
            Theme.state.tones = t;
            Theme.state.paintAt = 0;
        }
    }
    Connections {
        target: Theme.state
        function onRoundingChanged() { Theme.apply(); }
    }
    // ultra mode turns blur and shadows on/off on top of the settings — recolor windows (hertz and motion are set by Rules.setMode itself).
    // Game mode — the same plus animations
    Connections {
        target: Rules.store
        function onUltraChanged() { Theme.apply(); }
        function onGameChanged() { Rules.motion(); Theme.apply(); }
    }

    // Super tap — the launcher on release; any Super+<key> along the way sends an interrupt, and the launcher does not open
    property bool interrupted: false
    Shortcut {
        name: "launcher"
        description: "launcher (Super tap)"
        onReleased: {
            if (!shell.interrupted) launcher.toggle();
            shell.interrupted = false;
        }
    }
    Shortcut { name: "launcherArm"; description: "Super press — reset interrupt"; onPressed: shell.interrupted = false }
    Shortcut { name: "launcherInterrupt"; description: "Super+<key> — do not open the launcher"; onPressed: shell.interrupted = true }
    // Super+Space (altar in demonshot) — deck, the bottom dashboard: the launcher is already on the Super tap
    Shortcut { name: "altar"; description: "deck: bottom dashboard"; onPressed: deck.toggle() }
    Shortcut { name: "quick"; description: "quick settings"; onPressed: quick.toggle() }
    Shortcut { name: "ward"; description: "quick settings"; onPressed: quick.toggle() } // Super+N in demonshot — the same toggles
    Shortcut { name: "settings"; description: "settings"; onPressed: prefs.toggle() }
    Shortcut { name: "power"; description: "power menu"; onPressed: power.visible ? power.close() : power.open() }
    Shortcut { name: "shot"; description: "screenshot"; onPressed: shot.open() }
    Shortcut { name: "pact"; description: "vpn: clash verge"; onPressed: vpn.toggle() }
    Shortcut { name: "ovpn"; description: "vpn: networkmanager"; onPressed: ovpn.toggle() }
    Shortcut { name: "cheat"; description: "keybind cheatsheet"; onPressed: cheat.toggle() }
    Shortcut { name: "clip"; description: "clipboard"; onPressed: clip.toggle() }
    Shortcut { name: "charms"; description: "emoji, kaomoji, symbols"; onPressed: charms.toggle() }
    Shortcut { name: "wall"; description: "wallpapers"; onPressed: walls.toggle() }
    Shortcut { name: "game"; description: "game mode"; onPressed: Rules.store.game = !Rules.store.game }

    component Shortcut: GlobalShortcut { appid: "shell" }
}
