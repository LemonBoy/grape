#ifndef CPU_H
#define CPU_H

int cpu_run (int run_cycles);
void cpu_reset ();
void cpu_nmi ();
extern u32 cpu_regs[6];

enum {
    RF = 0,
    RY,
    RX,
    RA,
    RSP,
    RPC,
};


#endif
