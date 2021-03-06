#include <nds.h>
#include "emu.h"

static u8 key_map[12] = { 
    0x0d,   // A
    0x20,   // B
    0x80,   // SELECT
    0x80,   // START
    0x4c,   // RIGHT
    0x48,   // LEFT
    0x4b,   // UP
    0x4a,   // DOWN
    0x80,   // R
    0x80,   // L
    0x1b,   // X
    0x80,   // Y
};

void update_input () ITCM_CODE; 
void update_input () 
{
    u32 keys;
    int kbd_key;

    keys = keysDown() | keysHeld();

    // Send keyboard scancodes when a key is pressed
    if (emu_input == INPUT_KEYBOARD && (keys&0xfff)) {
        int bit_set = __builtin_ffs(keys);
        if (bit_set)
            keybd_latch = 0x80 ^ key_map[bit_set-1];
    } 
    
    if (emu_input == INPUT_JOYSTICK) {
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
