import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

KCM.SimpleKCM {
    id: page

    property string scriptPath: Qt.resolvedUrl("../../code/monitor.sh").toString().replace("file://", "")

    property var detectedCpuSensors: []
    property var detectedGpuSensors: []

    property var hiddenCpu: Plasmoid.configuration.hiddenCpuSensors || []
    property var hiddenGpu: Plasmoid.configuration.hiddenGpuSensors || []

    function toggleHidden(list, label, isHidden) {
        var idx = list.indexOf(label)
        if (isHidden && idx < 0) {
            list.push(label)
        } else if (!isHidden && idx >= 0) {
            list.splice(idx, 1)
        }
        return list
    }

    Plasma5Support.DataSource {
        id: cfgDataSource
        engine: "executable"
        connectedSources: []
        onNewData: {
            var lines = data.stdout.split("\n")
            var cpuList = [], gpuList = []
            for (var i = 0; i < lines.length; i++) {
                var eq = lines[i].indexOf("=")
                if (eq < 1) continue
                var k = lines[i].substring(0, eq)
                if (k.indexOf("CPUTEMP_") === 0) {
                    cpuList.push(k.substring(8).replace(/_/g, " "))
                } else if (k.indexOf("GPUTEMP_") === 0) {
                    gpuList.push(k.substring(8).replace(/_/g, " "))
                }
            }
            detectedCpuSensors = cpuList
            detectedGpuSensors = gpuList
            disconnectSource(sourceName)
        }
    }

    Component.onCompleted: {
        cfgDataSource.connectSource("bash " + scriptPath)
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            id: sectionToggles

            CheckBox {
                id: showBattery
                Kirigami.FormData.label: i18n("Sections:")
                checked: Plasmoid.configuration.showBattery
                onToggled: Plasmoid.configuration.showBattery = checked
                text: i18n("Battery")
            }
            CheckBox {
                id: showGpu
                checked: Plasmoid.configuration.showGpu
                onToggled: Plasmoid.configuration.showGpu = checked
                text: i18n("GPU")
            }
            CheckBox {
                id: showFans
                checked: Plasmoid.configuration.showFans
                onToggled: Plasmoid.configuration.showFans = checked
                text: i18n("Fans")
            }
            CheckBox {
                id: showNetwork
                checked: Plasmoid.configuration.showNetwork
                onToggled: Plasmoid.configuration.showNetwork = checked
                text: i18n("Network")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Kirigami.Theme.textColor
            opacity: 0.2
        }

        Kirigami.FormLayout {
            visible: detectedCpuSensors.length > 0
            Kirigami.FormData.label: i18n("CPU sensors:")

            Repeater {
                model: detectedCpuSensors
                delegate: CheckBox {
                    text: modelData
                    checked: page.hiddenCpu.indexOf(modelData) < 0
                    onToggled: {
                        page.hiddenCpu = page.toggleHidden(page.hiddenCpu, modelData, !checked)
                        Plasmoid.configuration.hiddenCpuSensors = page.hiddenCpu
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Kirigami.Theme.textColor
            opacity: 0.2
            visible: detectedGpuSensors.length > 0
        }

        Kirigami.FormLayout {
            visible: detectedGpuSensors.length > 0
            Kirigami.FormData.label: i18n("GPU sensors:")

            Repeater {
                model: detectedGpuSensors
                delegate: CheckBox {
                    text: modelData
                    checked: page.hiddenGpu.indexOf(modelData) < 0
                    onToggled: {
                        page.hiddenGpu = page.toggleHidden(page.hiddenGpu, modelData, !checked)
                        Plasmoid.configuration.hiddenGpuSensors = page.hiddenGpu
                    }
                }
            }
        }
    }
}
