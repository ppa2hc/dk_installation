# dk_installation

> Info: This repo provides a guideline to install the dreamOS.

## Prerequisites:
Git clone dk_installation repo.  
```
git clone https://github.com/ppa2hc/dk_installation.git
cd dk_installation
chmod +x *
```

## Install dreamOS
Defaut installation without IVI.  
```
sudo ./dk_install.sh
```

Or install with IVI. It is tested on Raspi5 Raspberry Pi OS and Microsoft Surface ubuntu.  
```
sudo ./dk_install.sh dk_ivi=true
```

## Uninstall dreamOS
```
sudo ./dk_uninstall.sh
```

## Notes:
The installation of dreamOS with IVI on NVidia boards (e.g., Jetson Orin, Jetson Orin Nano, Jetson Nano) are also possible. We shall provide a seperate installation file later.
