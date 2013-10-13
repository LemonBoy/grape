#ifndef EMU_H
#define EMU_H

#include <stdio.h>
#include "disk.h"
#include "cpu.h"
#include "video.h"
#include "mem.h"
#include "state.h"

#define INPUT_JSTK  0
#define INPUT_KBD   1

int emu_vsync;
int emu_input;

static char *basename;

void emu_init ();
void emu_run ();
void emu_reset ();

#endif
