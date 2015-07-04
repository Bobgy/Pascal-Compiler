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
program: program_head  routine  DOT {
    WARN_NULL($$ = createTreeNodeStmt(PROGRAM));
    syntaxTreeRoot = $$;
    $$->child = $1;
    $1->sibling = $2;
    if ($1->attr.assembly != NULL) {
        printf("%s\n", $1->attr.assembly);
    } else {
        printf("ERROR: NULL program\n");
    }
}
;
program_head: PROGRAM  NAME  SEMI // just skipped
;
routine: routine_head  routine_body {
    WARN_NULL($$ = createTreeNodeStmt(ROUTINE));
    $$->child = $1;
    $1->sibling = $2;
}
;
sub_routine: routine_head  routine_body {
    WARN_NULL($$ = createTreeNodeStmt(SUB_ROUTINE));
    $$->child = $1;
    $1->sibling = $2;
}
;

routine_head: label_part  const_part  type_part  var_part  routine_part {
    WARN_NULL($$ = createTreeNodeStmt(ROUTINE_HEAD));
    $$->child = $1;
    $1->sibling = $2; $2->sibling = $3; $3->sibling = $4; $4->sibling = $5;
}
;
label_part: // just skipped
;
const_part: CONST const_expr_list {
    WARN_NULL($$ = createTreeNodeStmt(CONST_PART));
    $$->child = $2;
}
|;
const_expr_list: const_expr_list  NAME  EQUAL  const_value  SEMI {
            $4->attr.symbolName = (char*)malloc(strlen($2->attr.symbolName)+1);
            strcpy($4->attr.symbolName, $2->attr.symbolName);
            WARN_NULL($$ = createTreeNodeStmt(CONST_EXPR_LIST));
            $$->child = $1;
            $1->sibling = $4;
        }
        |  NAME  EQUAL  const_value  SEMI {
            $3->attr.symbolName = (char*)malloc(strlen($1->attr.symbolName)+1);
            strcpy($3->attr.symbolName, $1->attr.symbolName);
            WARN_NULL($$ = createTreeNodeStmt(CONST_EXPR_LIST));
            $$->child = $3;
        }
;
const_value: INTEGER {
                WARN_NULL($$ = createTreeNodeConstant());
                $$->symbolType = INTEGER;
                $$->attr.value.integer = atoi($1->attr.symbolName);
            }
            |  REAL {
                WARN_NULL($$ = createTreeNodeConstant());
                $$->symbolType = REAL;
                $$->attr.value.real = atof($1->attr.symbolName);
            }
            |  CHAR {
                WARN_NULL($$ = createTreeNodeConstant());
                $$->symbolType = CHARACTER;
                $$->attr.value.character = $1->attr.symbolName[0];
            }
            |  STRING {
                WARN_NULL($$ = createTreeNodeConstant());
                $$->symbolType = STRING;
                $$->attr.value.string = (char*)malloc(strlen($1->attr.symbolName)+1);
                strcpy($$->attr.value.string, $1->attr.symbolName);
            }
            |  SYS_CON {
                WARN_NULL($$ = createTreeNodeConstant());
                if (strcmp($1->attr.symbolName,"false")==0) {
                    $$->symbolType = BOOLEAN;
                    $$->attr.value.boolean = 0;
                } else if (strcmp($1->attr.symbolName,"true")==0) {
                    $$->symbolType = BOOLEAN;
                    $$->attr.value.boolean = 1;
                } else if (strcmp($1->attr.symbolName,"maxint")==0) {
                    $$->symbolType = INTEGER;
                    $$->attr.value.integer = INT_MAX;
                } else {
                    $$->symbolType = INTEGER;
                    $$->attr.value.integer = 0;
                }
            };

type_part: TYPE type_decl_list {
                WARN_NULL($$ = createTreeNodeStmt(TYPE_PART));
                $$->child = $2;
            }
