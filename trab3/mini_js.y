%{
#include <iostream>
#include <string>
#include <vector>
#include <map>

using namespace std;

int linha = 1, coluna = 0; 

struct Atributos {
  vector<string> c; // Código

  int linha = 0, coluna = 0;

  void clear() {
    c.clear();
    linha = 0;
    coluna = 0;
  }
};

enum TipoDecl { Let = 1, Const, Var };

struct Simbolo {
  TipoDecl tipo;
  int linha;
  int coluna;
};

map< string, Simbolo > ts; // Tabela de símbolos

vector<string> declara_var( TipoDecl tipo, string nome, int linha, int coluna );
void checa_simbolo( string nome, bool modificavel );

#define YYSTYPE Atributos

extern "C" int yylex();
int yyparse();
void yyerror(const char *);

vector<string> concatena( vector<string> a, vector<string> b ) {
  a.insert( a.end(), b.begin(), b.end() );
  return a;
}

vector<string> operator+( vector<string> a, vector<string> b ) {
  return concatena( a, b );
}

vector<string> operator+( vector<string> a, string b ) {
  a.push_back( b );
  return a;
}

vector<string> operator+( string a, vector<string> b ) {
  return vector<string>{ a } + b;
}

vector<string> resolve_enderecos( vector<string> entrada ) {
  map<string,int> label;
  vector<string> saida;
  for( int i = 0; i < entrada.size(); i++ ) 
    if( entrada[i][0] == ':' ) 
        label[entrada[i].substr(1)] = saida.size();
    else
      saida.push_back( entrada[i] );
  
  for( int i = 0; i < saida.size(); i++ ) 
    if( label.count( saida[i] ) > 0 )
        saida[i] = to_string(label[saida[i]]);
    
  return saida;
}

string gera_label( string prefixo ) {
  static int n = 0;
  return prefixo + "_" + to_string( ++n ) + ":";
}

void print( vector<string> codigo ) {
  for( string s : codigo )
    cout << s << " ";
    
  cout << endl;  
}
%}

  // Definição dos tokens

%token _ID _IF _ELSE _LET _CONST _VAR _PRINT _FOR _WHILE
%token _CDOUBLE _CSTRING _CINT
%token _AND _OR _ME_IG _MA_IG _DIF _IGUAL
%token _MAIS_IGUAL _MAIS_MAIS

%right '='
%nonassoc '<' '>'
%left '+' '-'
%left '*' '/' '%'

%left '['
%left '.'


%%

S : COMANDOS                  { print( resolve_enderecos( $1.c + "." ) ); }
  ;

COMANDOS : COMANDOS COMANDO   { $$.c = $1.c + $2.c; };
     |                        { $$.clear(); }
     ;
     
COMANDO : COMANDO_LET ';'
    | COMANDO_VAR ';'
    | COMANDO_CONST ';'
    | COMANDO_IF
    | _PRINT EXPR ';'         { $$.c = $2.c + "println" + "#"; }
    | COMANDO_FOR ';'
    | COMANDO_WHILE ';'
    | EXPR ';'                { $$.c = $1.c + "^"; };
    | '{' COMANDOS '}'        { $$.c = $2.c; }
    ;
 
COMANDO_FOR : _FOR '(' EXP_PRIMARIAS ';' EXPR ';' EXPR ')' COMANDO 
        { string lbl_fim_for = gera_label( "fim_for" );
          string lbl_condicao_for = gera_label( "condicao_for" );
          string lbl_comando_for = gera_label( "comando_for" );
          string definicao_lbl_fim_for = ":" + lbl_fim_for;
          string definicao_lbl_condicao_for = ":" + lbl_condicao_for;
          string definicao_lbl_comando_for = ":" + lbl_comando_for;
          
          $$.c = $3.c + definicao_lbl_condicao_for +
                 $5.c + lbl_comando_for + "?" + lbl_fim_for + "#" +
                 definicao_lbl_comando_for + $9.c + 
                 $7.c + "^" + lbl_condicao_for + "#" +
                 definicao_lbl_fim_for;
        }
        ;

