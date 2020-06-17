CC=nvcc
CFLAGS=-Wall -Werror

tsp-cuda: tsp-cuda.cu
	$(CC) tsp-cuda.cu -o tsp-cuda
	rm tsp-cuda.cu

tsp-cuda.cu:
	cp tsp-cuda.c tsp-cuda.cu

clean:
	rm -f tsp-cuda 
	rm tsp-cuda.cu