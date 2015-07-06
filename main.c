#include "global.h"

SymbolNode symbolTable[SYMBOL_TABLE_SIZE];
TreeNode *syntaxTreeRoot;
extern int yydebug;

int main()
{
	fstream config;
	config.open(".config", ios::in);
	yydebug = 0;
	if (config.is_open()) {
		string a, b, c;
		while (config >> a >> b >> c) {
			if (b != "=") continue;
			if (a == "YYDEBUG") {
				yydebug = atoi(c.c_str());
				cerr << "CONFIG: YYDEBUG = " << yydebug << endl;
			}
		}
	}
	yyparse();
}
