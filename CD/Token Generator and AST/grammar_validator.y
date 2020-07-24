%{
	#include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include"lex.yy.c"
	void yyerror(char *string);

    void decrease_scope();

    void update_st(char *var);

    float get_var_val(char *var);
    float get_val(char *val);

    int check_if_var_exists(char *var);
    int check_multiple_assignments(char *var);

    void var_with_assign(char *var, float val);

    void create_st(FILE *f_st);


    // AST
    void push_cs_onto_stack(ast *comp_statement);
    ast* pop_cs_from_stack();

    void add_stat_to_cs_stack();

    ast* create_node_main_init();
    void create_node_arit_init(char *oper);
    void create_node_rel_init(char *oper);
    void create_node_assign_init(char *oper);
    void create_node_decl_init();
    void create_node_for_init();
    void create_node_dowhile_init();
    void if_init();
    void jump_stat_init(char *type);
    ast* comp_stat_init();
    void print_stat_init(char *oper);
    void var_init(char *var_name);
    void str_val_init(char *val);
    void float_init(float val);
    void int_init(int val);
    void char_val_init(char val);

    void push_onto_valarit_stack(ast *var);
    ast* pop_from_valarit_stack();

    void write_ast_into_file();
    void writing_ast(FILE *f_ast, int tab, ast *node);
    void print_tab(FILE *f_ast, int tab);
%}
%union {
    int ival;
    float fval;
    char *sval;
}

%token <ival> INT_CONS
%token <fval> FLOAT_CONS
%token <sval> STRING_CONS ID CHAR_CONS

%token PRO_BEG TYPE_SPEC FOR DO WHILE IF COUT REDIR_OPER ERR
%token LT GT LE GE EQ NE
%token BREAK CONTINUE RETURN

%left ',' ';'
%right '='
%left '+' '-'
%left '*' '/'
%left LT GT LE GE EQ NE
%left '(' '{' ')' '}' 

%type <fval> arit_expression
%type <sval> value
%%
program_beginning	:	PRO_BEG { head_ast = create_node_main_init();} left_brac right_brac { decrease_scope();} left_brac compound_statement right_brac { printf("Program accepted\n"); pop_cs_from_stack();}
                    ;

declarator_list     :   value { no_of_var_decl += 1; int ch = check_multiple_assignments($1); if(ch == 1){ yyerror("Multiple assignments");} this_var_is_being_declared  =1;} ',' declarator_list 
                    |   value '=' arit_expression { int ch = check_multiple_assignments($1); if(undefined_var_in_arit == 1){ yyerror("Undefined Variable");} else if(ch == 1){ yyerror("Multiple assignments");} else { var_with_assign($1,$3);} no_of_var_decl += 1; create_node_assign_init("="); undefined_var_in_arit = 0;}
                    |   value '=' arit_expression { int ch = check_multiple_assignments($1); if(undefined_var_in_arit == 1){ yyerror("Undefined Variable");} else if(ch == 1){ yyerror("Multiple assignments");} else { var_with_assign($1,$3);} no_of_var_decl += 1; create_node_assign_init("="); this_var_is_being_declared  =1; undefined_var_in_arit  =0;} ',' declarator_list
                    |   value { no_of_var_decl += 1; int ch = check_multiple_assignments($1); if(ch == 1){ yyerror("Multiple assignments");} }
                    ;

compound_statement  :   statement { add_stat_to_cs_stack();} compound_statement
                    |   statement { add_stat_to_cs_stack();}
                    ;

statement           :   exp_statement
                    |   selection_statement
                    |   iteration_statement
                    |   jump_statement semi
                    ;

exp_statement       :   expression semi
                    ;

selection_statement :   IF { comp_stat_init(); line_of_error = line_no;} left_brac expression right_brac { decrease_scope(); line_of_error = line_no;} left_brac compound_statement right_brac { decrease_scope(); if_init();}
                    ;

iteration_statement :   FOR { comp_stat_init(); line_of_error = line_no;} left_brac for_init_statement semi for_condition semi for_updation right_brac { decrease_scope();} left_brac compound_statement right_brac { decrease_scope(); create_node_for_init();}
                    |   DO { comp_stat_init(); line_of_error = line_no;} left_brac compound_statement right_brac WHILE { decrease_scope(); line_of_error = line_no;} left_brac rel_expression right_brac semi { decrease_scope(); create_node_dowhile_init();}
                    ;

