#include <stdint.h>
#include <stdbool.h>
#define NOB_IMPLEMENTATION
#include "nob.h"
int main(int argc, char **argv)
{
    NOB_GO_REBUILD_URSELF(argc, argv);
    Nob_Cmd cmd = {0};
#ifdef _WIN32
    nob_cmd_append(&cmd, "clang", "--target=x86_64-w64-mingw32", "-Wall", "-Wextra", "-o", "auga", "auga.c");
#else
    nob_cmd_append(&cmd, "clang", "-Wall", "-Wextra", "-o", "auga", "auga.c");
#endif /* ifdef WIN64 */
    if (!nob_cmd_run(&cmd)) return 1;
    // nob_cmd_append(&cmd, "./auga.exe");
    // if (!nob_cmd_run(&cmd)) return 1;
    return 0;
}
