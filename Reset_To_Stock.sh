#!/bin/bash
# ==============================================================================
# Script: Reset_To_Stock.sh
# Directory: .usb_network/
# Device: Battle XP G350 & Rockchip RK3326 Handhelds (ArkOS / dArkOS)
# Layout: Tailored for 3.5" Handhelds (Max 42 cols x 16 rows, zero overflow)
# Purpose: Restore Console to Factory Stock State for Clean Install Testing
# ==============================================================================

# Direct output to physical display if launched from EmulationStation
if [ -z "$SSH_CONNECTION" ]; then
    for tty in /dev/tty0 /dev/tty1; do
        if [ -e "$tty" ]; then
            sudo chmod 666 "$tty" 2>/dev/null
            exec > "$tty" 2>&1
            break
        fi
    done
fi

if [ -f /usr/share/consolefonts/Lat7-TerminusBold28x14.psf.gz ]; then
    sudo setfont /usr/share/consolefonts/Lat7-TerminusBold28x14.psf.gz 2>/dev/null
fi

C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_WHITE="\033[1;37m"
C_GRAY="\033[0;37m"

clear 2>/dev/null
printf "\033[H" 2>/dev/null

echo -e "${C_CYAN}==========================================${C_RESET}"
echo -e "${C_WHITE}   RESTORE G350 TO FACTORY STOCK STATE    ${C_RESET}"
echo -e "${C_CYAN}==========================================${C_RESET}"

# 1. Restore factory DTB
echo -e "${C_YELLOW}[1/4] Restoring original factory DTB...${C_RESET}"
if [ -s /boot/rk3326-g350-linux.dtb.original ]; then
    sudo cp /boot/rk3326-g350-linux.dtb.original /boot/rk3326-g350-linux.dtb 2>/dev/null
    sync
    echo -e "      ${C_GREEN}-> Factory DTB restored (dr_mode=otg).${C_RESET}"
else
    echo -e "      ${C_GRAY}-> Backup not found (already stock).${C_RESET}"
fi

# 2. Remove generated DTB profiles
echo -e "${C_YELLOW}[2/4] Removing generated DTB profiles...${C_RESET}"
sudo rm -f /boot/rk3326-g350-peripheral.dtb 2>/dev/null
sudo rm -f /boot/rk3326-g350-host.dtb 2>/dev/null
sudo rm -f /boot/rk3326-g350-linux.dtb.original 2>/dev/null
sync
echo -e "      ${C_GREEN}-> Generated profiles removed.${C_RESET}"

# 3. Remove Netplay role memory
echo -e "${C_YELLOW}[3/4] Resetting role configuration...${C_RESET}"
sudo rm -f /home/ark/.config/c2c_role 2>/dev/null
sudo rm -f /etc/c2c_role 2>/dev/null
sync
echo -e "      ${C_GREEN}-> First-launch state reset.${C_RESET}"

# 4. Reset RetroArch Netplay settings to default
echo -e "${C_YELLOW}[4/4] Resetting RetroArch configs...${C_RESET}"
for cfg in \
    /home/ark/.config/retroarch/retroarch.cfg \
    /home/ark/.config/retroarch32/retroarch.cfg \
    /opt/retroarch/config/retroarch.cfg \
    /opt/retroarch/retroarch.cfg; do
    if [ -f "$cfg" ]; then
        sudo sed -i 's/^netplay_use_relay_server.*/netplay_use_relay_server = "true"/' "$cfg" 2>/dev/null
        sudo sed -i 's/^netplay_nat_traversal.*/netplay_nat_traversal = "true"/' "$cfg" 2>/dev/null
        sudo sed -i 's/^netplay_ip_address.*/netplay_ip_address = ""/' "$cfg" 2>/dev/null
        sudo chown ark:ark "$cfg" 2>/dev/null
    fi
done

sudo rm -rf /tmp/c2c_netplay /tmp/c2c_state 2>/dev/null
sync
echo -e "      ${C_GREEN}-> RetroArch & runtime cache clean.${C_RESET}"

echo -e "${C_CYAN}==========================================${C_RESET}"
echo -e "${C_GREEN} SUCCESS: Console is back to stock state! ${C_RESET}"
echo -e "${C_WHITE} Rebooting in 3 seconds...                ${C_RESET}"
echo -e "${C_CYAN}==========================================${C_RESET}"
sleep 3
sudo reboot