COMANDO_WHILE : _WHILE '(' EXPR ')' COMANDO  
        { string lbl_fim_while = gera_label( "fim_while" );
          string lbl_condicao_while = gera_label( "condicao_while" );
          string lbl_comando_while = gera_label( "comando_while" );
          string definicao_lbl_fim_while = ":" + lbl_fim_while;
          string definicao_lbl_condicao_while = ":" + lbl_condicao_while;
          string definicao_lbl_comando_while = ":" + lbl_comando_while;
          
          $$.c = definicao_lbl_condicao_while +
                 $3.c + lbl_comando_while + "?" + lbl_fim_while + "#" +
                 definicao_lbl_comando_while + $5.c + 
                 lbl_condicao_while + "#" +
                 definicao_lbl_fim_while;
        }

EXP_PRIMARIAS : COMANDO_LET 
       | COMANDO_VAR
       | COMANDO_CONST
       | EXPR                 { $$.c = $1.c + "^"; }
       ;

COMANDO_LET : _LET VARIAVEIS_LET { $$.c = $2.c; }
        ;

VARIAVEIS_LET : VARIAVEL_LET ',' VARIAVEIS_LET { $$.c = $1.c + $3.c; } 
         | VARIAVEL_LET
         ;

VARIAVEL_LET : _ID  
          { $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ); }
        | _ID '=' EXPR
          { 
            $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) + 
                   $1.c + $3.c + "=" + "^"; }
        | _ID '=' '{' '}'
          {
            $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) + 
                   $1.c + "{}" + "=" + "^";
          }
        | _ID '=' '[' ']'
          {
            $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) + 
                   $1.c + "[]" + "=" + "^";
          }
        ;
  
COMANDO_VAR : _VAR VARIAVEIS_VAR { $$.c = $2.c; }
        ;
        
VARIAVEIS_VAR : VARIAVEL_VAR ',' VARIAVEIS_VAR { $$.c = $1.c + $3.c; } 
         | VARIAVEL_VAR
         ;

VARIAVEL_VAR : _ID  
          { $$.c = declara_var( Var, $1.c[0], $1.linha, $1.coluna ); }
        | _ID '=' EXPR
          {  $$.c = declara_var( Var, $1.c[0], $1.linha, $1.coluna ) + 
                    $1.c + $3.c + "=" + "^"; }
        ;
  
COMANDO_CONST: _CONST VARIAVEIS_CONST { $$.c = $2.c; }
         ;
  
VARIAVEIS_CONST : VARIAVEL_CONST ',' VARIAVEIS_CONST { $$.c = $1.c + $3.c; } 
           | VARIAVEL_CONST
           ;

VARIAVEL_CONST : _ID '=' EXPR
            { $$.c = declara_var( Const, $1.c[0], $1.linha, $1.coluna ) + 
                     $1.c + $3.c + "=" + "^"; }
          ;
  
COMANDO_IF : _IF '(' EXPR ')' COMANDO _ELSE COMANDO
         { string lbl_true = gera_label( "lbl_true" );
           string lbl_fim_if = gera_label( "lbl_fim_if" );
           string definicao_lbl_true = ":" + lbl_true;
           string definicao_lbl_fim_if = ":" + lbl_fim_if;
                    
            $$.c = $3.c +                       // Codigo da expressão
                   lbl_true + "?" +             // Código do IF
                   $7.c + lbl_fim_if + "#" +    // Código do False
                   definicao_lbl_true + $5.c +  // Código do True
                   definicao_lbl_fim_if         // Fim do IF
                   ;
         }
         | _IF '(' EXPR ')' COMANDO
         { string lbl_true = gera_label( "lbl_true" );
           string lbl_fim_if = gera_label( "lbl_fim_if" );
           string definicao_lbl_true = ":" + lbl_true;
           string definicao_lbl_fim_if = ":" + lbl_fim_if;
                    
            $$.c = $3.c +                       // Codigo da expressão
                   lbl_true + "?" +             // Código do IF
                   lbl_fim_if + "#" +           // Código do False
                   definicao_lbl_true + $5.c +  // Código do True
                   definicao_lbl_fim_if         // Fim do IF
                   ;
         }
       ;
        
LVALUE : _ID 
       ;
       
