%{
int token( int tk );
%}

DIGITO  	    [0-9]
LETRA   	[A-Za-z_]
INT	    {DIGITO}+
DOUBLE  {DIGITO}+"."{DIGITO}+([Ee][+\-]?{DIGITO}+)?
ID      {LETRA}({LETRA}|{DIGITO})*
STRING   \"([^\"\n\\]|(\\\")|\"\"|"\\\\")+\"
STRING2   \'([^\'\n\\]|(\\\')|\'\'|\'\\\\\')+\'


%%

"\t"       { coluna += 4; }
" "        { coluna++; }
"\n"	   { linha++; coluna = 0; }

{DOUBLE}   { return token( _CDOUBLE ); }
{INT}	   { return token( _CINT ); } 

"&&"	   { return token( _AND ); }
"||"	   { return token( _OR ); }
"<="	   { return token( _ME_IG ); }
">="	   { return token( _MA_IG ); }
"!="	   { return token( _DIF ); }
"=="	   { return token( _IGUAL ); }

"+="       { return token( _MAIS_IGUAL ); }
"++"       { return token( _MAIS_MAIS ); }

"let"      { return token( _LET ); }
"const"    { return token( _CONST ); }
"var"      { return token( _VAR ); }
"if"       { return token( _IF ); }
"else"     { return token( _ELSE ); }
"print"    { return token( _PRINT ); }
"for"      { return token( _FOR ); }

{ID}       { return token( _ID ); }
{STRING}      { return token( _CSTRING ); } 
{STRING2}      { return token( _CSTRING ); }

.          { return token( *yytext ); }

%%

int token( int tk ) {  
  yylval.c = vector<string>{ yytext };
  coluna += strlen( yytext ); 
  
  yylval.linha = linha;
  yylval.coluna = coluna;

  return tk;
} 