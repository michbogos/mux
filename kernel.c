#include <stdint.h>
#include <stddef.h>
#include "limine.h"
 
// The Limine requests can be placed anywhere, but it is important that
// the compiler does not optimise them away, so, usually, they should
// be made volatile or equivalent.
 
static volatile struct limine_framebuffer_request framebuffer_request = {
    .id = LIMINE_FRAMEBUFFER_REQUEST,
    .revision = 0
};
 
static void done(void) {
    for (;;) {
        asm ("hlt");
    }
}
 
// Our quick and dirty strlen() implementation.
size_t strlen(const char *str) {
    size_t ret = 0;
    while (*str++) {
        ret++;
    }
    return ret;
}
 
// The following will be our kernel's entry point.
void _start(void) {
    // Ensure we got a terminal
    if (framebuffer_request.response == NULL
     || framebuffer_request.response->framebuffers < 1) {
        done();
    }
 
    // We should now be able to call the Limine terminal to print out
    // a simple "Hello World" to screen.
    const char *hello_msg = "Hello World";

    struct limine_framebuffer *framebuffer = framebuffer_request.response->framebuffers[0];

    int pitch = framebuffer->pitch;
    int width = framebuffer->width;
    int height = framebuffer->height;
    int pixelwidth = framebuffer->bpp;

    int* adress = (int*)framebuffer->address;

    for(int i = 0; i < width; i++){
        for(int j = 0; j < height; j ++){
            adress[i*width+j] = 0xff0000;
        }
    }
 
    //struct limine_terminal *terminal = terminal_request.response->terminals[0];
    //terminal_request.response->write(terminal, hello_msg, strlen(hello_msg));
 
    // We're done, just hang...
    done();
}