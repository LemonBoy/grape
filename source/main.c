#include <nds.h>
#include <filesystem.h> 
#include <fat.h>
#include <stdio.h>
#include "emu.h"

int main(int argc, char **argv) 
{
    defaultExceptionHandler();
    consoleDebugInit(DebugDevice_NOCASH);

    consoleDemoInit();
    keyboardDemoInit();

    fatInitDefault();
    nitroFSInit(NULL);

    soundEnable();

    iprintf("-- grape\n");
    
    emu_init();

    if (argc != 2) {
        /*load_disk("Airheart (1986)(Broderbund)[cr].dsk");*/
        // Slow loading
        /*load_disk("PACMAN.DSK");*/
        /*load_disk("Karateka (1984)(Broderbund).dsk");*/
        // Awesome!
        /*load_disk("lode.dsk");*/
        // AppleII+
        /*load_disk("Prince of Persia (1989)(Broderbund)(Disk 1 of 3)[cr].dsk");*/
        // Gfx heavy
        /*load_disk("Starglider (19xx)(Rainbird).dsk");*/
        // Undocumented OPs
        /*load_disk("Ms. Pacman (19xx)(-)[cr].dsk");*/
        /*load_disk("Round About (1983)(Datamost).dsk");*/
        /*load_disk("Bug Attack (1981)(Cavalier Computer).dsk");*/
        // Scroller
        /*load_disk("TetrisII.DSK");*/
        // Mixed mode
        /*load_disk("tetris48k.nib");*/
        // Lowres
        /*load_disk("Fracas (1980)(Quality Software).dsk");*/
        /*load_disk("Colorix.dsk");*/
        /*load_disk("LoRes Games.DSK");*/
        load_disk("LoRes Hijinks.DSK");
        // SP Crash
        /*load_disk("Apple II Business Graphics 1.0 (1981).nib");*/
    } else {
        load_disk(argv[1]);
    }

    emu_run();

    return 0;
}
