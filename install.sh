#!/usr/bin/bash

#
# Arch Linux Installation
#
# You are currently running a Bash install script for Arch Linux.
#
# Ensure this script in ran on either a VM or a fresh install of Arch Linux before you decide to use it.
#
# The decisions made for this script are primarily for an opinionated installation and configuration of a single boot Arch Linux install.
#
# I personally don't need to be careful of a separate boot (like Windows), and so this script could damage or wipe any existing operating systems on the chosen disks.
#
# It aims to be minimal and efficient, requiring as little user input as possible to achieve an installation that I would typically use.
#
#
# Checklist (based on Arch wiki guide)
# - Encyption Option (Disk formatting option)
# - Bootloader (probably just Grub)
#
# After the last step, reboot. From there, the user can run the config setup script (or run it from here as an option)
#

main() {
  echo "You are currently running a Bash install script for Arch Linux."
  echo "Ensure this system is either a VM or a fresh install of Arch Linux before you decide to use it."
  echo "The decisions made for this script are primarily for an opinionated installation and configuration of a single boot Arch Linux install."
  echo "It aims to be minimal and efficient, requiring minimal user input to "

  echo
  echo "Installation Options:"
  echo "1) Manual"
  echo "2) Auto"
  echo "3) Exit (No Install)"
  read -p "Selection: " selection

  case $selection in
    [1]* ) manual_setup; break;;
    [2]* ) auto_setup; break;;
    * ) echo "Exiting installer"; return 0;;
  esac
}

# Based on my typical hardware, setup, and locale needs
# Could be changed in the future but these are my defaults and what I would typically do during setup
# Could make encryption be optional, but will make it a default
#
# Some settings require user input due to security reasons
#
auto_setup() {
  # pre root setup
  setup_disk_formatting

  echo "TwoFace" > /etc/hostname

  timedatectl set-timezone Etc/GMT
  setup_user_details
  setup_internet

  configure_pacman

  setup_root
  chroot /mnt

  # system configuration
  setup_package_configs
  localectl set-keymap uk
  localectl set-locale LANG=en_GB.utf-8
  generate_fstab
}

manual_setup() {
  # setup checking vars
  #
  # ps: forgive this awful code I will need to write for all these checks
  
  # Pre Root Setup
  disk_formatted=" "
  internet_setup=" "
  hostname_setup=" "
  user_details_setup=" "
  timezone_setup=" "

  all_complete=false

  while true; do
    echo "Initial Setup Options:"
    echo "1) Disk Formatting [$disk_formatted]"
    echo "2) Internet [$internet_setup]"
    echo "3) Hostname [$hostname_setup]"
    echo "4) Timezone [$timezone_setup]"
    echo "5) User Details [$user_details_setup]"
    if [ $all_complete = true ]; then
      echo "10) Proceed to system configuration" 
    else
      echo "10) Proceed to system configuration [Not Available]" 
    fi
    echo "99) Exit Installer"

    read -p "Choose an option: " selection
    case $selection in
      [1]* ) setup_disk_formatting && $disk_formatted="/";;
      [2]* ) setup_internet && $internet_setup="/";;
      [3]* ) setup_hostname && $hostname_setup="/";;
      [4]* ) setup_timezone && $timezone_setup="/"; break;;
      [5]* ) setup_user_details && $user_details_setup="/"; break;;
      [10]* ) 
          if [ $all_complete = true ]; then
            configure_pacman
            setup_root
            chroot /mnt
            break
          else 
            echo "Please complete the rest of the setup before continuing."
          fi ;;
      [99]* ) echo "Exiting installer"; return 0;;
      * ) echo "Select appropriate option";;
    esac
  done

  # Post Root Setup
  locale_setup=" "
  keymap_setup=" "
  package_setup=" "

  all_complete=false

  while true; do
    echo "System Setup Options:"
    echo "1) Locale [$timezone_setup]"
    echo "2) Keymap [$keymap_setup]"
    echo "3) Package Setup [$package_setup]"
    if [ $all_complete = true ]; then
      echo "10) Finish Installation" 
    else
      echo "10) Finish Installation [Not Available]" 
    fi
    echo "99) Exit Installer"

    read -p "Choose an option: " selection
    case $selection in
      [1]* ) setup_locale && $locale_setup="/"; break;;
      [2]* ) setup_keymap && $keymap_setup="/"; break;;
      [3]* ) setup_package_configs && $package_setup="/"; break;;
      [10]* ) 
        generate_fstab
        echo "Installation complete, run reboot and boot into your install."
        ;;
      [99]* ) echo "Exiting installer"; return 0;;
      * ) echo "Select appropriate option";;
    esac
  done
}

