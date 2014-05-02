.arm
.section .itcm,"ax",%progbits

#define UNDOC_OPS
//#define PRINT_TRACE
//#define CHECK_IDLE_JUMP

.global cpu_run
.global cpu_reset
.global cpu_regs

.extern mainram
.extern readb
.extern writeb

reg_pc  .req r11
reg_sp  .req r10
reg_a   .req r9
reg_x   .req r8 
reg_y   .req r7
reg_f   .req r6
cycles  .req r5

// XXX rebase the pc on page cross
.macro fetch 
    ldrb r0, [reg_pc], #1
.endm

.macro fetchw
    ldrb r0, [reg_pc], #1
    ldrb r1, [reg_pc], #1
    orr r0, r1, lsl #8 
.endm

.macro rebase_pc r
    ldr r1, =memmap_r
    mov r2, \r, lsr #12
    ldr r1, [r1, r2, lsl #2]
    add \r, r1
    ldr r2, =last_page
    str r1, [r2]
.endm

.macro unbase_pc r
    ldr r1, =last_page
    ldr r1, [r1]
    sub \r, reg_pc, r1
.endm

.macro push r
    ldr r3, =(mainram+0x100)
    strb \r, [r3, reg_sp]
    sub reg_sp, #1
    and reg_sp, #255
.endm

.macro pop r
    ldr r1, =(mainram+0x100)
    add reg_sp, #1
    and reg_sp, #255
    ldrb \r, [r1, reg_sp]
.endm

.macro adr_zp_z
    fetch
.endm

.macro adr_zp r
    fetch
    add r0, \r
    and r0, #0xff
.endm

.macro adr_abs_z 
    fetchw
.endm

.macro adr_abs r
    fetchw
    mov r1, r0, lsr #8
    add r0, \r
    cmp r1, r0, lsr #8
    // Page crossing adds a penality cycle
    subne cycles, #1
.endm

.macro adr_idx 
    fetchw
    and r4, r0, #0xff00 
    add r3, r0, #1
    and r3, #255
    orr r4, r3
    ldr r2, =memmap_r

    lsr r1, r0, #12
    ldr r3, [r2, r1, lsl #2]
    ldrb r0, [r3, r0]

    lsr r1, r4, #12
    ldr r3, [r2, r1, lsl #2]
    ldrb r1, [r3, r4]

    orr r0, r1, lsl #8
.endm

.macro adr_idx_x
    fetch
    add r0, reg_x
    and r0, #255
    ldr r3, =memmap_r
    ldr r3, [r3]
    add r2, r0, #1
    and r2, #255
    ldrb r0, [r3, r0]
    ldrb r1, [r3, r2]
    orr r0, r1, lsl #8
.endm

.macro adr_idx_y
    fetch
    ldr r3, =memmap_r
    ldr r3, [r3]
    add r2, r0, #1
    and r2, #255
    ldrb r0, [r3, r0]
    ldrb r1, [r3, r2]
    orr r0, r1, lsl #8
    add r0, reg_y
    // Page crossing adds a penality cycle
    cmp r1, r0, lsr #8
    subne cycles, #1
.endm

.macro adr_rel
    ldrsb r0, [reg_pc], #1
#ifdef CHECK_IDLE_JUMP
    cmp r0, #-2
    bne 2f
    ldr r0, =idle_loop_msg
    unbase_pc reg_pc
    mov r1, reg_pc
    bl iprintf
1:  b 1b
#endif
2:  add r1, reg_pc, r0
    eor r0, r1, reg_pc
    tst r0, #0x100
    addne cycles, #2
    mov reg_pc, r1
.endm

#define FLAG_CARRY  0x01<<24
#define FLAG_ZERO   0x02<<24
#define FLAG_INTR   0x04<<24
#define FLAG_DEC    0x08<<24
#define FLAG_BRK    0x20<<24
#define FLAG_OVER   0x40<<24
#define FLAG_NEG    0x80<<24

.macro op_adc r
    mov reg_a, reg_a, lsl #24
    movs r2, reg_f, lsr #25
    bic reg_f, #(FLAG_ZERO+FLAG_CARRY+FLAG_OVER+FLAG_NEG)
    subcs \r, \r, #0x100
    adcs reg_a, \r, ror #8
    orreq reg_f, #FLAG_ZERO
    orrcs reg_f, #FLAG_CARRY
    orrvs reg_f, #FLAG_OVER
    orrmi reg_f, #FLAG_NEG
    mov reg_a, reg_a, lsr #24
    // Decimal mode
    tst reg_f, #FLAG_DEC
    beq 1f
    // Low nibble
    bic reg_f, #FLAG_CARRY
    and r1, reg_a, #0x0f
    cmp r1, #0x09
    addhi reg_a, #0x06
    // High nibble
    and r1, reg_a, #0xf0
    cmp r1, #0x90
    addhi reg_a, #0x60
    orrhi reg_f, #FLAG_CARRY
    and reg_a, #255
    add cycles, #1
1:  
.endm

.macro op_sbc r
    mov reg_a, reg_a, lsl #24
    movs r2, reg_f, lsr #25
    bic reg_f, #(FLAG_ZERO+FLAG_CARRY+FLAG_OVER+FLAG_NEG)
    sbcs reg_a, \r, lsl #24
    orrcs reg_f, #FLAG_CARRY
    orrvs reg_f, #FLAG_OVER
    orrmi reg_f, #FLAG_NEG
    movs reg_a, reg_a, lsr #24
    orreq reg_f, #FLAG_ZERO
    // Decimal mode
    tst reg_f, #FLAG_DEC
    beq 1f
    sub reg_a, #0x66
    and reg_a, #255
    bic reg_f, #FLAG_CARRY
    // Low nibble
    and r2, reg_a, #0x0f
    cmp r2, #0x09
    addhi reg_a, #0x06
    // High nibble
    and r1, reg_a, #0xf0<<24
    cmp r1, #0x90
    addhi reg_a, #0x60
    orrhi reg_f, #FLAG_CARRY
    add cycles, #1
1:  
.endm

.macro op_and a1
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    lsl reg_a, #24
    ands reg_a, \a1, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
.endm

.macro op_asl a1
    bic reg_f, #(FLAG_CARRY+FLAG_ZERO+FLAG_NEG)
    movs \a1, \a1, lsl #25
    orrcs reg_f, #FLAG_CARRY
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr \a1, #24
.endm

.macro op_cmp a1, a2
    bic reg_f, #(FLAG_CARRY+FLAG_ZERO+FLAG_NEG)
    mov r3, \a1, lsl #24
    cmp r3, \a2, lsl #24
    orrcs reg_f, #FLAG_CARRY
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
.endm

.macro op_dec a1
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    lsl \a1, #24
    subs \a1, #1<<24
    orrmi reg_f, #FLAG_NEG
    movs \a1, \a1, lsr #24
    orreq reg_f, #FLAG_ZERO
.endm

.macro op_eor a1
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    lsl reg_a, #24
    eors reg_a, \a1, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
.endm

.macro op_inc a1
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    lsl \a1, #24
    adds \a1, #1<<24
    orrmi reg_f, #FLAG_NEG
    movs \a1, \a1, lsr #24
    orreq reg_f, #FLAG_ZERO
.endm

.macro op_lsr a1
    bic reg_f, #(FLAG_CARRY+FLAG_ZERO+FLAG_NEG)
    movs \a1, \a1, lsr #1
    orrcs reg_f, #FLAG_CARRY
    orreq reg_f, #FLAG_ZERO
.endm

.macro op_ora a1
    bic reg_f, #(FLAG_NEG+FLAG_ZERO)
    lsl reg_a, #24
    orrs reg_a, \a1, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
.endm

.macro op_rol a1
    and r3, reg_f, #FLAG_CARRY
    bic reg_f, #(FLAG_CARRY+FLAG_ZERO+FLAG_NEG)
    movs \a1, \a1, lsl #25
    orrcs reg_f, #FLAG_CARRY
    adds \a1, r3
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr \a1, #24
.endm

.macro op_ror a1
    movs r3, reg_f, lsr #25
    bic reg_f, #(FLAG_CARRY+FLAG_ZERO+FLAG_NEG)
    lsl \a1, #23
    orrcs reg_f, #FLAG_NEG
    orrcs \a1, #1<<31
    movs \a1, \a1, lsr #24
    orreq reg_f, #FLAG_ZERO
    orrcs reg_f, #FLAG_CARRY
.endm

.macro op_bit a1
    bic reg_f, #(FLAG_ZERO+FLAG_OVER+FLAG_NEG)
    tst reg_a, \a1
    orreq reg_f, #FLAG_ZERO
    tst \a1, #0x40
    orrne reg_f, #FLAG_OVER
    tst \a1, #0x80
    orrne reg_f, #FLAG_NEG    
.endm

.macro op_txb set, a1
    tst \a1, reg_a
    orreq reg_f, #FLAG_ZERO
    bicne reg_f, #FLAG_ZERO
    .if \set == 1
    orr \a1, reg_a
    .else
    bic \a1, reg_a
    .endif
.endm

// NOP
_ea:
    mov r0, #2
    b instr_end
// ORA
_09:
    fetch
    op_ora r0
    mov r0, #2
    b instr_end
_05:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_ora r2
    mov r0, #3
    b instr_end
_15:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_ora r2
    mov r0, #4
    b instr_end
_0d:
    adr_abs_z
    bl readb
    op_ora r0
    mov r0, #4
    b instr_end
_1d:
    adr_abs reg_x
    bl readb
    op_ora r0
    mov r0, #4
    b instr_end
_19:
    adr_abs reg_y
    bl readb
    op_ora r0
    mov r0, #4
    b instr_end
_01:
    adr_idx_x
    bl readb
    op_ora r0
    mov r0, #6
    b instr_end
_11:
    adr_idx_y
    bl readb
    op_ora r0
    mov r0, #5
    b instr_end
// AND
_29:
    fetch
    op_and r0
    mov r0, #2
    b instr_end
_25:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_and r2
    mov r0, #3
    b instr_end
_35:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_and r2
    mov r0, #4
    b instr_end
_2d:
    adr_abs_z
    bl readb
    op_and r0
    mov r0, #4
    b instr_end
_3d:
    adr_abs reg_x
    bl readb
    op_and r0
    mov r0, #4
    b instr_end
_39:
    adr_abs reg_y
    bl readb
    op_and r0
    mov r0, #4
    b instr_end
_21:
    adr_idx_x
    bl readb
    op_and r0
    mov r0, #6
    b instr_end
_31:
    adr_idx_y
    bl readb
    op_and r0
    mov r0, #5
    b instr_end
// ASL
_0a:
    op_asl reg_a
    mov r0, #2
    b instr_end
_06:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_asl r2
    strb r2, [r1, r0]
    mov r0, #5
    b instr_end
_16:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_asl r2
    strb r2, [r1, r0]
    mov r0, #6
    b instr_end
_0e:
    adr_abs_z
    mov r4, r0
    bl readb
    op_asl r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #6
    b instr_end
_1e:
    adr_abs reg_x
    mov r4, r0
    bl readb
    op_asl r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #7
    b instr_end
// BCC
_90:
    tst reg_f, #FLAG_CARRY
    addne reg_pc, #1
    mov r0, #2
    bne instr_end
    adr_rel
    mov r0, #3
    b instr_end
// BCS
_b0:
    tst reg_f, #FLAG_CARRY
    addeq reg_pc, #1
    mov r0, #2
    beq instr_end
    adr_rel
    mov r0, #3
    b instr_end
// BEQ
_f0:
    tst reg_f, #FLAG_ZERO
    addeq reg_pc, #1
    mov r0, #2
    beq instr_end
    adr_rel
    mov r0, #3
    b instr_end
// BIT
_24:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_bit r2
    mov r0, #3
    b instr_end
_2c:
    adr_abs_z
    bl readb
    op_bit r0
    mov r0, #4
    b instr_end
// BMI
_30:
    tst reg_f, #FLAG_NEG
    addeq reg_pc, #1
    mov r0, #2
    beq instr_end
    adr_rel
    mov r0, #3
    b instr_end
// BNE
_d0:
    tst reg_f, #FLAG_ZERO
    addne reg_pc, #1
    mov r0, #2
    bne instr_end
    adr_rel
    mov r0, #3
    b instr_end
// BPL
_10:
    tst reg_f, #FLAG_NEG
    addne reg_pc, #1
    mov r0, #2
    bne instr_end
    adr_rel
    mov r0, #3
    b instr_end
// BRK
_00:
    unbase_pc r0
    add r0, #1
    mov r1, r0, lsr #8
    and r2, r0, #0xff
    push r1
    push r2
    mov r0, reg_f, lsr #24
    orr r0, #0x30
    push r0
    orr reg_f, #(FLAG_INTR|FLAG_BRK)
    
    ldr r0, =memmap_r
    ldr r0, [r0, #0xf<<2]
    ldr r3, =0xfffe
    add r0, r3
    ldrb r1, [r0, #0]
    ldrb r2, [r0, #1]
    orr reg_pc, r1, r2, lsl #8
    rebase_pc reg_pc

    mov r0, #7
    b instr_end
// RTI
_40:
    pop r0
    mov reg_f, r0, lsl #24
    pop reg_pc 
    pop r0
    orr reg_pc, r0, lsl #8   
    rebase_pc reg_pc
    mov r0, #6
    b instr_end
// RTS
_60:
    pop reg_pc
    pop r0
    orr reg_pc, r0, lsl #8
    add reg_pc, #1
    rebase_pc reg_pc
    mov r0, #6
    b instr_end
// CLD
_d8:
    bic reg_f, #FLAG_DEC
    mov r0, #2
    b instr_end
// JSR
_20:
    unbase_pc r4
    add r4, #1
    mov r0, r4, lsr #8
    push r0
    and r4, #0xff
    push r4
    adr_abs_z
    mov reg_pc, r0
    rebase_pc reg_pc
    mov r0, #6
    b instr_end
// STX
_86:
    adr_zp_z
    ldr r1, =mainram
    strb reg_x, [r1, r0]
    mov r0, #3
    b instr_end
_96:
    adr_zp reg_y
    ldr r1, =mainram
    strb reg_x, [r1, r0]
    mov r0, #4
    b instr_end
_8e:
    adr_abs_z
    mov r1, reg_x
    bl writeb
    mov r0, #4
    b instr_end
// LDY
_a0:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    fetch
    movs reg_y, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_y, #24
    mov r0, #2
    b instr_end
_a4:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_zp_z
    ldr r1, =mainram
    ldrb reg_y, [r1, r0]
    movs reg_y, reg_y, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_y, #24
    mov r0, #3
    b instr_end
_b4:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_zp reg_x
    ldr r1, =mainram
    ldrb reg_y, [r1, r0]
    movs reg_y, reg_y, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_y, #24
    mov r0, #4
    b instr_end
_ac:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_abs_z
    bl readb
    movs reg_y, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_y, #24
    mov r0, #4
    b instr_end
_bc:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_abs reg_x
    bl readb
    movs reg_y, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_y, #24
    mov r0, #4
    b instr_end
// STY
_84:
    adr_zp_z
    ldr r1, =mainram
    strb reg_y, [r1, r0]
    mov r0, #3
    b instr_end
_94:
    adr_zp reg_x
    ldr r1, =mainram
    strb reg_y, [r1, r0]
    mov r0, #4
    b instr_end
_8c:
    adr_abs_z
    mov r1, reg_y
    bl writeb
    mov r0, #4
    b instr_end
.ltorg
// BVS
_70:
    tst reg_f, #FLAG_OVER
    addeq reg_pc, #1
    mov r0, #2
    beq instr_end
    adr_rel
    mov r0, #3
    b instr_end
// BVC
_50:
    tst reg_f, #FLAG_OVER
    addne reg_pc, #1
    mov r0, #2
    bne instr_end
    adr_rel
    mov r0, #3
    b instr_end
// LDA
_a9:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    fetch
    movs reg_a, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #2
    b instr_end
_a5:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_zp_z
    ldr r1, =mainram
    ldrb reg_a, [r1, r0]
    movs reg_a, reg_a, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #3
    b instr_end
_b5:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_zp reg_x
    ldr r1, =mainram
    ldrb reg_a, [r1, r0]
    movs reg_a, reg_a, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #4
    b instr_end
_ad:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_abs_z
    bl readb
    movs reg_a, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #4
    b instr_end
_bd:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_abs reg_x
    bl readb
    movs reg_a, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #4
    b instr_end
_b9:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_abs reg_y
    bl readb
    movs reg_a, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #4
    b instr_end
_a1:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_idx_x
    bl readb
    movs reg_a, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #6
    b instr_end
_b1:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_idx_y
    bl readb
    movs reg_a, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #5
    b instr_end
// STA
_85:
    adr_zp_z
    ldr r1, =mainram
    strb reg_a, [r1, r0]
    mov r0, #3
    b instr_end
_95:
    adr_zp reg_x
    ldr r1, =mainram
    strb reg_a, [r1, r0]
    mov r0, #4
    b instr_end
_8d:
    adr_abs_z
    mov r1, reg_a
    bl writeb
    mov r0, #4
    b instr_end
_9d:
    adr_abs reg_x
    mov r1, reg_a
    bl writeb
    mov r0, #5
    b instr_end
_99:
    adr_abs reg_y
    mov r1, reg_a
    bl writeb
    mov r0, #5
    b instr_end
_81:
    adr_idx_x
    mov r1, reg_a
    bl writeb
    mov r0, #6
    b instr_end
_91:
    adr_idx_y
    mov r1, reg_a
    bl writeb
    mov r0, #6
    b instr_end
// JMP
_4c:
    adr_abs_z
#ifdef CHECK_IDLE_JUMP
    cmp reg_pc, r0
    bne 2f
    unbase_pc reg_pc
    ldr r0, =idle_loop_msg
    mov r1, reg_pc
    bl iprintf
1:  b 1b
#endif
2:  mov reg_pc, r0
    rebase_pc reg_pc
    mov r0, #3
    b instr_end
_6c:
    adr_idx
#ifdef CHECK_IDLE_JUMP
    cmp reg_pc, r0
    bne 2f
    unbase_pc reg_pc
    ldr r0, =idle_loop_msg
    mov r1, reg_pc
    bl iprintf
1:  b 1b
#endif
2:  mov reg_pc, r0
    rebase_pc reg_pc
    mov r0, #5
    b instr_end
// PHA
_48:
    push reg_a
    mov r0, #3
    b instr_end
// PLA
_68:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    pop r0
    movs reg_a, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #4
    b instr_end
// LSR
_4a:
    op_lsr reg_a
    mov r0, #2
    b instr_end
_46:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_lsr r2
    strb r2, [r1, r0]
    mov r0, #5
    b instr_end
_56:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_lsr r2
    strb r2, [r1, r0]
    mov r0, #6
    b instr_end
_4e:
    adr_abs_z
    mov r4, r0
    bl readb
    op_lsr r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #6
    b instr_end
_5e:
    adr_abs reg_x
    mov r4, r0
    bl readb
    op_lsr r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #7
    b instr_end
// ADC
_69:
    fetch
    op_adc r0
    mov r0, #2
    b instr_end
_65:
    adr_zp_z
    ldr r1, =mainram
    ldrb r0, [r1, r0]
    op_adc r0
    mov r0, #3
    b instr_end
_75:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r0, [r1, r0]
    op_adc r0
    mov r0, #4
    b instr_end
_6d:
    adr_abs_z
    bl readb
    op_adc r0
    mov r0, #4
    b instr_end
_7d:
    adr_abs reg_x
    bl readb
    op_adc r0
    mov r0, #4
    b instr_end
_79:
    adr_abs reg_y
    bl readb
    op_adc r0
    mov r0, #4
    b instr_end
_61:
    adr_idx_x
    bl readb
    op_adc r0
    mov r0, #6
    b instr_end
_71:
    adr_idx_y
    bl readb
    op_adc r0
    mov r0, #5
    b instr_end
// SBC
_e9:
    fetch 
    op_sbc r0
    mov r0, #2
    b instr_end
_e5:
    adr_zp_z
    ldr r1, =mainram
    ldrb r0, [r1, r0]
    op_sbc r0
    mov r0, #3
    b instr_end
_f5:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r0, [r1, r0]
    op_sbc r0
    mov r0, #4
    b instr_end
_ed:
    adr_abs_z
    bl readb
    op_sbc r0
    mov r0, #4
    b instr_end
_fd:
    adr_abs reg_x
    bl readb
    op_sbc r0
    mov r0, #4
    b instr_end
_f9:
    adr_abs reg_y
    bl readb
    op_sbc r0
    mov r0, #4
    b instr_end
_e1:
    adr_idx_x
    bl readb
    op_sbc r0
    mov r0, #6
    b instr_end
_f1:
    adr_idx_y
    bl readb
    op_sbc r0
    mov r0, #5
    b instr_end
.ltorg
// LDX
_a2:
    bic reg_f, #(FLAG_NEG+FLAG_ZERO)
    fetch
    movs reg_x, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_x, #24
    mov r0, #2
    b instr_end
_a6:
    bic reg_f, #(FLAG_NEG+FLAG_ZERO)
    adr_zp_z
    ldr r1, =mainram
    ldrb reg_x, [r1, r0]
    movs reg_x, reg_x, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_x, #24
    mov r0, #3
    b instr_end
_b6:
    bic reg_f, #(FLAG_NEG+FLAG_ZERO)
    adr_zp reg_y
    ldr r1, =mainram
    ldrb reg_x, [r1, r0]
    movs reg_x, reg_x, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_x, #24
    mov r0, #4
    b instr_end   
_ae:
    bic reg_f, #(FLAG_NEG+FLAG_ZERO)
    adr_abs_z
    bl readb
    movs reg_x, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_x, #24
    mov r0, #4
    b instr_end
_be:
    bic reg_f, #(FLAG_NEG+FLAG_ZERO)
    adr_abs reg_y
    bl readb
    movs reg_x, r0, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_x, #24
    mov r0, #4
    b instr_end
// CPX
_e0:
    fetch
    op_cmp reg_x, r0
    mov r0, #2
    b instr_end
_e4:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_cmp reg_x, r2
    mov r0, #3
    b instr_end
_ec:
    adr_abs_z
    bl readb
    op_cmp reg_x, r0
    mov r0, #4
    b instr_end
// CMP
_c9:
    fetch
    op_cmp reg_a, r0
    mov r0, #2
    b instr_end
_c5:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_cmp reg_a, r2
    mov r0, #3
    b instr_end
_d5:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_cmp reg_a, r2
    mov r0, #4
    b instr_end
_cd:
    adr_abs_z
    bl readb
    op_cmp reg_a, r0
    mov r0, #4
    b instr_end
_dd:
    adr_abs reg_x
    bl readb
    op_cmp reg_a, r0
    mov r0, #4
    b instr_end
_d9:
    adr_abs reg_y
    bl readb
    op_cmp reg_a, r0
    mov r0, #4
    b instr_end
_c1:
    adr_idx_x
    bl readb
    op_cmp reg_a, r0
    mov r0, #6
    b instr_end
_d1:
    adr_idx_y
    bl readb
    op_cmp reg_a, r0
    mov r0, #5
    b instr_end
// CPY
_c0:
    fetch
    op_cmp reg_y, r0
    mov r0, #2
    b instr_end
_c4:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_cmp reg_y, r2
    mov r0, #3
    b instr_end
_cc:
    adr_abs_z
    bl readb
    op_cmp reg_y, r0
    mov r0, #4
    b instr_end
// EOR
_49:
    fetch
    op_eor r0
    mov r0, #2
    b instr_end
_45:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_eor r2
    mov r0, #3
    b instr_end
_55:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_eor r2
    mov r0, #4
    b instr_end
_4d:
    adr_abs_z
    bl readb
    op_eor r0
    mov r0, #4
    b instr_end
_5d:
    adr_abs reg_x
    bl readb
    op_eor r0
    mov r0, #4
    b instr_end
_59:
    adr_abs reg_y
    bl readb
    op_eor r0
    mov r0, #4
    b instr_end
_41:
    adr_idx_x
    bl readb
    op_eor r0
    mov r0, #6
    b instr_end
_51:
    adr_idx_y
    bl readb
    op_eor r0
    mov r0, #5
    b instr_end
// INC
_e6:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_inc r2
    strb r2, [r1, r0]
    mov r0, #5
    b instr_end
_f6:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_inc r2
    strb r2, [r1, r0]
    mov r0, #6
    b instr_end
_ee:
    adr_abs_z
    mov r4, r0
    bl readb
    op_inc r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #6
    b instr_end
_fe:
    adr_abs reg_x
    mov r4, r0
    bl readb
    op_inc r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #7
    b instr_end
// INY
_c8:
    op_inc reg_y
    mov r0, #2
    b instr_end
// INX
_e8:
    op_inc reg_x
    mov r0, #2
    b instr_end
// DEX
_ca:
    op_dec reg_x
    mov r0, #2
    b instr_end
.ltorg
// DEY
_88:
    op_dec reg_y
    mov r0, #2
    b instr_end
// SEC
_38:
    orr reg_f, #FLAG_CARRY
    mov r0, #2
    b instr_end
// SED
_f8:
    orr reg_f, #FLAG_DEC
    mov r0, #2
    b instr_end
// TAX
_aa:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    movs reg_x, reg_a, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_x, #24
    mov r0, #2
    b instr_end
// TAY
_a8:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    movs reg_y, reg_a, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_y, #24
    mov r0, #2
    b instr_end
// TXA
_8a:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    movs reg_a, reg_x, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #2
    b instr_end
// TYA
_98:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    movs reg_a, reg_y, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_a, #24
    mov r0, #2
    b instr_end
// TXS
_9a:
    mov reg_sp, reg_x
    mov r0, #2
    b instr_end
// TSX
_ba:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    mov reg_x, reg_sp
    movs reg_x, reg_x, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    mov reg_x, reg_x, lsr #24
    mov r0, #2
    b instr_end
// DEC
_c6:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_dec r2
    strb r2, [r1, r0]
    mov r0, #5
    b instr_end
_d6:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_dec r2
    strb r2, [r1, r0]
    mov r0, #6
    b instr_end
_ce:
    adr_abs_z
    mov r4, r0
    bl readb
    op_dec r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #6
    b instr_end
_de:
    adr_abs reg_x
    mov r4, r0
    bl readb
    op_dec r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #7
    b instr_end
// CLC
_18:
    bic reg_f, #FLAG_CARRY
    mov r0, #2
    b instr_end
// PHP
_08:
    mov r0, reg_f, lsr #24
    orr r0, #0x30 // BRK flag + reserved bit
    push r0
    mov r0, #3
    b instr_end
// PLP
_28:
    pop r0
    mov reg_f, r0, lsl #24
    mov r0, #4
    b instr_end
// ROL
_2a:
    op_rol reg_a
    mov r0, #2
    b instr_end
_26:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_rol r2
    strb r2, [r1, r0]
    mov r0, #5
    b instr_end   
_36:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_rol r2
    strb r2, [r1, r0]
    mov r0, #6
    b instr_end 
_2e:
    adr_abs_z
    mov r4, r0
    bl readb
    op_rol r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #6
    b instr_end
_3e:
    adr_abs reg_x
    mov r4, r0
    bl readb
    op_rol r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #7
    b instr_end   
// ROR
_6a:
    op_ror reg_a
    mov r0, #2
    b instr_end
_66:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_ror r2
    strb r2, [r1, r0]
    mov r0, #5
    b instr_end
_76:
    adr_zp reg_x
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_ror r2
    strb r2, [r1, r0]
    mov r0, #6
    b instr_end
_6e:
    adr_abs_z
    mov r4, r0
    bl readb
    op_ror r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #6
    b instr_end
_7e:
    adr_abs reg_x
    mov r4, r0
    bl readb
    op_ror r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #7
    b instr_end
// SEI
_78:
    orr reg_f, #FLAG_INTR
    mov r0, #2
    b instr_end
// CLI
_58:
    bic reg_f, #FLAG_INTR
    mov r0, #2
    b instr_end
// CLV
_b8:
    bic reg_f, #FLAG_OVER
    mov r0, #2
    b instr_end
#ifdef UNDOC_OPS
// NOP
_7a:
    mov r0, #2
    b instr_end
// LAX
_b7:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    adr_zp reg_y
    ldr r1, =mainram
    ldrb reg_a, [r1, r0]
    movs reg_x, reg_a, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    mov reg_x, reg_a
    mov r0, #4
    b instr_end
// DOP
_04:
    add reg_pc, #1
    mov r0, #3
    b instr_end
// TOP
_fc:
    add reg_pc, #2
    mov r0, #4
    b instr_end
// SLO
_07:
    adr_zp_z
    ldr r2, =mainram
    ldrb r1, [r2, r0]
    movs r1, r1, lsl #25
    orrcs reg_f, #FLAG_CARRY
    lsr r1, #24
    strb r1, [r2, r0]
    op_ora r1
    mov r0, #5
    b instr_end
_1a:
_3c:
_5a:
_89:
_93:
_c7:
_da:
_f7:
_fa:
_0c:
_3a:
_64:
_74:
_80:
_9c:
_9e:
    b _xx
#else
// BIT
_89:
    fetch
    tst reg_a, r0
    bicne reg_f, #FLAG_ZERO
    orreq reg_f, #FLAG_ZERO
    mov r0, #2
    b instr_end
_3c:
    adr_abs reg_x
    bl readb
    op_bit r0
    mov r0, #4
    b instr_end
// PHX
_da:
    push reg_x
    mov r0, #3
    b instr_end
// PHY
_5a:
    push reg_y
    mov r0, #3
    b instr_end
// PLX
_fa:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    pop reg_x
    movs reg_x, reg_x, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_x, #24
    mov r0, #4
    b instr_end
// PLY
_7a:
    bic reg_f, #(FLAG_ZERO+FLAG_NEG)
    pop reg_y
    movs reg_y, reg_y, lsl #24
    orreq reg_f, #FLAG_ZERO
    orrmi reg_f, #FLAG_NEG
    lsr reg_y, #24
    mov r0, #4
    b instr_end
// TSB
_04:
    adr_zp_z
    ldr r1, =mainram
    ldrb r2, [r1, r0]
    op_txb 1, r2
    strb r2, [r1, r0]
    mov r0, #5
    b instr_end
_0c:
    adr_abs_z
    mov r4, r0
    bl readb
    op_txb 1, r0
    mov r1, r0
    mov r0, r4
    bl writeb
    mov r0, #6
    b instr_end
// INC
_1a:
    op_inc reg_a
    mov r0, #2
    b instr_end
// DEC
_3a:
    op_dec reg_a
    mov r0, #2
    b instr_end
// STZ
_64:
    adr_zp_z
    ldr r1, =mainram
    mov r2, #0
    strb r2, [r1, r0]
    mov r0, #3
    b instr_end
_74:
    adr_zp reg_x
    ldr r1, =mainram
    mov r2, #0
    strb r2, [r1, r0]
    mov r0, #3
    b instr_end
_9c:
    adr_abs_z
    mov r1, #0
    bl writeb
    mov r0, #4
    b instr_end
_9e:
    adr_abs reg_x
    mov r1, #0
    bl writeb
    mov r0, #4
    b instr_end
// BRA
_80:
    adr_rel
    mov r0, #3
    b instr_end
_07:
_b7:
_fc:
_f7:
_c7:
_93:
    b _xx
#endif
  
// http://emu-docs.org/CPU%2065xx/undocop.txt

_xx:
    // Stop the vblank irq
#if 1
    ldr r3, =0x4000210  
    ldr r2, [r3]
    bic r2, #1
    str r2, [r3]
#endif
    unbase_pc reg_pc
    lsr reg_f, #24
    stmfd sp!, {r0,reg_f,reg_sp,reg_pc}
    ldr r0, =unhandled_msg
    mov r1, reg_a
    mov r2, reg_x
    mov r3, reg_y
    bl iprintf
hang:
    b hang

// int cpu_run_1 (int cycles_to_do)
cpu_run:
    stmfd sp!, {r4-r12, lr}

    ldr r1, =cpu_regs
    ldmia r1, {reg_f-reg_pc}
    
    mov cycles, r0
loop:  
    fetch
#ifdef PRINT_TRACE
    unbase_pc reg_pc 
    lsr reg_f, #24
    stmfd sp!, {r0,reg_f,reg_sp,reg_pc}
        ldr r0, =debug_msg
        mov r1, reg_a
        mov r2, reg_x
        mov r3, reg_y
        bl iprintf
    ldmfd sp!, {r0,reg_f,reg_sp,reg_pc}
    lsl reg_f, #24
1:  rebase_pc reg_pc
#endif
    ldr pc, [pc, r0, lsl #2]
    nop
op_tab:
    .word _00,_01,_xx,_xx,_04,_05,_06,_07,_08,_09,_0a,_xx,_0c,_0d,_0e,_xx
    .word _10,_11,_xx,_xx,_xx,_15,_16,_xx,_18,_19,_1a,_xx,_xx,_1d,_1e,_xx
    .word _20,_21,_xx,_xx,_24,_25,_26,_xx,_28,_29,_2a,_xx,_2c,_2d,_2e,_xx
    .word _30,_31,_xx,_xx,_xx,_35,_36,_xx,_38,_39,_3a,_xx,_3c,_3d,_3e,_xx
    .word _40,_41,_xx,_xx,_xx,_45,_46,_xx,_48,_49,_4a,_xx,_4c,_4d,_4e,_xx
    .word _50,_51,_xx,_xx,_xx,_55,_56,_xx,_58,_59,_5a,_xx,_xx,_5d,_5e,_xx
    .word _60,_61,_xx,_xx,_64,_65,_66,_xx,_68,_69,_6a,_xx,_6c,_6d,_6e,_xx
    .word _70,_71,_xx,_xx,_74,_75,_76,_xx,_78,_79,_7a,_xx,_xx,_7d,_7e,_xx
    .word _80,_81,_xx,_xx,_84,_85,_86,_xx,_88,_89,_8a,_xx,_8c,_8d,_8e,_xx
    .word _90,_91,_xx,_93,_94,_95,_96,_xx,_98,_99,_9a,_xx,_9c,_9d,_9e,_xx
    .word _a0,_a1,_a2,_xx,_a4,_a5,_a6,_xx,_a8,_a9,_aa,_xx,_ac,_ad,_ae,_xx
    .word _b0,_b1,_xx,_xx,_b4,_b5,_b6,_b7,_b8,_b9,_ba,_xx,_bc,_bd,_be,_xx
    .word _c0,_c1,_xx,_xx,_c4,_c5,_c6,_c7,_c8,_c9,_ca,_xx,_cc,_cd,_ce,_xx
    .word _d0,_d1,_xx,_xx,_xx,_d5,_d6,_xx,_d8,_d9,_da,_xx,_xx,_dd,_de,_xx
    .word _e0,_e1,_xx,_xx,_e4,_e5,_e6,_xx,_e8,_e9,_ea,_xx,_ec,_ed,_ee,_xx
    .word _f0,_f1,_xx,_xx,_xx,_f5,_f6,_f7,_f8,_f9,_fa,_xx,_fc,_fd,_fe,_xx
instr_end:
    subs cycles, r0
    bpl loop

    mov r0, cycles
    // Copy the regs back to mem
    ldr r1, =cpu_regs
    stmia r1, {reg_f-reg_pc}
    // Return the undone cycles
    ldmfd sp!, {r4-r12, pc}

cpu_reset:
    stmfd sp!, {r4-r6, lr}
    ldr r4, =0xfffd
    mov r0, r4
    bl readb
    mov r5, r0, lsl #8
    sub r0, r4, #1
    bl readb
    orr r0, r5
    ldr r6, =cpu_regs
    mov r5, r0          // r5 = pc
    mov r4, #0xfd       // r4 = sp
    rebase_pc r5
    mov r0, #0          // r0 = f
    mov r1, #0          // r1 = y
    mov r2, #0          // r2 = x
    mov r3, #0          // r3 = a
    stmia r6!, {r0-r5}
    ldmfd sp!, {r4-r6, pc}

cpu_regs:
    .word 0,0,0,0,0,0

last_page:
    .word 0

.section .rodata
unhandled_msg: 
    .ascii "- Unhandled op!\n"
debug_msg:
    .ascii "A%02x X%02x Y%02x OP%02x F%02x SP%02x P%04x\n"
    .byte 0
#ifdef CHECK_IDLE_JUMP
idle_loop_msg:
    .ascii "Idle %04x\n"
    .byte 0
#endif
