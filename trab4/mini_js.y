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

  // Só para argumentos e parâmetros
  int contador = 0;     
  
  // Só para valor default de argumento        
  vector<string> valor_default; 

  void clear() {
    c.clear();
    valor_default.clear();
    linha = 0;
    coluna = 0;
    contador = 0;
  }
};

enum TipoDecl { Let = 1, Const, Var };
map<TipoDecl, string> nomeTipoDecl = { 
  { Let, "let" }, 
  { Const, "const" }, 
  { Var, "var" }
};

struct Simbolo {
  TipoDecl tipo;
  int linha;
  int coluna;
};

int in_func = 0;

// Tabela de símbolos - agora é uma pilha
vector< map< string, Simbolo > > ts = { map< string, Simbolo >{} }; 
vector<string> funcoes;

vector<string> declara_var( TipoDecl tipo, string nome, int linha, int coluna );
void checa_simbolo( string nome, bool modificavel );

#define YYSTYPE Atributos

extern "C" int yylex();
int yyparse();
void yyerror(const char *);

string trim(string str)   {
    size_t pos_inicial = str.find('{');
    size_t pos_final = str.find('}', pos_inicial);
    return str.substr(pos_inicial + 1, pos_final - pos_inicial - 1);
}

vector<string> tokeniza(string line){
	vector<string> c;
	string intr = "";

  for(auto cr : line){

    if(cr == ' '){
      c.push_back(intr);
      intr = "";
    } else {
      intr += cr;
    }
  }
  c.push_back(intr);
	return c;
}

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

%token _ID _IF _ELSE _LET _CONST _VAR _PRINT _FOR _WHILE _FUNCAO _ASM _RETURN
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

S : COMANDOS                  { print( resolve_enderecos( $1.c + "." + funcoes ) ); }
  ;

COMANDOS : COMANDOS COMANDO   { $$.c = $1.c + $2.c; };
     |                        { $$.clear(); }
     ;
     
COMANDO : COMANDO_LET ';'
    | COMANDO_VAR ';'
    | COMANDO_CONST ';'
    | COMANDO_IF
    | COMANDO_FUNCAO
    | EXPR _ASM ';' 	        { $$.c = $1.c + $2.c + "^"; }
    | _RETURN EXPR ';' 	      { $$.c = $2.c + "'&retorno'" + "@" + "~"; }
    | _PRINT EXPR ';'         { $$.c = $2.c + "println" + "#"; }
    | COMANDO_FOR ';'
    | COMANDO_WHILE ';'
    | EXPR ';'                { $$.c = $1.c + "^"; };
    | '{' EMPILHA_TS COMANDOS '}'
      { ts.pop_back();
        $$.c = "<{" + $3.c + "}>"; }
    | ';'                    { $$.clear(); }
    ;
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

EMPILHA_TS : { ts.push_back( map< string, Simbolo >{} ); } 
           ;
    
COMANDO_FUNCAO : _FUNCAO _ID { declara_var( Var, $2.c[0], $2.linha, $2.coluna ); } 
             '(' EMPILHA_TS LISTA_PARAMETROS ')' '{' COMANDOS '}'
           { 
             string lbl_endereco_funcao = gera_label( "func_" + $2.c[0] );
             string definicao_lbl_endereco_funcao = ":" + lbl_endereco_funcao;
             
             $$.c = $2.c + "&" + $2.c + "{}"  + "=" + "'&funcao'" +
                    lbl_endereco_funcao + "[=]" + "^";
             funcoes = funcoes + definicao_lbl_endereco_funcao + $6.c + $9.c +
                       "undefined" + "@" + "'&retorno'" + "@"+ "~";
             ts.pop_back(); 
           }
         ;

LISTA_PARAMETROS : PARAMETROS
           | { $$.clear();}
           ;
           
