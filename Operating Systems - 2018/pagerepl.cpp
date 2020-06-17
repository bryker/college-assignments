#include <stdio.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include <string.h>
#include "policies.cpp"

long pages = 0;
int verbose = 0;
int policy;
Policytype* pagetable;

void set_policy(char * name){
    if (strcmp(optarg, "FIFO") == 0){
        policy = 1;
        if(verbose){
            printf("FIFO policy\n");
        }
    } else if (strcmp(optarg, "clock") == 0){
        policy = 2;
        if(verbose){
            printf("Clock policy\n");
        }
    } else {
        printf("Unrecognized policy: %s\n", optarg);
    }
}

int is_FIFO(){
    return policy == 1;
}
int is_Clock(){
    return policy == 2;
}


int main(int argc, char** argv){
    struct option opts[] = {
        {"policy", required_argument, 0, 'p'},
        {"num-pages", required_argument, 0, 'n'},
        {0,0,0,0}
    };
    int op;
    while ((op = getopt_long(argc, argv, "vp:n:", opts, NULL)) != -1){
        switch(op){
            case 'v':
                verbose = 1;
                printf("Verbose mode on\n");
                break;
            case 'n':
                pages = atol(optarg);
                if(verbose){
                    printf("Pages: %ld\n", pages);
                }
                break;
            case 'p':
                set_policy(optarg);
                break;
            default:
                printf("Unrecognized option -%c\n", op);
                break;
        }
    }
    if(pages <= 0){
        printf("Invalid or unset number of pages\n");
        return 1;
    }
    if (is_FIFO()){
        pagetable = new FIFOpolicy();
        pagetable->init(pages);
        if(verbose){
            pagetable->print();
        }
    } else if (is_Clock()){
        pagetable = new Clockpolicy();
        pagetable->init(pages);
        if(verbose){
            pagetable->print();
        }
    }


    char c;
    long addr;
    int len;
    while (scanf("%c\n", &c) == 1){
        if(c != 'I' && c != 'S' && c != 'L' && c != 'M'){
            printf("Junk line found\n\t");
            char junk;
            do {
                scanf("%c", &junk);
                printf("%c", junk);
            } while (junk != '\n');
        } else {
            scanf(" %lx, %i\n", &addr, &len);
            long pagenum = addr >> 12;
            if(! pagetable->findpage(pagenum)){
                pagetable->replacepage(pagenum);
            }
            long temp = (addr + len - 1) >> 12;
            if (temp != pagenum){
                if(! pagetable->findpage(temp)){
                    pagetable->replacepage(temp);
                }
            }
        }
    }
    printf("%s %ld: %ld\n", pagetable->getName(), pages, pagetable->getFaults());
    return 0;
}
