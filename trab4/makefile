all: teste entradas.txt
	./teste < entradas.txt	

teste: lex.yy.c y.tab.c
	g++ -std=c++17 -o teste y.tab.c -lfl

lex.yy.c:	mini_js.l
	lex mini_js.l

y.tab.c: mini_js.y
	yacc mini_js.y

clean:
	rm -f lex.yy.c trab3 y.tab.c teste