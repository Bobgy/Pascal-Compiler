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
    $$ = createTreeNodeStmt(PROGRAM);
    syntaxTreeRoot = $$;
    $$->child = $1;
    $1->sibling = $2;
    if ($2->attr.assembly != NULL) {
        printf("%s\n", $2->attr.assembly);
    } else {
        printf("ERROR: NULL program\n");
    }
}
;
program_head: PROGRAM  NAME  SEMI { // just skipped
    $$ = createTreeNodeStmt(PROGRAM_HEAD);
}
;
routine: routine_head  routine_body {
    $$ = createTreeNodeStmt(ROUTINE);
    $$->child = $1;
    $1->sibling = $2;
    $$->attr.assembly = $1->attr.assembly; // TODO: add routine_body
}
;
sub_routine: routine_head  routine_body {
    $$ = createTreeNodeStmt(SUB_ROUTINE);
    $$->child = $1;
    $1->sibling = $2;
    $$->attr.assembly = $1->attr.assembly; // TODO: add routine_body
}
;

routine_head: label_part  const_part  type_part  var_part  routine_part {
    $$ = createTreeNodeStmt(ROUTINE_HEAD);
    $$->child = $1;
    $1->sibling = $2; $2->sibling = $3; $3->sibling = $4; $4->sibling = $5;
    $$->attr.assembly = asmCatSiblin($1);
}
;
label_part: { // just skipped
    $$ = createTreeNodeStmt(LABEL_PART);
}
;
const_part: CONST const_expr_list {
        $$ = createTreeNodeStmt(CONST_PART);
        $$->child = $2;
    }
    | {
        $$ = createTreeNodeStmt(CONST_PART);
    }
;
const_expr_list: const_expr_list  NAME  EQUAL  const_value  SEMI {
            $4->attr.symbolName = strAllocCopy($2->attr.symbolName);
            strcpy($4->attr.symbolName, $2->attr.symbolName);
            $$ = createTreeNodeStmt(CONST_EXPR_LIST);
            $$->child = $1;
            $1->sibling = $4;
            // add to symbol table
            char *idName = $2->attr.symbolName;
            insert(strAllocCat(path,idName),0,$4);
        }
        |  NAME  EQUAL  const_value  SEMI {
            $3->attr.symbolName = strAllocCopy($1->attr.symbolName);
            strcpy($3->attr.symbolName, $1->attr.symbolName);
            $$ = createTreeNodeStmt(CONST_EXPR_LIST);
            $$->child = $3;
            // add to symbol table
            char *idName = $1->attr.symbolName;
            insert(strAllocCat(path,idName),0,$3);
        }
;
const_value: INTEGER {
                $$ = createTreeNodeConstant();
                $$->symbolType = TYPE_INTEGER;
                $$->attr.value.integer = atoi($1->attr.symbolName);
            }
            |  REAL {
                $$ = createTreeNodeConstant();
                $$->symbolType = TYPE_REAL;
                $$->attr.value.real = atof($1->attr.symbolName);
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
                $$->child = $2;
            }
            | {
                $$ = createTreeNodeStmt(TYPE_PART);
            };
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
        $$->child = $1;
    }
    |  record_type_decl { // TODO-Bobgy
        $$ = createTreeNodeStmt(TYPE_DECL);
        $$->child = $1;
    };
simple_type_decl: //TODO cannot determine which type
    SYS_TYPE { // "boolean", "char", "integer", "real"
        $$ = yylval;
        // type is in $$->symbolType
    }
    |  NAME {
        $$ = lookup($1->attr.symbolName)->treeNode;
    }
    |  LP  name_list  RP
    |  const_value  DOTDOT  const_value {  // just need this to pass test
        $$ = createTreeNodeStmt(SIMPLE_TYPE_DECL);
        $$->attr.value.integer = $3->attr.value.integer;
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
        $$->child = $1;
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
        $$ = $3;
        $$->child = $1;
    }
    | NAME {
        $$ = $1;
    };
var_part: VAR  var_decl_list {
        $$ = createTreeNodeStmt(VAR_PART);
        $$->child = $2;
        $$->attr.assembly = $2->attr.assembly;
    }
    | {
        $$ = createTreeNodeStmt(VAR_PART);
    }
;
var_decl_list :
    var_decl_list  var_decl {
        $$ = createTreeNodeStmt(VAR_DECL_LIST);
        $$->child = $1;
        $1->sibling = $2;
        $$->attr.assembly = strAllocCat(
            $1->attr.assembly,
            $2->attr.assembly
        );
    }
    | var_decl {
        $$ = createTreeNodeStmt(VAR_DECL_LIST);
        $$->child = $1;
        $$->attr.assembly = $1->attr.assembly;
    };
