import QtQuick
import Quickshell
import Quickshell.Io

// outside control: `glyph <target> <function> [args]` (bin/glyph) calls these through qs ipc
Scope {
    IpcHandler {
        target: "theme"
        function wall(path: string): string { return Actions.setWall(path); }
        function randomWall(): string { return Actions.randomWall(); }
        function source(name: string): string { return Actions.setSource(name); }
        function custom(hex: string): string { return Actions.setCustom(hex); }
        function variant(id: string): string { return Actions.setVariant(id); }
        function scheme(id: string): string { return Actions.setScheme(id); }
        function tone(i: int): string { return Actions.setTone(i); }
        function light(mode: string): string { return Actions.setLight(mode); }
    }
    IpcHandler {
        target: "shell"
        function run(name: string): string { return Actions.run(name); }
        function actions(): string { return Actions.list.map(a => a.hint ? `${a.name}\t${a.hint}` : a.name).join("\n"); }
    }
    IpcHandler {
        target: "toast"
        function set(key: string, state: string): string {
            if (state !== "on" && state !== "off") return "toast: on or off";
            return Actions.setToast(key, state === "on");
        }
        function list(): string { return Actions.toastList(); }
    }
    IpcHandler {
        target: "battery"
        function levels(warn: int, crit: int): string { return Actions.setBatteryLevels(warn, crit); }
        function get(): string { return Actions.batteryLevels(); }
    }
}
