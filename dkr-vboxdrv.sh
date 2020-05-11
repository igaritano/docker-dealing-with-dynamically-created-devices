#! /bin/sh

if test -x /usr/lib/virtualbox/VirtualBox; then
    INSTALL_DIR=/usr/lib/virtualbox
else
    # Silently exit if the package was uninstalled but not purged.
    # Applies to Debian packages only (but shouldn't hurt elsewhere)
    exit 0
fi

GROUP=vboxusers
DEVICE_MODE=0660

## Create a usb device node for a given sysfs path to a USB device.
install_create_usb_node_for_sysfs() {
    path="$1"           # sysfs path for the device
    usb_createnode="$2" # Path to the USB device node creation script
    usb_group="$3"      # The group to give ownership of the node to
    if test -r "${path}/dev"; then
        dev="`cat "${path}/dev" 2> /dev/null`"
        major="`expr "$dev" : '\(.*\):' 2> /dev/null`"
        minor="`expr "$dev" : '.*:\(.*\)' 2> /dev/null`"
        class="`cat ${path}/bDeviceClass 2> /dev/null`"
        sh "${usb_createnode}" "$major" "$minor" "$class" \
              "${usb_group}" 2>/dev/null
    fi
}

sysfs_usb_devices="/sys/bus/usb/devices/*"

## Install udev rules and create device nodes for usb access
setup_usb() {
    VBOXDRV_GRP="$1"      # The group that should own /dev/vboxdrv
    VBOXDRV_MODE="$2"     # The mode to be used for /dev/vboxdrv
    INSTALLATION_DIR="$3" # The directory VirtualBox is installed in
    USB_GROUP="$4"        # The group that should own the /dev/vboxusb device

    usb_createnode="$INSTALLATION_DIR/VBoxCreateUSBNode.sh"
    usb_group=$USB_GROUP
    vboxdrv_group=$VBOXDRV_GRP

    # Build our device tree
    for i in ${sysfs_usb_devices}; do  # This line intentionally without quotes.
        install_create_usb_node_for_sysfs "$i" "${usb_createnode}" \
                                          "${usb_group}"
    done
}

cleanup_usb()
{
    # Remove our USB device tree
    rm -rf /dev/vboxusb
}

add() {
    $(docker exec virtualbox bash -c '/usr/lib/virtualbox/VBoxCreateUSBNode.sh '$1' '$2' '$3)
}

rm() {
    $(docker exec virtualbox bash -c '/usr/lib/virtualbox/VBoxCreateUSBNode.sh --remove '$1' '$2)
}

case "$1" in
setup_usb)
    setup_usb "$GROUP" "$DEVICE_MODE" "$INSTALL_DIR"
    ;;
cleanup)
    cleanup_usb
    ;;
add)
    add "$2" "$3" "$4"
    ;;
rm)
    rm "$2" "$3"
    ;;
*)
    echo "Usage: $0 {setup_usb|cleanup}"
    exit 1
esac

exit 0