jump_statement      :   BREAK { jump_stat_init("break"); line_of_error = line_no;}
                    |   CONTINUE { jump_stat_init("continue"); line_of_error = line_no;}
                    |   RETURN { line_of_error = line_no;} expression { jump_stat_init("return");}
                    ;

expression          :   rel_expression
                    |   value '=' arit_expression { int ch = check_if_var_exists($1); if(undefined_var_in_arit == 1 || ch == 0){ yyerror("Undefined Variable");} else { var_with_assign($1,$3);} create_node_assign_init("=");}
                    |   TYPE_SPEC { line_of_error = line_no;} declarator_list { create_node_decl_init();}
                    |   print
                    |   arit_expression
                    ;

rel_expression      :   arit_expression LT arit_expression { create_node_rel_init("<");}
                    |   arit_expression GT arit_expression { create_node_rel_init(">");}
                    |   arit_expression LE arit_expression { create_node_rel_init("<=");}
                    |   arit_expression GE arit_expression { create_node_rel_init(">=");}
                    |   arit_expression EQ arit_expression { create_node_rel_init("==");}
                    |   arit_expression NE arit_expression { create_node_rel_init("!=");}
                    ;

arit_expression     :   value { $$ = get_val($1); int ch = check_if_var_exists($1); if(ch == 0){ undefined_var_in_arit = 1;}}
                    |   value '+' arit_expression { $$ = get_val($1)+$3; create_node_arit_init("+");}
                    |   value '-' arit_expression { $$ = get_val($1)-$3; create_node_arit_init("-");}
                    |   value '*' arit_expression { $$ = get_val($1)*$3; create_node_arit_init("*");}
                    |   value '/' arit_expression { $$ = get_val($1)/$3; create_node_arit_init("/");}
                    ;

for_init_statement  :   for_init_st_val ',' for_init_statement 
                    |   for_init_st_val
                    |   
                    ;
for_init_st_val     :   TYPE_SPEC value '=' arit_expression { var_with_assign($2,$4); no_of_var_decl += 1; create_node_assign_init("="); create_node_decl_init();}
                    |   value '=' arit_expression { var_with_assign($1,$3); create_node_assign_init("=");}
                    ;

for_condition       :   rel_expression
                    |
                    ;

for_updation        :   for_updation_val ',' for_updation
                    |   for_updation_val
                    |   
                    ;
for_updation_val    :   value '=' arit_expression { var_with_assign($1,$3); create_node_assign_init("=");}
                    ;

print               :   COUT { line_of_error = line_no;} REDIR_OPER arit_expression print1 { print_stat_init("<<");}
                    ;

print1              :   REDIR_OPER arit_expression print1
                    |   
                    ;

value               :   ID { $$ = $1; update_st($1); var_init($1); line_of_error = line_no; this_var_is_being_declared = 0;}
                    |   INT_CONS { char var[20]; sprintf(var, "%d", $1); $$ = var; int_init($1);}
                    |   FLOAT_CONS { char var[20]; sprintf(var, "%f", $1); $$ = var; float_init($1);}
                    |   STRING_CONS { $$ = $1; str_val_init($1);}
                    |   CHAR_CONS { $$ = $1; value_of_char = $1[1]; char_val_init($1[1]);}
                    ;

semi                :   ';'
                    |   error { yyerror("Missing semicolon");}
                    ;

left_brac           :   '('
                    |   '{'
                    |   error { scope++; yyerror("Missing left bracket");}
                    ;

right_brac          :   ')'
                    |   '}'
                    |   error { scope_decrease = 1; yyerror("Missing right bracket");}
                    ;

%%
int main()
{   
    yyin = fopen("input_file.txt","r");
    f_tokens = fopen("tokens.txt","w");

	yyparse();
    fclose(f_tokens);

    FILE *f_st = fopen("symbol_table1.txt","w");
    create_st(f_st);
    fclose(f_st);

    write_ast_into_file();
	
    return 0;
}

void decrease_scope()
{
    if(scope_decrease == 1)
    {
        scope--;
        scope_decrease = 0;
    }
}


