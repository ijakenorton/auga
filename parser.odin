package main
import "core:fmt"
import "core:os"
import "core:io"
import "core:strings"
import "core:mem"
import "core:strconv"

Precedence :: enum {
    LOWEST = 1,
    EQUALS = 2,
    LESSGREATER = 3,
    SUM = 4,
    PRODUCT = 5,
    PREFIX = 6,
    CALL = 7,
    INDEX = 8,
}

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

Literal :: enum {
    NUMBER,
    STRING,
}

Literal_Type :: union {
    int,
    string,
}

Literal_Node :: struct {
    kind: Literal,
    value: Literal_Type,
}

Binding :: struct {
    name: string,
    exp: ^Expression,
    pos: Position,
}

Value_Type :: union {
    Binop,
    string,
    ^Expression
}

Expression :: struct {
    type: Expression_Type,
    value: Value_Type,
    pos: Position,
}

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

peek_precedence :: proc(p: ^Parser) -> Precedence {
    // return p.tokens[p.next].kind
    return .LOWEST
}

token_precedence :: proc(kind: Kind) -> Precedence {
    using Kind
    #partial switch kind {
    case EQUALS:
            return .EQUALS
        case PLUS, MINUS:
            return .SUM
        case MULTIPLY:
            return .PRODUCT
        case LPAREN: // for function calls
            return .CALL
        case:
            return .LOWEST
    }
}

expect :: proc(p: ^Parser, kind: Kind) -> bool {
    return curr_tok(p).kind == kind
}

next_and_expect :: proc(p: ^Parser, kind: Kind) -> Token {
    curr := curr_tok(p)

    if !next_tok(p) {

        fmt.printfln("%s Expected: %s, got %s", to_string(curr.pos), to_string(kind), to_string(curr_tok(p).kind))
        assert(false)
    }

    curr = curr_tok(p)
    if !expect(p, kind) {
        fmt.printfln("%s Expected: %s, got %s", to_string(curr.pos), to_string(kind), to_string(curr_tok(p).kind))
        assert(false)
    }

    return curr_tok(p)
}

parse_let :: proc(p: ^Parser) -> ^Expression {
    using Kind
    curr := curr_tok(p)
    
    exp := new(Expression, context.temp_allocator)

    pos := curr.pos
    curr = next_and_expect(p, IDENT)
    name := curr.literal

    curr = next_and_expect(p, EQUALS)

    if !next_tok(p) {
        fmt.printfln("%s Unexpected EOF after EQUALS", to_string(curr.pos))
        assert(false)
    }
    exp = parse_expression(p)


    let := Binding{
        name = curr.literal,
        exp = exp,
        pos = pos,
    }

    return exp
}

parse_number :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    pos := curr.pos
    value, ok := strconv.parse_int(curr.literal)
    if !ok {
        fmt.printfln("%s could not parse int: %s, got %s", to_string(curr.pos), curr.literal)
        assert(false)
    }

    exp := new(Expression, context.temp_allocator)
    
    exp.type = .NUMBER
    exp.value = exp
    exp.pos = pos

    return exp
}


parse_expression :: proc(p: ^Parser) -> ^Expression {
    return parse_precedence(p, .LOWEST)
}

parse_precedence :: proc(p: ^Parser, precedence: Precedence) -> ^Expression {
    // curr := curr_tok(p)
    // exp : ^Expression
    //
    // pos := curr.pos
    left := parse_prefix(p)

    return left
}

parse_identifier :: proc(p: ^Parser) -> ^Expression {
    // using Expression_Type
    curr := curr_tok(p)
    pos := curr.pos
    name := curr.literal
    exp := new(Expression, context.temp_allocator)

    id := Expression{
        type = .IDENTIFIER,
        value = curr.literal,
        pos = pos,
    }

    return exp
}

parse_prefix :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)

    pos := curr.pos
    using Kind
    #partial switch (curr.kind) {
        case LET: return parse_let(p)
        case IDENT: return parse_identifier(p)
        case NUMBER: return parse_number(p)
    }
    fmt.printfln("%s unknown prefix expression expected LET | IDENT | NUMBER: %s, got %s", curr.pos, to_string(curr.kind), to_string(curr_tok(p).kind))
    assert(false)
    return nil
}


parse :: proc(p: ^Parser) -> [dynamic]Token {
    token : Token 
    tokens: [dynamic]Token

    error_string: strings.Builder
    strings.builder_init(&error_string)

    next_tok(p)
    curr : Token

    using Kind
    for {
        curr = curr_tok(p)
        exp := parse_expression(p)

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
            row = 1,
            col = 1,
            file_path = file_name,
        },
        text = string(raw_code)
    }

    tokens := lex(l)


    // p := &Parser{
    //     curr = 0,
    //     next = 0,
    //     tokens = tokens,
    // }
    //
    // parse(p)
    // free_all(context.temp_allocator)

}

    //     case FN: { 
    //         assert(false, fmt.aprintf("FN not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case RETURN: { 
    //         assert(false, fmt.aprintf("RETURN not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case IDENT: { 
    //         assert(false, fmt.aprintf("IDENT not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case NUMBER: { 
    //         assert(false, fmt.aprintf("NUMBER not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case PLUS: { 
    //         assert(false, fmt.aprintf("PLUS not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case MINUS: { 
    //         assert(false, fmt.aprintf("MINUS not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case ASTERISK: { 
    //         assert(false, fmt.aprintf("ASTERISK not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case FSLASH: { 
    //         assert(false, fmt.aprintf("FSLASH not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case BSLASH: { 
    //         assert(false, fmt.aprintf("BSLASH not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case LPAREN: { 
    //         assert(false, fmt.aprintf("LPAREN not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case RPAREN: { 
    //         assert(false, fmt.aprintf("RPAREN not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case LBRACE: { 
    //         assert(false, fmt.aprintf("LBRACE not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case COMMA: { 
    //         assert(false, fmt.aprintf("COMMA not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case NEWLINE: { 
    //         assert(false, fmt.aprintf("NEWLINE not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case EOF: { 
    //         assert(false, fmt.aprintf("EOF not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    //
    //     case : { 
    //         assert(false, fmt.aprintf("UNKNOWN not implemented at: %s", to_string(curr_tok(p).pos)))
    //     }
    // }
