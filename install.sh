#!/usr/bin/bash

#
# Arch Linux Installation
#

#
# Checklist (based on Arch wiki guide)
# - Keymaps
# - Encyption Option
# - Password and Login
# - Internet
# - System Clock
# - Disk Picker / Partitioning
# - Disk Formatting
# - Disk Mounting
# - Root and Fstab
# - Localization
# - Time
# - Network Config
# - Root Password
# - Bootloader (probably just Grub)
#
# After the last step, reboot. From there, the user can run the config setup script (or run it from here as an option)
#
# make use of the 'less' command
#

#
# Keymaps
#

keymaps=$(localectl list-keymaps)
current_keymap=$($keymaps | grep "VC Keymap" | awk -F ':' '{print $2}')

while true; do
  read -p "Is the current keymap '$current_keymap' correct? (Y/N): " answer
    case $answer in
        [Yy]* ) break;;
        [Nn]*) 
          break;;
        * ) echo "Please answer Y or N.";;
    esac
done

disks=$(lsblk)
