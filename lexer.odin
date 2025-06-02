package main
import "core:fmt"
import "core:os"
import "core:io"
import "core:strings"

Lexer :: struct {
    curr: int,
    next: int,
    pos: Position,
    text: string,
}


Position :: struct {
    row: int,
    col: int,
    file_path: string,
}

Token :: struct {
    literal: string,
    kind: Kind,
    pos: Position,
}

Kind :: enum {
    LET,
    FN,
    RETURN,
    IDENT,
    DOT,
    EQUALS,       
    NUMBER,
    PLUS,
    MINUS,        
    ASTERISK,     
    FSLASH,       
    BSLASH,       
    LPAREN,       
    RPAREN,       
    LBRACE,       
    RBRACE,       
    SQUOTE,       
    DQUOTE,       
    QUESTION_MARK,
    BANG,         
    COMMA,        
    NEWLINE,
    EOF
}

kind_to_string :: proc(kind: Kind) -> string {
    using Kind
    switch kind {
        case LET: return "LET"
        case FN: return "FN"
        case RETURN: return "RETURN"
        case IDENT: return "IDENT"
        case DOT: return "DOT"
        case EQUALS: return "EQUALS"
        case NUMBER: return "NUMBER"
        case PLUS: return "PLUS"
        case MINUS: return "MINUS"
        case ASTERISK: return "ASTERISK"
        case FSLASH: return "FSLASH"
        case BSLASH: return "BSLASH"
        case LPAREN: return "LPAREN"
        case RPAREN: return "RPAREN"
        case LBRACE: return "LBRACE"
        case RBRACE: return "RBRACE"
        case SQUOTE: return "SQUOTE"
        case DQUOTE: return "DQUOTE"
        case QUESTION_MARK: return "QUESTION_MARK"
        case BANG: return "BANG"
        case COMMA: return "COMMA"
        case NEWLINE: return "NEWLINE"
        case EOF: return "EOF"
        case : {
            assert(false, "UNREACHABLE")
        }
    }
    return "INVALID"

}

position_to_string :: proc(pos: Position) -> string { 
    out: strings.Builder
    strings.builder_init(&out)

    fmt.sbprintf(&out ,"%s:%d:%d \n", pos.file_path, pos.row, pos.col) 
    return strings.to_string(out)
}

token_to_string :: proc(token: Token) -> string { 
    out: strings.Builder
    strings.builder_init(&out)
    lit := token.literal == "\n" ? "\\n": token.literal

    fmt.sbprintf(&out ,"Token: \n") 
    fmt.sbprintf(&out ,"    literal: %s\n",  lit)
    fmt.sbprintf(&out ,"    kind: %s\n",     to_string(token.kind))
    fmt.sbprintf(&out ,"    position: %s\n", to_string(token.pos))
    return strings.to_string(out)
}

to_string :: proc{kind_to_string, token_to_string, position_to_string}

print_token :: proc(token: Token) {
    fmt.printf("%s\n", to_string(token))
}

print :: proc{print_token}

shift :: proc(args: []string) -> ([]string, string) {
    return args[1:], args[0]
}

alphanumeric :: proc(c: u8) -> bool {
    switch (c) {
        case 'A'..='Z', 'a'..='z', '0'..='9': return true
        case : return false
    }
 }

alpha :: proc(c: u8) -> bool {
    switch (c) {
        case 'A'..='Z', 'a'..='z': return true
        case : return false
    }
 }


numeric :: proc(c: u8) -> bool {
    switch (c) {
        case '0'..='9': return true
        case : return false
    }
 }


next_char :: proc(l: ^Lexer) -> bool {
    if !(l.next < len(l.text)){
        return false
    }

    l.curr = l.next
    l.next += 1

    if curr_char(l) == '\n' {
        l.pos.col = 0
        l.pos.row += 1
    } else {
        l.pos.col += 1
    }

    return true
}

curr_char :: proc(l: ^Lexer) -> u8 {
    return l.text[l.curr]
}

