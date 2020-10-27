#include <iostream>
#include <math.h>

#define BLOCK_SIZE 32

__global__ void add(int n, float **x, float **y) {

    int i = BLOCK_SIZE * blockIdx.x + threadIdx.x;
    int j = BLOCK_SIZE * blockIdx.y + threadIdx.y;

    if (i < n && j < n){
        y[i][j] += x[i][j];
    }
}

int main(void) {
    
    int N = 1 << 10;  // N = 2^10 = 1024
    int N_blocks = 1 + (N-1)/BLOCK_SIZE;
    dim3 threads(BLOCK_SIZE, BLOCK_SIZE);
    dim3 blocks(N_blocks, N_blocks);
    float **x;
    float **y;

    cudaMallocManaged(&x, N*sizeof(float *));
    cudaMallocManaged(&y, N*sizeof(float *));

    for (int i = 0; i < N; i++){
        cudaMallocManaged(x+i, N*sizeof(float));
        cudaMallocManaged(y+i, N*sizeof(float));
    }
    
    for (int i = 0; i < N; i++){
        for (int j = 0; j < N; j++){
            x[i][j] = 1.0f;
            y[i][j] = 2.0f;
        }
    }
    add<<<blocks,threads>>>(N, x, y);
    cudaDeviceSynchronize();
    float maxError = 0.0f;
    int contError = 0;

    for (int i = 0; i < N; i++){
        for (int j = 0; j < N; j++){
            maxError = fmax(maxError,fabs(y[i][j]-3.0f));
            if (y[i][j] != 3.0) contError++;
        } 
    }
    std::cout << "Suma de " << N << "x" << N << " elementos" << std::endl;
    std::cout << "Número de errores: " << contError << std::endl;
    std::cout << "Max error: " << maxError << std::endl;

    for (int i = 0; i < N; i++){
        cudaFree(x[i]);
        cudaFree(y[i]);
    }

    cudaFree (x);
    cudaFree (y);
   
   return 0;
}