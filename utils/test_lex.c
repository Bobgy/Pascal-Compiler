#include "../lex.yy.h"
#include <stdio.h>
int main(){
	int rt=-1;
	while(rt=yylex()){
		printf("%d\n", rt);
	}
}