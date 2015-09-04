%{
#include "global.h"
#include "util.h"
Expression NULL_EXP, opExpr;
void init_template_expr(){
    opExpr.expKind = OPKIND;
}
%}

%token NAME

// OP
%token DOT EQUAL LB RB LP RP ASSIGN GE GT LE LT UNEQUAL
%token PLUS MINUS MUL MOD DIV OR AND NOT

// 保留字
%token PROGRAM TYPE OF RECORD CONST BEGIN_TOKEN END FUNCTION PROCEDURE ARRAY
%token IF THEN ELSE REPEAT UNTIL FOR DO TO DOWNTO CASE GOTO WHILE LABEL VAR
%token INTEGER REAL CHAR STRING SYS_CON SYS_FUNCT

%token COLON COMMA SEMI DOTDOT

%token SYS_PROC SYS_TYPE READ // see doc

%%
program_stmt:
    program_head  routine  DOT {
        $$ = createTreeNodeStmt(PROGRAM_STMT);
        $$->attr.symbolName = "main";
        syntaxTreeRoot = $$;
        $$->child = {$1, $2};
        //generate code for the main function
        Code func = $$->genCode();
    };

program_head:
    PROGRAM  NAME  SEMI { //$$->child = {parameters};
        $$ = createTreeNodeStmt(PROGRAM_HEAD);
        $$->derivation = 1;
        $$->attr.symbolName = strAllocCopy("main");

        //create a parameters node with an empty parameter_list
        TreeNode *parameters = createTreeNodeStmt(PARAMETERS);
        parameters->derivation = 2;

        $$->child = {parameters};
    };
routine: routine_head  routine_body {
    $$ = createTreeNodeStmt(ROUTINE);
    $$->child = {$1, $2};
}
;
sub_routine: routine_head  routine_body {
    $$ = createTreeNodeStmt(SUB_ROUTINE);
    $$->child = {$1, $2};
}
;

routine_head: label_part  const_part  type_part  var_part  routine_part {
    $$ = createTreeNodeStmt(ROUTINE_HEAD);
    $$->child = {$1, $2, $3, $4, $5};
}
;
label_part: { // just skipped
    $$ = createTreeNodeStmt(LABEL_PART);
}
;
const_part: CONST const_expr_list {
        $$ = createTreeNodeStmt(CONST_PART);
        $$->child = {$2};
    }
    | {
        $$ = createTreeNodeStmt(CONST_PART);
    }
;
const_expr_list: const_expr_list  NAME  EQUAL  const_value  SEMI {
            $4->attr.symbolName = strAllocCopy($2->attr.symbolName);
            strcpy($4->attr.symbolName, $2->attr.symbolName);
            $$ = createTreeNodeStmt(CONST_EXPR_LIST);
            $$->child = {$1, $4};
            // add to symbol table
            char *idName = $2->attr.symbolName;
            //insert(strAllocCat(path,idName),0,$4);
        }
        |  NAME  EQUAL  const_value  SEMI {
            $3->attr.symbolName = strAllocCopy($1->attr.symbolName);
            strcpy($3->attr.symbolName, $1->attr.symbolName);
            $$ = createTreeNodeStmt(CONST_EXPR_LIST);
            $$->child = {$3};
            // add to symbol table
            char *idName = $1->attr.symbolName;
            //insert(strAllocCat(path,idName),0,$3);
        }
