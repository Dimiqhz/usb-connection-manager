#!/bin/bash

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Этот скрипт должен запускаться с правами root (sudo)." >&2
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
    echo "Текущие USB устройства:"
    echo "=========================================="
    lsusb 2>/dev/null || echo "Команда lsusb не найдена"
}

show_usb_storage() {
    echo "=========================================="
    echo "Текущие USB-накопители и точки монтирования:"
    echo "=========================================="
    
    echo "USB блочные устройства:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,VENDOR,MODEL 2>/dev/null | grep -i disk || \
    echo "    Не найдено USB устройств"
    
    echo ""
    echo "Точки монтирования:"
    mount | grep -i 'sd\|usb' 2>/dev/null || \
    echo "    Не найдено точек монтирования USB"
    
    echo ""
    echo "Информация из /proc/partitions:"
    grep -i 'sd' /proc/partitions 2>/dev/null || \
    echo "    Не найдено разделов USB"
}

show_dmesg_usb() {
    echo "=========================================="
    echo "dmesg про USB (последние 50 записей):"
    echo "=========================================="
    dmesg | grep -i 'usb\|sd' | tail -50 2>/dev/null || \
    echo "Не удалось получить dmesg информацию"
}

show_journalctl_usb() {
    echo "=========================================="
    echo "journalctl про USB (последние 30 дней):"
    echo "=========================================="
    if command -v journalctl >/dev/null 2>&1; then
        journalctl --since="30 days ago" | grep -i 'usb\|sd' | tail -50 2>/dev/null || \
        echo "Не найдено записей о USB за последние 30 дней"
    else
        echo "journalctl не доступен"
    fi
}

show_syslog_usb() {
    echo "=========================================="
    echo "syslog/kern.log про USB:"
    echo "=========================================="
    
    local found_entries=false
    
    if [ -f /var/log/syslog ]; then
        echo "Syslog записи:"
        grep -i 'usb\|sd' /var/log/syslog | tail -20 2>/dev/null
        found_entries=true
    fi
    
    if [ -f /var/log/kern.log ]; then
        echo ""
        echo "Kern.log записи:"
        grep -i 'usb\|sd' /var/log/kern.log | tail -20 2>/dev/null
        found_entries=true
    fi
    
    if [ -f /var/log/messages ]; then
        echo ""
        echo "Messages записи:"
        grep -i 'usb\|sd' /var/log/messages | tail -20 2>/dev/null
        found_entries=true
    fi
    
    if [ "$found_entries" = false ]; then
        echo "Не найдено системных логов с USB записями"
    fi
}

show_udevadm_info() {
    echo "=========================================="
    echo "udevadm info по USB дискам:"
    echo "=========================================="
    
    usb_devices=$(find /dev/disk/by-id/ -name '*usb*' -o -name '*USB*' 2>/dev/null | head -5)
    
    if [ -n "$usb_devices" ]; then
        for device in $usb_devices; do
            echo "Устройство: $device"
            udevadm info -q all -n "$(readlink -f $device)" 2>/dev/null | \
            grep -E '(ID_VENDOR|ID_MODEL|ID_SERIAL|DEVTYPE)' | head -5
            echo "---"
        done
    else
        echo "Не найдено USB устройств в /dev/disk/by-id/"
        
        echo ""
        echo "Поиск USB устройств через lsblk:"
        lsblk -o NAME,TRAN,VENDOR,MODEL | grep -i usb 2>/dev/null || \
        echo "Не найдено USB устройств через lsblk"
    fi
}

show_history_menu() {
    echo "=========================================="
    echo "  Просмотр истории USB подключений"
    echo "=========================================="
    echo "1. Текущие USB устройства (lsusb)"
    echo "2. Текущие USB-накопители и точки монтирования"
    echo "3. dmesg про USB"
    echo "4. journalctl про USB (30 дней)"
    echo "5. syslog/kern.log про USB"
    echo "6. udevadm info по USB дискам"
    echo "7. Вернуться в главное меню"
    echo "=========================================="
    
    read -p "Выберите опцию (1-7): " choice
    
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
            echo "Неверный выбор. Попробуйте снова."
            ;;
    esac
    
    echo ""
    read -p "Нажмите Enter для продолжения..."
    show_history_menu
}

