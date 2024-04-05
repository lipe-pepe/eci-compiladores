/* Coloque aqui definições regulares */

WS	    [ \t\n]
DIGITO  [0-9]
LETRA   [a-zA-Z]

ID      (\$?({LETRA}|_)[{LETRA}{DIGITO}_]*)


%%
    /* Padrões e ações. Nesta seção, comentários devem ter um tab antes */

{WS}	{ /* ignora espaços, tabs e '\n' */ } 

"for"   { lexema = yytext; return _FOR; }
"if"    { lexema = yytext; return _IF; }


{ID}    { lexema = yytext; return _ID;}

.       { return *yytext; 
          /* Essa deve ser a última regra. Dessa forma qualquer caractere isolado será retornado pelo seu código ascii. */ }

%%

/* Não coloque nada aqui - a função main é automaticamente incluída na hora de avaliar e dar a nota. */