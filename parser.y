%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

typedef struct ASTNode {
    char* type;
    char* value;
    struct ASTNode* left;
    struct ASTNode* right;
} ASTNode;

ASTNode* make_node(char* type, char* value, ASTNode* left, ASTNode* right) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = strdup(type);
    node->value = strdup(value);
    node->left = left;
    node->right = right;
    return node;
}

ASTNode* root;

// Генерація JSON для візуалізації (D3.js)
void export_json(ASTNode* node, FILE* f) {
    if(!node) { fprintf(f, "null"); return; }
    fprintf(f, "{\"name\": \"%s%s%s\"", node->type, strlen(node->value)>0 ? "\\n" : "", node->value);
    if(node->left || node->right) {
        fprintf(f, ", \"children\": [");
        if(node->left) export_json(node->left, f);
        if(node->left && node->right) fprintf(f, ", ");
        if(node->right) export_json(node->right, f);
        fprintf(f, "]");
    }
    fprintf(f, "}");
}

// Семантика: Прості обчислення (Evaluation)
int eval_ast(ASTNode* node) {
    if(!node) return 0;
    if(strcmp(node->type, "Number") == 0) return atoi(node->value);
    if(strcmp(node->type, "Add") == 0) return eval_ast(node->left) + eval_ast(node->right);
    if(strcmp(node->type, "Sub") == 0) return eval_ast(node->left) - eval_ast(node->right);
    if(strcmp(node->type, "Mul") == 0) return eval_ast(node->left) * eval_ast(node->right);
    return 0; 
}

//Трансляція: Генерація коду з AST
void generate_code(ASTNode* node) {
    if(!node) return;
    if(strcmp(node->type, "Sequence") == 0) {
        generate_code(node->left);
        generate_code(node->right);
    } else if(strcmp(node->type, "Assign") == 0) {
        printf("    %s = ", node->left->value);
        generate_code(node->right);
        printf(";\n");
    } else if(strcmp(node->type, "If") == 0) {
        printf("    if (");
        generate_code(node->left);
        printf(") {\n    ");
        generate_code(node->right);
        printf("    }\n");
    } else if(strcmp(node->type, "Number") == 0 || strcmp(node->type, "Var") == 0) {
        printf("%s", node->value);
    } else { 
        generate_code(node->left);
        if(strcmp(node->type, "Add") == 0) printf(" + ");
        if(strcmp(node->type, "Sub") == 0) printf(" - ");
        if(strcmp(node->type, "Mul") == 0) printf(" * ");
        generate_code(node->right);
    }
}
%}

%union {
    int num;
    char* str;
    struct ASTNode* node;
}

%token <str> ID
%token <num> NUM
%token IF INT ASSIGN SEMI LPAREN RPAREN LBRACE RBRACE
%token PLUS MINUS MUL DIV

%type <node> program stmts stmt expr term

%left PLUS MINUS
%left MUL DIV

%%
program:
    stmts { root = $1; }
    ;

stmts:
    stmt stmts { $$ = make_node("Sequence", "", $1, $2); }
    | /* порожньо */ { $$ = NULL; }
    ;

stmt:
    ID ASSIGN expr SEMI { $$ = make_node("Assign", "=", make_node("Var", $1, NULL, NULL), $3); }
    | IF LPAREN expr RPAREN LBRACE stmts RBRACE { $$ = make_node("If", "", $3, $6); }
    ;

expr:
    expr PLUS expr  { $$ = make_node("Add", "+", $1, $3); }
    | expr MINUS expr { $$ = make_node("Sub", "-", $1, $3); }
    | expr MUL expr   { $$ = make_node("Mul", "*", $1, $3); }
    | term            { $$ = $1; }
    ;

term:
    ID { $$ = make_node("Var", $1, NULL, NULL); }
    | NUM { 
        char buf[16];
        sprintf(buf, "%d", $1);
        $$ = make_node("Number", buf, NULL, NULL); 
      }
    | LPAREN expr RPAREN { $$ = $2; }
    ;
%%

void yyerror(const char *s) {
    fprintf(stderr, "Помилка синтаксису: %s\n", s);
}

int main(void) {
    printf("Введіть код мовою Mini-C (Ctrl+D для завершення):\n");
    yyparse();
    
    if (root) {
        printf("\n--- РЕЗУЛЬТАТ ОБЧИСЛЕНЬ (Семантика першого виразу) ---\n");
        if(root->left && strcmp(root->left->type, "Assign") == 0) {
            printf("Результат виразу для %s: %d\n", root->left->left->value, eval_ast(root->left->right));
        }

        printf("\n--- ЗГЕНЕРОВАНИЙ КОД (Трансляція з AST) ---\n");
        printf("int main() {\n");
        generate_code(root);
        printf("    return 0;\n}\n");

        FILE* f = fopen("ast.json", "w");
        export_json(root, f);
        fclose(f);
        printf("\nAST експортовано у 'ast.json' для візуалізації.\n");
    }
    return 0;
}
