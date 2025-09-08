package main

import "core:fmt"
import "core:strings"
import "base:runtime"
import "core:log"


INDENT :: "  "

Logger_Level :: enum {
	Debug   = 0,
	Info    = 10,
	Warning = 20,
	Error   = 30,
	Fatal   = 40,
}

perror :: proc(pos: Position, message: string) -> string {
    return fmt.aprintf("\n%s Error: %s", to_string(pos), message)
}


shift :: proc(args: []string) -> ([]string, string) {
    return args[1:], args[0]
}

sb_pad_left :: proc(sb: ^strings.Builder, indent: int) {
    for i in 0..<indent {
        fmt.sbprint(sb, INDENT)
    }
}


sb_body_to_string :: proc(sb: ^strings.Builder, body: [dynamic]^Expression, indent: int = 0) {
    for stmt, i in body {
        fmt.sbprintf(sb, "%s", expression_to_string(stmt, indent))
        fmt.sbprintf(sb, "\n")
    }
}

kind_to_string :: proc(kind: Kind) -> string {
    using Kind
    switch kind {
        case LET: return "LET"
        case FN: return "FN"
        case LT: return "LT"
        case GT: return "GT"
        case RETURN: return "RETURN"
        case FOR: return "FOR"
        case WHILE: return "WHILE"
        case IF: return "IF"
        case ELSE: return "ELSE"
        case TRUE: return "TRUE"
        case FALSE: return "FALSE"
        case PRINT: return "PRINT"
        case SHELL: return "SHELL"
        case IDENT: return "IDENT"
        case DOT: return "DOT"
        case DOTDOT: return "DOTDOT"
        case EQUALS: return "EQUALS"
        case SAME: return "SAME"
        case INT64: return "INT64"
        case FLOAT64: return "FLOAT64"
        case PLUS: return "PLUS"
        case MINUS: return "MINUS"
        case MOD: return "MOD"
        case MULTIPLY: return "MULTIPLY"
        case DIVIDE: return "DIVIDE"
        case BSLASH: return "BSLASH"
        case LPAREN: return "LPAREN"
        case RPAREN: return "RPAREN"
        case LBRACE: return "LBRACE"
        case RBRACE: return "RBRACE"
        case LBLOCK: return "LBLOCK"
        case RBLOCK: return "RBLOCK"
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

binop_kind_to_string :: proc(kind: Binop_Kind) -> string {
    using Binop_Kind
    switch kind {
        case PLUS: return "PLUS" 
        case MINUS: return "MINUS" 
        case MULTIPLY: return "MULTIPLY" 
        case DIVIDE: return "DIVIDE" 
        case MOD: return "MOD" 
        case SAME: return "SAME" 
        case LT: return "LT" 
        case GT: return "GT" 

        case : assert(false, "UNREACHABLE")
    }
    return "INVALID"
}


literal_to_string :: proc(lit: Literal_Value_Type, indent: int = 0) -> string {
    if lit == nil do return "nil"
    switch t in lit {
        case string: return string_to_string(lit.(string), indent)
        case Number: return number_to_string(lit.(Number), indent)
        case Function: return function_to_string(lit.(Function), indent)
        case bool: return boolean_to_string(lit.(bool), indent)
        case Return_Value: assert(false, "Not implemented")
        case Array_Literal: return array_literal_to_string(lit.(Array_Literal), indent)
    }

    assert(false, "UNREACHABLE")
    return ""

}

literal_node_to_string :: proc(literal_node: Literal_Node, indent: int = 0) -> string {
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, "Literal_Node(\n")

    sb_pad_left(&sb, indent + 1)
    fmt.sbprint(&sb, "value: (\n")

    fmt.sbprintf(&sb, "%s\n", literal_to_string(literal_node.value, indent+2))

    sb_pad_left(&sb, indent + 1)
    fmt.sbprint(&sb, ")\n")

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, ")")

    return strings.to_string(sb)
}

return_to_string :: proc(returnn: Return, indent: int = 0) -> string {
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, "Return(\n")

    sb_pad_left(&sb, indent + 1)
    fmt.sbprint(&sb, "value: \n")
    fmt.sbprintf(&sb,"%s\n", expression_to_string(returnn.value, indent+2))

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, ")")

    return strings.to_string(sb)
}

if_to_string :: proc(iff: If, indent: int = 0) -> string {
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprintf(&sb, "If(\n")

    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "cond: (\n")
    fmt.sbprintf(&sb, "%s\n", expression_to_string(iff.cond, indent+2))
    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "),\n")
    
    // Print body/value
    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "ifbody: [")

    if len(iff.body) > 0 {
        fmt.sbprintf(&sb, "\n")
        sb_body_to_string(&sb, iff.body, indent + 2)
    }
    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "]\n")

    //Print elsebody
    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "elsebody: [")
    if len(iff.elze) > 0 {
        fmt.sbprintf(&sb, "\n")
        sb_body_to_string(&sb, iff.elze, indent + 2)
    }
    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "]\n")

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, ")")

    return strings.to_string(sb)
}

