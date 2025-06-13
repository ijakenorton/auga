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
    PRINT,
    IDENT,
    STRING,
    DOT,
    EQUALS,       
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
    SQUOTE,       
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
        case PRINT: return "PRINT"
        case IDENT: return "IDENT"
        case DOT: return "DOT"
        case EQUALS: return "EQUALS"
        case INT64: return "INT64"
        case FLOAT64: return "FLOAT64"
        case PLUS: return "PLUS"
        case MINUS: return "MINUS"
        case MULTIPLY: return "MULTIPLY"
        case DIVIDE: return "DIVIDE"
        case BSLASH: return "BSLASH"
        case LPAREN: return "LPAREN"
        case RPAREN: return "RPAREN"
        case LBRACE: return "LBRACE"
        case RBRACE: return "RBRACE"
        case LBRACKET: return "LBRACKET"
        case RBRACKET: return "RBRACKET"
        case SQUOTE: return "SQUOTE"
        case STRING: return "STRING"
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

expression_to_string :: proc(expr: ^Expression, indent: int = 0) -> string {
    if expr == nil do return "nil"
    
    sb: strings.Builder
    strings.builder_init(&sb)
    
    // Add indentation
    for i in 0..<indent {
        strings.write_string(&sb, "  ")
    }
    
    #partial switch expr.kind {
    case .LITERAL:
        fmt.sbprintf(&sb, "LITERAL(%v)", expr.value.(Literal_Node))
        
    case .IDENTIFIER:
        fmt.sbprintf(&sb, "Identifier(%v)", expr.value.(string))
        
    case .LET:
        binding := expr.value.(Binding)
        fmt.sbprintf(&sb, "Let(\n")
        for i in 0..<indent+1 {
            strings.write_string(&sb, "  ")
        }
        fmt.sbprintf(&sb, "name: %s,\n", binding.name)
        for i in 0..<indent+1 {
            strings.write_string(&sb, "  ")
        }
        fmt.sbprintf(&sb, "value: %s\n", expression_to_string(binding.value, indent+1))
        for i in 0..<indent {
            strings.write_string(&sb, "  ")
        }
        strings.write_string(&sb, ")")
        
    case .INFIX:
        binop := expr.value.(Binop)
        fmt.sbprintf(&sb, "Infix(\n")
        for i in 0..<indent+1 {
            strings.write_string(&sb, "  ")
        }
        fmt.sbprintf(&sb, "op: %s,\n", to_string(binop.kind))
        for i in 0..<indent+1 {
            strings.write_string(&sb, "  ")
        }
        fmt.sbprintf(&sb, "left: %s,\n", expression_to_string(binop.left, indent+1))
        for i in 0..<indent+1 {
            strings.write_string(&sb, "  ")
        }
        fmt.sbprintf(&sb, "right: %s\n", expression_to_string(binop.right, indent+1))
        for i in 0..<indent {
            strings.write_string(&sb, "  ")
        }
        strings.write_string(&sb, ")")
        
    case .FUNCTION:
        function := expr.value.(Function)
        fmt.sbprintf(&sb, "Function(\n")
        
        // Print arguments
        for i in 0..<indent+1 {
            strings.write_string(&sb, "  ")
        }
        fmt.sbprintf(&sb, "args: [")
        if len(function.args) > 0 {
            fmt.sbprintf(&sb, "\n")
            for arg, i in function.args {
                for j in 0..<indent+2 {
                    strings.write_string(&sb, "  ")
                }
                fmt.sbprintf(&sb, "%s", expression_to_string(arg, indent+2))
                if i < len(function.args) - 1 {
                    fmt.sbprintf(&sb, ",")
                }
                fmt.sbprintf(&sb, "\n")
            }
            for i in 0..<indent+1 {
                strings.write_string(&sb, "  ")
            }
        }
        fmt.sbprintf(&sb, "],\n")
        
        // Print body/value
        for i in 0..<indent+1 {
            strings.write_string(&sb, "  ")
        }
        fmt.sbprintf(&sb, "body: [")
        if len(function.value) > 0 {
            fmt.sbprintf(&sb, "\n")
            for stmt, i in function.value {
                for j in 0..<indent+2 {
                    strings.write_string(&sb, "  ")
                }
                fmt.sbprintf(&sb, "%s", expression_to_string(stmt, indent+2))
                if i < len(function.value) - 1 {
                    fmt.sbprintf(&sb, ",")
                }
                fmt.sbprintf(&sb, "\n")
            }
            for i in 0..<indent+1 {
                strings.write_string(&sb, "  ")
            }
        }
        fmt.sbprintf(&sb, "]\n")
        
        for i in 0..<indent {
            strings.write_string(&sb, "  ")
        }
        strings.write_string(&sb, ")")
    }
    
    return strings.to_string(sb)
}


position_to_string :: proc(pos: Position) -> string { 
    out: strings.Builder
    strings.builder_init(&out)

    fmt.sbprintf(&out ,"%s(%d:%d)", pos.file_path, pos.row, pos.col) 
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

to_string :: proc{kind_to_string, token_to_string, position_to_string, expression_to_string}

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
        case "let":    return .LET
        case "fn":     return .FN  
        case "return": return .RETURN
        case "print": return .PRINT
        case:          return .IDENT
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

    using Kind
    for {

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

            case '=': {
                token = Token{ 
                    kind = EQUALS,
                    literal = "=",
                    pos = l.pos
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

            case '/': {
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
            
            case '{': { 
                token = Token{ 
                    kind = LBRACE,
                    literal = "}",
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
            case ' ', '\n', '\t', '\r': {
                assert(false, "SPACE leaked")
            }

        }

        append(&tokens, token)
        // fmt.printfln("%s", to_string(token))
    }

    append(&tokens, Token{
        kind = EOF,
        literal = "EOF",
        pos = l.pos
    })
    return tokens
}

