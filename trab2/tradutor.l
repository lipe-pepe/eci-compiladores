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
void A();
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

void replace_all( string& subject, const  string& search, const  string& replace ) {
    size_t pos = 0;
    while ((pos = subject.find(search, pos)) != string::npos) {
         subject.replace(pos, search.length(), replace);
         pos += replace.length();
    }
}

void remove_escape( string& st ) {
    st = st.substr( 1, lexema.size() - 2 );
    replace_all( st, "\"\"", "\"" );
    replace_all( st, "\\\"", "\"" );
    replace_all( st, "\\\\", "\\" );
}

inline void push( Valor valor ) {
  pilha.push_back( valor );
}

inline void push( double valor ) {
  push( Valor( valor ) );
}

inline void push( string valor ) {
  push( Valor( valor ) );
}

inline Valor pop() {
  if( pilha.size() <= 0 )
    erro( "Tentou desempilhar mas a pilha está vazia" );
  
  Valor temp = pilha.back();
  pilha.pop_back();
  
  return temp;
}

inline double pop_number() {
  Valor temp = pop();
  
  if( !temp.isNumber )
    erro( "Esperado um operando numérico, encontrado \"" + temp.valStr + "\"" );
    
  return temp.valNum;
}

inline string pop_string() {
  Valor temp = pop();
  
  if( temp.isNumber )
    erro( "Esperado um operando string, encontrado " + to_string( temp.valNum ) );
    
  return temp.valStr;
}

inline ostream& operator << ( ostream& o, const Valor& valor ) {
  if( valor.isNumber )
      o << "Num: " << valor.valNum;
    else
      o << "Str: " << valor.valStr;
      
  return o;
}

inline ostream& operator << ( ostream& o, const map<string,Valor>& v ) {
  for( auto x : v ) 
    cout << "|" << x.first << " ==> " << x.second << "|" << endl;
  return o;
}

inline ostream& operator << ( ostream& o, const vector<Valor>& v ) {
  for( unsigned int i = 0; i < 10 && i < v.size(); i++ ) 
    cout << "|" << v[i] << "|" << endl;
  return o;
}

inline void erro( string msg ) {
  cout << "=== Erro: " << msg << " ===" <<endl;
  cout << "=== Vars ===" << endl << var;
  cout << "=== Pilha ===" << endl << pilha;
  exit( 0 ); 
}

double fatorial( int n ) {
  if( n < 0 ) 
    erro( "Fatorial somente está definido para n >= 0" );
  else if( n == 0 )
    return 1;
  else
    return n * fatorial( n - 1 );
}

map<string, Funcao> func = {
  { "max", []() { double b = pop_number();
                  double a = pop_number();
                  push( a > b ? a : b ); } },
  { "power", []() { double b = pop_number();
                    double a = pop_number();
                    push( pow( a, b ) ); } },
  { "print", []() { cout << pop() << endl; } }, 
  { "fat", []() { push( fatorial( pop_number() ) ); } }, 
  { "dtos", []() { push( to_string( pop_number() ) ); } }
};

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

void OPE() {
  switch( token ) {
    case PRINT: 
      PRT();
      casa( ';' );
      break;
  }
}

void A() {
// Guardamos o lexema pois a função 'casa' altera o seu valor.
  string temp = lexema; 
  casa( ID );
  print( temp );
  casa( '=' );
  E();
  print( "=" );
}

void PRT() {
  casa( PRINT );
  E();
  print( "print" );
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
    case ID: {
      string temp = lexema;
      casa( ID ); 
      print( temp ); }
      break;
  }
}

void G() {
  switch( token ) {
    case ID : {
      string temp = lexema;
      casa( ID ); 
      print( temp + "@" ); } 
      break;
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
    int token = yylex();
    auto p = func.begin();
    string nome;
    double op1, op2;
    Valor val;
    
    cout << "=== Console ===" << endl;
    
    while( token != 0 ) {
        switch( token ) {
            case PRINT:
                push( lexema );
                break;
            case CDOUBLE:
                push( stod( lexema ) ); 
                break;
                
            case ID:
                push( lexema );
                break;
                
            case CSTR:
                push( lexema );
                break;
                
            case '#': 
                if( (p = func.find( nome = pop_string() )) == func.end() ) {
                erro( "Funcao não definida: " + nome );
                }
                
                (p->second)();
                break;
                
            case '@':
                push( var[pop_string()] );
                break;
                
            case '=':
                val = pop();
                var[pop_string()] = val;
                push( val );
                break;
                
            case '^' :
              pop();
            break;    
                
            case '+':
                val = pop();
                
                if( val.isNumber ) 
                push( pop_number() + val.valNum );
                else  
                push( pop_string() + val.valStr );
                
                break;
                
            case '-':
                op2 = pop_number();
                op1 = pop_number();
                
                push( op1 - op2 ); 
                break;
                
            case '/':
                op2 = pop_number();
                op1 = pop_number();
                
                push( op1 / op2 ); 
                break;
                
            case '*':
                op2 = pop_number();
                op1 = pop_number();
                
                push( op1 * op2 ); 
                break;  
              
            default:
                erro( "Instrução ou operador inválido: " + lexema );
        }
        
        token = yylex();
    }
    
    cout << "=== Vars ===" << endl << var;
    cout << "=== Pilha ===" << endl << pilha;
    
    return 0;
}
