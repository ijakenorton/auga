#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#define NOB_IMPLEMENTATION
#include "nob.h"
/*
//================================================================================\\
//CONSTANTS_START
\\================================================================================//
*/
// Unsure if this should be here
#define INDENT "__"
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
    LEXER_LBRACKET,
    LEXER_RBRACKET,
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
    if      (kind == LEXER_LET)           return "LET";
    else if (kind == LEXER_FN)            return "FN";
    else if (kind == LEXER_LT)            return "LT";
    else if (kind == LEXER_GT)            return "GT";
    else if (kind == LEXER_RETURN)        return "RETURN";
    else if (kind == LEXER_FOR)           return "FOR";
    else if (kind == LEXER_WHILE)         return "WHILE";
    else if (kind == LEXER_IF)            return "IF";
    else if (kind == LEXER_ELSE)          return "ELSE";
    else if (kind == LEXER_TRUE)          return "TRUE";
    else if (kind == LEXER_FALSE)         return "FALSE";
    else if (kind == LEXER_PRINT)         return "PRINT";
    else if (kind == LEXER_SHELL)         return "SHELL";
    else if (kind == LEXER_IDENT)         return "IDENT";
    else if (kind == LEXER_DOT)           return "DOT";
    else if (kind == LEXER_DOTDOT)        return "DOTDOT";
    else if (kind == LEXER_EQUALS)        return "EQUALS";
    else if (kind == LEXER_SAME)          return "SAME";
    else if (kind == LEXER_INT64)         return "INT64";
    else if (kind == LEXER_FLOAT64)       return "FLOAT64";
    else if (kind == LEXER_PLUS)          return "PLUS";
    else if (kind == LEXER_MINUS)         return "MINUS";
    else if (kind == LEXER_MOD)           return "MOD";
    else if (kind == LEXER_MULTIPLY)      return "MULTIPLY";
    else if (kind == LEXER_DIVIDE)        return "DIVIDE";
    else if (kind == LEXER_BSLASH)        return "BSLASH";
    else if (kind == LEXER_LPAREN)        return "LPAREN";
    else if (kind == LEXER_RPAREN)        return "RPAREN";
    else if (kind == LEXER_LBRACE)        return "LBRACE";
    else if (kind == LEXER_RBRACE)        return "RBRACE";
    else if (kind == LEXER_LBLOCK)        return "LBLOCK";
    else if (kind == LEXER_RBLOCK)        return "RBLOCK";
    else if (kind == LEXER_LBRACKET)      return "LBRACKET";
    else if (kind == LEXER_RBRACKET)      return "RBRACKET";
    else if (kind == LEXER_SQUOTE)        return "SQUOTE";
    else if (kind == LEXER_STRING)        return "STRING";
    else if (kind == LEXER_QUESTION_MARK) return "QUESTION_MARK";
    else if (kind == LEXER_BANG)          return "BANG";
    else if (kind == LEXER_COMMA)         return "COMMA";
    else if (kind == LEXER_NEWLINE)       return "NEWLINE";
    else if (kind == LEXER_EOF)           return "EOF";

    assert(false && "UNREACHABLE");
    return "INVALID";
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
    // TODO Address leak
    return strdup(sb.items);
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

    // TODO Address leak
    return strdup(sb.items);
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
    char *lit = strdup(tok.items);
    sb_free(tok);
// TODO: UNSURE IF I CAN PASS ITEMS LIKE THIS
// TODO: Fix leak here for now
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

// TODO: UNSURE IF I CAN PASS ITEMS LIKE THIS
// TODO: Fix leak here for now
    char *lit = strdup(tok.items);
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

// TODO: UNSURE IF I CAN PASS ITEMS LIKE THIS
// TODO: Fix leak here for now
    char *lit = strdup(tok.items);
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

        nob_da_append(&tokens, token);
        max_depth -= 1;
    }

    Token eof_token = (Token){
        .kind = LEXER_EOF,
        .literal = "EOF",
        .pos = l->pos,
    };
    nob_da_append(&tokens, eof_token);
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
typedef union Number Number;

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
    Literal_Value_Type *value;
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
} Function;

