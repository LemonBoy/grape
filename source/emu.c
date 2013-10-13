#include <nds.h>
#include "emu.h"

static u32 frames_done;
static u32 vblanks;

void irq_vblank ()
{
    if (vblanks++ == 60) {
        consoleClear();
        iprintf("FPS %i\n", frames_done);
        // iprintf("keybd_latch : %02x\n", keybd_latch);
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

    // Setup the video hardware
    video_init();

    // Load the appropriate bios
    if (load_bin("apple.rom", 0xD000, 0x3000, &crc)) {
        valid_crc = valid_rom_crc(crc);
        iprintf("BIOS CRC16 %04x (%s)\n", crc, (valid_crc) ? "Valid" : "Invalid");
        // Refuse to load a wrong bios
        if (!valid_crc)
            while (1);
    } else {
        iprintf("No BASIC.ROM found. Halting.");
        while (1);
    }

    // Load the disk rom in place
    load_buf(disk_rom, 0xc600, 0x100);

    basename = NULL;

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

        update_input();
        frames_done++;

        if (keysDown()&KEY_START)
            pause_menu(); 

        sound_play();

        if (emu_vsync)
            swiWaitForVBlank();
        bgUpdate();
    }
}