function_to_value_string :: proc(function: Function, indent: int = 0) -> string {
    sb: strings.Builder
    strings.builder_init(&sb)

    fmt.sbprintf(&sb, "fn(")
    
    if len(function.args) > 0 {
        for arg, i in function.args {
            fmt.sbprintf(&sb, "%s", arg.value.(Identifier).name)
            if i < len(function.args) - 1 {
                fmt.sbprintf(&sb, " ")
            }
        }
    }
    fmt.sbprint(&sb, ")")

    return strings.to_string(sb)
}

function_to_string :: proc(function: Function, indent: int = 0) -> string {
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, "Function(\n")

    sb_pad_left(&sb, indent + 1)
    fmt.sbprint(&sb, "args(")

    if len(function.args) > 0 {
        fmt.sbprintf(&sb, "\n")
        sb_body_to_string(&sb, function.args, indent + 2)
    }

    sb_pad_left(&sb, indent + 1)
    fmt.sbprint(&sb, "],\n")

    sb_pad_left(&sb, indent + 1)
    fmt.sbprint(&sb, "body: [")

    if len(function.value) > 0 {
        fmt.sbprintf(&sb, "\n")
        sb_body_to_string(&sb, function.value, indent + 2)
    }

    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "]\n")

    sb_pad_left(&sb, indent)
    fmt.sbprintf(&sb, ")")

    return strings.to_string(sb)
}

function_call_to_string :: proc(fun_call: Function_Call, indent: int = 0) -> string {
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprintf(&sb, "Function_Call(\n")

    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "name: %s\n", fun_call.name)

    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "params: [")
    if len(fun_call.params) > 0 {
        fmt.sbprintf(&sb, "\n")
        sb_body_to_string(&sb, fun_call.params, indent + 2)
        sb_pad_left(&sb, indent + 1)
    }
    fmt.sbprintf(&sb, "]\n")

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, ")")
    
    return strings.to_string(sb)
}

expression_to_value_string :: proc(expr: ^Expression, env: ^Environment, indent: int = 0) -> string {
    if expr == nil do return "nil"
    
    sb: strings.Builder
    strings.builder_init(&sb)
    
    switch t in expr.value {
        case While, For, Return, If, Array, Array_Access, ^Expression, Binop, Binding, Function, Function_Call: { 
            assert(false,"Not implemented") 
        }
        case Identifier: { 
            return identifier_to_value_string(expr.value.(Identifier), env)
        }
        case Literal_Node: { 
           return literal_to_string(expr.value.(Literal_Node).value, indent)
        }
    }
    return strings.to_string(sb)
}

expression_to_string :: proc(expr: ^Expression, indent: int = 0) -> string {
    if expr == nil do return "nil"
    
    sb: strings.Builder
    strings.builder_init(&sb)
    
    switch t in expr.value {
        case ^Expression: fmt.sbprintf(&sb, "Expression(%v)", expression_to_string(expr.value.(^Expression), indent))
        case Binding: fmt.sbprintf(&sb, "%s", binding_to_string(expr.value.(Binding), indent))
        case Literal_Node: fmt.sbprintf(&sb, "%s", literal_node_to_string(expr.value.(Literal_Node), indent))
        case Identifier: fmt.sbprintf(&sb, "%s", identifier_to_string(expr.value.(Identifier), indent))
        case Binop: fmt.sbprintf(&sb, "%s", binop_to_string(expr.value.(Binop), indent))
        case Array: fmt.sbprintf(&sb, "%s", array_to_string(expr.value.(Array), indent)) 
        case Array_Access: assert(false,"Not implemented") 
        case Function_Call: fmt.sbprintf(&sb, "%s", function_call_to_string(expr.value.(Function_Call), indent))
        case Function: fmt.sbprintf(&sb, "%s", function_to_string(expr.value.(Function), indent))
        case Return: fmt.sbprintf(&sb, "%s", return_to_string(expr.value.(Return), indent))
        case While: assert(false,"Not implemented") 
        case For: assert(false,"Not implemented") 
        case If: fmt.sbprintf(&sb, "%s", if_to_string(expr.value.(If), indent))
        
    }
        
    return strings.to_string(sb)
}

identifier_to_string :: proc (identifier: Identifier, indent: int  = 0) -> string{
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprintf(&sb, "Identifier(%s)", identifier.name)

    return strings.to_string(sb)
}

