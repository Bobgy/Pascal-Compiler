#include "global.h"

SymbolNode symbolTable[SYMBOL_TABLE_SIZE];
TreeNode *syntaxTreeRoot;

int main()
{
	yyparse();
}
