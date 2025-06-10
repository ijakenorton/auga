package main

import "core:fmt"
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
