%{
#include <stdlib.h>
#include <math.h>
#include <map>
#include <vector>
#include <string>
#include <iostream>

using namespace std;

struct Valor {
    bool isNumber;
    double valNum;
    string valStr;
    
    Valor(): isNumber(true), valNum(0), valStr("") {}
    Valor(double valNum): isNumber(true), valNum(valNum), valStr("") {}
    Valor(string valStr): isNumber(false), valNum(0), valStr(valStr) {}
};

enum TOKEN { CDOUBLE = 256, CSTR, ID, PRINT };

map<int,string> nome_tokens = {
  { CDOUBLE, "double" },
  { CSTR, "string" },
  { ID, "identificador" },
  { PRINT, "print" }
};

int linha = 1;
int coluna = 1;
string lexema;

typedef void (*Funcao)();

vector<Valor> pilha;
map<string,Valor> var;

int token;
void erro(string msg);
void remove_escape( string& );  

void casa( int );
void OPE();
void ATR();
void PRT();
void E();
void E_linha();
void T();
void T_linha();
void F();
void G();

%}

/* Definições regulares */

DIGITO  [0-9]
LETRA   [A-Za-z_]
DOUBLE  {DIGITO}+("."{DIGITO}+)?
ID      {LETRA}({LETRA}|{DIGITO})*
STR   \"([^\"\n\\]|(\\\")|\"\"|"\\\\")+\"

%%

"\t"       { coluna += 4; }
" "        { coluna++; }
"\n"     { linha++; coluna = 1; }

"print"   { lexema = yytext; return ( PRINT ); }

{DOUBLE}   { lexema = yytext; return ( CDOUBLE ); }
{STR}     { lexema = yytext; return ( CSTR ); }


{ID}       { lexema = yytext; return ( ID ); }

.          { lexema = yytext; return ( *yytext ); }

%%

void print(string str){
  cout << str << " ";
}

int next_token() {
  return yylex();
}

string nome_token( int token ) {
  if( nome_tokens.find( token ) != nome_tokens.end() )
    return nome_tokens[token];
  else {
    string r;
    
    r = token;
    return r;
  }
}

void casa( int esperado ) {
  if( token == esperado )
    token = next_token();
  else {
      cout << "Esperado " << nome_token( esperado ) 
	   << " , encontrado: " << nome_token( token ) << endl;
    exit( 1 );
  }
}

void erro( string msg ) {
  cout << "=== Erro: " << msg << " ===" <<endl;
  exit( 0 ); 
}

void OPE() {
  switch( token ) {
    case PRINT: 
      PRT();
      casa( ';' );
      OPE();
      break;
    case ID:
    case CSTR:
    case CDOUBLE:
      ATR();
      casa( ';' );
      OPE();
      break; 
  }
}

void ATR() {
// Guardamos o lexema pois a função 'casa' altera o seu valor.
  string temp = lexema; 
  casa( ID );
  print( temp );
  casa( '=' );
  E();
  print( "= ^" );
}

void PRT() {
  casa( PRINT );
  E();
  print( "print #" );
}

void E() {
  T();
  E_linha();
}

void E_linha() {
  switch( token ) {
    case '+' : 
      casa( '+' ); 
      T(); 
      print( "+"); 
      E_linha(); 
      break;
    case '-' : 
      casa( '-' ); 
      T(); 
      print( "-"); 
      E_linha(); 
      break;
  }
}

void T() {
  F();
  T_linha();
}

void T_linha() {
  switch( token ) {
    case '*' : 
      casa( '*' ); 
      F(); print( "*"); 
      T_linha(); 
      break;
    case '/' : 
      casa( '/' ); 
      F(); 
      print( "/"); 
      T_linha(); 
      break;
  }
}

void F() {
  switch( token ) {
    case '-':
      print( "0" );
      casa( '-' );
      F();
      print( "-" );
      break;
    case '+' :
      casa( '+' );
      F();
      break;
    default:
      G();
  }
}

void G() {
  switch( token ) {
    case ID : {
      string temp = lexema;
      casa( ID ); 
      print( temp + " @" ); } 
      break;
    case CSTR : {
      string temp = lexema;
      casa( CSTR ); 
      print( temp );
      break;
    }
    case CDOUBLE : {
      string temp = lexema;
      casa( CDOUBLE ); 
      print( temp ); }
      break;
    case '(': 
      casa( '(' ); E(); casa( ')' ); break;
    default:
      erro( "Operando esperado, encontrado " + lexema );
  }
}

int main() {
  token = next_token();
  OPE();
  return 0;
}
