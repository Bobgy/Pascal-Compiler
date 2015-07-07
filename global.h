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

typedef enum {Element, Array, Function, Constant} SymbolKind;
typedef union {
	int integer;
	double real;
	char character;
	unsigned char boolean;
	char *string;
} SymbolValue;

// Syntax Tree
typedef enum {STMTKIND,EXPKIND} NodeKind;
typedef enum {
	OPKIND, CONSTKIND, IDKIND, FUNCKIND, ARRAYKIND, RECORDKIND
} ExpKind;
typedef enum {
	OP_DOT, OP_EQUAL, OP_LP, OP_RP, OP_LB, OP_RB, OP_ASSIGN, OP_GE, OP_GT, OP_LE, OP_LT,
	OP_UNEQUAL, OP_PLUS, OP_MINUS, OP_MUL, OP_MOD, OP_DIV, OP_OR, OP_AND, OP_NOT
} OpType;
typedef enum {
	TYPE_VOID, TYPE_INTEGER, TYPE_BOOLEAN, TYPE_REAL, TYPE_CHARACTER, TYPE_STRING
} SymbolType;

typedef enum {
	ARRAY_TYPE_DECL, ASSIGN_STMT, ARGS_LIST,
	CASE_STMT, CASE_EXPR, CASE_EXPR_LIST, COMPOUND_STMT, CONST_PART, CONST_EXPR_LIST,
	DIRECTION,
	ELSE_CALUSE, EXPRESSION_LIST,
	FIELD_DECL, FIELD_DECL_LIST, FOR_STMT, FUNCTION_DECL, FUNCTION_HEAD,
	IF_STMT,
	LABEL_PART,
	NAME_LIST, NON_LABEL_STMT,
	PARA_DECL_LIST, PARA_TYPE_LIST, PARAMETERS,
	PROCEDURE_DECL, PROCEDURE_HEAD, PROGRAM_STMT, PROGRAM_HEAD, PROC_STMT,
	RECORD_TYPE_DECL, REPEAT_STMT,
	ROUTINE, ROUTINE_HEAD, ROUTINE_BODY, ROUTINE_PART,
	SIMPLE_TYPE_DECL, SUB_ROUTINE, STMT, STMT_LIST,
	TYPE_DECL, TYPE_DECL_LIST, TYPE_DEFINITION, TYPE_PART,
	VAR_DECL, VAR_DECL_LIST, VAR_PART, VAR_PARA_LIST, VAR_VAR_PARA_LIST,
	WHILE_STMT
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
		string assembly; //generated assembly, NULL means no code
	} attr;
	SymbolType symbolType;
};

extern TreeNode *syntaxTreeRoot; // Root of Syntax Tree
extern Module *TheModule;
extern IRBuilder<> Builder;
extern map<string, AllocaInst *> NamedValues;
extern FunctionPassManager *TheFPM;

// symbol table
#define SYMBOL_TABLE_SIZE 1000007
#define HASH_SEED 9875321
typedef struct symbolNode {
	char* symbolName;
	size_t address; // store runtime address
	TreeNode *treeNode; // id on tree
} SymbolNode;

extern SymbolNode symbolTable[SYMBOL_TABLE_SIZE];

#ifndef YYSTYPE_IS_DECLARED
	#define YYSTYPE_IS_DECLARED 1
	typedef TreeNode *YYSTYPE;
#endif

#define WARN_NULL(x) do { if ((x) == NULL) {fprintf(stderr, "WARNING: "#x" is NULL\n");} } while(0)

#define MAX_LENGTH 128

#endif
