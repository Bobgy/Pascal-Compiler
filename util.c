#include "util.h"

void yyerror(char *s)
{
	fprintf(stderr, "%s\n", s);
}

void insert(char* idName, size_t address, TreeNode* treeNode)
{
	int index = BKDRhash(idName);
	for (; index!=SYMBOL_TABLE_SIZE; ++index) {
		if (symbolTable[index].symbolName==NULL) break;
	}
	strcpy(symbolTable[index].symbolName,idName);
	symbolTable[index].address = address;
	symbolTable[index].treeNode = treeNode;
}

SymbolNode *lookup(char *idName)
{
	int index = BKDRhash(idName);
	for (; index!=SYMBOL_TABLE_SIZE; ++index) {
		if (strcmp(symbolTable[index].symbolName,idName)==0) break;
	}
	return symbolTable+index;
}

int BKDRhash(char *s)
{
	int n = strlen(s);
	int i;
	unsigned int res = 0;
	for (i = 0; i<n; ++i) {
		res = res*HASH_SEED+s[i];
	}
	return res%SYMBOL_TABLE_SIZE;
}

TreeNode *createTreeNodeStmt(StmtType stmtType)
{
	TreeNode *p = (TreeNode*)malloc(sizeof(TreeNode));
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = STMTKIND;
	p->kind.stmtType = stmtType;
	p->child = p->sibling = NULL;
	p->attr.assembly = NULL;
	return p;
}

TreeNode *createTreeNodeConstant()
{
	TreeNode *p = (TreeNode*)malloc(sizeof(TreeNode));
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = EXPKIND;
	p->kind.expKind = CONSTKIND;
	p->child = p->sibling = NULL;
	p->attr.assembly = NULL;
	return p;
}

TreeNode *createTreeNodeExp(Expression T)
// parameter size is only for ARRAYKIND
{
	TreeNode *p = (TreeNode*)malloc(sizeof(TreeNode));
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = EXPKIND;
	p->kind.expKind = T.expKind;
	switch (T.expKind) { //OPKIND, IDKIND, FUNCKIND, ARRAYKIND
		OPKIND:
			p->attr.op = T.op;
			break;
		IDKIND:
			p->attr.symbolName = (char*)malloc(sizeof(T.symbolName));
			strcpy(p->attr.symbolName, T.symbolName);
			p->symbolType = T.symbolType;
			break;
		FUNCKIND:
			p->attr.symbolName = (char*)malloc(sizeof(T.symbolName));
			strcpy(p->attr.symbolName, T.symbolName);
			p->symbolType = T.symbolType;
			break;
		ARRAYKIND:
			p->attr.symbolName = (char*)malloc(sizeof(T.symbolName));
			strcpy(p->attr.symbolName, T.symbolName);
			p->symbolType = T.symbolType;
			p->attr.size = T.size;
			break;
		default:
			break;
	}
	p->child = p->sibling = NULL;
	p->attr.assembly = NULL;
	return p;
}


//allocate space that fits string s and copy it
char *strAllocCopy(char *s) {
	char *p = (char *) malloc(strlen(s)+1);
	if (p!=NULL) strcpy(p, s);
	return p;
}
