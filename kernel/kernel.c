#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "../lib/stdlib.h"
#include "../drivers/ports.h"
#include "../lib/serial.h"
 
void kernel_main(void) 
{
	//find a way to call global constructors
	/* Newline support is left as an exercise. */
	clear_screen();
	char buffer[16];
	int res = init_serial();
	itoa(res, buffer);
	kprint(buffer);
	kprint("Hello");
	serial_write("Hello");
}