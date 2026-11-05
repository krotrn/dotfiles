import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// "home screen" on the bottom layer, transparent: a Doto clock, a greeting and the widget bento. The grid, orb and wallpaper are under it, in Back.
// When a window opens — everything goes under it by itself. System polling and animations — only while the workspace is empty
PanelWindow {
    id: root

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "glyph-home"

    readonly property bool home: (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) === 0
    Binding { target: SysStats; property: "detailed"; value: root.home || Sys.deckOpen }
    // not in the delegate: a destroyed Binding returns no value — remove a widget and cava would run forever
    Binding { target: Cava; property: "active"; value: root.home && bento.model.some(w => w.id === "cava") }
    // the development widgets are polled only while one of them is on screen
    Binding { target: Dev; property: "active"; value: root.home && bento.model.some(w => ["projects", "git", "docker", "ports", "commits", "heat", "tools", "prs"].includes(w.id)) }

    // a slow beat for the little "live" dots of the dev widgets (two states, the opacity eases between them)
    property bool breathe: false
    Timer { running: root.home; interval: 1200; repeat: true; onTriggered: root.breathe = !root.breathe }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var en: Qt.locale("en_US")

    // blinking colon — two frames a second, not an animation on every vsync
    property bool dim: false
    Timer { running: root.home && Theme.state.blink; interval: 500; repeat: true; onTriggered: root.dim = !root.dim }

    readonly property var player: Media.player
    readonly property var buds: Bluetooth.devices.values.find(d => d.connected && d.batteryAvailable) ?? null
    property var hist: [] // cpu over a minute: 34 matrix columns
    Connections {
        target: SysStats
        function onCpuChanged() { root.hist = root.hist.concat([SysStats.cpu]).slice(-34); }
    }

    function week(d) { // ISO week
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
    }
    readonly property string hello: { const h = clock.date.getHours(); return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"; }

    Stage {
        id: stage
        k: Theme.bs // the home screen fills the whole screen: it follows the screen size, not the global panel size (Theme.uiScale)
        x: Theme.state.barAt === "top" ? -39 * Theme.bs : 0 // layout under the bar on the left; bar on top — half its width to the left, centered

        Row {
            x: 182
            y: 150
            Num { text: Theme.hh(clock.date); font.pixelSize: 300 }
            Num { text: ":"; font.pixelSize: 300; opacity: Theme.state.blink && root.dim ? 0.2 : 1 }
            Num { text: Qt.formatTime(clock.date, "mm"); font.pixelSize: 300 }
        }
        Lb {
            x: 190
            y: 448
            text: `${root.en.toString(clock.date, "dddd · d MMMM")} · week ${root.week(clock.date)}`
            px: 14
        }
        Text {
            x: 188
            y: 560
            textFormat: Text.StyledText
            text: `${root.hello},<br><font color="${Theme.grey}">${Theme.state.name || Quickshell.env("USER")}.</font>`
            font { family: Theme.ui; pixelSize: 54; weight: Font.Light; letterSpacing: -1 }
            lineHeight: 1.1
            color: Theme.fg
        }
        Row {
            x: 190
            y: 700
            spacing: 28
            Meta { icon: "\u{F009A}"; text: `${Notes.list.length} notifications` }
            Meta { visible: Weather.ok; icon: Weather.glyph(Weather.now?.code ?? 0, Weather.now?.day); text: `${Math.round(Weather.now?.temp ?? 0)}° ${Weather.name(Weather.now?.code)}` }
            Meta { visible: !!root.buds; icon: "\u{F02CB}"; text: `${root.buds?.name ?? ""} · ${Math.round((root.buds?.battery ?? 0) * 100)}%` }
        }

        // bento: cells 220, gap 20, a Theme.homeCols × Theme.homeRows grid. Which widgets and in which order — Theme.state.widgets (settings), widths —
        // Theme.kinds. Laid left to right: if it does not fit in the row — from the next one, if the page is full — on the next page (Theme.pack).
        // Pages: the dots under the bento or the mouse wheel over it switch them. Same layout as the settings editor (prefs pack)
        // A square with rounding 40 or a circle — there are no other shapes
        property int page: 0
        readonly property var packed: Theme.pack((Theme.state.widgets ?? []).filter(id => Theme.kinds[id])).map(c => ({ id: c.id, page: c.page, x: 975 + c.col * 240, y: 55 + c.row * 240 }))
        readonly property int pages: Math.max(1, ...packed.map(p => p.page + 1))
        readonly property int pg: Math.min(page, pages - 1)

        Item {
            x: 975
            y: 55
            width: 940
            height: 940
            WheelHandler { onWheel: e => stage.page = Math.max(0, Math.min(stage.pages - 1, stage.pg + (e.angleDelta.y < 0 ? 1 : -1))) }
        }
        Row {
            visible: stage.pages > 1
            x: 1445 - width / 2
            y: 1008
            spacing: 12
            Repeater {
                model: stage.pages
                Rectangle {
                    required property int index
                    width: index === stage.pg ? 28 : 8
                    height: 8
                    radius: 4
                    color: index === stage.pg ? Theme.fg : Theme.s3
                    Behavior on width { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                    Behavior on color { ColorAnimation { duration: Theme.t } }
                    MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: stage.page = parent.index }
                }
            }
        }

        Repeater {
            id: bento
            model: stage.packed.filter(p => p.page === stage.pg)
            Loader {
                required property var modelData
                x: modelData.x
                y: modelData.y
                sourceComponent: ({ weather: weatherW, calendar: calendarW, cpu: cpuW, ram: ramW, gpu: gpuW, disk: diskW,
                                    battery: batteryW, buds: budsW, player: playerW, system: systemW, cat: catW, cava: cavaW,
                                    projects: projectsW, git: gitW, docker: dockerW, ports: portsW,
                                    commits: commitsW, heat: heatW, focus: focusW, launch: launchW, tools: toolsW, prs: prsW })[modelData.id] ?? null
            }
        }

        // ---- development (services/Dev): projects, git, docker, ports, commits, heat, focus, launch, tools, prs ----
        // recent repos with their branch and uncommitted changes (the dot is lit and breathes when there are some); a click opens the project in VS Code.
        // The rows slide in one after another; numbers count up (Count)
        Component {
            id: projectsW
            W {
                id: pw
                span: 2
                property bool showHidden: false
                readonly property bool listing: showHidden && Dev.hidden.length > 0
                Lb { x: 28; y: 22; text: `projects · ${Dev.projects.length}`; px: 11 }
                Lb { visible: !Dev.hidden.length; anchors { right: parent.right; rightMargin: 28 } y: 23; text: "right-click hides"; px: 8; opacity: 0.45 }
                // the chip: how many are hidden; a click lists them, a click on one shows it again
                Rectangle {
                    visible: Dev.hidden.length > 0
                    anchors { right: parent.right; rightMargin: 20 }
                    y: 16
                    width: chipT.width + 24
                    height: 24
                    radius: 12
                    color: pw.listing ? Theme.fg : chipH.hovered ? Theme.s3 : Theme.s2
                    Behavior on color { ColorAnimation { duration: Theme.t } }
                    Lb { id: chipT; anchors.centerIn: parent; text: pw.listing ? "back" : `hidden · ${Dev.hidden.length}`; px: 9; color: pw.listing ? Theme.ink : Theme.fg }
                    HoverHandler { id: chipH; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: pw.showHidden = !pw.showHidden }
                }
                Column {
                    visible: !pw.listing
                    x: 20
                    y: 52
                    width: parent.width - 40
                    spacing: 2
                    Repeater {
                        model: Dev.projects.slice(0, 4)
                        Rise {
                            id: pr
                            required property var modelData
                            required property int index
                            slot: index
                            width: parent.width
                            height: 32
                            radius: 16
                            color: ph.hovered ? Theme.s2 : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.t } }
                            HoverHandler { id: ph; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Quickshell.execDetached(["code", pr.modelData.path]) }
                            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Dev.ignore(pr.modelData.name) }
                            Rectangle {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                radius: 4
                                color: pr.modelData.dirty ? Theme.accent : Theme.s3
                                opacity: pr.modelData.dirty && !root.breathe ? 0.4 : 1
                                Behavior on opacity { NumberAnimation { duration: 1000 } }
                            }
                            Text {
                                x: 28
                                anchors.verticalCenter: parent.verticalCenter
                                width: 170
                                elide: Text.ElideRight
                                text: pr.modelData.name
                                color: Theme.fg
                                font { family: Theme.ui; pixelSize: 15; weight: Font.DemiBold }
                            }
                            Lb {
                                x: 206
                                anchors.verticalCenter: parent.verticalCenter
                                width: 150
                                elide: Text.ElideRight
                                text: pr.modelData.branch + (pr.modelData.dirty ? ` · ${pr.modelData.dirty}±` : "")
                                px: 9
                            }
                            Lb { anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } text: Dev.ago(pr.modelData.ts); px: 9 }
                        }
                    }
                }
                Column {
                    visible: pw.listing
                    x: 20
                    y: 52
                    width: parent.width - 40
                    spacing: 2
                    Repeater {
                        model: Dev.hidden.slice(0, 4)
                        Rise {
                            id: hr
                            required property string modelData
                            required property int index
                            slot: index
                            width: parent.width
                            height: 32
                            radius: 16
                            color: hh.hovered ? Theme.s2 : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.t } }
                            HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Dev.unignore(hr.modelData) }
                            Text {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 300
                                elide: Text.ElideRight
                                text: hr.modelData.split("/").pop()
                                color: Theme.grey
                                font { family: Theme.ui; pixelSize: 15 }
                            }
                            Lb { anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter } text: "show again"; px: 9; color: Theme.fg }
                        }
                    }
                }
            }
        }
        // the most recently committed repo: uncommitted changes as a counting number and a segment scale; a click opens lazygit there
        Component {
            id: gitW
            W {
                readonly property var p: Dev.projects[0] ?? null
                property real fill: p ? Math.min(1, p.dirty / 20) : 0
                Behavior on fill { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
                Lb { x: 24; y: 22; text: "git"; px: 11 }
                Count { x: 24; y: 40; v: p ? p.dirty : 0; font.pixelSize: 90 }
                Seg { x: 24; y: 138; width: parent.width - 48; height: 5; n: 20; f: parent.fill }
                Lb { x: 24; y: 150; text: "uncommitted"; px: 10 }
                Text {
                    x: 24
                    y: 168
                    width: parent.width - 48
                    elide: Text.ElideRight
                    text: p ? p.name : "no repo"
                    color: Theme.fg
                    font { family: Theme.ui; pixelSize: 16; weight: Font.DemiBold }
                }
                Lb { x: 24; y: 192; width: parent.width - 48; elide: Text.ElideRight; text: p ? p.branch : ""; px: 9 }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: if (parent.p) Quickshell.execDetached(["wezterm", "start", "--cwd", parent.p.path, "--", "lazygit"]) }
            }
        }
        // running containers: a dot for each, breathing
        Component {
            id: dockerW
            W {
                Lb { x: 24; y: 22; text: "docker"; px: 11 }
                Row {
                    anchors { right: parent.right; rightMargin: 24 }
                    y: 26
                    spacing: 5
                    Repeater {
                        model: 6
                        Rectangle {
                            required property int index
                            readonly property bool lit: index < Dev.containers.length
                            width: 8
                            height: 8
                            radius: 4
                            color: lit ? Theme.accent : Theme.s3
                            opacity: lit && !root.breathe ? 0.4 : 1
                            Behavior on opacity { NumberAnimation { duration: 1000 } }
                        }
                    }
                }
                Count { x: 24; y: 40; v: Dev.containers.length; visible: Dev.dockerUp; font.pixelSize: 90 }
                Num { x: 24; y: 40; visible: !Dev.dockerUp; text: "off"; font.pixelSize: 90 }
                Lb { x: 24; y: 148; text: Dev.dockerUp ? "running" : "daemon down"; px: 10 }
                Text {
                    x: 24
                    y: 168
                    width: parent.width - 48
                    elide: Text.ElideRight
                    text: Dev.containers[0]?.name ?? ""
                    color: Theme.fg
                    font { family: Theme.ui; pixelSize: 16; weight: Font.DemiBold }
                }
                Lb { x: 24; y: 192; width: parent.width - 48; elide: Text.ElideRight; text: Dev.containers[0]?.status ?? ""; px: 9 }
            }
        }
        // dev servers listening on this machine; a click on a port opens it in the browser
        Component {
            id: portsW
            W {
                Lb { x: 24; y: 22; text: "ports"; px: 11 }
                Count { x: 24; y: 40; v: Dev.ports.length; font.pixelSize: 90 }
                Lb { x: 24; y: 148; text: "listening"; px: 10 }
                Column {
                    x: 14
                    y: 164
                    width: parent.width - 28
                    Repeater {
                        model: Dev.ports.slice(0, 2)
                        Rise {
                            id: pt
                            required property var modelData
                            required property int index
                            slot: index
                            width: parent.width
                            height: 28
                            radius: 14
                            color: th.hovered ? Theme.s2 : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.t } }
                            HoverHandler { id: th; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Qt.openUrlExternally(`http://localhost:${pt.modelData.port}`) }
                            Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: `:${pt.modelData.port}`; color: Theme.fg; font { family: Theme.mono; pixelSize: 14; weight: Font.DemiBold } }
                            Lb { anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } text: pt.modelData.proc; px: 9 }
                        }
                    }
                }
            }
        }
        // the latest commit of each recent repo, newest first
        Component {
            id: commitsW
            W {
                span: 2
                Lb { x: 28; y: 22; text: "latest commits"; px: 11 }
                Lb { anchors { right: parent.right; rightMargin: 28 } y: 23; text: "right-click hides"; px: 8; opacity: 0.45 }
                Column {
                    x: 20
                    y: 52
                    width: parent.width - 40
                    spacing: 2
                    Repeater {
                        model: Dev.projects.filter(p => p.subject).slice(0, 4)
                        Rise {
                            id: cm
                            required property var modelData
                            required property int index
                            slot: index
                            width: parent.width
                            height: 32
                            radius: 16
                            color: ch.hovered ? Theme.s2 : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.t } }
                            HoverHandler { id: ch; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Quickshell.execDetached(["code", cm.modelData.path]) }
                            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Dev.ignore(cm.modelData.name) }
                            Lb { x: 12; anchors.verticalCenter: parent.verticalCenter; width: 104; elide: Text.ElideRight; text: cm.modelData.name; px: 9; color: Theme.fg }
                            Text {
                                x: 124
                                anchors.verticalCenter: parent.verticalCenter
                                width: 262
                                elide: Text.ElideRight
                                text: cm.modelData.subject
                                color: Theme.grey
                                font { family: Theme.ui; pixelSize: 14 }
                            }
                            Lb { anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } text: Dev.ago(cm.modelData.ts); px: 9 }
                        }
                    }
                }
            }
        }
        // your commits for the last 17 weeks, one dot per day; the dots light up as a wave from the left
        Component {
            id: heatW
            W {
                span: 2
                Lb { x: 28; y: 20; text: `commits · ${Dev.weekCommits} this week`; px: 11 }
                Repeater {
                    model: Dev.heat
                    Rectangle {
                        id: hd
                        required property int modelData
                        required property int index
                        readonly property int col: Math.floor(index / 7)
                        readonly property real base: modelData < 0 ? 0 : modelData === 0 ? 0.5 : Math.min(1, 0.35 + modelData * 0.13)
                        property real lit: 0
                        Behavior on lit { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
                        Timer { interval: 150 + hd.col * 38; running: true; onTriggered: hd.lit = 1 }
                        x: 43 + col * 22
                        y: 50 + (index % 7) * 22
                        width: 12
                        height: 12
                        radius: 6
                        color: modelData > 0 ? Theme.fg : Theme.s3
                        opacity: base * lit
                        scale: 0.6 + 0.4 * lit
                    }
                }
            }
        }
        // the focus timer (the same one as in the calendar): a ring that fills while you work; a click starts and pauses
        Component {
            id: focusW
            W {
                round: true
                Ring { anchors { fill: parent; margins: 12 } f: Focus.f }
                Column {
                    anchors.centerIn: parent
                    Num { anchors.horizontalCenter: parent.horizontalCenter; text: Focus.mmss(Focus.left); font.pixelSize: 52 }
                    Lb { anchors.horizontalCenter: parent.horizontalCenter; topPadding: 8; text: Focus.running ? "focusing" : Focus.paused ? "paused" : "tap to focus" }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Focus.toggle() }
            }
        }
        // launchers: VS Code, a terminal, lazygit, the dev server in the browser
        Component {
            id: launchW
            W {
                span: 2
                Repeater {
                    model: [
                        { icon: "\u{F0A1E}", name: "code", cmd: ["code"] },
                        { icon: "\u{F018D}", name: "terminal", cmd: ["wezterm"] },
                        { icon: "\u{F02A2}", name: "lazygit", cmd: ["wezterm", "start", "--", "lazygit"] },
                        { icon: "\u{F059F}", name: "localhost", url: "http://localhost:3000" }
                    ]
                    Item {
                        id: lc
                        required property var modelData
                        required property int index
                        x: 12 + index * 116
                        y: 38
                        width: 88
                        height: 130
                        Rise {
                            id: lb
                            slot: lc.index
                            width: 88
                            height: 88
                            radius: 44
                            color: lh.hovered ? Theme.fg : Theme.s2
                            scale: lh.hovered ? 1.1 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.t; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: Theme.t } }
                            Icon { anchors.centerIn: parent; text: lc.modelData.icon; font.pixelSize: 36; color: lh.hovered ? Theme.ink : Theme.fg }
                            HoverHandler { id: lh; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: lc.modelData.url ? Qt.openUrlExternally(lc.modelData.url) : Quickshell.execDetached(lc.modelData.cmd) }
                        }
                        Lb { anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 102 } text: lc.modelData.name; px: 10 }
                    }
                }
            }
        }
        // the toolchain versions
        Component {
            id: toolsW
            W {
                Lb { x: 24; y: 22; text: "toolchain"; px: 11 }
                Column {
                    x: 14
                    y: 50
                    width: parent.width - 28
                    Repeater {
                        model: Dev.tools
                        Rise {
                            id: tl
                            required property var modelData
                            required property int index
                            slot: index
                            width: parent.width
                            height: 32
                            radius: 16
                            Lb { x: 10; anchors.verticalCenter: parent.verticalCenter; text: tl.modelData.name; px: 10 }
                            Text { anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } text: tl.modelData.version; color: Theme.fg; font { family: Theme.mono; pixelSize: 13; weight: Font.DemiBold } }
                        }
                    }
                }
            }
        }
        // your open GitHub pull requests and the reviews waiting for you (gh); a click opens the first one
        Component {
            id: prsW
            W {
                Lb { x: 24; y: 22; text: "github"; px: 11 }
                Count { x: 24; y: 40; v: Dev.prs.length; font.pixelSize: 90 }
                Lb { x: 24; y: 148; text: "open pull requests"; px: 10 }
                Text {
                    x: 24
                    y: 168
                    width: parent.width - 48
                    elide: Text.ElideRight
                    text: Dev.prs[0]?.title ?? "none open"
                    color: Theme.fg
                    font { family: Theme.ui; pixelSize: 16; weight: Font.DemiBold }
                }
                Lb { x: 24; y: 192; text: `${Dev.reviews} to review`; px: 9; color: Dev.reviews > 0 ? Theme.accent : Theme.grey }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Qt.openUrlExternally(Dev.prs[0]?.url ?? "https://github.com/pulls") }
            }
        }

        // weather
        Component {
            id: weatherW
            W {
                round: true
                Column {
                    anchors.centerIn: parent
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Weather.glyph(Weather.now?.code ?? 3, Weather.now?.day)
                        font.pixelSize: 78
                        layer.enabled: true
                        layer.effect: Dm { step: 4 }
                    }
                    Num { anchors.horizontalCenter: parent.horizontalCenter; topPadding: lead + 6; text: Weather.ok ? Math.round(Weather.now.temp) + "°" : "--"; font.pixelSize: 66 }
                    Lb {
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 8
                        width: Math.min(implicitWidth, 160) // chord of the circle at this height
                        elide: Text.ElideRight
                        text: Weather.ok ? `${Weather.name(Weather.now.code)} · ${Math.round(Weather.days[0]?.min)}°/${Math.round(Weather.days[0]?.max)}°` : "no sky"
                    }
                }
            }
        }

        // calendar
        Component {
            id: calendarW
            W {
                Column {
                    x: 24
                    y: 24
                    width: parent.width - 48
                    Lb { text: root.en.monthName(clock.date.getMonth()) }
                    Num { topPadding: lead + 8; text: clock.date.getDate(); font.pixelSize: 118 }
                    Row {
                        width: parent.width
                        topPadding: 14
                        Repeater {
                            model: ["M", "T", "W", "T", "F", "S", "S"]
                            Text {
                                required property string modelData
                                required property int index
                                readonly property bool today: (clock.date.getDay() + 6) % 7 === index
                                width: parent.width / 7
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                font { family: Theme.mono; pixelSize: 11 }
                                color: today ? Theme.fg : Theme.grey
                                Rectangle { visible: parent.today; anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter } width: 10; height: 2; color: Theme.fg }
                            }
                        }
                    }
                }
            }
        }

        // rings: cpu, memory, video card, disk, battery
        Component { id: cpuW; RingW { f: SysStats.cpu; value: Math.round(SysStats.cpu * 100); label: "cpu %" } }
        Component { id: ramW; RingW { f: SysStats.mem; value: Math.round(SysStats.mem * 100); label: "ram %" } }
        Component { id: gpuW; RingW { f: SysStats.gpu; value: Math.round(SysStats.gpu * 100); label: `gpu · ${Math.round(SysStats.gpuTemp)}°` } }
        Component { id: diskW; RingW { f: SysStats.disks[0]?.used ?? 0; value: Math.round((SysStats.disks[0]?.used ?? 0) * 100); label: "disk %" } }
        Component {
            id: batteryW
            RingW {
                readonly property var bat: UPower.displayDevice
                f: bat.percentage
                value: Math.round(bat.percentage * 100)
                label: bat.state === UPowerDeviceState.Charging ? "charging" : "battery"
                on: bat.state !== UPowerDeviceState.Charging && bat.percentage < 0.15 ? Theme.red : Theme.fg
            }
        }

        // player: the cover as dots spins while it plays
        Component {
            id: playerW
            W {
                span: 2
                Item {
                    id: art
                    x: 28
                    anchors.verticalCenter: parent.verticalCenter
                    width: 164
                    height: 164
                    property real turn: 0
                    Timer { running: root.home && Media.playing; interval: 33; repeat: true; onTriggered: art.turn = (art.turn + 360 / 14 / 30) % 360 }
                    Art { anchors.fill: parent; rotation: art.turn; url: root.player?.trackArtUrl ?? ""; step: 6 }
                }
                Column {
                    anchors { left: art.right; leftMargin: 26; right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }
                    Lb { text: `now playing · ${root.player?.identity ?? "silence"}`; width: parent.width; elide: Text.ElideRight }
                    Text {
                        width: parent.width
                        topPadding: 10
                        elide: Text.ElideRight
                        text: root.player?.trackTitle || "Nothing on"
                        font { family: Theme.ui; pixelSize: 26; weight: Font.DemiBold }
                        color: Theme.fg
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.player?.trackArtist ?? ""
                        font { family: Theme.ui; pixelSize: 15 }
                        color: Theme.grey
                    }
                    Item { width: 1; height: 18 }
                    Seg { width: parent.width; height: 6; n: 24; f: root.player?.lengthSupported && root.player.length > 0 ? Media.position / root.player.length : 0 } // firefox does not send the length
                    Item { width: 1; height: 16 }
                    Controls { size: 22; play: 52 }
                }
            }
        }

        // headphones as a ring; none — volume
        Component {
            id: budsW
            W {
                round: true
                Ring { anchors { fill: parent; margins: 12 } f: root.buds ? root.buds.battery : Sys.vol }
                Column {
                    anchors.centerIn: parent
                    Icon { anchors.horizontalCenter: parent.horizontalCenter; text: root.buds ? "\u{F02CB}" : "\u{F057E}"; font.pixelSize: 30 }
                    Num { anchors.horizontalCenter: parent.horizontalCenter; topPadding: lead + 8; text: Math.round((root.buds ? root.buds.battery : Sys.vol) * 100); font.pixelSize: 54 }
                    Lb {
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 6
                        width: 130
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.buds?.name ?? "volume"
                    }
                }
            }
        }

        // cat: a gif as a matrix in the theme tone through the wallpaper shader (like Wall in look 0), which one — services/Gifs, the tile itself — Gif.
        // Dances only while home is visible
        Component {
            id: catW
            W {
                id: cw
                Gif { anchors.fill: parent; playing: root.home; bg: cw.color }
            }
        }

        // cava as a matrix in a circle, like the Glyph Matrix on the back of the Nothing Phone (3): bass in the center, highs toward the edges, bars grow
        // from the middle up and down. Silence — unlit dots. cava runs only while home is visible
        Component {
            id: cavaW
            W {
                round: true
                Grid {
                    anchors.centerIn: parent
                    columns: 15
                    spacing: 4
                    Repeater {
                        model: 15 * 15
                        Rectangle {
                            required property int index
                            readonly property int cx: index % 15 - 7
                            readonly property int cy: Math.floor(index / 15) - 7
                            readonly property int half: Math.floor(Math.sqrt(7.5 * 7.5 - cx * cx)) // half the height of a column inside the circle
                            readonly property real v: Cava.bars[Math.abs(cx)] ?? 0
                            width: 8
                            height: 8
                            radius: 4
                            // outside the circle — transparent, not visible: Grid would shift the others
                            color: Math.abs(cy) > half ? "transparent" : Math.abs(cy) < v * (half + 1) ? Theme.fg : Theme.s3
                        }
                    }
                }
            }
        }

        // system: numbers and a cpu chart as a matrix
        Component {
            id: systemW
            W {
                span: 3
                Grid {
                    x: 34
                    anchors.verticalCenter: parent.verticalCenter
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 22
                    Stat { label: "cpu"; value: Math.round(SysStats.cpu * 100) + "%" }
                    Stat { label: "mem"; value: SysStats.memUsed.toFixed(1) + "G" }
                    Stat { label: "gpu"; value: Math.round(SysStats.gpuTemp) + "°" }
                    Stat { label: "disk"; value: Math.round((SysStats.disks[0]?.used ?? 0) * 100) + "%" }
                }
                Column {
                    x: 344
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - 34
                    spacing: 12
                    Lb { text: "cpu · 60 s" }
                    // the top dot of the column is white, grey under it
                    Grid {
                        id: spark
                        width: parent.width
                        columns: 34
                        spacing: 4
                        readonly property real d: (width - 33 * spacing) / 34
                        Repeater {
                            model: 34 * 8
                            Rectangle {
                                required property int index
                                readonly property int x_: index % 34
                                readonly property int up: 8 - Math.floor(index / 34) // 8 at the top … 1 at the bottom
                                readonly property int h: Math.round(1 + 6 * (root.hist[x_ - 34 + root.hist.length] ?? 0))
                                width: spark.d
                                height: spark.d
                                radius: spark.d / 2
                                color: up === h ? Theme.fg : up < h ? Theme.grey : Theme.s2
                            }
                        }
                    }
                }
            }
        }
    }

    // a number that counts up to its value
    component Count: Num {
        property real v: 0
        property real shown: v
        Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        text: Math.round(shown)
    }
    // a row that slides in and fades in, one after another (slot)
    component Rise: Rectangle {
        id: rise
        property int slot: 0
        color: "transparent"
        opacity: 0
        transform: Translate { id: shift; x: 18 }
        Component.onCompleted: enter.start()
        SequentialAnimation {
            id: enter
            PauseAnimation { duration: 120 + rise.slot * 80 }
            ParallelAnimation {
                NumberAnimation { target: rise; property: "opacity"; to: 1; duration: 380 }
                NumberAnimation { target: shift; property: "x"; to: 0; duration: 420; easing.type: Easing.OutCubic }
            }
        }
    }
    component W: Rectangle {
        property int span: 1
        property bool round
        width: span * 220 + (span - 1) * 20
        height: 220
        radius: round ? 110 : Theme.corner(40)
        color: Theme.s1
        border { width: 1; color: Theme.s2 }
    }
    // round widget: a ring of dots lit by the share f, a number and a caption in the center
    component RingW: Rectangle {
        id: rw
        property real f
        property string value
        property string label
        property color on: Theme.fg
        width: 220
        height: 220
        radius: 110
        color: Theme.s1
        border { width: 1; color: Theme.s2 }
        Ring { anchors { fill: parent; margins: 12 } f: rw.f; on: rw.on }
        Column {
            anchors.centerIn: parent
            Num { anchors.horizontalCenter: parent.horizontalCenter; text: rw.value; font.pixelSize: 72 }
            Lb { anchors.horizontalCenter: parent.horizontalCenter; topPadding: 8; text: rw.label }
        }
    }
    component Meta: Row {
        property string icon
        property string text
        spacing: 10
        Icon { anchors.verticalCenter: parent.verticalCenter; text: parent.icon; font.pixelSize: 16 }
        Lb { anchors.verticalCenter: parent.verticalCenter; text: parent.text }
    }
    component Stat: Column {
        property string label
        property string value
        width: 130
        Lb { text: parent.label }
        Num { topPadding: lead + 6; text: parent.value }
    }
}
