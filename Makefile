C_SOURCES = $(wildcard kernel/*.c drivers/*.c cpu/*.c lib/*.c)
HEADERS = $(wildcard kernel/*.h drivers/*.h cpu/*.h lib/*.h)
# Nice syntax for file extension replacement
OBJ = ${C_SOURCES:.c=.o} 

# Change this if your cross-compiler is somewhere else
CC = i686-elf-gcc
GDB = i686-elf-gdb
# -g: Use debugging symbols in gcc
CFLAGS = -g -ffreestanding -Wall -Wextra -fno-exceptions

# First rule is run by default
boot.o: boot.s
	nasm -felf32 boot.s -o boot.o

# '--oformat binary' deletes all symbols as a collateral, so we don't need
# to 'strip' them manually on this case
kernel.bin: ${OBJ}
	nasm -felf32 boot.s -o boot.o
	i686-elf-gcc -T linker.ld -o $@ -ffreestanding -O2 -nostdlib $^ boot.o -lgcc

# Used for debugging purposes
kernel.elf: boot/kernel_entry.o ${OBJ}
	i386-elf-ld -o $@ -Ttext 0x1000 $^ 

run: kernel.bin
	qemu-system-i386 -kernel kernel.bin -serial file:serial.txt

# Open the connection to qemu and load our kernel-object file with symbols
debug: os-image.bin kernel.elf
	qemu-system-i386 -s -fda os-image.bin -d guest_errors,int &
	${GDB} -ex "target remote localhost:1234" -ex "symbol-file kernel.elf"

# Generic rules for wildcards
# To make an object, always compile from its .c
%.o: %.c ${HEADERS}
	${CC} ${CFLAGS} -c $< -o $@

%.o: %.s
	nasm $< -felf32 -o $@

%.bin: %.s
	nasm $< -f bin -o $@

clean:
	rm -rf *.bin *.dis *.o os-image.bin *.elf
	rm -rf kernel/*.o boot/*.bin drivers/*.o boot/*.o cpu/*.o lib/*.o