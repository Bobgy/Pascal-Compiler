%{
#include "global.h"
#include "util.h"
%}

%token NAME

// OP
%token DOT EQUAL LB RB LP RP ASSIGN GE GT LE LT UNEQUAL
%token PLUS MINUS MUL MOD DIV OR AND NOT

// 保留字
%token PROGRAM TYPE OF RECORD CONST BEGIN END FUNCTION PROCEDURE ARRAY
%token IF THEN ELSE REPEAT UNTIL FOR DO TO DOWNTO CASE GOTO WHILE LABEL VAR

%token COLON COMMA SEMI DOTDOT

%token SYS_PROC SYS_TYPE READ // see doc

%%
program: program_head  routine  DOT {
    $$ = createTreeNodeStmt(PROGRAM);
    syntaxTreeRoot = $$;
    $$->child = $1;
    $1->sibling = $2;
}
;
program_head: PROGRAM  NAME  SEMI // just skipped
;
routine: routine_head  routine_body {
    $$ = createTreeNodeStmt(ROUTINE);
    $$->child = $1;
    $1->sibling = $2;
}
;
sub_routine: routine_head  routine_body {
    $$ = createTreeNodeStmt(SUB_ROUTINE);
    $$->child = $1;
    $1->sibling = $2;
}
;

routine_head: label_part  const_part  type_part  var_part  routine_part {
    $$ = createTreeNodeStmt(ROUTINE_HEAD);
    $$->child = $1;
    $1->sibling = $2; $2->sibling = $3; $3->sibling = $4; $4->sibling = $5;
}
;
label_part: // just skipped
;
const_part: CONST const_expr_list {
    $$ = createTreeNodeStmt(CONST_PART);
    $$->child = $2;
}
|;
const_expr_list: const_expr_list  NAME  EQUAL  const_value  SEMI {
            $4->attr.symbolName = (char*)malloc(sizeof($2));
            strcpy(p->attr.symbolName, $2);
            $$ = createTreeNodeStmt(CONST_EXPR_LIST);
            $$->child = $1;
            $1->sibling = $4;
        }
        |  NAME  EQUAL  const_value  SEMI {
            $3->attr.symbolName = (char*)malloc(sizeof($1));
            strcpy(p->attr.symbolName, $1);
            $$ = createTreeNodeStmt(CONST_EXPR_LIST);
            $$->child = $3;
        }
;
const_value: INTEGER {
                $$ = createTreeNodeConstant();
                $$->type = INTEGER;
                $$->attr.value.integer = atoi($1);
            }
            |  REAL {
                $$ = createTreeNodeConstant();
                $$->type = REAL;
                $$->attr.value.real = atof($1);
            }
            |  CHAR {
                $$ = createTreeNodeConstant();
                $$->type = CHARACTER;
                $$->attr.value.character = $1[0];
            }
            |  STRING {
                $$ = createTreeNodeConstant();
                $$->type = STRING;
                $$->attr.value.string = (char*)malloc(sizeof($1));
                strcpy($$->attr.value.string, $1);
            }
            |  SYS_CON {
                $$ = createTreeNodeConstant();
                if (strcmp($1,"false")==0) {
                    $$->type = BOOLEAN;
                    $$-attr.value.boolean = 0;
                } else if (strcmp($1,"true")==0) {
                    $$->type = BOOLEAN;
                    $$-attr.value.boolean = 1;
                } else if (strcmp($1,"maxint")==0) {
                    $$->type = INTEGER;
                    $$-attr.value.integer = INT_MAX;
                } else {
                    $$->type = INTEGER;
                    $$-attr.value.integer = 0;
                }
            };

type_part: TYPE type_decl_list {
                $$ = createTreeNodeStmt(TYPE_PART);
                $$->child = $2;
            }
|;
type_decl_list: type_decl_list  type_definition {
                    $$ = createTreeNodeStmt(TYPE_DECL_LIST);
                    $$->child = $1;
                    $1->sibling = $2;
                }
                | type_definition {
                    $$ = createTreeNodeStmt(TYPE_DECL_LIST);
                    $$->child = $1;
                }
;
type_definition: NAME  EQUAL  type_decl  SEMI {
                    $$ = createTreeNodeStmt(TYPE_DEFINITION);
                    $$->attr.symbolName = (char*)malloc(sizeof($1));
                    strcpy($$->attr.symbolName, $1);
                    // store typename in type_definition node
                }
;
type_decl:  simple_type_decl {
                $$ = createTreeNodeStmt(TYPE_DECL);
                $$->child = $1;
            }
            |  array_type_decl {
                $$ = createTreeNodeStmt(TYPE_DECL);
                $$->child = $1;
            }
            |  record_type_decl {
                $$ = createTreeNodeStmt(TYPE_DECL);
                $$->child = $1;
            }
