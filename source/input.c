#include <nds.h>
#include "emu.h"

static u8 key_map[12] = { 
    0x0d,   // A
    0x20,   // B
    0x80,   // SELECT
    0x80,   // START
    0x4C,   // RIGHT
    0x4A,   // LEFT
    0x4B,   // UP
    0x80,   // DOWN
    0x80,   // R
    0x80,   // L
    0x80,   // X
    0x80,   // Y
};

void update_input () ITCM_CODE; 
void update_input () 
{
    u32 keys;
    int kbd_key;

    scanKeys();
    keys = keysHeld()&0xfff;

    // Send keyboard scancodes when a key is pressed
    if (emu_input == INPUT_KBD && keys) {
        keybd_latch = 0x80 ^ key_map[__builtin_ctz(keys)];
    } 
    
    if (emu_input == INPUT_JSTK) {
        jstk_btn[0] = (keys&KEY_X) ? 0x80 : 0x00;
        jstk_btn[1] = (keys&KEY_Y) ? 0x80 : 0x00;
        jstk_btn[2] = (keys&KEY_B) ? 0x80 : 0x00;
    }

    kbd_key = keyboardUpdate();

    if (kbd_key > 0) {
        switch (kbd_key) {
            case DVK_ENTER:
                keybd_latch = 0x8d;
                return;
            default:
                if (kbd_key >= '`') keybd_latch = 0x80 | (kbd_key - 32);
                else                keybd_latch = 0x80 | kbd_key;
                return;
        }
    }
}
