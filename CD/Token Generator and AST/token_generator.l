%{
    #include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include<ctype.h>
    #include"y.tab.h"
    extern YYSTYPE yylval;

    typedef struct node
    {
        char id_name[20];
        char id_type[20];
        int scope;
        int val_int;
        int storage_req;
        float val_float;
        char val_char;
        int line_no[100];
        int no_of_lines;
        struct node *link;
        int has_been_declared;
    }node;
    node *head = NULL;
    
    char value_of_char = 'a';
    int scope = 0;
    int line_no = 1;
    char prev_type[20];
    int prev_line;
    int is_it_arit_exp = 0;
    int make_scope_increase = 0;
    int line_of_error;
    int line_of_declaration = 0;
    int undefined_var_in_arit = 0;
    int multiple_declarations = 0;
    int this_var_is_being_declared = 0;
    int scope_decrease = 0;

    int is_var_present = 0;

    FILE *f_tokens;

    //AST
    typedef struct AST 
    {
        enum 
        {   
            main_func, arit_expression, rel_expression,
            assign_expression, declaration,
            for_loop, do_while_loop, if_cond,
            jump_stat, comp_stat, print_stat, 
            var, str_cons, float_cons, int_cons, char_cons
        } tag;
        union 
        {   
            struct
            {
                struct AST* body;
            } main_body;
            
            struct 
            { 
                char oper[3];
                struct AST* left;
                struct AST* right; 
            } arit;

            struct 
            { 
                char oper[3];
                struct AST* left;
                struct AST* right; 
            } rel;

            struct 
            {
                char oper[3];
                struct AST* var;
                struct AST* assigned_val;
            } assign;

            struct 
            {
                char type[20];
                struct AST* list[10];
                int count_no_decl;
            } decl;

            struct 
            { 
                struct AST* for_init;
                struct AST* for_cond;
                struct AST* for_upd;
                struct AST* for_body;
            } for_loop;

            struct
            { 
                struct AST* dowhile_exp;
                struct AST* dowhile_body;
            } dowhile;

            struct 
            { 
                struct AST* if_expr;
                struct AST* if_body; 
            } if_cond;

            struct
            {
                struct AST* val;
                char jump_stat_type[10];
            } jump_st;

            struct 
            {
                struct AST* stat[100];
                int stat_count;
            } comp_st;

            struct 
            {
                char oper[3];
                struct AST* output;
            } print_st;

            struct
            {
                char name[20];
            } var;

            struct 
            {
                char val[20];
            } str_val;

            struct 
            {
                float val;
            } float_val;

            struct
            {
                int val;
            } int_val;

            struct
            {
                char val;
            } char_val;

        } op;
    } ast;
    ast *head_ast = NULL;

    typedef struct compound_stat_stack
    {
        ast* comp_stat;
        struct compound_stat_stack* next;
    } css;
    css *topc = NULL;

    typedef struct value_and_arit_stack
    {
        ast* expr;
        struct value_and_arit_stack* next;
    } vas;
    vas *topv = NULL;

    int no_of_var_decl = 0;
    int value_added_to_expr = 0;
%}

digit [0-9]
alpha [a-zA-Z_]
id {alpha}({alpha}|{digit})*
%%
int[ ]main { fprintf(f_tokens,"<KEYW, 'int', %d>\n",line_no); fprintf(f_tokens,"<KEYW, 'main', %d>\n",line_no); return PRO_BEG;}

([ ]*|(\n\t)*|(\n)*|(\t)*)*\/\/.* 
([ ]*|(\n\t)*|(\n)*|(\t)*)*\/\*(.*\n)*.*\*\/ 

int|char|float|void { fprintf(f_tokens,"<KEYW, '%s', %d>\n",yytext,line_no); line_of_declaration = line_no; this_var_is_being_declared = 1; strcpy(prev_type,yytext); return TYPE_SPEC;}
for { fprintf(f_tokens,"<KEYW, 'for', %d>\n",line_no); return FOR;}
do { fprintf(f_tokens,"<KEYW, 'do', %d>\n",line_no); return DO;}
while { fprintf(f_tokens,"<KEYW, 'while', %d>\n",line_no); return WHILE;}
if { fprintf(f_tokens,"<KEYW, 'if', %d>\n",line_no); return IF;}
break { fprintf(f_tokens,"<KEYW, 'break', %d>\n",line_no); return BREAK;}
continue { fprintf(f_tokens,"<KEYW, 'continue', %d>\n",line_no); return CONTINUE;}
return { fprintf(f_tokens,"<KEYW, 'return', %d>\n",line_no); return RETURN;}
cout { fprintf(f_tokens,"<KEYW, 'cout', %d>\n",line_no); return COUT;}

\(|\{ { scope++; fprintf(f_tokens,"<SEP, '%s', %d>\n",yytext,line_no); return yytext[0];}
\)|\} { scope_decrease = 1; fprintf(f_tokens,"<SEP, '%s', %d>\n",yytext,line_no); return yytext[0];}
\;|\, { fprintf(f_tokens,"<SEP, '%s', %d>\n",yytext,line_no); return yytext[0];}
\= { fprintf(f_tokens,"<ASSIGN, '=', %d>\n",line_no); return yytext[0];}
\<\< { fprintf(f_tokens,"<REDIR, '%s', %d>\n",yytext,line_no); return REDIR_OPER;}
\+|\*|\-|\/ { fprintf(f_tokens,"<AROP, '%s', %d>\n",yytext,line_no); return yytext[0];}

\< { fprintf(f_tokens,"<RELOP, '%s', %d>\n",yytext,line_no); return LT;}
\> { fprintf(f_tokens,"<RELOP, '%s', %d>\n",yytext,line_no); return GT;}
\<\= { fprintf(f_tokens,"<RELOP, '%s', %d>\n",yytext,line_no); return LE;}
\>\= { fprintf(f_tokens,"<RELOP, '%s', %d>\n",yytext,line_no); return GE;}
\=\= { fprintf(f_tokens,"<RELOP, '%s', %d>\n",yytext,line_no); return EQ;}
\!\= { fprintf(f_tokens,"<RELOP, '%s', %d>\n",yytext,line_no); return NE;}

{id} { yylval.sval=strdup(yytext); fprintf(f_tokens,"<ID, '%s', %d, %d>\n",yytext,scope,line_no); return ID;}
{digit}+ { yylval.ival = atoi(yytext); fprintf(f_tokens,"<CONS, 'INT', %d, %d>\n",yylval.ival,line_no); return INT_CONS;}
\".*\" { yylval.sval=strdup(yytext); fprintf(f_tokens,"<CONS, 'STRING', %s, %d>\n",yytext,line_no); return STRING_CONS;}
{digit}+[\.]{digit}+ { yylval.fval = atof(yytext); fprintf(f_tokens,"<CONS, 'FLOAT', %f, %d>\n",yylval.fval,line_no); return FLOAT_CONS;}
\'{alpha}\' { yylval.sval = strdup(yytext); fprintf(f_tokens,"<CONS, 'CHAR', %c, %d>\n",yylval.sval[1],line_no); return CHAR_CONS;}

[\n] { line_no++;}
[ |\t] ;

[.] { return ERR;}
%%
int yywrap()
{
	return 1;
}