;
const_value:
    INTEGER {
        $$ = $1;
        $$->symbolType = TYPE_INTEGER;
    }
    |  REAL {
        $$ = $1;
        $$->symbolType = TYPE_REAL;
    }
    |  CHAR {
        $$ = createTreeNodeConstant();
        $$->symbolType = TYPE_CHARACTER;
        $$->attr.value.character = $1->attr.symbolName[0];
    }
    |  STRING {
        $$ = createTreeNodeConstant();
        $$->symbolType = TYPE_STRING;
        $$->attr.value.string = strAllocCopy($1->attr.symbolName);
        strcpy($$->attr.value.string, $1->attr.symbolName);
    }
    |  SYS_CON {
        $$ = createTreeNodeConstant();
        if (strcmp($1->attr.symbolName,"false")==0) {
            $$->symbolType = TYPE_BOOLEAN;
            $$->attr.value.boolean = 0;
        } else if (strcmp($1->attr.symbolName,"true")==0) {
            $$->symbolType = TYPE_BOOLEAN;
            $$->attr.value.boolean = 1;
        } else if (strcmp($1->attr.symbolName,"maxint")==0) {
            $$->symbolType = TYPE_INTEGER;
            $$->attr.value.integer = INT_MAX;
        } else {
            $$->symbolType = TYPE_INTEGER;
            $$->attr.value.integer = 0;
        }
    }
;
type_part:
    TYPE type_decl_list {
        $$ = $2;
    }
    | {
        $$ = createTreeNodeStmt(TYPE_DECL_LIST);
    }
;
type_decl_list:
    //child = {type_definition1, type_definition2, ...};
    type_decl_list  type_definition {
        $$ = $1;
        $1->child.push_back($2);
    }
    | type_definition {
        $$ = createTreeNodeStmt(TYPE_DECL_LIST);
        $$->child = {$1};
    }
;
type_definition:
    NAME  EQUAL  type_decl  SEMI {
        $$ = createTreeNodeStmt(TYPE_DEFINITION);
        $$->attr.symbolName = strAllocCopy($1->attr.symbolName);
        $$->child = {$3};
    }
;
type_decl:
    simple_type_decl {
        $$ = $1;
    }
    |  array_type_decl {
        $$ = $1;
    }
    |  record_type_decl {
        $$ = $1;
    };
simple_type_decl: //TODO cannot determine which type
    SYS_TYPE { // "boolean", "char", "integer", "real"
        $$ = $1;
        $$->setStmtType(SIMPLE_TYPE_DECL);
        $$->derivation = 1;
        // type is in $$->symbolType
    }
    |  NAME {
        $$ = $1;
        $$->setStmtType(SIMPLE_TYPE_DECL);
        $$->derivation = 2;
    }
    |  LP  name_list  RP {
        yyerror("(simple_type_decl: LP name_list RP) not implemented!");
    }
    |  const_value  DOTDOT  const_value {  // just need this to pass test
        $$ = createTreeNodeStmt(SIMPLE_TYPE_DECL);
        $$->attr.value.integer = $3->attr.value.integer - $1->attr.value.integer + 1;
        $$->derivation = 4;
    }
    |  MINUS  const_value  DOTDOT  const_value
    |  MINUS  const_value  DOTDOT  MINUS  const_value
    |  NAME  DOTDOT  NAME
;
array_type_decl:
    ARRAY  LB  simple_type_decl  RB  OF  type_decl {
        $$ = createTreeNodeStmt(ARRAY_TYPE_DECL);
        $$->attr.size = $3->attr.value.integer;
        $$->child = {$3, $6};
    }
;
record_type_decl:
    RECORD  field_decl_list  END {
        $$ = $2;
    }
;
field_decl_list:
    field_decl_list  field_decl {
        $$ = $1;
        $$->child.push_back($2);
    }
    | field_decl {
        $$ = createTreeNodeStmt(RECORD_TYPE_DECL);
        $$->child = {$1};
    }
;
field_decl:
    name_list  COLON  type_decl  SEMI {
        $$ = createTreeNodeStmt(FIELD_DECL);
        $$->child = {$1, $3};
    }
;
name_list:
    name_list  COMMA  NAME {
        $$ = $1;
        $1->child.push_back($3);
    }
    | NAME {
        $$ = createTreeNodeStmt(NAME_LIST);
        $$->child = {$1};
    };
var_part:
    //$$->child = {var_decl_list}
    VAR  var_decl_list {
        $$ = createTreeNodeStmt(VAR_PART);
        $$->child = {$2};
        $$->derivation = 1;
    }
    | { //$$->child = {}
        $$ = createTreeNodeStmt(VAR_PART);
        $$->derivation = 2;
    }
