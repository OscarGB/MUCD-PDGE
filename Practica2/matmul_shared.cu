#include <stdio.h>
#define N 16
#define BLOCK_SIZE 32 < N ? 32 : N
void matrixMultCPU(int a[N][N], int b[N][N], int c[N][N]) {
	int n,m;
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			int sum = 0;
			for (int k = 0; k < N; k++) {
				m = a[i][k];
				n = b[k][j];
				sum += m * n;
			}
			c[i][j] = sum;
		}
	}
}


__global__ void matrixMultGPU(int *a, int *b, int *c) {
	int k, sum = 0;
	int col = threadIdx.x + blockDim.x * blockIdx.x;
	int fil = threadIdx.y + blockDim.y * blockIdx.y;

	__shared__ float A[BLOCK_SIZE][N];
	__shared__ float B[BLOCK_SIZE][N];

	for (int i = threadIdx.x; i < N; i+=blockDim.x){
		A[threadIdx.y][i] = a[fil*N + i];
	}
	for (int i = threadIdx.y; i < N; i+=blockDim.y){
		B[threadIdx.x][i] = b[i*N + col];
	}
	
	__syncthreads();

	if (col < N && fil < N) {
		// #pragma unroll
		for (k = 0; k < N; k++) {
			sum += A[threadIdx.y][k] * B[threadIdx.x][k];
		}
		c[fil * N + col] = sum;
	}
}


int main() {
	int a[N][N], b[N][N], c[N][N], d[N][N];
	int *dev_a, *dev_b, *dev_c;
	int cont,i,j;
/* inicializando variables con datos*/
	for (i = 0; i < N; i++) {
		cont = 0;
		for (j = 0; j < N; j++) {
			a[i][j] = cont;
			b[i][j] = cont;
			cont++;
		}
	}
	int size = N * N * sizeof(int);

	cudaMalloc((void **) &dev_a, size);
	cudaMalloc((void **) &dev_b, size);
	cudaMalloc((void **) &dev_c, size);

	cudaMemcpy(dev_a, a, size, cudaMemcpyHostToDevice);
	cudaMemcpy(dev_b, b, size, cudaMemcpyHostToDevice);

	dim3 dimGrid((N+32-1)/32, (N+32-1)/32);
	dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE);

  	// Allocate CUDA events that we'll use for timing
	cudaEvent_t start;
	cudaEventCreate(&start);
	cudaEvent_t stop;
	cudaEventCreate(&stop);
 // Record the start event
	cudaEventRecord(start, NULL);
// Repita la ejecucion del kernel 1000 veces para eliminar
// efectos de arranque en frio
	int nIter = 1000;
	for (int j = 0; j < nIter; j++)
		matrixMultGPU<<<dimGrid, dimBlock>>>(dev_a, dev_b, dev_c);

 // Record the stop event
	cudaEventRecord(stop, NULL);
 // Wait for the stop event to complete
	cudaEventSynchronize(stop);
	float msecTotal = 0.0f;
	cudaEventElapsedTime(&msecTotal, start, stop);
// Compute and print the performance
	float msecPerKernelExecution = msecTotal / nIter;
	double flopsPerMMul = 2.0 * N * N * N;
	double gigaFlops = (flopsPerMMul * 1.0e-9f) /
	(msecPerKernelExecution / 1000.0f);

	printf("GFlops: %lf\n", gigaFlops);
	printf("TPKernel: %lf\n", msecPerKernelExecution);
	printf("Size: %d\n", N);

	matrixMultCPU(a,b,d);

	cudaMemcpy(c, dev_c, size, cudaMemcpyDeviceToHost);
	cudaFree(dev_a);
	cudaFree(dev_b);
	cudaFree(dev_c);

// comprobando
	for (int y = 0; y < N; y++) {
		for (int x = 0; x < N; x++) {
			if (c[y][x] != d[y][x]){
				printf("ERROR en %d %d, %d != %d\n", y,x,c[y][x], d[y][x]);
				return 1;
			}
		}
	}
	printf("SUCCESS\n");
	return 0;
}