#include <stdio.h>
#include <stdlib.h>

int main() {
    FILE *fp;
    char path[1035];

    fp = popen("python3 --version 2>&1", "r");
    if (fp == NULL) {
        printf("Error: Python not found\n");
        return 1;
    }

    if (fgets(path, sizeof(path) - 1, fp) != NULL) {
        printf("Detected Python Version: %s", path);

        FILE *log = fopen("/tmp/python_ver.log", "w");
        if (log) {
            fprintf(log, "Detected Python Version: %s", path);
            fclose(log);
        }
    } else {
        printf("Error: Python not found\n");
        return 1;
    }

    pclose(fp);
    return 0;
}