|;
type_decl_list: type_decl_list  type_definition {
                    WARN_NULL($$ = createTreeNodeStmt(TYPE_DECL_LIST));
                    $$->child = $1;
                    $1->sibling = $2;
                }
                | type_definition {
                    WARN_NULL($$ = createTreeNodeStmt(TYPE_DECL_LIST));
                    $$->child = $1;
                }
;
type_definition: NAME  EQUAL  type_decl  SEMI {
                    WARN_NULL($$ = createTreeNodeStmt(TYPE_DEFINITION));
                    $$->attr.symbolName = (char*)malloc(strlen($1->attr.symbolName)+1);
                    strcpy($$->attr.symbolName, $1->attr.symbolName);
                    // store typename in type_definition node
                }
;
type_decl:  simple_type_decl {
                WARN_NULL($$ = createTreeNodeStmt(TYPE_DECL));
                $$->child = $1;
            }
            |  array_type_decl {
                WARN_NULL($$ = createTreeNodeStmt(TYPE_DECL));
                $$->child = $1;
            }
            |  record_type_decl {
                WARN_NULL($$ = createTreeNodeStmt(TYPE_DECL));
                $$->child = $1;
            }
;
simple_type_decl: SYS_TYPE // "boolean", "char", "integer", "real"
                {
                    WARN_NULL($$ = createTreeNodeStmt(SIMPLE_TYPE_DECL));
                    $$->attr.symbolName = (char*)malloc(strlen($1->attr.symbolName)+1);
                    strcpy($$->attr.symbolName, $1->attr.symbolName);
                    // store type name in node
                }
                |  NAME
                |  LP  name_list  RP
                |  const_value  DOTDOT  const_value {  // just need this to pass test
                    WARN_NULL($$ = createTreeNodeStmt(SIMPLE_TYPE_DECL));
                    $$->child = $1;
                    $1->sibling = $3;
                }
                |  MINUS  const_value  DOTDOT  const_value
                |  MINUS  const_value  DOTDOT  MINUS  const_value
                |  NAME  DOTDOT  NAME
;
array_type_decl: ARRAY  LB  simple_type_decl  RB  OF  type_decl {
                    WARN_NULL($$ = createTreeNodeStmt(ARRAY_TYPE_DECL));
                    $$->child = $1;
                    $1->sibling = $2;
                }
;
record_type_decl: RECORD  field_decl_list  END {
                    WARN_NULL($$ = createTreeNodeStmt(RECORD_TYPE_DECL));
                    $$->child = $2;
                }
;

field_decl_list: field_decl_list  field_decl {
                    WARN_NULL($$ = createTreeNodeStmt(FIELD_DECL_LIST));
                    $$->child = $1;
                    $1->sibling = $2;
                }
                | field_decl {
                    WARN_NULL($$ = createTreeNodeStmt(FIELD_DECL_LIST));
                    $$->child = $1;
                }
;
field_decl: name_list  COLON  type_decl  SEMI {
                WARN_NULL($$ = createTreeNodeStmt(FIELD_DECL));
                $$->child = $1;
                $1->sibling = $3;
            }
;
name_list: name_list  COMMA  NAME {
            WARN_NULL($$ = createTreeNodeStmt(NAME_LIST));
            $$->child = $1;
        }
        |  NAME {
            WARN_NULL($$ = createTreeNodeStmt(NAME_LIST));
        }
;
var_part: VAR  var_decl_list {
    WARN_NULL($$ = createTreeNodeStmt(VAR_PART));
    $$->child = $2;
}
|;
var_decl_list : var_decl_list  var_decl {
                    WARN_NULL($$ = createTreeNodeStmt(VAR_DECL_LIST));
                    $$->child = $1;
                    $1->sibling = $2;
                 }
                 |  var_decl {
                     WARN_NULL($$ = createTreeNodeStmt(VAR_DECL_LIST));
                     $$->child = $1;
                 }
;
var_decl :  name_list  COLON  type_decl  SEMI {
                WARN_NULL($$ = createTreeNodeStmt(VAR_DECL));
                $$->child = $1;
                $1->sibling = $3;
            }
