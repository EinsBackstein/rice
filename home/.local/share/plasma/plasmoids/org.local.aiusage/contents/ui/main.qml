import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string cmd: "bash -lc 'ai-usage json'"
    property var providers: []
    property real generated: 0
    property var active: []
    property real nowSec: Date.now() / 1000

    Timer { interval: 10000; running: true; repeat: true; onTriggered: root.nowSec = Date.now() / 1000 }

    // Highest "5h" usage across providers, for the panel label.
    function worst(wid) {
        var m = -1
        for (var i = 0; i < providers.length; i++)
            for (var j = 0; j < providers[i].windows.length; j++) {
                var w = providers[i].windows[j]
                if (w.id === wid && w.pct !== null && w.pct > m) m = w.pct
            }
        return m
    }
    function pctColor(p) {
        return p < 60 ? Kirigami.Theme.positiveTextColor
             : p < 85 ? Kirigami.Theme.neutralTextColor
             : Kirigami.Theme.negativeTextColor
    }
    function dur(secs) {
        secs = Math.max(0, Math.floor(secs))
        var d = Math.floor(secs / 86400), h = Math.floor(secs % 86400 / 3600), m = Math.floor(secs % 3600 / 60)
        return d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m"
    }

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: [root.cmd]
        interval: 15000
        onNewData: (source, data) => {
            try {
                var j = JSON.parse(data["stdout"])
                root.providers = j.providers
                root.generated = j.generated
                root.active = j.active || []
                root.nowSec = Date.now() / 1000
            } catch (e) { }
        }
    }

    function mins(a) { return Math.max(0, Math.floor((nowSec - a.since) / 60)) }
    function toolName(t) { return t === "claude" ? "Claude" : t === "codex" ? "Codex" : t === "opencode" ? "OpenCode" : t }

    toolTipMainText: active.length > 0 ? "AI working: " + active.map(function (a) { return toolName(a.tool) + " " + mins(a) + " min" }).join(", ") : "AI usage"
    toolTipSubText: providers.map(function (p) {
        return p.name + ": " + p.windows.map(function (w) {
            return w.id + " " + (w.pct === null ? "?" : Math.round(w.pct) + "%")
        }).join("  ")
    }).join("\n")

    compactRepresentation: MouseArea {
        onClicked: root.expanded = !root.expanded
        Layout.minimumWidth: label.implicitWidth + (root.active.length > 0 ? activeRow.implicitWidth + Kirigami.Units.smallSpacing : 0) + Kirigami.Units.largeSpacing * 2
        Row {
            id: activeRow
            visible: root.active.length > 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Kirigami.Units.smallSpacing
            spacing: 4
            Rectangle {
                width: 8; height: 8; radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: Kirigami.Theme.highlightColor
                SequentialAnimation on opacity {
                    running: root.active.length > 0
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                }
            }
            PlasmaComponents.Label {
                text: root.active.length > 0 ? root.mins(root.active[0]) + "m" + (root.active.length > 1 ? " +" + (root.active.length - 1) : "") : ""
                color: Kirigami.Theme.highlightColor
                font.weight: Font.DemiBold
            }
        }
        PlasmaComponents.Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Kirigami.Units.smallSpacing
            text: {
                var a = root.worst("5h"), b = root.worst("7d")
                return (a < 0 ? "–" : Math.round(a) + "%") + " · " + (b < 0 ? "–" : Math.round(b) + "%")
            }
            color: root.worst("5h") < 0 ? Kirigami.Theme.textColor : root.pctColor(root.worst("5h"))
            font.weight: Font.DemiBold
        }
    }

    fullRepresentation: Item {
      Layout.minimumWidth: Kirigami.Units.gridUnit * 18
      Layout.minimumHeight: Kirigami.Units.gridUnit * 10
      implicitWidth: Kirigami.Units.gridUnit * 20
      implicitHeight: Kirigami.Units.gridUnit * 28
      PlasmaComponents.ScrollView {
       anchors.fill: parent
       contentWidth: availableWidth
       ColumnLayout {
        width: parent.width - Kirigami.Units.largeSpacing * 2
        x: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Repeater {
            model: root.active
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: Kirigami.Theme.highlightColor
                    SequentialAnimation on opacity {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                    }
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.toolName(modelData.tool) + " · " + modelData.project + (modelData.name ? " · " + modelData.name : "")
                    font.weight: Font.DemiBold
                }
                PlasmaComponents.Label {
                    text: "running " + root.mins(modelData) + " min"
                    color: Kirigami.Theme.highlightColor
                }
            }
        }
        Repeater {
            model: root.providers
            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Heading {
                    level: 3
                    text: modelData.name + (modelData.plan ? "  (" + modelData.plan + ")" : "")
                }
                PlasmaComponents.Label {
                    visible: modelData.windows.length === 0
                    text: modelData.note
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    Layout.fillWidth: true
                }
                Repeater {
                    model: modelData.windows
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            PlasmaComponents.Label { text: modelData.label; Layout.fillWidth: true }
                            PlasmaComponents.Label {
                                text: modelData.pct === null ? "?" : modelData.pct.toFixed(0) + "%"
                                color: modelData.pct === null ? Kirigami.Theme.textColor : root.pctColor(modelData.pct)
                                font.weight: Font.DemiBold
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 8
                            radius: 4
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                            Rectangle {
                                width: parent.width * Math.min(100, modelData.pct === null ? 0 : modelData.pct) / 100
                                height: parent.height
                                radius: 4
                                color: modelData.pct === null ? "transparent" : root.pctColor(modelData.pct)
                            }
                        }
                        PlasmaComponents.Label {
                            text: modelData.resets_at ? "resets in " + root.dur(modelData.resets_at - Date.now() / 1000) : "window idle"
                            opacity: 0.6
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
       }
      }
    }
}
