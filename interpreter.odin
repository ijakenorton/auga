package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:os/os2"


Environment :: struct {
    env: map[string]Literal_Value_Type,
    parent: ^Environment,
}

Return_Value :: struct {
    value: ^Literal_Value_Type,
    pos: Position,
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
        case Function: assert(false, "Must be a LITERAL NUMBER not Function, perhaps this should try to eval the function?")
        case string: assert(false, "Must be a LITERAL NUMBER not string")
        case bool: assert(false, "Must be a LITERAL NUMBER not bool")
        case Return_Value: assert(false, "Must be a LITERAL NUMBER not Return_Value")
        case Array_Literal: assert(false, "Must be a LITERAL NUMBER not Array_Literal literal")
    }

    return  result
}


literal_to_number :: proc(node: ^Expression) -> Number {

    result : Number

    literal_node := node.value.(Literal_Node)
    switch t in literal_node.value{
        case Number: result = literal_node.value.(Number)
        case Function: assert(false, "Must be a LITERAL NUMBER not Function")
        case Return_Value: assert(false, "Must be a LITERAL NUMBER not Return_Value")
        case string: assert(false, "Must be a LITERAL NUMBER not string")
        case bool : assert(false, "Must be a LITERAL NUMBER not bool")
        case Array_Literal : assert(false, "Must be a LITERAL NUMBER not Array_Literal")
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

eval_minus :: proc(left: Number, right: Number) -> Number {
    switch l in left {
    case f64:
        switch r in right {
            case f64: return l - r    
            case i64: return l - f64(r)
        }
    case i64:
        switch r in right {
            case f64: return f64(l) - r
            case i64: return l - r    
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

eval_lt :: proc(left: Number, right: Number) -> bool {
    switch l in left {
    case f64:
        switch r in right {
            case f64: return l < r    
            case i64: return l < f64(r) 
        }
    case i64:
        switch r in right {
            case f64: return f64(l) < r 
            case i64: return l < r     
        }
    }

    assert(false, "UNREACHABLE")
    return false
}

eval_gt :: proc(left: Number, right: Number) -> bool {
    switch l in left {
    case f64:
        switch r in right {
            case f64: return l > r     
            case i64: return l > f64(r) 
        }
    case i64:
        switch r in right {
            case f64: return f64(l) > r  
            case i64: return l > r
        }
    }

    assert(false, "UNREACHABLE")
    return false
}

// TODO add better checking, very much happy path currently
// Also needs to handle other for constructions e.g: 
//     for 0 .. 10 .. 1 {
//         print("0..10..1")
//     }
//     for ele .. elements .. {
//         print("ele .. elements ..")
//     }
eval_for :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type

    for_node := node.value.(For)
    // fmt.printf("cond: %s", to_string(for_node.cond))
    // fmt.printf("update_exp: %s", to_string(for_node.update_exp))
    // fmt.printf("iterator: %s", to_string(for_node.iterator))

    // assert(false, "NOT IMPLEMENTED")
    unwrapped_cond : bool

    func_env := make(map[string]Literal_Value_Type)
    new_env := Environment{
        parent = env,
        env = func_env,
    }
    defer delete(func_env)

    binding := for_node.iterator.value.(Binding)
    result = eval(env, binding.value)
    env.env[binding.name] = result
    for {
        cond := eval(&new_env, for_node.cond)
        switch t in cond {
            case Number: parser_errorf(for_node.pos ,false, 
                 "If condition expression must result in a boolean, found Number")
            case Function: parser_errorf(for_node.pos ,false, 
                 "If condition expression must result in a boolean, found Function")
            case string: parser_errorf(for_node.pos ,false, 
                 "If condition expression must result in a boolean, found String")
            case Return_Value: parser_errorf(for_node.pos ,false, 
                 "If condition expression must result in a boolean, found Return_Value, maybe should be unwrapped")
            case Array_Literal: parser_errorf(for_node.pos ,false, 
                 "If condition expression must result in a boolean, found Array_Literal")
            case bool : 
                unwrapped_cond = cond.(bool)
        }

        if unwrapped_cond {
            result = eval_block(&new_env, for_node.body)
        } else {
            return result
        }

        update_exp := eval(&new_env, for_node.update_exp)
        //TODO Unsure if this is the move but will work for the time being
        env.env[binding.name] = update_exp
    }

    return result
}

eval_while :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type

    while_node := node.value.(While)
    unwrapped_cond : bool

    func_env := make(map[string]Literal_Value_Type)
    new_env := Environment{
        parent = env,
        env = func_env,
    }
    defer delete(func_env)
    for {
        if while_node.cond == nil {
            unwrapped_cond = true
        } else {
            cond := eval(&new_env, while_node.cond)

            switch t in cond {
                case Number: parser_errorf(while_node.pos ,false, 
                     "If condition expression must result in a boolean, found Number")
                case Function: parser_errorf(while_node.pos ,false, 
                     "If condition expression must result in a boolean, found Function")
                case string: parser_errorf(while_node.pos ,false, 
                     "If condition expression must result in a boolean, found String")
                case Return_Value: parser_errorf(while_node.pos ,false, 
                     "If condition expression must result in a boolean, found Return_Value, maybe should be unwrapped")
                case Array_Literal: parser_errorf(while_node.pos ,false, 
                     "If condition expression must result in a boolean, found Array_Literal")
                case bool : 
                    unwrapped_cond = cond.(bool)
            }
        }


        if unwrapped_cond {

            result = eval_block(&new_env, while_node.body)
        } else {
            return result
        }
    }

    return result
}
eval_if :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type

    if_node := node.value.(If)
    cond := eval(env, if_node.cond)

    switch t in cond {
        case Number: parser_errorf(if_node.pos ,false, "If condition expression must result in a boolean, found Number")
        case Function: parser_errorf(if_node.pos ,false, "If condition expression must result in a boolean, found Function")
        case string: parser_errorf(if_node.pos ,false, "If condition expression must result in a boolean, found String")
        case Return_Value: parser_errorf(if_node.pos ,false, "If condition expression must result in a boolean, found Return_Value")
        case Array_Literal: parser_errorf(if_node.pos ,false, "If condition expression must result in a boolean, found Array_Literal")
        case bool : 
    }

    if cond.(bool) {
        func_env := make(map[string]Literal_Value_Type)
        new_env := Environment{
            parent = env,
            env = func_env,
        }
        defer delete(func_env)
        result = eval_block(env, if_node.body)

    } else if if_node.elze != nil {
        func_env := make(map[string]Literal_Value_Type)
        new_env := Environment{
            parent = env,
            env = func_env,
        }
        defer delete(func_env)
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
                case Array_Literal: return false
                case Return_Value: parser_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
            }
        }
        case string: {
            switch t in right {
                case Number: return false
                case string: return left.(string) == right.(string)
                case bool: return false
                case Function: return false
                case Array_Literal: return false
                case Return_Value: parser_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
            }
        }
        case bool: {
            switch t in right {
                case Number: return false
                case string: return false
                case bool: return left.(bool) == right.(bool)
                case Function: return false
                case Array_Literal: return false
                case Return_Value: parser_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
            }
        }
        case Function: {
            switch t in right {
                case Number: return false
                case string: return false
                case bool: return false
                //TODO Maybe need to adjust this in the future, possibly just pointer equality, or recursive struct equality
                case Function: return false
                case Array_Literal: return false
                case Return_Value: parser_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
            }
        }

        case Array_Literal: {
            switch t in right {
                case Number: return false
                case string: return false
                case bool: return false
                //TODO Maybe need to adjust this in the future, possibly just pointer equality, or recursive struct equality
                case Function: return false
                //TODO Maybe should be extracted to a function
                case Array_Literal: {
                    left := left.(Array_Literal)
                    right := right.(Array_Literal)
                    if len(left.elements) != len(right.elements) { return false }
                    for i in 0 ..< len(left.elements) {
                        if !eval_same(left.elements[i], right.elements[i])  { return false }
                    }
                    return true
                }
                case Return_Value: parser_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
            }
        }

        case Return_Value: parser_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
    }

    assert(false, "UNREACHABLE")
    return false
}

