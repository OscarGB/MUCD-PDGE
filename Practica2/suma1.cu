#include <iostream>
#include <math.h>


__global__ void add(int n, float *x, float *y) {
    
    for (int i =0; i < n; i++){
        y[i] = x[i]+y[i];
    }
}

int main(void) {
    
    int N = 1 << 20;  // N = 2^20 = 1024*1024= 1.048.576
    float *x; // = new float[N];
    float *y; // = new float[N]; 
    cudaMallocManaged(&x, N*sizeof(float));
    cudaMallocManaged(&y, N*sizeof(float));
    
    for (int i = 0; i < N; i++){
        x[i] = 1.0f;
        y[i] = 2.0f;
    }
    add<<<1,1>>>(N, x, y);
    cudaDeviceSynchronize();
    float maxError = 0.0f;
    int contError = 0;

    for (int i = 0; i < N; i++){
       maxError = fmax(maxError, fabs(y[i]-3.0f));
       if (y[i] != 3.0) contError++; 
    }
    std::cout << "suma de " << N << " Elementos" << std::endl;
    std::cout << "Número de Errores: " <<contError << std::endl;
    std::cout << "Max error: " <<maxError << std::endl;
    cudaFree (x);
    cudaFree (y);
   
   return 0;
}
