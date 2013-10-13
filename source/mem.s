.arm
.section .itcm,"ax",%progbits

.global readb
.global writeb
.global mem_reset

.global mainram
.global lcram
.global jstk_btn
.global jstk_axis
.global memmap_w
.global memmap_r
.global keybd_latch
.global jstk_rst_cycle
.global page_dirty

// uint8_t readb (uint16_t addr)
readb:
    mov r1, r0, lsr #8
    cmp r1, #0xc0
    beq 1f
    mov r1, r1, lsr #4
    ldr r2, =memmap_r
    ldr r3, [r2, r1, lsl #2]
    ldrb r0, [r3, r0]
    bx lr
    // IO Read @ 0xc000
1:  and r1, r0, #0xf0
    ldr pc, [pc, r1, lsr #2]
    nop
io_read_tbl:
    .word io_keybd
    .word io_keybdl
    .word io_null
    .word io_spkr
    .word io_null
    .word video_io_read
    .word io_jstk
    .word io_jstk_rst
    .word io_lc    
    .word io_null
    .word io_null
    .word io_null
    .word io_null
    .word io_null
    .word disk_io_read
    .word io_null

.ltorg

// void writeb (uint16_t addr, uint8_t val)
writeb:
    mov r2, r0, lsr #8
    cmp r2, #0xc0
    // IO Read
    beq 1f
    mov r2, r2, lsr #2
    // Mark the page as dirty
    mov r3, #1
    ldr r12, =page_dirty
    strb r3, [r12, r2]
    mov r2, r2, lsr #2
    ldr r12, =memmap_w
    ldr r3, [r12, r2, lsl #2]
    strb r1, [r3, r0]
    bx lr
1:  and r1, r0, #0xf0
    ldr pc, [pc, r1, lsr #2]
    nop
io_write_tbl:
    .word io_null  
    .word io_keybdl
    .word io_null
    .word io_null
    .word io_null
    .word video_io_read
    .word io_jstk_rst 
    .word io_null
    .word io_lc
    .word io_null
    .word io_null
    .word io_null
    .word io_null
    .word io_null
    .word disk_io_read
    .word io_null

.ltorg

// IO handlers

io_keybd:
    ldr r2, =keybd_latch
    ldr r0, [r2]
    bx lr

io_keybdl:
    ldr r2, =keybd_latch
    ldr r0, [r2]
    // Clear the latch
    and r0, #0x7f
    str r0, [r2]
    bx lr

io_jstk:
    and r0, #0xf
    ldr r1, =(jstk_btn-4)
    cmp r0, #0x4
    ldr r0, [r1, r0, lsl #2]
    // Handle the pushbutton status
    bxlo lr
    ldr r1, [r1, #32] // jstk_rst_cycle
    // Check how many cycles have passed
    subs r2, r1, r5
    ldrmi r3, =17030
    addmi r2, r3
    // Should the paddle be sent low ?
    cmp r2, r0
    movls r0, #0x80
    movhi r0, #0x00
    bx lr
   
io_jstk_rst:
    ldr r0, =jstk_rst_cycle
    str r5, [r0]
    // Read KEYINPUT
    ldr r3, =0x4000130
    ldrh r3, [r3]
    // Find how many cycles the joystick counter takes to return to 0
    mvn r3, r3, lsr #4
    adr r2, axis_to_cycles 
    and r3, #0xf
    add r2, r3, lsl #2
    ldrh r1, [r2, #0]
    str r1, [r0, #-16]
    ldrh r1, [r2, #2]
    str r1, [r0, #-12]
    bx lr
    // The pdlread routine takes 11 cycles
axis_to_cycles:  
.short 0x7f*11,0x7f*11 // 
.short 0xff*11,0x7f*11 // R
.short 0x00*11,0x7f*11 // L
.short 0x00*11,0x7f*11 // R+L
.short 0x7f*11,0x00*11 // U
.short 0xff*11,0x00*11 // R+U
.short 0x00*11,0x00*11 // L+U
.short 0x00*11,0x00*11 // R+L+U
.short 0x7f*11,0xff*11 // D
.short 0xff*11,0xff*11 // R+D
.short 0x00*11,0xff*11 // L+D
.short 0x00*11,0xff*11 // R+L+D
.short 0x7f*11,0xff*11 // U+D
.short 0xff*11,0xff*11 // R+U+D
.short 0x00*11,0xff*11 // L+U+D
.short 0x00*11,0xff*11 // R+L+U+D

io_lc:
    ldr r12, =memmap_w
    ldr r3, =(mainram+0x4000)
    // Do it backwards so we can reuse r3
    str r3, [r12, #0xf<<2]
    str r3, [r12, #0xe<<2]
    // Select between bank 1/2
    tst r0, #8
    mov r2, r3
    subne r2, #0x1000
    str r2, [r12, #0xd<<2]
    // Check if rom is mapped on read
    ldr r1, =map_rom_tbl
    and r0, #3
    ldr r0, [r1, r0, lsl #2]
    ldr r12, =memmap_r
    tst r0, #1 // this is lame
    bne 1f // map the rom
    str r2, [r12, #0xd<<2]
    str r3, [r12, #0xe<<2]
    str r3, [r12, #0xf<<2]
    bx  lr
1:  sub r3, #0x4000
    str r3, [r12, #0xd<<2]
    str r3, [r12, #0xe<<2]
    str r3, [r12, #0xf<<2]
    bx lr

io_spkr:
    mov r0, r5
    ldr r1, =sound_spkr_flip
    bx r1
    
io_null:
    mov r0, #0
    bx lr

mem_reset:
    ldr r0, =memmap_r
    ldr r1, =memmap_w
    ldr r2, =mainram
    mov r3, #0x10
1:  str r2, [r0], #4
    str r2, [r1], #4
    subs r3, #1
    bne 1b
    bx lr

.ltorg

.bss
.align 4
mainram:
    .space 0x10000
lcram:
    .space 0x1000*4

.section .dtcm
.align 4
memmap_r:
    .rept 16
    .word mainram
    .endr

memmap_w:
    .rept 16
    .word mainram
    .endr

page_dirty:
    .rept 64
    .byte 0
    .endr

// A button is active when the 7th bit is set
jstk_btn:
    .word 0     // PB1
    .word 0     // PB2
    .word 0     // PB3 (shift)
// Axis are 0 <= x <= 255, where 0x80 is center
jstk_axis:
    .word 0     // P1 X
    .word 0     // P1 Y
    .word 0     // P2 X
    .word 0     // P2 Y
// io_jstk_rst relies on this to be after the joystick
// data for correct indexing. Don't move.
jstk_rst_cycle:
    .word 0

keybd_latch:
    .word 0

.section .rodata
map_rom_tbl:
    .word 0,1,1,0

