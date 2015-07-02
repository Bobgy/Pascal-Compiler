#include "global.h"
#include "util.h"

void yyerror(char *s)
{
	fprintf(stderr, "%s\n", s);
}

TreeNode *createTreeNodeStmt(char *stmtName)
{
	TreeNode *p = (TreeNode*)malloc(sizeof(TreeNode));
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = StmtKind;
	strcpy(p->kind.stmtName, stmtName);
	p->child = p->sibling = NULL;
	return p;
}

TreeNode *createTreeNodeConstant(char *Name)
{
	TreeNode *p = (TreeNode*)malloc(sizeof(TreeNode));
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = ExpKind;
	p->kind.expKind = ConstKind;
	strcpy(p->attr.name, Name);
	p->child = p->sibling = NULL;
	return p;
}

// Symbol Table
void addSymbol(char *symName, TypeNode *T)
{
	strcpy(symbolTable[stSize].symbolName, symName);
	symbolTable[stSize].type = T;
	++stSize;
}

TypeNode *lookup(char *idName)
{
	int i;
	for (i = 0; i<stSize; ++i) {
		if (strcmp(idName, symbolTable[i].symbolName)==0) {
			return symbolTable[i].type;
		}
	}
	fprintf(stderr, "Undefined ID %s\n", idName);
}

int typeEqual(TypeNode* a, TypeNode *b)
{
	return (strcmp(a->typeName, b->typeName)==0);
}
