#ifndef _GLOBAL_H_
#define _GLOBAL_H_

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <assert.h>

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
	DOT, EQUAL, LP, RP, LB, RB, ASSIGN, GE, GT, LE, LT, UNEQUAL,
	PLUS, MINUS, MUL, MOD, DIV, OR, AND, NOT
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
	PROCEDURE_DECL, PROCEDURE_HEAD, PROGRAM, PROGRAM_HEAD, PROC_STMT,
	RECORD_TYPE_DECL, REPEAT_STMT,
	ROUTINE, ROUTINE_HEAD, ROUTINE_BODY, ROUTINE_PART,
	SIMPLE_TYPE_DECL, SUB_ROUTINE, STMT, STMT_LIST,
	TYPE_DECL, TYPE_DECL_LIST, TYPE_DEFINITION, TYPE_PART,
	VAR_DECL, VAR_DECL_LIST, VAR_PART, VAR_PARA_LIST, VAR_VAR_PARA_LIST,
	WHILE_STMT
} StmtType;

typedef struct treeNode {
	struct treeNode *child; // for exp
	struct treeNode *sibling; // for stmt
	NodeKind nodeKind; // STMTKIND, EXPKIND
	union {
		StmtType stmtType;
		ExpKind expKind;
	} kind;
	struct {
		OpType op; // operator
		SymbolValue value; // constant, remember check sumbolType first
		char* symbolName; // symbol name, type name, function/procedure name
		int size; // array size
		char* assembly; //generated assembly, NULL means no code
	} attr;
	SymbolType symbolType;
} TreeNode;

extern TreeNode *syntaxTreeRoot; // Root of Syntax Tree

// symbol table
#define SYMBOL_TABLE_SIZE 1000007
#define HASH_SEED 31;
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
