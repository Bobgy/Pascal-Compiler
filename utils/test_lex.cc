#include "../util.h"
#include "../y.tab.h"
#include <stdio.h>
YYSTYPE yylval;
FuncContext *globalFuncContext;
SymbolNode symbolTable[SYMBOL_TABLE_SIZE];
int main(){
	int rt=-1;
	while((rt=yylex())){
		printf("%d\n", rt);
		switch(rt) {
			case NAME:
				fprintf(stderr, "NAME: %s\n", yylval->attr.symbolName);
				break;
			case REAL:
				fprintf(stderr, "REAL: %.4lf\n", yylval->attr.value.real);
				break;
			case INTEGER:
				fprintf(stderr, "INTEGER: %d\n", yylval->attr.value.integer);
				break;
		}
	}
	fprintf(stderr, "======================\n");
}
