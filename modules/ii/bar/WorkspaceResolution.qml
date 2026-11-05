import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property color contentColor: Appearance.colors.colOnLayer1
    property bool contentColorOverridden: false
    readonly property var choices: [
        { label: "3840×1440", mode: "3840x1440@165" },
        { label: "2560×1440", mode: "2560x1440@165" },
        { label: "1920×1080", mode: "1920x1080@165" }
    ]
    readonly property bool compact: (root.QsWindow.window?.screen?.width ?? 3840) <= 1920

    visible: root.QsWindow.window?.screen?.name === "DP-2"
    implicitWidth: visible ? (compact ? compactButton.implicitWidth : controls.implicitWidth) + 8 : 0
    implicitHeight: Appearance.sizes.barHeight

    Rectangle {
        id: compactButton
        visible: root.compact
        anchors.centerIn: parent
        implicitWidth: compactLabel.implicitWidth + 16
        implicitHeight: 24
        radius: Appearance.rounding.full
        color: compactHover.containsMouse || modePopup.visible
            ? Appearance.colors.colLayer1Hover : "transparent"

        StyledText {
            id: compactLabel
            anchors.centerIn: parent
            text: `WS ${WorkspaceResolutionService.currentWorkspaceId || "–"} · `
                + (WorkspaceResolutionService.currentOverride.split("x")[0] || "Default")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.contentColor
        }
        MouseArea {
            id: compactHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: modePopup.visible = !modePopup.visible
        }
    }

    PopupWindow {
        id: modePopup
        visible: false
        color: "transparent"
        implicitWidth: popupBody.implicitWidth + 16
        implicitHeight: popupBody.implicitHeight + 16
        anchor {
            window: root.QsWindow.window
            item: compactButton
            gravity: Config.options.bar.bottom ? Edges.Top : Edges.Bottom
            edges: Config.options.bar.bottom ? Edges.Top : Edges.Bottom
        }
        HyprlandFocusGrab {
            active: modePopup.visible
            windows: [modePopup]
            onCleared: modePopup.visible = false
        }
        Rectangle {
            id: popupBody
            anchors.centerIn: parent
            implicitWidth: popupChoices.implicitWidth + 24
            implicitHeight: popupChoices.implicitHeight + 20
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: popupChoices
                anchors.centerIn: parent
                spacing: 4
                StyledText {
                    text: `Workspace ${WorkspaceResolutionService.currentWorkspaceId || "–"}`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.contentColor
                }
                Repeater {
                    model: root.choices
                    delegate: Rectangle {
                        id: popupChoice
                        required property var modelData
                        readonly property bool selected: WorkspaceResolutionService.currentOverride === modelData.mode
                        implicitWidth: 125
                        implicitHeight: 30
                        radius: Appearance.rounding.small
                        color: selected ? Appearance.colors.colPrimaryContainer
                            : popupMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                        StyledText {
                            anchors.centerIn: parent
                            text: popupChoice.modelData.label
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: popupChoice.selected ? Appearance.colors.colOnPrimaryContainer : root.contentColor
                        }
                        MouseArea {
                            id: popupMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                WorkspaceResolutionService.toggle(popupChoice.modelData.mode)
                                modePopup.visible = false
                            }
                        }
                    }
                }
                StyledText {
                    text: "Click selected mode again for Default"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.contentColor
                }
            }
        }
    }

    RowLayout {
        id: controls
        visible: !root.compact
        anchors.centerIn: parent
        spacing: 5

        StyledText {
            text: `WS ${WorkspaceResolutionService.currentWorkspaceId || "–"}`
                + (WorkspaceResolutionService.currentOverride ? "" : " · Default")
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.contentColor
            Layout.rightMargin: 3
        }

        Repeater {
            model: root.choices
            delegate: Rectangle {
                id: choice
                required property var modelData
                readonly property bool selected: WorkspaceResolutionService.currentOverride === modelData.mode
                implicitWidth: label.implicitWidth + 12
                implicitHeight: 24
                radius: Appearance.rounding.full
                color: selected ? Appearance.colors.colPrimaryContainer
                    : hover.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

                StyledText {
                    id: label
                    anchors.centerIn: parent
                    text: choice.modelData.label
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: choice.selected ? Appearance.colors.colOnPrimaryContainer : root.contentColor
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WorkspaceResolutionService.toggle(choice.modelData.mode)
                }
            }
        }
    }
}