void update_st(char *var)
{
    if(head == NULL)
    {
        head = (node *)malloc(sizeof(node));
        strcpy(head->id_name,var);
        strcpy(head->id_type,prev_type);
        head->scope = scope;
        head->val_int = 0;
        head->val_float = 0;
        char val_char = 'a';
        head->no_of_lines = 1;
        head->line_no[0] = line_no;
        head->link = NULL;
        if((strcmp(head->id_type,"int") == 0) || (strcmp(head->id_type,"float") == 0))
        {
            head->storage_req = 4;
        }
        else if(strcmp(head->id_type,"char") == 0)
        {
            head->storage_req = 1;
        }
        if(line_of_declaration == line_no  && this_var_is_being_declared == 1)
        {
            head->has_been_declared = 1;
        }
        else
        {
            head->has_been_declared = 0;
        }
        return;
    }
    
    node *temp = head;
    node *temp1 = NULL;
    node *temp_prev = NULL;
    int flag = 0;
    int val_i;
    float val_f;
    char val_c;
    while(temp != NULL)
    {
        if(strcmp(temp->id_name,var) == 0)
        {
            temp_prev = temp;
            if(strcmp(temp->id_type,"float") == 0)
            {
                flag = 1;
                val_f = temp->val_float;
            }
            else if(strcmp(temp->id_type,"int") == 0)
            {
                val_i = temp->val_int;
            }
            else 
            {
                flag = 2;
                val_c = temp->val_char;
            }
            if(temp->scope == scope)
            {
                break;
            }
        }

        temp1 = temp;
        temp = temp->link;
    }

    if(temp == NULL)
    {
        temp = (node *)malloc(sizeof(node));
        strcpy(temp->id_name,var);
        temp->scope = scope;
        temp->no_of_lines = 1;
        temp->line_no[0] = line_no;
        temp->link = NULL;
        temp1->link = temp;

        if(temp_prev == NULL)
        {   
            strcpy(temp->id_type,prev_type);
            if(strcmp(prev_type,"int") == 0 || strcmp(prev_type,"float") == 0)
            {
                temp->storage_req = 4;
            }
            else
            {
                temp->storage_req = 1;
            }
            temp->val_int = 0;
            temp->val_float = 0;
            temp->val_char = 'a';
            if(line_of_declaration == line_no  && this_var_is_being_declared == 1)
            {
                temp->has_been_declared = 1;
            }
            else
            {
                temp->has_been_declared = 0;
            }
        }

        else
        {
            strcpy(temp->id_type,temp_prev->id_type);
            if(flag == 1)
            {
                temp->val_float = temp_prev->val_float;
            }
            else if(flag == 0)
            {
                temp->val_int = temp_prev->val_int;
            }
            else
            {
                temp->val_char = temp_prev->val_char;
            }
            temp->storage_req = temp_prev->storage_req;
            temp->has_been_declared = temp_prev->has_been_declared;
            if(line_of_declaration == line_no  && this_var_is_being_declared == 1)
            {
                temp->has_been_declared = 1;
                if(temp_prev->has_been_declared == 1)
                {
                    multiple_declarations = 1;
                }
            }
        }
    }

    else
    {
        temp->line_no[temp->no_of_lines] = line_no;
        temp->no_of_lines++;
        if(line_of_declaration == line_no && this_var_is_being_declared == 1)
        {
            if(temp->has_been_declared == 1)
            {
                multiple_declarations = 1;
            }
            temp->has_been_declared = 1;
        }
    }
}


float get_var_val(char *var)
{
    node *temp = head;
    while(temp != NULL)
    {
        if(strcmp(temp->id_name,var) == 0 && temp->scope == scope)
        {
            break;
        }
        temp = temp->link;
    }
    if(scope_decrease == 1)
    {
        scope--;
        scope_decrease = 0;
    }
    
    if(strcmp(temp->id_type,"int") == 0)
    {
        return (float)temp->val_int;
    }
    else if(strcmp(temp->id_type,"char") == 0)
    {
        value_of_char = temp->val_char;
        return 0.0;
    }
    else
    {
        return temp->val_float;
    }
}


float get_val(char *var)
{   
    if(isdigit(var[0]))
    {
        return atof(var);
    }
    else if(var[0] == '"')
    {
        return -1;
    }
    else if(var[0] == '\'')
    {
        value_of_char = var[1];
        return -1;
    }
    return get_var_val(var);
}