;
var_decl_list :
    var_decl_list  var_decl {
        $$ = $1;
        $$->child.push_back($2);
    }
    | var_decl {
        $$ = createTreeNodeStmt(VAR_DECL_LIST);
        $$->child = {$1};
    };
var_decl:
    //$$->child = {name_list, type_decl}
    name_list  COLON  type_decl  SEMI {
        $$ = createTreeNodeStmt(VAR_DECL);
        $$->derivation = 1;
        $$->child = {$1, $3};
        //$$->genCode();
    };
routine_part:
    routine_part  function_decl {
        $$ = createTreeNodeStmt(ROUTINE_PART);
        $$->child = {$1, $2};
    }
    |  routine_part  procedure_decl {
        $$ = createTreeNodeStmt(ROUTINE_PART);
        $$->child = {$1, $2};
    }
    |  function_decl {
        $$ = $1;
    }
    |  procedure_decl {
        $$ = $1;
    }
    | {
        $$ = createTreeNodeStmt(ROUTINE_PART);
    };
function_decl :
    function_head  SEMI  sub_routine  SEMI {
        $$ = createTreeNodeStmt(FUNCTION_DECL);
        $$->child = {$1, $3};
    };
function_head:
    //$$->child = {parameters, simple_type_decl}
    FUNCTION  NAME  parameters  COLON  simple_type_decl {
        $$ = createTreeNodeStmt(FUNCTION_HEAD);
        $$->attr.symbolName = strAllocCopy($2->attr.symbolName);
        // function_head saved the name of function
        $$->child = {$3, $5};
    };
procedure_decl :
    procedure_head  SEMI  sub_routine  SEMI {
        $$ = createTreeNodeStmt(PROCEDURE_DECL);
        $$->child = {$1, $3};
    };
procedure_head :
    //$$->child = {parameters}
    PROCEDURE NAME parameters {
        $$ = createTreeNodeStmt(PROCEDURE_HEAD);
        $$->attr.symbolName = strAllocCopy($2->attr.symbolName);
        // procedure_head saved the name of function
        $$->child = {$3};
    };
parameters:
    LP  para_decl_list  RP {
        $$ = $2;
        $$->setStmtType(PARAMETERS);
        $$->derivation = 1;
    }
    | {
        $$ = createTreeNodeStmt(PARAMETERS);
        $$->derivation = 2;
    };
para_decl_list:
    //$$->child = {para_type_list0, para_type_list1, ...}
    para_decl_list  SEMI  para_type_list {
        $$ = $1;
        $$->child.push_back($3);
    }
    //$$->child = {para_type_list}
    | para_type_list {
        $$ = createTreeNodeStmt(PARA_DECL_LIST);
        $$->child = {$1};
    };
para_type_list:
    //$$->child = {var_para_list, simple_type_decl};
    var_para_list COLON  simple_type_decl {
        $$ = createTreeNodeStmt(PARA_TYPE_LIST);
        $$->derivation = $1->derivation;
        $$->child = {$1, $3};
    };
var_para_list:
    //$$->child = {name0, name1, ...}
    VAR name_list { // pass by reference
        $$ = $2;
        $$->setStmtType(VAR_PARA_LIST);
        $$->derivation = 1;
    };
    //$$->child = {name0, name1, ...}
    | name_list { // pass by value
        $$ = $1;
        $$->setStmtType(VAR_PARA_LIST);
        $$->derivation = 2;
    };
routine_body:
    compound_stmt {
        $$ = $1;
    }
;
compound_stmt:
    BEGIN_TOKEN  stmt_list  END {
        $$ = $2;
    }
;
stmt_list:
    stmt_list  stmt  SEMI {
        $$ = $1;
        $$->child.push_back($2);
    }
    | {
        $$ = createTreeNodeStmt(STMT_LIST);
    };
stmt:
    INTEGER  COLON non_label_stmt {
        yyerror("Label not implemented");
        $$ = $3;
    }
    |  non_label_stmt {
        $$ = $1;
    };
