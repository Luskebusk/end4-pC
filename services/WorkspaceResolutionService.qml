pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common

Singleton {
    id: root

    readonly property string monitorName: "DP-2"
    readonly property string statePath: `${Quickshell.env("XDG_RUNTIME_DIR")}/workspace-resolution-overrides.json`
    property var overrides: ({})
    property bool stateReady: false
    property int currentWorkspaceId: 0
    property string defaultMode: "3840x1440@165"
    readonly property string currentOverride: overrides[String(currentWorkspaceId)] ?? ""
    property string pendingMode: ""

    function readDefault() {
        const block = monitorConfig.text().split("hl.monitor({")
            .find(part => /output\s*=\s*["']DP-2["']/.test(part.split("})")[0]));
        const match = block?.match(/mode\s*=\s*["']([^"']+)["']/);
        if (match) root.defaultMode = match[1];
    }

    function sameMode(monitor, mode) {
        const match = mode.match(/^(\d+)x(\d+)@([\d.]+)/);
        return match && monitor.width === Number(match[1])
            && monitor.height === Number(match[2])
            && Math.abs(monitor.refreshRate - Number(match[3])) < 1;
    }

    function applyForMonitor(monitor) {
        if (!root.stateReady || !monitor?.activeWorkspace?.id) return;
        root.currentWorkspaceId = monitor.activeWorkspace.id;
        const wanted = root.currentOverride || root.defaultMode;
        if (!wanted || root.sameMode(monitor, wanted)) return;
        root.pendingMode = wanted;
        if (!applyProc.running) root.startApply();
    }

    function startApply() {
        if (!root.pendingMode || applyProc.running) return;
        const mode = root.pendingMode;
        root.pendingMode = "";
        if (!/^\d+x\d+@[\d.]+$/.test(mode)) return;
        applyProc.command = ["hyprctl", "eval",
            `hl.monitor({ output = "${root.monitorName}", mode = "${mode}", position = "0x0", scale = 1 })`];
        applyProc.running = true;
    }

    function toggle(mode) {
        if (!root.stateReady || root.currentWorkspaceId <= 0) return;
        if (!["3840x1440@165", "2560x1440@165", "1920x1080@165"].includes(mode)) return;
        const key = String(root.currentWorkspaceId);
        const updated = Object.assign({}, root.overrides);
        if (updated[key] === mode) delete updated[key];
        else updated[key] = mode;
        root.overrides = updated;
        stateFile.setText(JSON.stringify(updated));
        refreshTimer.restart();
    }

    FileView {
        id: stateFile
        path: root.statePath
        printErrors: false
    }

    FileView {
        id: monitorConfig
        path: `${Quickshell.env("HOME")}/.config/hypr/monitors.lua`
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.readDefault();
            refreshTimer.restart();
        }
        onFileChanged: reload()
    }

    Process {
        id: loadState
        command: ["python3", "-c",
            "import pathlib,sys; p=pathlib.Path(sys.argv[1]); print(p.read_text() if p.exists() else '{}')",
            root.statePath]
        running: WM.compositor === "hyprland"
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.overrides = data && typeof data === "object" && !Array.isArray(data) ? data : ({});
                } catch (error) {
                    root.overrides = ({});
                }
                root.stateReady = true;
                refreshTimer.restart();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (WM.compositor !== "hyprland" || !root.stateReady) return;
            if (monitorQuery.running) root.queryPending = true;
            else monitorQuery.running = true;
        }
    }
    property bool queryPending: false

    Connections {
        target: Hyprland
        enabled: WM.compositor === "hyprland"
        function onRawEvent(event) {
            if (event.name.startsWith("workspace") || event.name === "focusedmon"
                    || event.name === "configreloaded" || event.name.startsWith("moveworkspace"))
                refreshTimer.restart();
        }
    }

    Process {
        id: monitorQuery
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const monitor = JSON.parse(text).find(m => m.name === root.monitorName);
                    if (monitor) root.applyForMonitor(monitor);
                } catch (error) {
                    console.warn("[WorkspaceResolution] Could not read monitors:", error);
                }
            }
        }
        onExited: {
            if (root.queryPending) {
                root.queryPending = false;
                refreshTimer.restart();
            }
        }
    }

    Process {
        id: applyProc
        onExited: {
            if (root.pendingMode) root.startApply();
            else refreshTimer.restart();
        }
    }
}
