#ifndef STDLIB_H
#define STDLIB_H

#include <stddef.h>

#define RAND_MAX 32767

int   rand(void);
void  srand(unsigned int seed);

void* malloc(size_t size);
void  free(void* ptr);
int   abs(int j);
void  exit(int status);

#endif