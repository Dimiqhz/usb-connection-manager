#!/bin/bash

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run with root (sudo) privileges." >&2
        exit 1
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    echo "$OS" | tr '[:upper:]' '[:lower:]'
}

show_current_usb_devices() {
    echo "=========================================="
    echo "Current USB devices:"
    echo "=========================================="
    lsusb 2>/dev/null || echo "lsusb command not found"
}

show_usb_storage() {
    echo "=========================================="
    echo "Current USB drives and mount points:"
    echo "=========================================="
    
    echo "USB block devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,VENDOR,MODEL 2>/dev/null | grep -i disk || \
    echo "    No USB devices found"
    
    echo ""
    echo "Mounting points:"
    mount | grep -i 'sd\|usb' 2>/dev/null || \
    echo "    No USB mount points found"
    
    echo ""
    echo "Information from /proc/partitions:"
    grep -i 'sd' /proc/partitions 2>/dev/null || \
    echo "    No USB partitions found"
}

show_dmesg_usb() {
    echo "=========================================="
    echo "dmesg about USB (last 50 entries):"
    echo "=========================================="
    dmesg | grep -i 'usb\|sd' | tail -50 2>/dev/null || \
    echo "Couldn't get dmesg information"
}

show_journalctl_usb() {
    echo "=========================================="
    echo "journalctl about USB (last 30 days):"
    echo "=========================================="
    if command -v journalctl >/dev/null 2>&1; then
        journalctl --since="30 days ago" | grep -i 'usb\|sd' | tail -50 2>/dev/null || \
        echo "No USB records found in the last 30 days"
    else
        echo "journalctl is not available"
    fi
}

show_syslog_usb() {
    echo "=========================================="
    echo "syslog/kern.log about USB:"
    echo "=========================================="
    
    local found_entries=false
    
    if [ -f /var/log/syslog ]; then
        echo "Syslog entries:"
        grep -i 'usb\|sd' /var/log/syslog | tail -20 2>/dev/null
        found_entries=true
    fi
    
    if [ -f /var/log/kern.log ]; then
        echo ""
        echo "Kern.log entries:"
        grep -i 'usb\|sd' /var/log/kern.log | tail -20 2>/dev/null
        found_entries=true
    fi
    
    if [ -f /var/log/messages ]; then
        echo ""
        echo "Messages entries:"
        grep -i 'usb\|sd' /var/log/messages | tail -20 2>/dev/null
        found_entries=true
    fi
    
    if [ "$found_entries" = false ]; then
        echo "No system logs with USB records were found."
    fi
}

show_udevadm_info() {
    echo "=========================================="
    echo "udevadm info on USB disks:"
    echo "=========================================="
    
    usb_devices=$(find /dev/disk/by-id/ -name '*usb*' -o -name '*USB*' 2>/dev/null | head -5)
    
    if [ -n "$usb_devices" ]; then
        for device in $usb_devices; do
            echo "Device: $device"
            udevadm info -q all -n "$(readlink -f $device)" 2>/dev/null | \
            grep -E '(ID_VENDOR|ID_MODEL|ID_SERIAL|DEVTYPE)' | head -5
            echo "---"
        done
    else
        echo "No USB devices found in /dev/disk/by-id/"
        
        echo ""
        echo "Search for USB devices via lsblk:"
        lsblk -o NAME,TRAN,VENDOR,MODEL | grep -i usb 2>/dev/null || \
        echo "No USB devices found via lsblk"
    fi
}

show_history_menu() {
    echo "=========================================="
    echo "  Viewing the history of USB connections"
    echo "=========================================="
    echo "1. Current USB Devices (lsusb)"
    echo "2. Current USB drives and mount points"
    echo "3. dmesg about USB"
    echo "4. journalctl about USB (30 days)"
    echo "5. syslog/kern.log about USB"
    echo "6. udevadm info on USB disks"
    echo "7. Go back to the main menu"
    echo "=========================================="
    
    read -p "Select an option (1-7): " choice
    
    case $choice in
        1)
            show_current_usb_devices
            ;;
        2)
            show_usb_storage
            ;;
        3)
            show_dmesg_usb
            ;;
        4)
            show_journalctl_usb
            ;;
        5)
            show_syslog_usb
            ;;
        6)
            show_udevadm_info
            ;;
        7)
            return
            ;;
        *)
            echo "Wrong choice. Try again."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_history_menu
}

