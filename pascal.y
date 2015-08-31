%{
#include "global.h"
#include "util.h"
Expression NULL_EXP;
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
    $$->attr.assembly = $1->attr.assembly; // TODO: add routine_body
}
;
sub_routine: routine_head  routine_body {
    $$ = createTreeNodeStmt(SUB_ROUTINE);
    $$->child = {$1, $2};
    $$->attr.assembly = $1->attr.assembly; // TODO: add routine_body
}
;

routine_head: label_part  const_part  type_part  var_part  routine_part {
    $$ = createTreeNodeStmt(ROUTINE_HEAD);
    $$->child = {$1, $2, $3, $4, $5};
    //$$->attr.assembly = asmCatSiblin($1);
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
    };

type_part: TYPE type_decl_list {
                $$ = createTreeNodeStmt(TYPE_PART);
                $$->child = {$2};
            }
            | {
                $$ = createTreeNodeStmt(TYPE_PART);
            };
type_decl_list: type_decl_list  type_definition {
                    $$ = createTreeNodeStmt(TYPE_DECL_LIST);
                    $$->child = {$1, $2};
                }
                | type_definition {
                    $$ = createTreeNodeStmt(TYPE_DECL_LIST);
                    $$->child = {$1};
                }
;
type_definition: NAME  EQUAL  type_decl  SEMI {
                    $$ = createTreeNodeStmt(TYPE_DEFINITION);
                    $$->attr.symbolName = strAllocCopy($1->attr.symbolName);
                    strcpy($$->attr.symbolName, $1->attr.symbolName);
                    // store typename in type_definition node
                }
;
type_decl:
    simple_type_decl {
        $$ = $1;
    }
    |  array_type_decl {  // TODO-Bobgy
        $$ = createTreeNodeStmt(TYPE_DECL);
        $$->derivation = 2;
        $$->child = {$1};
    }
    |  record_type_decl { // TODO-Bobgy
        $$ = createTreeNodeStmt(TYPE_DECL);
        $$->derivation = 3;
        $$->child = {$1};
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
        $$->attr.value.integer = $3->attr.value.integer;
        $$->derivation = 4;
    }
    |  MINUS  const_value  DOTDOT  const_value
    |  MINUS  const_value  DOTDOT  MINUS  const_value
    |  NAME  DOTDOT  NAME
;
array_type_decl:
    ARRAY  LB  simple_type_decl  RB  OF  type_decl {
        $$ = createTreeNodeStmt(ARRAY_TYPE_DECL);
        $$->symbolType = $6->symbolType;
        $$->attr.size = $3->attr.value.integer;
    }
;
record_type_decl:
    RECORD  field_decl_list  END {
        $$ = $2;
    }
;
field_decl_list:
    field_decl_list  field_decl {
        $$ = $2;
        $$->child = {$1};
    }
    | field_decl {
        $$ = $1;
    }
