#ifndef _UTIL_H_
#define _UTIL_H_
#include "global.h"
int yylex();
int yylex(void);
void yyerror(char *s);
TreeNode *createTreeNodeStmt(char*);
TreeNode *createTreeNodeConstant();
TreeNode *createTreeNodeExp(ExpKind, char*, OpType, SymbolType, int);
void insert(char*, size_t, TreeNode*);
SymbolNode *lookup(char*);
#endif