clean_debian_ubuntu() {
    echo "Clearing the USB history for Debian/Ubuntu..."
    
    if [ -f /var/log/syslog ]; then
        echo "Clearing /var/log/syslog..."
        sudo sed -i '/usb\|USB\|sd\|ttyUSB\|mount\|umount/d' /var/log/syslog 2>/dev/null
    fi
    
    if [ -f /var/log/kern.log ]; then
        echo "Clearing /var/log/kern.log..."
        sudo sed -i '/usb\|USB\|sd\|ttyUSB\|scsi\|storage/d' /var/log/kern.log 2>/dev/null
    fi
    
    if [ -f /var/log/messages ]; then
        echo "Clearing /var/log/messages..."
        sudo sed -i '/usb\|USB\|sd\|ttyUSB/d' /var/log/messages 2>/dev/null
    fi
    
    if [ -f /var/log/auth.log ]; then
        echo "Clearing /var/log/auth.log..."
        sudo sed -i '/mount\|umount\|usb/d' /var/log/auth.log 2>/dev/null
    fi
    
    echo "Cleaning up the journalctl..."
    journalctl --vacuum-time=1h 2>/dev/null
    journalctl --rotate 2>/dev/null
    
    echo "Cleaning the udev database..."
    udevadm info --cleanup-db 2>/dev/null
    
    rm -f /var/lib/udev/hwdb.bin 2>/dev/null
    rm -f /run/udev/data/* 2>/dev/null
    
    echo "The USB history has been cleared for Debian/Ubuntu."
}

clean_redhat_centos() {
    echo "Clearing the USB history for RedHat/CentOS..."
    
    if [ -f /var/log/messages ]; then
        echo "Clearing /var/log/messages..."
        sudo sed -i '/usb\|USB\|sd\|ttyUSB\|scsi/d' /var/log/messages 2>/dev/null
    fi
    
    if [ -f /var/log/secure ]; then
        echo "Clearing /var/log/secure..."
        sudo sed -i '/mount\|umount\|usb/d' /var/log/secure 2>/dev/null
    fi
    
    if [ -f /var/log/boot.log ]; then
        echo "Clearing /var/log/boot.log..."
        sudo sed -i '/usb\|USB/d' /var/log/boot.log 2>/dev/null
    fi
    
    echo "Cleaning up the journalctl..."
    journalctl --vacuum-time=1h 2>/dev/null
    journalctl --rotate 2>/dev/null
    
    echo "Cleaning the udev database..."
    udevadm info --cleanup-db 2>/dev/null
    
    rm -f /run/udev/data/* 2>/dev/null
    
    echo "The USB history has been cleared for RedHat/CentOS."
}

clean_arch() {
    echo "Clearing the USB history for Arch Linux..."
    
    echo "Cleaning up the journalctl..."
    journalctl --vacuum-time=1h 2>/dev/null
    journalctl --rotate 2>/dev/null
    
    echo "Cleaning the udev database..."
    udevadm info --cleanup-db 2>/dev/null
    
    rm -f /var/lib/udev/hwdb.bin 2>/dev/null
    rm -f /run/udev/data/* 2>/dev/null
    
    if [ -f /var/log/pacman.log ]; then
        echo "Clearing /var/log/pacman.log..."
        sudo sed -i '/usb\|USB/d' /var/log/pacman.log 2>/dev/null
    fi
    
    echo "The USB history has been cleared for Arch Linux."
}

clean_bash_history() {
    echo "Clearing the bash history..."
    
    for user_dir in /home/* /root; do
        if [ -f "$user_dir/.bash_history" ]; then
            echo "Clearing $user_dir/.bash_history"
            sed -i '/mount\|umount\|usb\|fdisk\|lsblk\|dd\|mkfs/d' "$user_dir/.bash_history" 2>/dev/null
        fi
    done
    
    history -c
    history -w
    
    rm -f ~/.zsh_history 2>/dev/null
    rm -f ~/.fish_history 2>/dev/null
    
    echo "The bash history has been cleared."
}

clean_usb_history() {
    local distro=$(detect_distro)
    
    echo "OS detected: $distro"
    echo "I'm starting to clear the USB history..."
    echo "=========================================="
    
    case $distro in
        *debian*|*ubuntu*|*mint*)
            clean_debian_ubuntu
            ;;
        *red*hat*|*centos*|*fedora*|*rhel*)
            clean_redhat_centos
            ;;
        *arch*|*manjaro*)
            clean_arch
            ;;
        *)
            echo "Unknown distribution. I apply a general cleaning..."
            journalctl --vacuum-time=1h 2>/dev/null
            udevadm info --cleanup-db 2>/dev/null
            ;;
    esac
    
    clean_bash_history
    
    echo "=========================================="
    echo "I'm doing additional cleaning..."
    
    echo "Cleaning temporary files..."
    rm -f /tmp/usb* /tmp/sd* /tmp/mount* 2>/dev/null
    rm -f /var/tmp/usb* /var/tmp/sd* 2>/dev/null
    
    echo "Cache synchronization..."
    sync
    
    if command -v apt-get >/dev/null 2>&1; then
        apt-get clean 2>/dev/null
    fi
    
    if command -v yum >/dev/null 2>&1; then
        yum clean all 2>/dev/null
    fi
    
    if command -v pacman >/dev/null 2>&1; then
        pacman -Scc --noconfirm 2>/dev/null
    fi
    
    echo "=========================================="
    echo "The cleaning is completed successfully!"
    echo "It is recommended to reboot the system for full effect."
    echo "=========================================="
}

show_main_menu() {
    echo "==================================================="
    echo "  Clearing the history of USB connections - Linux"
    echo "==================================================="
    echo "1. Start clearing the USB history"
    echo "2. Viewing the history of USB connections"
    echo "3. Show information about the system"
    echo "4. Exit"
    echo "=========================================="
    
    read -p "Select an option (1-4): " choice
    
    case $choice in
        1)
            check_root
            clean_usb_history
            ;;
        2)
            show_history_menu
            ;;
        3)
            echo "Information about the system:"
            echo "Distribution: $(detect_distro)"
            echo "Kernel: $(uname -r)"
            echo "Architecture: $(uname -m)"
            ;;
        4)
            echo "Exit..."
            exit 0
            ;;
        *)
            echo "Wrong choice. Try again."
            show_main_menu
            ;;
    esac
}

main() {
    if [ ! -t 0 ]; then
        echo "This script should be run in the terminal."
        exit 1
    fi
    
    show_main_menu
}

main "$@"