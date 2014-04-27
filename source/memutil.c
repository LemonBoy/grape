#include <nds.h>
#include <stdio.h>
#include <stdint.h>
#include "cpu.h"
#include "mem.h"

ssize_t load_buf (const u8 *buf, const u32 addr, const ssize_t len)
{
    if (addr + len > 0x10000) {
        iprintf("oob\n");
        return -1;
    }
    memcpy(mainram + addr, buf, len);

    return len;
}

ssize_t load_bin (const char *file, const u32 addr, const ssize_t len, u16 *crc)
{
    FILE *f;
    size_t read, bin_len;

    f = fopen(file, "rb");
    if (!f) {
        iprintf("Can't open %s\n", file);
        return -1;
    }

    if (len < 0) {
        fseek(f, 0, SEEK_END);
        bin_len = ftell(f);
        fseek(f, 0, SEEK_SET);
    } else
        bin_len = len;

    if (addr + bin_len > 0x10000) {
        bin_len = 0x4000;
        iprintf("oob\n");
        fclose(f);
        return -1;
    }
    read = fread(mainram + addr, 1, bin_len, f);
    fclose(f);
    iprintf("Read %x to %x\n", read, addr);

    if (crc)
        *crc = swiCRC16(0xffff, mainram + addr, read);

    return read;
}

