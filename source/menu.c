#include <nds.h>
#include <stdio.h>
#include "emu.h"

typedef struct entry_t {
    const char *label;
    const int opts_no;
    const char *opts[10];
    int *opt_ptr;
    int confirm;
    int (*cb)(int);
} entry_t;

typedef struct page_t {
    const char *title;
    const int entries_no;
    const entry_t *entries;
} page_t;

static int opt_screen (const int sel)
{
    emu_screen = sel;
    (sel) ? lcdMainOnBottom() : lcdMainOnTop();
    return 1;
}

static int opt_vsync (const int sel)
{
    emu_vsync = sel;
    return 1;
}

static int opt_scale (const int sel)
{
    emu_scale = sel;
    video_set_scale(emu_scale);
    return 1;
}

static int opt_input (const int sel)
{
    emu_input = sel;
    return 1;
}

static int opt_exit (const int sel)
{
    exit(0);
    return 1;
}

static int opt_hires (const int sel)
{
    video_set_hires(sel);
    return 1;
}

static int sel_slot_l = 0, sel_slot_s = 0;

const static struct page_t paused_pg = { 
    "Paused", 8, (const entry_t []){ 
        { "Vsync", 2, { "No", "Yes" }, &emu_vsync, 0, opt_vsync },
        { "Scale", 2, { "No", "Yes" }, &emu_scale, 0, opt_scale },
        { "Screen", 2, { "Top", "Bottom" }, &emu_screen, 0, opt_screen },
        { "Hires mode", 3, { "B/W", "Old", "Color" }, &emu_hires, 0, opt_hires },
        { "Map keys to", 2, { "joystick", "keyboard" }, &emu_input, 0, opt_input },
        { "Save state", 9, { "1", "2", "3", "4", "5", "6", "7", "8", "9" }, &sel_slot_s, 1, state_save },
        { "Load state", 9, { "1", "2", "3", "4", "5", "6", "7", "8", "9" }, &sel_slot_l, 1, state_load },
        { "Exit", 0, { }, NULL, 1, opt_exit },
    }
};

void menu_print_page (const page_t *page) 
{
    int i, cur;
    u32 keys, keys_;

    cur = 0;

    while (1) {
        consoleClear();

        iprintf("-- %s\n\n", page->title);

        const entry_t *sel_entry = &page->entries[cur];
        for (i = 0; i < page->entries_no; i++) {
            const entry_t *entry = &page->entries[i];
            iprintf("%c %s %s\n", (i == cur) ? '>' : ' ', entry->label, 
                    (entry->opts_no) ? entry->opts[*entry->opt_ptr] : "");
        }

        scanKeys();
        keys  = keysDown();
        keys_ = keysDownRepeat();

        if (keys_&KEY_UP) { 
            cur--;
            if (cur < 0)
                cur = page->entries_no - 1;
        }
        if (keys_&KEY_DOWN) {
            cur++;
            if (cur == page->entries_no)
                cur = 0;
        }
        if (sel_entry->opts_no && (keys_&(KEY_LEFT|KEY_RIGHT))) {
            if (keys_&KEY_LEFT && *sel_entry->opt_ptr > 0)
                (*sel_entry->opt_ptr)--;
            if (keys_&KEY_RIGHT && *sel_entry->opt_ptr < sel_entry->opts_no - 1)
                (*sel_entry->opt_ptr)++;
            if (!sel_entry->confirm && sel_entry->cb)
                sel_entry->cb(*sel_entry->opt_ptr);
        }

        if (keys&KEY_A && sel_entry->cb) {
            sel_entry->cb(*sel_entry->opt_ptr);
            return;
        }

        if (keys&(KEY_B|KEY_START))
            return;

        swiWaitForVBlank();
    }
}

void print_msg (const char *msg)
{
    iprintf("\n-- %s\n", msg);
    swiDelay(50000000);
}

void pause_menu () { menu_print_page(&paused_pg); }
