#include <nds.h>
#include <stdio.h>
#include <stdint.h>
#include "cpu.h"
#include "mem.h"

int load_buf (const u8 *buf, u16 addr, u16 len)
{
    if (addr + len > 0x10000) {
        iprintf("oob\n");
        return 0;
    }
    memcpy(mainram + addr, buf, len);

    return 1;
}

int load_bin (char *file, u16 addr, u16 len, u16 *crc)
{
    FILE *f;

    if (addr + len > 0x10000) {
        iprintf("oob\n");
        return 0;
    }
    f = fopen(file, "rb");
    if (!f) {
        iprintf("Can't open %s\n", file);
        return 0;
    }
    fread(mainram + addr, 1, len, f);
    fclose(f);

    if (crc)
        *crc = swiCRC16(0xffff, mainram + addr, len);

    return 1;
}

