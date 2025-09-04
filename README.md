# USB Connection Manager 🔍

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Linux|Windows](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-blue.svg)]()
[![Shell: Bash|PowerShell](https://img.shields.io/badge/Shell-Bash%20%7C%20PowerShell-green.svg)]()

A cross-platform tool for analyzing and cleaning USB device connection history on Windows and Linux systems. Designed for cybersecurity professionals, digital forensics investigators, and privacy-conscious users.

## ⚠️ Disclaimer
EDUCATIONAL USE ONLY - This tool is designed for educational purposes and security research. The authors are not responsible for any misuse or damages caused by this software. Users must ensure proper authorization and comply with all applicable laws.

## ✨ Features

### 🔍 Forensic Analysis
- **View current USB devices** and connected storage
- **Analyze historical connections** across multiple log sources
- **Examine system logs** for USB-related events
- **Retrieve detailed device information** using system tools

### 🧹 Cleaning Capabilities
- **Remove USB connection traces** from system logs
- **Clean registry entries** (Windows)
- **Clear bash history** and command logs
- **Sanitize temporary files** and caches
- **Multi-OS support** with automatic distribution detection

### 🛡️ Privacy Protection
- **Cross-platform compatibility** (Windows + Linux)
- **Non-destructive analysis** before cleaning
- **Educational mode** for learning forensic techniques
- **Comprehensive logging** of all operations

## 📋 Supported Systems

### Linux Distributions
- **Debian/Ubuntu** (and derivatives: Mint, Pop!_OS)
- **RedHat/CentOS/Fedora** (RHEL-based systems)
- **Arch Linux/Manjaro** (Arch-based systems)
- **Other distributions** (with basic support)

### Windows Versions
- **Windows 10/11** (full support)
- **Windows 8/8.1** (basic support)
- **Windows 7** (limited functionality)

## 🚀 Quick Start

### Linux Installation
```bash
# Clone repository
git clone https://github.com/Dimiqhz/usb-connection-manager.git
cd usb-connection-manager/[lang(ru/en)]

# Make executable
chmod +x linux_multios_script.sh

# Run with sudo
sudo ./linux_multios_script.sh
```

### Windows Installation
```bash
# Clone repository
git clone https://github.com/Dimiqhz/usb-connection-manager.git
cd usb-connection-manager/[lang(ru/en)]

# Run PowerShell as Administrator
Set-ExecutionPolicy RemoteSigned -Scope Process
.\windows_multios_script.ps1
```

## 🔧 Technical Details
### Linux Components Analyzed
- lsusb - USB device information
- dmesg - Kernel ring buffer
- journalctl - Systemd journals
- /var/log/ - System logs (syslog, kern.log, messages)
- udevadm - Device manager database
- Bash history files

### Windows Components Analyzed
- Registry: USBSTOR, device classes, setupapi
- Event Logs: System, Application, Security
- File System: Prefetch, temporary files
- WMI: Device information through Windows Management Instrumentation

## ⚠️ Important Notes
### System Requirements
- Linux: Bash 4.0+, root privileges, standard system tools
- Windows: PowerShell 3.0+, Administrator privileges
- Storage: Minimal disk space required
- Memory: 512MB RAM minimum

### Best Practices
- Always backup important data before cleaning
-Test in isolated environment first
- Document all operations for audit purposes
- Verify authorization before running on any system

### 🎓 Educational Value
This tool demonstrates:
- Digital forensics investigation techniques
- Operating system artifact analysis
- Privacy protection methodologies
- Cross-platform scripting techniques
- Security tool development practices

## 🤝 Contributing
We welcome contributions!

## 📜 License
This project is licensed under the MIT License - see the LICENSE file for details.