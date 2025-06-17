package main

import "core:os"
import "core:fmt"

Environment :: map[string]Literal_Value_Type

// Painful extra step but only way to get around the compiler complaining when 
// casting from Literal_Value_Type as there is string in the union
// Maybe string should not be in the union but it is for now
eval_add :: proc(left: Number, right: Number) -> Number {
    switch l in left {
    case f64:
        switch r in right {
            case f64: return l + r        // f64 + f64 = f64
            case i64: return l + f64(r)   // f64 + i64 = f64
        }
    case i64:
        switch r in right {
            case f64: return f64(l) + r   // i64 + f64 = f64
            case i64: return l + r        // i64 + i64 = i64 
        }
    }
    return i64(0) // UNREACHABLE
}

eval_mul :: proc(left: Number, right: Number) -> Number {
    switch l in left {
    case f64:
        switch r in right {
            case f64: return l * r        // f64 + f64 = f64
            case i64: return l * f64(r)   // f64 + i64 = f64
        }
    case i64:
        switch r in right {
            case f64: return f64(l) * r   // i64 + f64 = f64
            case i64: return l * r        // i64 + i64 = i64 
        }
    }
    return i64(0) // UNREACHABLE
}

eval_div :: proc(left: Number, right: Number) -> Number {
    switch l in left {
    case f64:
        switch r in right {
            case f64: return l / r        // f64 + f64 = f64
            case i64: return l / f64(r)   // f64 + i64 = f64
        }
    case i64:
        switch r in right {
            case f64: return f64(l) / r   // i64 + f64 = f64
            case i64: return l / r        // i64 + i64 = i64 
        }
    }
    return i64(0) // UNREACHABLE
}

eval_numeric_ops :: proc(node: ^Expression) -> Number {
    result : Number

    switch node.kind {
        case .LITERAL: {
            result = literal_to_number(node)
        }
        case .IDENTIFIER: assert(false, "NOT IMPLEMENTED")
        case .LET: assert(false, "NOT IMPLEMENTED")
        case .FUNCTION: assert(false, "NOT IMPLEMENTED")
        case .FUNCTION_CALL: assert(false, "NOT IMPLEMENTED")
        case .BLOCK: assert(false, "NOT IMPLEMENTED")
        case .INFIX: assert(false, "NOT IMPLEMENTED")
    }
    return result
}


literal_to_number :: proc(node: ^Expression) -> Number {
    assert(node.kind == .LITERAL, "Must be a LITERAL to convert to NUMBER")

    result : Number

    literal_node := node.value.(Literal_Node)
    switch v in literal_node.value{
        case Number: result = literal_node.value.(Number)
        case Function: assert(false, "NOT IMPLEMENTED")
        case string: assert(false, "Must be a LITERAL NUMBER not string")
    }

    return  result
}

eval_infix :: proc(env: ^Environment, infix: ^Expression) -> Number {
    result : Number
    switch v in infix.value {

        case  Function: parser_errorf(infix.pos ,false, "UNIMPLEMENTED")
        case  Function_Call: parser_errorf(infix.pos ,false, "UNIMPLEMENTED")
        case  Binding: parser_errorf(infix.pos ,false, "Expected Binop, got Binding")
        case  i64: parser_errorf(infix.pos ,false, "Expected Binop, got i64")
        case  f64: parser_errorf(infix.pos ,false, "Expected Binop, got f64")
        case  string: parser_errorf(infix.pos ,false, "Expected Binop, got string")
        case  ^Expression: parser_errorf(infix.pos ,false, "Expected Binop, got ^Expression")
        case  Literal_Node: parser_errorf(infix.pos ,false, "Expected Binop, got Literal_Node")
        case  Binop: {
            binop := infix.value.(Binop)
            left := binop.left
            right := binop.right
            left_number : Number 
            right_number : Number 
            #partial switch binop.kind {
                case .PLUS : {
                    left_number = eval_numeric_ops(left)
                    right_number = eval_numeric_ops(right)
                    result = eval_add(left_number, right_number)
                }
                case .MULTIPLY: {
                    left_number = eval_numeric_ops(left)
                    right_number = eval_numeric_ops(right)
                    result = eval_mul(left_number, right_number)
                }
                case .DIVIDE :{
                    left_number = eval_numeric_ops(left)
                    right_number = eval_numeric_ops(right)
                    result = eval_div(left_number, right_number)
                }
                case : parser_errorf(infix.pos ,false, "Expected Binop, got %s", binop.kind)
            }
        }
    }
    return result
}

