#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdlib.h>
#define NOB_IMPLEMENTATION
#include "nob.h"
#define ARENA_IMPLEMENTATION
#include "arena.h"

static Arena a = {0};
/*
//================================================================================\\
//CONSTANTS_START
\\================================================================================//
*/
// Unsure if this should be here
#define INDENT "  "
/*
//================================================================================\\
//CONSTANTS_END
\\================================================================================//
*/

/*
//================================================================================\\
//UTILS_START
\\================================================================================//
*/
typedef enum {
    LEXER_LET = 0,
    LEXER_FN,
    LEXER_FOR,
    LEXER_WHILE,
    LEXER_RETURN,
    LEXER_IF,
    LEXER_ELSE,
    LEXER_TRUE,
    LEXER_FALSE,
    LEXER_MOD,
    LEXER_PRINT,
    LEXER_SHELL,
    LEXER_IDENT,
    LEXER_STRING,
    LEXER_DOT,
    LEXER_EQUALS,
    LEXER_SAME,
    LEXER_LT,
    LEXER_GT,
    LEXER_DOTDOT,
    LEXER_INT64,
    LEXER_FLOAT64,
    LEXER_PLUS,
    LEXER_MINUS,
    LEXER_MULTIPLY,
    LEXER_DIVIDE,
    LEXER_BSLASH,
    LEXER_LPAREN,
    LEXER_RPAREN,
    LEXER_LBRACE,
    LEXER_RBRACE,
    LEXER_LBLOCK,
    LEXER_RBLOCK,
    LEXER_SQUOTE,
    LEXER_QUESTION_MARK,
    LEXER_BANG,
    LEXER_COMMA,
    LEXER_NEWLINE,
    LEXER_EOF,
} Lexer_Kind;

char *to_string_kind(Lexer_Kind kind) {
    if      (kind == LEXER_LET)           return "\"LET\": let";
    else if (kind == LEXER_FN)            return "\"FN\": fn";
    else if (kind == LEXER_LT)            return "\"LT\": <";
    else if (kind == LEXER_GT)            return "\"GT\": >";
    else if (kind == LEXER_RETURN)        return "\"RETURN\": return";
    else if (kind == LEXER_FOR)           return "\"FOR\": for";
    else if (kind == LEXER_WHILE)         return "\"WHILE\": while";
    else if (kind == LEXER_IF)            return "\"IF\": if";
    else if (kind == LEXER_ELSE)          return "\"ELSE\": else";
    else if (kind == LEXER_TRUE)          return "\"TRUE\": true";
    else if (kind == LEXER_FALSE)         return "\"FALSE\": false";
    else if (kind == LEXER_PRINT)         return "\"PRINT\"";
    else if (kind == LEXER_SHELL)         return "\"SHELL\"";
    else if (kind == LEXER_IDENT)         return "\"IDENT\"";
    else if (kind == LEXER_DOT)           return "\"DOT\": .";
    else if (kind == LEXER_DOTDOT)        return "\"DOTDOT\": ..";
    else if (kind == LEXER_EQUALS)        return "\"EQUALS\": = ";
    else if (kind == LEXER_SAME)          return "\"SAME\": ==";
    else if (kind == LEXER_INT64)         return "\"INT64\"";
    else if (kind == LEXER_FLOAT64)       return "\"FLOAT64\"";
    else if (kind == LEXER_PLUS)          return "\"PLUS\": +";
    else if (kind == LEXER_MINUS)         return "\"MINUS\": -";
    else if (kind == LEXER_MOD)           return "\"MOD\": %";
    else if (kind == LEXER_MULTIPLY)      return "\"MULTIPLY\": *";
    else if (kind == LEXER_DIVIDE)        return "\"DIVIDE\": /";
    else if (kind == LEXER_BSLASH)        return "\"BSLASH\": \\";
    else if (kind == LEXER_LPAREN)        return "\"LPAREN\": (";
    else if (kind == LEXER_RPAREN)        return "\"RPAREN\": )";
    else if (kind == LEXER_LBRACE)        return "\"LBRACE\": {";
    else if (kind == LEXER_RBRACE)        return "\"RBRACE\": }";
    else if (kind == LEXER_LBLOCK)        return "\"LBLOCK: [\"";
    else if (kind == LEXER_RBLOCK)        return "\"RBLOCK\": ]";
    else if (kind == LEXER_SQUOTE)        return "\"SQUOTE\"";
    else if (kind == LEXER_STRING)        return "\"STRING\"";
    else if (kind == LEXER_QUESTION_MARK) return "\"QUESTION_MARK\"";
    else if (kind == LEXER_BANG)          return "\"BANG\"";
    else if (kind == LEXER_COMMA)         return "\"COMMA\"";
    else if (kind == LEXER_NEWLINE)       return "\"NEWLINE\"";
    else if (kind == LEXER_EOF)           return "\"EOF\"";

    assert(false && "\"UNREACHABLE");
    return "\"INVALID";
}

Lexer_Kind keyword_or_identifier(char* literal) {
    if      (strcmp(literal, "let")    == 0 ) return LEXER_LET;
    else if (strcmp(literal, "fn")     == 0 ) return LEXER_FN;
    else if (strcmp(literal, "for")    == 0 ) return LEXER_FOR;
    else if (strcmp(literal, "while")  == 0 ) return LEXER_WHILE;
    else if (strcmp(literal, "return") == 0 ) return LEXER_RETURN;
    else if (strcmp(literal, "print")  == 0 ) return LEXER_PRINT;
    else if (strcmp(literal, "if")     == 0 ) return LEXER_IF;
    else if (strcmp(literal, "else")   == 0 ) return LEXER_ELSE;
    else if (strcmp(literal, "true")   == 0 ) return LEXER_TRUE;
    else if (strcmp(literal, "false")  == 0 ) return LEXER_FALSE;
    else if (strcmp(literal, "shell")  == 0 ) return LEXER_SHELL;

    return LEXER_IDENT;
}

typedef struct {
    int row;
    int col;
    char * file_path;
} Position;

typedef struct {
    char* literal;
    Lexer_Kind kind;
    Position pos;
} Token;

typedef struct {
    Token *items;
    size_t count;
    size_t capacity;
} Tokens;


typedef struct {
    size_t curr;
    size_t next;
    Position pos;
    char * text;
} Lexer;

                                                                                  


typedef enum {
	Debug   = 0,
	Info    = 10,
	Warning = 20,
	Error   = 30,
	Fatal   = 40,
} Logger_Level;


void sb_pad_left (String_Builder *sb, int indent) {
    for (int i = 0; i < indent; ++i) {
        sb_appendf(sb,"%s", INDENT);
    }
}

char *to_string_pos(Position pos, int indent){ 
    String_Builder sb = {0};
    sb_pad_left(&sb, indent);

    sb_appendf(&sb,"%s", INDENT);
    sb_appendf(&sb ,"%s(%d:%d)", pos.file_path, pos.row, pos.col) ;
    sb_append_null(&sb);

    return arena_strdup(&a, sb.items);
}

char *to_string_token(Token token, int indent) { 
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Token(\n");

    sb_pad_left(&sb, indent + 1);
    sb_appendf(&sb, "literal: %s,\n", token.literal);

    sb_pad_left(&sb, indent + 1);
    sb_appendf(&sb, "kind: %s,\n", to_string_kind(token.kind));

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb,"position: \n");
    sb_appendf(&sb,"%s\n", to_string_pos(token.pos, indent+2));

    sb_pad_left(&sb, indent);

    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);


    return arena_strdup(&a, sb.items);
}

/*
//================================================================================\\
//UTILS_END
\\================================================================================//
*/


/*
//================================================================================\\
//LEXER_START
\\================================================================================//
*/


bool alpha(uint8_t c)  {
    if ((c >= 'A' && c <= 'Z')
        ||  (c >= 'a' && c <= 'z')) {
        return true;
    }
    return false;
}

bool numeric(uint8_t c)  {
    if (c >= '0' && c <= '9'){
        return true;
    }
    return false;
}

bool alphanumeric(uint8_t c)  {
    if (alpha(c) || numeric(c) ) {
        return true;
    }
    return false;
}

void lexer_check_utilities() {
    for (char c = 32; c < 127; ++c){
        printf("alpha: %c = %s\n", c, alpha(c) ? "true": "false");
    }
    for (char c = 32; c < 127; ++c){
        printf("numeric: %c = %s\n", c, numeric(c) ? "true": "false");
    }

    for (char c = 32; c < 127; ++c){
        printf("alphanumeric: %c = %s\n", c, alphanumeric(c) ? "true": "false");
    }
}

bool empty(Lexer* l) {
    return l->curr >= strlen(l->text);
}

char curr_char(Lexer* l) {
    return l->text[l->curr];
}

char peek_char(Lexer* l) {
    return l->text[l->next];
}

bool next_char(Lexer* l) {
    if  (l->next >= strlen(l->text)) {
        l->curr = l->next;
        return false;
    }

    char curr = curr_char(l);
    if (curr == '\n') {
        l->pos.row += 1;
        l->pos.col = 1;
    } else {
        l->pos.col += 1;
    }

    l->curr = l->next;
    l->next += 1;
    return true;
}

