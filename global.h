#ifndef _GLOBAL_H_
#define _GLOBAL_H_

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>

int yylex();
int yyparse();

#define MAXSIZE 1000000
SymbolNode symbolTable[MAXSIZE];
int stSize;

typedef enum {Void, Integer, Boolean, Real, Character, String } SymbolType;
const int sizeOfType[] = {0, 4, 1, 8, 1, 256};
typedef enum {Element, Array, Function, Constant} SymbolKind;
typedef union {
	int integer;
	double real;
	char character;
	unsigned char boolean;
	char string[256];
} SymbolValue;

// default type
TypeNode *boolean;
TypeNode *integer;
TypeNode *array;

// symbol table element
struct symbolNode {
	char symbolName[256] ;
	size_t address; // store runtime address
	TypeNode *data; // store named-constant data
} SymbolNode;

// Syntax Tree
typedef enum {StmtKind,ExpKind} NodeKind;
typedef enum {
	OpKind, ConstKind, IdKind, FuncKind, ArrayKind
} ExpKind;
typedef enum {
	DOT, EQUAL, LP, RP, LB, RB, ASSIGN, GE, GT, LE, LT, UNEQUAL, 
	PLUS, MINUS, MUL, MOD, DIV, OR, AND, NOT
} OpType;

#define MAXCHILDREN 3

typedef struct treeNode {
	TreeNode *child; // for exp
	TreeNode *sibling; // for stmt
	NodeKind nodeKind; // StmtK, ExpK
	union {
		char stmtName[256];
		ExpKind expKind;
	} kind;
	struct {
		OpType op; // operator
		SymbolValue value; // unnamed-constant
		char name[256]; // symbol name
	} attr;
	SymbolType type;
} TreeNode;

TreeNode *syntaxTreeRoot; // Root of Syntax Tree

#endif