typedef struct {
    Expressions params;
    char *name;
    Position pos;
} Function_Call;

union Number {
    int64_t i;
    double f;
};

typedef struct {
    Literal_Value_Type *elements;
    size_t count;
    size_t capacity;
    Position pos;
} Array_Literal;

typedef struct {
    Expression *value;
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
        case LEXER_LET: case LEXER_FN: case LEXER_RETURN: case LEXER_IF: case LEXER_TRUE: case LEXER_FALSE:
        case LEXER_SHELL: case LEXER_IDENT: case LEXER_STRING: case LEXER_DOT: case LEXER_INT64:
        case LEXER_FLOAT64: case LEXER_BSLASH: case LEXER_RPAREN: case LEXER_LBRACKET: case LEXER_RBRACKET:
        case LEXER_LBRACE: case LEXER_RBRACE: case LEXER_SQUOTE: case LEXER_QUESTION_MARK: case LEXER_BANG:
        case LEXER_COMMA: case LEXER_NEWLINE: case LEXER_EOF: case LEXER_ELSE: case LEXER_FOR: case LEXER_WHILE:
        case LEXER_DOTDOT: case LEXER_LBLOCK: case LEXER_RBLOCK:
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
    Expression *exp = malloc(sizeof(Expression));
    assert(exp && "allocation failed");
    exp->kind = kind;
    exp->value = value;
    exp->pos = pos;
    return exp;
}

Expressions parse_block(Parser *p) {
    Expressions block_exps = {0};

    while (!expect(p, LEXER_RBRACE)) {
        Expression *exp = parse_expression(p);
        nob_da_append(&block_exps, exp);
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
        nob_da_append(&args, exp);
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
        nob_da_append(&params, exp);
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
    nob_da_append(&param, parse_string_expr(p));

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

    if (!next_tok(p)) {
        fprintf(stderr, "%s Error: Expected: ], got %s\n",
                to_string_pos(curr_tok(p).pos, 0), to_string_kind(curr_tok(p).kind));
        assert(false);
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
        nob_da_append(&elements, exp);
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

    Literal_Value_Type *lit_val = malloc(sizeof(Literal_Value_Type));
    assert(lit_val && "allocation failed");
    lit_val->string = curr.literal;

    Literal_Node node = {
        .value = lit_val,
    };

    next_tok(p);
    return create_expression(VAL_LITERAL_NODE, (Value_Type){ .literal_node = node }, pos);
}

Expression *parse_number_expr(Parser *p) {
    Token curr = curr_tok(p);
    Position pos = curr.pos;

    Literal_Value_Type *lit_val = malloc(sizeof(Literal_Value_Type));
    assert(lit_val && "allocation failed");

    if (curr.kind == LEXER_INT64) {
        int64_t parsed = strtoll(curr.literal, NULL, 10);
        lit_val->number = (Number){ .i = parsed };
    } else if (curr.kind == LEXER_FLOAT64) {
        double parsed = strtod(curr.literal, NULL);
        lit_val->number = (Number){ .f = parsed };
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

    Literal_Value_Type *lit_val = malloc(sizeof(Literal_Value_Type));
    assert(lit_val && "allocation failed");

    if (curr.kind == LEXER_FALSE) {
        lit_val->boolean = false;
    } else {
        lit_val->boolean = true;
    }

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
    Expression *left = parse_prefix(p);

    while (token_precedence(p) > precedence) {
        if (!has_infix_parser(curr_tok(p).kind)) break;
        left = parse_binop(p, left);
    }

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
        nob_da_append(&ast, exp);

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
int main(int argc, char **argv)
{
    char *file_name = "placeholder";
    char *text = "let x = 1 + 2";
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
    nob_da_foreach(Token, t, &tokens) {
        puts(to_string_token(*t, 0));
    }
    // lexer_check_utilities();

}