# need to look into further, as proper way of setting up timezone requires a symlink to /usr/share/zoneinfo/* file into /etc/timezone, followed by hwclock --systohc command
set_timezone() {
  timezones=$(timedatectl list-timezones)
  current_zone=$(timedatectl | grep "Time zone" | awk -F ':' '{print $2}' | awk '{print $1}')

  echo "Timezone setting..."
  echo

  read -p "Is the current timezone '$current_timezone' correct? (y/N): " answer
  case $answer in
    [Yy]* ) break;;
    * ) echo "Current timezone not correct, listing valid options";;
  esac

  while true; do
    read -p "Do you want to see the list of timezones? (y/N): " answer
    if [ $answer = "y" ] || [ $answer = "Y" ]; then
      echo "Listing timezone options"
      echo "Use Up / Down arrows to scroll, press 'q' to exit"
      $timezones | less
    fi

    read -p "Enter the desired timezone (case sensitive): " selected_timezone
    in_list=$($timezones | grep -Fxq $selected_timezone && echo 1 || echo 0)
    if [ $in_list -eq 1 ]; then
      echo "Valid timezone selected"
      timedatectl set-timezone $selected_timezone
    fi
  done
}

setup_keymap() {
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
    if [ $answer = "y" ] || [ $answer = "Y" ]; then
      echo "Listing valid keymaps"
      echo "Use Up / Down arrows to scroll, press 'q' to exit"
      $keymaps | less
    fi

    read -p "Enter the desired keymap (case sensitive): " selected_keymap
    in_list=$($keymaps | grep -Fxq $selected_keymap && echo 1 || echo 0)
    if [ $in_list -eq 1 ]; then
      echo "Valid keymap selected"
      echo "KEYMAP=$selected_keymap" > /etc/vconsole.conf
      localectl set-keymap $selected_keymap
    else
      echo "Invalid keymap entered, try again"
    fi
  done
}

# requires chroot into arch install first
setup_locale() {
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
    if [ $answer = "y" ] || [ $answer = "Y" ]; then
      echo "Listing locales options"
      echo "Use Up / Down arrows to scroll, press 'q' to exit"
      $locales | less
    fi

    read -p "Enter the desired keymap (case sensitive): " selected_locale
    in_list=$($locales | grep -Fxq $selected_locale && echo 1 || echo 0)
    if [ $in_list -eq 1 ]; then
      echo "Valid locale selected"
      sed --in-place 's/#$selected_locale/$selected_locale/g' /etc/locale.gen
      locale-gen
      echo "LANG=$selected_locale" > /etc/locale.conf
      localectl set-locale $selected_locale
    else
      echo "Invalid locale entered, try again"
    fi
  done
}

# User Input Required
#
# doesn't handle functions like partition labelling and etc (use a tool like Gparted for in the future)
setup_disk_formatting() {
  disks=$(lsblk)

  echo "Disk Formatting"
  echo "Listing disks"
  echo
  echo $disks
  
  # partitioning
  while true; do
    read -p "Enter the disk you want to partition (case sensitive): " selected_disk
    in_list=$($disks | grep -Fxq $selected_disk && echo 1 || echo 0)
    if [ $in_list -eq 1 ]; then
      echo "Valid disk selected"
      echo "Opening cfdisk..."
      cfdisk "/dev/$selected_disk"
    else
      echo "Invalid disk entered, try again"
      read -p "Would you like to see all your disks and partitions again? (y/N): " answer
      if [ $answer = "y" ] || [ $answer = "Y" ]; then
        lsblk
      fi
    fi

    read -p "Have you finished partitioning your disk (y/N)? " answer
    if [ $answer = "y" ] || [ $answer = "Y" ]; then
      break;
    fi
  done

  # normal formatting
  while true; do
    read -p "Enter the disk you want to partition (case sensitive): " selected_disk
    in_list=$($disks | grep -Fxq $selected_disk && echo 1 || echo 0)

    if [ $in_list -eq 1 ]; then
      echo "Valid disk selected"

      while true; do
        echo
        echo "File System Options:"
        echo "1) Ext4"
        echo "2) Btrfs"
        echo "3) Swap Partition"
        echo "4) Fat32"
        echo

        read -p "Which file system do you want to format this partition into? " answer
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
      read -p "Would you like to see all your disks and partitions again? (y/N): " answer
      if [ $answer = "y" ] || [ $answer = "Y" ]; then
        lsblk
      fi
    fi

    read -p "Have you finished formatting your disks (y/N)? " answer
    if [ $answer = "y" ] || [ $answer = "Y" ]; then
      break;
    fi
  done

  echo "Mounting partitions"
  # mounting formatted drives
  formatted_partitions=$(lsblk -o +FSTYPE,PATH -r -i -n)

  # 6 = type, 8 = fstype, 9 = path
  for partition in $formatted_partitions; do
    itemtype=$(formatted_partitions | awk -F '[ ]' '{print $6}')
    fstype=$(formatted_partitions | awk -F '[ ]' '{print $8}')
    path=$(formatted_partitions | awk -F '[ ]' '{print $9}')

    # will assume any vfat partitions are meant for the bootloader
    if [ $itemtype = 'part' ] || [ $itemtype = 'crypt' ]; then
      if [ $fstype = 'vfat' ] || [ $fstype = 'ext4' ] || [ $fstype = 'btrfs' ]; then
        mount $path /mnt
      elif [ $fstype = 'vfat' ]; then
        mkdir /mnt/boot
        mount $path /mnt/boot
      elif [ $fstype = 'swap' ]; then
        swapon $path /mnt
      fi
    fi
  done
}

