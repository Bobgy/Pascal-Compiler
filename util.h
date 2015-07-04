#ifndef _UTIL_H_
#define _UTIL_H_
#include "global.h"
int yylex();
int yylex(void);
void yyerror(char *s);
TreeNode *createTreeNodeStmt(StmtType);
TreeNode *createTreeNodeConstant();
typedef struct expression {
	ExpKind expKind;
	char *symbolName;
	OpType op;
	SymbolType symbolType;
	int size;
} Expression;
TreeNode *createTreeNodeExp(Expression);
void insert(char*, size_t, TreeNode*);
SymbolNode *lookup(char*);

//allocate space that fits string s and copy it
char *strAllocCopy(char *s);
#endif
