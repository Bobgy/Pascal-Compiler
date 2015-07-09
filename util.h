#ifndef _UTIL_H_
#define _UTIL_H_
#include "global.h"

class FuncContext {
private:
	map<string, Code> symbolTable;
public:
	string funcName;
	FuncContext(const string &name): funcName(name) {
		// do nothing
	}
	void insertName(const string &name, Code code);
	// get the code corresponding to a name
	// return Code with codeKind==Code::UNDEFINED when not found
	Code getName(const string &name) {
		auto it = symbolTable.find(name);
		if (it != symbolTable.end()) return it->second;
		return Code();
	}
	void dump();
};

//function context
extern stack<FuncContext> funcContext;

extern char buf[MAX_LENGTH*10];
extern char path[MAX_LENGTH];
extern int isGlobal;

void pushFuncContext(char *s);
void popFuncContext();
Code getName(const string &name);
FuncContext *getFuncContext();
extern FuncContext *globalFuncContext;

int yylex();
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

//temporary storage for string pointers
extern char *strList[MAX_LENGTH];
//concatenate strings from global strList
char *strCatList(int len);

#endif