int check_if_var_exists(char *var)
{
    if(isdigit(var[0]))
    {
        return 1;
    }
    else if(var[0] == '\'')
    {
        return 1;
    }

    node *temp = head;
    while(temp)
    {
        if(strcmp(temp->id_name,var) == 0 && temp->scope == scope)
        {
            break;
        }
        temp = temp->link;
    }

    if(temp->has_been_declared == 0)
    {
        line_of_error = line_no;
        return 0;
    }
    return 1;
}

int check_multiple_assignments(char *var)
{
    if(multiple_declarations == 1)
    {
        multiple_declarations = 0;
        line_of_error = line_no;
        return 1;
    }
    return 0;
}


void var_with_assign(char *var,float val)
{
    node *temp = head;

    while(temp!= NULL)
    {
        if(strcmp(temp->id_name,var) == 0)
        {
            if(strcmp(temp->id_type,"int") == 0)
            {
                temp->val_int = (int)val;
            }
            else if(strcmp(temp->id_type,"char") == 0)
            {
                temp->val_char = value_of_char;
            }
            else
            {
                temp->val_float = val;
            }
        }
        temp = temp->link;
    }
}



void create_st(FILE *f_st)
{
    node *temp = head;
    fprintf(f_st,"Identifier\t\tType\t\tValue\t\tScope\t\tStorage Req (bytes)\t\tLine Number\n");
    while(temp!= NULL)
    {
        if(temp->has_been_declared == 1)
        {   fprintf(f_st,"%s\t\t\t\t%s\t\t",temp->id_name,temp->id_type);

            if(strcmp(temp->id_type,"int") == 0)
            {
                fprintf(f_st,"\t%d\t\t\t",temp->val_int);
            }
            else if(strcmp(temp->id_type,"char") == 0)
            {
                fprintf(f_st,"%c\t\t\t",temp->val_char);
            }
            else
            {
                fprintf(f_st,"%0.2f\t\t",temp->val_float);
            }
            fprintf(f_st,"%d\t\t\t",temp->scope);
            fprintf(f_st,"%d\t\t\t\t\t\t",temp->storage_req);

            int count = 0;
            while(count<temp->no_of_lines-1)
            {
                fprintf(f_st,"%d,",temp->line_no[count]);
                count++;
            }
            if(temp->no_of_lines != 0)
            {
                fprintf(f_st,"%d\n",temp->line_no[count]);
            }
        }

        temp = temp->link;
    }
}


void yyerror(char *string)
{
	printf("At line no : %d\nError occured : %s\n",line_of_error,string);
}


// AST

void push_cs_onto_stack(ast *comp_statement)
{
    css *temp = (css *)malloc(sizeof(css));
    temp->comp_stat = comp_statement;
    temp->next = NULL;
    
    if(topc == NULL)
    {
        topc = temp;
    }
    else
    {
        temp->next = topc;
        topc = temp;
    }
}

ast* pop_cs_from_stack()
{
    if(topc != NULL)
    {
        css *temp = topc;
        topc = topc->next;
        ast *temp1 = temp->comp_stat;
        free(temp);
        return temp1;
    }
    return NULL;
}


void add_stat_to_cs_stack()
{
    if(topc != NULL)
    {
        topc->comp_stat->op.comp_st.stat[topc->comp_stat->op.comp_st.stat_count] = pop_from_valarit_stack();
        topc->comp_stat->op.comp_st.stat_count += 1;
    }
}


ast* create_node_main_init()
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = main_func;

    ast *comp_statement = comp_stat_init();

    temp->op.main_body.body = comp_statement;
    
    return temp;
}

void create_node_arit_init(char *oper)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = arit_expression;

    strcpy(temp->op.arit.oper,oper);
    temp->op.arit.right = pop_from_valarit_stack();
    temp->op.arit.left = pop_from_valarit_stack();

    push_onto_valarit_stack(temp);
}


void create_node_rel_init(char *oper)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = rel_expression;

    strcpy(temp->op.rel.oper,oper);
    temp->op.rel.right = pop_from_valarit_stack();
    temp->op.rel.left = pop_from_valarit_stack();

    push_onto_valarit_stack(temp);
}

void create_node_assign_init(char *oper)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = assign_expression;

    strcpy(temp->op.assign.oper,oper);
    temp->op.assign.assigned_val = pop_from_valarit_stack();
    temp->op.assign.var = pop_from_valarit_stack();

    push_onto_valarit_stack(temp);
}

