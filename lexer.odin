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
    FOR,
    WHILE,
    RETURN,
    IF,
    ELSE,
    TRUE,
    FALSE,
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
    INT64,
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
    EOF
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

empty :: proc(l: ^Lexer) -> bool {
    return l.next >= len(l.text)
}

next_char :: proc(l: ^Lexer) -> bool {
    if  l.next >= len(l.text) {
        return false
    }
    
    curr := curr_char(l)
    if curr == '\n' {
        l.pos.row += 1
        l.pos.col = 1
    } else {
        l.pos.col += 1
    }
    
    l.curr = l.next
    l.next += 1
    return true
}

skip_whitespace :: proc(l: ^Lexer) {
    for l.curr < len(l.text) {
        curr := curr_char(l)

        if curr != ' ' && curr != '\t' && curr != '\r' && curr != '\n' {
            break
        }

        if !next_char(l) {
            break
        }
    }
}

curr_char :: proc(l: ^Lexer) -> u8 {
    return l.text[l.curr]
}

peek_char :: proc(l: ^Lexer) -> u8 {
    return l.text[l.next]
}


//Assume curr_char(l) == "\""
lex_string :: proc(l:^Lexer) -> Token {

    assert(curr_char(l) == '\"', fmt.aprintf("%s Error: lexing error, this should be \"", to_string((l.pos))))
    if !next_char(l) {
            assert(false, fmt.aprintf("%s Error: unexpected end of string %s", to_string((l.pos))))
    }

    tok: strings.Builder
    strings.builder_init(&tok)

    //take_while exclusive
    //TODO: Add support for escaping strings
    for  {

        strings.write_byte(&tok, curr_char(l))

        if !next_char(l) {
            break
        }

        if curr_char(l) == '\"' {
            break
        }
    }

    next_char(l) 

    return Token {
        kind = .STRING,
        literal = strings.to_string(tok),
        pos = l.pos
    }
}

lex_identifier :: proc(l: ^Lexer) -> Token {

    curr := curr_char(l)
    assert(curr == '_' || curr == '-' || alphanumeric(curr_char(l)), fmt.aprintf("%s Error: lexing error", to_string((l.pos))))
    tok: strings.Builder
    strings.builder_init(&tok)

    // sort of a take_while might be useful to extract at somepoint
    for curr == '_' || curr == '-' || alphanumeric(curr) {
        strings.write_byte(&tok, curr)

        if !next_char(l) {
            break
        }
        curr = curr_char(l)
    }

    literal := strings.to_string(tok)
    kind := keyword_or_identifier(literal)


    return Token {
        kind = kind,
        literal = literal,
        pos = l.pos
    }
}

keyword_or_identifier :: proc(literal: string) -> Kind {
    switch literal {
        case "let": return .LET
        case "fn": return .FN  
        case "for": return .FOR  
        case "while": return .WHILE
        case "return": return .RETURN
        case "print": return .PRINT
        case "if": return .IF
        case "else": return .ELSE
        case "true": return .TRUE
        case "false": return .FALSE
        case "shell": return .SHELL
        case: return .IDENT
    }
}

lex_number :: proc(l: ^Lexer) -> Token {
    curr := curr_char(l)
    assert(curr == '.' || numeric(curr), fmt.aprintf("%s Error: lexing error", to_string((l.pos))))
    tok: strings.Builder
    strings.builder_init(&tok)
    has_dot := false

    //take_while
    for curr == '.' || numeric(curr) {
        if curr == '.' {
            has_dot = true
        }

        strings.write_byte(&tok, curr)

        if !next_char(l) {
            break
        }

        curr = curr_char(l)
    }
    kind := has_dot ? Kind.FLOAT64: Kind.INT64

    return Token {
        kind = kind,
        literal = strings.to_string(tok),
        pos = l.pos
    }
}