;
routine_part: routine_part  function_decl {
                WARN_NULL($$ = createTreeNodeStmt(ROUTINE_PART));
                $$->child = $1;
                $1->sibling = $2;
            }
        |  routine_part  procedure_decl {
            WARN_NULL($$ = createTreeNodeStmt(ROUTINE_PART));
            $$->child = $1;
            $1->sibling = $2;
        }
        |  function_decl {
            WARN_NULL($$ = createTreeNodeStmt(ROUTINE_PART));
            $$->child = $1;
        }
        |  procedure_decl {
            WARN_NULL($$ = createTreeNodeStmt(ROUTINE_PART));
            $$->child = $1;
        }
        | ;
function_decl : function_head  SEMI  sub_routine  SEMI {
                    WARN_NULL($$ = createTreeNodeStmt(FUNCTION_DECL));
                    $$->child = $1;
                    $1->sibling = $3;
                };
function_head :  FUNCTION  NAME  parameters  COLON  simple_type_decl {
                    WARN_NULL($$ = createTreeNodeStmt(FUNCTION_HEAD));
                    $$->attr.symbolName = (char*)malloc(strlen($2->attr.symbolName)+1);
                    strcpy($$->attr.symbolName, $2->attr.symbolName);
                    // function_head saved the name of function
                    $$->child = $3;
                    $3->sibling = $5;
                };
procedure_decl :  procedure_head  SEMI  sub_routine  SEMI {
                    WARN_NULL($$ = createTreeNodeStmt(PROCEDURE_DECL));
                    $$->child = $1;
                    $1->sibling = $3;
                };
procedure_head :  PROCEDURE NAME parameters {
                    WARN_NULL($$ = createTreeNodeStmt(PROCEDURE_HEAD));
                    $$->attr.symbolName = (char*)malloc(strlen($2->attr.symbolName)+1);
                    strcpy($$->attr.symbolName, $2->attr.symbolName);
                    // procedure_head saved the name of function
                    $$->child = $3;
                };
parameters: LP  para_decl_list  RP {
            WARN_NULL($$ = createTreeNodeStmt(PARAMETERS));
            $$->child = $2;
}
|;
para_decl_list: para_decl_list  SEMI  para_type_list {
                    WARN_NULL($$ = createTreeNodeStmt(PARA_DECL_LIST));
                    $$->child = $1;
                    $1->sibling = $3;
                }
                | para_type_list {
                    WARN_NULL($$ = createTreeNodeStmt(PARA_DECL_LIST));
                    $$->child = $1;
                };
para_type_list: var_para_list COLON  simple_type_decl {
                    WARN_NULL($$ = createTreeNodeStmt(PARA_TYPE_LIST));
                    $$->child = $1;
                    $1->sibling = $3;
                }
;
var_para_list: VAR name_list { // pass by reference
                    WARN_NULL($$ = createTreeNodeStmt(VAR_PARA_LIST));
                    $$->child = $2;
                };
                | name_list { // pass by value
                    WARN_NULL($$ = createTreeNodeStmt(VAR_PARA_LIST));
                    $$->child = $1;
                }
;
routine_body: compound_stmt {
                WARN_NULL($$ = createTreeNodeStmt(ROUTINE_BODY));
                $$->child = $1;
            }
;
compound_stmt: BEGIN_TOKEN  stmt_list  END {
                    WARN_NULL($$ = createTreeNodeStmt(COMPOUND_STMT));
                    $$->child = $2;
                }
;
stmt_list: stmt_list  stmt  SEMI {
                WARN_NULL($$ = createTreeNodeStmt(STMT_LIST));
                $$->child = $1;
                $1->sibling = $2;
            }
|;
stmt: INTEGER  COLON non_label_stmt {
        WARN_NULL($$ = createTreeNodeStmt(STMT));
        $$->child = $3;
    }
    |  non_label_stmt {
        WARN_NULL($$ = createTreeNodeStmt(STMT));
        $$->child = $1;
    }
