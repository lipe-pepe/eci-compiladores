%{
int token( int tk );
%}

DIGITO  	    [0-9]
LETRA   	[A-Za-z_]
INT	    {DIGITO}+
DOUBLE  {DIGITO}+"."{DIGITO}+([Ee][+\-]?{DIGITO}+)?
ID      {LETRA}({LETRA}|{DIGITO})*
STRING   \"([^\"\n\\]|(\\\")|\"\"|"\\\\")+\"

%%

"\t"       { coluna += 4; }
" "        { coluna++; }
"\n"	   { linha++; coluna = 0; }

{DOUBLE}   { return token( CDOUBLE ); }
{INT}	   { return token( CINT ); } 

"&&"	   { return token( AND ); }
"||"	   { return token( OR ); }
"<="	   { return token( ME_IG ); }
">="	   { return token( MA_IG ); }
"!="	   { return token( DIF ); }
"=="	   { return token( IGUAL ); }

"+="       { return token( MAIS_IGUAL ); }
"++"       { return token( MAIS_MAIS ); }

"let"      { return token( LET ); }
"const"    { return token( CONST ); }
"var"      { return token( VAR ); }
"if"       { return token( IF ); }
"else"     { return token( ELSE ); }
"print"    { return token( PRINT ); }
"for"      { return token( FOR ); }

{ID}       { return token( ID ); }
{STRING}      { return token( CSTRING ); } 

.          { return token( *yytext ); }

%%

int token( int tk ) {  
  yylval.c = vector<string>{ yytext };
  coluna += strlen( yytext ); 
  
  yylval.linha = linha;
  yylval.coluna = coluna;

  return tk;
} 