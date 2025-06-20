package main

import "core:os"
import "core:fmt"

Environment :: map[string]Literal_Value_Type

literal_value_to_number :: proc(lit: Literal_Value_Type) -> Number {
    // assert(node.kind == .LITERAL, "Must be a LITERAL to convert to NUMBER")
    result : Number
    switch t in lit {
        case Number: result = lit.(Number)
        case Function: assert(false, "NOT IMPLEMENTED")
        case string: assert(false, "Must be a LITERAL NUMBER not string")
        case bool : assert(false, "Must be a LITERAL NUMBER not bool")
    }

    return  result
}


literal_to_number :: proc(node: ^Expression) -> Number {

    result : Number

    literal_node := node.value.(Literal_Node)
    switch t in literal_node.value{
        case Number: result = literal_node.value.(Number)
        case Function: assert(false, "NOT IMPLEMENTED")
        case string: assert(false, "Must be a LITERAL NUMBER not string")
        case bool : assert(false, "Must be a LITERAL NUMBER not bool")
    }

    return  result
}

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

    assert(false, "UNREACHABLE")
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

    assert(false, "UNREACHABLE")
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

    assert(false, "UNREACHABLE")
    return i64(0) // UNREACHABLE
}


eval_identifier :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type

    literal_node := node.value.(Identifier)
    ident := env[literal_node.name]
    switch t in ident {
        case Number: result = ident.(Number)
        case string: result = ident.(string)
        case Function: result = ident.(Function) 
        case bool : result = ident.(bool)
        case : parser_errorf(node.pos, false, "Expected NUMBER | STRING or | FUNCTION found: %v", ident)
    }
    return result
}


eval_binop :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    switch t in node.value {

        case  Function: parser_errorf(node.pos ,false, "Expected Binop got Function")
        case  Function_Call: parser_errorf(node.pos ,false, "Expected Binop got Function Call")
        case  Binding: parser_errorf(node.pos ,false, "Expected Binop, got Binding")
        case  Identifier: parser_errorf(node.pos ,false, "Expected Binop, got Identifier")
        case  ^Expression: parser_errorf(node.pos ,false, "Expected Binop, got ^Expression")
        case  Literal_Node: parser_errorf(node.pos ,false, "Expected Binop, got Literal_Node")
        case  Binop: {
            binop := node.value.(Binop)
            left := eval(env, binop.left)
            right := eval(env, binop.right)
            left_number := literal_value_to_number(left)
            right_number := literal_value_to_number(right) 
            #partial switch binop.kind {
                case .PLUS : {
                    result = eval_add(left_number, right_number)

                }
                case .MULTIPLY: {
                    result = eval_mul(left_number, right_number)
                }
                case .DIVIDE :{
                    result = eval_div(left_number, right_number)
                }

                case .MOD :{
                    left_integer : i64
                    right_integer : i64

                    switch t in left_number {
                        case f64: parser_errorf(node.pos ,false, "Operator '%' is only allowed with integers, got float64")
                        case i64: left_integer = left_number.(i64)
                    }

                    switch t in right_number {
                        case f64: parser_errorf(node.pos ,false, "Operator '%' is only allowed with integers, got float64")
                        case i64: right_integer = right_number.(i64)
                    }
                    result = Number(left_integer % right_integer)
                }
                case : parser_errorf(node.pos ,false, "Expected Binop, got %s", binop.kind)
            }
        }
    }


    return result
}

// Basically just type assertions out of the Literal_Value_Type union
eval_literal :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    literal_node := node.value.(Literal_Node)
    switch t in literal_node.value {
        case Number: result = literal_to_number(node)
        case Function: result = eval_function(env, node)
        case string: result = literal_node.value.(string)
        case bool: result = literal_node.value.(bool)
    }
    return result
}

//Unsure what to do with this yet, I can just be printed, in which case it should return a string? OR a Function
eval_function :: proc(env: ^Environment, node: ^Expression) -> Function {
    result : Function
    result = node.value.(Function)
    return result
}

eval_function_call :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    function_call := node.value.(Function_Call)
    params := function_call.params
    name := function_call.name

    //Ensure function exists, may be portable once there are multiple scopes, maybe have to be refactored
    var := env[name]
    fn : Function
    switch t in var {
        case Function: fn = var.(Function)
        case Number: parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", t)
        case string: parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", t)
        case bool: parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", t)
    }

    param_length := len(params)

    arg_length := len(fn.args)

    func_env := make(map[string]Literal_Value_Type)
    defer delete(func_env)

    //Copy env for now, later can have a structure of envs, tree perhaps. Could look into how web assembly does it
    for name, value in env {
        func_env[name] = value
    }

    for i in 0..<len(params) {
        param_value := eval(env, params[i])
        arg_name := fn.args[i].value.(Identifier).name
        func_env[arg_name] = param_value
    }
    
    // Execute function body
    for stmt in fn.value { 
        result = eval(&func_env, stmt)  
    }

    return result
}

eval_binding :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    switch t in node.value {
         case  Binding: {
            binding := node.value.(Binding)
            name := binding.name
            result = eval(env, binding.value)
            env[name] = result
        }

        case  Binop: assert(false, "Expected binding, found binop")
        case  Identifier: assert(false, "Expected binding, found Identifier")
        case  Function: assert(false, "Expected binding, found function")
        case  Function_Call: assert(false, "Expected binding, found function")
        case  ^Expression: assert(false, "Expected binding, found Expression")
        case  Literal_Node: assert(false, "Expected binding, found Literal_Node")

    }

    return result
}

// Unsure if this should take a block type or [dynamic]^Expression. Maybe after type refactor will be more obvious
eval_block :: proc(env: ^Environment, exps: [dynamic]^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    func_env := make(map[string]Literal_Value_Type)
    defer delete(func_env)

    //Copy env for now, later can have a structure of envs, tree perhaps. Could look into how web assembly does it
    for name, value in env {
        func_env[name] = value
    }

    // Execute function body
    for stmt in exps { 
        result = eval(&func_env, stmt)  
    }

    return result
}

eval :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type{
    result : Literal_Value_Type

    switch t in node.value {
        case Literal_Node: result = eval_literal(env, node)
        case Identifier: result = eval_identifier(env, node)
        case Binding: result = eval_binding(env, node)
        case Function: result = eval_function(env, node)
        case Function_Call: result = eval_function_call(env, node)
        case Binop: result = eval_binop(env, node)
        // Unsure if this is the right move...
        case ^Expression: result = eval(env, node.value.(^Expression))
    }

    parser_errorf(node.pos, result != nil, "Nil node %v, result: %v", node, result)
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
    fmt.eprintln("Lexed")

    p := &Parser{
        curr = 0,
        next = 0,
        tokens = tokens,
    }

    ast := parse(p)
    fmt.eprintln("Parsed")

    env := make(map[string]Literal_Value_Type)

    for node in ast {
        _ = eval(&env, node)
        // fmt.printfln("%#v", result)
    }

    for key, value in env {
        // fmt.printfln("key %s, value: %#v", key, value)
        fmt.printfln("key %s, value: %s", key, literal_to_string(value))
    }

    free_all(context.temp_allocator)

}