non_label_stmt:
    assign_stmt {
        $$ = $1;
    }
    | proc_stmt {
        $$ = $1;
    }
    | compound_stmt {
        $$ = $1;
    }
    | if_stmt {
        $$ = $1;
    }
    | repeat_stmt {
        $$ = $1;
    }
    | while_stmt {
        $$ = $1;
    }
    | for_stmt {
        $$ = $1;
    }
    | case_stmt {
        $$ = $1;
    }
    | goto_stmt {
        $$ = $1;
    };
assign_stmt:
    //$$->child = {expression}
    NAME ASSIGN expression {
        $$ = createTreeNodeStmt(ASSIGN_STMT);
        $$->derivation = 1;
        $$->child = {$3};
        $$->attr.symbolName = strAllocCopy($1->attr.symbolName);
    }
    | NAME LB expression RB ASSIGN expression {
        $$ = createTreeNodeStmt(ASSIGN_STMT);
        $$->derivation = 2;
        $$->child = {$6, $3};
        $$->attr.symbolName = strAllocCopy($1->attr.symbolName);
    }
    | NAME  DOT  NAME  ASSIGN  expression {
        $$ = createTreeNodeStmt(ASSIGN_STMT);
        $$->derivation = 3;
        $$->child = {$5, $3};
        $$->attr.symbolName = strAllocCopy($1->attr.symbolName);
    };
proc_stmt:
    NAME {
        Expression expArgs;
        expArgs.expKind = NAMEKIND;
        expArgs.symbolName = $1->attr.symbolName;
        $$ = createTreeNodeExp(expArgs);
        $$->derivation = 1;
    }
    |  NAME  LP  args_list  RP {
        Expression expArgs;
        expArgs.expKind = FUNCKIND;
        expArgs.symbolName = $1->attr.symbolName;
        $$ = createTreeNodeExp(expArgs);
        $$->derivation = 2;
        $$->child = {$3};
    }
    |  SYS_PROC { // just skipped
    }
    |  SYS_PROC  LP  args_list  RP { // only need to consider writeln()
        $$ = createTreeNodeStmt(PROC_STMT);
        $$->child = {$1, $3};
        $$->derivation = 4;
    }
    |  READ  LP  factor  RP {
        $$ = createTreeNodeStmt(PROC_STMT);
        $$->child = {$3};
    }
;
if_stmt:
    IF  expression  THEN  stmt  else_clause {
        $$ = createTreeNodeStmt(IF_STMT);
        $$->child = {$2, $4, $5};
    };
else_clause:
    ELSE stmt {
        $$ = $2;
    }
    | {
        $$ = createTreeNodeStmt(ELSE_CLAUSE);
    }
;
repeat_stmt: REPEAT  stmt_list  UNTIL  expression {
                $$ = createTreeNodeStmt(REPEAT_STMT);
                $$->child = {$2, $4};
            };
while_stmt: WHILE  expression  DO stmt {
                $$ = createTreeNodeStmt(WHILE_STMT);
                $$->child = {$2};
            };
for_stmt:
    FOR  NAME  ASSIGN  expression  direction  expression  DO stmt {
        $$ = createTreeNodeStmt(FOR_STMT);
        $$->child = {$4, $5, $6, $8};
        $$->attr.symbolName = strAllocCopy($2->attr.symbolName);
    };
direction:
    TO {
        $$ = createTreeNodeStmt(DIRECTION);
        $$->derivation = 1;
    }
    | DOWNTO {
        $$ = createTreeNodeStmt(DIRECTION);
        $$->derivation = 2;
    }
;
case_stmt:     CASE expression OF case_expr_list  END {
                $$ = createTreeNodeStmt(CASE_STMT);
                $$->child = {$2, $4};
            };
case_expr_list: case_expr_list  case_expr {
                    $$ = createTreeNodeStmt(CASE_EXPR_LIST);
                    $$->child = {$1, $2};
                }
                | case_expr {
                    $$ = createTreeNodeStmt(CASE_EXPR_LIST);
                    $$->child = {$1};
                }
