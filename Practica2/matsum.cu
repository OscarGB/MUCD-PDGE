#include "../common/book.h"
#define N 10

__global__ void add( int *a, int *b, int *c ) {
	int tid = blockIdx.x; // handle the data at this index
	if (tid < N)
	c[tid] = a[tid] + b[tid];
}

int main( void ) {
	int a[N], b[N], c[N];
	int *dev_a, *dev_b, *dev_c;
	// allocate the memory on the GPU
	HANDLE_ERROR( cudaMalloc( (void**)&dev_a, N * sizeof(int) ) );
	HANDLE_ERROR( cudaMalloc( (void**)&dev_b, N * sizeof(int) ) );
	HANDLE_ERROR( cudaMalloc( (void**)&dev_c, N * sizeof(int) ) );
	// fill the arrays 'a' and 'b' on the CPU
	for (int i=0; i<N; i++) {
		a[i] = -i;
		b[i] = i * i;
	}