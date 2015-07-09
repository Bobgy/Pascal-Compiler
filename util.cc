#include "global.h"
#include "util.h"

char buf[MAX_LENGTH*10];
char path[MAX_LENGTH];
stack<FuncContext> funcContext;
int isGlobal = 1;

void FuncContext::dump() {
	fprintf(stderr, "Dumping symbol table info of %s:\n", funcName.c_str());
	for (auto x: symbolTable) {
		fprintf(stderr, "> %s\n",  x.first.c_str());
	}
	fflush(stderr);
}

void FuncContext::insertName(const string &name, Code code) {
	if(symbolTable.find(name) != symbolTable.end()){
		yyerror("The name has already been declared");
	}
	yyinfo("inserting name: ");
	yyinfo((char*)name.c_str());
	yyinfo("\n");
	symbolTable[name] = code;
}

// This is a global helper function to get a name in the current context.
// It includes both current namespace and the global namespace.
Code getName(const string &name) {
	Code code = funcContext.top().getName(name);
	if (code.getCodeKind() != Code::Code::UNDEFINED) return code;
	if (funcContext.size()>1) {
		code = globalFuncContext->getName(name);
		if (code.getCodeKind() != Code::UNDEFINED) return code;
	}
	funcContext.top().dump();
	if (funcContext.size()>1) globalFuncContext->dump();
	yyerror("name not found in symbol table");
	return Code();
}

FuncContext *getFuncContext() {
	assert(!funcContext.empty());
	return &funcContext.top();
}

void pushFuncContext(char *func) {
    yyinfo("Entering path: ");
	yyinfo(func);
	yyinfo("\n");

    //leaving global region
    isGlobal = 0;

	funcContext.push(FuncContext(func));
}

void popFuncContext() {
	yyinfo("Leaving path\n");
	funcContext.pop();
}

void yyerror(char *s)
{
	fprintf(stderr, "YYERROR: %s\n", s);
	exit(-1);
}

void yyinfo(char *s)
{
	fprintf(stderr, "%s", s);
	fflush(stderr);
}

int BKDRhash(char *s)
{
	unsigned int res = 0;
	for (; *s; ++s) {
		res = res * HASH_SEED + *s;
	}
	return res % SYMBOL_TABLE_SIZE;
}

void insert(char* idName, size_t address, TreeNode* treeNode)
{
	yyinfo("Inserting \"");
	yyinfo(idName);
	yyinfo("\"\n");
	int index = BKDRhash(idName);
	for (; index != SYMBOL_TABLE_SIZE; ++index) {
		char *name = symbolTable[index].symbolName;
		if (symbolTable[index].symbolName==NULL) break;
		else if (strcmp(name, idName)==0) {
			sprintf(buf, "%s redeclared!\n", name);
			yyerror(buf);
		}
	}
	symbolTable[index].symbolName = strAllocCopy(idName);
	symbolTable[index].address = address;
	symbolTable[index].treeNode = treeNode;
}

SymbolNode *lookup(char *idName)
{
	int index = BKDRhash(idName);
	int found = 0;
	for (; index!=SYMBOL_TABLE_SIZE; ++index) {
		if (symbolTable[index].symbolName==NULL) break; // not found
		if (strcmp(symbolTable[index].symbolName,idName)==0) {
			found = 1;
			break;
		}
	}
	if (found) {
		return symbolTable+index;
	} else {
		sprintf(buf, "Symbol \"%s\" not found\n", idName);
		yyinfo(buf);
		return NULL;
	}
}

TreeNode *createTreeNodeStmt(StmtType stmtType)
{
	TreeNode *p = new TreeNode;
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = STMTKIND;
	p->kind.stmtType = stmtType;
	return p;
}

TreeNode *createTreeNodeConstant()
{
	TreeNode *p = new TreeNode;
	if (p==NULL) {
		yyerror("Malloc TreeNode Failed!\n");
		return NULL;
	}
	p->nodeKind = EXPKIND;
	p->kind.expKind = CONSTKIND;
	return p;
}

TreeNode *createTreeNodeExp(Expression T)
// parameter size is only for ARRAYKIND
{
	TreeNode *p = new TreeNode;
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
			p->attr.symbolName = strAllocCopy(T.symbolName);
			p->symbolType = T.symbolType;
			break;
		FUNCKIND:
			p->attr.symbolName = strAllocCopy(T.symbolName);
			p->symbolType = T.symbolType;
			break;
		ARRAYKIND:
			p->attr.symbolName = strAllocCopy(T.symbolName);
			p->symbolType = T.symbolType;
			p->attr.size = T.size;
			break;
		RECORDKIND:
			break;
		default:
			break;
	}
	return p;
}


//allocate space that fits string s and copy it
char *strAllocCopy(char *s) {
	WARN_NULL(s);
	char *p = (char *) malloc(strlen(s)+1);
	WARN_NULL(p);
	if (p!=NULL) strcpy(p, s);
	return p;
}

//allocate space and concatenate catS and catT
char *strAllocCat(char *catS, char *catT) {
	WARN_NULL(catS); WARN_NULL(catT);
	char *ret = (char*) malloc(strlen(catS) + strlen(catT) + 1);
	strcpy(ret, catS);
	strcat(ret, catT);
	return ret;
}

//temporary storage for string pointers
char *strList[MAX_LENGTH];
//concatenate strings from global strList
char *strCatList(int len) {
	int totLen = 0, i;
	for (i=0; i<len; ++i) {
		char *s = strList[i];
		if (s != NULL) totLen += strlen(s);
	}
	char *ret = strAlloc(totLen + 1);
	for (i=0; i<len; ++i) {
		char *s = strList[i];
		if (s != NULL) strcat(ret, s);
	}
	return ret;
}

//allocate space for an empty string
char *strAlloc(int num) {
	char *p = (char *) malloc(num);
	WARN_NULL(p);
	p[0] = 0;
	return p;
}
