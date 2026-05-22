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
    property var cpuSensors: []
    property var gpuSensors: []
    property var fanSensors: []

    Plasma5Support.DataSource {
        id: cfgDataSource
        engine: "executable"
        connectedSources: []
        onNewData: {
            var lines = data.stdout.split("\n")
            var cpu = [], gpu = [], fan = []
            for (var i = 0; i < lines.length; i++) {
                var eq = lines[i].indexOf("=")
                if (eq < 1) continue
                var k = lines[i].substring(0, eq)
                if (k.indexOf("CPUTEMP_") === 0) {
                    cpu.push(k.substring(8).replace(/_/g, " "))
                } else if (k.indexOf("GPUTEMP_") === 0) {
                    gpu.push(k.substring(8).replace(/_/g, " "))
                } else if (k.indexOf("FAN_") === 0) {
                    fan.push(k.substring(4).replace(/_/g, " "))
                }
            }
            cpuSensors = cpu
            gpuSensors = gpu
            fanSensors = fan
            disconnectSource(sourceName)
        }
    }

    Component.onCompleted: {
        cfgDataSource.connectSource("bash " + scriptPath)
    }

    function toggleList(list, item) {
        var idx = list.indexOf(item)
        if (idx >= 0) list.splice(idx, 1)
        else list.push(item)
        return list
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // ── Column header ──
        RowLayout {
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            spacing: 4
            Label { text: "Show"; font.pixelSize: 10; opacity: 0.5; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter }
            Label { text: "Bar";  font.pixelSize: 10; opacity: 0.5; Layout.preferredWidth: 16; horizontalAlignment: Text.AlignHCenter }
            Label { text: ""; Layout.fillWidth: true }
        }

        // ── Battery ──
        Kirigami.FormLayout {
            CheckBox {
                id: bat
                Kirigami.FormData.label: i18n("Sections:")
                checked: Plasmoid.configuration.showBattery
                onToggled: Plasmoid.configuration.showBattery = checked
                text: i18n("Battery")
            }
        }
        ColumnLayout {
            id: batGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showBatteryCycles;  onToggled: Plasmoid.configuration.showBatteryCycles = checked }
                CheckBox { visible: false; Layout.preferredWidth: 16 }
                Label { text: i18n("Cycles") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showBatteryCapacity; onToggled: Plasmoid.configuration.showBatteryCapacity = checked }
                CheckBox { visible: false; Layout.preferredWidth: 16 }
                Label { text: i18n("Capacity") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showBatteryHealth;  onToggled: Plasmoid.configuration.showBatteryHealth = checked }
                CheckBox { visible: false; Layout.preferredWidth: 16 }
                Label { text: i18n("Health") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showBatteryEnergy;  onToggled: Plasmoid.configuration.showBatteryEnergy = checked }
                CheckBox { visible: false; Layout.preferredWidth: 16 }
                Label { text: i18n("Charge") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showBatteryVoltage; onToggled: Plasmoid.configuration.showBatteryVoltage = checked }
                CheckBox { visible: false; Layout.preferredWidth: 16 }
                Label { text: i18n("Voltage") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showBatteryStatus;  onToggled: Plasmoid.configuration.showBatteryStatus = checked }
                CheckBox { visible: false; Layout.preferredWidth: 16 }
                Label { text: i18n("Status") }
            }
            RowLayout {
                spacing: 4
                CheckBox { visible: false; Layout.preferredWidth: 32 }
                CheckBox { checked: Plasmoid.configuration.taskbarBattery; onToggled: Plasmoid.configuration.taskbarBattery = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("Show battery % in taskbar"); opacity: 0.7 }
            }
        }

        // ── CPU ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: cpu
                checked: Plasmoid.configuration.showCpu
                onToggled: Plasmoid.configuration.showCpu = checked
                text: i18n("CPU")
            }
        }
        ColumnLayout {
            id: cpuGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            Repeater {
                model: page.cpuSensors
                delegate: RowLayout {
                    spacing: 4
                    CheckBox {
                        checked: (Plasmoid.configuration.hiddenCpuSensors || []).indexOf(modelData) < 0
                        onToggled: {
                            var list = Plasmoid.configuration.hiddenCpuSensors || []
                            list = page.toggleList(list, modelData)
                            Plasmoid.configuration.hiddenCpuSensors = list
                        }
                    }
                    Item { Layout.preferredWidth: 16 }
                    Label { text: modelData }
                }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showCpuLoad; onToggled: Plasmoid.configuration.showCpuLoad = checked }
                CheckBox { checked: Plasmoid.configuration.taskbarCpuLoad; onToggled: Plasmoid.configuration.taskbarCpuLoad = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("Load") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showCpuFreq;  onToggled: Plasmoid.configuration.showCpuFreq = checked }
                CheckBox { checked: Plasmoid.configuration.taskbarCpuFreq; onToggled: Plasmoid.configuration.taskbarCpuFreq = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("Frequency") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.taskbarCpuTemp; onToggled: Plasmoid.configuration.taskbarCpuTemp = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("Show CPU temp in taskbar"); opacity: 0.7; Layout.leftMargin: 36 }
            }
        }

        // ── GPU ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: gpu
                checked: Plasmoid.configuration.showGpu
                onToggled: Plasmoid.configuration.showGpu = checked
                text: i18n("GPU")
            }
        }
        ColumnLayout {
            id: gpuGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            Repeater {
                model: page.gpuSensors
                delegate: RowLayout {
                    spacing: 4
                    CheckBox {
                        checked: (Plasmoid.configuration.hiddenGpuSensors || []).indexOf(modelData) < 0
                        onToggled: {
                            var list = Plasmoid.configuration.hiddenGpuSensors || []
                            list = page.toggleList(list, modelData)
                            Plasmoid.configuration.hiddenGpuSensors = list
                        }
                    }
                    Item { Layout.preferredWidth: 16 }
                    Label { text: modelData }
                }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showGpuLoad; onToggled: Plasmoid.configuration.showGpuLoad = checked }
                CheckBox { checked: Plasmoid.configuration.taskbarGpuLoad; onToggled: Plasmoid.configuration.taskbarGpuLoad = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("Load") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showGpuVram; onToggled: Plasmoid.configuration.showGpuVram = checked }
                CheckBox { checked: Plasmoid.configuration.taskbarVram; onToggled: Plasmoid.configuration.taskbarVram = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("VRAM") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.taskbarGpuTemp; onToggled: Plasmoid.configuration.taskbarGpuTemp = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("Show GPU temp in taskbar"); opacity: 0.7; Layout.leftMargin: 36 }
            }
        }

        // ── RAM ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: ramSec
                checked: Plasmoid.configuration.showRam
                onToggled: Plasmoid.configuration.showRam = checked
                text: i18n("RAM")
            }
        }
        ColumnLayout {
            id: ramGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showRamUsed; onToggled: Plasmoid.configuration.showRamUsed = checked }
                CheckBox { checked: Plasmoid.configuration.taskbarRam; onToggled: Plasmoid.configuration.taskbarRam = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("Used") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showRamBar;  onToggled: Plasmoid.configuration.showRamBar = checked }
                CheckBox { visible: false; Layout.preferredWidth: 16 }
                Label { text: i18n("Usage bar") }
            }
        }

        // ── Fans ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: fans
                checked: Plasmoid.configuration.showFans
                onToggled: Plasmoid.configuration.showFans = checked
                text: i18n("Fans")
            }
        }
        ColumnLayout {
            id: fansGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            Repeater {
                model: page.fanSensors
                delegate: RowLayout {
                    spacing: 4
                    CheckBox {
                        checked: (Plasmoid.configuration.hiddenFanSensors || []).indexOf(modelData) < 0
                        onToggled: {
                            var list = Plasmoid.configuration.hiddenFanSensors || []
                            list = page.toggleList(list, modelData)
                            Plasmoid.configuration.hiddenFanSensors = list
                        }
                    }
                    Item { Layout.preferredWidth: 16 }
                    Label { text: modelData }
                }
            }
        }

        // ── Network ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: net
                checked: Plasmoid.configuration.showNetwork
                onToggled: Plasmoid.configuration.showNetwork = checked
                text: i18n("Network")
            }
        }
        ColumnLayout {
            id: netGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showNetDown; onToggled: Plasmoid.configuration.showNetDown = checked }
                CheckBox { checked: Plasmoid.configuration.taskbarNetDown; onToggled: Plasmoid.configuration.taskbarNetDown = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("Download") }
            }
            RowLayout {
                spacing: 4
                CheckBox { checked: Plasmoid.configuration.showNetUp;   onToggled: Plasmoid.configuration.showNetUp = checked }
                CheckBox { checked: Plasmoid.configuration.taskbarNetUp; onToggled: Plasmoid.configuration.taskbarNetUp = checked; Layout.preferredWidth: 16 }
                Label { text: i18n("Upload") }
            }
        }
    }
}
