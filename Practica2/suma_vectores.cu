#include <iostream>
#include <math.h>

#define THREADS_PER_BLOCK 1024

__global__ void add(int n, float *x, float *y) {

    int i = THREADS_PER_BLOCK * blockIdx.x + threadIdx.x;

    if (i < n){
        y[i] += x[i];
    }
}

int main(void) {
    
    int N = 1 << 20;  // N = 2^20 = 1024*1024= 1.048.576
    int N_blocks = 1 + (N-1)/THREADS_PER_BLOCK; // ceiling(N/THREADS_PER_BLOCK)
    float *x; // = new float[N];
    float *y; // = new float[N]; 
    cudaMallocManaged(&x, N*sizeof(float));
    cudaMallocManaged(&y, N*sizeof(float));
    
    for (int i = 0; i < N; i++){
        x[i]= 1.0f;
        y[i]= 2.0f;
    }
    add<<<N_blocks,THREADS_PER_BLOCK>>>(N, x, y);
    cudaDeviceSynchronize();
    float maxError = 0.0f;
    int contError = 0;

    for (int i = 0; i < N; i++){
       maxError = fmax(maxError,fabs(y[i]-3.0f));
       if (y[i] != 3.0) contError++; 
    }
    std::cout << "Suma de " << N << " elementos" << std::endl;
    std::cout << "Número de errores: " <<contError << std::endl;
    std::cout << "Max error: " <<maxError << std::endl;

    cudaFree (x);
    cudaFree (y);
   
   return 0;
}