peek_char :: proc(l: ^Lexer) -> u8 {
    return l.text[l.next]
}

lex_ident :: proc(l: ^Lexer) -> (string, bool) {
    tok: strings.Builder
    strings.builder_init(&tok)
    has_alpha := false
    has_num := false

    curr := curr_char(l)
    for  alphanumeric(curr) || curr == '-' || curr == '_' {
    if alpha(curr) || curr == '-' || curr == '_'{
        has_alpha = true
    }

    if numeric(curr) {
        has_num = true
    }

    strings.write_byte(&tok, curr)

    if !next_char(l) {
        break
    }

    curr = curr_char(l)
    }

    return strings.to_string(tok), !has_alpha && has_num
}

lex :: proc(l: ^Lexer) -> [dynamic]Token {
    token : Token 
    tokens: [dynamic]Token

    next_char(l)

    using Kind
    for {
        switch (curr_char(l)) {
            case 'A'..='Z', 'a'..='z', '0'..='9': {
                tok, is_num := lex_ident(l)

                if is_num { 
                    token = Token{ 
                        kind = NUMBER,
                        literal = tok,
                        pos = l.pos
                    } 
                } else {

                    switch tok {
                        case "let": {
                            token = Token{ 
                                kind = LET,
                                literal = tok,
                                pos = l.pos
                            }
                        }
                        case "fn": {
                            token = Token{ 
                                kind = FN,
                                literal = tok,
                                pos = l.pos
                            }
                        }

                        case "return": {
                            token = Token{ 
                                kind = RETURN,
                                literal = tok,
                                pos = l.pos
                            }
                        }
                        case : {
                            token = Token{ 
                                kind = IDENT,
                                literal = tok,
                                pos = l.pos
                            }
                        }
                    }
                }
            }

            case '.': token = Token{ 
                kind = DOT,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '=': token = Token{ 
                kind = EQUALS,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            }

            case '+': token = Token{ 
                kind = PLUS,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '-': token = Token{ 
                kind = MINUS        ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '*': token = Token{ 
                kind = ASTERISK     ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '/': token = Token{ 
                kind = FSLASH       ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '\\': token = Token{ 
                kind = BSLASH       ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '(': token = Token{ 
                kind = LPAREN       ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case ')': token = Token{ 
                kind = RPAREN       ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 
            
            case '{': token = Token{ 
                kind = LBRACE       ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '}': token = Token{ 
                kind = RBRACE       ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '\'': token = Token{ 
                kind = SQUOTE       ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '\"': token = Token{ 
                kind = DQUOTE       ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 
            
            case '?': token = Token{ 
                kind = QUESTION_MARK,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '!': token = Token{ 
                kind = BANG         ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case ',': token = Token{ 
                kind = COMMA ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case '\n': token = Token{ 
                kind = NEWLINE       ,
                literal = string([]u8{curr_char(l)}),
                pos = l.pos
            } 

            case ' ', '\t', '\r': {
                if !next_char(l) {
                    break
                }
                continue
            }

        }

        append(&tokens, token)

        if !next_char(l) {
            break
        }

        append(&tokens, Token{
            kind = EOF,
            literal = "EOF",
            pos = l.pos
        })
    }
    return tokens
}


// main :: proc() {
//
//     args := os.args
//     if len(args) < 2 {
//     fmt.println("USAGE: ./norse <source_file>")
//     os.exit(69)
//     }
//     name : string
//     file_name: string
//     args, name = shift(args)
//     args, file_name = shift(args)
//
//
//     raw_code, ok := os.read_entire_file_from_filename(file_name)
//     if !ok {
//         fmt.eprintln("Failed to load the file!")
//         return
//     }
//     defer delete(raw_code) 
//
//     lexer := Lexer{ 
//         curr = 0,
//         next = 0,
//         text = string(raw_code)
//     }
//
//     pos := Position{ 
//         row = 0,
//         col = 0,
//         file_path = file_name,
//     }
//
//     l := &lexer
//     tokens := lex(l)
//
//
//     for token in tokens {
//        print(token)
//     }
//
// }
