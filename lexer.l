%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
%}

%option noyywrap

%%
"if"       {return IF; }
"int"      {return INT;}
[a-zA-Z_][a-zA-Z0-9_]* {yylval.str = strdup(yytext); return ID; }
[0-9]+     {yylval.num = atoi(yytext); return NUM; }
"+"    	   {return PLUS; }
"-"	   {return MINUS; }
"*"	   {return MUL; }
"/"	   {return DIV; }
"="	   {return ASSIGN; }
";"	   {return SEMI; }
"("	   {return LPAREN; }
")"	   {return RPAREN; }
"{"	   {return LBRACE; }
"}"	   {return RBRACE; }
[ \t\n]+   {}
.	   {printf("Can not understand symbol : %s\n", yytext); }
%%
