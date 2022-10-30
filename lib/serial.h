#ifndef SERIAL_H
#define SERIAL_H
#define PORT 0x3f8
int init_serial();
void serial_write(char* data);
#endif
