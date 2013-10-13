#include <nds.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "emu.h"

// Working buffer
static u8 diskbuf[35*6656];

static int Q6, Q7;
static int motor_on;
static int phase;
static int last_stepper;
static int track_start, track_pos;
static int sel_disk;

void disk_save (FILE *f)
{
    fwrite(&Q6, 1, 4, f);
    fwrite(&Q7, 1, 4, f);
    fwrite(&motor_on, 1, 4, f);
    fwrite(&phase, 1, 4, f);
    fwrite(&last_stepper, 1, 4, f);
    fwrite(&track_start, 1, 4, f);
    fwrite(&track_pos, 1, 4, f);
    fwrite(&sel_disk, 1, 4, f);
}

void disk_load (FILE *f)
{
    fread(&Q6, 1, 4, f);
    fread(&Q7, 1, 4, f);
    fread(&motor_on, 1, 4, f);
    fread(&phase, 1, 4, f);
    fread(&last_stepper, 1, 4, f);
    fread(&track_start, 1, 4, f);
    fread(&track_pos, 1, 4, f);
    fread(&sel_disk, 1, 4, f);
}

u8 disk_io_read (u16 addr) ITCM_CODE;
u8 disk_io_read (u16 addr)
{
    int set;
    int stepper;
    int delta;

    set = addr&1;
    stepper = (addr>>1)&3;

    switch (addr&0xf) {
        case 0x1:
        case 0x3:
        case 0x5:
        case 0x7:
            if (motor_on) {
                delta = 0;
                if (stepper == ((last_stepper + 1)&3))
                    delta += 1;
                if (stepper == ((last_stepper + 3)&3))
                    delta -= 1;
                last_stepper = stepper;
                if (delta) {
                    phase += delta;
                    if (phase < 0)
                        phase = 0;
                    if (phase > 70)
                        phase = 70;
                    /*track_pos = 0;*/
                    track_start = (phase >> 1) * 6656;
                }
            }
            return 0xff;
        case 0x0:
        case 0x2:
        case 0x4:
        case 0x6:
            return 0xff;
        // ENABLE
        case 0x8:
        case 0x9:
            motor_on = set;
            return 0xff;
        // SELECT
        case 0xa:
        case 0xb:
            sel_disk = set;
            return 0xff;
        // Q6L
        case 0xc:
            Q6 = 0;
            if (!Q7) {
                // The tracks are circular, so wrap around
                if (track_pos >= 6656) track_pos = 0;
                return diskbuf[track_start + (track_pos++)];
            }
            // Handshake register
            return 0x80;
        // Q6H
        case 0xd:
            Q6 = 1;
            return 0;
        // Q7
        case 0xe:
        case 0xf:
            Q7 = set;
            // The status register is read from Q7L
            return 0x20|0x80; // Write protect and ready
    }
    return 0xff;
}

int load_nib_disk (const char *file)
{
    FILE *f;
    size_t size;

    f = fopen(file, "rb");

    if (!f)
        return 0;

    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (size != 232960) {
        iprintf("Size mismatch\n");
        fclose(f);
        return 0;
    }
    fread(diskbuf, 1, 232960, f);
    fclose(f);

    return 1;
}

// DOS 3.3 format 35 T 16 S (343 nybbles)
// http://www.umich.edu/~archive/apple2/misc/hardware/disk.encoding.txt
// http://mirrors.apple2.org.za/ground.icaen.uiowa.edu/MiscInfo/Programming/c600.disasm
// http://www.mac.linux-m68k.org/devel/iwm.php
// http://www.textfiles.com/apple/ANATOMY/t.dos.b800.bcff.txt