lex :: proc(l: ^Lexer) -> [dynamic]Token {
    token : Token 
    tokens: [dynamic]Token
    
    curr : u8

    next_char(l)
    max_depth := 10000

    using Kind
    for {

        assert(max_depth > 0, fmt.aprintf("\n%s Error: lexing error", to_string((l.pos))))

        skip_whitespace(l) // Always skip whitespace first
        if empty(l) {
            break // End of input
        }
                
        curr = curr_char(l)
        switch (curr) {
            case 'A'..='Z', 'a'..='z': {
                token = lex_identifier(l)
            }

            case '0'..='9': {
                token = lex_number(l)
            }

            //Could be cleaner
            case '=': {
                if peek_char(l) == '=' {
                    next_char(l)
                    token = Token{ 
                        kind = SAME,
                        literal = "==",
                        pos = l.pos
                    }
                } else {
                    token = Token{ 
                        kind = EQUALS,
                        literal = "=",
                        pos = l.pos
                    }
                }

                next_char(l)
            }

            case '+': {
                token = Token{ 
                    kind = PLUS,
                    literal = "+",
                    pos = l.pos
                }
                next_char(l)
            } 

            case '-': {
                token = Token{ 
                    kind = MINUS,
                    literal = "-",
                    pos = l.pos
                }
                next_char(l)
            } 

            case '*': {
                token = Token{ 
                    kind = MULTIPLY,
                    literal = "*",
                    pos = l.pos
                } 

                next_char(l)
            }

            case '<': {
                token = Token{ 
                    kind = LT,
                    literal = "<",
                    pos = l.pos
                } 

                next_char(l)
            }
            case '>': {
                token = Token{ 
                    kind = GT,
                    literal = ">",
                    pos = l.pos
                } 

                next_char(l)
            }
            case '/': {
                if peek_char(l) == '/' {
                    next_char(l)
                    for peek_char(l) != '\n' {
                        next_char(l)
                    }

                    next_char(l)
                    continue
                }
                token = Token{ 
                    kind = DIVIDE,
                    literal = "/",
                    pos = l.pos
                }

                next_char(l)
            } 

            case '\\': token = Token{ 
                kind = BSLASH,
                literal = "\\",
                pos = l.pos
            } 

            case '(': { 
                token = Token{ 
                    kind = LPAREN,
                    literal = "(",
                    pos = l.pos
                }
                next_char(l)
            } 

            case ')': { 
                token = Token{ 
                    kind = RPAREN,
                    literal = ")",
                    pos = l.pos
                }
                next_char(l)
            } 

            case '[': { 
                token = Token{ 
                    kind = LBLOCK,
                    literal = "[",
                    pos = l.pos
                }
                next_char(l)
            } 

            case ']': { 
                token = Token{ 
                    kind = RBLOCK,
                    literal = "]",
                    pos = l.pos
                }
                next_char(l)
            } 
            
            case '{': { 
                token = Token{ 
                    kind = LBRACE,
                    literal = "{",
                    pos = l.pos
                }
                next_char(l)
            } 

            case '}': { 
                token = Token{ 
                    kind = RBRACE,
                    literal = "}",
                    pos = l.pos
                }
                next_char(l)
            } 

            case '\'': { 
                token = Token{ 
                    kind = SQUOTE,
                    literal = "\\",
                    pos = l.pos
                }

                next_char(l)
            } 

            case '%': { 
                token = Token{ 
                    kind = MOD,
                    literal = "%",
                    pos = l.pos
                }

                next_char(l)
            } 

            case '\"': { 
                token = lex_string(l)
            } 
            
            case '?': {
                assert(false, "QUESTION_MARK not implemented in lexer")
                token = Token{ 
                    kind = QUESTION_MARK,
                    literal = "?",
                    pos = l.pos
                }

                next_char(l)
            } 

            case '!': {
                assert(false, "BANG not implemented in lexer")
                token = Token{ 
                    kind = BANG,
                    literal = "!",
                    pos = l.pos
                }

                next_char(l)
            } 

            case ',': {
                assert(false, " COMMA not implemented in lexer")
                token = Token{ 
                    kind = BANG,
                    literal = "!",
                    pos = l.pos
                }

                next_char(l)
            } 
            case '.': {
                if peek_char(l) == '.' {
                    next_char(l)
                    token = Token{ 
                        kind = DOTDOT,
                        literal = "..",
                        pos = l.pos
                    }
                } else {

                    assert(false, fmt.aprintf("%s Error: unexpected \".\"", to_string((l.pos))))
                }

                next_char(l)
            }
            case ' ', '\n', '\t', '\r': {
                assert(false, "SPACE leaked")
            }

            case : {
                assert(false, fmt.aprintf("\n%s Error: lexing error, unlexible char %c", to_string((l.pos)), curr_char(l)))
            }

        }

        append(&tokens, token)
        // fmt.printfln("%s", to_string(token))
        max_depth -= 1
    }

    append(&tokens, Token{
        kind = EOF,
        literal = "EOF",
        pos = l.pos
    })
    return tokens
}

