#include <stdio.h>
#include <string.h>

const int cn = 2;
const double dn = 123.23;

typedef struct {
    int a, b;
} ar;

int i;
ar j;
char str[256];

int add(int a, int b) {
    return a + b;
}

void main() {
    j.a = 0;
    for (i=0; i<10; ++i) {
        j.a = j.a + i;
    }
    printf("%d\n", j.a);
    
    switch (j.a % 4) {
        case 0: strcpy(str, "A1"); break;
        case 1: strcpy(str, "B2"); break;
        case cn: strcpy(str, "C3"); break;
        case 3: strcpy(str, "D4"); break;
    }

    if (j.a >= 0) {
        j.a = j.a + 1;
    }
    printf("%d\n", j.a);
    printf("%s\n", str);
}
