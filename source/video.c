#include <stdio.h>
#include <nds.h>
#include "mem.h"

const u8 apple_font[] = {
    0x00, 0x70, 0x88, 0xa8, 0xe8, 0x68, 0x08, 0xf0, 0x00, 0x20, 0x50, 0x88, 0x88, 0xf8, 0x88, 0x88,
    0x00, 0x78, 0x88, 0x88, 0x78, 0x88, 0x88, 0x78, 0x00, 0x70, 0x88, 0x08, 0x08, 0x08, 0x88, 0x70,
    0x00, 0x78, 0x88, 0x88, 0x88, 0x88, 0x88, 0x78, 0x00, 0xf8, 0x08, 0x08, 0x78, 0x08, 0x08, 0xf8,
    0x00, 0xf8, 0x08, 0x08, 0x78, 0x08, 0x08, 0x08, 0x00, 0xf0, 0x08, 0x08, 0x08, 0xc8, 0x88, 0xf0,
    0x00, 0x88, 0x88, 0x88, 0xf8, 0x88, 0x88, 0x88, 0x00, 0x70, 0x20, 0x20, 0x20, 0x20, 0x20, 0x70,
    0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x88, 0x70, 0x00, 0x88, 0x48, 0x28, 0x18, 0x28, 0x48, 0x88,
    0x00, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0xf8, 0x00, 0x88, 0xd8, 0xa8, 0xa8, 0x88, 0x88, 0x88,
    0x00, 0x88, 0x88, 0x98, 0xa8, 0xc8, 0x88, 0x88, 0x00, 0x70, 0x88, 0x88, 0x88, 0x88, 0x88, 0x70,
    0x00, 0x78, 0x88, 0x88, 0x78, 0x08, 0x08, 0x08, 0x00, 0x70, 0x88, 0x88, 0x88, 0xa8, 0x48, 0xb0,
    0x00, 0x78, 0x88, 0x88, 0x78, 0x28, 0x48, 0x88, 0x00, 0x70, 0x88, 0x08, 0x70, 0x80, 0x88, 0x70,
    0x00, 0xf8, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x70,
    0x00, 0x88, 0x88, 0x88, 0x88, 0x88, 0x50, 0x20, 0x00, 0x88, 0x88, 0x88, 0xa8, 0xa8, 0xd8, 0x88,
    0x00, 0x88, 0x88, 0x50, 0x20, 0x50, 0x88, 0x88, 0x00, 0x88, 0x88, 0x50, 0x20, 0x20, 0x20, 0x20,
    0x00, 0xf8, 0x80, 0x40, 0x20, 0x10, 0x08, 0xf8, 0x00, 0xf8, 0x18, 0x18, 0x18, 0x18, 0x18, 0xf8,
    0x00, 0x00, 0x08, 0x10, 0x20, 0x40, 0x80, 0x00, 0x00, 0xf8, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xf8,
    0x00, 0x00, 0x00, 0x20, 0x50, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x20,
    0x00, 0x50, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x50, 0x50, 0xf8, 0x50, 0xf8, 0x50, 0x50,
    0x00, 0x20, 0xf0, 0x28, 0x70, 0xa0, 0x78, 0x20, 0x00, 0x18, 0x98, 0x40, 0x20, 0x10, 0xc8, 0xc0,
    0x00, 0x10, 0x28, 0x28, 0x10, 0xa8, 0x48, 0xb0, 0x00, 0x20, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x20, 0x10, 0x08, 0x08, 0x08, 0x10, 0x20, 0x00, 0x20, 0x40, 0x80, 0x80, 0x80, 0x40, 0x20,
    0x00, 0x20, 0xa8, 0x70, 0x20, 0x70, 0xa8, 0x20, 0x00, 0x00, 0x20, 0x20, 0xf8, 0x20, 0x20, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x20, 0x10, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x80, 0x40, 0x20, 0x10, 0x08, 0x00,
    0x00, 0x70, 0x88, 0xc8, 0xa8, 0x98, 0x88, 0x70, 0x00, 0x20, 0x30, 0x20, 0x20, 0x20, 0x20, 0x70,
    0x00, 0x70, 0x88, 0x80, 0x60, 0x10, 0x08, 0xf8, 0x00, 0xf8, 0x80, 0x40, 0x60, 0x80, 0x88, 0x70,
    0x00, 0x40, 0x60, 0x50, 0x48, 0xf8, 0x40, 0x40, 0x00, 0xf8, 0x08, 0x78, 0x80, 0x80, 0x88, 0x70,
    0x00, 0xe0, 0x10, 0x08, 0x78, 0x88, 0x88, 0x70, 0x00, 0xf8, 0x80, 0x40, 0x20, 0x10, 0x10, 0x10,
    0x00, 0x70, 0x88, 0x88, 0x70, 0x88, 0x88, 0x70, 0x00, 0x70, 0x88, 0x88, 0xf0, 0x80, 0x40, 0x38,
    0x00, 0x00, 0x00, 0x20, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x20, 0x20, 0x10,
    0x00, 0x40, 0x20, 0x10, 0x08, 0x10, 0x20, 0x40, 0x00, 0x00, 0x00, 0xf8, 0x00, 0xf8, 0x00, 0x00,
    0x00, 0x10, 0x20, 0x40, 0x80, 0x40, 0x20, 0x10, 0x00, 0x70, 0x88, 0x40, 0x20, 0x20, 0x00, 0x20
};

