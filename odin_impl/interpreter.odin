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

env_create :: proc(parent: ^Environment) -> Environment{
    func_env := make(map[string]Literal_Value_Type)
    return Environment {
        parent = parent,
        env = func_env,
    }
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

expect_expression_type :: proc($T: typeid, node: ^Expression, message := "", loc := #caller_location) -> T {
    #partial switch v in node.value {
        case T: return v
        case: {
            if message == "" {
                internal_errorf(Position{}, false, "Expected %v, got value: %v \n%s Error: From function below\n", typeid_of(T), v, loc)
            } else {
                internal_errorf(Position{}, false, message)
            }
        }
    }
    return {}
}

expect_literal_type :: proc($T: typeid, literal: Literal_Value_Type, message := "", loc := #caller_location) -> T {
    #partial switch v in literal {
        case T: return v
        case: {
            if message == "" {
                internal_errorf(Position{},
                    false, 
                    "Expected %v, got value: %v \n%s Error: From caller function\n",
                    typeid_of(T), 
                    v, 
                    loc)
            } else {
                internal_errorf(Position{}, false, message)
            }
        }
    }
    return {}
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

eval_same :: proc(left: Literal_Value_Type, right: Literal_Value_Type) -> bool {
    switch t in left {
        case Number: {
            switch t in right {
                case Number: return left.(Number) == right.(Number)
                case string: return false
                case bool: return false
                case Function: return false
                case Array_Literal: return false
                case Return_Value: internal_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
            }
        }
        case string: {
            switch t in right {
                case Number: return false
                case string: return left.(string) == right.(string)
                case bool: return false
                case Function: return false
                case Array_Literal: return false
                case Return_Value: internal_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
            }
        }
        case bool: {
            switch t in right {
                case Number: return false
                case string: return false
                case bool: return left.(bool) == right.(bool)
                case Function: return false
                case Array_Literal: return false
                case Return_Value: internal_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
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
                case Return_Value: internal_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
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
                case Return_Value: internal_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
            }
        }

        case Return_Value: internal_errorf(right.(Return_Value).pos ,false, "found Return in == expression")
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
    cond_bool : bool


    binding := for_node.iterator.value.(Binding)
    result = eval(env, binding.value)
    env.env[binding.name] = result

    new_env := env_create(env)
    defer delete(new_env.env)

    for {
        if for_node.cond == nil {
            cond_bool = true
        } else {
            cond := eval(&new_env, for_node.cond)
            cond_bool = expect_literal_type(bool, cond)
        }

        //Should we continue
        if cond_bool {
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
    cond_bool : bool

    new_env := env_create(env)
    defer delete(new_env.env)

    for {
        if while_node.cond == nil {
            cond_bool = true
        } else {
            cond := eval(&new_env, while_node.cond)
            cond_bool = expect_literal_type(bool, cond)
        }

        //Should we continue
        if cond_bool {
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
    cond_bool := expect_literal_type(bool, cond)

    new_env := env_create(env)
    defer delete(new_env.env)

    if cond_bool {
        result = eval_block(env, if_node.body)
    } else if if_node.elze != nil {
        result = eval_block(env, if_node.elze)
    }

    return result
}

eval_binop :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    binop := expect_expression_type(Binop, node)

    left := eval(env, binop.left)
    right := eval(env, binop.right)

    switch binop.kind {
        case .SAME : {
            result = eval_same(left, right)
        }
        case .LT : {
            left_number := expect_literal_type(Number, left)
            right_number := expect_literal_type(Number, right)
            result = eval_lt(left_number, right_number)
        }
        case .GT : {
            left_number := expect_literal_type(Number, left)
            right_number := expect_literal_type(Number, right)
            result = eval_gt(left_number, right_number)
        }
        case .PLUS : {
            left_number := expect_literal_type(Number, left)
            right_number := expect_literal_type(Number, right)
            result = eval_add(left_number, right_number)
        }
        case .MINUS : {
            left_number := expect_literal_type(Number, left)
            right_number := expect_literal_type(Number, right)
            result = eval_minus(left_number, right_number)
        }
        case .MULTIPLY: {
            left_number := expect_literal_type(Number, left)
            right_number := expect_literal_type(Number, right)
            result = eval_mul(left_number, right_number)
        }
        case .DIVIDE :{
            left_number := expect_literal_type(Number, left)
            right_number := expect_literal_type(Number, right)
            result = eval_div(left_number, right_number)
        }

        case .MOD :{
            left_number := expect_literal_type(Number, left)
            right_number := expect_literal_type(Number, right)
            left_integer : i64
            right_integer : i64

            switch t in left_number {
                case f64: runtime_errorf(node.pos ,false, "Operator '%' is only allowed with integers, got float64")
                case i64: left_integer = left_number.(i64)
            }

            switch t in right_number {
                case f64: runtime_errorf(node.pos ,false, "Operator '%' is only allowed with integers, got float64")
                case i64: right_integer = right_number.(i64)
            }
            result = Number(left_integer % right_integer)
        }
        case : internal_errorf(node.pos ,false, "Expected Binop, got %s", binop.kind)
    }

    return result
}

eval_identifier :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    identifier := expect_expression_type(Identifier, node)
    
    ident, ok := env_get(env, identifier.name)
    if !ok {
        runtime_errorf(node.pos, false, "Var: %s, is undefined in the current scope", identifier.name)
    }
    switch t in ident {
        case Number: result = ident.(Number)
        case string: result = ident.(string)
        case Function: result = ident.(Function) 
        case bool : result = ident.(bool)
        case Array_Literal : result = ident.(Array_Literal)
        case Return_Value: runtime_errorf(ident.(Return_Value).pos ,false, "found Return, expected Identifier")
        case : runtime_errorf(node.pos, false, "Var: %s, Expected NUMBER | STRING | FUNCTION | BOOL | ARRAY_LITERAL | RETURN_VALUE found: %v", ident, identifier.name)
    }
    return result
}

// Basically just type assertions out of the Literal_Value_Type union
eval_literal :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    result : Literal_Value_Type
    literal_node := expect_expression_type(Literal_Node, node)
    switch t in literal_node.value {
        case Number: result = literal_node.value.(Number)
        case string: result = literal_node.value.(string)
        case bool: result = literal_node.value.(bool)
        case Function: result = eval_function(env, node)
        case Array_Literal: result = eval_array(env, node)
        case Return_Value: internal_errorf(literal_node.value.(Return_Value).pos ,false, "found Return, expected literal")
    }
    return result
}

//Unsure what to do with this yet, I can just be printed, in which case it should return a string? OR a Function
eval_function :: proc(env: ^Environment, node: ^Expression) -> Function {
    return expect_expression_type(Function, node)
}


eval_function_call :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    function_call := expect_expression_type(Function_Call, node)
    result : Literal_Value_Type

    params := function_call.params
    name := function_call.name
    fn : Function

    if name == "print" {
        for param in params{
            param_value := eval(env, param)
            fmt.printf("%s", to_value_string(param_value))
        }
        fmt.println()

        return true
    } 
    else if name == "shell" {
        if len(params) < 1 {
            runtime_errorf(node.pos, false, "shell() expects at least 1 argument")
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
            runtime_errorf(node.pos, false, "Var: %s, is undefined in the current scope", name)
        }

        fn = expect_literal_type(Function, var)

        param_length := len(params)
        arg_length := len(fn.args)

        new_env := env_create(env)
        defer delete(new_env.env)

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
    exit_code := state.exit_code
    
    elements: [dynamic]Literal_Value_Type
    append(&elements, stdout_str)
    append(&elements, stderr_str)
    append(&elements, Number(i64(exit_code)))
    
    return Array_Literal{
        elements = elements,
        pos = Position{},
    }
}

eval_binding :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    binding := expect_expression_type(Binding, node)
    result : Literal_Value_Type
    name := binding.name
    result = eval(env, binding.value)
    env.env[name] = result
    return result
}

eval_array :: proc(env: ^Environment, node: ^Expression) -> Array_Literal {
    array_literal := expect_expression_type(Array, node)
    
    evaluated_elements: [dynamic]Literal_Value_Type
    for expr in array_literal.elements {
        value := eval(env, expr)  
        append(&evaluated_elements, value)
    }
    
    return Array_Literal {
        elements = evaluated_elements,  
        pos = array_literal.pos,
    }
}

eval_array_index :: proc(array_checked: Array_Literal, index: Number) -> Literal_Value_Type {
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

eval_array_access :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    array := expect_expression_type(Array_Access, node)
    array_literal, ok := env_get(env, array.name)
    if !ok {
        runtime_errorf(node.pos, false, "Var: %s, is undefined in the current scope", array.name)
    }
    array_checked := expect_literal_type(Array_Literal, array_literal)

    index := eval(env, array.index)
    index_checked := expect_literal_type(Number, index)

    return eval_array_index(array_checked, index_checked)
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

eval_return :: proc(env: ^Environment, node: ^Expression) -> Literal_Value_Type {
    returnn := expect_expression_type(Return, node)
    result := eval(env,returnn.value)  

    return Return_Value{ value = &result, pos = node.pos }
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
        case Array_Access: result = eval_array_access(env, node)
        case Binop: result = eval_binop(env, node)
        case If: result = eval_if(env, node)
        case While: result = eval_while(env, node)
        case For: result = eval_for(env, node)
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
    args, name = shift(args)
    args, file_name = shift(args)

    if len(args) > 0 {
        args, inflag = shift(args)
        if inflag == "debug" {
            DEBUG = true 
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

    env := env_create(nil)
    delete(env.env)

    //main loop
    for node in ast {
        result := eval(&env, node)

        if DEBUG {
            switch t in result {
                case Function: fmt.printfln("[DEBUG]: %s",function_to_value_string(result.(Function)))
                case Return_Value: fmt.printfln("[DEBUG]: %s",to_string(result.(Return_Value)))
                case Number: fmt.printfln("[DEBUG]: %s",to_string(result.(Number)))
                case string: fmt.printfln("[DEBUG]: %s",to_string(result.(string)))
                case bool: fmt.printfln("[DEBUG]: %s",to_string(result.(bool)))
                case Array_Literal: fmt.printfln("[DEBUG]: %s",to_string(result.(Array_Literal)))
            }
        }
    }


    // fmt.printfln("%v", env)
    // for key, value in env {
    //     fmt.printfln("key %s, value: %s", key, literal_to_string(value))
    // }

    free_all(context.temp_allocator)

}