const u8 dos33table[] = {
    0x96, 0x97, 0x9A, 0x9B, 0x9D, 0x9E, 0x9F, 0xA6,
    0xA7, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xB2, 0xB3,
    0xB4, 0xB5, 0xB6, 0xB7, 0xB9, 0xBA, 0xBB, 0xBC,
    0xBD, 0xBE, 0xBF, 0xCB, 0xCD, 0xCE, 0xCF, 0xD3,
    0xD6, 0xD7, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE,
    0xDF, 0xE5, 0xE6, 0xE7, 0xE9, 0xEA, 0xEB, 0xEC,
    0xED, 0xEE, 0xEF, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6,
    0xF7, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF
};
const int dos_order[] = {
    0x0, 0x7, 0xE, 0x6, 0xD, 0x5, 0xC, 0x4, 0xB, 0x3, 0xA, 0x2, 0x9, 0x1, 0x8, 0xF
};
const int prodos_order[] = {
    0x0, 0x8, 0x1, 0x9, 0x2, 0xA, 0x3, 0xB, 0x4, 0xC, 0x5, 0xD, 0x6, 0xE, 0x7, 0xF
};

void write_address (u8 *b, u8 track, u8 sector, u8 volume)
{
    // Handy macros for 4 and 4 encoding
#define X1(x) (((x)>>1)|0xAA)
#define X2(x) ((x)|0xAA)
    b[0]  = 0xD5;
    b[1]  = 0xAA;
    b[2]  = 0x96;
    b[3]  = X1(volume);
    b[4]  = X2(volume);
    b[5]  = X1(track);
    b[6]  = X2(track);
    b[7]  = X1(sector);
    b[8]  = X2(sector);
    b[9]  = X1(volume^track^sector);
    b[10] = X2(volume^track^sector);
    b[11] = 0xDE;
    b[12] = 0xAA;
    b[13] = 0xEB;
#undef X1
#undef X2
}

// GAP + (ADDRESS + GAP + DATA + GAP)
#define GAP1_LEN    48
#define GAP2_LEN    6
#define GAP3_LEN    27
#define ADDRESS_LEN 14  // 3 + 2 + 2 + 2 + 2 + 3
#define DATA_LEN    349 // 3 + 342 + 1 + 3

int load_dsk_disk (const char *file, const int *sec_order)
{
    FILE *f;
    size_t size;
    u8 sec_buf[256];
    u8 nib_buf[343];
    u8 *p, chksum;
    int i, j, k;

    f = fopen(file, "rb");
    
    if (!f)
        return 0;

    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (size > 143360) {
        iprintf("Size mismatch\n");
        fclose(f);
        return 0;
    }

    p = diskbuf;

    memset(p, 0xff, sizeof(diskbuf));

    // Crunch all the tracks 
    for (i = 0; i < 35; i++) {
        p += 64;
        // Crunch all the sectors
        for (j = 0; j < 16; j++) {
            fseek(f, 256 * sec_order[j] + (i * 16 * 256), SEEK_SET);
            fread(sec_buf, 1, 256, f);
            // 0xFE is the default volume
            write_address(p, i, j, 0xFE);           
            p += 14;
            // Second sync gap
            p += 4;
            // Data marker
            p[0] = 0xD5; p[1] = 0xAA; p[2] = 0xAD;  
            p += 3;
            // Convert to 6bit, the stashed bits start at 0
            memset(nib_buf, 0, sizeof(nib_buf));
            for (k = 0; k < 256; k++) {
                u8 v = sec_buf[k];
                nib_buf[k+86]  = v >> 2;
                nib_buf[k%86] |= ((v&1) << 1 | (v&2) >> 1) << (2 * (k/86));
            }
            chksum = 0;
            for (k = 0; k < 342; k++) {
                *p++ = dos33table[chksum^nib_buf[k]];
                chksum = nib_buf[k];
            }
            // Write the checksum
            *p++ = dos33table[chksum];
            // Write the last marker
            p[0] = 0xDE; p[1] = 0xAA; p[2] = 0xEB;
            p += 3;
            p += 45;
        }
    }

    fclose(f);

    return 1;
}

int load_disk (const char *path)
{
    char *ext;

    ext = strrchr(path, '.');
    if (!ext)
        return 0;

    if (!stricmp(ext + 1, "dsk") || !stricmp(ext + 1, "do"))
        return load_dsk_disk(path, dos_order);

    if (!stricmp(ext + 1, "po"))
        return load_dsk_disk(path, prodos_order);

    if (!stricmp(ext + 1, "nib"))
        return load_nib_disk(path);

    return 0;
}
