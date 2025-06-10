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
    LITERAL,
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

Literal_Kind :: enum {
    INT64,
    FLOAT64,
    STRING,
}

Literal_Node :: struct {
    kind: Literal_Kind,
    value: Literal_Value_Type,
}

Binding :: struct {
    name: string,
    exp: ^Expression,
    pos: Position,
}

Expression :: struct {
    type: Expression_Type,
    value: Value_Type,
    pos: Position,
}

Number :: union {
    i64,
    f64,
}

Literal_Value_Type :: union {
    Number,
    string,
}

Value_Type :: union {
    Binop,
    Binding,
    i64,
    f64,
    string,
    ^Expression,
    Literal_Node,
}

next_tok :: proc(p: ^Parser) -> bool {
    if (peek_tok(p).kind == Kind.EOF){
        return false
    }

    // fmt.printfln("NEXT_TOK: moving from curr=%d to curr=%d", p.curr, p.next)
    // fmt.printfln("NEXT_TOK: was on %v", curr_tok(p))
    
    p.curr = p.next
    p.next += 1
    
    // fmt.printfln("NEXT_TOK: now on %v", curr_tok(p))
    return true
}


curr_tok :: proc(p: ^Parser) -> Token {
    return p.tokens[p.curr]
}

peek_tok :: proc(p: ^Parser) -> Token {
    return p.tokens[p.next]
}

peek_precedence :: proc(p: ^Parser) -> Precedence {
    return token_precedence(p)
}

token_precedence :: proc(p: ^Parser) -> Precedence {
    kind := curr_tok(p).kind
    using Kind
    #partial switch kind {
        case EQUALS:
            return .EQUALS
        case PLUS, MINUS:
            return .SUM
        case MULTIPLY, DIVIDE:
            return .PRODUCT
        case LPAREN: 
            return .CALL
        case LET, EOF, INT64, FLOAT64, IDENT, STRING:
            return .LOWEST
        case:
            parser_errorf(curr_tok(p).pos, false, "Unexpected KIND: %s", to_string(curr_tok(p).kind))
            //UNREACHABLE
            return .LOWEST
    }
}

expect :: proc(p: ^Parser, kind: Kind) -> bool {
    return curr_tok(p).kind == kind
}

next_and_expect :: proc(p: ^Parser, kind: Kind) -> Token {
    curr := curr_tok(p)

    if !next_tok(p) {
        parser_errorf(curr.pos, false, "Expected: %s, got %s", to_string(kind), to_string(curr_tok(p).kind))
    }

    curr = curr_tok(p)
    if !expect(p, kind) {
        parser_errorf(curr.pos, false, "Expected: %s, got %s", to_string(kind), to_string(curr_tok(p).kind))
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
        parser_errorf(curr.pos, false, "Unexpected EOF after EQUALS")
    }
    exp = parse_expression(p)

    binding := Binding{
        name = name,
        exp = exp,
        pos = pos,
    }

    let_exp := new(Expression, context.temp_allocator)
    let_exp.type = .LET
    let_exp.value = binding
    let_exp.pos = pos

    return let_exp  
}

parse_string :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    pos := curr.pos
    exp := new(Expression, context.temp_allocator)
    value := curr.literal
    
    lit := Literal_Node {
        kind = .STRING,
        value = value
    }
    
    exp.type = .LITERAL
    exp.value = lit
    exp.pos = pos
    next_tok(p)
    return exp
}