configure_pacman() {
  echo "Adjusting settings based on CPU core count"
  echo "Also making more opinionated settings"

  thread_count=$(cat /proc/cpuinfo | grep -m 1 siblings | awk -F ': ' '{print $2}')

  # first, adjust parallel downloads to make full use of devices thread count
  # should speed up download speed, assuming internet is also fast
  sed --in-place 's/ParallelDownloads*/ParallelDownloads = $thread_count/g' /etc/pacman.conf
  sed --in-place 's/#CheckSpace/CheckSpace/g' /etc/pacman.conf
  sed --in-place 's/#DownloadUser = alpm/DownloadUser = alpm/g' /etc/pacman.conf
  sed --in-place 's/#VerbosePkgLists/VerbosePkgLists/g' /etc/pacman.conf
  sed --in-place 's/#Color/Color/g' /etc/pacman.conf
  sed '/Color/a ILoveCandy' /etc/pacman.conf
}

# User Input Required
# requires chroot into arch install first
setup_package_configs() {
  # pacstrapping necessary packages to install
  echo "Package installation and config setup"

  read -p "Do you want to enable AUR packages? (Y/n): " answer
  if [ $answer != "N" ] || [ $answer != "n" ]; then
    sed --in-place 's/#[multilib]\n#Include = /etc/pacman.conf/[multilib]\nInclude = /mnt/etc/pacman.conf/g'

    # my chosen AUR helper is Paru, but can be changed post install
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ../
    rm -rf paru
  fi
}

generate_fstab() {
  genfstab -U /mnt > /mnt/etc/fstab
}

setup_root() {
  pacstrap /mnt base base-devel linux linux-firmware git lvm2 vim nvim nano cryptsetup networkmanager zsh efibootmgr
}

# User Input Required
# requires chroot into arch install first
setup_hostname() {
  while true; do
    read -p "Enter a system hostname: " hostname

    read -p "Are you happy with the hostname $hostname? (y/N) " answer
    if [ $answer = "y" ] || [ $answer = "Y" ]; then
      echo $hostname > /etc/hostname
    fi
  done
}

# User Input Required
# requires chroot into arch install first
setup_user_details() {
  # setup root and local username / hostname and password
  # also grant user root permissions
  # will set shell to Zsh by default, although that can be changed post install

  echo "Setting Sudoers details"
  echo "Be very cafeful when modifying this file" 
  echo "Look for the line that contains '%wheel ALL=(ALL:ALL) ALL' and remove the '#' at the front."
  read -p "Use Vim or Nano to edit this file? (1: Nano (default) | 2: Vim)" answer
  if [ $answer -eq 2 ]; then
    visudo
  else
    EDITOR=nano visudo
  fi

  while true; do
    echo "Setting root user password"
    passwd
  done

  while true; do
    echo "Setting username and password"

    read -p "Enter a username: " username

    read -p "Are you happy with the username $username? (y/N) " answer
    if [ $answer = "y" ] || [ $answer = "Y" ]; then
      useradd -m -G wheel -s /bin/zsh $username

      while true; do
        read -p "Do you want to set a password? (y/N) " answer
        if [ $answer = "y" ] || [ $answer = "Y" ]; then
          echo "No password set for user: $username"
          break
        else
          passwd $username
        fi
      done
    fi
  done
}

# User Input Required
# requires chroot into arch install first
setup_internet() {
  # Not needed for devices connected to Ethernet
  nmtui

  systemctl enable NetworkManager
}

setup_bootloader() {
  echo test
}
