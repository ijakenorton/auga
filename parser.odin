package main
import "core:fmt"
import "core:os"
import "core:io"
import "core:strings"

Parser :: struct {
    curr: int,
    next: int,
    tokens: [dynamic]Token,
}

Ast :: struct {
    expressions: []Expression,
}

Expression_Type :: enum {
    NUMBER,
    IDENTIFIER,
    LET,
    FUNCTION,
    FUNCTION_CALL,
    BLOCK,
    INFIX,
}

Binop :: struct {
    kind: Kind,
    left: ^Expression,
    right: ^Expression,
}

Binding :: struct {
    kind: Kind,
    left: ^Expression,
    right: ^Expression,
}

Value_Type :: union {
    Binop,
    string
}

Expression :: struct {
    type: Expression_Type,
    value: Value_Type,
    position: Position,
}

// position_to_string :: proc(pos: Position) -> string { 
//     out: strings.Builder
//     strings.builder_init(&out)
//
//     fmt.sbprintf(&out ,"\nPosition: \n") 
//     fmt.sbprintf(&out ,"    row: %d\n",  pos.row)
//     fmt.sbprintf(&out ,"    col: %d\n",     pos.col)
//     fmt.sbprintf(&out ,"    file_path: %s\n", pos.file_path)
//     return strings.to_string(out)
// }
//
// token_to_string :: proc(token: Token) -> string { 
//     out: strings.Builder
//     strings.builder_init(&out)
//     lit := token.literal == "\n" ? "\\n": token.literal
//
//     fmt.sbprintf(&out ,"Token: \n") 
//     fmt.sbprintf(&out ,"    literal: %s\n",  lit)
//     fmt.sbprintf(&out ,"    kind: %s\n",     to_string(token.kind))
//     fmt.sbprintf(&out ,"    position: %s\n", to_string(token.pos))
//     return strings.to_string(out)
// }
//
// to_string :: proc{kind_to_string, token_to_string, position_to_string}

// print_token :: proc(token: Token) {
//     fmt.printf("%s\n", to_string(token))
// }
//
// print :: proc{print_token}

// Kind :: enum {
//     LET,
//     FN,
//     RETURN,
//     IDENT,
//     DOT,
//     EQUALS,       
//     NUMBER,
//     PLUS,
//     MINUS,        
//     ASTERISK,     
//     FSLASH,       
//     BSLASH,       
//     LPAREN,       
//     RPAREN,       
//     LBRACE,       
//     RBRACE,       
//     SQUOTE,       
//     DQUOTE,       
//     QUESTION_MARK,
//     BANG,         
//     COMMA,        
//     NEWLINE       
// }


next_tok :: proc(p: ^Parser) -> bool {
    if (peek_tok(p).kind == Kind.EOF){
        return false
    }

    p.curr = p.next
    p.next += 1

    return true
}

curr_tok :: proc(p: ^Parser) -> Token {
    return p.tokens[p.curr]
}

peek_tok :: proc(p: ^Parser) -> Token {
    return p.tokens[p.next]
}

parse :: proc(p: ^Parser) -> [dynamic]Token {
    token : Token 
    tokens: [dynamic]Token

    error_string: strings.Builder
    strings.builder_init(&error_string)

    next_tok(p)

    using Kind
    for {
        switch (curr_tok(p).kind) {
            case LET: { 
                assert(false, fmt.aprintf("LET not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case FN: { 
                assert(false, fmt.aprintf("FN not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case RETURN: { 
                assert(false, fmt.aprintf("RETURN not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case IDENT: { 
                assert(false, fmt.aprintf("IDENT not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case DOT: { 
                assert(false, fmt.aprintf("DOT not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case EQUALS: { 
                assert(false, fmt.aprintf("EQUALS not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case NUMBER: { 
                assert(false, fmt.aprintf("NUMBER not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case PLUS: { 
                assert(false, fmt.aprintf("PLUS not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case MINUS: { 
                assert(false, fmt.aprintf("MINUS not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case ASTERISK: { 
                assert(false, fmt.aprintf("ASTERISK not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case FSLASH: { 
                assert(false, fmt.aprintf("FSLASH not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case BSLASH: { 
                assert(false, fmt.aprintf("BSLASH not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case LPAREN: { 
                assert(false, fmt.aprintf("LPAREN not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case RPAREN: { 
                assert(false, fmt.aprintf("RPAREN not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case LBRACE: { 
                assert(false, fmt.aprintf("LBRACE not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case RBRACE: { 
                assert(false, fmt.aprintf("RBRACE not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case SQUOTE: { 
                assert(false, fmt.aprintf("SQUOTE not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case DQUOTE: { 
                assert(false, fmt.aprintf("DQUOTE not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case QUESTION_MARK: { 
                assert(false, fmt.aprintf("QUESTION_MARK not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case BANG: { 
                assert(false, fmt.aprintf("BANG not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case COMMA: { 
                assert(false, fmt.aprintf("COMMA not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case NEWLINE: { 
                assert(false, fmt.aprintf("NEWLINE not implemented at: %s", to_string(curr_tok(p).pos)))
            }

            case EOF: { 
                assert(false, fmt.aprintf("EOF not implemented at: %s", to_string(curr_tok(p).pos)))
            }
        }

        if !next_tok(p) {
            break
        }
    }
    return tokens
}


main :: proc() {

    args := os.args
    if len(args) < 2 {
        fmt.println("USAGE: ./norse <source_file>")
        os.exit(69)
    }
    name : string
    file_name: string
    args, name = shift(args)
    args, file_name = shift(args)


    raw_code, ok := os.read_entire_file_from_filename(file_name)
    if !ok {
        fmt.eprintln("Failed to load the file!")
        return
    }
    defer delete(raw_code) 


    l := &Lexer{ 
        curr = 0,
        next = 0,
        pos = Position{ 
            row = 0,
            col = 0,
            file_path = file_name,
        },
        text = string(raw_code)
    }

    tokens := lex(l)

    p := &Parser{
        curr = 0,
        next = 0,
        tokens = tokens,
    }

    parse(p)

}