PARAMETROS : PARAMETROS ',' PARAMETRO  
       { // a & a arguments @ 0 [@] = ^ 
         $$.c = $1.c + $3.c + "&" + $3.c + "arguments" + "@" + to_string( $1.contador )
                + "[@]" + "=" + "^"; 
                
         if( $3.valor_default.size() > 0 ) {
           string lbl_true = gera_label( "lbl_true" );
           string lbl_fim_if = gera_label( "lbl_fim_if" );
           string definicao_lbl_true = ":" + lbl_true;
           string definicao_lbl_fim_if = ":" + lbl_fim_if;
          
           $$.c = $$.c + $3.c + "@" +  "undefined" + "@" + "!=" +
                 lbl_true + "?" + $3.c + $3.valor_default + "=" + "^" +
                 lbl_fim_if + "#" +
                 definicao_lbl_true + 
                 definicao_lbl_fim_if;
         }
         $$.contador++; 
       }
     | PARAMETRO 
       { // a & a arguments @ 0 [@] = ^ 
         $$.c = $1.c + "&" + $1.c + "arguments" + "@" + "0" + "[@]" + "=" + "^"; 
                
         if( $1.valor_default.size() > 0 ) {
           string lbl_true = gera_label( "lbl_true" );
           string lbl_fim_if = gera_label( "lbl_fim_if" );
           string definicao_lbl_true = ":" + lbl_true;
           string definicao_lbl_fim_if = ":" + lbl_fim_if;
           $$.c = $$.c + $1.c + "@" +  "undefined" + "@" + "!=" +
                 lbl_true + "?" + $1.c + $1.valor_default + "=" + "^" +
                 lbl_fim_if + "#" +
                 definicao_lbl_true + 
                 definicao_lbl_fim_if;
         }
         $$.contador = $1.contador; 
       }
     ;
     
PARAMETRO : _ID 
      { $$.c = $1.c;      
        $$.contador = 1;
        $$.valor_default.clear();
        declara_var( Let, $1.c[0], $1.linha, $1.coluna ); 
      }
    | _ID '=' EXPR
      { // Código do IF
        $$.c = $1.c;
        $$.contador = 1;
        $$.valor_default = $3.c;         
        declara_var( Let, $1.c[0], $1.linha, $1.coluna ); 
      }
    ;
             
ARGUMENTOS : EXPR               { $$.c = $1.c; $$.contador = 1; }
      | ARGUMENTOS ',' EXPR     { $$.c = $1.c + $3.c; $$.contador = $1.contador + 1; }
      | { $$.clear(); }
     ;

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

    | EXPR '(' ARGUMENTOS ')' { $$.c = $3.c + to_string( $3.contador ) + $1.c + "$"; }
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
//  cerr << "insere_simbolo( " << tipo << ", " << nome 
//       << ", " << linha << ", " << coluna << ")" << endl;
       
  auto& topo = ts.back();    
       
  if( topo.count( nome ) == 0 ) {
    topo[nome] = Simbolo{ tipo, linha, coluna };
    return vector<string>{ nome, "&" };
  }
  else if( tipo == Var && topo[nome].tipo == Var ) {
    topo[nome] = Simbolo{ tipo, linha, coluna };
    return vector<string>{};
  } 
  else {
    cerr << "Erro: a variável '" << nome << "' já foi declarada na linha " << topo[nome].linha << "." << endl;
    exit( 1 );     
  }
}

void checa_simbolo( string nome, bool modificavel ) {
  for( int i = ts.size() - 1; i >= 0; i-- ) {  
    auto& atual = ts[i];
    
    if( atual.count( nome ) > 0 ) {
      if( modificavel && atual[nome].tipo == Const ) {
        cerr << "Variavel '" << nome << "' não pode ser modificada." << endl;
        exit( 1 );     
      }
      else 
        return;
    }
  } 
}

void yyerror( const char* st ) {
   cerr << st << endl; 
   cerr << "Proximo a: " << yytext << endl;
   exit( 1 );
}

int main( int PARAMETROc, char* PARAMETROv[] ) {
  yyparse();
  
  return 0;
}