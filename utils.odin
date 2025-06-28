package main

import "core:fmt"
import "core:strings"
import "base:runtime"

import "core:log"

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

kind_to_string :: proc(kind: Kind) -> string {
    using Kind
    switch kind {
        case LET: return "LET"
        case FN: return "FN"
        case RETURN: return "RETURN"
        case IF: return "IF"
        case TRUE: return "TRUE"
        case FALSE: return "FALSE"
        case PRINT: return "PRINT"
        case IDENT: return "IDENT"
        case DOT: return "DOT"
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

literal_to_string :: proc(lit: Literal_Value_Type, indent: int = 0) -> string {
    if lit == nil do return "nil"
    switch t in lit {
        case string: return lit.(string)
        case Number: return number_to_string(lit.(Number))
        case Function: return function_to_string(lit.(Function), indent)
        case bool : return boolean_to_string(lit.(bool))
    }

    assert(false, "UNREACHABLE")
    return ""
}

function_to_string :: proc(function: Function, indent: int = 0) -> string {

    sb: strings.Builder
    strings.builder_init(&sb)

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

    return strings.to_string(sb)
}

expression_to_string :: proc(expr: ^Expression, indent: int = 0) -> string {
    if expr == nil do return "nil"
    
    sb: strings.Builder
    strings.builder_init(&sb)
    
    // Add indentation
    for i in 0..<indent {
        strings.write_string(&sb, "  ")
    }
    
    switch t in expr.value {
        //Unsure if this is a problem
        case ^Expression: 
            fmt.sbprintf(&sb, "Expression(%v)", expression_to_string(expr.value.(^Expression), indent+1))

        case  If: 
            fmt.sbprintf(&sb, "If(%#v)", expr.value.(If))
        case Literal_Node:
            fmt.sbprintf(&sb, "LITERAL(%v)", expr.value.(Literal_Node))
            
        case Identifier:
            fmt.sbprintf(&sb, "Identifier(%v)", expr.value.(Identifier).name)
        case Binding:
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
            
        case Binop:
            binop := expr.value.(Binop)
            fmt.sbprintf(&sb, "Infix(\n")
            for i in 0..<indent+1 {
                strings.write_string(&sb, "  ")
            }
            fmt.sbprintf(&sb, "op: %v,\n", binop.kind)
            for i in 0..<indent+1 {
                strings.write_string(&sb, "  ")
            }
            fmt.sbprintf(&sb, "left: %s,\n", expression_to_string(binop.left, indent))
            for i in 0..<indent+1 {
                strings.write_string(&sb, "  ")
            }
            fmt.sbprintf(&sb, "right: %s\n", expression_to_string(binop.right, indent))
            for i in 0..<indent {
                strings.write_string(&sb, "  ")
            }
            strings.write_string(&sb, ")")

        case Function_Call:
            fun_call := expr.value.(Function_Call)
            fmt.sbprintf(&sb, "Function_Call(\n")
            for i in 0..<indent+1 {
                strings.write_string(&sb, "  ")
            }

            fmt.sbprintf(&sb, "name: %s,\n", fun_call.name)
            for i in 0..<indent+1 {
                strings.write_string(&sb, "  ")
            }

            // Print params
            for i in 0..<indent+1 {
                strings.write_string(&sb, "  ")
            }
            fmt.sbprintf(&sb, "params: [")
            if len(fun_call.params) > 0 {
                fmt.sbprintf(&sb, "\n")

                for param, i in fun_call.params {
                    for j in 0..<indent+2 {
                        strings.write_string(&sb, "  ")
                    }
                    fmt.sbprintf(&sb, "%s", expression_to_string(param, indent+2))
                    if i < len(fun_call.params) - 1 {
                        fmt.sbprintf(&sb, ",")
                    }
                    fmt.sbprintf(&sb, "\n")
                }
                for i in 0..<indent+1 {
                    strings.write_string(&sb, "  ")
                }
            }

            fmt.sbprintf(&sb, "],\n")
            strings.write_string(&sb, ")")
            
            case Function: {
                function := expr.value.(Function)
                fmt.sbprintf(&sb, "%s", function_to_string(function, indent+2))
            }
        }
        
        return strings.to_string(sb)
}


position_to_string :: proc(pos: Position) -> string { 
    out: strings.Builder
    strings.builder_init(&out)

    fmt.sbprintf(&out ,"%s(%d:%d)", pos.file_path, pos.row, pos.col) 
    return strings.to_string(out)
}

boolean_to_string :: proc(flag: bool) -> string {
    switch flag {
        case true: return "true"
        case false: return "false"
    }

    assert(false, "UNREACHABLE")
    return ""
}

number_to_string :: proc(num: Number) -> string { 
    out: strings.Builder
    strings.builder_init(&out)

    switch v in num {
        case f64: fmt.sbprintf(&out ,"%f", num)
        case i64: fmt.sbprintf(&out ,"%d", num)
    }
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

to_string :: proc{kind_to_string, token_to_string, position_to_string, number_to_string, expression_to_string, literal_to_string, function_to_string}

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
