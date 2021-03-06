#include <stdio.h>
#include <nds.h>
#include "emu.h"

typedef struct state_hdr_t {
    u32 magic;
    u8  ver;
    u8  flags;
    u16 resv;
} __attribute__((packed)) state_hdr_t;

#define STATE_MAGIC (0x47525033)

char *build_path (const int slot)
{
    static char tmp[1024];
    if (basename)
        snprintf(tmp, sizeof(tmp), "%s.%03i", basename, slot);
    else
        snprintf(tmp, sizeof(tmp), "grape.%03i", slot);
    return tmp;
}

int state_save (const int slot)
{
    FILE *f;
    state_hdr_t h;
    const char *path;

    path = build_path(slot+1);
    f = fopen(path, "wb");
    if (!f) {
        print_msg("Save failed!");
        return 0;
    }

    h.magic = STATE_MAGIC;
    h.ver = 1;
    h.flags = 0;
    h.resv = 0;

    fwrite(&h, 1, sizeof(state_hdr_t), f);

    fwrite(&cpu_regs, 6, 4, f);
    fwrite(&mainram, 1, sizeof(mainram), f);
    fwrite(&lcram, 1, sizeof(lcram), f);
    fwrite(&memmap_r, 0x10, 4, f);
    fwrite(&memmap_w, 0x10, 4, f);
    fwrite(&page_dirty, 1, 64, f);
    fwrite(&jstk_axis, 4, 4, f);
    fwrite(&jstk_btn, 3, 4, f);
    fwrite(&jstk_rst_cycle, 1, 4, f);
    fwrite(&keybd_latch, 1, 4, f);

    video_save(f);
    disk_save(f);

    fclose(f);

    return 1;
}

int state_load (const int slot)
{
    FILE *f;
    state_hdr_t h;
    const char *path;

    path = build_path(slot+1);
    f = fopen(path, "rb");
    if (!f) {
        print_msg("Load failed!");
        return 0;
    }

    fread(&h, 1, sizeof(state_hdr_t), f);

    if (h.magic != STATE_MAGIC) {
        fclose(f);
        print_msg("Invalid save file!");
        return 0;
    }

    fread(&cpu_regs, 6, 4, f);
    fread(&mainram, 1, sizeof(mainram), f);
    fread(&lcram, 1, sizeof(lcram), f);
    fread(&memmap_r, 0x10, 4, f);
    fread(&memmap_w, 0x10, 4, f);
    fread(&page_dirty, 1, 64, f);
    fread(&jstk_axis, 4, 4, f);
    fread(&jstk_btn, 3, 4, f);
    fread(&jstk_rst_cycle, 1, 4, f);
    fread(&keybd_latch, 1, 4, f);

    video_load(f);
    disk_load(f);

    fclose(f);

    return 1;
}