;
field_decl:
    name_list  COLON  type_decl  SEMI {
        $$ = createTreeNodeStmt(RECORD_TYPE_DECL);
        $$->symbolType = $3->symbolType;
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
        $$ = createTreeNodeStmt(VAR_DECL_LIST);
        $$->child = {$1, $2};
        $$->attr.assembly = $1->attr.assembly + $2->attr.assembly;
    }
    | var_decl {
        $$ = createTreeNodeStmt(VAR_DECL_LIST);
        $$->child = {$1};
        $$->attr.assembly = $1->attr.assembly;
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

        Code func = $$->genCode();
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
routine_body: compound_stmt {
                $$ = createTreeNodeStmt(ROUTINE_BODY);
                $$->child = {$1};
            }
;
compound_stmt: BEGIN_TOKEN  stmt_list  END {
                    $$ = createTreeNodeStmt(COMPOUND_STMT);
                    $$->child = {$2};
                }
;
stmt_list:
    stmt_list  stmt  SEMI {
        $$ = createTreeNodeStmt(STMT_LIST);
        $$->child = {$1, $2};
    }
    | {
        $$ = createTreeNodeStmt(STMT_LIST);
    };
stmt:
    INTEGER  COLON non_label_stmt {
        yyerror("Label not implemented");
        $$ = createTreeNodeStmt(STMT);
        $$->child = {$3};
    }
    |  non_label_stmt {
        $$ = $1;
        //$$->genCode();
    };
non_label_stmt:
    assign_stmt {
        $$ = $1;
    }
    | proc_stmt {
        $$ = createTreeNodeStmt(NON_LABEL_STMT);
        $$->derivation = 2;
        $$->child = {$1};
    }
    | compound_stmt {
        $$ = createTreeNodeStmt(NON_LABEL_STMT);
        $$->child = {$1};
    }
    | if_stmt {
        $$ = createTreeNodeStmt(NON_LABEL_STMT);
        $$->child = {$1};
    }
    | repeat_stmt {
        $$ = createTreeNodeStmt(NON_LABEL_STMT);
        $$->child = {$1};
    }
    | while_stmt {
        $$ = createTreeNodeStmt(NON_LABEL_STMT);
        $$->child = {$1};
    }
    | for_stmt {
        $$ = createTreeNodeStmt(NON_LABEL_STMT);
        $$->child = {$1};
    }
    | case_stmt {
        $$ = createTreeNodeStmt(NON_LABEL_STMT);
        $$->child = {$1};
    }
    | goto_stmt {
        $$ = createTreeNodeStmt(NON_LABEL_STMT);
        $$->child = {$1};
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
        $$->child = {$3, $5};
    }
    | NAME  DOT  NAME  ASSIGN  expression {
        $$ = createTreeNodeStmt(ASSIGN_STMT);
        $$->derivation = 3;
        $$->child = {$5};
    };
proc_stmt:     NAME {
                $$ = createTreeNodeStmt(PROC_STMT);
            }
              |  NAME  LP  args_list  RP {
                $$ = createTreeNodeStmt(PROC_STMT);
                $$->child = {$3};
            }
             |  SYS_PROC { // just skipped
            }
              |  SYS_PROC  LP  expression_list  RP { // only need to consider writeln()
                $$ = createTreeNodeStmt(PROC_STMT);
                $$->child = {$3};
            }
              |  READ  LP  factor  RP {
                $$ = createTreeNodeStmt(PROC_STMT);
                $$->child = {$3};
            }
;
if_stmt: IF  expression  THEN  stmt  else_clause {
            $$ = createTreeNodeStmt(IF_STMT);
            $$->child = {$2, $4, $5};
        };
else_clause: ELSE stmt {
                $$ = createTreeNodeStmt(ELSE_CALUSE);
                $$->child = {$2};
            }
|;
repeat_stmt: REPEAT  stmt_list  UNTIL  expression {
                $$ = createTreeNodeStmt(REPEAT_STMT);
                $$->child = {$2, $4};
            };
while_stmt: WHILE  expression  DO stmt {
                $$ = createTreeNodeStmt(WHILE_STMT);
                $$->child = {$2};
            };
for_stmt:     FOR  NAME  ASSIGN  expression  direction  expression  DO stmt {
                $$ = createTreeNodeStmt(FOR_STMT);
                $$->child = {$4, $5, $6, $8};
            };
direction:     TO {
                $$ = createTreeNodeStmt(DIRECTION);
            }
              | DOWNTO {
                  $$ = createTreeNodeStmt(DIRECTION);
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
expression_list: expression_list  COMMA  expression {
                    $$ = createTreeNodeStmt(EXPRESSION_LIST);
                    $$->child = {$1, $3};
                }
                | expression {
                    $$ = createTreeNodeStmt(EXPRESSION_LIST);
                    $$->child = {$1};
                }
;
expression:
    expression  GE  expr {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_GE
        $$->child = {$1, $3};
    }
    |  expression  GT  expr {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_GT
        $$->child = {$1, $3};
    }
    |  expression  LE  expr {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_LE
        $$->child = {$1, $3};
    }
    |  expression  LT  expr {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_LT
        $$->child = {$1, $3};
    }
    |  expression  EQUAL  expr {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_EQUAL
        $$->child = {$1, $3};
    }
    |  expression  UNEQUAL  expr {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_UNEQUAL
        $$->child = {$1, $3};
    }
    |  expr {
        $$ = $1;
    };
expr:
    expr  PLUS  term {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_PLUS
        $$->derivation = 1;
        $$->child = {$1, $3};
    }
    |  expr  MINUS  term {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_MINUS
        $$->derivation = 2;
        $$->child = {$1, $3};
    }
    |  expr  OR  term {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_OR
        $$->derivation = 3;
        $$->child = {$1, $3};
    }
    |  term {
        $$ = $1;
    };
term: term  MUL  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_MUL
        $$->derivation = 1;
        $$->child = {$1, $3};
    }
    |  term  DIV  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_DIV
        $$->derivation = 2;
        $$->child = {$1, $3};
    }
    |  term  MOD  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_MOD
        $$->derivation = 3;
        $$->child = {$1, $3};
    }
    |  term  AND  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_AND
        $$->derivation = 4;
        $$->child = {$1, $3};
    }
    |  factor {
        $$ = $1;
    }
;
factor:
    NAME {
        $$ = $1;
    }
    |  NAME  LP  args_list  RP {
        Expression expArgs;
        expArgs.expKind = FUNCKIND;
        expArgs.symbolName = $1->attr.symbolName;
        $$ = createTreeNodeExp(expArgs);
        $$->derivation = 2;
        $$->child.push_back($3);
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
    }
    |  NAME  DOT  NAME {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OP_DOT
        //memcpy($$->child,lookup($1->attr.symbolName),sizeof(TreeNode));
    }
;
args_list:     args_list  COMMA  expression {
                $$ = createTreeNodeStmt(ARGS_LIST);
                $$->child = {$1, $3};
            }
            |  expression {
                $$ = createTreeNodeStmt(ARGS_LIST);
                $$->child = {$1};
            }
;

%%