void skip_whitespace(Lexer* l) {
    while (l->curr < strlen(l->text)) {
        char curr = curr_char(l);

        if (curr != ' ' && curr != '\t' && curr != '\r' && curr != '\n') {
            break;
        }

        if (!next_char(l)) {
            break;
        }
    }
}

//Assume curr_char(l) == '"'
Token lex_string(Lexer* l) {
    assert(curr_char(l) == '\"' && "lexing error, this should be \"");
    if (!next_char(l)) {
        fprintf(stderr, "%s Error: unexpected end of string\n", to_string_pos(l->pos, 0));
        assert(false);
    }

    String_Builder tok = {0};
    //take_while exclusive
    //TODO: Add support for escaping strings
    for (;;) {

        sb_append(&tok, curr_char(l));

        if (!next_char(l)) {
            break;
        }

        if (curr_char(l) == '\"') {
            break;
        }
    }
    
    sb_append_null(&tok);

    next_char(l) ;
    char *lit = arena_strdup(&a, tok.items);
    sb_free(tok);

    return (Token){
        .kind = LEXER_STRING,
        .literal = lit,
        .pos = l->pos,
    };
}

Token lex_identifier(Lexer* l) {

    char curr = curr_char(l);
    assert((curr == '_' || curr == '-' || alphanumeric(curr)) && "lexing error");

    String_Builder tok = {0};

    // sort of a take_while might be useful to extract at somepoint
    while (curr == '_' || curr == '-' || alphanumeric(curr)) {
        sb_append(&tok, curr_char(l));

        if (!next_char(l)) {
            break;
        }
        curr = curr_char(l);
    }
    sb_append_null(&tok);


    char *lit = arena_strdup(&a, tok.items);
    Lexer_Kind kind = keyword_or_identifier(lit);

    sb_free(tok);
    return (Token){
        .kind = kind,
        .literal = lit,
        .pos = l->pos,
    };
}

Token lex_number(Lexer* l) {
    char curr = curr_char(l);
    assert((curr == '.' || numeric(curr)) && "lexing error");
    String_Builder tok = {0};
    bool has_dot = false;

    //take_while
    while (curr == '.' || numeric(curr)) {
        if (curr == '.') {
            has_dot = true;
        }
        sb_append(&tok, curr);


        if (!next_char(l)) {
            break;
        }

        curr = curr_char(l);
    }

    sb_append_null(&tok);


    char *lit = arena_strdup(&a, tok.items);
    Lexer_Kind kind = has_dot ? LEXER_FLOAT64 : LEXER_INT64;

    sb_free(tok);
    return (Token){
        .kind = kind,
        .literal = lit,
        .pos = l->pos,
    };
}