// Basically just type assertions out of the Literal_Value_Type union
eval_literal :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    parser_errorf(node.pos, node.kind == .LITERAL, "Unexpected KIND: %v expected LITERAL", node.kind)
    result : Literal_Value_Type
    literal_node := node.value.(Literal_Node)
    switch v in literal_node.value {
        case Number: result = literal_to_number(node)
        case Function: assert(false, "NOT IMPLEMENTED")
        case string: result = literal_node.value
    }
    return result
}

eval_function_decl :: proc(env: ^Environment, node: ^Expression) -> Function {
    parser_errorf(node.pos, node.kind == .FUNCTION, "Unexpected KIND: %v expected FUNCTION", node.kind)

    result : Function
    result = node.value.(Function)
    return result
}

eval_function_call :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    parser_errorf(node.pos, node.kind == .FUNCTION_CALL, "Unexpected KIND: %v expected FUNCTION_CALL", node.kind)

    result : Literal_Value_Type
    function_call := node.value.(Function_Call)
    params := function_call.params
    name := function_call.name

    //Ensure function exists, may be portable once there are multiple scopes, maybe have to be refactored
    var := env[name]
    fn : Function
    switch v in var {
        case Function: fn = var.(Function)
        case Number: parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", node.kind)
        case string: parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", node.kind)
    }

    param_length := len(params)
    arg_length := len(fn.args)
    parser_errorf(node.pos, param_length == arg_length, "Incorrect arguments for '%s', expected %d, got %d ", param_length, arg_length)

    func_env := make(map[string]Literal_Value_Type)
    defer delete(func_env)

    //Copy env for now, later can have a structure of envs, tree perhaps. Could look into how web assembly does it
    for name, value in env {
        func_env[name] = value
    }

    assert(false, "not implemented")


    return result
}

eval_let :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    switch v in node.value {
        case  Binding: {
            binding := node.value.(Binding)
            name := binding.name
            switch binding.value.kind {
                case .LITERAL: result = eval_literal(env, binding.value)
                case .IDENTIFIER: assert(false, "not implemented")
                case .LET: assert(false, "NOT IMPLEMENTED")
                case .FUNCTION: result = eval_function_decl(env, binding.value)
                case .FUNCTION_CALL: assert(false, "NOT IMPLEMENTED")
                case .BLOCK: assert(false, "NOT IMPLEMENTED")
                case .INFIX: {
                    infix := binding.value
                    result = eval_infix(env, infix)
                }
            }

            env[name] = result
        }

        case  Binop: assert(false, "Expected binding, found binop")
        case  Function: assert(false, "Expected binding, found function")
        case  Function_Call: assert(false, "Expected binding, found function")
        case  i64: assert(false, "Expected binding, found i64")
        case  f64: assert(false, "Expected binding, found f64")
        case  string: assert(false, "Expected binding, found string")
        case  ^Expression: assert(false, "Expected binding, found Expression")
        case  Literal_Node: assert(false, "Expected binding, found Literal_Node")

    }

    return result
}



main :: proc() {

    args := os.args
    if len(args) < 2 {
        fmt.println("USAGE: ./auga <source_file>")
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


    p := &Parser{
        curr = 0,
        next = 0,
        tokens = tokens,
    }

    ast := parse(p)

    env := make(map[string]Literal_Value_Type)

    //REFACTOR out to a recursive eval(env: ^Environment, node: ^Expression)
    for node in ast {
        result : Literal_Value_Type

        fmt.printfln("%s", to_string(node))
        switch node.kind {
            case .LITERAL: parser_errorf(node.pos, false, "Expected expression, found LITERAL: %v", node.value)
            case .IDENTIFIER: assert(false, "NOT IMPLEMENTED")
            case .LET: result = eval_let(&env, node)
            case .FUNCTION: assert(false, "NOT IMPLEMENTED")
            case .FUNCTION_CALL: eval_function_call(&env, node)
            case .BLOCK: assert(false, "NOT IMPLEMENTED")
            case .INFIX: assert(false, "NOT IMPLEMENTED")
        }

        fmt.printfln("%v", result)
        fmt.printfln("%v", env)
    }

    free_all(context.temp_allocator)

}