binding_to_string :: proc(binding: Binding, indent: int  = 0) -> string{
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, "Let(\n")

    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "name: %s,\n", binding.name)

    sb_pad_left(&sb, indent + 1)
    fmt.sbprint(&sb,"value: \n")
    fmt.sbprintf(&sb,"%s\n", expression_to_string(binding.value, indent+2))

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, ")")

    return strings.to_string(sb)
}

binop_to_string :: proc(binop: Binop, indent: int  = 0) -> string{
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprintf(&sb, "Binop(\n")

    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "op: %s,\n", to_string(binop.kind))

    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "left: \n")
    fmt.sbprintf(&sb,"%s\n", expression_to_string(binop.left, indent+2))

    sb_pad_left(&sb, indent + 1)
    fmt.sbprintf(&sb, "right: \n")
    fmt.sbprintf(&sb,"%s\n", expression_to_string(binop.right, indent+2))

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, ")")

    return strings.to_string(sb)
}

position_to_string :: proc(pos: Position, indent: int = 0) -> string { 
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprintf(&sb ,"%s(%d:%d)", pos.file_path, pos.row, pos.col) 
    return strings.to_string(sb)
}

array_literal_to_string :: proc(array: Array_Literal, indent: int = 0) -> string {
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, "[")
    for ele, i in array.elements {
        fmt.sbprintf(&sb, "%s",literal_to_string(ele))

        if i < len(array.elements) - 1 {
            fmt.sbprintf(&sb, " ")
        }
    }

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, "]")

    return strings.to_string(sb)
}
array_to_string :: proc(array: Array, indent: int = 0) -> string {
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, "Array(")

    if len(array.elements) > 0 {
        fmt.sbprint(&sb, "\n")
        sb_body_to_string(&sb, array.elements, indent + 1)
        fmt.sbprint(&sb, "\n")
    }

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, ")\n")

    return strings.to_string(sb)
}

boolean_to_string :: proc(flag: bool, indent: int = 0) -> string {
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    switch flag {
        case true: fmt.sbprint(&sb, "true")
        case false: fmt.sbprint(&sb, "false")
    }

    return strings.to_string(sb)
}

string_to_string :: proc(str: string, indent: int = 0) -> string { 
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)
    fmt.sbprint(&sb, str)

    return strings.to_string(sb)
}

number_to_string :: proc(num: Number, indent: int = 0) -> string { 
    sb: strings.Builder
    strings.builder_init(&sb)

    sb_pad_left(&sb, indent)

    switch v in num {
        case f64: fmt.sbprintf(&sb ,"%f", num)
        case i64: fmt.sbprintf(&sb ,"%d", num)
    }
    return strings.to_string(sb)
}

identifier_to_value_string :: proc(identifier: Identifier, env: ^Environment, indent: int = 0) -> string { 
    out: strings.Builder
    strings.builder_init(&out)
    name := identifier.name

    fmt.sbprintf(&out ,"%s: ", name)
    ident, ok := env_get(env, name)
    if !ok {
        parser_errorf(identifier.pos, false, "Var: %s, is undefined in the current scope", name)
    }
    fmt.sbprintf(&out ,"%s", literal_to_string(ident))
    return strings.to_string(out)
}

bool_to_string :: proc(b: bool) -> string { 
    return b ? "True": "False"
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

to_string :: proc{kind_to_string, binop_kind_to_string, token_to_string, position_to_string, 
    number_to_string, expression_to_string, literal_to_string, function_to_string, if_to_string, 
    array_to_string, return_to_string}

to_value_string :: proc{expression_to_value_string, function_to_value_string, identifier_to_value_string, literal_to_string, array_literal_to_string}

print_token :: proc(token: Token) {
    fmt.printf("%s\n", to_string(token))
}

print :: proc{print_token}

// NOTE adapted/yoinked from odin source
@(disabled=ODIN_DISABLE_ASSERT)
parser_errorf :: proc(pos: Position, condition: bool, fmt_str: string, args: ..any, loc := #caller_location) {
	if !condition {
		// NOTE(dragos): We are using the same trick as in builtin.assert
		// to improve performance to make the CPU not
		// execute speculatively, making it about an order of
		// magnitude faster
		@(cold)
		internal :: proc(pos: Position ,loc: runtime.Source_Code_Location, fmt_str: string, args: ..any) {
			p := context.assertion_failure_proc
			if p == nil {
				p = runtime.default_assertion_failure_proc
			}

            fmt.printf("\n%s Error: \n", to_string(pos))
			message := fmt.tprintf(fmt_str, ..args)
			log.log(.Fatal, message, location = loc)
			p("runtime assertion", message, loc)
		}
		internal(pos, loc, fmt_str, ..args)
	}
}

