#ifndef _UTIL_H_
#define _UTIL_H_
#include "global.h"

extern int depth;
typedef struct {
	char *initList;
	int paramCount;
} Stack;
extern Stack stack[MAX_LENGTH];
extern char buf[MAX_LENGTH*10];
void push();
void pop();
void pushInitList(char *p);
Stack *top();

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

//allocate space for an empty string
char *strAlloc(int num);

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

//temporary storage for string pointers
extern char *strList[MAX_LENGTH];
//concatenate strings from global strList
char *strCatList(int len);

#endif
