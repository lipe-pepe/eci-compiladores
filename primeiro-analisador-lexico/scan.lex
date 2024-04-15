%{
string lexema;
%}

/* Coloque aqui definições regulares */

WS	    [ \t\n]
DIGITO  [0-9]
LETRA   [a-zA-Z]

ID      (\$?({LETRA}|_)[a-zA-Z0-9_]*)
INT     ({DIGITO}+)
FLOAT   ({DIGITO}?+"."?{DIGITO}+([eE][+-]?{DIGITO}+)?)
STRING  (\"[^\"\n]*\"|\'[^\'\n]*\') 


%%
    /* Padrões e ações. Nesta seção, comentários devem ter um tab antes */

{WS}	{ /* ignora espaços, tabs e '\n' */ } 

">="    { lexema = yytext; return _MAIG; }
"<="    { lexema = yytext; return _MEIG; }
"=="    { lexema = yytext; return _IG; }
"!="    { lexema = yytext; return _DIF; }

"for"   { lexema = yytext; return _FOR; }
"if"    { lexema = yytext; return _IF; }

{ID}    { lexema = yytext; return _ID;}
"$"     { lexema = yytext; return _ID; }
{INT}   { lexema = yytext; return _INT; }
{FLOAT} { lexema = yytext; return _FLOAT; }
{STRING} {  lexema = yytext;
            lexema.erase(0, 1);
            lexema.erase(lexema.length() - 1);
            return _STRING; }

.       { lexema = yytext; return *yytext; 
          /* Essa deve ser a última regra. Dessa forma qualquer caractere isolado será retornado pelo seu código ascii. */ }

%%

/* Não coloque nada aqui - a função main é automaticamente incluída na hora de avaliar e dar a nota. */