parse_number :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    pos := curr.pos
    exp := new(Expression, context.temp_allocator)
    value : Literal_Value_Type
    kind : Literal_Kind
    
    #partial switch (curr.kind) {
        case Kind.INT64: {
            // Shadowing is annoying
            parsed_value, ok := strconv.parse_i64(curr.literal) 
            if !ok {
                parser_errorf(curr.pos, false, "could not parse int: %s", curr.literal)
            }
            value = Number(parsed_value)
            kind = Literal_Kind.INT64
        }
        case Kind.FLOAT64: {
            parsed_value, ok := strconv.parse_f64(curr.literal) 
            if !ok {
                parser_errorf(curr.pos, false, "could not parse float: %s", curr.literal)
            }
            value = Number(parsed_value)
            kind = Literal_Kind.FLOAT64
        }
    }
    
    lit := Literal_Node {
        kind = kind,
        value = value
    }
    
    exp.type = .LITERAL
    exp.value = lit
    exp.pos = pos
    next_tok(p)
    return exp
}


parse_expression :: proc(p: ^Parser) -> ^Expression {
    return parse_precedence(p, .LOWEST)
}

has_infix_parser :: proc(kind: Kind) -> bool{
    #partial switch kind {
        case .PLUS, .MINUS, .MULTIPLY, .DIVIDE: return true
        case: return false
    }
}
 parse_precedence :: proc(p: ^Parser, precedence: Precedence) -> ^Expression {
    left := parse_prefix(p)

    for token_precedence(p) > precedence {
        if !has_infix_parser(curr_tok(p).kind) { break }
        
        left = parse_infix(p, left) 
    }

    return left
}

parse_prefix :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)

    pos := curr.pos
    using Kind
    #partial switch (curr.kind) {
        case LET: return parse_let(p)
        case IDENT: return parse_identifier(p)
        case INT64, FLOAT64: return parse_number(p)

        case STRING: return parse_string(p)
        case: parser_errorf(curr.pos, false, fmt.aprintf("unknown prefix expression expected LET | IDENT | INT64 | FLOAT64: %s, got %s\n, %s\n",
               to_string(curr.kind), to_string(curr_tok(p).kind), to_string(curr)))
    }
    //UNREACHABLE
    return nil
}

parse_infix :: proc(p: ^Parser, left: ^Expression) -> ^Expression {
    curr := curr_tok(p) // This is now the operator token
    pos := curr.pos
    kind := curr.kind
    operator_precedence := token_precedence(p)
    
    // Move past operator
    if !next_tok(p) {
        parser_errorf(curr.pos, false, "Unexpected EOF after %s", to_string(curr.kind))
    }

    right := parse_precedence(p, operator_precedence) 
    binop := Binop {
        kind = kind,
        left = left,
        right = right, 
    }

    exp := new(Expression, context.temp_allocator)
    exp.type = .INFIX
    exp.value = binop
    exp.pos = pos


    return exp
}

parse_identifier :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    exp := new(Expression, context.temp_allocator)
    
    exp.type = .IDENTIFIER      
    exp.value = curr.literal
    exp.pos = curr.pos
    
    next_tok(p)
    return exp
}

parse :: proc(p: ^Parser) -> [dynamic]^Expression {
    exp : ^Expression 
    ast: [dynamic]^Expression

    error_string: strings.Builder
    strings.builder_init(&error_string)

    next_tok(p)

    using Kind
    for {
        exp := parse_expression(p)
        append(&ast, exp)

        if (peek_tok(p).kind == Kind.EOF){
            break
        }

        // if !next_tok(p) {
        //     break
        // }

    }

    return ast
}

// main :: proc() {
//
//     args := os.args
//     if len(args) < 2 {
//         fmt.println("USAGE: ./norse <source_file>")
//         os.exit(69)
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
//     l := &Lexer{ 
//         curr = 0,
//         next = 0,
//         pos = Position{ 
//             row = 1,
//             col = 1,
//             file_path = file_name,
//         },
//         text = string(raw_code)
//     }
//
//     tokens := lex(l)
//
//     // for token in tokens {
//     //     fmt.printfln("%v", token)
//     // }
//     p := &Parser{
//         curr = 0,
//         next = 0,
//         tokens = tokens,
//     }
//
//     ast := parse(p)
//     for node in ast {
//         fmt.printfln("%s", to_string(node))
//     }
//
//     free_all(context.temp_allocator)
//
// }