void create_node_decl_init()
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = declaration;

    strcpy(temp->op.decl.type,prev_type);
    temp->op.decl.count_no_decl = no_of_var_decl;
    while(no_of_var_decl--)
    {
        temp->op.decl.list[no_of_var_decl] = pop_from_valarit_stack();
    }

    no_of_var_decl = 0;

    push_onto_valarit_stack(temp);
}

void create_node_for_init()
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = for_loop;

    temp->op.for_loop.for_upd = pop_from_valarit_stack();
    temp->op.for_loop.for_cond = pop_from_valarit_stack();
    temp->op.for_loop.for_init = pop_from_valarit_stack();
    temp->op.for_loop.for_body = pop_cs_from_stack();

    push_onto_valarit_stack(temp);
}

void create_node_dowhile_init()
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = do_while_loop;

    temp->op.dowhile.dowhile_exp = pop_from_valarit_stack();
    temp->op.dowhile.dowhile_body = pop_cs_from_stack();

    push_onto_valarit_stack(temp);
}

void if_init()
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = if_cond;

    temp->op.if_cond.if_expr = pop_from_valarit_stack();
    temp->op.if_cond.if_body = pop_cs_from_stack();
    
    push_onto_valarit_stack(temp);
}

void jump_stat_init(char *type)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = jump_stat;

    strcpy(temp->op.jump_st.jump_stat_type,type);
    
    if(strcmp(type,"return") == 0)
    {
        temp->op.jump_st.val = pop_from_valarit_stack();
    }
    else
    {
        temp->op.jump_st.val = NULL;
    }

    push_onto_valarit_stack(temp);
}

ast* comp_stat_init()
{
    ast *comp_statement = (ast *)malloc(sizeof(ast));
    comp_statement->tag = comp_stat;

    comp_statement->op.comp_st.stat_count = 0;

    push_cs_onto_stack(comp_statement);

    return comp_statement;
}

void print_stat_init(char *oper)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = print_stat;

    strcpy(temp->op.print_st.oper,oper);
    temp->op.print_st.output = pop_from_valarit_stack();

    push_onto_valarit_stack(temp);
}

void var_init(char *var_name)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = var;

    strcpy(temp->op.var.name,var_name);

    push_onto_valarit_stack(temp);
}
void str_val_init(char *val)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = str_cons;

    strcpy(temp->op.str_val.val,val);

    push_onto_valarit_stack(temp);
}

void float_init(float val)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = float_cons;

    temp->op.float_val.val = val;

    push_onto_valarit_stack(temp);
}

void int_init(int val)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = int_cons;

    temp->op.int_val.val = val;

    push_onto_valarit_stack(temp);
}

void char_val_init(char val)
{
    ast *temp = (ast *)malloc(sizeof(ast));
    temp->tag = char_cons;

    temp->op.char_val.val = val;

    push_onto_valarit_stack(temp);
}


void push_onto_valarit_stack(ast *var)
{
    vas *temp = (vas *)malloc(sizeof(vas));
    temp->expr = var;
    temp->next = NULL;
    
    if(topv == NULL)
    {
        topv = temp;
    }
    else
    {
        temp->next = topv;
        topv = temp;
    }
}

ast* pop_from_valarit_stack()
{
    if(topv != NULL)
    {
        vas *temp = topv;
        topv = topv->next;
        ast *temp1 = temp->expr;
        free(temp);
        return temp1;
    }
    return NULL;
}


void write_ast_into_file()
{
    FILE *f_ast = fopen("ast.txt","w");
    int no_of_tab_spaces = 0;

    writing_ast(f_ast,no_of_tab_spaces,head_ast);

    fclose(f_ast);
}

