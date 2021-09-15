# Black Widow

FPGA implementation of [Atari Black Widow](http://spritesmods.com/?art=bwidow_fpga) by Jeroen Domburg with help from james10952001 
Rasterizer by Dave Woo and fpgaarcade.com
Port to MiSTer by Alan Steremberg

This game used two joysticks. If you hook it to an ipac/jpac style adapter, it will use joystick 1 and 2. You can use the MiSTer OSD to
map the joystick buttons for the second joystick to the digital buttons on the gamepad.

## Keyboard inputs :
```
   F1                        : Coin + Start 1P
   F2                        : Coin + Start 2P
   UP,DOWN,LEFT,RIGHT arrows : move spider

   MAME/IPAC/JPAC Style Keyboard inputs:
     5           : Coin 1
     6           : Coin 2
     1           : Start 1 Player
     2           : Start 2 Players
     R,F,D,G     : Right joystick motion
   

 Joystick support. Make sure to setup the keys specifically for this. It will use 4 buttons for a second digital joypad.
```

## Hiscore save/load

Save and load of hiscores is supported for the following games on this core:
 - Black Widow
 - Gravitar

To save your hiscores manually, press the 'Save Settings' option in the OSD.  Hiscores will be automatically loaded when the core is started.

To enable automatic saving of hiscores, turn on the 'Autosave Hiscores' option, press the 'Save Settings' option in the OSD, and reload the core.  Hiscores will then be automatically saved (if they have changed) any time the OSD is opened.

Hiscore data is stored in /media/fat/config/nvram/ as ```<mra filename>.nvm```

## ROMs
```
                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip

```