clean_debian_ubuntu() {
    echo "Очистка истории USB для Debian/Ubuntu..."
    
    if [ -f /var/log/syslog ]; then
        echo "Очистка /var/log/syslog..."
        sudo sed -i '/usb\|USB\|sd\|ttyUSB\|mount\|umount/d' /var/log/syslog 2>/dev/null
    fi
    
    if [ -f /var/log/kern.log ]; then
        echo "Очистка /var/log/kern.log..."
        sudo sed -i '/usb\|USB\|sd\|ttyUSB\|scsi\|storage/d' /var/log/kern.log 2>/dev/null
    fi
    
    if [ -f /var/log/messages ]; then
        echo "Очистка /var/log/messages..."
        sudo sed -i '/usb\|USB\|sd\|ttyUSB/d' /var/log/messages 2>/dev/null
    fi
    
    if [ -f /var/log/auth.log ]; then
        echo "Очистка /var/log/auth.log..."
        sudo sed -i '/mount\|umount\|usb/d' /var/log/auth.log 2>/dev/null
    fi
    
    echo "Очистка journalctl..."
    journalctl --vacuum-time=1h 2>/dev/null
    journalctl --rotate 2>/dev/null
    
    echo "Очистка udev базы данных..."
    udevadm info --cleanup-db 2>/dev/null
    
    rm -f /var/lib/udev/hwdb.bin 2>/dev/null
    rm -f /run/udev/data/* 2>/dev/null
    
    echo "История USB очищена для Debian/Ubuntu."
}

clean_redhat_centos() {
    echo "Очистка истории USB для RedHat/CentOS..."
    
    if [ -f /var/log/messages ]; then
        echo "Очистка /var/log/messages..."
        sudo sed -i '/usb\|USB\|sd\|ttyUSB\|scsi/d' /var/log/messages 2>/dev/null
    fi
    
    if [ -f /var/log/secure ]; then
        echo "Очистка /var/log/secure..."
        sudo sed -i '/mount\|umount\|usb/d' /var/log/secure 2>/dev/null
    fi
    
    if [ -f /var/log/boot.log ]; then
        echo "Очистка /var/log/boot.log..."
        sudo sed -i '/usb\|USB/d' /var/log/boot.log 2>/dev/null
    fi
    
    echo "Очистка journalctl..."
    journalctl --vacuum-time=1h 2>/dev/null
    journalctl --rotate 2>/dev/null
    
    echo "Очистка udev базы данных..."
    udevadm info --cleanup-db 2>/dev/null
    
    rm -f /run/udev/data/* 2>/dev/null
    
    echo "История USB очищена для RedHat/CentOS."
}

clean_arch() {
    echo "Очистка истории USB для Arch Linux..."
    
    echo "Очистка journalctl..."
    journalctl --vacuum-time=1h 2>/dev/null
    journalctl --rotate 2>/dev/null
    
    echo "Очистка udev базы данных..."
    udevadm info --cleanup-db 2>/dev/null
    
    rm -f /var/lib/udev/hwdb.bin 2>/dev/null
    rm -f /run/udev/data/* 2>/dev/null
    
    if [ -f /var/log/pacman.log ]; then
        echo "Очистка /var/log/pacman.log..."
        sudo sed -i '/usb\|USB/d' /var/log/pacman.log 2>/dev/null
    fi
    
    echo "История USB очищена для Arch Linux."
}

clean_bash_history() {
    echo "Очистка истории bash..."
    
    for user_dir in /home/* /root; do
        if [ -f "$user_dir/.bash_history" ]; then
            echo "Очистка $user_dir/.bash_history"
            sed -i '/mount\|umount\|usb\|fdisk\|lsblk\|dd\|mkfs/d' "$user_dir/.bash_history" 2>/dev/null
        fi
    done
    
    history -c
    history -w
    
    rm -f ~/.zsh_history 2>/dev/null
    rm -f ~/.fish_history 2>/dev/null
    
    echo "История bash очищена."
}

clean_usb_history() {
    local distro=$(detect_distro)
    
    echo "Обнаружена ОС: $distro"
    echo "Начинаю очистку истории USB..."
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
            echo "Неизвестный дистрибутив. Применяю общую очистку..."
            journalctl --vacuum-time=1h 2>/dev/null
            udevadm info --cleanup-db 2>/dev/null
            ;;
    esac
    
    clean_bash_history
    
    echo "=========================================="
    echo "Выполняю дополнительную очистку..."
    
    echo "Очистка временных файлов..."
    rm -f /tmp/usb* /tmp/sd* /tmp/mount* 2>/dev/null
    rm -f /var/tmp/usb* /var/tmp/sd* 2>/dev/null
    
    echo "Синхронизация кэша..."
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
    echo "Очистка завершена успешно!"
    echo "Рекомендуется перезагрузить систему для полного эффекта."
    echo "=========================================="
}

show_main_menu() {
    echo "=========================================="
    echo "  Очистка истории USB подключений - Linux"
    echo "=========================================="
    echo "1. Запустить очистку истории USB"
    echo "2. Просмотр истории USB подключений"
    echo "3. Показать информацию о системе"
    echo "4. Выход"
    echo "=========================================="
    
    read -p "Выберите опцию (1-4): " choice
    
    case $choice in
        1)
            check_root
            clean_usb_history
            ;;
        2)
            show_history_menu
            ;;
        3)
            echo "Информация о системе:"
            echo "Дистрибутив: $(detect_distro)"
            echo "Ядро: $(uname -r)"
            echo "Архитектура: $(uname -m)"
            ;;
        4)
            echo "Выход..."
            exit 0
            ;;
        *)
            echo "Неверный выбор. Попробуйте снова."
            show_main_menu
            ;;
    esac
}

main() {
    if [ ! -t 0 ]; then
        echo "Этот скрипт должен запускаться в терминале."
        exit 1
    fi
    
    show_main_menu
}

main "$@"