#ifndef STDLIB_H
#define STDLIB_H
#include<stddef.h>
#include<stdint.h>

int strlen(char s[]);
void reverse(char s[]);
void itoa(int n, char str[]);

void kprint(const char* data);
void clear_screen();

#endif