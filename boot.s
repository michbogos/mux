; Declare constants for the multiboot header.
MBALIGN  equ  0x00000001            ; align loaded modules on page boundaries
MEMINFO  equ  0x00000002        ; provide memory map
FRAMEBUFFER equ 8
AOUT_KLUDGE equ 0x00010000
FLAGS    equ  MBALIGN | MEMINFO ;| FRAMEBUFFER | AOUT_KLUDGE; this is the Multiboot 'flag' field
MAGIC    equ  0x1BADB002        ; 'magic number' lets bootloader find the header
CHECKSUM equ -(MAGIC + FLAGS)   ; checksum of above, to prove we are multiboot
 
; Declare a multiboot header that marks the program as a kernel. These are magic
; values that are documented in the multiboot standard. The bootloader will
; search for this signature in the first 8 KiB of the kernel file, aligned at a
; 32-bit boundary. The signature is in its own section so the header can be
; forced to be within the first 8 KiB of the kernel file.
section .multiboot
align 4
	dd MAGIC
	dd FLAGS
	dd CHECKSUM
 
; The multiboot standard does not define the value of the stack pointer register
; (esp) and it is up to the kernel to provide a stack. This allocates room for a
; small stack by creating a symbol at the bottom of it, then allocating 16384
; bytes for it, and finally creating a symbol at the top. The stack grows
; downwards on x86. The stack is in its own section so it can be marked nobits,
; which means the kernel file is smaller because it does not contain an
; uninitialized stack. The stack on x86 must be 16-byte aligned according to the
; System V ABI standard and de-facto extensions. The compiler will assume the
; stack is properly aligned and failure to align the stack will result in
; undefined behavior.

	gdt_start: ; don't remove the labels, they're needed to compute sizes and jumps
		; the GDT starts with a null 8-byte
		dd 0x0 ; 4 byte
		dd 0x0 ; 4 byte

	; GDT for code segment. base = 0x00000000, length = 0xfffff
	; for flags, refer to os-dev.pdf document, page 36
	gdt_code: 
		dw 0xffff    ; segment length, bits 0-15
		dw 0x0       ; segment base, bits 0-15
		db 0x0       ; segment base, bits 16-23
		db 10011010b ; flags (8 bits)
		db 11001111b ; flags (4 bits) + segment length, bits 16-19
		db 0x0       ; segment base, bits 24-31

	; GDT for data segment. base and length identical to code segment
	; some flags changed, again, refer to os-dev.pdf
	gdt_data:
		dw 0xffff
		dw 0x0
		db 0x0
		db 10010010b
		db 11001111b
		db 0x0

	gdt_end:

	; GDT descriptor
	gdt_descriptor:
		dw gdt_end - gdt_start - 1 ; size (16 bit), always one less of its true size
		dd gdt_start ; address (32 bit)

	; define some constants for later use
	CODE_SEG equ gdt_code - gdt_start
	DATA_SEG equ gdt_data - gdt_start

section .bss
align 16
stack_bottom:
resb 16384 ; 16 KiB
stack_top:
 
; The linker script specifies _start as the entry point to the kernel and the
; bootloader will jump to this position once the kernel has been loaded. It
; doesn't make sense to return from this function as the bootloader is gone.
; Declare _start as a function symbol with the given symbol size.
section .text
global _start:function (end - _start)
_start:
	; The bootloader has loaded us into 32-bit protected mode on a x86
	; machine. Interrupts are disabled. Paging is disabled. The processor
	; state is as defined in the multiboot standard. The kernel has full
	; control of the CPU. The kernel can only make use of hardware features
	; and any code it provides as part of itself. There's no printf
	; function, unless the kernel provides its own <stdio.h> header and a
	; printf implementation. There are no security restrictions, no
	; safeguards, no debugging mechanisms, only what the kernel provides
	; itself. It has absolute and complete power over the
	; machine.
 
	; To set up a stack, we set the esp register to point to the top of our
	; stack (as it grows downwards on x86 systems). This is necessarily done
	; in assembly as languages such as C cannot function without a stack.
	mov esp, stack_top
 
	; This is a good place to initialize crucial processor state before the
	; high-level kernel is entered. It's best to minimize the early
	; environment where crucial features are offline. Note that the
	; processor is not fully initialized yet: Features such as floating
	; point instructions and instruction set extensions are not initialized
	; yet. The GDT should be loaded here. Paging should be enabled here.
	; C++ features such as global constructors and exceptions will require
	; runtime support to work as well.
 
	; Enter the high-level kernel. The ABI requires the stack is 16-byte
	; aligned at the time of the call instruction (which afterwards pushes
	; the return pointer of size 4 bytes). The stack was originally 16-byte
	; aligned above and we've since pushed a multiple of 16 bytes to the
	; stack since (pushed 0 bytes so far) and the alignment is thus
	; preserved and the call is well defined.
    ; note, that if you are building on Windows, C functions may have "_" prefix in assembly: _kernel_main
	cli
	lgdt [gdt_descriptor] ; 2. load the GDT descriptor
    mov eax, cr0
    or eax, 0x1 ; 3. set 32-bit mode bit in cr0
    mov cr0, eax
    jmp CODE_SEG:init_pm ; 4. far jump by using a different segment
 
	; If the system has nothing more to do, put the computer into an
	; infinite loop. To do that:
	; 1) Disable interrupts with cli (clear interrupt enable in eflags).
	;    They are already disabled by the bootloader, so this is not needed.
	;    Mind that you might later enable interrupts and return from
	;    kernel_main (which is sort of nonsensical to do).
	; 2) Wait for the next interrupt to arrive with hlt (halt instruction).
	;    Since they are disabled, this will lock up the computer.
	; 3) Jump to the hlt instruction if it ever wakes up due to a
	;    non-maskable interrupt occurring or due to system management mode.
	cli
hang:	hlt
	jmp hang
end:

init_pm:
	mov ax, DATA_SEG ; 5. update the segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000 ; 6. update the stack right at the top of the free space
    mov esp, ebp
	extern kernel_main
	call kernel_main
	cli
	jmp hang