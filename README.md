# Arch Linux Installation Script

An opinionated Arch Linux setup script, based on configurations I would do with some decision marking on behalf of the end user.

### Script Installation

Install the script using the following curl command:

```
$ curl -fsSL https://raw.githubusercontent.com/FuzionDragon/arch-install-script/main/install.sh -o install.sh
```

**Ensure that the contents of the script are read and verified first before running**

If you want to run the script directly instead of installing it first, run the following:

```
$ source <(curl -s https://raw.githubusercontent.com/FuzionDragon/arch-install-script/main/install.sh -o install.sh)
```

After the last step, reboot. From there, the user can run the config setup script (or run it from here as an option)

### Resources

I couldn't have completed this script without the help of these resources:
- [Arch Linux Wiki - Installation Guide](https://wiki.archlinux.org/title/Installation_guide#Prepare_an_installation_medium)
- [Arch Linux Wiki - dm-crypt/Encrypting an entire system](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system)
- [DeshiVideo - Arch Linux: An 𝔼𝕟𝕔𝕣𝕪𝕡𝕥𝕖𝕕 Guide](https://www.youtube.com/watch?v=kXqk91R4RwU&t=370s)
- [RedHat - Important Linux /proc filesystem files you need to know](https://www.redhat.com/en/blog/important-proc-files)

These were used to ensure the script covers all the required setup checks, but to also allow automation and validation of user inputs regarding hardware specs, without need for dedicated tools to be installed like lscpu.