void writing_ast(FILE *f_ast, int tab, ast* node)
{
    if(node->tag == main_func)
    {
        fprintf(f_ast,"<Main Tree>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.main_body.body);
        tab -= 1;
        fprintf(f_ast,"<Main Tree Closed>\n");
    }

    else if(node->tag == arit_expression)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Arit Exp>\n");

        tab += 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Arit Exp oper> %s\n",node->op.arit.oper);
        
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Left Operand>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.arit.left);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Left Operand Closed>\n");

        print_tab(f_ast,tab);
        fprintf(f_ast,"<Right Operand>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.arit.right);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Right Operand Closed>\n");

        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Arit Exp Closed>\n");
    }

    else if(node->tag == rel_expression)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Rel Exp>\n");

        tab += 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Rel Exp oper> %s\n",node->op.rel.oper);
        
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Left Operand>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.rel.left);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Left Operand Closed>\n");

        print_tab(f_ast,tab);
        fprintf(f_ast,"<Right Operand>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.rel.right);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Right Operand Closed>\n");

        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Rel Exp Closed>\n");
    }

    else if(node->tag == assign_expression)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Assign Exp>\n");

        tab += 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Assign Exp oper> %s\n",node->op.assign.oper);
        
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Var Getting Val>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.assign.var);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Var Getting Val Closed>\n");

        print_tab(f_ast,tab);
        fprintf(f_ast,"<Val Being Assigned>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.assign.assigned_val);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Val Being Assigned Closed>\n");

        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Assign Exp Closed>\n");
    }

    else if(node->tag == declaration)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Declaration>\n");

        tab += 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Type> %s\n",node->op.decl.type);

        print_tab(f_ast,tab);
        fprintf(f_ast,"<Declared Vars>\n");
        tab += 1;
        for(int i=0;i<node->op.decl.count_no_decl;i++)
        {
            writing_ast(f_ast,tab,node->op.decl.list[i]);
        }
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Declared Vars Closed>\n");

        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Declaration Closed>\n");
    }

    else if(node->tag == for_loop)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Loop>\n");

        tab += 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Init>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.for_loop.for_init);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Init Closed>\n");

        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Cond>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.for_loop.for_cond);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Cond Closed>\n");

        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Upd>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.for_loop.for_upd);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Upd Closed>\n");

        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Body>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.for_loop.for_body);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Body Closed>\n");

        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<For Loop Closed>\n");
    }

    else if(node->tag == do_while_loop)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Do While Loop>\n");

        tab += 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Do While Exp>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.dowhile.dowhile_exp);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Do While Exp Closed>\n");

        print_tab(f_ast,tab);
        fprintf(f_ast,"<Do While Body Cond>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.dowhile.dowhile_body);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Do While Body Closed>\n");

        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Do While Loop Closed>\n");
    }

    else if(node->tag == if_cond)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<If>\n");

        tab += 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<If Exp>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.if_cond.if_expr);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<If Exp Closed>\n");

        print_tab(f_ast,tab);
        fprintf(f_ast,"<If Body Cond>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.if_cond.if_body);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<If Body Closed>\n");

        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<If Closed>\n");
    }

    else if(node->tag == jump_stat)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Jump Statement>\n");

        tab += 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<JS Type> %s\n",node->op.jump_st.jump_stat_type);

        if(strcmp("return",node->op.jump_st.jump_stat_type) == 0)
        {
            print_tab(f_ast,tab);
            fprintf(f_ast,"<Return Value>\n");
            
            tab += 1;
            writing_ast(f_ast,tab,node->op.jump_st.val);
            tab -= 1;

            print_tab(f_ast,tab);
            fprintf(f_ast,"<Return Value Closed>\n");
        }

        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Jump Statement Closed>\n");
    }

    else if(node->tag == comp_stat)
    {
        for(int i=0;i<node->op.comp_st.stat_count;i++)
        {
            writing_ast(f_ast,tab,node->op.comp_st.stat[i]);
        }
    }

    else if(node->tag == print_stat)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Print>\n");

        tab += 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Print oper> %s\n",node->op.print_st.oper);

        print_tab(f_ast,tab);
        fprintf(f_ast,"<Print Val>\n");
        tab += 1;
        writing_ast(f_ast,tab,node->op.print_st.output);
        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Print Val Closed>\n");

        tab -= 1;
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Print Closed>\n");
    }

    else if(node->tag == var)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Var> %s\n",node->op.var.name);
    }

    else if(node->tag == str_cons)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<String Constant> %s\n",node->op.str_val.val);
    }

    else if(node->tag == float_cons)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Float Constant> %f\n",node->op.float_val.val);
    }

    else if(node->tag == int_cons)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Int Constant> %d\n",node->op.int_val.val);
    }

    else if(node->tag == char_cons)
    {
        print_tab(f_ast,tab);
        fprintf(f_ast,"<Char Constant> %c\n",node->op.char_val.val);
    }
}

void print_tab(FILE *f_ast,int tab)
{
    for(int i=0;i<tab;i++)
    {
        fprintf(f_ast,"\t");
    }
}