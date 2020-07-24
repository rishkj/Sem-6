%{
	#include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include"lex.yy.c"
	void yyerror(char *string);

    void update_st(char *var);

    float get_var_val(char *var);
    float get_val(char *val);

    void var_with_assign(char *var, float val);

    // ICG
    void push_onto_icg_stack(char val[20]);
    void pop_from_icg_stack(char val[20]);
    void create_inter_var(char inter[20]);
    void create_new_branch_var(char branch[20]);

    void assign_icg();
    void arit_icg();
    void rel_icg();
    void create_branch();
    void rel_expr();
    void for_branch_dec();
    void if_branch_dec();
    void rel_expr_dowhile();
    void do_while_after_branch();
    void do_while_print_after_br();
    void break_icg();
    void print_icg();

    void insert_into_quad(char op[20], char arg1[20], char arg2[20], char res[20]);
    void write_quad(FILE *f_quad);

    //Optimization
    void add_to_copy(char var[20], char val_being_assign[20]);
    void add_to_cons(char var[20], char val_being_assign[20]);
    int check_if_copy_or_cons_prop(char var[20], char return_val[20]);
    int cons_or_var(char val[20]);

    void remove_from_copy_lhs(char var[20]);
    void remove_from_cons_lhs(char var[20]);
    void remove_from_copy_rhs(char var[20]);
    void remove_from_cons_rhs(char var[20]);

    void remove_from_all(char var[20]);

    void add_lines_to_arr(int st,int end);
    void if_var_add(char var[20]);
    void add_to_vars_list_assign(char var[20]);
    void var_being_used(char var[20]);
    void write_all_lines();

    void write_optim_code(FILE *f_opt);

    void create_final_optim_code();

    // Assembly Code Generation
    void create_reg_queue();
    void check_reg_avail();
    void free_all_temp_reg();
    void add_reg_to_avail_reg(char reg[20]);

    int assign_reg(char reg[20], char var[20]);
    void get_reg(char reg[20], char var[20]);
    void add_to_used_reg(char reg[20],char var[20]);
    void get_first_used_reg(char reg[20]);

    void add_arit_to_assembly(char res[20],char left_oper[20],char oper[20],char right_oper[20]);
    void add_assign_to_assembly(char res[20],char val[20]);
    void add_branch_label_to_assembly(char branch[20]);
    void add_rel_to_assembly(char res[20],char left_oper[20],char oper[20],char right_oper[20], int i);
    void add_goto_to_assembly(char res[20]);

    void write_into_assembly();
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

%type <fval> arit_expression arit_expression1
%type <sval> value
%%
program_beginning	:	PRO_BEG '(' ')' '{' compound_statement '}' { printf("Program accepted\n");}
                    ;

declarator_list     :   value { line_st = oc_pos; push_onto_icg_stack("0"); assign_icg(); add_to_vars_list_assign($1);} ',' declarator_list 
                    |   value '=' arit_expression { var_with_assign($1,$3); assign_icg(); add_to_vars_list_assign($1);}
                    |   value '=' arit_expression { var_with_assign($1,$3); assign_icg(); add_to_vars_list_assign($1);} ',' declarator_list
                    |   value { line_st = oc_pos; push_onto_icg_stack("0"); assign_icg(); add_to_vars_list_assign($1);}
                    ;

compound_statement  :   statement compound_statement
                    |   statement
                    ;

statement           :   exp_statement
                    |   selection_statement
                    |   iteration_statement
                    |   jump_statement
                    ;

exp_statement       :   expression ';'
                    ;

selection_statement :   IF '(' expression { rel_expr(); no_of_loops++;} ')' '{' compound_statement '}' { if_branch_dec(); no_of_loops--;}
                    ;

iteration_statement :   FOR '(' for_init_statement ';' { create_branch(); is_for_upd = 1; no_of_loops++;} for_condition { top_loop++; loop_br[top_loop] = branch_no; rel_expr();} ';' for_updation ')' '{' compound_statement '}' { for_branch_dec(); top_loop--; no_of_loops--;}
                    |   DO { create_branch(); do_while_after_branch(); no_of_loops++;} '{' compound_statement '}' WHILE '(' rel_expression { rel_expr_dowhile(); do_while_print_after_br(); top_loop--; no_of_loops--;} ')' ';'
                    ;

jump_statement      :   BREAK ';' { break_icg();}
                    |   CONTINUE ';'
                    |   RETURN expression ';'
                    ;

expression          :   rel_expression
                    |   value '=' arit_expression { var_with_assign($1,$3); assign_icg(); add_to_vars_list_assign($1);}
                    |   TYPE_SPEC declarator_list
                    |   print
                    |   arit_expression
                    ;

rel_expression      :   arit_expression LT { push_onto_icg_stack("<");} arit_expression { rel_icg(); arit_exp_is_only_val = 1; no_of_term_arit = 0;}
                    |   arit_expression GT { push_onto_icg_stack(">");} arit_expression { rel_icg(); arit_exp_is_only_val = 1; no_of_term_arit = 0;}
                    |   arit_expression LE { push_onto_icg_stack("<=");} arit_expression { rel_icg(); arit_exp_is_only_val = 1; no_of_term_arit = 0;}
                    |   arit_expression GE { push_onto_icg_stack(">=");} arit_expression { rel_icg(); arit_exp_is_only_val = 1; no_of_term_arit = 0;}
                    |   arit_expression EQ { push_onto_icg_stack("==");} arit_expression { rel_icg(); arit_exp_is_only_val = 1; no_of_term_arit = 0;}
                    |   arit_expression NE { push_onto_icg_stack("!=");} arit_expression { rel_icg(); arit_exp_is_only_val = 1; no_of_term_arit = 0;}
                    ;

arit_expression     :   arit_expression1 { $$ = $1;}
                    |   arit_expression '+' { push_onto_icg_stack("+");} arit_expression { $$ = 0; arit_icg(); arit_exp_is_only_val = 0;}
                    |   arit_expression '-' { push_onto_icg_stack("-");} arit_expression { $$ = 0; arit_icg(); arit_exp_is_only_val = 0;}
                    ;

arit_expression1    :   value { $$ = get_val($1); no_of_term_arit++;}
                    |   arit_expression1 '*' { push_onto_icg_stack("*");} arit_expression1 { $$ = 0; arit_icg(); arit_exp_is_only_val = 0;}
                    |   arit_expression1 '/' { push_onto_icg_stack("/");} arit_expression1 { $$ = 0; arit_icg(); arit_exp_is_only_val = 0;}
                    ;

for_init_statement  :   for_init_st_val ',' for_init_statement 
                    |   for_init_st_val
                    |   
                    ;
for_init_st_val     :   TYPE_SPEC value '=' arit_expression { var_with_assign($2,$4); assign_icg(); add_to_vars_list_assign($2);}
                    |   value '=' arit_expression { var_with_assign($1,$3); assign_icg(); add_to_vars_list_assign($1);}
                    ;

for_condition       :   rel_expression
                    |
                    ;

for_updation        :   for_updation_val ',' for_updation
                    |   for_updation_val
                    |   
                    ;
for_updation_val    :   value '=' arit_expression { assign_icg(); add_to_vars_list_assign($1);}
                    ;

print               :   COUT REDIR_OPER arit_expression print1 { print_icg(); no_of_term_arit = 0;}
                    ;

print1              :   REDIR_OPER arit_expression print1
                    |   
                    ;

value               :   ID { $$ = $1; update_st($1); push_onto_icg_stack($1);}
                    |   INT_CONS { char var[20]; sprintf(var, "%d", $1); $$ = var; push_onto_icg_stack(var);}
                    |   FLOAT_CONS { char var[20]; sprintf(var, "%f", $1); $$ = var; push_onto_icg_stack(var);}
                    |   STRING_CONS { $$ = $1; push_onto_icg_stack($1);}
                    |   CHAR_CONS { $$ = $1; char val[20]; val[0] = $1[1]; val[1] = '\0';  push_onto_icg_stack(val);}
                    ;

%%
int main()
{   
    yyin = fopen("input_file.txt","r");
    f_icg = fopen("icg.txt","w");
    f_assembly = fopen("assembly_code.txt","w");

    create_reg_queue();

	yyparse();

    fclose(f_icg);

    FILE *f_quad = fopen("quadruples.txt","w");
    write_quad(f_quad);
    fclose(f_quad);

    FILE *f_opt = fopen("optimized_icg.txt","w");
    write_optim_code(f_opt);
    fclose(f_opt);

    write_into_assembly();
    fclose(f_assembly);
	
    return 0;
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
        head->no_of_lines = 1;
        head->line_no[0] = line_no;
        head->link = NULL;
        return;
    }
    
    node *temp = head;
    node *temp1 = NULL;
    node *temp_prev = NULL;
    int flag = 0;
    int val_i;
    char val_c;
    float val_f;
    while(temp != NULL)
    {
        if(strcmp(temp->id_name,var) == 0)
        {
            temp_prev = temp;
            if(strcmp(temp->id_type,"int") != 0)
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
            temp->val_int = 0;
            temp->val_float = 0;
            temp->val_char = 'a';
        }

        else
        {
            strcpy(temp->id_type,temp_prev->id_type);
            if(flag == 1)
            {
                temp->val_float = temp_prev->val_float;
            }
            else if(flag == 2)
            {
                temp->val_char = value_of_char;
            }
            else
            {
                temp->val_int = temp_prev->val_int;
            }
        }
    }

    else
    {
        temp->line_no[temp->no_of_lines] = line_no;
        temp->no_of_lines++;
    }
}


