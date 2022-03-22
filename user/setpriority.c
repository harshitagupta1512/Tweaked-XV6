#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char **argv) {

    if (argc != 3) {
        printf("Invalid Command\n");
        return 1;
    }

    int new = atoi(argv[1]);
    int pid = atoi(argv[2]);

    int old = set_priority(new, pid);
    if (old == -1)
        return 0;

    return 1;
}