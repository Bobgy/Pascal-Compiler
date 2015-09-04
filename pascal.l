%{
#include "global.h"
#include "util.h"
#include "y.tab.h"
extern YYSTYPE yylval;
#ifdef __cplusplus
    #define YYINPUT yyinput
#else
    #define YYINPUT input
#endif

int isInteger(char *s) {
    int head = 0;
    if (s[0]=='+' || s[0]=='-') head = 1;
    int i;
    int n = strlen(s);
    for (i = head; i<n; ++i) {
        if (!isdigit(s[i])) return 0;
    }
    return 1;
}
int waitForFuncName = 0;

%}

dot         "."
program     "program"
semi        ";"
const       "const"
equal       "="
sys_con     "true"|"false"|"maxint"
type        "type"
lp          "("
rp          ")"
lb          "["
rb          "]"
dotdot      ".."
boolean     "boolean"
char        "char"
integer     "integer"
string      "string"
real        "real"
array       "array"
of          "of"
record      "record"
end         "end"
comma       ","
colon       ":"
assign      ":="
begin       "begin"
sys_proc    "write"|"writeln"
read        "read"
if          "if"
then        "then"
else        "else"
repeat      "repeat"
until       "until"
for         "for"
do          "do"
to          "to"
downto      "downto"
case        "case"
goto        "goto"
ge          ">="
gt          ">"
le          "<="
lt          "<"
unequal     "<>"
plus        "+"
minus       "-"
mul         "*"
mod         "%"
div         "/"
and         "and"
or          "or"
sys_funct   "abs"|"chr"|"odd"|"ord"|"pred"|"sqr"|"sqrt"|"succ"
var         "var"
function    "function"
procedure   "procedure"
while       "while"
not         "not"
label       "label"
name        [A-Za-z_][A-Za-z0-9_]*
const_int   [0-9]+
const_fp    [0-9]+"."[0-9]+

%%

"{" {
// brackets comment
    char c;
    while (1) {
        c = YYINPUT();
        if (c=='}') break;
    }
}
"//".*\n {
// one-line comment
}
"\'" {
// recognize word string first.
    char c;
    int cnt = 0;
    while (1) {
        c = YYINPUT();
        if (c=='\'') break;
        buf[cnt++] = c;
    }
    yylval = createTreeNodeConstant();
    yylval->symbolType = TYPE_STRING;
    buf[cnt]=0;
    yylval->attr.symbolName = strAllocCopy(buf);
    return STRING;
}

{dot}         {return DOT;}
{program}     {return PROGRAM;}
{semi}        {return SEMI;}
{const}       {return CONST;}
{equal}       {return EQUAL;}
{sys_con}     {return SYS_CON;}
{type}        {return TYPE;}
{lp}          {return LP;}
{rp}          {return RP;}
{lb}          {return LB;}
{rb}          {return RB;}
{dotdot}      {return DOTDOT;}
{string} {
    yylval = createTreeNodeStmt(SIMPLE_TYPE_DECL);
    yylval->symbolType = TYPE_STRING;
    return SYS_TYPE;
}
{integer} {
    yylval = createTreeNodeStmt(SIMPLE_TYPE_DECL);
    yylval->symbolType = TYPE_INTEGER;
    return SYS_TYPE;
}
{boolean} {
    yylval = createTreeNodeStmt(SIMPLE_TYPE_DECL);
    yylval->symbolType = TYPE_BOOLEAN;
    return SYS_TYPE;
}
{char} {
    yylval = createTreeNodeStmt(SIMPLE_TYPE_DECL);
    yylval->symbolType = TYPE_CHARACTER;
    return SYS_TYPE;
}
{real} {
    yylval = createTreeNodeStmt(SIMPLE_TYPE_DECL);
    yylval->symbolType = TYPE_REAL;
    return SYS_TYPE;
}
{array}       {return ARRAY;}
{of}          {return OF;}
{record}      {return RECORD;}
{end}         {return END;}
{comma}       {return COMMA;}
{colon}       {return COLON;}
{assign}      {return ASSIGN;}
{begin}       {return BEGIN_TOKEN;}
{sys_proc}    {
    yylval = createTreeNodeConstant();
    yylval->symbolType = TYPE_STRING;
    yylval->attr.symbolName = strAllocCopy(yytext);
    return SYS_PROC;
}
{read}        {return READ;}
{if}          {return IF;}
{then}        {return THEN;}
{else}        {return ELSE;}
{repeat}      {return REPEAT;}
{until}       {return UNTIL;}
{for}         {return FOR;}
{do}          {return DO;}
{to}          {return TO;}
{downto}      {return DOWNTO;}
{case}        {return CASE;}
{goto}        {return GOTO;}
{ge}          {return GE;}
{gt}          {return GT;}
{le}          {return LE;}
{lt}          {return LT;}
{unequal}     {return UNEQUAL;}
{plus}        {return PLUS;}
{minus}       {return MINUS;}
{mul}         {return MUL;}
{mod}         {return MOD;}
{div}         {return DIV;}
{and}         {return AND;}
{or}          {return OR;}
{sys_funct}   {return SYS_FUNCT;}
{var}         {return VAR;}
{function} {
    waitForFuncName = 1;
    return FUNCTION;
}
{procedure} {
    waitForFuncName = 1;
    return PROCEDURE;
}
{while}       {return WHILE;}
{not}         {return NOT;}
{label}       {return LABEL;}
{name} {
    yylval = createTreeNodeConstant();
    yylval->symbolType = TYPE_STRING;
    yylval->attr.symbolName = strAllocCopy(yytext);
    return NAME;
}
{const_int} {
    yylval = createTreeNodeConstant();
    yylval->symbolType = TYPE_INTEGER;
    sscanf(yytext, "%d", &yylval->attr.value.integer);
    return INTEGER;
}
{const_fp} {
    yylval = createTreeNodeConstant();
    yylval->symbolType = TYPE_REAL;
    sscanf(yytext, "%lf", &yylval->attr.value.real);
    return REAL;
}
.|\n {
    //Other
    //puts("catch");
}
%%

int yywrap(void) {
    return 1;
}
