#include <cstdio>

int v[100];

int main () {
  int i;
  for (i = 99; ; i += 3) {
    printf ("%d", v[i]);
  }
  return 0;
}
