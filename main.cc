#include "global.h"
#include <fstream>

extern int yydebug;

SymbolNode symbolTable[SYMBOL_TABLE_SIZE];
TreeNode *syntaxTreeRoot;

static Module *TheModule;
static IRBuilder<> Builder(getGlobalContext());
static std::map<std::string, Value*> NamedValues;

void loadConfig() {
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
}

int main()
{
	loadConfig();

	LLVMContext &Context = getGlobalContext();

	// the target module to generate
	TheModule = new Module("pascal", Context);

	yyparse();

	// dump generated assembly code
	TheModule->dump();

	return 0;
}
