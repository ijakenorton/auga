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
    LET = 0,
    FN,
    FOR,
    WHILE,
    RETURN,
    IF,
    ELSE,
    AUGA_TRUE,
    AUGA_FALSE,
    MOD,
    PRINT,
    SHELL,
    IDENT,
    STRING,
    DOT,
    EQUALS,       
    SAME,
    LT,
    GT,
    DOTDOT,
    AUGA_INT64,
    AUGA_FLOAT64,
    PLUS,
    MINUS,        
    MULTIPLY,     
    DIVIDE,       
    BSLASH,       
    LPAREN,       
    RPAREN,       
    LBRACKET,       
    RBRACKET,       
    LBRACE,       
    RBRACE,       
    LBLOCK,       
    RBLOCK,       
    SQUOTE,       
    QUESTION_MARK,
    BANG,         
    COMMA,        
    NEWLINE,
    AUGA_EOF,
} Kind;

char *to_string_kind(Kind kind) {
    if      (kind == LET)           return "LET";
    else if (kind == FN)            return "FN";
    else if (kind == LT)            return "LT";
    else if (kind == GT)            return "GT";
    else if (kind == RETURN)        return "RETURN";
    else if (kind == FOR)           return "FOR";
    else if (kind == WHILE)         return "WHILE";
    else if (kind == IF)            return "IF";
    else if (kind == ELSE)          return "ELSE";
    else if (kind == AUGA_TRUE)     return "TRUE";
    else if (kind == AUGA_FALSE)    return "FALSE";
    else if (kind == PRINT)         return "PRINT";
    else if (kind == SHELL)         return "SHELL";
    else if (kind == IDENT)         return "IDENT";
    else if (kind == DOT)           return "DOT";
    else if (kind == DOTDOT)        return "DOTDOT";
    else if (kind == EQUALS)        return "EQUALS";
    else if (kind == SAME)          return "SAME";
    else if (kind == AUGA_INT64)    return "INT64";
    else if (kind == AUGA_FLOAT64)  return "FLOAT64";
    else if (kind == PLUS)          return "PLUS";
    else if (kind == MINUS)         return "MINUS";
    else if (kind == MOD)           return "MOD";
    else if (kind == MULTIPLY)      return "MULTIPLY";
    else if (kind == DIVIDE)        return "DIVIDE";
    else if (kind == BSLASH)        return "BSLASH";
    else if (kind == LPAREN)        return "LPAREN";
    else if (kind == RPAREN)        return "RPAREN";
    else if (kind == LBRACE)        return "LBRACE";
    else if (kind == RBRACE)        return "RBRACE";
    else if (kind == LBLOCK)        return "LBLOCK";
    else if (kind == RBLOCK)        return "RBLOCK";
    else if (kind == LBRACKET)      return "LBRACKET";
    else if (kind == RBRACKET)      return "RBRACKET";
    else if (kind == SQUOTE)        return "SQUOTE";
    else if (kind == STRING)        return "STRING";
    else if (kind == QUESTION_MARK) return "QUESTION_MARK";
    else if (kind == BANG)          return "BANG";
    else if (kind == COMMA)         return "COMMA";
    else if (kind == NEWLINE)       return "NEWLINE";
    else if (kind == AUGA_EOF)      return "EOF";

    assert(false && "UNREACHABLE");
    return "INVALID";
}

Kind keyword_or_identifier(char* literal) {
    if      (strcmp(literal, "let")    == 0 ) return LET;     
    else if (strcmp(literal, "fn")     == 0 ) return FN;     
    else if (strcmp(literal, "for")    == 0 ) return FOR;     
    else if (strcmp(literal, "while")  == 0 ) return WHILE;     
    else if (strcmp(literal, "return") == 0 ) return RETURN; 
    else if (strcmp(literal, "print")  == 0 ) return PRINT;     
    else if (strcmp(literal, "if")     == 0 ) return IF;     
    else if (strcmp(literal, "else")   == 0 ) return ELSE;     
    else if (strcmp(literal, "true")   == 0 ) return AUGA_TRUE;
    else if (strcmp(literal, "false")  == 0 ) return AUGA_FALSE;
    else if (strcmp(literal, "shell")  == 0 ) return SHELL;     

    return IDENT;               
}

typedef struct {
    int row;
    int col;
    char * file_path;
} Position;

typedef struct {
    char* literal;
    Kind kind;
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
        .kind = STRING,
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
    Kind kind = keyword_or_identifier(lit);

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
    Kind kind = has_dot ? AUGA_FLOAT64: AUGA_INT64;

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
                        .kind = SAME,
                        .literal = "==",
                        .pos = l->pos,
                    };
                } else {
                    token = (Token){
                        .kind = EQUALS,
                        .literal = "=",
                        .pos = l->pos,
                    };
                }
                next_char(l);
            } break;

            case '+': {
                token = (Token){
                    .kind = PLUS,
                    .literal = "+",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '-': {
                token = (Token){
                    .kind = MINUS,
                    .literal = "-",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '*': {
                token = (Token){
                    .kind = MULTIPLY,
                    .literal = "*",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '<': {
                token = (Token){
                    .kind = LT,
                    .literal = "<",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '>': {
                token = (Token){
                    .kind = GT,
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
                    .kind = DIVIDE,
                    .literal = "/",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '\\': {
                token = (Token){
                    .kind = BSLASH,
                    .literal = "\\",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '(': {
                token = (Token){
                    .kind = LPAREN,
                    .literal = "(",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case ')': {
                token = (Token){
                    .kind = RPAREN,
                    .literal = ")",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '[': {
                token = (Token){
                    .kind = LBLOCK,
                    .literal = "[",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case ']': {
                token = (Token){
                    .kind = RBLOCK,
                    .literal = "]",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '{': {
                token = (Token){
                    .kind = LBRACE,
                    .literal = "{",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '}': {
                token = (Token){
                    .kind = RBRACE,
                    .literal = "}",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '\'': {
                token = (Token){
                    .kind = SQUOTE,
                    .literal = "'",
                    .pos = l->pos,
                };
                next_char(l);
            } break;

            case '%': {
                token = (Token){
                    .kind = MOD,
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
                        .kind = DOTDOT,
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
        .kind = AUGA_EOF,
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