var_decl:
    name_list  COLON  type_decl  SEMI {
        $$ = createTreeNodeStmt(VAR_DECL);
        $$->child = $1;
        $1->sibling = $3;
        char *type = asmParseType($3);
        int i = 0;
        for (TreeNode *p = $1; p != NULL; p = p->child, ++i) {
            char *name = p->attr.symbolName;
            if (isGlobal) {
                sprintf(buf, "@%s%s = %s\n", path, name, type);
            } else {
                sprintf(buf, "%%%s%s = alloca %s\n", path, name, type);
            }
            strList[i] = strAllocCopy(buf);
        }
        $$->attr.assembly = strCatList(i);
        while(~--i)free(strList[i]);
        for (TreeNode *p = $1; p != NULL; p = p->child) {
            insert(strAllocCat(path, p->attr.symbolName), 0, $3);
        }
    };
routine_part:
    routine_part  function_decl {
        $$ = $2;
        $$->child = $1;
    }
    |  routine_part  procedure_decl {
        $$ = $2;
        $$->child = $1;
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
        $$->child = $1;
        $1->sibling = $3;
        strParentPath(path);
        yyinfo("Leaving path:");
        yyinfo(path);

        // asm
        strList[0] = $1->attr.assembly;
        strList[1] = $3->attr.assembly;
        strList[2] = "}";
        $$->attr.assembly = strCatList(3);

        pop();
    };
function_head :
    FUNCTION  NAME  parameters  COLON  simple_type_decl {
        $$ = createTreeNodeStmt(FUNCTION_HEAD);
        $$->attr.symbolName = strAllocCat(path, $2->attr.symbolName);

        // function_head saved the name of function
        $$->child = $3;
        $3->sibling = $5;

        // asm
        strList[0] = "define ";
        strList[1] = asmParseType($5);
        strList[2] = " @";
        strList[3] = $$->attr.symbolName;
        strList[4] = "(";
        strList[5] = $3->attr.assembly;
        strList[6] = "){\n";
        strList[7] = top()->initList;
        $$->attr.assembly = strCatList(8);
    };
procedure_decl :
    procedure_head  SEMI  sub_routine  SEMI {
        $$ = createTreeNodeStmt(PROCEDURE_DECL);
        $$->child = $1;
        $1->sibling = $3;
        strParentPath(path);
        yyinfo("Leaving path:");
        yyinfo(path);

        //asm TODO
        strList[0] = $1->attr.assembly;
        strList[1] = $3->attr.assembly;
        strList[2] = "}";
        $$->attr.assembly = strCatList(3);

        pop();
    };
procedure_head :
    PROCEDURE NAME parameters {
        $$ = createTreeNodeStmt(PROCEDURE_HEAD);
        $$->attr.symbolName = strAllocCopy($2->attr.symbolName);
        // procedure_head saved the name of function
        $$->child = $3;

        // asm
        strList[0] = "define void @";
        strList[1] = $$->attr.symbolName;
        strList[2] = "(";
        strList[3] = $3->attr.assembly;
        strList[4] = "){\n";
        strList[5] = top()->initList;
        $$->attr.assembly = strCatList(6);
        //free(top()->initList);
    };
parameters:
    LP  para_decl_list  RP {
        $$ = createTreeNodeStmt(PARAMETERS);
        $$->child = $2;
        $$->attr.assembly = $2->attr.assembly;
    }
    |;
para_decl_list:
    para_decl_list  SEMI  para_type_list {
        $$ = createTreeNodeStmt(PARA_DECL_LIST);
        $$->child = $1;
        $1->sibling = $3;
        sprintf(buf, "%s, %s", $1->attr.assembly, $3->attr.assembly);
        $$->attr.assembly = strAllocCopy(buf);
        free($1->attr.assembly);
        free($3->attr.assembly);
    }
    | para_type_list {
        $$ = createTreeNodeStmt(PARA_DECL_LIST);
        $$->child = $1;
        $$->attr.assembly = $1->attr.assembly;
    };
