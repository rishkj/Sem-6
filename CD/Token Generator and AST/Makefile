LEX = lex
YACC = yacc
CC = gcc
YFLAGS = -d

all: 
	$(LEX) token_generator.l
	$(YACC) $(YFLAGS) grammar_validator.y
	$(CC) y.tab.c
	./a.out
