#ifndef _UTIL_H_
#define _UTIL_H_
#include "global.h"
int yylex(void);
void yyerror(char *s);
TreeNode *createTreeNodeStmt(char*);
TreeNode *createTreeNodeConstant(char*);
void addSymbol(char *symName, TypeNode *T);
TypeNode *lookup(char *idName);
int typeEqual(TypeNode* a, TypeNode *b);

#endif