LVALUEPROP : EXPR '[' EXPR ']' { $$.c = $1.c + $3.c; }
           | EXPR '.' _ID      { $$.c = $1.c + $3.c; }
           ;

LISTA : '[' LISTA_ELEM ']'          { $$.c = $2.c; }
      ;

LISTA_ELEM : EXPR ',' LISTA_ELEM    { $$.c = $1.c + $3.c; }
           | EXPR
           | { $$.clear(); }
          ;

EXPR : LVALUE '=' '{' '}'           { checa_simbolo( $1.c[0], true ); $$.c = $1.c + "{}" + "="; }
    | LVALUE '=' EXPR               { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "="; }
    | LVALUE _MAIS_MAIS             { checa_simbolo( $1.c[0], true ); $$.c = $1.c + "@" + $1.c + $1.c + "@" + "1" + "+" + "=" + "^"; }
    | LVALUE _IGUAL EXPR            { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "=="; }
    | LVALUE _MAIS_IGUAL EXPR       { checa_simbolo( $1.c[0], true ); $$.c = $1.c + "@" + $1.c + $1.c + "@" + $3.c + "+" + "=" + "^";}

    | LVALUEPROP '=' '[' ']'        { checa_simbolo( $1.c[0], true ); $$.c = $1.c + "[]" + "[=]"; }
    | LVALUEPROP '=' EXPR   	      { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "[=]"; }
    | LVALUEPROP _MAIS_IGUAL EXPR   { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $1.c +  "[@]" + $3.c +  "+" + "[=]";}

    | EXPR '<' EXPR                 { $$.c = $1.c + $3.c + $2.c; }
    | EXPR '>' EXPR                 { $$.c = $1.c + $3.c + $2.c; }
    | EXPR '+' EXPR                 { $$.c = $1.c + $3.c + $2.c; }
    | EXPR '-' EXPR                 { $$.c = $1.c + $3.c + $2.c; }
    | EXPR '*' EXPR                 { $$.c = $1.c + $3.c + $2.c; }
    | EXPR '/' EXPR                 { $$.c = $1.c + $3.c + $2.c; }
    | EXPR '%' EXPR                 { $$.c = $1.c + $3.c + $2.c; }
    
    | _CDOUBLE
    | _CINT
    | '-' _CINT                     { $$.c = "0" + $2.c + "-"; }
    | LVALUE                        { checa_simbolo( $1.c[0], false ); $$.c = $1.c + "@"; } 
    | LVALUEPROP                    { $$.c = $1.c + "[@]"; }
    | '(' EXPR ')'                  { $$.c = $2.c; }
    | '(' '{' '}' ')'               { $$.c = vector<string>{"{}"}; }
    | LISTA
    | _CSTRING
  ;
  
  
%%

#include "lex.yy.c"

vector<string> declara_var( TipoDecl tipo, string nome, int linha, int coluna ) {
  // Debug:
  // cerr << "insere_simbolo( " << tipo << ", " << nome 
  //      << ", " << linha << ", " << coluna << ")" << endl;
       
  if( ts.count( nome ) == 0 ) {
    ts[nome] = Simbolo{ tipo, linha, coluna };
    return vector<string>{ nome, "&" };
  }
  else if( tipo == Var && ts[nome].tipo == Var ) {
    ts[nome] = Simbolo{ tipo, linha, coluna };
    return vector<string>{};
  } 
  else {
    cerr << "Erro: a variável '" << nome << "' ja foi declarada na linha " << ts[nome].linha << "." << endl;
    exit( 1 );     
  }
}

void checa_simbolo( string nome, bool modificavel ) {
  if( ts.count( nome ) > 0 ) {
    if( modificavel && ts[nome].tipo == Const ) {
      cerr << "Variavel '" << nome << "' não pode ser modificada." << endl;
      exit( 1 );     
    }
  }
  else {
    cerr << "Erro: a variável '" << nome << "' não foi declarada." << endl;
    exit( 1 );     
  }
}

void yyerror( const char* st ) {
   cerr << st << endl; 
   cerr << "Proximo a: " << yytext << endl;
   exit( 1 );
}

int main( int argc, char* argv[] ) {
  yyparse();
  
  return 0;
}