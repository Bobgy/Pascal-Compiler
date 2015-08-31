#include "global.h"
#include "util.h"

char buf[MAX_LENGTH*10];
stack<FuncContext> funcContext;
int isGlobal = 1;

void FuncContext::dump() {
    fprintf(stderr, "Dumping symbol table info of %s:\n", funcName.c_str());
    for (auto x: symbolTable) {
        fprintf(stderr, "> %s\n",  x.first.c_str());
        x.second.dump();
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
    sprintf(buf, "name %s not found in symbol table\n", name.c_str());
    yyerror(buf);
    return Code();
}

FuncContext *getFuncContext() {
    assert(!funcContext.empty());
    return &funcContext.top();
}

void pushFuncContext(const char *func) {
    yyinfo("Entering path: ");
    yyinfo(func);
    yyinfo("\n");

    if (funcContext.empty()){
        funcContext.push(FuncContext(func, string(func)+"$"));
        globalFuncContext = &funcContext.top();
    } else {
        string stmp = funcContext.top().path + func;
        funcContext.push(FuncContext(func, stmp+"$"));
    }
}

void popFuncContext() {
    yyinfo("Leaving path\n");
    funcContext.pop();
    if (!funcContext.empty()) {
        Builder.SetInsertPoint(
            &funcContext.top().getCurrentFunction()->getEntryBlock()
        );
    }
}

void yyerror(const char *s)
{
    fprintf(stderr, "YYERROR: %s\n", s);
    exit(-1);
}

void yyinfo(const char *s)
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

/// CreateEntryBlockAlloca - Create an alloca instruction in the entry block of
/// the function.  This is used for mutable variables etc.
AllocaInst *CreateEntryBlockAlloca(Function *TheFunction,
                                          const char * VarName, Code Type) {
    IRBuilder<> TmpB(
        &TheFunction->getEntryBlock(),
        TheFunction->getEntryBlock().begin()
    );
    AllocaInst *alloca = TmpB.CreateAlloca(
        Type.getType(),
        0, VarName
    );
    getFuncContext()->insertName(VarName, alloca);
    return alloca;
}

void Code::dump(){
   switch(getCodeKind()){
       case VALUE:
           DEBUG_INFO("Value:\n");
           getValue()->dump();
           break;
       case FUNCTION:
           DEBUG_INFO("Function:\n");
           getFunction()->dump();
           break;
       case TYPE:
           DEBUG_INFO("Type\n");
           break;
       case UNDEFINED:
           DEBUG_INFO("Undefined\n");
           break;
       default:
           DEBUG_INFO("Error: not found\n");
   }
}
