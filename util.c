#include "util.h"

void yyerror(char *s)
{
	fprintf(stderr, "%s\n", s);
}

SymbolNode *lookup(char *idName)
{

}

int BKDRhash(char *s)
{
	int n = strlen(s);
	int i;
	int res = 0;
	for (i = 0; i<n; ++i) {
		res = (res*HASH_SEED+s[i])%HASH_SIZE;
	}
	return res;
}

TreeNode *createTreeNodeStmt(StmtType stmtType)
{
	TreeNode *p = (TreeNode*)malloc(sizeof(TreeNode));
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = STMT;
	p->kind.stmtType = stmtType;
	p->child = p->sibling = NULL;
	return p;
}

TreeNode *createTreeNodeConstant()
{
	TreeNode *p = (TreeNode*)malloc(sizeof(TreeNode));
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = EXP;
	p->kind.expKind = CONSTKIND;
	p->child = p->sibling = NULL;
	return p;
}

TreeNode *createTreeNodeExp(ExpKind expKind, char *symbolName = NULL, OpType op = 0, SymbolType symbolType = 0, int size = 0)
// parameter size is only for ARRAYKIND
{
	TreeNode *p = (TreeNode*)malloc(sizeof(TreeNode));
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = EXP;
	p->kind.expKind = expKind;
	switch (expKind) { //OPKIND, IDKIND, FUNCKIND, ARRAYKIND
		OPKIND:
			p->attr.op = op;
			break;
		IDKIND:
			p->attr.symbolName = (char*)malloc(sizeof(symbolName));
			strcpy(p->attr.symbolName, symbolName);
			p->symbolType = symbolType;
			break;
		FUNCKIND:
			p->attr.symbolName = (char*)malloc(sizeof(symbolName));
			strcpy(p->attr.symbolName, symbolName);
			p->symbolType = symbolType;
			break;
		ARRAYKIND:
			p->attr.symbolName = (char*)malloc(sizeof(symbolName));
			strcpy(p->attr.symbolName, symbolName);
			p->symbolType = symbolType;
			p->attr.size = size;
			break;
		default:
	}
	p->child = p->sibling = NULL;
	return p;	
}