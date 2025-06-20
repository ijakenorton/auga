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

Binop_Kind :: enum {
    PLUS,
    MINUS,        
    MULTIPLY,     
    DIVIDE,       
    MOD,
}


Binop :: struct {
    kind: Binop_Kind,
    left: ^Expression,
    right: ^Expression,
}


Literal_Node :: struct {
    value: Literal_Value_Type,
}

Binding :: struct {
    name: string,
    value: ^Expression,
    pos: Position,
}

Identifier :: struct {
    name: string,
    pos: Position,
}

Function :: struct {
    args: [dynamic]^Expression,
    value: [dynamic]^Expression,
    pos: Position,
}

Function_Call :: struct {
    params:[dynamic]^Expression,
    name: string,
    pos: Position,
}

Expression :: struct {
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
    bool,
    Function,
}

Value_Type :: union {
    ^Expression,
    Binop,
    Binding,
    Identifier,
    Function,
    Function_Call,
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

token_precedence :: proc(p: ^Parser, loc := #caller_location) -> Precedence {
    kind := curr_tok(p).kind
    using Kind
    #partial switch kind {
        case EQUALS:
            return .EQUALS
        case PLUS, MINUS:
            return .SUM
        case MULTIPLY, DIVIDE, MOD:
            return .PRODUCT
        case LPAREN: 
            return .CALL
        case LET, EOF, INT64, FLOAT64, IDENT, STRING, RBRACE, RPAREN, IF:
            return .LOWEST
        case:
            parser_errorf(curr_tok(p).pos, false, "Unexpected KIND: %s\n%s Error: Calling function\n", to_string(curr_tok(p).kind), loc)
            //UNREACHABLE
            return .LOWEST
    }
}

expect :: proc(p: ^Parser, kind: Kind) -> bool {
    return curr_tok(p).kind == kind
}

expect_peek :: proc(p: ^Parser, kind: Kind) -> bool {
    return peek_tok(p).kind == kind
}

next_and_expect :: proc(p: ^Parser, kind: Kind, loc := #caller_location) -> Token {
    curr := curr_tok(p)

    if !next_tok(p) {
        parser_errorf(curr.pos, false, "Expected: %s, got %s, \n%s Error: Calling function\n", to_string(kind), to_string(curr_tok(p).kind), loc)
    }

    curr = curr_tok(p)
    if !expect(p, kind) {
        parser_errorf(curr.pos, false, "Expected: %s, got %s, \n%s Error: Calling function\n", to_string(kind), to_string(curr_tok(p).kind), loc)
    }

    return curr_tok(p)
}


parse_block :: proc(p: ^Parser) -> [dynamic]^Expression {
    curr := curr_tok(p)
    block_exps: [dynamic]^Expression
    for !expect(p, .RBRACE) {
        if !next_tok(p) {
            parser_errorf(curr.pos, false, "Expected: Expression or }, got %s", to_string(curr_tok(p).kind))
        }
        exp := parse_expression(p)
        append(&block_exps, exp)
    }
    next_tok(p)
    return block_exps
}

parse_fn_params :: proc(p: ^Parser) -> [dynamic]^Expression {
    params: [dynamic]^Expression

    if !next_tok(p){
        parser_errorf(curr_tok(p).pos, false, "Expected: param or ), got %s", to_string(curr_tok(p).kind))
    }

    count := 0
    for !expect(p, .RPAREN) {
        if count > 1000 {
            parser_errorf(curr_tok(p).pos, false, "Count hit max depth, either params is over 1000 or 'parse_expression' did not move the parser forward", to_string(curr_tok(p).kind))
        }
        exp := parse_expression(p)

        append(&params, exp)
        count += 1

        //Unsure if this is quite right, might get stuck in infinite loop here if parse_expression doesnt move anywhere
        // if !next_tok(p){
        //
        //     parser_errorf(curr_tok(p).pos, false, "Expected: param or ), got %s", to_string(curr_tok(p).kind))
        // }
    }


    next_tok(p)

    return params
}
//Fix missing funciont call
parse_fn_call :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    name := curr.literal
    pos := curr.pos

    curr = next_and_expect(p, .LPAREN)
    params := parse_fn_params(p)

    fn := Function_Call {
        name = name,
        params = params,
        pos = pos,
    }

    fn_call := new(Expression, context.temp_allocator)
    fn_call.value = fn
    fn_call.pos = pos

    return fn_call  
}

parse_fn_args :: proc(p: ^Parser) -> [dynamic]^Expression {
    curr := curr_tok(p)
    args: [dynamic]^Expression

    if !next_tok(p){
        parser_errorf(curr_tok(p).pos, false, "Expected: argument or {{, got %s", to_string(curr_tok(p).kind))
    }

    for !expect(p, .LBRACE) {
        exp := parse_identifier(p)
        append(&args, exp)
    }

    next_tok(p)
    return args
}