;
non_label_stmt: assign_stmt {
                    WARN_NULL($$ = createTreeNodeStmt(NON_LABEL_STMT));
                    $$->child = $1;
                }
                | proc_stmt {
                    WARN_NULL($$ = createTreeNodeStmt(NON_LABEL_STMT));
                    $$->child = $1;
                }
                | compound_stmt {
                    WARN_NULL($$ = createTreeNodeStmt(NON_LABEL_STMT));
                    $$->child = $1;
                }
                | if_stmt {
                    WARN_NULL($$ = createTreeNodeStmt(NON_LABEL_STMT));
                    $$->child = $1;
                }
                | repeat_stmt {
                    WARN_NULL($$ = createTreeNodeStmt(NON_LABEL_STMT));
                    $$->child = $1;
                }
                | while_stmt {
                    WARN_NULL($$ = createTreeNodeStmt(NON_LABEL_STMT));
                    $$->child = $1;
                }
                | for_stmt {
                    WARN_NULL($$ = createTreeNodeStmt(NON_LABEL_STMT));
                    $$->child = $1;
                }
                | case_stmt {
                    WARN_NULL($$ = createTreeNodeStmt(NON_LABEL_STMT));
                    $$->child = $1;
                }
                | goto_stmt {
                    WARN_NULL($$ = createTreeNodeStmt(NON_LABEL_STMT));
                    $$->child = $1;
                }
;
assign_stmt: NAME  ASSIGN  expression {
                WARN_NULL($$ = createTreeNodeStmt(ASSIGN_STMT));
                $$->child = $3;
            }
           | NAME LB expression RB ASSIGN expression {
                WARN_NULL($$ = createTreeNodeStmt(ASSIGN_STMT));
                $$->child = $3;
                $$->sibling = $5;
            }
           | NAME  DOT  NAME  ASSIGN  expression {
                   WARN_NULL($$ = createTreeNodeStmt(ASSIGN_STMT));
                $$->child = $5;
           }
;
proc_stmt:     NAME {
                WARN_NULL($$ = createTreeNodeStmt(PROC_STMT));
            }
              |  NAME  LP  args_list  RP {
                WARN_NULL($$ = createTreeNodeStmt(PROC_STMT));
                $$->child = $3;
            }
             |  SYS_PROC { // just skipped
            }
              |  SYS_PROC  LP  expression_list  RP { // only need to consider writeln()
                WARN_NULL($$ = createTreeNodeStmt(PROC_STMT));
                $$->child = $3;
            }
              |  READ  LP  factor  RP {
                WARN_NULL($$ = createTreeNodeStmt(PROC_STMT));
                $$->child = $3;
            }
;
if_stmt: IF  expression  THEN  stmt  else_clause {
            WARN_NULL($$ = createTreeNodeStmt(IF_STMT));
            $$->child = $2;
            $2->sibling = $4; $4->sibling = $5;
        };
else_clause: ELSE stmt {
                WARN_NULL($$ = createTreeNodeStmt(ELSE_CALUSE));
                $$->child = $2;
            }
|;
repeat_stmt: REPEAT  stmt_list  UNTIL  expression {
                WARN_NULL($$ = createTreeNodeStmt(REPEAT_STMT));
                $$->child = $2;
                $2->sibling = $4;
            };
while_stmt: WHILE  expression  DO stmt {
                WARN_NULL($$ = createTreeNodeStmt(WHILE_STMT));
                $$->child = $2;
            };
for_stmt:     FOR  NAME  ASSIGN  expression  direction  expression  DO stmt {
                WARN_NULL($$ = createTreeNodeStmt(FOR_STMT));
                $$->child = $4;
                $4->sibling = $5; $5->sibling = $6; $6->sibling = $8;
            };
direction:     TO {
                WARN_NULL($$ = createTreeNodeStmt(DIRECTION));
            }
              | DOWNTO {
                  WARN_NULL($$ = createTreeNodeStmt(DIRECTION));
              }
