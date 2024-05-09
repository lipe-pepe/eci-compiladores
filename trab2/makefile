all: teste entradas.txt
	./teste < entradas.txt

lex.yy.c: tradutor.l
	lex tradutor.l

teste: lex.yy.c
	g++ -o teste -Wall -std=c++17 lex.yy.c -ll

clean:
	rm -f lex.yy.c teste