Tokens lex(Lexer* l) {
    Token token = {0};
    Tokens tokens = {0};

    char curr;

    next_char(l);
    int max_depth = 100000;

    for (;;) {
        assert(max_depth > 0);

        skip_whitespace(l);
        if (empty(l)) {
            break;
        }

        curr = curr_char(l);

        if (alpha(curr) || curr == '_') {
            token = lex_identifier(l);
        } else if (numeric(curr)) {
            token = lex_number(l);
        } else {
            switch (curr) {

            case '=': {
                if (peek_char(l) == '=') {
                    next_char(l);
                    token = (Token){
                        .kind = LEXER_SAME,
                        .literal = "==",
                        .pos = l->pos,
                    };
                } else {
                    token = (Token){
                        .kind = LEXER_EQUALS,
                        .literal = "=",
                        .pos = l->pos,
                    };
                }
                next_char(l);
            } break;

            case '+': {
                token = (Token){
                    .kind = LEXER_PLUS,
                    .literal = "+",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '-': {
                token = (Token){
                    .kind = LEXER_MINUS,
                    .literal = "-",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '*': {
                token = (Token){
                    .kind = LEXER_MULTIPLY,
                    .literal = "*",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '<': {
                token = (Token){
                    .kind = LEXER_LT,
                    .literal = "<",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '>': {
                token = (Token){
                    .kind = LEXER_GT,
                    .literal = ">",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '/': {
                if (peek_char(l) == '/') {
                    // Skip comment line
                    next_char(l);
                    while (peek_char(l) != '\n') {
                        if (!next_char(l)) break;
                    }
                    next_char(l);
                    continue;
                }
                token = (Token){
                    .kind = LEXER_DIVIDE,
                    .literal = "/",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '\\': {
                token = (Token){
                    .kind = LEXER_BSLASH,
                    .literal = "\\",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '(': {
                token = (Token){
                    .kind = LEXER_LPAREN,
                    .literal = "(",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case ')': {
                token = (Token){
                    .kind = LEXER_RPAREN,
                    .literal = ")",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '[': {
                token = (Token){
                    .kind = LEXER_LBLOCK,
                    .literal = "[",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case ']': {
                token = (Token){
                    .kind = LEXER_RBLOCK,
                    .literal = "]",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '{': {
                token = (Token){
                    .kind = LEXER_LBRACE,
                    .literal = "{",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '}': {
                token = (Token){
                    .kind = LEXER_RBRACE,
                    .literal = "}",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '\'': {
                token = (Token){
                    .kind = LEXER_SQUOTE,
                    .literal = "'",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '%': {
                token = (Token){
                    .kind = LEXER_MOD,
                    .literal = "%",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '"': {
                token = lex_string(l);
            } break;

            case '?': {
                assert(false && "QUESTION_MARK not implemented in lexer");
            } break;

            case '!': {
                assert(false && "BANG not implemented in lexer");
            } break;

            case ',': {
                assert(false && "COMMA not implemented in lexer");
            } break;

            case '.': {
                if (peek_char(l) == '.') {
                    next_char(l);
                    token = (Token){
                        .kind = LEXER_DOTDOT,
                        .literal = "..",
                        .pos = l->pos,
                    };
                } else {
                    assert(false && "unexpected \".\"");
                }
                next_char(l);
            } break;

            case ' ':
            case '\n':
            case '\t':
            case '\r': {
                assert(false && "Error: Lexer error SPACE leaked");
            } break;

            default: {
                fprintf(stderr, "\n%s Error: lexing error, unlexible char %c\n",
                        to_string_pos(l->pos, 0), curr_char(l));
                assert(false);
            } break;

            }
        }

        arena_da_append(&a,&tokens, token);
        max_depth -= 1;
    }

    Token eof_token = (Token){
        .kind = LEXER_EOF,
        .literal = "EOF",
        .pos = l->pos,
    };
    arena_da_append(&a,&tokens, eof_token);
    return tokens;
}

/*
//================================================================================\\
//LEXER_END
\\================================================================================//
*/
/*
//================================================================================\\
//PARSER_START
\\================================================================================//
*/

typedef enum {
    PRECEDENCE_LOWEST = 1,
    PRECEDENCE_EQUALS = 2,
    PRECEDENCE_LESSGREATER = 3,
    PRECEDENCE_SUM = 4,
    PRECEDENCE_PRODUCT = 5,
    PRECEDENCE_PREFIX = 6,
    PRECEDENCE_CALL = 7,
    PRECEDENCE_INDEX = 8,
} Precedence;

// Forward declarations
typedef struct Expression Expression;
typedef union Value_Type Value_Type;
typedef union Literal_Value_Type Literal_Value_Type;
typedef struct Literal_Value Literal_Value;
typedef struct Environment Environment;

typedef enum { NUMBER_INT, NUMBER_FLOAT } Number_Kind;
typedef struct {
    Number_Kind kind;
    union { int64_t i; double f; };
} Number;

typedef enum {
    BINOP_PLUS,
    BINOP_MINUS,
    BINOP_MULTIPLY,
    BINOP_DIVIDE,
    BINOP_MOD,
    BINOP_SAME,
    BINOP_LT,
    BINOP_GT,
} Binop_Kind;

typedef struct {
    Binop_Kind kind;
    Expression *left;
    Expression *right;
} Binop;

typedef struct {
    Literal_Value *value;
} Literal_Node;

typedef struct {
    Expression *value;
    Position pos;
} Return;

typedef struct {
    char *name;
    Expression *value;
    Position pos;
} Binding;

typedef struct {
    Expression **items;
    size_t count;
    size_t capacity;
} Expressions;

typedef struct {
    Expressions elements;
    Position pos;
} Array;

typedef struct {
    Expression *index;
    char *name;
    Position pos;
} Array_Access;

typedef struct {
    char *name;
    Expression *index;
    Expression *exp;
    Position pos;
} Array_Insert;

typedef struct {
    Expression *cond;
    Expressions body;
    Expressions elze;
    Position pos;
} If;

typedef struct {
    Expression *cond;
    Expressions body;
    Position pos;
} While;

typedef struct {
    Expression *cond;
    Expression *iterator;
    Expression *update_exp;
    Expressions body;
    Position pos;
} For;

typedef struct {
    char *name;
    Position pos;
} Identifier;

typedef struct {
    Expressions args;
    Expressions value;
    Position pos;
    Environment *closure_env;
} Function;

typedef struct {
    Expressions params;
    char *name;
    Position pos;
} Function_Call;

typedef struct {
    Literal_Value *items;
    size_t count;
    size_t capacity;
    Position pos;
} Array_Literal;

typedef struct {
    Literal_Value *value;
    Position pos;
} Return_Value;

typedef enum {
    LIT_NUMBER,
    LIT_STRING,
    LIT_BOOL,
    LIT_FUNCTION,
    LIT_RETURN_VALUE,
    LIT_ARRAY_LITERAL,
} Literal_Value_Kind;

union Literal_Value_Type {
    Number number;
    char *string;
    bool boolean;
    Function function;
    Return_Value return_value;
    Array_Literal array_literal;
};

struct Literal_Value {
    Literal_Value_Kind kind;
    Literal_Value_Type value;
};

typedef enum {
    VAL_EXPRESSION,
    VAL_BINOP,
    VAL_BINDING,
    VAL_IDENTIFIER,
    VAL_FUNCTION,
    VAL_FUNCTION_CALL,
    VAL_LITERAL_NODE,
    VAL_IF,
    VAL_WHILE,
    VAL_FOR,
    VAL_RETURN,
    VAL_ARRAY,
    VAL_ARRAY_ACCESS,
    VAL_ARRAY_INSERT,
} Value_Kind;

union Value_Type {
    Expression *expression;
    Binop binop;
    Binding binding;
    Identifier identifier;
    Function function;
    Function_Call function_call;
    Literal_Node literal_node;
    If iff;
    While whilee;
    For forr;
    Return returnn;
    Array array;
    Array_Access array_access;
    Array_Insert array_insert;
};

struct Expression {
    Value_Kind kind;
    Value_Type value;
    Position pos;
};

typedef struct {
    Expression **items;
    size_t count;
    size_t capacity;
} Ast;

typedef struct {
    size_t curr;
    size_t next;
    Tokens tokens;
} Parser;

/*
//================================================================================\\
//ENVIRONMENT_START
\\================================================================================//
*/

typedef struct {
    char *key;
    Literal_Value value;
} Env_Entry;

struct Environment {
    Env_Entry *items;
    size_t count;
    size_t capacity;
    Environment *parent;
};

/*
//================================================================================\\
//ENVIRONMENT_END
\\================================================================================//
*/

/*
//================================================================================\\
//AST_TO_STRING_START
\\================================================================================//
*/

char *to_string_binop_kind(Binop_Kind kind) {
    if      (kind == BINOP_PLUS)     return "PLUS";
    else if (kind == BINOP_MINUS)    return "MINUS";
    else if (kind == BINOP_MULTIPLY) return "MULTIPLY";
    else if (kind == BINOP_DIVIDE)   return "DIVIDE";
    else if (kind == BINOP_MOD)      return "MOD";
    else if (kind == BINOP_SAME)     return "SAME";
    else if (kind == BINOP_LT)       return "LT";
    else if (kind == BINOP_GT)       return "GT";

    assert(false && "UNREACHABLE");
    return "INVALID";
}

// Forward declarations for mutually recursive to_string functions
char *to_string_expression(Expression *expr, int indent);
char *to_string_literal(Literal_Value *lit, int indent);
char *to_string_function(Function function, int indent);
char *to_string_return_value(Return_Value rv, int indent);
char *to_string_array_literal(Array_Literal array, int indent);

void sb_body_to_string(String_Builder *sb, Expressions body, int indent) {
    for (size_t i = 0; i < body.count; ++i) {
        sb_appendf(sb, "%s", to_string_expression(body.items[i], indent));
        sb_append_cstr(sb, "\n");
    }
}

char *to_string_boolean(bool flag, int indent) {
    String_Builder sb = {0};
    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, flag ? "true" : "false");
    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_string(char *str, int indent) {
    String_Builder sb = {0};
    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, str);
    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_number(Number num, int indent) {
    String_Builder sb = {0};
    sb_pad_left(&sb, indent);
    if (num.kind == NUMBER_FLOAT) {
        sb_appendf(&sb, "%f", num.f);
    } else {
        sb_appendf(&sb, "%lld", (long long)num.i);
    }
    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_literal(Literal_Value *lit, int indent) {
    if (lit == NULL) return arena_strdup(&a, "nil");

    switch (lit->kind) {
        case LIT_STRING:        return to_string_string(lit->value.string, indent);
        case LIT_NUMBER:        return to_string_number(lit->value.number, indent);
        case LIT_BOOL:          return to_string_boolean(lit->value.boolean, indent);
        case LIT_FUNCTION:      return to_string_function(lit->value.function, indent);
        case LIT_RETURN_VALUE:  return to_string_return_value(lit->value.return_value, indent);
        case LIT_ARRAY_LITERAL: return to_string_array_literal(lit->value.array_literal, indent);
    }

    assert(false && "UNREACHABLE");
    return arena_strdup(&a, "");
}

char *to_string_literal_node(Literal_Node node, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Literal_Node(\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "value: (\n");

    sb_appendf(&sb, "%s\n", to_string_literal(node.value, indent + 2));

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, ")\n");

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_identifier(Identifier ident, int indent) {
    String_Builder sb = {0};
    sb_pad_left(&sb, indent);
    sb_appendf(&sb, "Identifier(%s)", ident.name);
    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_binding(Binding binding, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Let(\n");

    sb_pad_left(&sb, indent + 1);
    sb_appendf(&sb, "name: %s,\n", binding.name);

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "value: \n");
    sb_appendf(&sb, "%s\n", to_string_expression(binding.value, indent + 2));

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_binop(Binop binop, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Binop(\n");

    sb_pad_left(&sb, indent + 1);
    sb_appendf(&sb, "op: %s,\n", to_string_binop_kind(binop.kind));

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "left: \n");
    sb_appendf(&sb, "%s\n", to_string_expression(binop.left, indent + 2));

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "right: \n");
    sb_appendf(&sb, "%s\n", to_string_expression(binop.right, indent + 2));

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_return(Return returnn, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Return(\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "value: \n");
    sb_appendf(&sb, "%s\n", to_string_expression(returnn.value, indent + 2));

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_return_value(Return_Value rv, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Return_Value(\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "value: \n");
    sb_appendf(&sb, "%s\n", to_string_literal(rv.value, indent + 2));

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_while(While whilee, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "While(\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "cond: (\n");
    sb_appendf(&sb, "%s\n", to_string_expression(whilee.cond, indent + 2));
    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "),\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "body: {");
    if (whilee.body.count > 0) {
        sb_append_cstr(&sb, "\n");
        sb_body_to_string(&sb, whilee.body, indent + 2);
    }
    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "}\n");

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_for(For forr, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "For(\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "iterator: (\n");
    sb_appendf(&sb, "%s\n", to_string_expression(forr.iterator, indent + 2));

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "cond: (\n");
    sb_appendf(&sb, "%s\n", to_string_expression(forr.cond, indent + 2));
    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "),\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "body: {");
    if (forr.body.count > 0) {
        sb_append_cstr(&sb, "\n");
        sb_body_to_string(&sb, forr.body, indent + 2);
    }
    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "}\n");

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_if(If iff, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "If(\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "cond: (\n");
    sb_appendf(&sb, "%s\n", to_string_expression(iff.cond, indent + 2));
    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "),\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "ifbody: {");
    if (iff.body.count > 0) {
        sb_append_cstr(&sb, "\n");
        sb_body_to_string(&sb, iff.body, indent + 2);
    }
    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "}\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "elsebody: {");
    if (iff.elze.count > 0) {
        sb_append_cstr(&sb, "\n");
        sb_body_to_string(&sb, iff.elze, indent + 2);
    }
    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "}\n");

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_function(Function function, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Function(\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "args: (");
    if (function.args.count > 0) {
        sb_append_cstr(&sb, "\n");
        sb_body_to_string(&sb, function.args, indent + 2);
        sb_pad_left(&sb, indent + 1);
    }
    sb_append_cstr(&sb, ")\n");

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "body: {");
    if (function.value.count > 0) {
        sb_append_cstr(&sb, "\n");
        sb_body_to_string(&sb, function.value, indent + 2);
    }
    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "}\n");

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_function_call(Function_Call fn_call, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Function_Call(\n");

    sb_pad_left(&sb, indent + 1);
    sb_appendf(&sb, "name: %s\n", fn_call.name);

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "params: (");
    if (fn_call.params.count > 0) {
        sb_append_cstr(&sb, "\n");
        sb_body_to_string(&sb, fn_call.params, indent + 2);
        sb_pad_left(&sb, indent + 1);
    }
    sb_append_cstr(&sb, ")\n");

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_array(Array array, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Array(");
    if (array.elements.count > 0) {
        sb_append_cstr(&sb, "\n");
        sb_body_to_string(&sb, array.elements, indent + 1);
        sb_append_cstr(&sb, "\n");
    }
    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")\n");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_array_access(Array_Access access, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Array_Access(\n");

    sb_pad_left(&sb, indent + 1);
    sb_appendf(&sb, "name: %s,\n", access.name);

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "index: \n");
    sb_appendf(&sb, "%s\n", to_string_expression(access.index, indent + 2));

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_array_insert(Array_Insert insert, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "Array_Insert(\n");

    sb_pad_left(&sb, indent + 1);
    sb_appendf(&sb, "name: %s,\n", insert.name);

    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "index: \n");
    sb_appendf(&sb, "%s\n", to_string_expression(insert.index, indent + 2));
    sb_append_cstr(&sb, "value: (\n");
    sb_appendf(&sb, "%s\n", to_string_expression(insert.exp, indent + 2));
    sb_pad_left(&sb, indent + 1);
    sb_append_cstr(&sb, "),\n");

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, ")");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_array_literal(Array_Literal array, int indent) {
    String_Builder sb = {0};

    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "[");
    for (size_t i = 0; i < array.count; ++i) {
        sb_appendf(&sb, "%s", to_string_literal(&array.items[i], 0));
        if (i < array.count - 1) {
            sb_append_cstr(&sb, " ");
        }
    }
    sb_pad_left(&sb, indent);
    sb_append_cstr(&sb, "]");

    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *to_string_expression(Expression *expr, int indent) {
    if (expr == NULL) return arena_strdup(&a, "nil");

    switch (expr->kind) {
        case VAL_EXPRESSION:    return to_string_expression(expr->value.expression, indent);
        case VAL_BINDING:       return to_string_binding(expr->value.binding, indent);
        case VAL_LITERAL_NODE:  return to_string_literal_node(expr->value.literal_node, indent);
        case VAL_IDENTIFIER:    return to_string_identifier(expr->value.identifier, indent);
        case VAL_BINOP:         return to_string_binop(expr->value.binop, indent);
        case VAL_ARRAY:         return to_string_array(expr->value.array, indent);
        case VAL_ARRAY_ACCESS:  return to_string_array_access(expr->value.array_access, indent);
        case VAL_ARRAY_INSERT:  return to_string_array_insert(expr->value.array_insert, indent);
        case VAL_FUNCTION_CALL: return to_string_function_call(expr->value.function_call, indent);
        case VAL_FUNCTION:      return to_string_function(expr->value.function, indent);
        case VAL_RETURN:        return to_string_return(expr->value.returnn, indent);
        case VAL_WHILE:         return to_string_while(expr->value.whilee, indent);
        case VAL_FOR:           return to_string_for(expr->value.forr, indent);
        case VAL_IF:            return to_string_if(expr->value.iff, indent);
    }

    assert(false && "UNREACHABLE");
    return arena_strdup(&a, "");
}

// Error reporting
void runtime_errorf(Position pos, const char *fmt_str, ...) {
    va_list args;
    va_start(args, fmt_str);
    fprintf(stderr, "\n%s Runtime Error: ", to_string_pos(pos, 0));
    vfprintf(stderr, fmt_str, args);
    fprintf(stderr, "\n");
    va_end(args);
    exit(1);
}

void syntax_errorf(Position pos, const char *fmt_str, ...) {
    va_list args;
    va_start(args, fmt_str);
    fprintf(stderr, "\n%s Syntax Error: ", to_string_pos(pos, 0));
    vfprintf(stderr, fmt_str, args);
    fprintf(stderr, "\n");
    va_end(args);
    exit(1);
}

void internal_errorf(Position pos, const char *fmt_str, ...) {
    va_list args;
    va_start(args, fmt_str);
    fprintf(stderr, "\n%s Internal Error: ", to_string_pos(pos, 0));
    vfprintf(stderr, fmt_str, args);
    fprintf(stderr, "\n");
    va_end(args);
    exit(1);
}

// TODO: expression_to_value_string and identifier_to_value_string
// require the interpreter's Environment type - stub for now

/*
//================================================================================\\
//AST_TO_STRING_END
\\================================================================================//
*/

// Forward declarations for mutually recursive parser functions
Expression *parse_expression(Parser *p);
Expression *parse_precedence(Parser *p, Precedence precedence);
Expression *parse_prefix(Parser *p);
Expression *parse_binop(Parser *p, Expression *left);
Expression *parse_identifier_expr(Parser *p);
Expression *parse_string_expr(Parser *p);

Token curr_tok(Parser *p) {
    return p->tokens.items[p->curr];
}

Token peek_tok(Parser *p) {
    return p->tokens.items[p->next];
}

bool next_tok(Parser *p) {

    // puts(to_string_token(curr_tok(p), 0));
    if (peek_tok(p).kind == LEXER_EOF) {
        return false;
    }

    p->curr = p->next;
    p->next += 1;
    return true;
}

bool expect(Parser *p, Lexer_Kind kind) {
    return curr_tok(p).kind == kind;
}

bool expect_peek(Parser *p, Lexer_Kind kind) {
    return peek_tok(p).kind == kind;
}

Precedence token_precedence(Parser *p) {
    Lexer_Kind kind = curr_tok(p).kind;
    switch (kind) {
        case LEXER_EQUALS:
            return PRECEDENCE_EQUALS;
        case LEXER_PLUS:
        case LEXER_MINUS:
            return PRECEDENCE_SUM;
        case LEXER_MULTIPLY:
        case LEXER_DIVIDE:
        case LEXER_MOD:
            return PRECEDENCE_PRODUCT;
        case LEXER_SAME:
        case LEXER_LT:
        case LEXER_GT:
            return PRECEDENCE_LESSGREATER;
        case LEXER_LPAREN:
        case LEXER_PRINT:
            return PRECEDENCE_CALL;
        case LEXER_LET: 
        case LEXER_FN: 
        case LEXER_RETURN: 
        case LEXER_IF: 
        case LEXER_TRUE: 
        case LEXER_FALSE:
        case LEXER_SHELL: 
        case LEXER_IDENT: 
        case LEXER_STRING: 
        case LEXER_DOT: 
        case LEXER_INT64:
        case LEXER_FLOAT64: 
        case LEXER_BSLASH: 
        case LEXER_RPAREN:
        case LEXER_LBRACE: 
        case LEXER_RBRACE: 
        case LEXER_SQUOTE: 
        case LEXER_QUESTION_MARK: 
        case LEXER_BANG:
        case LEXER_COMMA: 
        case LEXER_NEWLINE: 
        case LEXER_EOF: 
        case LEXER_ELSE: 
        case LEXER_FOR: 
        case LEXER_WHILE:
        case LEXER_DOTDOT: 
        case LEXER_LBLOCK: 
        case LEXER_RBLOCK:
            return PRECEDENCE_LOWEST;
        default:
            fprintf(stderr, "Unexpected KIND: %s\n", to_string_kind(curr_tok(p).kind));
            assert(false && "UNREACHABLE");
            return PRECEDENCE_LOWEST;
    }
}

Token next_and_expect(Parser *p, Lexer_Kind kind) {
    Token curr = curr_tok(p);

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: %s, got %s\n",
                to_string_pos(curr.pos, 0), to_string_kind(kind), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    curr = curr_tok(p);
    if (!expect(p, kind)) {
        fprintf(stderr, "%s Error: Expected: %s, got %s\n",
                to_string_pos(curr.pos, 0), to_string_kind(kind), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    return curr_tok(p);
}

Expression *create_expression(Value_Kind kind, Value_Type value, Position pos) {
    Expression *exp = arena_alloc(&a, sizeof(Expression));

    exp->kind = kind;
    exp->value = value;
    exp->pos = pos;
    return exp;
}

Expressions parse_block(Parser *p) {
    Expressions block_exps = {0};

    while (!expect(p, LEXER_RBRACE)) {
        Expression *exp = parse_expression(p);
        arena_da_append(&a,&block_exps, exp);
    }

    next_tok(p);
    return block_exps;
}

Expressions parse_fn_args(Parser *p) {
    Expressions args = {0};

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: argument or {, got %s\n",
                to_string_pos(curr_tok(p).pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    while (!expect(p, LEXER_LBRACE)) {
        Expression *exp = parse_identifier_expr(p);
        arena_da_append(&a,&args, exp);
    }

    next_tok(p);
    return args;
}

Expression *parse_fn_decl(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;
    Expressions args = parse_fn_args(p);
    Expressions block = parse_block(p);

    Function fn = {
        .value = block,
        .args = args,
        .pos = pos,
    };

    return create_expression(VAL_FUNCTION, (Value_Type){ .function = fn }, pos);
}

Expressions parse_fn_params(Parser *p) {
    Expressions params = {0};

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: param or ), got %s\n",
                to_string_pos(curr_tok(p).pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    int count = 0;
    int max_depth = 10000;
    while (!expect(p, LEXER_RPAREN)) {
        if (count > max_depth) {
            fprintf(stderr, "%s Error: Count hit max depth\n",
                    to_string_pos(curr_tok(p).pos, 0));
            assert(false);
        }
        Expression *exp = parse_expression(p);
        arena_da_append(&a,&params, exp);
        count += 1;
    }

    next_tok(p);
    return params;
}

Expression *parse_fn_call(Parser *p) {
    Token curr = curr_tok(p);
    char *name = curr.literal;
    Position pos = curr.pos;

    next_and_expect(p, LEXER_LPAREN);
    Expressions params = parse_fn_params(p);

    Function_Call fn_call = {
        .name = name,
        .params = params,
        .pos = pos,
    };

    return create_expression(VAL_FUNCTION_CALL, (Value_Type){ .function_call = fn_call }, pos);
}

Expression *parse_shell_call(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    Expressions param = {0};

    next_and_expect(p, LEXER_LPAREN);
    next_and_expect(p, LEXER_STRING);
    arena_da_append(&a,&param, parse_string_expr(p));

    Function_Call fn_call = {
        .params = param,
        .name = "shell",
        .pos = curr_tok(p).pos,
    };

    return create_expression(VAL_FUNCTION_CALL, (Value_Type){ .function_call = fn_call }, pos);
}

Expression *parse_array_access(Parser *p) {
    Token curr = curr_tok(p);
    char *name = curr.literal;
    Position pos = curr.pos;

    next_and_expect(p, LEXER_LBLOCK);

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: argument or ], got %s\n",
                to_string_pos(curr_tok(p).pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    Expression *index = parse_expression(p);
    Array_Access array = {
        .name = name,
        .index = index,
        .pos = pos,
    };

    // printf("[array_access: expression]: %s\n", to_string_expression(index, 0));

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: ], got %s\n",
                to_string_pos(curr_tok(p).pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
    }
    // printf("TOken after array_access_exp: %s\n", to_string_token(curr_tok(p), 0));

    // Check for array insert option e.g. arr[0] = "array ele 0"
    if (curr_tok(p).kind == LEXER_EQUALS) {
        // if (!next_tok(p)) {
        //     return create_expression(VAL_ARRAY_ACCESS, (Value_Type){ .array_access = array }, pos);
        // }
        if (!next_tok(p)) {
            return create_expression(VAL_ARRAY_ACCESS, (Value_Type){ .array_access = array }, pos);
        }

        Expression *exp = parse_expression(p);

        Array_Insert array_insert = {
            .name = name,
            .index = index,
            .exp = exp,
            .pos = pos,
        };
        return create_expression(VAL_ARRAY_INSERT, (Value_Type){ .array_insert = array_insert}, pos);

    }

    return create_expression(VAL_ARRAY_ACCESS, (Value_Type){ .array_access = array }, pos);
}

Expression *parse_array_decl(Parser *p) {
    Expressions elements = {0};
    int MAX_DEPTH = 1000000000;
    Position pos = curr_tok(p).pos;

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: element or ], got %s\n",
                to_string_pos(curr_tok(p).pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    int count = 0;
    while (!expect(p, LEXER_RBLOCK)) {
        if (count > MAX_DEPTH) {
            fprintf(stderr, "%s Error: Count hit max depth\n",
                    to_string_pos(curr_tok(p).pos, 0));
            assert(false);
        }
        Expression *exp = parse_expression(p);
        arena_da_append(&a,&elements, exp);
        count += 1;
    }

    Array array = {
        .elements = elements,
        .pos = pos,
    };

    next_tok(p);
    return create_expression(VAL_ARRAY, (Value_Type){ .array = array }, pos);
}

Expression *parse_while_expr(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;
    Expression *cond = NULL;

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Unexpected EOF after WHILE\n", to_string_pos(curr.pos, 0));
        assert(false);
    }

    if (expect(p, LEXER_LBRACE)) {
        // infinite while, no condition
    } else {
        cond = parse_expression(p);
        if (!expect(p, LEXER_LBRACE)) {
            fprintf(stderr, "%s Error: Expected: LBRACE, got %s\n",
                    to_string_pos(curr.pos, 0), to_string_kind(curr_tok(p).kind));
            assert(false);
        }
    }

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: WHILE block {, got EOF\n", to_string_pos(curr_tok(p).pos, 0));
        assert(false);
    }

    Expressions block = parse_block(p);

    While whilee = {
        .cond = cond,
        .body = block,
        .pos = pos,
    };

    return create_expression(VAL_WHILE, (Value_Type){ .whilee = whilee }, pos);
}

Expression *parse_for_expr(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Unexpected EOF after FOR\n", to_string_pos(curr.pos, 0));
        assert(false);
    }

    Expression *iterator = parse_expression(p);
    if (!expect(p, LEXER_DOTDOT)) {
        fprintf(stderr, "%s Error: Expected: DOTDOT `..`, got %s\n",
                to_string_pos(curr.pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Unexpected EOF after DOTDOT\n", to_string_pos(curr.pos, 0));
        assert(false);
    }

    Expression *cond = parse_expression(p);
    if (!expect(p, LEXER_DOTDOT)) {
        fprintf(stderr, "%s Error: Expected: DOTDOT `..`, got %s\n",
                to_string_pos(curr.pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Unexpected EOF after DOTDOT\n", to_string_pos(curr.pos, 0));
        assert(false);
    }

    Expression *update_exp = parse_expression(p);
    if (!expect(p, LEXER_LBRACE)) {
        fprintf(stderr, "%s Error: Expected: LBRACE, got %s\n",
                to_string_pos(curr.pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: FOR block {, got EOF\n", to_string_pos(curr_tok(p).pos, 0));
        assert(false);
    }

    Expressions block = parse_block(p);

    For forr = {
        .iterator = iterator,
        .update_exp = update_exp,
        .cond = cond,
        .body = block,
        .pos = pos,
    };

    return create_expression(VAL_FOR, (Value_Type){ .forr = forr }, pos);
}

Expression *parse_if_expr(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Unexpected EOF after IF\n", to_string_pos(curr.pos, 0));
        assert(false);
    }

    Expression *cond = parse_expression(p);
    if (!expect(p, LEXER_LBRACE)) {
        fprintf(stderr, "%s Error: Expected: LBRACE, got %s\n",
                to_string_pos(curr.pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
    }

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: IF block {, got EOF\n", to_string_pos(curr_tok(p).pos, 0));
        assert(false);
    }

    Expressions block = parse_block(p);
    Expressions elze = {0};

    if (expect(p, LEXER_ELSE)) {
        if (!next_tok(p)) {
            fprintf(stderr, "%s Error: Expected: ELSE block {, got EOF\n", to_string_pos(curr_tok(p).pos, 0));
            assert(false);
        }
        if (!next_tok(p)) {
            fprintf(stderr, "%s Error: Expected: ELSE block {, got EOF\n", to_string_pos(curr_tok(p).pos, 0));
            assert(false);
        }
        elze = parse_block(p);
    }

    If iff = {
        .cond = cond,
        .body = block,
        .elze = elze,
        .pos = pos,
    };

    return create_expression(VAL_IF, (Value_Type){ .iff = iff }, pos);
}

Expression *parse_return_expr(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Unexpected EOF after RETURN\n", to_string_pos(curr.pos, 0));
        assert(false);
    }

    Expression *exp = parse_expression(p);

    Return returnn = {
        .value = exp,
        .pos = pos,
    };

    return create_expression(VAL_RETURN, (Value_Type){ .returnn = returnn }, pos);
}

Expression *parse_let(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    curr = next_and_expect(p, LEXER_IDENT);
    char *name = curr.literal;

    next_and_expect(p, LEXER_EQUALS);

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Unexpected EOF after EQUALS\n", to_string_pos(curr.pos, 0));
        assert(false);
    }

    Expression *exp = parse_expression(p);

    Binding binding = {
        .name = name,
        .value = exp,
        .pos = pos,
    };

    return create_expression(VAL_BINDING, (Value_Type){ .binding = binding }, pos);
}

Expression *parse_string_expr(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    Literal_Value *lit_val = arena_alloc(&a, sizeof(Literal_Value));

    lit_val->kind = LIT_STRING;
    lit_val->value.string = curr.literal;

    Literal_Node node = {
        .value = lit_val,
    };

    next_tok(p);
    return create_expression(VAL_LITERAL_NODE, (Value_Type){ .literal_node = node }, pos);
}

Expression *parse_number_expr(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    Literal_Value *lit_val = arena_alloc(&a, sizeof(Literal_Value));

    lit_val->kind = LIT_NUMBER;

    if (curr.kind == LEXER_INT64) {
        int64_t parsed = strtoll(curr.literal, NULL, 10);
        lit_val->value.number = (Number){ .kind = NUMBER_INT, .i = parsed };
    } else if (curr.kind == LEXER_FLOAT64) {
        double parsed = strtod(curr.literal, NULL);
        lit_val->value.number = (Number){ .kind = NUMBER_FLOAT, .f = parsed };
    }

    Literal_Node node = {
        .value = lit_val,
    };

    next_tok(p);
    return create_expression(VAL_LITERAL_NODE, (Value_Type){ .literal_node = node }, pos);
}

Expression *parse_boolean_expr(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    Literal_Value *lit_val = arena_alloc(&a, sizeof(Literal_Value));

    lit_val->kind = LIT_BOOL;
    lit_val->value.boolean = (curr.kind != LEXER_FALSE);

    Literal_Node node = {
        .value = lit_val,
    };

    next_tok(p);
    return create_expression(VAL_LITERAL_NODE, (Value_Type){ .literal_node = node }, pos);
}

Expression *parse_identifier_expr(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    Identifier ident = {
        .name = curr.literal,
        .pos = curr.pos,
    };

    next_tok(p);
    return create_expression(VAL_IDENTIFIER, (Value_Type){ .identifier = ident }, pos);
}

Binop_Kind to_binop_kind(Position pos, Lexer_Kind kind) {
    switch (kind) {
        case LEXER_PLUS:     return BINOP_PLUS;
        case LEXER_MINUS:    return BINOP_MINUS;
        case LEXER_MULTIPLY: return BINOP_MULTIPLY;
        case LEXER_DIVIDE:   return BINOP_DIVIDE;
        case LEXER_MOD:      return BINOP_MOD;
        case LEXER_SAME:     return BINOP_SAME;
        case LEXER_LT:       return BINOP_LT;
        case LEXER_GT:       return BINOP_GT;
        default:
            fprintf(stderr, "%s Error: Unexpected Kind %s, should be PLUS | MINUS | MULTIPLY | DIVIDE | MOD | SAME | LT | GT\n",
                    to_string_pos(pos, 0), to_string_kind(kind));
            assert(false && "UNREACHABLE");
            return BINOP_PLUS;
    }
}

Expression *parse_binop(Parser *p, Expression *left) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;
    Lexer_Kind kind = curr.kind;
    Precedence operator_precedence = token_precedence(p);

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Unexpected EOF after %s\n",
                to_string_pos(curr.pos, 0), to_string_kind(curr.kind));
        assert(false);
    }

    Expression *right = parse_precedence(p, operator_precedence);

    Binop binop = {
        .kind = to_binop_kind(pos, kind),
        .left = left,
        .right = right,
    };

    return create_expression(VAL_BINOP, (Value_Type){ .binop = binop }, pos);
}

bool has_infix_parser(Lexer_Kind kind) {
    switch (kind) {
        case LEXER_PLUS: case LEXER_MINUS: case LEXER_MULTIPLY: case LEXER_DIVIDE:
        case LEXER_MOD: case LEXER_SAME: case LEXER_LT: case LEXER_GT:
            return true;
        default:
            return false;
    }
}

Expression *parse_precedence(Parser *p, Precedence precedence) {
    // printf("[parse_precedence]: %s\n", to_string_token(curr_tok(p), 0));
    Expression *left = parse_prefix(p);

    while (token_precedence(p) > precedence) {
        if (!has_infix_parser(curr_tok(p).kind)) break;
        left = parse_binop(p, left);
    }

    // printf("[expression]: %s\n", to_string_expression(left, 0));
    return left;
}

Expression *parse_prefix(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    switch (curr.kind) {
        case LEXER_FN:         return parse_fn_decl(p);
        case LEXER_LBLOCK:     return parse_array_decl(p);
        case LEXER_LET:        return parse_let(p);
        case LEXER_RETURN:     return parse_return_expr(p);
        case LEXER_TRUE:
        case LEXER_FALSE: return parse_boolean_expr(p);
        case LEXER_STRING:     return parse_string_expr(p);
        case LEXER_INT64:
        case LEXER_FLOAT64: return parse_number_expr(p);

        case LEXER_IF:    return parse_if_expr(p);
        case LEXER_WHILE: return parse_while_expr(p);
        case LEXER_FOR:   return parse_for_expr(p);

        case LEXER_IDENT: {
            if (expect_peek(p, LEXER_LPAREN)) {
                return parse_fn_call(p);
            }
            if (expect_peek(p, LEXER_LBLOCK)) {
                return parse_array_access(p);
            }
            return parse_identifier_expr(p);
        }

        case LEXER_PRINT:
        case LEXER_SHELL:
            return parse_fn_call(p);

        case LEXER_RPAREN:
            fprintf(stderr, "%s Error: Unexpected Kind %s\n",
                    to_string_pos(pos, 0), to_string_kind(curr.kind));
            assert(false);
            break;
        case LEXER_EQUALS:
            fprintf(stderr, "%s Error: Found %s, assignment expressions require `let`\ne.g let foo = \"bar\"\n",
                    to_string_pos(pos, 0), to_string_kind(curr.kind));
            assert(false);
            break;
        default:
            fprintf(stderr, "%s Error: unknown prefix expression %s\n",
                    to_string_pos(pos, 0), to_string_kind(curr.kind));
            assert(false);
            break;
    }

    assert(false && "UNREACHABLE");
    return NULL;
}

Expression *parse_expression(Parser *p) {
    return parse_precedence(p, PRECEDENCE_LOWEST);
}

Ast parse(Parser *p) {
    Ast ast = {0};

    next_tok(p);

    for (;;) {
        Expression *exp = parse_expression(p);
        arena_da_append(&a,&ast, exp);

        if (peek_tok(p).kind == LEXER_EOF) {
            break;
        }
    }

    return ast;
}

/*
//================================================================================\\
//PARSER_END
\\================================================================================//
*/

/*
//================================================================================\\
//INTERPRETER_START
\\================================================================================//
*/

// --- Environment operations ---

Environment *env_create(Environment *parent) {
    Environment *env = arena_alloc(&a, sizeof(Environment));

    env->items = NULL;
    env->count = 0;
    env->capacity = 0;
    env->parent = parent;
    return env;
}

typedef struct {
    Literal_Value value;
    bool found;
} Env_Result;

Env_Result env_get(Environment *env, const char *key) {
    Environment *curr = env;
    int max_depth = 50000;

    while (curr != NULL) {
        assert(max_depth >= 0 && "Hit max scope depth");
        for (size_t i = 0; i < curr->count; ++i) {
            if (strcmp(curr->items[i].key, key) == 0) {
                return (Env_Result){ .value = curr->items[i].value, .found = true };
            }
        }
        curr = curr->parent;
        max_depth -= 1;
    }

    return (Env_Result){ .found = false };
}

void env_set(Environment *env, const char *key, Literal_Value value) {
    // Overwrite if exists in current scope
    for (size_t i = 0; i < env->count; ++i) {
        if (strcmp(env->items[i].key, key) == 0) {
            env->items[i].value = value;
            return;
        }
    }
    // Append new entry
    Env_Entry entry = { .key = (char *)key, .value = value };
    arena_da_append(&a,env, entry);
}

// --- Value constructors ---

Literal_Value make_number_int(int64_t v) {
    return (Literal_Value){
        .kind = LIT_NUMBER,
        .value.number = (Number){ .kind = NUMBER_INT, .i = v },
    };
}

Literal_Value make_number_float(double v) {
    return (Literal_Value){
        .kind = LIT_NUMBER,
        .value.number = (Number){ .kind = NUMBER_FLOAT, .f = v },
    };
}

Literal_Value make_string(char *s) {
    return (Literal_Value){
        .kind = LIT_STRING,
        .value.string = s,
    };
}

Literal_Value make_bool(bool b) {
    return (Literal_Value){
        .kind = LIT_BOOL,
        .value.boolean = b,
    };
}

Literal_Value make_function(Function fn, Environment *closure_env) {
    fn.closure_env = closure_env;
    return (Literal_Value){
        .kind = LIT_FUNCTION,
        .value.function = fn,
    };
}

Literal_Value make_array_literal(Array_Literal arr) {
    return (Literal_Value){
        .kind = LIT_ARRAY_LITERAL,
        .value.array_literal = arr,
    };
}

Literal_Value make_return_value(Literal_Value *val, Position pos) {
    return (Literal_Value){
        .kind = LIT_RETURN_VALUE,
        .value.return_value = (Return_Value){ .value = val, .pos = pos },
    };
}

// --- Print string for runtime output ---

char *literal_value_to_print_string(Literal_Value val);

char *function_to_value_string(Function function) {
    String_Builder sb = {0};
    sb_append_cstr(&sb, "fn(");
    for (size_t i = 0; i < function.args.count; ++i) {
        sb_appendf(&sb, "%s", function.args.items[i]->value.identifier.name);
        if (i < function.args.count - 1) {
            sb_append_cstr(&sb, " ");
        }
    }
    sb_append_cstr(&sb, ")");
    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *array_literal_to_print_string(Array_Literal array) {
    String_Builder sb = {0};
    sb_append_cstr(&sb, "[");
    for (size_t i = 0; i < array.count; ++i) {
        sb_appendf(&sb, "%s", literal_value_to_print_string(array.items[i]));
        if (i < array.count - 1) {
            sb_append_cstr(&sb, " ");
        }
    }
    sb_append_cstr(&sb, "]");
    sb_append_null(&sb);
    return arena_strdup(&a, sb.items);
}

char *literal_value_to_print_string(Literal_Value val) {
    switch (val.kind) {
        case LIT_NUMBER:        return to_string_number(val.value.number, 0);
        case LIT_STRING:        return val.value.string;
        case LIT_BOOL:          return val.value.boolean ? "true" : "false";
        case LIT_FUNCTION:      return function_to_value_string(val.value.function);
        case LIT_ARRAY_LITERAL: return array_literal_to_print_string(val.value.array_literal);
        case LIT_RETURN_VALUE:
            if (val.value.return_value.value != NULL) {
                return literal_value_to_print_string(*val.value.return_value.value);
            }
            return "nil";
    }
    assert(false && "UNREACHABLE");
    return "";
}

// --- Arithmetic helpers ---

static inline double number_to_double(Number n) {
    return n.kind == NUMBER_FLOAT ? n.f : (double)n.i;
}

Number eval_add(Number left, Number right) {
    if (left.kind == NUMBER_FLOAT || right.kind == NUMBER_FLOAT) {
        return (Number){ .kind = NUMBER_FLOAT, .f = number_to_double(left) + number_to_double(right) };
    }
    return (Number){ .kind = NUMBER_INT, .i = left.i + right.i };
}

Number eval_minus(Number left, Number right) {
    if (left.kind == NUMBER_FLOAT || right.kind == NUMBER_FLOAT) {
        return (Number){ .kind = NUMBER_FLOAT, .f = number_to_double(left) - number_to_double(right) };
    }
    return (Number){ .kind = NUMBER_INT, .i = left.i - right.i };
}

Number eval_mul(Number left, Number right) {
    if (left.kind == NUMBER_FLOAT || right.kind == NUMBER_FLOAT) {
        return (Number){ .kind = NUMBER_FLOAT, .f = number_to_double(left) * number_to_double(right) };
    }
    return (Number){ .kind = NUMBER_INT, .i = left.i * right.i };
}

Number eval_div(Number left, Number right) {
    if (left.kind == NUMBER_FLOAT || right.kind == NUMBER_FLOAT) {
        return (Number){ .kind = NUMBER_FLOAT, .f = number_to_double(left) / number_to_double(right) };
    }
    return (Number){ .kind = NUMBER_INT, .i = left.i / right.i };
}

bool eval_lt(Number left, Number right) {
    if (left.kind == NUMBER_FLOAT || right.kind == NUMBER_FLOAT) {
        return number_to_double(left) < number_to_double(right);
    }
    return left.i < right.i;
}

bool eval_gt(Number left, Number right) {
    if (left.kind == NUMBER_FLOAT || right.kind == NUMBER_FLOAT) {
        return number_to_double(left) > number_to_double(right);
    }
    return left.i > right.i;
}

bool eval_same(Literal_Value left, Literal_Value right) {
    if (left.kind != right.kind) return false;

    switch (left.kind) {
        case LIT_NUMBER: {
            // Compare as doubles if either is float
            if (left.value.number.kind == NUMBER_FLOAT || right.value.number.kind == NUMBER_FLOAT) {
                return number_to_double(left.value.number) == number_to_double(right.value.number);
            }
            return left.value.number.i == right.value.number.i;
        }
        case LIT_STRING:
            return strcmp(left.value.string, right.value.string) == 0;
        case LIT_BOOL:
            return left.value.boolean == right.value.boolean;
        case LIT_FUNCTION:
            return false;
        case LIT_ARRAY_LITERAL: {
            Array_Literal la = left.value.array_literal;
            Array_Literal ra = right.value.array_literal;
            if (la.count != ra.count) return false;
            for (size_t i = 0; i < la.count; ++i) {
                if (!eval_same(la.items[i], ra.items[i])) return false;
            }
            return true;
        }
        case LIT_RETURN_VALUE:
            runtime_errorf(right.value.return_value.pos, "found Return in == expression");
            return false;
    }
    assert(false && "UNREACHABLE");
    return false;
}

// --- Forward declarations for mutually recursive eval ---
Literal_Value eval(Environment *env, Expression *node);
Literal_Value eval_block(Environment *env, Expressions exps);

// --- Eval helpers ---

Literal_Value eval_literal(Environment *env, Expression *node) {
    // TODO check why we pass the env if not used
    (void)env;
    Literal_Node literal_node = node->value.literal_node;
    if (literal_node.value == NULL) {
        internal_errorf(node->pos, "found nil literal");
    }

    switch (literal_node.value->kind) {
        case LIT_NUMBER:
        case LIT_STRING:
        case LIT_BOOL:
            return *literal_node.value;
        case LIT_FUNCTION:
            return make_function(node->value.function, node->value.function.closure_env);
        case LIT_ARRAY_LITERAL:
            // Fall through to eval_array-like behavior
            return *literal_node.value;
        case LIT_RETURN_VALUE:
            internal_errorf(node->pos, "found Return, expected literal");
    }
    assert(false && "UNREACHABLE");
    return make_bool(false);
}

Literal_Value eval_identifier(Environment *env, Expression *node) {
    Identifier identifier = node->value.identifier;
    Env_Result result = env_get(env, identifier.name);

    if (!result.found) {
        runtime_errorf(node->pos, "Var: %s, is undefined in the current scope", identifier.name);
    }

    if (result.value.kind == LIT_RETURN_VALUE) {
        runtime_errorf(result.value.value.return_value.pos, "found Return, expected Identifier");
    }

    return result.value;
}

Literal_Value eval_binding(Environment *env, Expression *node) {
    Binding binding = node->value.binding;
    Literal_Value result = eval(env, binding.value);
    // Unwrap return values at binding site (e.g. let val = if ... { return x })
    if (result.kind == LIT_RETURN_VALUE) {
        result = *result.value.return_value.value;
    }
    // Ensure functions capture the definition environment
    if (result.kind == LIT_FUNCTION && result.value.function.closure_env == NULL) {
        result.value.function.closure_env = env;
    }
    env_set(env, binding.name, result);
    return result;
}

Literal_Value eval_return(Environment *env, Expression *node) {
    Return returnn = node->value.returnn;
    Literal_Value result = eval(env, returnn.value);

    Literal_Value *heap_val = arena_alloc(&a, sizeof(Literal_Value));

    *heap_val = result;

    return make_return_value(heap_val, node->pos);
}

Literal_Value eval_binop(Environment *env, Expression *node) {
    Binop binop = node->value.binop;
    Literal_Value left = eval(env, binop.left);
    Literal_Value right = eval(env, binop.right);

    switch (binop.kind) {
        case BINOP_SAME:
            return make_bool(eval_same(left, right));
        case BINOP_LT: {
            if (left.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '<', got non-number");
            if (right.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '<', got non-number");
            return make_bool(eval_lt(left.value.number, right.value.number));
        }
        case BINOP_GT: {
            if (left.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '>', got non-number");
            if (right.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '>', got non-number");
            return make_bool(eval_gt(left.value.number, right.value.number));
        }
        case BINOP_PLUS: {
            if (left.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '+', got non-number");
            if (right.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '+', got non-number");
            Number r = eval_add(left.value.number, right.value.number);
            return (Literal_Value){ .kind = LIT_NUMBER, .value.number = r };
        }
        case BINOP_MINUS: {
            if (left.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '-', got non-number");
            if (right.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '-', got non-number");
            Number r = eval_minus(left.value.number, right.value.number);
            return (Literal_Value){ .kind = LIT_NUMBER, .value.number = r };
        }
        case BINOP_MULTIPLY: {
            if (left.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '*', got non-number");
            if (right.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '*', got non-number");
            Number r = eval_mul(left.value.number, right.value.number);
            return (Literal_Value){ .kind = LIT_NUMBER, .value.number = r };
        }
        case BINOP_DIVIDE: {
            if (left.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '/', got non-number");
            if (right.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '/', got non-number");
            Number r = eval_div(left.value.number, right.value.number);
            return (Literal_Value){ .kind = LIT_NUMBER, .value.number = r };
        }
        case BINOP_MOD: {
            if (left.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '%%', got non-number");
            if (right.kind != LIT_NUMBER) runtime_errorf(node->pos, "Expected Number for '%%', got non-number");
            if (left.value.number.kind == NUMBER_FLOAT) runtime_errorf(node->pos, "Operator '%%' is only allowed with integers, got float64");
            if (right.value.number.kind == NUMBER_FLOAT) runtime_errorf(node->pos, "Operator '%%' is only allowed with integers, got float64");
            return make_number_int(left.value.number.i % right.value.number.i);
        }
    }

    internal_errorf(node->pos, "Expected Binop");
    return make_bool(false);
}

// --- Control flow ---

Literal_Value eval_if(Environment *env, Expression *node) {
    If if_node = node->value.iff;
    Literal_Value cond = eval(env, if_node.cond);

    if (cond.kind != LIT_BOOL) {
        runtime_errorf(node->pos, "Expected bool in if condition");
    }

    Literal_Value result = make_bool(false);
    if (cond.value.boolean) {
        result = eval_block(env, if_node.body);
    } else if (if_node.elze.count > 0) {
        result = eval_block(env, if_node.elze);
    }

    return result;
}

Literal_Value eval_while(Environment *env, Expression *node) {
    While while_node = node->value.whilee;
    Literal_Value result = make_bool(false);

    Environment *new_env = env_create(env);

    for (;;) {
        bool cond_bool;
        if (while_node.cond == NULL) {
            cond_bool = true;
        } else {
            Literal_Value cond = eval(new_env, while_node.cond);
            if (cond.kind != LIT_BOOL) {
                runtime_errorf(node->pos, "Expected bool in while condition");
            }
            cond_bool = cond.value.boolean;
        }

        if (cond_bool) {
            result = eval_block(new_env, while_node.body);
        } else {
            break;
        }
    }

    return result;
}

Literal_Value eval_for(Environment *env, Expression *node) {
    For for_node = node->value.forr;
    Literal_Value result = make_bool(false);

    // Evaluate iterator (which is a binding like `let i = 0`)
    Binding binding = for_node.iterator->value.binding;
    Literal_Value init_val = eval(env, binding.value);
    env_set(env, binding.name, init_val);

    Environment *new_env = env_create(env);

    for (;;) {
        bool cond_bool;
        if (for_node.cond == NULL) {
            cond_bool = true;
        } else {
            Literal_Value cond = eval(new_env, for_node.cond);
            if (cond.kind != LIT_BOOL) {
                runtime_errorf(node->pos, "Expected bool in for condition");
            }
            cond_bool = cond.value.boolean;
        }

        if (cond_bool) {
            result = eval_block(new_env, for_node.body);
        } else {
            break;
        }

        // Update expression (e.g. i + 1)
        Literal_Value update_val = eval(new_env, for_node.update_exp);
        env_set(env, binding.name, update_val);
    }

    return result;
}

Literal_Value eval_block(Environment *env, Expressions exps) {
    Literal_Value result = make_bool(false);

    for (size_t i = 0; i < exps.count; ++i) {
        result = eval(env, exps.items[i]);
        if (result.kind == LIT_RETURN_VALUE) {
            // Propagate return value up without unwrapping
            return result;
        }
    }

    return result;
}

// --- Functions ---

Literal_Value eval_function(Environment *env, Expression *node) {
    return make_function(node->value.function, env);
}

Literal_Value eval_function_call(Environment *env, Expression *node) {
    Function_Call function_call = node->value.function_call;
    Expressions params = function_call.params;
    char *name = function_call.name;

    if (strcmp(name, "print") == 0) {
        for (size_t i = 0; i < params.count; ++i) {
            Literal_Value param_value = eval(env, params.items[i]);
            printf("%s", literal_value_to_print_string(param_value));
        }
        printf("\n");
        return make_bool(true);
    }

    if (strcmp(name, "shell") == 0) {
#ifndef _WIN32
        if (params.count < 1) {
            runtime_errorf(node->pos, "shell() expects at least 1 argument");
        }

        // Build command string
        Literal_Value command_val = eval(env, params.items[0]);
        if (command_val.kind != LIT_STRING) {
            runtime_errorf(node->pos, "shell() expects a string argument");
        }
        char *command = command_val.value.string;

        // Capture stdout via popen
        String_Builder stdout_sb = {0};
        FILE *fp = popen(command, "r");
        if (fp == NULL) {
            runtime_errorf(node->pos, "shell() failed to execute command: %s", command);
        }

        char buf[256];
        while (fgets(buf, sizeof(buf), fp) != NULL) {
            sb_append_cstr(&stdout_sb, buf);
        }
        sb_append_null(&stdout_sb);

        int status = pclose(fp);
        int exit_code = WEXITSTATUS(status);

        char *stdout_str = stdout_sb.items ? arena_strdup(&a, stdout_sb.items) : arena_strdup(&a, "");
        sb_free(stdout_sb);

        // Build result array: [stdout, stderr, exit_code]
        Array_Literal result_array = {0};
        Literal_Value stdout_elem = make_string(stdout_str);
        Literal_Value stderr_elem = make_string(arena_strdup(&a, ""));
        Literal_Value exit_elem = make_number_int((int64_t)exit_code);
        arena_da_append(&a,&result_array, stdout_elem);
        arena_da_append(&a,&result_array, stderr_elem);
        arena_da_append(&a,&result_array, exit_elem);
        result_array.pos = node->pos;

        return make_array_literal(result_array);

#endif /* ifdef _WIN32 */

        TODO("shell not implemented for windows yet");
    }

    // User-defined function call
    Env_Result var = env_get(env, name);
    if (!var.found) {
        runtime_errorf(node->pos, "Var: %s, is undefined in the current scope", name);
    }
    if (var.value.kind != LIT_FUNCTION) {
        runtime_errorf(node->pos, "Var: %s, is not a function", name);
    }

    Function fn = var.value.value.function;
    Environment *new_env = env_create(fn.closure_env ? fn.closure_env : env);

    for (size_t i = 0; i < params.count; ++i) {
        Literal_Value param_value = eval(env, params.items[i]);
        char *arg_name = fn.args.items[i]->value.identifier.name;
        env_set(new_env, arg_name, param_value);
    }

    Literal_Value result = eval_block(new_env, fn.value);
    // Unwrap return value at function boundary
    if (result.kind == LIT_RETURN_VALUE) {
        return *result.value.return_value.value;
    }
    return result;
}

// --- Arrays ---

Literal_Value eval_array(Environment *env, Expression *node) {
    Array array_node = node->value.array;

    Array_Literal result = {0};
    for (size_t i = 0; i < array_node.elements.count; ++i) {
        Literal_Value val = eval(env, array_node.elements.items[i]);
        arena_da_append(&a,&result, val);
    }
    result.pos = array_node.pos;

    return make_array_literal(result);
}
int64_t to_array_index(Array_Literal array, Number index) {
    int64_t idx;
    if (index.kind == NUMBER_INT) {
        idx = index.i;
    } else {
        idx = (int64_t)index.f;
    }
    if (idx < 0 || (size_t)idx >= array.count) {
        runtime_errorf(array.pos, "Array index %lld out of bounds (length %zu)", (long long)idx, array.count);
    }
    return idx;
}

Literal_Value eval_array_index(Array_Literal array, Number index) {
    int64_t idx = to_array_index(array, index);

    return array.items[idx];
}

Literal_Value eval_array_access(Environment *env, Expression *node) {
    Array_Access access = node->value.array_access;

    Env_Result arr_result = env_get(env, access.name);
    if (!arr_result.found) {
        runtime_errorf(node->pos, "Var: %s, is undefined in the current scope", access.name);
    }
    if (arr_result.value.kind != LIT_ARRAY_LITERAL) {
        runtime_errorf(node->pos, "Var: %s, is not an array", access.name);
    }

    Literal_Value index_val = eval(env, access.index);
    if (index_val.kind != LIT_NUMBER) {
        runtime_errorf(node->pos, "Array index must be a number");
    }

    return eval_array_index(arr_result.value.value.array_literal, index_val.value.number);
}

Literal_Value eval_array_insert(Environment *env, Expression *node) {
    Array_Insert insert = node->value.array_insert;

    Env_Result arr_result = env_get(env, insert.name);
    if (!arr_result.found) {
        runtime_errorf(node->pos, "Var: %s, is undefined in the current scope", insert.name);
    }

    if (arr_result.value.kind != LIT_ARRAY_LITERAL) {
        runtime_errorf(node->pos, "Var: %s, is not an array", insert.name);
    }
    Array_Literal array = arr_result.value.value.array_literal;

    Literal_Value index_val = eval(env, insert.index);
    if (index_val.kind != LIT_NUMBER) {
        runtime_errorf(node->pos, "Array index must be a number");
    }
    Number index = index_val.value.number;

    int64_t idx;
    // TODO refactor to coerce_number?
    if (index.kind == NUMBER_INT) {
        idx = index.i;
    } else {
        idx = (int64_t)index.f;
    }
    if (idx < 0 ) {
        runtime_errorf(array.pos, "Array index %lld out of bounds, must be a positive number", (long long)idx, array.count);
    }

    Literal_Value val = eval(env, insert.exp);

    // Pad array with zeros for now
    while (array.count <= (size_t)idx) {
        arena_da_append(&a, &array, make_number_int(0));
    }

    array.items[(size_t)idx] = val;
    env_set(env, insert.name, make_array_literal(array));
    // TODO("Need to check scoping rules");

    // TODO Unsure if this is the right thing to return but does allow for using (arr[0] = val) as an expression
    return val;
}

// --- Main eval dispatch ---

Literal_Value eval(Environment *env, Expression *node) {
    switch (node->kind) {
        case VAL_RETURN:        return eval_return(env, node);
        case VAL_LITERAL_NODE:  return eval_literal(env, node);
        case VAL_IDENTIFIER:    return eval_identifier(env, node);
        case VAL_BINDING:       return eval_binding(env, node);
        case VAL_FUNCTION:      return eval_function(env, node);
        case VAL_ARRAY:         return eval_array(env, node);
        case VAL_FUNCTION_CALL: return eval_function_call(env, node);
        case VAL_ARRAY_ACCESS:  return eval_array_access(env, node);
        case VAL_ARRAY_INSERT:  return eval_array_insert(env, node);
        case VAL_BINOP:         return eval_binop(env, node);
        case VAL_IF:            return eval_if(env, node);
        case VAL_WHILE:         return eval_while(env, node);
        case VAL_FOR:           return eval_for(env, node);
        case VAL_EXPRESSION:    return eval(env, node->value.expression);
    }

    internal_errorf(node->pos, "Unhandled expression kind in eval");
    return make_bool(false);
}

/*
//================================================================================\\
//INTERPRETER_END
\\================================================================================//
*/

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "USAGE: ./augac <source_file> [debug]\n");
        exit(69);
    }

    char *file_name = argv[1];
    bool debug = false;
    if (argc > 2 && strcmp(argv[2], "debug") == 0) {
        debug = true;
    }

    // Read file
    FILE *f = fopen(file_name, "rb");
    if (!f) {
        fprintf(stderr, "Failed to open file: %s\n", file_name);
        return 1;
    }
    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *text = arena_alloc(&a, fsize + 1);
    fread(text, 1, fsize, f);
    text[fsize] = '\0';
    fclose(f);

    // Lex
    Lexer l = (Lexer){
        .curr = 0,
        .next = 0,
        .pos = (Position){
            .row = 1,
            .col = 1,
            .file_path = file_name,
        },
        .text = text,
    };
    Tokens tokens = lex(&l);

    // Parse
    Parser p = (Parser){
        .curr = 0,
        .next = 0,
        .tokens = tokens,
    };
    Ast ast = parse(&p);

    // Eval
    Environment *env = env_create(NULL);

    for (size_t i = 0; i < ast.count; ++i) {
        Literal_Value result = eval(env, ast.items[i]);

        if (debug) {
            fprintf(stderr, "[DEBUG]: %s\n", literal_value_to_print_string(result));
        }
    }

    arena_free(&a);
    return 0;
}

