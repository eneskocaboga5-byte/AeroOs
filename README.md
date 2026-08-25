# AeroOs v2.0 🚀

A ultra-lightweight, minimal Linux distribution built from scratch on Arch Linux, specifically optimized for AMD Ryzen systems. It features native dual virtual Wi-Fi simulation and a customized local package manager (`apm`).

## 🛠️ Key Features
- **Kernel Version:** Custom-built Linux Kernel 7.1.10
- **Package Manager:** `apm` (Aero Package Manager v2.0) supporting `.tar.gz` packages
- **Networking:** `mac80211_hwsim` enabled dual Wi-Fi (`wlan0`, `wlan1`) and auto-configured internet bridge (`rtl8139` / `eth0`)
- **Shell & Init:** BusyBox-powered environment with a stylized Figlet ASCII welcome banner

## 📦 Directory Structure
- `/rootfs`: Core system files, customized scripts, and the `apm` source code.
- `/linux-7.10`: Tailored kernel configuration (`.config`) and compiled `bzImage` boot source.

## 🚀 How to Run (QEMU)
Launch AeroOs instantaneously using the following hardware-accelerated QEMU command:
```bash
qemu-system-x86_64 -cpu host -enable-kvm -m 1G -kernel linux-7.10/arch/x86/boot/bzImage -initrd rootfs.img -append "root=/dev/ram0 console=ttyS0" -net nic,model=rtl8139 -net user -nographic
```

## 📜 License
This project is open-source and licensed under the terms of the **GNU General Public License v3.0 (GPL-3.0)**. The full legal text of the license can be found in the accompanying [LICENSE](./LICENSE) file. Anyone is free to copy, modify, and distribute this software, provided that all derivative works remain open-source under the same terms.

## 🤝 Contributing
Feel free to fork this project, report bugs via issues, or submit Pull Requests (PRs) to expand the `apm` ecosystem or kernel capabilities!