parse_fn_decl :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)

    pos := curr.pos
    args := parse_fn_args(p)
    block := parse_block(p)

    fn := Function {
        value = block,
        args = args,
        pos = pos,
    }

    fn_decl := new(Expression, context.temp_allocator)
    fn_decl.value = fn
    fn_decl.pos = pos

    return fn_decl  
}

parse_let :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    pos := curr.pos
    exp := new(Expression, context.temp_allocator)

    curr = next_and_expect(p, .IDENT)
    name := curr.literal

    curr = next_and_expect(p, .EQUALS)

    if !next_tok(p) {
        parser_errorf(curr.pos, false, "Unexpected EOF after EQUALS")
    }
    exp = parse_expression(p)

    binding := Binding{
        name = name,
        value = exp,
        pos = pos,
    }

    let_exp := new(Expression, context.temp_allocator)
    let_exp.value = binding
    let_exp.pos = pos

    return let_exp  
}

parse_string :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    pos := curr.pos
    value := curr.literal
    
    lit := Literal_Node {
        value = value
    }
    
    exp := new(Expression, context.temp_allocator)
    exp.value = lit
    exp.pos = pos
    next_tok(p)
    return exp
}

parse_number :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    pos := curr.pos
    value : Literal_Value_Type
    
    #partial switch (curr.kind) {
        case Kind.INT64: {
            // Shadowing is annoying
            parsed_value, ok := strconv.parse_i64(curr.literal) 
            if !ok {
                parser_errorf(curr.pos, false, "could not parse int: %s", curr.literal)
            }
            value = Number(parsed_value)
        }
        case Kind.FLOAT64: {
            parsed_value, ok := strconv.parse_f64(curr.literal) 
            if !ok {
                parser_errorf(curr.pos, false, "could not parse float: %s", curr.literal)
            }
            value = Number(parsed_value)
        }
    }
    
    lit := Literal_Node {
        value = value
    }
    
    exp := new(Expression, context.temp_allocator)
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
        case .PLUS, .MINUS, .MULTIPLY, .DIVIDE, .MOD: return true
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

// TODO: Handle parentheses for precedence, 
// Also I believe there is some issue with function parsing still as parantheses leaked to here
parse_prefix :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)

    pos := curr.pos
    using Kind
    #partial switch (curr.kind) {
        case LET: return parse_let(p)
        case IDENT: {
            if expect_peek(p, .LPAREN) {
                return parse_fn_call(p)
            }

            return parse_identifier(p)
        }
        case INT64, FLOAT64: return parse_number(p)
        case STRING: return parse_string(p)
        case TRUE, FALSE : return parse_boolean(p)
        case FN: return parse_fn_decl(p)

        case: parser_errorf(curr.pos, false, fmt.aprintf("unknown prefix expression expected LET | IDENT | INT64 | FLOAT64: %s, got %s\n \n%s",
               to_string(curr.kind), to_string(curr_tok(p).kind), to_string(curr)))
    }
    //UNREACHABLE
    return nil
}

to_binop_kind ::proc(pos: Position ,kind: Kind) -> Binop_Kind {
    #partial switch kind {
        case Kind.PLUS: return Binop_Kind.PLUS
        case Kind.MINUS: return Binop_Kind.MINUS
        case Kind.MULTIPLY: return Binop_Kind.MULTIPLY
        case Kind.DIVIDE: return Binop_Kind.DIVIDE
        case Kind.MOD: return Binop_Kind.MOD
        case : 
            parser_errorf(pos, false, "Unexpected Kind %s, should be PLUS | MINUS | MULTIPLY | DIVIDE | MOD", to_string(kind))
    }
    assert(false, "UNREACHABLE")
    return Binop_Kind.PLUS
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
        kind = to_binop_kind(pos, kind),
        left = left,
        right = right, 
    }

    exp := new(Expression, context.temp_allocator)
    exp.value = binop
    exp.pos = pos

    return exp
}

parse_boolean :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    pos := curr.pos
    value : Literal_Value_Type
    
    #partial switch (curr.kind) {
        case Kind.FALSE: {
            value = false
        }
        case Kind.TRUE: {
            value = true
        }
    }
    
    lit := Literal_Node {
        value = value
    }
    
    exp := new(Expression, context.temp_allocator)
    exp.value = lit
    exp.pos = pos
    next_tok(p)
    return exp
}

parse_identifier :: proc(p: ^Parser) -> ^Expression {
    curr := curr_tok(p)
    
    ident := Identifier{
        name = curr.literal,
        pos = curr.pos
    }
    
    exp := new(Expression, context.temp_allocator)
    exp.value = ident
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
