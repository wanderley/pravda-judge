#include <cstdio>
#include <cstring>
#include <cstdlib>

#define BLOCK 1000000

int main () {
  while (1) {
    int *a = (int *) malloc (BLOCK * sizeof (int));
    memset (a, 0, BLOCK * sizeof (int));
  }
  return 0;
}