;
case_expr:     const_value  COLON  stmt  SEMI {
                $$ = createTreeNodeStmt(CASE_EXPR);
                $$->child = {$1, $3, $4};
            }
              |  NAME  COLON  stmt  SEMI {
                  $$ = createTreeNodeStmt(CASE_EXPR);
                $$->child = {$3};
              }
;
goto_stmt: GOTO  INTEGER // just skipped
;

  /////////////////////////////////////
 ////      expression part        ////
/////////////////////////////////////
expression:
    expression  GE  expr {
        opExpr.op = OP_GE;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
    }
    |  expression  GT  expr {
        opExpr.op = OP_GT;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
    }
    |  expression  LE  expr {
        opExpr.op = OP_LE;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
    }
    |  expression  LT  expr {
        opExpr.op = OP_LT;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
    }
    |  expression  EQUAL  expr {
        opExpr.op = OP_EQUAL;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
    }
    |  expression  UNEQUAL  expr {
        opExpr.op = OP_UNEQUAL;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
    }
    |  expr {
        $$ = $1;
    };
expr:
    expr  PLUS  term {
        opExpr.op = OP_PLUS;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
    }
    |  expr  MINUS  term {
        opExpr.op = OP_MINUS;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
    }
    |  expr  OR  term {
        opExpr.op = OP_OR;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
    }
    |  term {
        $$ = $1;
    };
term: term  MUL  factor {
        opExpr.op = OP_MUL;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
        $$->derivation = 1;
    }
    |  term  DIV  factor {
        opExpr.op = OP_DIV;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
        $$->derivation = 2;
    }
    |  term  MOD  factor {
        opExpr.op = OP_MOD;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
        $$->derivation = 3;
    }
    |  term  AND  factor {
        opExpr.op = OP_AND;
        $$ = createTreeNodeExp(opExpr);
        $$->child = {$1, $3};
        $$->derivation = 4;
    }
    |  factor {
        $$ = $1;
    }
;
factor:
    NAME {
        Expression expArgs;
        expArgs.expKind = NAMEKIND;
        expArgs.symbolName = $1->attr.symbolName;
        $$ = createTreeNodeExp(expArgs);
        $$->derivation = 1;
    }
    |  NAME  LP  args_list  RP {
        Expression expArgs;
        expArgs.expKind = FUNCKIND;
        expArgs.symbolName = $1->attr.symbolName;
        $$ = createTreeNodeExp(expArgs);
        $$->derivation = 2;
        $$->child = {$3};
    }
    |  SYS_FUNCT { //"abs", "chr", "odd", "ord", "pred", "sqr", "sqrt", "succ"
        $$ = createTreeNodeExp(NULL_EXP); //FUNCKIND,$1,0,TYPE_INTEGER
    }
    |  SYS_FUNCT  LP  args_list  RP {
        $$ = createTreeNodeExp(NULL_EXP); //FUNCKIND,$1,0,TYPE_INTEGER
        $$->child = {$3};
    }
    |  const_value {
        $$ = $1;
        $$->derivation = 5;
    }
    |  LP  expression  RP {
        $$ = $2;
    }
    |  NOT  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_NOT
        $$->child = {$2};
    }
    |  MINUS  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_MINUS
        $$->child = {$2};
    }
    |  NAME  LB  expression  RB {
        Expression expArgs;
        expArgs.expKind = NAMEKIND;
        expArgs.symbolName = $1->attr.symbolName;
        $$ = createTreeNodeExp(expArgs);
        $$->child = {$3};
        $$->derivation = 9;
    }
    |  NAME  DOT  NAME {
        Expression expArgs;
        expArgs.expKind = NAMEKIND;
        expArgs.symbolName = $1->attr.symbolName;
        $$ = createTreeNodeExp(expArgs);
        $$->child = {$3};
        $$->derivation = 10;
    }
;
args_list: //$$->child = {exp, exp, exp, ...}
    args_list  COMMA  expression {
        $$ = $1;
        $$->child.push_back($3);
    }
    |  expression {
        $$ = createTreeNodeStmt(ARGS_LIST);
        $$->child = {$1};
    }
;

%%