static const u16 video_addr[] DTCM_DATA = {
    0x000, 0x080, 0x100, 0x180,
    0x200, 0x280, 0x300, 0x380,
    0x028, 0x0a8, 0x128, 0x1a8,
    0x228, 0x2a8, 0x328, 0x3a8,
    0x050, 0x0d0, 0x150, 0x1d0,
    0x250, 0x2d0, 0x350, 0x3d0
};

static const u16 palette[] = {
    RGB15(0, 0, 0),
    RGB15(28, 4, 12),
    RGB15(12, 9, 23),
    RGB15(31, 8, 31),
    RGB15(0, 20, 12),
    RGB15(19, 19, 19),
    RGB15(2, 25, 31),
    RGB15(25, 24, 31),
    RGB15(12, 14, 0),
    RGB15(31, 13, 7),
    RGB15(19, 19, 19),
    RGB15(31, 19, 25),
    RGB15(2, 30, 7),
    RGB15(25, 27, 17),
    RGB15(14, 31, 25),
    RGB15(31, 31, 31),
};

static int text_bg;
static int gfx_bg;

static int text_mode;
static int mixed_mode;
static int sel_page;
static int hires;

static void (* draw_hires_line)(u16 *, u8 *);

// The mixed mode can be enabled only if graphic mode is set
#define render_mixed_mode (mixed_mode&(!text_mode))

void video_set_mode ();

void video_save (FILE *f)
{
    fwrite(&text_mode, 1, 4, f);
    fwrite(&mixed_mode, 1, 4, f);
    fwrite(&sel_page, 1, 4, f);
    fwrite(&hires, 1, 4, f);
}

void video_load (FILE *f)
{
    fread(&text_mode, 1, 4, f);
    fread(&mixed_mode, 1, 4, f);
    fread(&sel_page, 1, 4, f);
    fread(&hires, 1, 4, f);

    video_set_mode();
}

void video_set_mode ()
{
    if (render_mixed_mode) {
        bgShow(gfx_bg);
        bgShow(text_bg);
        REG_DISPCNT |= DISPLAY_WIN0_ON;
    } else {
        bgShow(text_mode ? text_bg : gfx_bg);
        bgHide(text_mode ? gfx_bg : text_bg);
        REG_DISPCNT &= ~DISPLAY_WIN0_ON;
    }
}

u8 video_io_read (u16 addr) ITCM_CODE;
u8 video_io_read (u16 addr)
{
    switch (addr&0xf) {
        case 0x0:
            text_mode = 0;
            break;
        case 0x1:
            text_mode = 1;
            break;
        case 0x2:
            mixed_mode = 0;
            break;
        case 0x3:
            mixed_mode = 1;
            break;
        case 0x4:
            sel_page = 1;
            break;
        case 0x5:
            sel_page = 2;
            break;
        case 0x6:
            hires = 0;
            break;
        case 0x7:
            hires = 1;
            break;
        // Annunciators
        case 0x8:
        case 0xa:
        case 0xc:
        case 0xe:
            break;
    }

    video_set_mode();

    // Duh, some scrollers wont work if we don't return 0x80
    // http://rich12345.tripod.com/aiivideo/vbl.html
    return 0x80;
}

