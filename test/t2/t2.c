#include <stdio.h>

int i;

int go(int a) {
    int ret;
    if (a==1) {
        ret = 1;
    } else {
        if (a==2) {
            ret = 1;
        } else {
            ret = go(a-1) + go(a-2);
        }
    }
    return ret;
}

void main() {
    i = go(10);
    printf("%d\n", i);
}
