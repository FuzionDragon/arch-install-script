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

set_keymap() {
  keymaps=$(localectl list-keymaps)
  current_keymap=$(localectl | grep "VC Keymap" | awk -F ': ' '{print $2}')

  echo "Keymap setting..."
  echo

  read -p "Is the current keymap '$current_keymap' correct? (y/N): " answer
  case $answer in
    [Yy]* ) break;;
    * ) echo "Current keymap not correct, listing valid options";;
  esac

  while true; do
    read -p "Do you want to see the list of keymaps? (y/N): " answer
    if [ $answer -eq "y" ] || [ $answer -eq "Y" ];
      echo "Listing valid keymaps"
      echo "Use Up / Down arrows to scroll, press 'q' to exit"
      $keymaps | less
    fi

    read -p "Enter the desired keymap (case sensitive): " selected_keymap
    in_list=$($keymaps | grep -Fxq $selected_keymap && echo 1 || echo 0)
    if [ $in_list -eq 1 ];
      echo "Valid keymap selected"
      localectl set-keymap $selected_keymap
    else
      echo "Invalid keymap entered, try again"
    fi
  done
}

set_locale() {
  locales=$(localectl list-locales)
  current_locale=$(localectl | grep "System Locale" | awk -F ': ' '{print $2}')

  echo "Locale setting..."
  echo

  read -p "Is the current locale '$current_locale' correct? (y/N): " answer
  case $answer in
    [Yy]* ) break;;
    * ) echo "Current locale not correct, listing valid options";;
  esac

  while true; do
    read -p "Do you want to see the list of locales? (y/N): " answer
    if [ $answer -eq "y" ] || [ $answer -eq "Y" ];
      echo "Listing locales options"
      echo "Use Up / Down arrows to scroll, press 'q' to exit"
      $locales | less
    fi

    read -p "Enter the desired keymap (case sensitive): " selected_locale
    in_list=$($locales | grep -Fxq $selected_locale && echo 1 || echo 0)
    if [ $in_list -eq 1 ];
      echo "Valid locale selected"
      localectl set-locale $selected_locale
    else
      echo "Invalid locale entered, try again"
    fi
  done
}

disk_formatting() {
  disks=$(lsblk)

  echo "Disk Formatting"
  echo "Listing disks"
  echo
  echo $disks
  
  # partitioning
  while true; do
    read -p "Enter the disk you want to partition (case sensitive): " selected_disk
    in_list=$($disks | grep -Fxq $selected_disk && echo 1 || echo 0)
    if [ $in_list -eq 1 ];
      echo "Valid disk selected"
      echo "Opening cfdisk..."
      cfdisk "/dev/$selected_disk"
    else
      echo "Invalid disk entered, try again"
    fi

    read -p "Have you finished partitioning your disks (y/N)? " answer
    if [ $answer -eq "y" ] || [ $answer -eq "Y" ];
      break;
    fi
  done

  # normal formatting
  while true; do
    read -p "Enter the disk you want to partition (case sensitive): " selected_disk
    in_list=$($disks | grep -Fxq $selected_disk && echo 1 || echo 0)

    if [ $in_list -eq 1 ];
      echo "Valid disk selected"

      while true; do
        echo
        echo "File System Options:"
        echo "1) Ext4"
        echo "2) Btrfs"
        echo "3) Swap Partition"
        echo "4) Fat32"
        echo

        read -p "Which file system do you want to format this disk into? " answer
        case $answer in
          [1]* ) mkfs.ext4 "/dev/$selected_disk"; break;;
          [1]* ) mkfs.btrfs "/dev/$selected_disk"; break;;
          [1]* ) mkswap "/dev/$selected_disk"; break;;
          [1]* ) mkfs.fat -F 32 "/dev/$selected_disk"; break;;
          * ) echo "Invalid format, try again";;
        esac
      done
    else
      echo "Invalid disk entered, try again"
    fi

    read -p "Have you finished formatting your disks (y/N)? " answer
    if [ $answer -eq "y" ] || [ $answer -eq "Y" ];
      break;
    fi
  done

  # mounting formatted drives
  formatted_partitions=$(lsblk -o +FSTYPE,PATH -r -i -n)

  # 6 = type, 8 = fstype, 9 = path
  for partition in $formatted_partitions; do
    itemtype=$(formatted_partitions | awk '{print $6}')
    fstype=$(formatted_partitions | awk '{print $8}')
    path=$(formatted_partitions | awk '{print $9}')

    if [ $itemtype -eq 'part' ] || [ $itemtype -eq 'crypt' ];
      if [ $fstype -eq 'vfat' ] || [ $fstype -eq 'ext4' ] || [ $fstype -eq 'btrfs' ];
        mount $path /mnt
      elif [ $fstype -eq 'swap' ];
        swapon $path /mnt
      fi
    fi
  done
}
