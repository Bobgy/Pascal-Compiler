#include "global.h"

int main()
{
	// define default type
	boolean = createTypeNode("boolean", 0, 0, 1, NULL);
	integer = createTypeNode("integer", 0, 0, 4, NULL);
	array = createTypeNode("array", 1, 0, 0, NULL);
	return yyparse();
}