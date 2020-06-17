#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <time.h>
#include "kth-perm.c"

int num_cities = 5;
int shortest_length = INT_MAX;
int num_as_short = -1;
int num_trials = 0;
int random_seed = 42;

#define TSP_ELT(tsp, n, i, j) *(tsp + (i * n) + j)

void usage(char *prog_name){
    fprintf(stderr, "usage: %s [flags]\n", prog_name);
    fprintf(stderr, "   -h\n");
    fprintf(stderr, "   -c <number of cities>\n");
    fprintf(stderr, "   -s <random seed>\n");
    exit(1);
}

int *create_tsp(int n){
    int *tsp = (int*) malloc(n * n * sizeof(int));

    srandom(random_seed);
    for (int i = 0; i < n; i++){
        for (int j = 0; j <= i; j++){
            int val = (int)(random() / (RAND_MAX / 100));
            TSP_ELT(tsp, n, i, j) = val;
            TSP_ELT(tsp, n, j, i) = val;
        }
    }
    return tsp;
}

__global__
void shortest_path(int num_cities, int* dist, int* tsp) {
    long perms = factorial(num_cities);
    int perm_idx = perms*threadIdx.x/blockDim.x + 1;

    int* current_perm = kth_perm(perm_idx, num_cities);

    int local_min = INT_MAX;

    while(perm_idx < perms*(threadIdx.x+1)/blockDim.x + 1){
        int temp_min = 0;
        for(int i = 0; i < num_cities; i++){
            temp_min+=TSP_ELT(tsp, num_cities, current_perm[i], current_perm[(i+1)%num_cities]);
        }
        
        if(temp_min < local_min){
            local_min = temp_min;
        }
        next_perm(current_perm, num_cities);
        perm_idx++;
    }

    dist[threadIdx.x] = local_min;
}

void print_tsp(int *tsp, int n){
    printf("TSP (%d cities - seed %d)\n    ", n, random_seed);
    for (int j = 0; j < n; j++){
        printf("%3d|", j);
    }
    printf("\n");
    for (int i = 0; i < n; i++){
        printf("%2d|", i);
        for (int j = 0; j < n; j++){
            printf("%4d", TSP_ELT(tsp, n, i, j));
        }
        printf("\n");
    }
    printf("\n");
}

int main(int argc, char** argv) {
    int threads = 1;
    int ch;
    while ((ch = getopt(argc, argv, "c:hs:t:")) != -1){
        switch (ch){
        case 'c':
            num_cities = atoi(optarg);
            break;
        case 's':
            random_seed = atoi(optarg);
            break;
        case 't':
            threads = atoi(optarg);
            break;
        case 'h':
        default:
            usage(argv[0]);
        }
    }

    int* device_dist;
    cudaMalloc((void**)&device_dist, threads*sizeof(int));

    int* host_tsp = create_tsp(num_cities);
    int* device_tsp;
    cudaMalloc((void**)&device_tsp, num_cities*num_cities*sizeof(int));
    cudaMemcpy(device_tsp, host_tsp, num_cities*num_cities*sizeof(int), cudaMemcpyHostToDevice);

    shortest_path<<<1, threads>>>(num_cities, device_dist, device_tsp);

    //print_tsp(host_tsp, num_cities);
    
    int* host_dist = (int*) malloc(threads*sizeof(int));
    cudaMemcpy(host_dist, device_dist, threads * sizeof(int), cudaMemcpyDeviceToHost);

    int global_min = host_dist[0];
    for(int i = 0; i < threads; i++){
        if(host_dist[i] < global_min){
            global_min = host_dist[i];
        }
        //printf("Thread %i has value %i\n", i, host_dist[i]);
    }
    printf("%d\n", global_min);
    return 0;
}