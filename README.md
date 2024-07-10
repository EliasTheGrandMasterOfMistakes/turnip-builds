# Mesa3D Freedreno's Turnip CI releases

  This is a unofficial CI releases for Turnip Vulkan Driver from Mesa3D

## What is Turnip?

 Turnip is a open source vulkan driver from freedreno project: https://gitlab.freedesktop.org/freedreno/freedreno. Developed first think in linux and chromeos usage.
 Turnip is based on reverse engineering backed in past from Google help and now maintained with @igalia help with Open Source Mesa3D community.
 Turnip leverage all power from Mesa3D common code libraries, Queue common code, WSI, Mesa Vulkan Runtime and NIR compiler library and Intermediate Representation.

## Why Turnip is better for emulators or Termux Games usage?

  Different from Qualcomm Proprietary Drivers that targets Android, Turnip reaches Linux and Chromeos in Mind, this means
  that is trying to expose all necessary capabilities that a Linux Desktop or Linux Mobile environment depends to use.
  By leverage Mesa3D common code, Turnip can implement and gains multiples capabilities that is necessary.

  Qualcomm proprietary driver doesn't depend to target specific Linux usage and not expose a greater Vulkan version target.


### Magisk Usage

  This is designed to be used like a Magisk Module, if you reach problems just disable if are necessary.

### Out of Magisk (Non-Root) Targets.

 Is possible to install out of magisk or root devices, you will need to be in permissive rom
 and using extract vulkan.adreno.so library, You can use ADB pull or acess using Adb shell, TWRP File manager is possible too.

 Folder Location: Vendor/lib64/hw/


### Vendor 32 Libraries:
 Doesn't exist for while a 32 bits library, i recommend you to use a just 64bit rom or not use a 32 bit application if are possible


### Adreno Tools.
 Weekly will have a zip for usage in adrenotools, it's manually builded.
 You can use it in adrenotools applications
  
### Scheduled Releases
- Automated releases at 06:00 UTC on the 1st and 15th of each month.

### Notes;
- Root must be visible to target app/game.
- Tested with these apps/games listed [here](list.md).

### To Build Locally
- Obtain the script [turnip_builder.sh](https://raw.githubusercontent.com/ilhan-athn7/freedreno_turnip-CI/main/turnip_builder.sh) on your linux environment. (visit the link and use ```CTRL + S``` keys)
- Execute script on linux terminal ```bash ./turnip_builder.sh```
- To build experimental branchs, change [this](https://github.com/ilhan-athn7/freedreno_turnip-CI/blob/c704685653879114860ce4cae9629a2511c6eeea/turnip_builder.sh#L50) line, and add one more line to rename unzipped folder to mesa-main.

### References

- https://forum.xda-developers.com/t/getting-freedreno-turnip-mesa-vulkan-driver-on-a-poco-f3.4323871/

- https://gitlab.freedesktop.org/mesa/mesa/-/issues/6802

### Credits to Freedreno and Mesa3D projects.
