#include <nds.h>
#include "emu.h"

static u8 sound_buf[44100];
static int buf_pos;
static int last_cycles;
static u8 spkr_phase;

void sound_reset ()
{
    memset(&sound_buf, 0, sizeof(sound_buf));
    buf_pos = 0;
    last_cycles = 0;
    spkr_phase = 0x80;
}

#define MIN(a,b) (((a) < (b)) ? (a) : (b))

void sound_spkr_flip (u32 cycles_left)
{
    int ts, i;

    // Check how many cycles have passed since last flip
    ts = (last_cycles - cycles_left);
    if (ts < 0)
        ts += 17030;
    last_cycles = cycles_left;
    
    int len;
    len = MIN(ts/23, sizeof(sound_buf) - buf_pos);

    for (i = 0; i < len; i++) {
        sound_buf[buf_pos++] = spkr_phase;
    }

    spkr_phase = ~spkr_phase;
}

void sound_play ()
{
    if (buf_pos) {
        memset(sound_buf + buf_pos, 0, sizeof(sound_buf) - buf_pos);
        soundPlaySample(sound_buf, SoundFormat_8Bit, buf_pos, 44100, 127, 0x40, 0, 0);
        buf_pos = 0;
    }
}