;
simple_type_decl: SYS_TYPE // "boolean", "char", "integer", "real"
                {
                    $$ = createTreeNodeStmt(SIMPLE_TYPE_DECL);
                    $$->attr.symbolName = (char*)malloc(sizeof($1));
                    strcpy($$->attr.symbolName, $1);
                    // store type name in node
                }
                |  NAME
                |  LP  name_list  RP
                |  const_value  DOTDOT  const_value {  // just need this to pass test
                    $$ = createTreeNodeStmt(SIMPLE_TYPE_DECL);
                    $$->child = $1;
                    $1->sibling = $3;
                }
                |  MINUS  const_value  DOTDOT  const_value
                |  MINUS  const_value  DOTDOT  MINUS  const_value
                |  NAME  DOTDOT  NAME
;
array_type_decl: ARRAY  LB  simple_type_decl  RB  OF  type_decl {
                    $$ = createTreeNodeStmt(ARRAY_TYPE_DECL);
                    $$->child = $1;
                    $1->sibling = $2;
                }
;
record_type_decl: RECORD  field_decl_list  END {
                    $$ = createTreeNodeStmt(RECORD_TYPE_DECL);
                    $$->child = $2;
                }
;

field_decl_list: field_decl_list  field_decl {
                    $$ = createTreeNodeStmt(FIELD_DECL_LIST);
                    $$->child = $1;
                    $1->sibling = $2;
                }
                | field_decl {
                    $$ = createTreeNodeStmt(FIELD_DECL_LIST);
                    $$->child = $1;
                }
;
field_decl: name_list  COLON  type_decl  SEMI {
                $$ = createTreeNodeStmt(FIELD_DECL);
                $$->child = $1;
                $1->sibling = $3;
            }
;
name_list: name_list  COMMA  NAME {
            $$ = createTreeNodeStmt(NAME_LIST);
            $$->child = $1;
        }
        |  NAME {
            $$ = createTreeNodeStmt(NAME_LIST);
        }
;
var_part: VAR  var_decl_list {
    $$ = createTreeNodeStmt(VAR_PART);
    $$->child = $2;
}
|;
var_decl_list : var_decl_list  var_decl {
                    $$ = createTreeNodeStmt(VAR_DECL_LIST);
                    $$->child = $1;
                    $1->sibling = $2;
                 }
                 |  var_decl {
                     $$ = createTreeNodeStmt(VAR_DECL_LIST);
                     $$->child = $1;
                 }
;
var_decl :  name_list  COLON  type_decl  SEMI {
                $$ = createTreeNodeStmt(VAR_DECL);
                $$->child = $1;
                $1->sibling = $3;
            }
;
routine_part: routine_part  function_decl {
                $$ = createTreeNodeStmt(ROUTINE_PART);
                $$->child = $1;
                $1->sibling = $2;
            }
        |  routine_part  procedure_decl {
            $$ = createTreeNodeStmt(ROUTINE_PART);
            $$->child = $1;
            $1->sibling = $2;
        }
        |  function_decl {
            $$ = createTreeNodeStmt(ROUTINE_PART);
            $$->child = $1;
        }
        |  procedure_decl {
            $$ = createTreeNodeStmt(ROUTINE_PART);
            $$->child = $1;
        }
        | ;
function_decl : function_head  SEMI  sub_routine  SEMI {
                    $$ = createTreeNodeStmt(FUNCTION_DECL);
                    $$->child = $1;
                    $1->sibling = $3;
                };
function_head :  FUNCTION  NAME  parameters  COLON  simple_type_decl {
                    $$ = createTreeNodeStmt(FUNCTION_HEAD);
                    $$->attr.symbolName = (char*)malloc(sizeof($2));
                    strcpy($$->attr.symbolName, $2);
                    // function_head saved the name of function
                    $$->child = $3;
                    $3->sibling = $5;
                };
procedure_decl :  procedure_head  SEMI  sub_routine  SEMI
                    $$ = createTreeNodeStmt(PROCEDURE_DECL);
                    $$->child = $1;
                    $1->sibling = $3;
                };
procedure_head :  PROCEDURE NAME parameters
                    $$ = createTreeNodeStmt(PROCEDURE_HEAD);
                    $$->attr.symbolName = (char*)malloc(sizeof($2));
                    strcpy($$->attr.symbolName, $2);
                    // procedure_head saved the name of function
                    $$->child = $3;
                };
