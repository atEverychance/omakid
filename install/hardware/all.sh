# Dell Inspiron 3531 / Bay Trail bounded hardware pass.
run_logged "$OMARCHY_INSTALL/hardware/network.sh"
run_logged "$OMARCHY_INSTALL/hardware/set-wireless-regdom.sh"
run_logged "$OMARCHY_INSTALL/hardware/fix-synaptic-touchpad.sh"
run_logged "$OMARCHY_INSTALL/hardware/bluetooth.sh"
run_logged "$OMARCHY_INSTALL/hardware/intel/thermald.sh"
