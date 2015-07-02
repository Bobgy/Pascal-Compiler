%{
#include "global.h"
#include "util.h"
%}

%union {
	TreeNode *syntaxTree;
}

%type <syntaxTree> program program_head routine
%type <syntaxTree> expression expr factor term  // 常数名 类型 函数名 变量名

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
	$$ = createTreeNodeStmt("program");
	syntaxTreeRoot = $$;
	$1 = createTreeNodeStmt("program_head");
	$2 = createTreeNodeStmt("routine");
	$$->child = $1;
	$1->sibling = $2;
}
;
program_head: PROGRAM  NAME  SEMI
;
routine: routine_head  routine_body {
	$1 = createTreeNodeStmt("routine_head");
	$2 = createTreeNodeStmt("routine_body");
	$$->child = $1;
	$1->sibling = $2;
}
;
sub_routine: routine_head  routine_body {
	$1 = createTreeNodeStmt("routine_head");
	$2 = createTreeNodeStmt("routine_body");
	$$->child = $1;
	$1->sibling = $2;
}
;

routine_head: label_part  const_part  type_part  var_part  routine_part {
	$1 = createTreeNodeStmt("label_part");
	$2 = createTreeNodeStmt("const_part");
	$3 = createTreeNodeStmt("type_part");
	$4 = createTreeNodeStmt("var_part");
	$5 = createTreeNodeStmt("routine_part");
	$$->child = $1;
	$1->sibling = $2; $2->sibling = $3; $3->sibling = $4; $4->sibling = $5;
}
;
label_part: 
;
const_part: CONST const_expr_list {
	$2 = createTreeNodeStmt("const_expr_list");
	$$->child = $2;
}
|;
const_expr_list: const_expr_list  NAME  EQUAL  const_value  SEMI {
			$1 = createTreeNodeStmt("const_expr_list");
			$4 = createTreeNodeConstant($2);
			$$->child = $1;
			$1->sibling = $4;
		}
		|  NAME  EQUAL  const_value  SEMI {
			$3 = createTreeNodeConstant($1);
			$$->child = $3;
		}
;
const_value: INTEGER {
				$$->type = Integer;
				$$->attr.value.integer = atoi($1);
			}
			|  REAL {
				$$->type = Real;
				$$->attr.value.real = atof($1);
			}
			|  CHAR {
				$$->type = Character;
				$$->attr.value.character = $1[0];
			}  
			|  STRING {
				$$->type = String;
				strcpy($$->attr.value.string, $1);
			}
			|  SYS_CON {
				if (strcmp($1,"false")==0) {
					$$->type = Boolean;
					$$-attr.value.boolean = 0;
				} else if (strcmp($1,"true")==0) {
					$$->type = Boolean;
					$$-attr.value.boolean = 1;
				} else if (strcmp($1,"maxint")==0) {
					$$->type = Integer;
					$$-attr.value.integer = INT_MAX;
				} else {
					$$->type = Integer;
					$$-attr.value.integer = 0;
				}
			};

type_part: TYPE type_decl_list  
|;
type_decl_list: type_decl_list  type_definition  |  type_definition
;
type_definition: NAME  EQUAL  type_decl  SEMI
;
type_decl: simple_type_decl  |  array_type_decl  |  record_type_decl
;
simple_type_decl: SYS_TYPE  |  NAME  |  LP  name_list  RP  
		|  const_value  DOTDOT  const_value  
		|  MINUS  const_value  DOTDOT  const_value
		|  MINUS  const_value  DOTDOT  MINUS  const_value
		|  NAME  DOTDOT  NAME
;
array_type_decl: ARRAY  LB  simple_type_decl  RB  OF  type_decl
;
record_type_decl: RECORD  field_decl_list  END
;

field_decl_list: field_decl_list  field_decl  |  field_decl
;
field_decl: name_list  COLON  type_decl  SEMI
;
name_list: name_list  COMMA  NAME  
		|  NAME
;
var_part: VAR  var_decl_list {
	$2 = createTreeNodeStmt("var_decl_list");
	$$->child = $2;
}
|;
var_decl_list : var_decl_list  var_decl {
					$1 = createTreeNodeStmt("var_decl_list");
			  		$2 = createTreeNodeStmt("var_decl");
					$$->child = $1;
					$1->sibling = $2;
			 	}
			 	|  var_decl {
			 		$1 = createTreeNodeStmt("var_decl");
			 		$$->child = $1;
			 	}
