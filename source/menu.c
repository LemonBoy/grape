#include <nds.h>
#include <stdio.h>
#include "emu.h"

typedef struct entry_t {
    const char *label;
    const int opts_no;
    const char *opts[10];
    int (*cb)(int);
} entry_t;

typedef struct page_t {
    const char *title;
    const int entries_no;
    const entry_t *entries;
} page_t;

#define OPT(n) int opt_##n (int sel) { emu_##n = sel; return 1; }

OPT(vsync);
OPT(input);

int opt_screen (int sel)
{
    (sel) ? lcdMainOnBottom() : lcdMainOnTop();
    return 1;
}

const static struct page_t paused_pg = { 
    "Paused", 7, (const entry_t []){ 
        { "Vsync", 2, { "No", "Yes" }, opt_vsync },
        { "Scale", 2, { "No", "Yes" }, video_set_scale },
        { "Screen", 2, { "Top", "Bottom" }, opt_screen },
        { "Map keys to", 2, { "joystick", "keyboard" }, opt_input },
        { "Save state", 9, { "1", "2", "3", "4", "5", "6", "7", "8", "9" }, state_save },
        { "Load state", 9, { "1", "2", "3", "4", "5", "6", "7", "8", "9" }, state_load },
        { "Exit", 0, { }, exit },
    }
};
static int paused_pg_opt[6] = { 1, 0, 0, 0, 0, 0 };

void menu_print_page (const page_t *page, int *opts) 
{
    int i;
    int cur;
    int keys;

    cur = 0;

    while (1) {
        consoleClear();

        iprintf("-- %s\n\n", page->title);

        const entry_t *sel_entry = &page->entries[cur];
        for (i = 0; i < page->entries_no; i++) {
            const entry_t *entry = &page->entries[i];
            iprintf("%c %s %s\n", (i == cur) ? '>' : ' ', entry->label, 
                    (entry->opts_no) ? entry->opts[opts[i]] : "");
        }

        scanKeys();
        keys = keysDownRepeat();

        if (keys&KEY_UP) { 
            cur--;
            if (cur < 0)
                cur = page->entries_no - 1;
        }
        if (keys&KEY_DOWN) {
            cur++;
            if (cur == page->entries_no)
                cur = 0;
        }
        if (sel_entry->opts_no) {
            if (keys&KEY_LEFT && opts[cur] > 0) {
                opts[cur]--;
                /*if (sel_entry->cb) sel_entry->cb(opts[cur]);*/
            }
            if (keys&KEY_RIGHT && opts[cur] < sel_entry->opts_no - 1) {
                opts[cur]++;
                /*if (sel_entry->cb) sel_entry->cb(opts[cur]);*/
            }
        }

        if (keys&KEY_A) {
            if (sel_entry->cb)
                if (sel_entry->cb(opts[cur]))
                    return;
        }

        // Use keysDown to avoid bouncing
        if (keysDown()&KEY_START)
            return;

        swiWaitForVBlank();
    }
}

void print_msg (const char *msg)
{
    iprintf("\n-- %s\n", msg);
    swiDelay(10000000);
}

void pause_menu () { menu_print_page(&paused_pg, (int *)&paused_pg_opt); }
