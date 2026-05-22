# Linux System Monitor — KDE Plasma Widget

A KDE Plasma 6 widget for monitoring system hardware: CPU, GPU, RAM, fans, battery, and network.

Forked and ported from [asus-ux510-monitor](https://github.com/nhilo94/asus-ux510-monitor) by Nhilo94.

## What it shows

| Section | Sensors |
|---------|---------|
| **Battery** | Cycles, capacity %, health %, charge (Wh/mAh), voltage, charge status |
| **CPU** | Per-core temps, load %, frequency (via `coretemp`/`k10temp` hwmon) |
| **GPU** | Temp, load %, VRAM used/total (via `nvidia-smi`) |
| **RAM** | Used / total with usage bar |
| **Fans** | CPU/GPU fan RPM (via `asus` hwmon) |
| **Network** | Download / upload speed (auto-detects active interface) |

Every section and sub-item can be individually shown/hidden in the popup ("Show" column) or pinned to the panel taskbar ("Bar" column) via the configuration dialog. Dynamic sensor lists (CPU cores, GPU sensors, fans) have per-sensor toggles. Taskbar toggles remain accessible even when a popup section is turned off.

## Changes from upstream

- **KDE Plasma 6** — ported from Plasma 5 (PlasmoidItem, plasma5support DataSource, Kirigami.Icon, kpackagetool6)
- **NVIDIA GPU stats** — load %, VRAM usage, temperature (requires `nvidia-smi`)
- **Network speed** — real-time download/upload via sysfs counters
- **Configurable sections and sub-items** — toggle every section on/off; drill into each section to toggle individual sensors (cycles, health, load, freq, VRAM, etc.)
- **Independent taskbar toggles** — "Bar" column in config always visible, even when a section is toggled off; standalone taskbar options merged into the Bar column of their related sensor row (Capacity, Package id 0, Temp)
- **CPU sensor sorting** — package temp first, then alphabetical cores (applied in both widget and config dialog)
- **Charge fallback** — batteries reporting µAh via `charge_full` instead of µWh via `energy_full` are detected and displayed in mAh
- **Cleaner UI** — no emojis, percentage bars for VRAM/RAM, compact panel display

## Install

```bash
git clone https://github.com/ziad0ayman/Linux_System_Monitor.git
cd Linux_System_Monitor
bash install.sh
```

Then right-click panel → **Add Widgets** → search for **"Monitor"**.

## Uninstall

```bash
kpackagetool6 -t Plasma/Applet -r com.github.nhilo94.pcmonitor
```

## Requirements

- **KDE Plasma 6** (Plasma 5 is **not** supported)
- **nvidia-smi** (for GPU stats — optional, GPU section hides automatically if unavailable)

## Structure

```
Linux_System_Monitor/
├── plasmoid/
│   ├── metadata.json               # Widget metadata (Plasma 6)
│   ├── contents/
│   │   ├── config/
│   │   │   ├── main.xml            # KConfig XT schema
│   │   │   └── config.qml          # Config tab definition
│   │   ├── code/
│   │   │   └── monitor.sh          # Sensor polling script
│   │   └── ui/
│   │       ├── main.qml            # Widget UI and logic
│   │       └── config/
│   │           └── ConfigGeneral.qml # Configuration page
│   └── metadata.desktop            # Legacy metadata (Plasma 5 compat)
├── install.sh                      # Install/update script
├── LICENSE
└── README.md
```

## License

MIT — original by Fanilo Rakotovao (Nhilo94), modified by Ziad Ayman.
