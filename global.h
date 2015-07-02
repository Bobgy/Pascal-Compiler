#ifndef _GLOBAL_H_
#define _GLOBAL_H_

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>

int yylex();
int yyparse();

#define SYMBOL_TABLE_SIZE 1000000

typedef enum {Element, Array, Function, Constant} SymbolKind;
typedef union {
	int integer;
	double real;
	char character;
	unsigned char boolean;
	char *string;
} SymbolValue;

// symbol table element
struct symbolNode {
	char* symbolName;
	size_t address; // store runtime address
	TypeNode *data; // store named-constant data
} SymbolNode;

// Syntax Tree
typedef enum {STMT,EXP} NodeKind;
typedef enum {
	OPKIND, CONSTKIND, IDKIND, FUNCKIND, ARRAYKIND
} ExpKind;
typedef enum {
	DOT, EQUAL, LP, RP, LB, RB, ASSIGN, GE, GT, LE, LT, UNEQUAL,
	PLUS, MINUS, MUL, MOD, DIV, OR, AND, NOT
} OpType;
typedef enum {
	VOID, INTEGER, BOOLEAN, REAL, CHARACTER, STRING
} SymbolType;

typedef enum {
	CONST_PART, CONST_EXPR_LIST,
	FUNCTION_DECL, FUNCTION_HEAD, 
	LABEL_PART,  
	NAME_LIST, 
	PARA_DECL_LIST, PARA_TYPE_LIST,
	PROCEDURE_DECL, PROCEDURE_HEAD, PROGRAM, PROGRAM_HEAD, 
	ROUTINE, ROUTINE_HEAD, ROUTINE_BODY, ROUTINE_PART,	
	SIMPLE_TYPE_DECL, SUB_ROUTINE,
	TYPE_DECL, TYPE_PART, 
	VAR_DECL, VAR_DECL_LIST, VAR_PART, VAR_PARA_LIST	
} StmtType;

typedef struct treeNode {
	TreeNode *child; // for exp
	TreeNode *sibling; // for stmt
	NodeKind nodeKind; // StmtK, ExpK
	union {
		StmtType stmtType;
		ExpKind expKind;
	} kind;
	struct {
		OpType op; // operator
		SymbolValue value; // unnamed-constant
		char* symbolName; // symbol name
	} attr;
	SymbolType symbolType;
} TreeNode;

extern TreeNode *syntaxTreeRoot; // Root of Syntax Tree

#endif