para_type_list:
    var_para_list COLON  simple_type_decl {
        $$ = createTreeNodeStmt(PARA_TYPE_LIST);
        $$->child = $1;
        $1->sibling = $3;
        char *type = asmParseType($3);
        int i = 0, cnt;
        for (TreeNode *p = $1->child; p != NULL; p = p->child, ++i) {
            char *name = strAllocCat(path, p->attr.symbolName);
            if ($1->kind.stmtType == VAR_VAR_PARA_LIST) {
                if (i) {
                    sprintf(buf, ", %%%s %s", name, type);
                } else {
                    sprintf(buf, "%%%s %s", name, type);
                }
                strList[i] = strAllocCopy(buf);
            } else {
                cnt = ++top()->paramCount;
                if (i) {
                    sprintf(buf, ", %%%d %s", cnt, type);
                } else {
                    sprintf(buf, "%%%d %s", cnt, type);
                }
                strList[i] = strAllocCopy(buf);
                sprintf(
                    buf, "%%%s = alloca %s\nstore %s %%%d, %s* %%%s\n",
                    name, type, type, cnt, type, name
                );
                pushInitList(buf);
            }
            insert(name, 0, $3);
        }
        $$->attr.assembly = strCatList(i);
        while(~--i)free(strList[i]);
    };
var_para_list:
    VAR name_list { // pass by reference
        $$ = createTreeNodeStmt(VAR_VAR_PARA_LIST);
        $$->child = $2;
    };
    | name_list { // pass by value
        $$ = createTreeNodeStmt(VAR_PARA_LIST);
        $$->child = $1;
    };
routine_body: compound_stmt {
                $$ = createTreeNodeStmt(ROUTINE_BODY);
                $$->child = $1;
            }
;
compound_stmt: BEGIN_TOKEN  stmt_list  END {
                    $$ = createTreeNodeStmt(COMPOUND_STMT);
                    $$->child = $2;
                }
;
stmt_list:
    stmt_list  stmt  SEMI {
        $$ = createTreeNodeStmt(STMT_LIST);
        $$->child = $1;
        $1->sibling = $2;
    }
    |;
stmt:
    INTEGER  COLON non_label_stmt {
        $$ = createTreeNodeStmt(STMT);
        $$->child = $3;
    }
    |  non_label_stmt {
        $$ = createTreeNodeStmt(STMT);
        $$->child = $1;
    };
non_label_stmt:
    assign_stmt {
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
    };
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
                }
;
expression: expression  GE  expr {
                $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",GE
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  GT  expr {
                $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",GT
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  LE  expr {
                $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",LE
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  LT  expr {
                $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",LT
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  EQUAL  expr {
                $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",EQUAL
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expression  UNEQUAL  expr {
                $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",UNEQUAL
                $$->child = $1;
                $1->sibling = $3;
            }
            |  expr {
                $$ = $1;
            }
;
expr: expr  PLUS  term {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",PLUS
        $$->child = $1;
        $1->sibling = $3;
    }
    |  expr  MINUS  term {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",MINUS
        $$->child = $1;
        $1->sibling = $3;
    }
    |  expr  OR  term {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",OR
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term {
        $$ = $1;
    }
;
term: term  MUL  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",MUL
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term  DIV  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",DIV
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term  MOD  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",MOD
        $$->child = $1;
        $1->sibling = $3;
    }
    |  term  AND  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",AND
        $$->child = $1;
        $1->sibling = $3;
    }
    |  factor {
        $$ = $1;
    }
;
factor: NAME {
        char *name = $1->attr.symbolName, *pathName;
        SymbolNode *p = lookup(pathName = strAllocCat(path, name));
        if (p == NULL) p = lookup(name);
        if (p == NULL) yyerror("symbol not found");
        $$ = p->treeNode;
        free(pathName);
    }
    |  NAME  LP  args_list  RP {
        TreeNode *p = lookup($1->attr.symbolName)->treeNode;
        $$ = createTreeNodeExp(NULL_EXP); //p->treeNode->kind.expKind,$1,0,p->treeNode->symbolType,p->treeNode->attr.size
        $$->child = $3;
    }
    |  SYS_FUNCT { //"abs", "chr", "odd", "ord", "pred", "sqr", "sqrt", "succ"
        $$ = createTreeNodeExp(NULL_EXP); //FUNCKIND,$1,0,INTEGER
    }
    |  SYS_FUNCT  LP  args_list  RP {
        $$ = createTreeNodeExp(NULL_EXP); //FUNCKIND,$1,0,INTEGER
        $$->child = $3;
    }
    |  const_value {
        $$ = $1;
    }
    |  LP  expression  RP {
        $$ = $2;
    }
    |  NOT  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",NOT
        $$->child = $2;
    }
    |  MINUS  factor {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",MINUS
        $$->child = $2;
    }
    |  NAME  LB  expression  RB {
    }
    |  NAME  DOT  NAME {
        $$ = createTreeNodeExp(NULL_EXP); //OPKIND,"",DOT
        memcpy($$->child,lookup($1->attr.symbolName),sizeof(TreeNode));
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
            }
;

%%
