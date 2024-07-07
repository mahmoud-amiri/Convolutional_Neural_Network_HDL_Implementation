#include <stdio.h>
#include <svdpi.h>

int dpi_fopen(const char* filename, const char* mode) {
    FILE* file = fopen(filename, mode);
    if (file == NULL) {
        return 0;  // Return 0 if the file couldn't be opened
    }
    return (int)(uintptr_t)file;
}

int dpi_fclose(int file) {
    return fclose((FILE*)(uintptr_t)file);
}

int dpi_fread(unsigned char* data, int file) {
    size_t result = fread(data, 1, 1, (FILE*)(uintptr_t)file);
    return (result == 1) ? 1 : 0;
}