parameters: LP  para_decl_list  RP {
            $$ = createTreeNodeStmt(PARAMETERS);
            $$->child = $2;
}
|;
para_decl_list: para_decl_list  SEMI  para_type_list {
                    $$ = createTreeNodeStmt(PARA_DECL_LIST);
                    $$->child = $1;
                    $1->sibling = $3;
                }
                | para_type_list {
                    $$ = createTreeNodeStmt(PARA_DECL_LIST);
                    $$->child = $1;
                };
para_type_list: var_para_list COLON  simple_type_decl {
                    $$ = createTreeNodeStmt(PARA_TYPE_LIST);
                    $$->child = $1;
                    $1->sibling = $3;
                }
;
var_para_list: VAR name_list { // pass by reference
                    $$ = createTreeNodeStmt(VAR_PARA_LIST);
                    $$->child = $2;
                };
                | name_list { // pass by value
                    $$ = createTreeNodeStmt(VAR_PARA_LIST);
                    $$->child = $1;
                }
;
routine_body: compound_stmt {
                $$ = createTreeNodeStmt(ROUTINE_BODY);
                $$->child = $1;
            }
;
compound_stmt: BEGIN  stmt_list  END {
                    $$ = createTreeNodeStmt(COMPOUND_STMT);
                    $$->child = $2;
                }
;
stmt_list: stmt_list  stmt  SEMI {
                $$ = createTreeNodeStmt(STMT_LIST);
                $$->child = $1;
                $1->sibling = $2;
            }
|;
stmt: INTEGER  COLON non_label_stmt {
        $$ = createTreeNodeStmt(STMT);
        $$->child = $3;
    }
    |  non_label_stmt {
        $$ = createTreeNodeStmt(STMT);
        $$->child = $1;
    }
;
non_label_stmt: assign_stmt {
                    $$ = createTreeNodeStmt(NON_LABEL_STMT);
                    $$->child = $1;
                }
                | proc_stmt {
                    $$ = createTreeNodeStmt(NON_LABEL_STMT);
                    $$->child = $1;
                }
                | compound_stmt {
                    $$ = createTreeNodeStmt(NON_LABEL_STMT);
                    $$->child = $1;
                }
                | if_stmt {
                    $$ = createTreeNodeStmt(NON_LABEL_STMT);
                    $$->child = $1;
                }
                | repeat_stmt {
                    $$ = createTreeNodeStmt(NON_LABEL_STMT);
                    $$->child = $1;
                }
                | while_stmt {
                    $$ = createTreeNodeStmt(NON_LABEL_STMT);
                    $$->child = $1;
                }
                | for_stmt {
                    $$ = createTreeNodeStmt(NON_LABEL_STMT);
                    $$->child = $1;
                }
                | case_stmt {
                    $$ = createTreeNodeStmt(NON_LABEL_STMT);
                    $$->child = $1;
                }
                | goto_stmt {
                    $$ = createTreeNodeStmt(NON_LABEL_STMT);
                    $$->child = $1;
                }
;
assign_stmt: NAME  ASSIGN  expression {
                $$ = createTreeNodeStmt(ASSIGN_STMT);
                $$->child = $3;
            }
           | NAME LB expression RB ASSIGN expression {
                $$ = createTreeNodeStmt(ASSIGN_STMT);
                $$->child = $3;
                $$->sibling = $5;
            }
           | NAME  DOT  NAME  ASSIGN  expression {
                   $$ = createTreeNodeStmt(ASSIGN_STMT);
                $$->child = $5;
           }
;
proc_stmt:     NAME {
                $$ = createTreeNodeStmt(PROC_STMT);
            }
              |  NAME  LP  args_list  RP {
                $$ = createTreeNodeStmt(PROC_STMT);
                $$->child = $3;
            }
             |  SYS_PROC { // just skipped
            }
              |  SYS_PROC  LP  expression_list  RP { // only need to consider writeln()
                $$ = createTreeNodeStmt(PROC_STMT);
                $$->child = $3;
            }
              |  READ  LP  factor  RP {
                $$ = createTreeNodeStmt(PROC_STMT);
                $$->child = $3;
            }
;
if_stmt: IF  expression  THEN  stmt  else_clause {
            $$ = createTreeNodeStmt(IF_STMT);
            $$->child = $2;
            $2->sibling = $4; $4->sibling = $5;
        };
else_clause: ELSE stmt {
                $$ = createTreeNodeStmt(ELSE_CALUSE);
                $$->child = $2;
            }
|;
repeat_stmt: REPEAT  stmt_list  UNTIL  expression {
                $$ = createTreeNodeStmt(REPEAT_STMT);
                $$->child = $2;
                $2->sibling = $4;
            };
while_stmt: WHILE  expression  DO stmt {
                $$ = createTreeNodeStmt(WHILE_STMT);
                $$->child = $2;
            };
