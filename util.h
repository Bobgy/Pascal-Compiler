#ifndef _UTIL_H_
#define _UTIL_H_
#include "global.h"
int yylex();
int yylex(void);
void yyerror(char *s);
void yyinfo(char *s);
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
int BKDRhash(char *s);
void insert(char*, size_t, TreeNode*);
SymbolNode *lookup(char*);

//allocate space that fits string s and copy it
char *strAllocCopy(char *);

//allocate space and concatenate catS and catT
char *strAllocCat(char *catS, char *catT);

//concatenate path
void strCatPath(char *path, char *name);

//get parent path
void strParentPath(char *path);

//parse tree to assembly type string
char *asmParseType(TreeNode *);

//concatenate assembly of a node's siblings
char *asmCatSiblin(TreeNode *p);

#endif
