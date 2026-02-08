#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#define NOB_IMPLEMENTATION
#include "nob.h"

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
    FLOAT64,
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
    size_t curr;
    size_t next;
    Position pos;
    char * text;
} Lexer;

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
    return sb.items;
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
    return l->next >= strlen(l->text);
}

char curr_char(Lexer* l) {
    return l->text[l->curr];
}

char next_char(Lexer* l) {
    return l->text[l->next];
}

//Assume curr_char(l) == '"'
Token lex_string(Lexer* l) {
    assert(curr_char(l) == '\"');
    printf("%s Error: lexing error, this should be \"", to_string_pos((l->pos), 0));
    if (!next_char(l)) {
            assert(false && printf("%s Error: unexpected end of string %s", to_string_pos((l->pos), 0)));
    }

    String_Builder tok = {0};
    //take_while exclusive
    //TODO: Add support for escaping strings
    for  (;;){

        sb_append(&tok, curr_char(l));

        if (!next_char(l)) {
            break;
        }

        if (curr_char(l) == '\"') {
            break;
        }
    }
    
    sb_append_null(&tok);

//================================================================================

    next_char(l) ;
// TODO: UNSURE IF I CAN PASS ITEMS LIKE THIS
    return (Token){
        kind = STRING,
        literal = tok.items,
        pos = l.pos,
    };
}
/*
//================================================================================\\
//LEXER_END
\\================================================================================//
*/
int main(int argc, char **argv)
{
    NOB_GO_REBUILD_URSELF(argc, argv);
    Nob_Cmd cmd = {0};
    nob_cmd_append(&cmd, "cc", "-Wall", "-Wextra", "-o", "auga", "auga.c");
    if (!nob_cmd_run(&cmd)) return 1;
    return 0;
}



