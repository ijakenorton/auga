package main

import "core:os"
import "core:fmt"

Environment :: struct {
    env: map[string]Literal_Value_Type,
    parent: ^Environment,
}

// Recursive access of environments
env_get :: proc(env: ^Environment, key: string) -> (Literal_Value_Type, bool){ 
    result : Literal_Value_Type
    ok : bool
    max_depth := 50000
    curr_env := env

    //TODO clean this up
    for {
        assert(max_depth >= 0, "Hit max scope depth, something went wrong")

        if curr_env == nil {
            return nil, ok
        }
        result, ok = curr_env.env[key]

        if ok {
            return result, ok
        }

        if curr_env == nil {
            return nil, ok
        }
        curr_env = curr_env.parent
        max_depth -= 1
    }

    return result, false
}

literal_value_to_number :: proc(lit: Literal_Value_Type) -> Number {
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

eval_if :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type

    if_node := node.value.(If)
    cond := eval(env, if_node.cond)

    switch t in cond {
        case Number: parser_errorf(if_node.pos ,false, "If condition expression must result in a boolean, found Number")
        case Function: parser_errorf(if_node.pos ,false, "If condition expression must result in a boolean, found Function")
        case string: parser_errorf(if_node.pos ,false, "If condition expression must result in a boolean, found String")
        case bool : 
    }

    if cond.(bool) {
        result = eval_block(env, if_node.body)
    } else if if_node.elze != nil {
        result = eval_block(env, if_node.elze)
    }

    return result
}


eval_same :: proc(left: Literal_Value_Type, right: Literal_Value_Type) -> bool {
    switch t in left {
        case Number: {
            switch t in right {
                case Number: return left.(Number) == right.(Number)
                case string: return false
                case bool: return false
                case Function: return false
            }
        }
        case string: {
            switch t in right {
                case Number: return false
                case string: return left.(string) == right.(string)
                case bool: return false
                case Function: return false
            }
        }
        case bool: {
            switch t in right {
                case Number: return false
                case string: return false
                case bool: return left.(bool) == right.(bool)
                case Function: return false
            }
        }
        case Function: {
            switch t in right {
                case Number: return false
                case string: return false
                case bool: return false
                //TODO Maybe need to adjust this in the future, possibly just pointer equality, or recursive struct equality
                case Function: return false
            }
        }
    }

    assert(false, "UNREACHABLE")
    return false
}

eval_binop :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    switch t in node.value {
        case  If: parser_errorf(node.pos ,false, "Expected Binop got If")
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
            //TODO possibly move this around as they are not needed in SAME binop
            left_number := literal_value_to_number(left)
            right_number := literal_value_to_number(right) 
            switch binop.kind {
                case .SAME : {
                    result = eval_same(left, right)
                }
                case .PLUS : {
                    result = eval_add(left_number, right_number)
                }
                case .MINUS : {
                    assert(false, "NOT IMPLEMENTED")
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

eval_identifier :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type

    literal_node := node.value.(Identifier)
    
    ident, ok := env_get(env, literal_node.name)
    if !ok {
        parser_errorf(node.pos, false, "Var: %s, is undefined in the current scope", literal_node.name)
    }
    switch t in ident {
        case Number: result = ident.(Number)
        case string: result = ident.(string)
        case Function: result = ident.(Function) 
        case bool : result = ident.(bool)
        case : parser_errorf(node.pos, false, "Var: %s, Expected NUMBER | STRING | FUNCTION | BOOL found: %v", ident, literal_node.name)
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
    fn : Function

    if name == "print" {
        // parser_errorf(node.pos, false, "Var: %s", name)
        for param in params{
            fmt.printf("%s", to_value_string(param, env))
        }

        fmt.println()

        return true
    } else {
        var, ok := env_get(env, name)
        if !ok {
            parser_errorf(node.pos, false, "Var: %s, is undefined in the current scope", name)
        }

        switch t in var {
            case Function: fn = var.(Function)
            case Number: parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", t)
            case string: parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", t)
            case bool: parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", t)
        }

        param_length := len(params)
        arg_length := len(fn.args)

        func_env := make(map[string]Literal_Value_Type)
        new_env := Environment{
            parent = env,
            env = func_env,
        }
        defer delete(func_env)

        for i in 0..<len(params) {
            param_value := eval(env, params[i])
            arg_name := fn.args[i].value.(Identifier).name
            new_env.env[arg_name] = param_value
        }
        
        // Execute function body
        for stmt in fn.value { 
            result = eval(&new_env, stmt)  
        }

        return result
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
            env.env[name] = result
        }

        case  If: assert(false, "Expected binding, found If")
        case  Binop: assert(false, "Expected binding, found Binop")
        case  Identifier: assert(false, "Expected binding, found Identifier")
        case  Function: assert(false, "Expected binding, found Function")
        case  Function_Call: assert(false, "Expected binding, found Function_Call")
        case  ^Expression: assert(false, "Expected binding, found Expression")
        case  Literal_Node: assert(false, "Expected binding, found Literal_Node")

    }

    return result
}

// Unsure if this should take a block type or [dynamic]^Expression. Maybe after type refactor will be more obvious
eval_block :: proc(env: ^Environment, exps: [dynamic]^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    func_env := make(map[string]Literal_Value_Type)
    new_env := Environment{
        parent = env,
        env = func_env,
    }
    defer delete(func_env)

    // Execute function body
    for stmt in exps { 
        result = eval(&new_env, stmt)  
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
        case If: result = eval_if(env, node)
        // Unsure if this is the right move...
        case ^Expression: result = eval(env, node.value.(^Expression))
    }

    // parser_errorf(node.pos, result != nil, "Nil node %v, result: %v", node, result)

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
    inflag: string
    debug:= false
    args, name = shift(args)
    args, file_name = shift(args)

    if len(args) > 0 {
        args, inflag = shift(args)
        if inflag == "debug" {
            debug = true 
        }
    }


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
    // for node in ast {
    //     fmt.printfln("%s", to_string(node))
    // }
    // assert(false, "stop")

    func_env := make(map[string]Literal_Value_Type)
    env := Environment{
        parent = nil,
        env = func_env,
    }
    defer delete(func_env)

    //main loop
    for node in ast {
        result := eval(&env, node)

        if debug {
            switch t in result {
                case Function: fmt.printfln("RES: %s",function_to_value_string(result.(Function)))
                case Number: fmt.printfln("RES: %#v",to_string(result))
                case string: fmt.printfln("RES: %#v",to_string(result))
                case bool: fmt.printfln("RES: %#v",to_string(result))
            }
        }
    }


    // fmt.printfln("%v", env)
    // for key, value in env {
    //     fmt.printfln("key %s, value: %s", key, literal_to_string(value))
    // }

    free_all(context.temp_allocator)

}

