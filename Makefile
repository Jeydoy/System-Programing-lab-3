all:
	flex lexer.l
	bison -d parser.y
	gcc lex.yy.c parser.tab.c -o parser
	
clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h parser ast.json
