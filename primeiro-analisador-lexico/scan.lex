%{
#include <iostream>
#include <string>
string lexema;
%}

/* Coloque aqui definições regulares */

/* OBS: Lookahead pro teste 11: $"/"{" */

WS	    [ \t\n]
DIGITO  [0-9]
LETRA   [a-zA-Z]

ID_INV  (\$?({LETRA}|{DIGITO}|_|$)[a-zA-Z0-9_]*\$)
ID      (\$?({LETRA}|_)[a-zA-Z0-9_]*)
INT     ({DIGITO}+)
FLOAT   ({DIGITO}?+"."?{DIGITO}+([eE][+-]?{DIGITO}+)?)
STRING_A  (\"[^\"\n]*(\\.|"")*[^\"\\]*\") 
STRING_B  (\'[^\'\n]*(\\.|'')*[^\'\\]*\')
STRING2 (\`[^\`]*\`)
COMENT  (\/\*[^*]*\*+([^/*][^*]*\*+)*\/|\/\/[^\n]*)


%%
    /* Padrões e ações. Nesta seção, comentários devem ter um tab antes */

{WS}	{ /* ignora espaços, tabs e '\n' */ } 

">="    { lexema = yytext; return _MAIG; }
"<="    { lexema = yytext; return _MEIG; }
"=="    { lexema = yytext; return _IG; }
"!="    { lexema = yytext; return _DIF; }

"for"   { lexema = yytext; return _FOR; }
"if"    { lexema = yytext; return _IF; }

{ID_INV}    { cout << "Erro: Identificador invalido: " << yytext << "\n"; }  
{ID}        { lexema = yytext; return _ID;}
"$"         { lexema = yytext; return _ID; }
{INT}       { lexema = yytext; return _INT; }
{FLOAT}     { lexema = yytext; return _FLOAT; }
{COMENT}    { lexema = yytext; return _COMENTARIO; }
{STRING_A}  {  
                lexema = yytext;
                lexema.erase(0, 1);
                lexema.erase(lexema.length() - 1);

                // Procura por caracteres de escape e remove
                size_t achado = lexema.find("\\\"");
                while (achado != std::string::npos) {
                    lexema.erase(achado, 1); // Remove 1 caractere na posição achado
                    achado = lexema.find("\\\"", achado); // Procura pelo proximo caracter de escape
                }

                // Procura por caracteres de "" e remove
                size_t achado2 = lexema.find("\"\"");
                while (achado2 != std::string::npos) {
                    lexema.erase(achado2, 1); // Remove a primeira aspa
                    achado2 = lexema.find("\"\"", achado2 + 1); // Procura pela próxima sequência de duas aspas
                }
                return _STRING; 
            }
{STRING_B}  {  
                lexema = yytext;
                lexema.erase(0, 1);
                lexema.erase(lexema.length() - 1);

                // Procura por caracteres de escape e remove
                size_t achado = lexema.find("\\\'");
                while (achado != std::string::npos) {
                    lexema.erase(achado, 1); // Remove 1 caractere na posição achado
                    achado = lexema.find("\\\'", achado); // Procura pelo proximo caracter de escape
                }

                // Procura por caracteres de '' e remove
                size_t achado2 = lexema.find("\'\'");
                while (achado2 != std::string::npos) {
                    lexema.erase(achado2, 1); // Remove a primeira aspa
                    achado2 = lexema.find("\'\'", achado2 + 1); // Procura pela próxima sequência de duas aspas
                }
                return _STRING; 
            }
{STRING2}   { 
                lexema = yytext;
                lexema.erase(0, 1);
                lexema.erase(lexema.length() - 1);
                return _STRING2; 
            }

.       { lexema = yytext; return *yytext; 
          /* Essa deve ser a última regra. Dessa forma qualquer caractere isolado será retornado pelo seu código ascii. */ }

%%

/* Não coloque nada aqui - a função main é automaticamente incluída na hora de avaliar e dar a nota. */