;
case_stmt:     CASE expression OF case_expr_list  END {
                WARN_NULL($$ = createTreeNodeStmt(CASE_STMT));
                $$->child = $2;
                $2->sibling = $4;
            };
case_expr_list: case_expr_list  case_expr {
                    WARN_NULL($$ = createTreeNodeStmt(CASE_EXPR_LIST));
                    $$->child = $1;
                    $1->sibling = $2;
                }
                | case_expr {
                    WARN_NULL($$ = createTreeNodeStmt(CASE_EXPR_LIST));
                    $$->child = $1;
                }
;
case_expr:     const_value  COLON  stmt  SEMI {
                WARN_NULL($$ = createTreeNodeStmt(CASE_EXPR));
                $$->child = $1;
                $1->sibling = $3; $3->sibling = $4;
            }
              |  NAME  COLON  stmt  SEMI {
                  WARN_NULL($$ = createTreeNodeStmt(CASE_EXPR));
                $$->child = $3;
              }
;
goto_stmt: GOTO  INTEGER // just skipped
;

//////////////////////////////////////
//  expression part                ///
/////////////////////////////////////
expression_list: expression_list  COMMA  expression {
                    WARN_NULL($$ = createTreeNodeStmt(EXPRESSION_LIST));
                    $$->child = $1;
                    $1->sibling = $3;
                }
                | expression {
                    WARN_NULL($$ = createTreeNodeStmt(EXPRESSION_LIST));
                    $$->child = $1;
                };
expression: expression  GE  expr {
                WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",GE
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  GT  expr {
                WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",GT
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  LE  expr {
                WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",LE
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  LT  expr {
                WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",LT
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  EQUAL  expr {
                WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",EQUAL
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  UNEQUAL  expr {
                WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",UNEQUAL
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expr {
                $$ = $1;
            }
;
expr: expr  PLUS  term {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",PLUS
        $$->child = $1;
        $1->sibling = $3;
    }
    |  expr  MINUS  term {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",MINUS
        $$->child = $1;
        $1->sibling = $3;
    }
    |  expr  OR  term {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",OR
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term {
        $$ = $1;
    }
;
term: term  MUL  factor {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",MUL
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term  DIV  factor {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",DIV
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term  MOD  factor {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",MOD
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term  AND  factor {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",AND
        $$->child = $1;
        $1->sibling = $3;
    }
    |  factor {
        $$ = $1;
    }
;
factor: NAME {
        $$ = lookup($1->attr.symbolName)->treeNode;
    }
    |  NAME  LP  args_list  RP {
        TreeNode *p = lookup($1->attr.symbolName)->treeNode;
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //p->treeNode->kind.expKind,$1,0,p->treeNode->symbolType,p->treeNode->attr.size
        $$->child = $3;
    }
    |  SYS_FUNCT { //"abs", "chr", "odd", "ord", "pred", "sqr", "sqrt", "succ"
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //FUNCKIND,$1,0,INTEGER
    }
    |  SYS_FUNCT  LP  args_list  RP {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //FUNCKIND,$1,0,INTEGER
        $$->child = $3;
    }
    |  const_value {
        $$ = $1;
    }
    |  LP  expression  RP {
        $$ = $2;
    }
    |  NOT  factor {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",NOT
        $$->child = $2;
    }
    |  MINUS  factor {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",MINUS
        $$->child = $2;
    }
    |  NAME  LB  expression  RB {
    }
    |  NAME  DOT  NAME {
        WARN_NULL($$ = createTreeNodeExp(NULL_EXP)); //OPKIND,"",DOT
        memcpy($$->child,lookup($1->attr.symbolName),sizeof(TreeNode));
    }
;
args_list:     args_list  COMMA  expression {
                WARN_NULL($$ = createTreeNodeStmt(ARGS_LIST));
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression {
                WARN_NULL($$ = createTreeNodeStmt(ARGS_LIST));
                $$->child = $1;
            };

%%