eval_binop :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    switch t in node.value {
        case  While, For, Return, Array, If, Function, Function_Call, Binding, Identifier, ^Expression, Literal_Node, Array_Access: { 
            parser_errorf(node.pos ,false, "Expected Binop got %s", t)
        }

        case  Binop: {
            binop := node.value.(Binop)
            left := eval(env, binop.left)
            right := eval(env, binop.right)
            switch binop.kind {
                case .SAME : {
                    result = eval_same(left, right)
                }
                case .LT : {
                    left_number := literal_value_to_number(left)
                    right_number := literal_value_to_number(right) 
                    result = eval_lt(left_number, right_number)
                }
                case .GT : {
                    left_number := literal_value_to_number(left)
                    right_number := literal_value_to_number(right) 
                    result = eval_gt(left_number, right_number)
                }
                case .PLUS : {
                    left_number := literal_value_to_number(left)
                    right_number := literal_value_to_number(right) 
                    result = eval_add(left_number, right_number)
                }
                case .MINUS : {
                    left_number := literal_value_to_number(left)
                    right_number := literal_value_to_number(right) 
                    result = eval_minus(left_number, right_number)
                }
                case .MULTIPLY: {
                    left_number := literal_value_to_number(left)
                    right_number := literal_value_to_number(right) 
                    result = eval_mul(left_number, right_number)
                }
                case .DIVIDE :{
                    left_number := literal_value_to_number(left)
                    right_number := literal_value_to_number(right) 
                    result = eval_div(left_number, right_number)
                }

                case .MOD :{
                    left_number := literal_value_to_number(left)
                    right_number := literal_value_to_number(right) 
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
        case Array_Literal : result = ident.(Array_Literal)
        case Return_Value: parser_errorf(ident.(Return_Value).pos ,false, "found Return, expected Identifier")
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
        case Array_Literal: result = eval_array(env, node)
        case Return_Value: parser_errorf(literal_node.value.(Return_Value).pos ,false, "found Return, expected literal")
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
            param_value := eval(env, param)
            fmt.printf("%s", to_value_string(param_value))
        }

        fmt.println()

        return true
    } 
    else if name == "shell" {
        if len(params) < 1 {
            parser_errorf(node.pos, false, "shell() expects at least 1 argument")
        }
        
        // First param is the command
        command_value := eval(env, params[0])
        command := command_value.(string)
        
        // Remaining params are arguments
        args: [dynamic]string
        for i in 1..<len(params) {
            arg_value := eval(env, params[i])
            append(&args, arg_value.(string))
        }
        
        result_array := eval_shell(command, args[:])
        return result_array
    } else {
        var, ok := env_get(env, name)
        if !ok {
            parser_errorf(node.pos, false, "Var: %s, is undefined in the current scope", name)
        }

        switch t in var {
            case Function: fn = var.(Function)
            case Number, string, bool, Array_Literal: 
                parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", t)
            case Return_Value: parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", t)
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
        
        result = eval_block(&new_env, fn.value)

        return result
    }

    return result
}

eval_shell :: proc(command: string, args: []string) -> Array_Literal {
    // Build the full command
    full_command := command
    if len(args) > 0 {
        full_command = fmt.aprintf("%s %s", command, strings.join(args, " "))
    }
    
    // Set up process description
    desc := os2.Process_Desc{
        command = []string{"sh", "-c", full_command},
        // stdout and stderr left as nil for capture
    }
    
    // Execute and capture output
    state, stdout_bytes, stderr_bytes, err := os2.process_exec(desc, context.allocator)
    defer delete(stdout_bytes)
    defer delete(stderr_bytes)
    
    // Convert bytes to strings
     stdout_str := strings.clone_from_bytes(stdout_bytes)
     stderr_str := strings.clone_from_bytes(stderr_bytes)
    // stdout_str := string(stdout_bytes)
    // stderr_str := string(stderr_bytes)
    exit_code := state.exit_code
    
    // Create result array
    elements: [dynamic]Literal_Value_Type
    append(&elements, stdout_str)                    // stdout
    append(&elements, stderr_str)                    // stderr  
    append(&elements, Number(i64(exit_code)))        // return code
    //fmt.printf("\e[0;32m%v\e[0m\n", exit_code)
    
    return Array_Literal{
        elements = elements,
        pos = Position{},
    }
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

        case  While, For, Return, If, Function, Function_Call, Binop, Identifier, ^Expression, Literal_Node, Array, Array_Access: { 
            parser_errorf(node.pos ,false, "Expected Binding got %s", t)
        }
    }

    return result
}

eval_array :: proc(env: ^Environment, node: ^Expression) -> Array_Literal {
    array_literal := node.value.(Array)  // From parser
    
    evaluated_elements: [dynamic]Literal_Value_Type
    for expr in array_literal.elements {
        value := eval(env, expr)  // Evaluate each expression
        append(&evaluated_elements, value)
    }
    
    return Array_Literal{
        elements = evaluated_elements,  // Store evaluated values
        pos = array_literal.pos,
    }
}

eval_array_index :: proc(array_literal: Literal_Value_Type, index: Number) -> Literal_Value_Type {
    switch t in array_literal {
        case Number, string, bool, Function, Return_Value: 
            parser_errorf(node.pos, false, "Unexpected KIND: %v expected FUNCTION_CALL", t)
        case Array_Literal: 
    }
    array_checked := array_literal.(Array_Literal)
    switch t in index {
        case i64: {
            return array_checked.elements[index.(i64)]
        }
        case f64: {
            return array_checked.elements[cast(i64)index.(f64)]
        }
    }
    return nil
}

to_literal_type :: proc(literal: Literal_Value_Type, type: Literal_Value_Type) -> Literal_Value_Type{

    switch t in literal {
        case Array_Literal, string, bool, Function, Return_Value: 
            // parser_errorf(node.pos, false, "Unexpected KIND: %v expected Number", t)
        case Number: 
    }
    return literal
}

eval_array_access :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    array := node.value.(Array_Access)
    index := eval(env, array.index)

    switch t in index {
        case Array_Literal, string, bool, Function, Return_Value: 
            parser_errorf(node.pos, false, "Unexpected KIND: %v expected Number", t)
        case Number: 
    }
    index_checked := index.(Number)

    array_literal, ok := env_get(env, array.name)
    if !ok {
        parser_errorf(node.pos, false, "Var: %s, is undefined in the current scope", array.name)
    }

    return eval_array_index(array_literal, index_checked)
}

