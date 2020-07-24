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
        float val_float;
        char val_char;
        int line_no[100];
        int no_of_lines;
        struct node *link;
    }node;
    node *head = NULL;
    
    int scope = 0;
    int line_no = 1;
    char prev_type[20];
    int prev_line;
    int is_it_arit_exp = 0;

    int is_var_present = 0;

    char value_of_char = 'a';

    // ICG
    int inter_var_no = 0;
    int branch_no = 0;

    char icg_var_stk[100][20];
    int top = -1;

    int branch_stk[50];
    int top_br = -1;

    int is_for_upd = 0;
    char for_upd_val[10][50];
    int top_for = -1;

    int loop_br[20];
    int top_loop = -1;

    char do_while_br[10][20];
    int top_dow = -1;


    FILE *f_icg;

    typedef struct quadruples
    {
        char op[20];
        char arg1[20];
        char arg2[20];
        char res[20];
        struct quadruples *link;
    } quad;
    quad *headq = NULL;

    //Optimization
    char optim_code[1000][100];
    int oc_pos = 0;

    typedef struct copy_prop
    {
        char var[20];
        char var_being_assign[20];
        struct copy_prop *link;
    } cyp;
    cyp *headcyp = NULL;

    typedef struct cons_prop
    {
        char var[20];
        char val_being_assign[20];
        struct cons_prop *link;
    } csp;
    csp *headcsp = NULL;

    int arit_exp_is_only_val = 1;
    int no_of_loops = 0;

    int no_of_term_arit = 0;
    typedef struct last_arit_calc
    {
        char left_oper[20];
        char oper[20];
        char right_oper[20];
    } lac;
    lac node_arit;

    typedef struct optim_for
    {
        char var[20];
        char left_oper[20];
        char oper[20];
        char right_oper[20];
        struct optim_for *link;
    } of;
    of *node_for = NULL;


    int lines_to_remove[1000];
    int top_line=0;

    typedef struct vars_used
    {
        char var[20];
        int line_assigned_start;
        int line_assigned_end;
        int has_been_used;
        int loop_no;
        struct vars_used *link;
    } vu;
    vu *headvu = NULL;

    int line_st = 0;
    int line_end = 0;
    int no_of_arit_stat = 0;

    typedef struct final_optim_code
    {
        enum
        {
            assign, arit, branch_label,
            rel_exp, GOTO, if_goto,
            not, print 
        } tag;

        char op[20];
        char arg1[20];
        char arg2[20];
        char res[20];
    } foc;
    foc optim_final[200];
    int of_count = 0;
    foc optim_final_assembly[200];
    int ofa_count = 0;

    // Assembly Code Generation
    FILE *f_assembly;

    typedef struct avail_reg_queue
    {
        char reg[20];
        struct avail_reg_queue *link;
    } arq;
    arq *headarq = NULL;

    typedef struct used_reg_list
    {
        char reg[20];
        char var[20];
        int temp_var_st;
        struct used_reg_list *link;
    } url;
    url *headurl = NULL;

    int reg_not_avail = 0;
%}

digit [0-9]
alpha [a-zA-Z_]
id {alpha}({alpha}|{digit})*
%%
int[ ]main { return PRO_BEG;}

([ ]*|(\n\t)*|(\n)*|(\t)*)*\/\/.* 
([ ]*|(\n\t)*|(\n)*|(\t)*)*\/\*(.*\n)*.*\*\/ 

int|char|float|void { strcpy(prev_type,yytext); return TYPE_SPEC;}
for { return FOR;}
do { return DO;}
while { return WHILE;}
if { return IF;}
break { return BREAK;}
continue { return CONTINUE;}
return { return RETURN;}
cout { return COUT;}

\(|\{ { scope++; return yytext[0];}
\)|\} { scope--; return yytext[0];}
\;|\, { return yytext[0]; no_of_arit_stat = 0;}
\= { return yytext[0];}
\<\< { return REDIR_OPER;}
\+|\*|\-|\/ { return yytext[0];}

\< { return LT;}
\> { return GT;}
\<\= { return LE;}
\>\= { return GE;}
\=\= { return EQ;}
\!\= { return NE;}

{id} { yylval.sval=strdup(yytext); return ID;}
{digit}+ { yylval.ival = atoi(yytext); return INT_CONS;}
\".*\" { yylval.sval=strdup(yytext); return STRING_CONS;}
{digit}+[\.]{digit}+ { yylval.fval = atof(yytext); return FLOAT_CONS;}
\'{alpha}\' { yylval.sval = strdup(yytext); return CHAR_CONS;}

[\n] { line_no++; no_of_arit_stat = 0;}
[ |\t] ;

[.] { return ERR;}
%%
int yywrap()
{
	return 1;
}