;
var_decl :  name_list  COLON  type_decl  SEMI {
				$1 = createTreeNodeStmt("name_list");
				$3 = createTreeNodeStmt("type_decl");
				$$->child = $1;
				$1->sibling = $3;
			}
;
routine_part: routine_part  function_decl {
				$1 = createTreeNodeStmt("routine_part");
				$2 = createTreeNodeStmt("function_decl");
				$$->child = $1;
				$1->sibling = $2;
			}
		|  routine_part  procedure_decl {
			$1 = createTreeNodeStmt("routine_part");
			$2 = createTreeNodeStmt("procedure_decl");
			$$->child = $1;
			$1->sibling = $2;
		}
		|  function_decl {
			$1 = createTreeNodeStmt("function_decl");
			$$->child = $1;
		}
		|  procedure_decl {
			$1 = createTreeNodeStmt("procedure_decl");
			$$->child = $1;
		}
		| ;
function_decl : function_head  SEMI  sub_routine  SEMI
;
function_head :  FUNCTION  NAME  parameters  COLON  simple_type_decl 
;
procedure_decl :  procedure_head  SEMI  sub_routine  SEMI
;
procedure_head :  PROCEDURE NAME parameters 
;
parameters: LP  para_decl_list  RP  | 
;
para_decl_list: para_decl_list  SEMI  para_type_list | para_type_list
;
para_type_list: var_para_list COLON  simple_type_decl  
		|  val_para_list  COLON  simple_type_decl
;
var_para_list: VAR  name_list
;
val_para_list: name_list
;
routine_body: compound_stmt
;
compound_stmt: BEGIN  stmt_list  END
;
stmt_list: stmt_list  stmt  SEMI  |  
;
stmt: INTEGER  COLON non_label_stmt  
	|  non_label_stmt
;
non_label_stmt: assign_stmt | proc_stmt | compound_stmt | if_stmt | repeat_stmt | while_stmt 
| for_stmt | case_stmt | goto_stmt
;
assign_stmt: NAME  ASSIGN  expression
           | NAME LB expression RB ASSIGN expression
           | NAME  DOT  NAME  ASSIGN  expression
;
proc_stmt: NAME
          |  NAME  LP  args_list  RP
          |  SYS_PROC
          |  SYS_PROC  LP  expression_list  RP
          |  READ  LP  factor  RP
;
if_stmt: IF  expression  THEN  stmt  else_clause
;
else_clause: ELSE stmt | 
;
repeat_stmt: REPEAT  stmt_list  UNTIL  expression
;
while_stmt: WHILE  expression  DO stmt
;
for_stmt: FOR  NAME  ASSIGN  expression  direction  expression  DO stmt
;
direction: TO | DOWNTO
;
case_stmt: CASE expression OF case_expr_list  END
;
case_expr_list: case_expr_list  case_expr  |  case_expr
;
case_expr: const_value  COLON  stmt  SEMI
          |  NAME  COLON  stmt  SEMI
;
goto_stmt: GOTO  INTEGER
;
expression_list: expression_list  COMMA  expression  |  expression
;
expression: expression  GE  expr  
		|  expression  GT  expr 
		|  expression  LE  expr
		|  expression  LT  expr  
		|  expression  EQUAL  expr  
		|  expression  UNEQUAL  expr  
		|  expr
;
expr: expr  PLUS  term  |  expr  MINUS  term  |  expr  OR  term  |  term
;
term: term  MUL  factor  
	|  term  DIV  factor  
	|  term  MOD  factor 
	|  term  AND  factor  
	|  factor
 ;
factor: NAME  
	|  NAME  LP  args_list  RP  
	|  SYS_FUNCT
	|  SYS_FUNCT  LP  args_list  RP  
	|  const_value  
	|  LP  expression  RP 
	|  NOT  factor  
	|  MINUS  factor  
	|  NAME  LB  expression  RB
	|  NAME  DOT  NAME
;
args_list: args_list  COMMA  expression  {

	}
	|  expression {
		
	}
}
;

%%

int main()
{
	return yyparse();
}

