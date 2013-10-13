grape
=====

An Apple II emulator for Nintendo DS, powered by devkitPRO, libnds and lots of
sweat. This is how I spent most of my summer nights when I couldn't sleep
because of the heat, debugging the asm core and reading the Apple II manuals.


What is emulated
================
* Apple II/II+
* Language card
* 5.25 floppy disk
* Speaker

Notes
=====

Consider it as a WIP, it lacks some stuff like configurable keymaps and
extensive testing.
The video generation takes ~50% of the CPU time and would definitely benefit
from optimization, beside the fact that it doesn't emulate color bleeding.
When playing games that make extensive use of disk IO disable vblank to make it
load faster (eg. Karateka and Pacman)
