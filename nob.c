#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#define NOB_IMPLEMENTATION
#include "nob.h"
int main(int argc, char **argv)
{
    NOB_GO_REBUILD_URSELF(argc, argv);
    Nob_Cmd cmd = {0};
    char *program_name = nob_shift_args(&argc, &argv);
#ifdef _WIN32
    mkdir_if_not_exists("./build");
    nob_cmd_append(&cmd, 
        "clang", 
        "--target=x86_64-w64-mingw32", 
        "-Wall", 
        "-Wextra", 
        "-Wswitch",
        "-o", 
        "build/auga_windows.exe", 
        "auga.c"
    );

    if (!nob_cmd_run(&cmd)) return 1;
    if (argc > 0) {
        char *command_name = nob_shift_args(&argc, &argv);
        puts(command_name);
        if (strcmp(command_name, "-run") == 0) {
            nob_cmd_append(&cmd, "./build/auga_windows.exe");
            nob_cmd_append(&cmd, "./examples/first.auga");
            if (!nob_cmd_run(&cmd)) return 1;
        }
    }
#else
    nob_cmd_append(&cmd, "clang", "-Wall", "-Wextra", "-o", "build/auga", "auga.c");

    if (!nob_cmd_run(&cmd)) return 1;

    if (argc > 0) {
        char *command_name = nob_shift_args(&argc, &argv);
        if (strcmp(command_name, "-run") == 0) {
            nob_cmd_append(&cmd, "./build/auga");
            nob_cmd_append(&cmd, "./examples/first.auga");
            if (!nob_cmd_run(&cmd)) return 1;
        }
    }
#endif /* ifdef WIN64 */
    // nob_cmd_append(&cmd, "./auga.exe");
    // if (!nob_cmd_run(&cmd)) return 1;
    return 0;
}
