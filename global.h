#ifndef _GLOBAL_H_
#define _GLOBAL_H_

// llvm headers
#include "llvm/Analysis/Passes.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
//#include "llvm/ExecutionEngine/MCJIT.h"
#include "llvm/ExecutionEngine/SectionMemoryManager.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/PassManager.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Support/raw_ostream.h"

// stl headers
#include <cctype>
#include <cstdio>
#include <map>
#include <string>
#include <vector>
#include <stack>
#include <iostream>

using namespace std;
using namespace llvm;

int yylex();
int yyparse();
extern int yydebug;
extern int debuginfo;
#define DEBUG_INFO(x) do { if(debuginfo)yyinfo(x); } while(0)
#define ASSERT(x) {if(!(x)){yyinfo("ASSERT Failed with ");yyerror(#x);}}

void yyerror(const char *s);
void yyinfo(const char *s);

typedef union {
    int integer;
    double real;
    char character;
    unsigned char boolean;
    char *string;
} SymbolValue;

// a helper class that wraps around a union pointer
// codeKind is the actual kind
// value refer to llvm::Value
// function refer to llvm::Function
// type refer to llvm:Type
class Code {
public:
    enum CodeKind {
        UNDEFINED,
        VALUE,
        FUNCTION,
        TYPE
    };
private:
    union {
        Value *value;
        Function *function;
        Type *type;
    };
    CodeKind codeKind;
public:
    Code(): codeKind(UNDEFINED) {}
    Code(Value *_) { setValue(_); }
    Code(Function *_) { setFunction(_); }
    Code(Type *_) { setType(_); }
    CodeKind getCodeKind() const {
        return codeKind;
    }
    void setValue(Value *_) {
        value = _;
        codeKind = Code::VALUE;
    }
    void setFunction(Function *_) {
        function = _;
        codeKind = Code::FUNCTION;
    }
    void setType(Type *_) {
        type = _;
        codeKind = Code::TYPE;
    }
    Value *getValue() {
        ASSERT(getCodeKind() == Code::VALUE);
        return value;
    }
    Function *getFunction() {
        ASSERT(getCodeKind() == Code::FUNCTION);
        return function;
    }
    Type *getType() {
        ASSERT(getCodeKind() == Code::TYPE);
        return type;
    }
    void dump();
};

// Syntax Tree
typedef enum {STMTKIND,EXPKIND} NodeKind;
typedef enum {
    OPKIND, CONSTKIND, IDKIND, FUNCKIND, ARRAYKIND, RECORDKIND, NAMEKIND
} ExpKind;
typedef enum {
    //0
    OP_UNDEFINED, OP_EQUAL, OP_LP, OP_RP, OP_LB,
    //5
    OP_RB, OP_ASSIGN, OP_GE, OP_GT, OP_LE,
    //10
    OP_LT, OP_UNEQUAL, OP_PLUS, OP_MINUS, OP_MUL,
    //15
    OP_MOD, OP_DIV, OP_OR, OP_AND, OP_NOT,
    //20
    OP_DOT
} OpType;
typedef enum {
    TYPE_VOID, TYPE_INTEGER, TYPE_BOOLEAN, TYPE_REAL, TYPE_CHARACTER, TYPE_STRING
} SymbolType;

typedef enum {
    //0
    ARRAY_TYPE_DECL, ASSIGN_STMT, ARGS_LIST, CASE_STMT, CASE_EXPR,
    //5
    CASE_EXPR_LIST, COMPOUND_STMT, CONST_PART, CONST_EXPR_LIST, DIRECTION,
    //10
    ELSE_CLAUSE, EXPRESSION_LIST, FIELD_DECL, FIELD_DECL_LIST, FOR_STMT,
    //15
    FUNCTION_DECL, FUNCTION_HEAD, IF_STMT, LABEL_PART, NAME_LIST,
    //20
    NON_LABEL_STMT, PARA_DECL_LIST, PARA_TYPE_LIST, PARAMETERS, PROCEDURE_DECL,
    //25
    PROCEDURE_HEAD, PROGRAM_STMT, PROGRAM_HEAD, PROC_STMT, RECORD_TYPE_DECL,
    //30
    REPEAT_STMT, ROUTINE, ROUTINE_HEAD, ROUTINE_BODY, ROUTINE_PART,
    //35
    SIMPLE_TYPE_DECL, SUB_ROUTINE, STMT, STMT_LIST, TYPE_DECL,
    //40
    TYPE_DECL_LIST, TYPE_DEFINITION, TYPE_PART, VAR_DECL, VAR_DECL_LIST,
    //45
    VAR_PART, VAR_PARA_LIST, WHILE_STMT, CONST_EXPR
} StmtType;

struct TreeNode {
    vector<TreeNode *> child;

    // the derivation this node used, start from 1
    // for example,
    //   expression_list:
    //       expression_list  COMMA  expression (derivation = 1)
    //     | expression                         (derivation = 2)
    unsigned derivation;
    NodeKind nodeKind; // STMTKIND, EXPKIND
    union {
        StmtType stmtType;
        ExpKind expKind;
    } kind;
    struct {
        OpType op; // operator
        SymbolValue value; // constant, remember check symbolType first
        char* symbolName; // symbol name, type name, function/procedure name
        int size; // array size
    } attr;
    SymbolType symbolType;
    Code genCode();
    void setStmtType(StmtType stmtType) {
        nodeKind = STMTKIND;
        kind.stmtType = stmtType;
    }
    void setExpType(ExpKind expKind) {
        nodeKind = EXPKIND;
        kind.expKind = expKind;
    }
};

extern TreeNode *syntaxTreeRoot; // Root of Syntax Tree
extern Module *TheModule;
extern IRBuilder<> Builder;
extern map<string, AllocaInst *> NamedValues;
extern FunctionPassManager *TheFPM;

#ifndef YYSTYPE_IS_DECLARED
    #define YYSTYPE_IS_DECLARED 1
    typedef TreeNode *YYSTYPE;
#endif

#define WARN_NULL(x) do { if ((x) == NULL) {fprintf(stderr, "WARNING: "#x" is NULL\n");} } while(0)

#define MAX_LENGTH 128

#endif
