LEX = lex
YACC = yacc
CC = gcc
YFLAGS = -d

all: 
	$(LEX) icg.l
	$(YACC) $(YFLAGS) icg.y
	$(CC) y.tab.c
	./a.out
