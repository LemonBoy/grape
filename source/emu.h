#ifndef EMU_H
#define EMU_H

#include <stdio.h>
#include "disk.h"
#include "cpu.h"
#include "video.h"
#include "mem.h"
#include "state.h"

#define INPUT_JOYSTICK 0
#define INPUT_KEYBOARD 1

int emu_vsync;
int emu_boost;
int emu_input;
int emu_screen;
int emu_scale;
int emu_hires;

char *basename;

void emu_init ();
void emu_run ();
void emu_reset ();

#endif