for_stmt:     FOR  NAME  ASSIGN  expression  direction  expression  DO stmt {
                $$ = createTreeNodeStmt(FOR_STMT);
                $$->child = $4;
                $4->sibling = $5; $5->sibling = $6; $6->sibling = $8;
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
                $$->child = $2;
                $2->sibling = $4;
            };
case_expr_list: case_expr_list  case_expr {
                    $$ = createTreeNodeStmt(CASE_EXPR_LIST);
                    $$->child = $1;
                    $1->sibling = $2;
                }
                | case_expr {
                    $$ = createTreeNodeStmt(CASE_EXPR_LIST);
                    $$->child = $1;
                }
;
case_expr:     const_value  COLON  stmt  SEMI {
                $$ = createTreeNodeStmt(CASE_EXPR);
                $$->child = $1;
                $1->sibling = $3; $3->sibling = $4;
            }
              |  NAME  COLON  stmt  SEMI {
                  $$ = createTreeNodeStmt(CASE_EXPR);
                $$->child = $3;
              }
;
goto_stmt: GOTO  INTEGER // just skipped
;

//////////////////////////////////////
//  expression part                ///
/////////////////////////////////////
expression_list: expression_list  COMMA  expression {
                    $$ = createTreeNodeStmt(EXPRESSION_LIST);
                    $$->child = $1;
                    $1->sibling = $3;
                }
                | expression {
                    $$ = createTreeNodeStmt(EXPRESSION_LIST);
                    $$->child = $1;
                };
expression: expression  GE  expr {
                $$ = createTreeNodeExp(OPKIND,"",GE);
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  GT  expr {
                $$ = createTreeNodeExp(OPKIND,"",GT);
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  LE  expr {
                $$ = createTreeNodeExp(OPKIND,"",LE);
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  LT  expr {
                $$ = createTreeNodeExp(OPKIND,"",LT);
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  EQUAL  expr {
                $$ = createTreeNodeExp(OPKIND,"",EQUAL);
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  UNEQUAL  expr {
                $$ = createTreeNodeExp(OPKIND,"",UNEQUAL);
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expr {
                $$ = $1;
            }
;
expr: expr  PLUS  term {
        $$ = createTreeNodeExp(OPKIND,"",PLUS);
        $$->child = $1;
        $1->sibling = $3;
    }
    |  expr  MINUS  term {
        $$ = createTreeNodeExp(OPKIND,"",MINUS);
        $$->child = $1;
        $1->sibling = $3;
    }
    |  expr  OR  term {
        $$ = createTreeNodeExp(OPKIND,"",OR);
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term {
        $$ = $1;
    }
;
term: term  MUL  factor {
        $$ = createTreeNodeExp(OPKIND,"",MUL);
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term  DIV  factor {
        $$ = createTreeNodeExp(OPKIND,"",DIV);
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term  MOD  factor {
        $$ = createTreeNodeExp(OPKIND,"",MOD);
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term  AND  factor {
        $$ = createTreeNodeExp(OPKIND,"",AND);
        $$->child = $1;
        $1->sibling = $3;
    }
    |  factor {
        $$ = $1;
    }
;
factor: NAME {
        $$ = lookup($1)->treeNode;
    }
    |  NAME  LP  args_list  RP {
        TreeNode *p = lookup($1);
        $$ = createTreeNodeExp(p->treeNode->kind.expKind,$1,0,p->treeNode->symbolType,p->treeNode->attr.size);
        $$->child = $3;
    }
    |  SYS_FUNCT { //"abs", "chr", "odd", "ord", "pred", "sqr", "sqrt", "succ"
        $$ = createTreeNodeExp(FUNCKIND,$1,0,INTEGER);
    }
    |  SYS_FUNCT  LP  args_list  RP {
        $$ = createTreeNodeExp(FUNCKIND,$1,0,INTEGER);
        $$->child = $3;
    }
    |  const_value {
        $$ = $1;
    }
    |  LP  expression  RP {
        $$ = $2;
    }
    |  NOT  factor {
        $$ = createTreeNodeExp(OPKIND,"",NOT);
        $$->child = $2;
    }
    |  MINUS  factor {
        $$ = createTreeNodeExp(OPKIND,"",MINUS);
        $$->child = $2;
    }
    |  NAME  LB  expression  RB {
    }
    |  NAME  DOT  NAME {
        $$ = createTreeNodeExp(OPKIND,"",DOT);
        memcpy($$->child,lookup($1),sizeof(TreeNode));
    }
;
args_list:     args_list  COMMA  expression {
                $$ = createTreeNodeStmt(ARGS_LIST);
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression {
                $$ = createTreeNodeStmt(ARGS_LIST);
                $$->child = $1;
            };

%%