float get_var_val(char *var)
{
    is_it_arit_exp = 1;
    node *temp = head;
    while(temp != NULL)
    {
        if(strcmp(temp->id_name,var) == 0 && temp->scope == scope)
        {
            break;
        }
        temp = temp->link;
    }

    if(strcmp(temp->id_type,"int") == 0)
    {
        return (float)temp->val_int;
    }
    else if(strcmp(temp->id_type,"char") == 0)
    {
        value_of_char = temp->val_char;
        return 0;
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


void var_with_assign(char *var,float val)
{
    if(is_it_arit_exp == 0)
    {    
        node *temp = head;
        while(temp!= NULL)
        {
            if(strcmp(temp->id_name,var) == 0 && temp->scope == scope)
            {
                break;
            }
            temp = temp->link;
        }

        if(strcmp(temp->id_type,"int") == 0)
        {
            temp->val_int = (int)val;
        }
        else
        {
            temp->val_float = val;
        }
    }
    else
    {
        is_it_arit_exp = 0;
    }
}


void yyerror(char *string)
{
	printf("At line no : %d. Error occured : %s\n",line_no,string);
    yyparse();
}


//ICG

void push_onto_icg_stack(char val[20])
{
    if(top != 99)
    {
        top++;
        strcpy(icg_var_stk[top],val);
    }
}

void pop_from_icg_stack(char val[20])
{
    if(top != -1)
    {
        strcpy(val,icg_var_stk[top]);
        top--;
    }
}

void create_inter_var(char inter[20])
{
    strcpy(inter,"t");
    char digit[20];
    sprintf(digit, "%d", inter_var_no);
    strcat(inter,digit);
    inter_var_no++;
}

void create_new_branch_var(char branch[20])
{
    strcpy(branch,"L");
    char digit[20];
    sprintf(digit,"%d",branch_no);
    strcat(branch,digit);

    top_br++;
    branch_stk[top_br] = branch_no;
    branch_no++;
}


void assign_icg()
{
    char val_being_assign[20];
    pop_from_icg_stack(val_being_assign);

    char var_getting_val[20];
    pop_from_icg_stack(var_getting_val);

    insert_into_quad("=",val_being_assign,"",var_getting_val);

    if(is_for_upd == 0)
    {
        fprintf(f_icg,"%s = %s\n",var_getting_val,val_being_assign);
        
        if(arit_exp_is_only_val == 1)
        {
            char return_val[20];
            int ch = check_if_copy_or_cons_prop(val_being_assign,return_val);
            if(ch)
            {
                strcpy(val_being_assign,return_val);
            }
            strcpy(optim_code[oc_pos],var_getting_val);
            strcat(optim_code[oc_pos]," = ");
            strcat(optim_code[oc_pos],val_being_assign);

            optim_final[of_count].tag = assign;
            strcpy(optim_final[of_count].arg1,val_being_assign);
            strcpy(optim_final[of_count].res,var_getting_val);
            of_count++;

            oc_pos++;

            if(no_of_loops == 0)
            {
                if(cons_or_var(val_being_assign) == 1)
                {
                    add_to_cons(var_getting_val,val_being_assign);
                }
                else
                {
                    add_to_copy(var_getting_val,val_being_assign);
                }
            }
            remove_from_copy_rhs(var_getting_val);
            remove_from_cons_rhs(var_getting_val);
        }
        else
        {
            remove_from_all(var_getting_val);
            arit_exp_is_only_val = 1;

            strcpy(optim_code[oc_pos],var_getting_val);
            strcat(optim_code[oc_pos]," = ");
            strcat(optim_code[oc_pos],val_being_assign);

            optim_final[of_count].tag = assign;
            strcpy(optim_final[of_count].arg1,val_being_assign);
            strcpy(optim_final[of_count].res,var_getting_val);
            of_count++;

            oc_pos++;
        }

        if(no_of_term_arit > 1)
        {
            oc_pos -= 2;
            strcpy(optim_code[oc_pos],var_getting_val);
            strcat(optim_code[oc_pos]," = ");
            strcat(optim_code[oc_pos],node_arit.left_oper);
            strcat(optim_code[oc_pos]," ");
            strcat(optim_code[oc_pos],node_arit.oper);
            strcat(optim_code[oc_pos]," ");
            strcat(optim_code[oc_pos],node_arit.right_oper);

            of_count -= 2;
            optim_final[of_count].tag = arit;
            strcpy(optim_final[of_count].arg1,node_arit.left_oper);
            strcpy(optim_final[of_count].arg2,node_arit.right_oper);
            strcpy(optim_final[of_count].op,node_arit.oper);
            strcpy(optim_final[of_count].res,var_getting_val);
            of_count++;

            if_var_add(node_arit.left_oper);
            if_var_add(node_arit.right_oper);
            
            oc_pos++;
            no_of_arit_stat--;
        }
        else
        {
            if_var_add(val_being_assign);
        }
        no_of_term_arit = 0;
        line_end = oc_pos-1;
    }
    else
    {
        top_for++;
        strcpy(for_upd_val[top_for],var_getting_val);
        strcat(for_upd_val[top_for]," = ");
        strcat(for_upd_val[top_for],val_being_assign);
        is_for_upd = 0;
        no_of_term_arit = 0;

        strcpy(node_for->var,var_getting_val);
    }
}

void arit_icg()
{
    char right_operand[20];
    pop_from_icg_stack(right_operand);

    char oper[20];
    pop_from_icg_stack(oper);

    char left_operand[20];
    pop_from_icg_stack(left_operand);

    char new_var[20];
    create_inter_var(new_var);

    insert_into_quad(oper,left_operand,right_operand,new_var);

    if(is_for_upd == 0)
    {
        fprintf(f_icg,"%s = %s %s %s\n",new_var,left_operand,oper,right_operand);

        char return_left_oper[20];
        int ch = check_if_copy_or_cons_prop(left_operand,return_left_oper);
        if(ch)
        {
            strcpy(left_operand,return_left_oper);
        }

        char return_right_oper[20];
        ch = check_if_copy_or_cons_prop(right_operand,return_right_oper);
        if(ch)
        {
            strcpy(right_operand,return_right_oper);
        }
        
        strcpy(optim_code[oc_pos],new_var);
        strcat(optim_code[oc_pos]," = ");
        strcat(optim_code[oc_pos],left_operand);
        strcat(optim_code[oc_pos]," ");
        strcat(optim_code[oc_pos],oper);
        strcat(optim_code[oc_pos]," ");
        strcat(optim_code[oc_pos],right_operand);
        oc_pos++;

        optim_final[of_count].tag = arit;
        strcpy(optim_final[of_count].arg1,left_operand);
        strcpy(optim_final[of_count].op,oper);
        strcpy(optim_final[of_count].arg2,right_operand);
        strcpy(optim_final[of_count].res,new_var);
        of_count++;

        if_var_add(left_operand);
        if_var_add(right_operand);
        
        strcpy(node_arit.left_oper,left_operand);
        strcpy(node_arit.oper,oper);
        strcpy(node_arit.right_oper,right_operand);
        no_of_arit_stat++;
    }
    else
    {
        top_for++;
        strcpy(for_upd_val[top_for],new_var);
        strcat(for_upd_val[top_for]," = ");
        strcat(for_upd_val[top_for],left_operand);
        strcat(for_upd_val[top_for]," ");
        strcat(for_upd_val[top_for],oper);
        strcat(for_upd_val[top_for]," ");
        strcat(for_upd_val[top_for],right_operand);

        of *temp = (of *)malloc(sizeof(of));
        strcpy(temp->left_oper,left_operand);
        strcpy(temp->oper,oper);
        strcpy(temp->right_oper,right_operand);
        temp->link=NULL;
        if(node_for == NULL)
        {
            node_for = temp;
        }
        else
        {
            temp->link = node_for;
            node_for = temp;
        }
    }
    push_onto_icg_stack(new_var);
}

void rel_icg()
{
    char right_operand[20];
    pop_from_icg_stack(right_operand);

    char oper[20];
    pop_from_icg_stack(oper);

    char left_operand[20];
    pop_from_icg_stack(left_operand);

    char new_var[20];
    create_inter_var(new_var);

    fprintf(f_icg,"%s = %s %s %s\n",new_var,left_operand,oper,right_operand);
    push_onto_icg_stack(new_var);

    insert_into_quad(oper,left_operand,right_operand,new_var);

    char return_left_oper[20];
    int ch = check_if_copy_or_cons_prop(left_operand,return_left_oper);
    if(ch)
    {
        strcpy(left_operand,return_left_oper);
    }

    char return_right_oper[20];
    ch = check_if_copy_or_cons_prop(right_operand,return_right_oper);
    if(ch)
    {
        strcpy(right_operand,return_right_oper);
    }

    strcpy(optim_code[oc_pos],new_var);
    strcat(optim_code[oc_pos]," = ");
    strcat(optim_code[oc_pos],left_operand);
    strcat(optim_code[oc_pos]," ");
    strcat(optim_code[oc_pos],oper);
    strcat(optim_code[oc_pos]," ");
    strcat(optim_code[oc_pos],right_operand);
    oc_pos++;

    optim_final[of_count].tag = rel_exp;
    strcpy(optim_final[of_count].arg1,left_operand);
    strcpy(optim_final[of_count].op,oper);
    strcpy(optim_final[of_count].arg2,right_operand);
    strcpy(optim_final[of_count].res,new_var);
    of_count++;

    if_var_add(left_operand);
    if_var_add(right_operand);
}

void create_branch()
{
    char branch[20];
    create_new_branch_var(branch);

    fprintf(f_icg,"%s:\n",branch);

    strcpy(optim_code[oc_pos],branch);
    strcat(optim_code[oc_pos],":");
    oc_pos++;

    optim_final[of_count].tag = branch_label;
    strcpy(optim_final[of_count].res,branch);
    of_count++;
}

void rel_expr()
{
    char val[20];
    pop_from_icg_stack(val);

    char var_getting_val[20];
    create_inter_var(var_getting_val);
    
    fprintf(f_icg,"%s = not %s\n",var_getting_val,val);
    insert_into_quad("not",val,"",var_getting_val);

    strcpy(optim_code[oc_pos],var_getting_val);
    strcat(optim_code[oc_pos]," = not ");
    strcat(optim_code[oc_pos],val);
    oc_pos++;

    optim_final[of_count].tag = not;
    strcpy(optim_final[of_count].arg1,val);
    strcpy(optim_final[of_count].res,var_getting_val);
    of_count++;

    char branch[20];
    create_new_branch_var(branch);
    fprintf(f_icg,"if %s GOTO %s\n",var_getting_val,branch);
    insert_into_quad("if",var_getting_val,"",branch);

    strcpy(optim_code[oc_pos],"if ");
    strcat(optim_code[oc_pos],var_getting_val);
    strcat(optim_code[oc_pos]," GOTO ");
    strcat(optim_code[oc_pos],branch);
    oc_pos++;

    optim_final[of_count].tag = if_goto;
    strcpy(optim_final[of_count].arg1,var_getting_val);
    strcpy(optim_final[of_count].res,branch);
    of_count++;
}

void for_branch_dec()
{
    fprintf(f_icg,"%s\n",for_upd_val[top_for-1]);
    fprintf(f_icg,"%s\n",for_upd_val[top_for]);
    top_for -=2;

    strcpy(optim_code[oc_pos],node_for->var);
    strcat(optim_code[oc_pos]," = ");
    strcat(optim_code[oc_pos],node_for->left_oper);
    strcat(optim_code[oc_pos]," ");
    strcat(optim_code[oc_pos],node_for->oper);
    strcat(optim_code[oc_pos]," ");
    strcat(optim_code[oc_pos],node_for->right_oper);
    oc_pos++;

    optim_final[of_count].tag = arit;
    strcpy(optim_final[of_count].arg1,node_for->left_oper);
    strcpy(optim_final[of_count].op,node_for->oper);
    strcpy(optim_final[of_count].arg2,node_for->right_oper);
    strcpy(optim_final[of_count].res,node_for->var);
    of_count++;

    of *temp = node_for;
    node_for = temp->link;
    free(temp);

    int br = branch_stk[top_br];
    char branch[20];
    strcpy(branch,"L");
    char digit[20];
    sprintf(digit,"%d",br-1);
    strcat(branch,digit);

    fprintf(f_icg,"GOTO %s\n",branch);
    insert_into_quad("goto","","",branch);

    strcpy(optim_code[oc_pos],"GOTO ");
    strcat(optim_code[oc_pos],branch);
    oc_pos++;

    optim_final[of_count].tag = GOTO;
    strcpy(optim_final[of_count].res,branch);
    of_count++;

    strcpy(branch,"L");
    sprintf(digit,"%d",br);
    strcat(branch,digit);
    fprintf(f_icg,"%s:\n",branch);
    top_br -= 2;

    strcpy(optim_code[oc_pos],branch);
    strcat(optim_code[oc_pos],":");
    oc_pos++;

    optim_final[of_count].tag = branch_label;
    strcpy(optim_final[of_count].res,branch);
    of_count++;
}

void if_branch_dec()
{
    int br = branch_stk[top_br];
    top_br--;

    char branch[20];
    strcpy(branch,"L");
    char digit[20];
    sprintf(digit,"%d",br);
    strcat(branch,digit);

    fprintf(f_icg,"%s:\n",branch);

    strcpy(optim_code[oc_pos],branch);
    strcat(optim_code[oc_pos],":");
    oc_pos++;

    optim_final[of_count].tag = branch_label;
    strcpy(optim_final[of_count].res,branch);
    of_count++;
}

void rel_expr_dowhile()
{
    char val[20];
    pop_from_icg_stack(val);

    int br = branch_stk[top_br];
    top_br--;
    
    char branch[20];
    strcpy(branch,"L");
    char digit[20];
    sprintf(digit,"%d",br);
    strcat(branch,digit);

    fprintf(f_icg,"if %s GOTO %s\n",val,branch);

    insert_into_quad("if",val,"",branch);

    strcpy(optim_code[oc_pos],"if ");
    strcat(optim_code[oc_pos],val);
    strcat(optim_code[oc_pos]," GOTO ");
    strcat(optim_code[oc_pos],branch);
    oc_pos++;

    optim_final[of_count].tag = if_goto;
    strcpy(optim_final[of_count].res,branch);
    of_count++;
}

void do_while_after_branch()
{
    char branch[20];
    create_new_branch_var(branch);

    top_loop++;
    loop_br[top_loop] = branch_no - 1;
    
    top_dow++;
    strcpy(do_while_br[top_dow],branch);
    
    top_br--;
}

void do_while_print_after_br()
{
    fprintf(f_icg,"%s:\n",do_while_br[top_dow]);
    strcpy(optim_code[oc_pos],do_while_br[top_dow]);
    strcat(optim_code[oc_pos],":");
    oc_pos++;

    optim_final[of_count].tag = branch_label;
    strcpy(optim_final[of_count].res,do_while_br[top_dow]);
    of_count++;

    top_dow--;
}

void break_icg()
{
    
    int br = loop_br[top_loop];
    char branch[20];
    strcpy(branch,"L");
    char digit[20];
    sprintf(digit,"%d",br);
    strcat(branch,digit);

    fprintf(f_icg,"GOTO %s\n",branch);
    insert_into_quad("goto","","",branch);

    strcpy(optim_code[oc_pos],"GOTO ");
    strcat(optim_code[oc_pos],branch);
    oc_pos++;

    optim_final[of_count].tag = GOTO;
    strcpy(optim_final[of_count].res,branch);
    of_count++;
}

void print_icg()
{
    char val[20];
    pop_from_icg_stack(val);

    fprintf(f_icg,"print %s\n",val);
    insert_into_quad("print","","",val);

    char return_value[20];
    int ch = check_if_copy_or_cons_prop(val,return_value);

    if(ch == 1)
    {
        strcpy(val,return_value);
    }
    if_var_add(val);

    strcpy(optim_code[oc_pos],"print ");
    strcat(optim_code[oc_pos],val);
    oc_pos++;

    optim_final[of_count].tag = print;
    strcpy(optim_final[of_count].res,val);
    of_count++;
}


void insert_into_quad(char op[20], char arg1[20], char arg2[20], char res[20])
{
    quad *temp = (quad *)malloc(sizeof(quad));
    strcpy(temp->op,op);
    strcpy(temp->arg1,arg1);
    strcpy(temp->arg2,arg2);
    strcpy(temp->res,res);

    if(headq == NULL)
    {
        headq = temp;
    }
    else
    {
        quad *temp1 = headq;
        while(temp1->link)
        {
            temp1 = temp1->link;
        }
        temp1->link = temp;
    }
}

void write_quad(FILE *f_quad)
{
    quad *temp = headq;
    fprintf(f_quad,"%s\t\t%20s\t\t%20s\t\t%20s\t\t%20s\n\n","Pos","Op","Arg1","Arg2","Res");
    int pos = 1;
    while(temp)
    {
        fprintf(f_quad,"%d\t\t%20s\t\t%20s\t\t%20s\t\t%20s\n",pos,temp->op,temp->arg1,temp->arg2,temp->res);
        temp = temp->link;
        pos++;
    }
}


//Optimization

void add_to_copy(char var[20], char val_being_assign[20])
{
    if(headcyp == NULL)
    {
        headcyp = (cyp *)malloc(sizeof(cyp));
        strcpy(headcyp->var,var);
        strcpy(headcyp->var_being_assign,val_being_assign);
        headcyp->link = NULL;
        return;
    }
    
    cyp *temp = headcyp;
    cyp *prev = NULL;
    while(temp)
    {
        if(strcmp(temp->var,var) == 0)
        {
            break;
        }
        prev = temp;
        temp = temp->link;
    }
    if(temp)
    {
        strcpy(temp->var_being_assign,val_being_assign);
    }
    else
    {
        temp = (cyp *)malloc(sizeof(cyp));
        strcpy(temp->var,var);
        strcpy(temp->var_being_assign,val_being_assign);
        prev->link = temp;
        temp->link = NULL;

        remove_from_cons_lhs(var);
    }
}

void add_to_cons(char var[20], char val_being_assign[20])
{
    if(headcsp == NULL)
    {
        headcsp = (csp *)malloc(sizeof(csp));
        strcpy(headcsp->var,var);
        strcpy(headcsp->val_being_assign,val_being_assign);
        headcsp->link = NULL;
        return;
    }
    
    csp *temp = headcsp;
    csp *prev = NULL;
    while(temp)
    {
        if(strcmp(temp->var,var) == 0)
        {
            break;
        }
        prev = temp;
        temp = temp->link;
    }
    if(temp)
    {
        strcpy(temp->val_being_assign,val_being_assign);
    }
    else
    {
        temp = (csp *)malloc(sizeof(csp));
        strcpy(temp->var,var);
        strcpy(temp->val_being_assign,val_being_assign);
        prev->link = temp;
        temp->link = NULL;

        remove_from_copy_lhs(var);
    }
}

int check_if_copy_or_cons_prop(char var[20], char return_val[20])
{
    if(no_of_loops == 0)
    {   cyp *temp = headcyp;
        while(temp)
        {
            if(strcmp(temp->var,var) == 0)
            {
                strcpy(return_val,temp->var_being_assign);
                return 1;
            }
            temp = temp->link;
        }

        csp *temp1 = headcsp;
        while(temp1)
        {
            if(strcmp(temp1->var,var) == 0)
            {
                strcpy(return_val,temp1->val_being_assign);
                return 1;
            }
            temp1=temp1->link;
        }
    }
    return 0;
}

int cons_or_var(char val[20])
{
    if(isdigit(val[0]))
    {
        return 1;
    }
    return 2;
}


void remove_from_copy_lhs(char var[20])
{
    cyp *temp = headcyp;
    cyp *prev = NULL;
    while(temp)
    {
        if(strcmp(temp->var,var) == 0)
        {
            break;
        }
        prev = temp;
        temp = temp->link;
    }
    if(temp)
    {
        if(prev == NULL)
        {
            headcyp = temp->link;
            free(temp);
        }
        else
        {
            prev->link = temp->link;
            temp->link = NULL;
            free(temp);
        }
    }
}

void remove_from_cons_lhs(char var[20])
{
    csp *temp = headcsp;
    csp *prev = NULL;
    while(temp)
    {
        if(strcmp(temp->var,var) == 0)
        {
            break;
        }
        prev = temp;
        temp = temp->link;
    }
    if(temp)
    {
        if(prev == NULL)
        {
            headcsp = temp->link;
            free(temp);
        }
        else
        {
            prev->link = temp->link;
            temp->link = NULL;
            free(temp);
        }
    }
}

void remove_from_copy_rhs(char var[20])
{
    cyp *temp = headcyp;
    cyp *prev = NULL;
    while(temp)
    {
        if(strcmp(temp->var_being_assign,var) == 0)
        {
            break;
        }
        prev = temp;
        temp = temp->link;
    }
    if(temp)
    {
        if(prev == NULL)
        {
            headcyp = temp->link;
            free(temp);
        }
        else
        {
            prev->link = temp->link;
            temp->link = NULL;
            free(temp);
        }
    }
}

void remove_from_cons_rhs(char var[20])
{
    csp *temp = headcsp;
    csp *prev = NULL;
    while(temp)
    {
        if(strcmp(temp->val_being_assign,var) == 0)
        {
            break;
        }
        prev = temp;
        temp = temp->link;
    }
    if(temp)
    {
        if(prev == NULL)
        {
            headcsp = temp->link;
            free(temp);
        }
        else
        {
            prev->link = temp->link;
            temp->link = NULL;
            free(temp);
        }
    }
}


void remove_from_all(char var[20])
{
    remove_from_cons_lhs(var);
    remove_from_cons_rhs(var);
    remove_from_copy_lhs(var);
    remove_from_copy_rhs(var);
}


void add_lines_to_arr(int st,int end)
{
    while(st<=end)
    {
        lines_to_remove[top_line] = st;
        st++;
        top_line++;
    }
}

void if_var_add(char var[20])
{
    if(cons_or_var(var) == 2)
    {
        var_being_used(var);
    }
}

void add_to_vars_list_assign(char var[20])
{
    if(headvu == NULL)
    {
        headvu = (vu *)malloc(sizeof(vu));
        strcpy(headvu->var,var);
        headvu->line_assigned_start = line_end - no_of_arit_stat;
        headvu->line_assigned_end = line_end;
        headvu->has_been_used = 0;
        headvu->loop_no = no_of_loops;
        headvu->link = NULL;

        return;
    }
    
    vu *temp = headvu;
    vu *prev = NULL;
    while(temp != NULL)
    {
        if(strcmp(temp->var,var) == 0)
        {
            break;
        }
        prev = temp;
        temp = temp->link;
    }
    if(temp)
    {
        if(no_of_loops < temp->loop_no)
        {
            if(temp->has_been_used == 0)
            {
                add_lines_to_arr(temp->line_assigned_start,temp->line_assigned_end);

                temp->line_assigned_start = line_end - no_of_arit_stat;
                temp->line_assigned_end = line_end;
                temp->loop_no = no_of_loops;
            }
            else
            {
                temp->line_assigned_start = line_end - no_of_arit_stat;
                temp->line_assigned_end = line_end;
                temp->loop_no = no_of_loops;
                temp->has_been_used = 0;
            }
        }
        else if(temp->loop_no == no_of_loops)
        {
            if(no_of_loops == 0)
            {
                if(temp->has_been_used == 0)
                {
                    add_lines_to_arr(temp->line_assigned_start,temp->line_assigned_end);

                    temp->line_assigned_start = line_end - no_of_arit_stat;
                    temp->line_assigned_end = line_end;
                    temp->loop_no = no_of_loops;
                }
                else
                {
                    temp->line_assigned_start = line_end - no_of_arit_stat;
                    temp->line_assigned_end = line_end;
                    temp->has_been_used = 0;
                }
            }
            else
            {
                temp->has_been_used = 1;
                temp->line_assigned_start = -1;
                temp->line_assigned_end = -2;
            }
        }
        else
        {
            temp->has_been_used = 1;
            temp->line_assigned_start = -1;
            temp->line_assigned_end = -2;
        }
    }
    else
    {
        temp = (vu *)malloc(sizeof(vu));
        strcpy(temp->var,var);
        temp->line_assigned_start = line_end - no_of_arit_stat;
        temp->line_assigned_end = line_end;
        temp->has_been_used = 0;
        temp->loop_no = no_of_loops;
        temp->link = NULL;

        prev->link = temp;
    }
}

void var_being_used(char var[20])
{
    vu *temp = headvu;
    while(temp)
    {
        if(strcmp(temp->var,var) == 0)
        {
            temp->has_been_used = 1;
            temp->line_assigned_start = -1;
            temp->line_assigned_end = -2;
            break;
        }
        temp = temp->link;
    }
}

void write_all_lines()
{
    vu *temp = headvu;
    while(temp)
    {
        if(temp->has_been_used == 0)
        {
            add_lines_to_arr(temp->line_assigned_start,temp->line_assigned_end);
        }
        temp=temp->link;
    }
}


void write_optim_code(FILE *f_opt)
{
    int i = 0;
    int k = 0;
    write_all_lines();
    while(i<oc_pos)
    {
        int flag = 0;
        for(int k=0;k<top_line;k++)
        {
            if(lines_to_remove[k] == i)
            {
                flag = 1;
                break;
            }
        }
        
        if(flag == 0)
        {
            fprintf(f_opt,"%s\n",optim_code[i]);

            optim_final_assembly[ofa_count] = optim_final[i];
            ofa_count++;
        }
        i++;
    }
}


// Assembly Code Generation
void create_reg_queue()
{
    headarq = (arq *)malloc(sizeof(arq));
    strcpy(headarq->reg,"R0");
    headarq->link = NULL;

    arq *temp = headarq;

    char curr_reg[20];
    char num[20];

    int i=1;
    while(i<9)
    {
        strcpy(curr_reg,"R");
        sprintf(num,"%d",i);
        strcat(curr_reg,num);

        arq *temp1 = (arq*)malloc(sizeof(arq));
        strcpy(temp1->reg,curr_reg);
        temp1->link = NULL;
        temp->link = temp1;
        temp = temp1;

        i++;
    }
}

void check_reg_avail()
{
    if(reg_not_avail == 1)
    {
        free_all_temp_reg();
        reg_not_avail = 0;
    }
}

void free_all_temp_reg()
{
    url *temp = headurl;
    url *prev = NULL;
    while(temp)
    {
        if(temp->temp_var_st == 1)
        {
            add_reg_to_avail_reg(temp->reg);
            if(prev == NULL)
            {
                url *temp1 = temp;
                headurl = temp->link;
                temp = headurl;
                free(temp1);
            }
            else
            {
                url *temp1 = temp;
                prev->link = temp->link;
                temp = temp->link;
                free(temp1);
            }
        }
        else
        {
            prev = temp;
            temp = temp->link;
        }
    }
}

void add_reg_to_avail_reg(char reg[20])
{
    if(headarq == NULL)
    {
        headarq = (arq *)malloc(sizeof(arq));
        strcpy(headarq->reg,reg);
        headarq->link = NULL;
        
        return;
    }
    arq *temp = headarq;
    arq *prev = NULL;

    while(temp)
    {
        prev = temp;
        temp = temp->link;
    }

    temp = (arq *)malloc(sizeof(arq));
    strcpy(temp->reg,reg);
    temp->link = NULL;
    prev->link = temp;
}


int assign_reg(char reg[20], char var[20])
{
    url *temp = headurl;
    url *prev = NULL;
    int flag = 0;
    while(temp)
    {
        if(strcmp(temp->var,var) == 0)
        {
            strcpy(reg,temp->reg);
            flag = 1;
            if(prev == NULL)
            {
                headurl = headurl->link;
                free(temp);
            }
            else
            {
                prev->link = temp->link;
                free(temp);
            }
            break;
        }
        prev = temp;
        temp = temp->link;
    }
    
    if(flag == 0)
    {
        get_reg(reg,var);
        return 1;
    }
    else
    {
        add_to_used_reg(reg,var);
        return 2;
    }
}

void get_reg(char reg[20], char var[20])
{
    arq *temp = headarq;
    if(temp == NULL)
    {
        get_first_used_reg(reg);
        add_to_used_reg(reg,var);
        reg_not_avail = 1;
        return;
    }

    strcpy(reg,temp->reg);
    headarq = temp->link;
    free(temp);
    
    add_to_used_reg(reg,var);

}

void add_to_used_reg(char reg[20],char var[20])
{
    if(headurl == NULL)
    {
        headurl = (url *)malloc(sizeof(url));
        strcpy(headurl->reg,reg);
        strcpy(headurl->var,var);
        if(var[0] == 't' || isdigit(var[0]))
        {
            headurl->temp_var_st = 1;
        }
        else
        {
            headurl->temp_var_st = 0;
        }
        return;
    }
    url *temp = headurl;
    while(temp->link)
    {
        temp = temp->link;
    }
    url *temp1 = (url *)malloc(sizeof(url));
    strcpy(temp1->reg,reg);
    strcpy(temp1->var,var);
    if(var[0] == 't' || isdigit(var[0]))
    {
        temp1->temp_var_st = 1;
    }
    else
    {
        temp1->temp_var_st = 0;
    }
    temp1->link = NULL;
    temp->link = temp1;
}

void get_first_used_reg(char reg[20])
{
    if(headurl != NULL)
    {
        url *temp = headurl;
        headurl = temp->link;
        strcpy(reg,temp->reg);

        free(temp);
    }
}


void add_arit_to_assembly(char res[20],char left_oper[20],char oper[20],char right_oper[20])
{
    char reg1[20];
    int ch1 = assign_reg(reg1,left_oper);
    if(ch1 == 1)
    {
        if(isdigit(left_oper[0]))
        {
            fprintf(f_assembly,"MOV %s, #%s\n",reg1,left_oper);
        }
        else
        {
            fprintf(f_assembly,"LD %s, %s\n",reg1,left_oper);
        }
    }

    char reg2[20];
    int ch2 = assign_reg(reg2,right_oper);
    if(ch2 == 1)
    {
        if(isdigit(right_oper[0]))
        {
            fprintf(f_assembly,"MOV %s, #%s\n",reg2,right_oper);
        }
        else
        {
            fprintf(f_assembly,"LD %s, %s\n",reg2,right_oper);
        }
    }

    char reg_res[20];
    int ch_res = assign_reg(reg_res,res);

    if(oper[0] == '+')
    {
        fprintf(f_assembly,"ADD %s, %s, %s\n",reg_res,reg1,reg2);
    }
    else if(oper[0] == '-')
    {
        fprintf(f_assembly,"SUB %s, %s, %s\n",reg_res,reg1,reg2);
    }
    else if(oper[0] == '*')
    {
        fprintf(f_assembly,"MUL %s, %s, %s\n",reg_res,reg1,reg2);
    }
    else if(oper[0] == '/')
    {
        fprintf(f_assembly,"DIV %s, %s, %s\n",reg_res,reg1,reg2);
    }
    
    fprintf(f_assembly,"ST %s, %s\n",res,reg_res);
}

void add_assign_to_assembly(char res[20],char val[20])
{
    char reg_res[20];
    int ch_res = assign_reg(reg_res,res);
    
    if(isdigit(val[0]))
    {
        fprintf(f_assembly,"MOV %s, #%s\n",reg_res,val);
        fprintf(f_assembly,"ST %s, %s\n",res,reg_res);
    }
    else
    {
        char reg1[20];
        int ch1 = assign_reg(reg1,val);
        if(ch1 == 1)
        {
            fprintf(f_assembly,"LD %s, %s\n",reg1,val);
        }

        fprintf(f_assembly,"MOV %s, %s\n",reg_res,reg1);
        fprintf(f_assembly,"ST %s, %s\n",res,reg_res);
    }
}

void add_branch_label_to_assembly(char branch[20])
{
    fprintf(f_assembly,"%s: ",branch);
}

void add_rel_to_assembly(char res[20],char left_oper[20],char oper[20],char right_oper[20], int i)
{
    char reg1[20];
    int ch1 = assign_reg(reg1,left_oper);
    if(ch1 == 1)
    {
        if(isdigit(left_oper[0]))
        {
            fprintf(f_assembly,"MOV %s, #%s\n",reg1,left_oper);
        }
        else
        {
            fprintf(f_assembly,"LD %s, %s\n",reg1,left_oper);
        }
    }

    char reg2[20];
    int ch2 = assign_reg(reg2,right_oper);
    if(ch2 == 1)
    {
        if(isdigit(right_oper[0]))
        {
            fprintf(f_assembly,"MOV %s, #%s\n",reg2,right_oper);
        }
        else
        {
            fprintf(f_assembly,"LD %s, %s\n",reg2,right_oper);
        }
    }

    char reg_res[20];
    int ch_res = assign_reg(reg_res,res);
    fprintf(f_assembly,"SUB %s, %s, %s\n",reg_res,reg1,reg2);

    if(strcmp(oper,"<") == 0)
    {
        if(optim_final_assembly[i+1].tag == not)
        {
            fprintf(f_assembly,"BGEZ %s, %s\n",reg_res,optim_final_assembly[i+2].res);
        }
        else
        {
            fprintf(f_assembly,"BLTZ %s, %s\n",reg_res,optim_final_assembly[i+1].res);
        }
    }
    else if(strcmp(oper,">") == 0)
    {
        if(optim_final_assembly[i+1].tag == not)
        {
            fprintf(f_assembly,"BLEZ %s, %s\n",reg_res,optim_final_assembly[i+2].res);
        }
        else
        {
            fprintf(f_assembly,"BGTZ %s, %s\n",reg_res,optim_final_assembly[i+1].res);
        }
    }
    else if(strcmp(oper,"<=") == 0)
    {
        if(optim_final_assembly[i+1].tag == not)
        {
            fprintf(f_assembly,"BGTZ %s, %s\n",reg_res,optim_final_assembly[i+2].res);
        }
        else
        {
            fprintf(f_assembly,"BLEZ %s, %s\n",reg_res,optim_final_assembly[i+1].res);
        }
    }
    else if(strcmp(oper,">=") == 0)
    {
        if(optim_final_assembly[i+1].tag == not)
        {
            fprintf(f_assembly,"BLTZ %s, %s\n",reg_res,optim_final_assembly[i+2].res);
        }
        else
        {
            fprintf(f_assembly,"BGEZ %s, %s\n",reg_res,optim_final_assembly[i+1].res);
        }
    }
    else if(strcmp(oper,"==") == 0)
    {
        if(optim_final_assembly[i+1].tag == not)
        {
            fprintf(f_assembly,"BNE %s, %s\n",reg_res,optim_final_assembly[i+2].res);
        }
        else
        {
            fprintf(f_assembly,"BEQ %s, %s\n",reg_res,optim_final_assembly[i+1].res);
        }
    }
    else if(strcmp(oper,"!=") == 0)
    {
        if(optim_final_assembly[i+1].tag == not)
        {
            fprintf(f_assembly,"BEQ %s, %s\n",reg_res,optim_final_assembly[i+2].res);
        }
        else
        {
            fprintf(f_assembly,"BNE %s, %s\n",reg_res,optim_final_assembly[i+1].res);
        }
    }
}

void add_goto_to_assembly(char res[20])
{
    fprintf(f_assembly,"BR %s\n",res);
}


void write_into_assembly()
{
    int i = 0;
    while(i<ofa_count)
    {
        if(optim_final_assembly[i].tag == arit)
        {
            add_arit_to_assembly(optim_final_assembly[i].res,optim_final_assembly[i].arg1,optim_final_assembly[i].op,optim_final_assembly[i].arg2);
        }
        else if(optim_final_assembly[i].tag == assign)
        {
            add_assign_to_assembly(optim_final_assembly[i].res,optim_final_assembly[i].arg1);
        }
        else if(optim_final_assembly[i].tag == branch_label)
        {
            add_branch_label_to_assembly(optim_final_assembly[i].res);
        }
        else if(optim_final_assembly[i].tag == rel_exp)
        {
            add_rel_to_assembly(optim_final_assembly[i].res,optim_final_assembly[i].arg1,optim_final_assembly[i].op,optim_final_assembly[i].arg2,i);
        }
        else if(optim_final_assembly[i].tag == GOTO)
        {
            add_goto_to_assembly(optim_final_assembly[i].res);
        }
        check_reg_avail();
        i++;
    }
}