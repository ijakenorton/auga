#define INDENT "  "

typedef enum {
	Debug   = 0,
	Info    = 10,
	Warning = 20,
	Error   = 30,
	Fatal   = 40,
} Logger_Level;

perror :: proc(pos: Position, message: string) -> string {
    return fmt.aprintf("\n%s Error: %s", to_string(pos), message)
}
