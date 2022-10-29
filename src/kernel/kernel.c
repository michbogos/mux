#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "../libc/stdlib.h"

enum vga_color {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15,
};

static const size_t VGA_WIDTH = 80;
static const size_t VGA_HEIGHT = 25;
 
size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer;
 
void terminal_initialize(void) 
{
	terminal_row = 0;
	terminal_column = 0;
	terminal_color = VGA_COLOR_BLACK;
	terminal_buffer = (uint16_t*) 0xB8000;
	for (size_t y = 0; y < VGA_HEIGHT; y++) {
		for (size_t x = 0; x < VGA_WIDTH; x++) {
			const size_t index = y * VGA_WIDTH + x;
			terminal_buffer[index] = ((uint16_t) ' ' | (uint16_t) terminal_color << 8);
		}
	}
}
 
void kprint(const char* data, uint8_t fg) 
{
	int i = 0;
	while(data[i]){
		if(data[i] == '\n'){
			terminal_column  = 0;
			terminal_row ++;
			continue;
		}
		const size_t index = terminal_row * VGA_WIDTH + terminal_column;
		terminal_buffer[index] = ((uint16_t) data[i] | (uint16_t) fg << 8);
		if (++terminal_column == VGA_WIDTH) {
		terminal_column = 0;
		if (++terminal_row == VGA_HEIGHT)
			terminal_row = 0;
		}
		i++;
	}
}
 
void kernel_main(void) 
{
	/* Initialize terminal interface */
	terminal_initialize();
 
	/* Newline support is left as an exercise. */
	for(int i = 0; i< 100; i++){
		for(int i = 0; i<1000; i++){
			char buffer[20];
			itoa(i, buffer);
			kprint(buffer, i%16);
		}
	}
}