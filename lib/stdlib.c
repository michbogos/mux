#include "stdlib.h"
#include "../drivers/ports.h"
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define PORT 0x3f8          // COM1

//String functions

int strlen(char s[]){
    int len = 0;
    while(s[len]){
        len++;
    }
    return len;
}
void reverse(char s[]) {
    int c, i, j;
    for (i = 0, j = strlen(s)-1; i < j; i++, j--) {
        c = s[i];
        s[i] = s[j];
        s[j] = c;
    }
}

void itoa(int n, char str[]) {
    int i, sign;
    if ((sign = n) < 0) n = -n;
    i = 0;
    do {
        str[i++] = n % 10 + '0';
    } while ((n /= 10) > 0);

    if (sign < 0) str[i++] = '-';
    str[i] = '\0';

    reverse(str);
}

//print

size_t terminal_row = 0;
size_t terminal_column = 0;
uint8_t terminal_color = 15;
uint16_t* terminal_buffer = (uint16_t*) 0xB8000;


void kprint(const char* data) 
{
	int i = 0;
	while(data[i]){
		if(data[i] == '\n'){
			terminal_row++;
			terminal_column = 0;
            i++;
		}
        else{
            const size_t index = terminal_row * VGA_WIDTH + terminal_column;
            terminal_buffer[index] = ((uint16_t) data[i] | (uint16_t) terminal_color << 8);
            if (++terminal_column == VGA_WIDTH) {
                terminal_column = 0;
            if (++terminal_row == VGA_HEIGHT)
                terminal_row = 0;
            }
        i++;
        }
	}
}

void clear_screen(){
terminal_row = 0;
terminal_column = 0;
terminal_color = 15;
terminal_buffer = (uint16_t*) 0xB8000;
for (size_t y = 0; y < VGA_HEIGHT; y++) {
		for (size_t x = 0; x < VGA_WIDTH; x++) {
			const size_t index = y * VGA_WIDTH + x;
			terminal_buffer[index] = ((uint16_t) ' ' | (uint16_t) terminal_color << 8);
		}
	}
}

//log