void draw_lores_scr (u16 *map) ITCM_CODE;
void draw_lores_scr (u16 *__restrict map)
{
    int last_line;
    int i, j;
    u8 *ptr;

    if (!page_dirty[sel_page])
        return;

    last_line = render_mixed_mode ? 168 : 192;

    for (i = 0; i < last_line; i++) {
        ptr = (u8 *)(mainram + (sel_page << 10) + video_addr[i/8]);
        for (j = 0; j < 40/2; j++) {
            const u8 col_a = ((i&0x7)>=4) ? (*ptr>>4) : (*ptr&0xf);
            ptr++;
            const u8 col_b = ((i&0x7)>=4) ? (*ptr>>4) : (*ptr&0xf);
            ptr++;

            *map++ = col_a << 8 | col_a;
            *map++ = col_a << 8 | col_a;
            *map++ = col_a << 8 | col_a;
            *map++ = col_a << 8 | col_a;
            *map++ = col_b << 8 | col_b;
            *map++ = col_b << 8 | col_b;
            *map++ = col_b << 8 | col_b;
            *map++ = col_b << 8 | col_b;
        }
        map += 192/2;
    }
}

/*odd_color  = (b1&0x80) ? 6 : 3;*/
/*even_color = (b1&0x80) ? 9 :  12;*/

static void draw_hires_line_mono (u16 *__restrict map, u8 *__restrict ptr) ITCM_CODE;
static void draw_hires_line_mono (u16 *__restrict map, u8 *__restrict ptr)
{
    const u16 lut[] = {0x0000, 0x000c, 0x0c00, 0x0c0c};
    int j;
    for (j = 0; j < 280/14; j++) {
        u16 tmp = (ptr[0]&0x7f) | ((ptr[1]&0x7f) << 7);
        ptr += 2;
        *map++ = lut[tmp&3]; tmp >>= 2;
        *map++ = lut[tmp&3]; tmp >>= 2;
        *map++ = lut[tmp&3]; tmp >>= 2;
        *map++ = lut[tmp&3]; tmp >>= 2;
        *map++ = lut[tmp&3]; tmp >>= 2;
        *map++ = lut[tmp&3]; tmp >>= 2;
        *map++ = lut[tmp&3]; 
    }
}

static void draw_hires_line_color (u16 *__restrict map, u8 *__restrict ptr) ITCM_CODE;
static void draw_hires_line_color (u16 *__restrict map, u8 *__restrict ptr)
{
    static u8 tmp_line[280];
    static const u8 color_lut[] DTCM_DATA = { 
        0, 12,  0, 15, 0,  9,  0, 15, 0,  3,  0, 15, 0,  6,  0, 15 
    };
    int j, k;
    u16 tmp;

    for (j = 0, tmp = 0; j < 280; j += 7) {
        const u8 b1 = *ptr++;

        tmp = (b1&0x7f) << 1 | tmp;
        const u8 *__restrict lut_b = color_lut + ((b1&0x80)>>5);

        for (k = 0; k < 7; k+=2)
        {
            tmp_line[j+k+0] = lut_b[((j&1) << 3) + (tmp&3)];
            tmp >>=  1;
            if(k == 6)
                break;
            tmp_line[j+k+1] = lut_b[((~j&1) << 3) + (tmp&3)];
            tmp >>= 1;
        }
    }
    DC_FlushRange(tmp_line, sizeof(tmp_line));
    dmaCopyAsynch(tmp_line, map, sizeof(tmp_line));
    DC_InvalidateRange(map, sizeof(tmp_line));
}


static void draw_hires_scr (u16 *map) ITCM_CODE;
static void draw_hires_scr (u16 *__restrict map)
{
    int i, x, last_line;
    u8 *__restrict xptr, *__restrict ptr;
    u16 *__restrict omap;

    last_line = render_mixed_mode ? 168/8 : 192/8;

    for(x = 0; x < 8; x++, map += 0x100) {
        if (!page_dirty[(sel_page<<3)+x])
            continue;

        xptr = mainram + (sel_page << 13) + (x << 10);

        for(omap = map, i = 0; i < last_line; i++, omap += 0x800) {
            ptr = xptr + video_addr[i];

            draw_hires_line(omap, ptr);

        }
        page_dirty[(sel_page<<3)+x] = 0;
    }
}