// Unsure if this should take a block type or [dynamic]^Expression. Maybe after type refactor will be more obvious
eval_block :: proc(env: ^Environment, exps: [dynamic]^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
// Execute function body
    for stmt in exps { 
        result = eval(env, stmt)  
        switch t in result {
            case Return_Value: return result.(Return_Value).value^
            case Function:
            case Number:
            case string:
            case bool:
            case Array_Literal:
        }
    }

    return result
}

eval_return :: proc(env: ^Environment, exp: ^Expression) -> Literal_Value_Type {
    returnn := exp.value.(Return)
    result := eval(env,returnn.value)  

    return Return_Value{ value = &result, pos = exp.pos }
}

eval :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type{
    result : Literal_Value_Type

    switch t in node.value {
        case Return: result = eval_return(env, node) 
        case Literal_Node: result = eval_literal(env, node)
        case Identifier: result = eval_identifier(env, node)
        case Binding: result = eval_binding(env, node)
        case Function: result = eval_function(env, node)
        case Array: result = eval_array(env, node)
        case Function_Call: result = eval_function_call(env, node)
        case Array_Access: {
            // assert(false, "IMPLEMENTED")
            result = eval_array_access(env, node)
        }
        case Binop: result = eval_binop(env, node)
        case If: result = eval_if(env, node)
        case While: result = eval_while(env, node)
        case For: result = eval_for(env, node)
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
                case Return_Value: fmt.printfln("RES: %s",to_string(result.(Return_Value)))
                case Number: fmt.printfln("RES: %s",to_string(result.(Number)))
                case string: fmt.printfln("RES: %s",to_string(result.(string)))
                case bool: fmt.printfln("RES: %s",to_string(result.(bool)))
                case Array_Literal: fmt.printfln("RES: %s",to_string(result.(Array_Literal)))
            }
        }
    }


    // fmt.printfln("%v", env)
    // for key, value in env {
    //     fmt.printfln("key %s, value: %s", key, literal_to_string(value))
    // }

    free_all(context.temp_allocator)

}

