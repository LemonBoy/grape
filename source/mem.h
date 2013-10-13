#ifndef MEM_H
#define MEM_H

// mem.s
extern u8 page_dirty[64];
extern u8 keybd_latch; 
extern u32 jstk_axis[4];
extern u32 jstk_btn[3]; 
extern u32 jstk_rst_cycle;
extern u8 mainram[0x10000];
extern u8 lcram[0x4000];
extern u32 memmap_r[0x10];
extern u32 memmap_w[0x10];

u8 readb (u16 addr);
void writeb (u16 addr, u8 val);
void mem_reset (void);

int load_bin (char *file, u16 addr, u16 len, u16 *crc);
int load_buf (const u8 *buf, u16 addr, u16 len);


#endif
