/* Yacc / Bison hl test file.
 * It won't compile :-) Sure !
 */

%{

#include <iostream>
using namespace std;

extern KateParser *parser;

%}

%locations

%union { 
   int int_val;
   double double_val;
   bool bool_val;
   char *string_val;
   char *ident_val;
   struct var *v;
   void *ptr;
}

%token <int_val>      TOK_NOT_EQUAL  "!="
%token <int_val>      TOK_LESSER_E   "<="
%token <int_val>      TOK_GREATER_E  ">="
%token <int_val>      TOK_EQUAL_2    "=="

%type <int_val>       type type_proc

%%

prog:                 KW_PROGRAM ident { parser->start($2); } prog_beg_glob_decl instructions { parser->endproc(0); } dev_procedures KW_ENDP ;

number:               integer_number
                      | TOK_DOUBLE
                      {
                         $$ = new var;
                         $$->type = KW_REEL;
                         $$->cl = var::LITTERAL;
                         $$->real = $<int_val>1;
                      };

%%

#include <stdio.h>

int main(void)
{
  puts("Hello, World!");
  return 0;
}