void draw_text_scr (u16 *map) ITCM_CODE;
void draw_text_scr (u16 *__restrict map)
{
    int start_line;
    int i, j;
    u16 *ptr;

    if (!page_dirty[sel_page])
        return;

    if ((start_line = render_mixed_mode ? 21 : 0))
        map += 32 * start_line;

    for (i = start_line; i < 24; i++) {
        ptr = (u16 *)(mainram + (sel_page << 10) + video_addr[i]);

        for (j = 0; j < 5; j++) {
            *map++ = (*ptr++)&0x3f3f;
            *map++ = (*ptr++)&0x3f3f;
            *map++ = (*ptr++)&0x3f3f;
            *map++ = (*ptr++)&0x3f3f;
        }

        map += 12;
    }
}

void video_draw () ITCM_CODE;
void video_draw ()
{
    u16 *text_ptr = (u16 *)0x6002000;
    u16 *gfx_ptr  = (u16 *)0x6020000;

    if (render_mixed_mode) {
        draw_text_scr(text_ptr);
        (hires) ? draw_hires_scr(gfx_ptr) : draw_lores_scr(gfx_ptr);
    } else {
        if (text_mode)
            draw_text_scr(text_ptr);
        else
            (hires) ? draw_hires_scr(gfx_ptr) : draw_lores_scr(gfx_ptr);
    }

    // Clear this here otherwise we won't be able to render a lores
    // screen after the text one
    page_dirty[sel_page] = 0;
}

void video_set_hires (int renderer)
{
    switch (renderer) {
        default:
        case 0:
            draw_hires_line = draw_hires_line_mono;
            break;
        case 1:
            draw_hires_line = draw_hires_line_color;
            break;
    }
}

int video_set_scale (int mode)
{
    int scaleg_x, scalet_x;
    int scale_y;

    switch (mode) {
        default:
        case 0:
            scaleg_x = scalet_x = floatToFixed(1., 8);
            scale_y = floatToFixed(1., 8);
            break;
        case 1:
            // 280 / 256 = 1.09
            scaleg_x = floatToFixed(1.09, 8);
            scalet_x = floatToFixed(1.25, 8);
            scale_y = floatToFixed(1., 8);
            break;
    }

    bgSetScale(gfx_bg, scaleg_x, scale_y);
    bgSetScale(text_bg, scalet_x, scale_y);

    return 1;
}

void video_init ()
{
    videoSetMode(MODE_4_2D);

    vramSetBankA(VRAM_A_MAIN_BG_0x06000000);
    vramSetBankB(VRAM_B_MAIN_BG_0x06020000);

    // http://mtheall.com/vram.html#T2=3&NT2=128&MB2=4&TB2=0&S2=2&T3=5&NT3=32&MB3=8&TB3=1&S3=3
    text_bg = bgInit(2, BgType_Rotation, BgSize_R_512x512, 4, 0);
    gfx_bg = bgInit(3, BgType_Bmp8, BgSize_B8_512x256, 8, 0);

    REG_DISPCNT &= ~DISPLAY_WIN0_ON;
    // Setup the window used for mixed mode
    WIN0_X0 = 0;
    WIN0_X1 = 255;
    WIN0_Y0 = 0;
    WIN0_Y1 = 160;
    // BG3 inside
    WIN_IN = 0x8;
    // BG2 outside
    WIN_OUT = 0x4;

    video_set_hires(-1);

    memcpy(BG_PALETTE, palette, sizeof(palette));

    struct UnpackStruct unpack_bit;
    unpack_bit.dataOffset = 14;
    unpack_bit.destWidth = 8;
    unpack_bit.sourceSize = 64*8;
    unpack_bit.sourceWidth = 1;
    swiUnpackBits((u8 *)&apple_font, (u32 *)bgGetGfxPtr(text_bg), &unpack_bit);
}
