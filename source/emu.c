#include <nds.h>
#include "emu.h"

static u32 frames_done;
static u32 vblanks;

void irq_vblank ()
{
    if (vblanks++ == 60) {
        consoleClear();
        iprintf("FPS %i\n", frames_done);
        frames_done = 0;
        vblanks = 0;
    }
}

void emu_reset ()
{
    sound_reset();
    mem_reset();
    cpu_reset();
}

int valid_rom_crc (const u16 crc)
{
    const u16 known_crcs[] = {
        0xAC8F, // 12288 BASIC.ROM 
        0x3F44, // 12288 apple.rom
        0x9CB5, // 12288 A2ROM.BIN
    };
    int i;

    for (i = 0; i < sizeof(known_crcs)/sizeof(u16); i++)
        if (crc == known_crcs[i])
            return 1;

    return 0;
}

void emu_init ()
{
    u16 crc;
    int valid_crc;

    keyboardShow();

    // Set some sane defaults
    emu_vsync = 1;
    emu_hires = 2;
    emu_boost = 0;

    // Setup the video hardware
    video_init();
#if 1
    crc = 0xffff;
    // Load the appropriate bios
    if (load_bin("BASIC.ROM", 0xD000, 0x3000, &crc) < 0) {
        print_msg("No BASIC.ROM found. Halting.");
        while (1);
    }
        
    valid_crc = valid_rom_crc(crc);
    iprintf("BIOS CRC16 %04x (%s)\n", crc, (valid_crc) ? "Valid" : "Invalid");
    // Refuse to load the incorrect bios
    if (!valid_crc)
        while (1);

    // Load the disk rom in place
    load_buf(disk_rom, 0xc600, 0x100);

    /*mainram[0xFCA8] = 0x60;*/
#else
    if (load_bin("6502_functional_test.bin", 0x0, -1, NULL) > 0) {
        const u16 reset_patch = 0x0400;
        iprintf("Test rom loaded\n");
        iprintf("PC : %04x\n", mainram[0xFFFD]<<8|mainram[0xFFFC]);
        iprintf("Routing the reset vector to %04x\n", reset_patch);
        mainram[0xFFFC] = reset_patch&0xFF;
        mainram[0xFFFD] = (reset_patch>>8)&0xFF;
    }
#endif

    // Used by the fps counter
    frames_done = 0;
    vblanks = 0;
    // Fire the counter
    irqSet(IRQ_VBLANK, irq_vblank);
    irqEnable(IRQ_VBLANK);

    emu_reset();
}

void emu_run ()
{
    while (1) {
        cpu_run(17030);

        video_draw();

        scanKeys();

        update_input();
        frames_done++;

        if (keysDown()&KEY_START)
            pause_menu(); 

        sound_play();

        if (emu_vsync && !emu_boost)
            swiWaitForVBlank();
        bgUpdate();
    }
}
