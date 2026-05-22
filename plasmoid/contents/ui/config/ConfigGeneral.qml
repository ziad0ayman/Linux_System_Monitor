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

        // ── Battery ──
        Kirigami.FormLayout {
            CheckBox {
                id: bat
                Kirigami.FormData.label: i18n("Sections:")
                checked: Plasmoid.configuration.showBattery
                onToggled: {
                    Plasmoid.configuration.showBattery = checked
                    batGroup.visible = checked
                }
                text: i18n("Battery")
            }
        }
        ColumnLayout {
            id: batGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            visible: Plasmoid.configuration.showBattery
            Kirigami.FormLayout {
                CheckBox { checked: Plasmoid.configuration.showBatteryCycles;  onToggled: Plasmoid.configuration.showBatteryCycles = checked;  text: i18n("Cycles") }
                CheckBox { checked: Plasmoid.configuration.showBatteryCapacity; onToggled: Plasmoid.configuration.showBatteryCapacity = checked; text: i18n("Capacity") }
                CheckBox { checked: Plasmoid.configuration.showBatteryHealth;  onToggled: Plasmoid.configuration.showBatteryHealth = checked;  text: i18n("Health") }
                CheckBox { checked: Plasmoid.configuration.showBatteryEnergy;  onToggled: Plasmoid.configuration.showBatteryEnergy = checked;  text: i18n("Energy") }
                CheckBox { checked: Plasmoid.configuration.showBatteryVoltage; onToggled: Plasmoid.configuration.showBatteryVoltage = checked; text: i18n("Voltage") }
                CheckBox { checked: Plasmoid.configuration.showBatteryStatus;  onToggled: Plasmoid.configuration.showBatteryStatus = checked;  text: i18n("Status") }
            }
        }

        // ── CPU ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: cpu
                checked: Plasmoid.configuration.showCpu
                onToggled: {
                    Plasmoid.configuration.showCpu = checked
                    cpuGroup.visible = checked
                }
                text: i18n("CPU")
            }
        }
        ColumnLayout {
            id: cpuGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            visible: Plasmoid.configuration.showCpu
            Kirigami.FormLayout {
                Repeater {
                    model: page.cpuSensors
                    delegate: CheckBox {
                        text: modelData
                        checked: (Plasmoid.configuration.hiddenCpuSensors || []).indexOf(modelData) < 0
                        onToggled: {
                            var list = Plasmoid.configuration.hiddenCpuSensors || []
                            list = page.toggleList(list, modelData)
                            Plasmoid.configuration.hiddenCpuSensors = list
                        }
                    }
                }
                CheckBox { checked: Plasmoid.configuration.showCpuLoad; onToggled: Plasmoid.configuration.showCpuLoad = checked; text: i18n("Load") }
                CheckBox { checked: Plasmoid.configuration.showCpuFreq;  onToggled: Plasmoid.configuration.showCpuFreq = checked;  text: i18n("Frequency") }
            }
        }

        // ── GPU ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: gpu
                checked: Plasmoid.configuration.showGpu
                onToggled: {
                    Plasmoid.configuration.showGpu = checked
                    gpuGroup.visible = checked
                }
                text: i18n("GPU")
            }
        }
        ColumnLayout {
            id: gpuGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            visible: Plasmoid.configuration.showGpu
            Kirigami.FormLayout {
                Repeater {
                    model: page.gpuSensors
                    delegate: CheckBox {
                        text: modelData
                        checked: (Plasmoid.configuration.hiddenGpuSensors || []).indexOf(modelData) < 0
                        onToggled: {
                            var list = Plasmoid.configuration.hiddenGpuSensors || []
                            list = page.toggleList(list, modelData)
                            Plasmoid.configuration.hiddenGpuSensors = list
                        }
                    }
                }
                CheckBox { checked: Plasmoid.configuration.showGpuLoad; onToggled: Plasmoid.configuration.showGpuLoad = checked; text: i18n("Load") }
                CheckBox { checked: Plasmoid.configuration.showGpuVram; onToggled: Plasmoid.configuration.showGpuVram = checked; text: i18n("VRAM") }
            }
        }

        // ── RAM ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: ram
                checked: Plasmoid.configuration.showRam
                onToggled: {
                    Plasmoid.configuration.showRam = checked
                    ramGroup.visible = checked
                }
                text: i18n("RAM")
            }
        }
        ColumnLayout {
            id: ramGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            visible: Plasmoid.configuration.showRam
            Kirigami.FormLayout {
                CheckBox { checked: Plasmoid.configuration.showRamUsed; onToggled: Plasmoid.configuration.showRamUsed = checked; text: i18n("Used") }
                CheckBox { checked: Plasmoid.configuration.showRamBar;  onToggled: Plasmoid.configuration.showRamBar = checked;  text: i18n("Usage bar") }
            }
        }

        // ── Fans ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: fans
                checked: Plasmoid.configuration.showFans
                onToggled: {
                    Plasmoid.configuration.showFans = checked
                    fansGroup.visible = checked
                }
                text: i18n("Fans")
            }
        }
        ColumnLayout {
            id: fansGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            visible: Plasmoid.configuration.showFans
            Kirigami.FormLayout {
                Repeater {
                    model: page.fanSensors
                    delegate: CheckBox {
                        text: modelData
                        checked: (Plasmoid.configuration.hiddenFanSensors || []).indexOf(modelData) < 0
                        onToggled: {
                            var list = Plasmoid.configuration.hiddenFanSensors || []
                            list = page.toggleList(list, modelData)
                            Plasmoid.configuration.hiddenFanSensors = list
                        }
                    }
                }
            }
        }

        // ── Network ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.15 }
        Kirigami.FormLayout {
            CheckBox {
                id: net
                checked: Plasmoid.configuration.showNetwork
                onToggled: {
                    Plasmoid.configuration.showNetwork = checked
                    netGroup.visible = checked
                }
                text: i18n("Network")
            }
        }
        ColumnLayout {
            id: netGroup
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            visible: Plasmoid.configuration.showNetwork
            Kirigami.FormLayout {
                CheckBox { checked: Plasmoid.configuration.showNetDown; onToggled: Plasmoid.configuration.showNetDown = checked; text: i18n("Download") }
                CheckBox { checked: Plasmoid.configuration.showNetUp;   onToggled: Plasmoid.configuration.showNetUp = checked;   text: i18n("Upload") }
            }
        }
    }
}
