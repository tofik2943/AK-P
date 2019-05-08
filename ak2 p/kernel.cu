#include <stdio.h>
#include <math.h> 
#include "cuda_runtime.h"
#include "device_launch_parameters.h"



cudaError_t addWithCuda(float *c, const float *tab, float alpha, int arraySize);		//NIE WIEM CZY POWINIEN BYC WSKAZNIK NA ALPHA/ARRAYSIZE


__global__ void addKernel(float *c, const float *tab, float alpha) {
	int i = threadIdx.x; //zaczyna sie od zera
	float x = tab[i * 3];
	float y = tab[i * 3 + 1];
	x = x * cos(alpha) - y * sin(alpha);
	y = x * sin(alpha) + y * cos(alpha);
	c[i * 3] = x;
	c[i * 3 + 1] = y;
}


/*
__global__ void addKernel(int *c, const int *a, const int *b)
{
	int i = threadIdx.x;
	c[i] = a[i] + b[i];
}
*/
int main()
{
	float alpha = 0;
	const int arraySize = 21; //7punkt�w po 3 wsp�rz�dne
	const float tab[arraySize] = { 1, 2, 3, 4, 5, 6 ,7, 1, 2, 3, 4, 5, 6 ,7,  1, 2, 3, 4, 5, 6 ,7 };

	float c[arraySize] = { 1, 2, 3, 4, 5, 6 ,7, 1, 2, 3, 4, 5, 6 ,7,  1, 2, 3, 4, 5, 6 ,7, };

	// Add vectors in parallel.
	cudaError_t cudaStatus = addWithCuda(c, tab, alpha, arraySize);	// jakies wskazniki?
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "addWithCuda failed!");
		return 1;
	}
	/*
	printf("{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
		c[0], c[1], c[2], c[3], c[4]); */

		// cudaDeviceReset must be called before exiting in order for profiling and
		// tracing tools such as Nsight and Visual Profiler to show complete traces.
	cudaStatus = cudaDeviceReset();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceReset failed!");
		return 1;
	}

	return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(float *c, float  *tab, float *alpha, int *arraySize)		//nie wiem dlaczego powinien byc wskaznik alpha
{
	float *dev_tab;
	float *dev_c;
	float *dev_alpha;
	const int dev_arraySize = 21;
	cudaError_t cudaStatus;

	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		goto Error;
	}

	// Allocate GPU buffers for three vectors (two input, one output)    .
	cudaStatus = cudaMalloc((void**)&arraySize, sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_c, dev_arraySize * sizeof(float));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_tab, dev_arraySize * sizeof(float));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_alpha, sizeof(float));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}
	// Copy input vectors from host memory to GPU buffers.

	/*

cudaError_t cudaMemcpy	(	void * 	dst,
const void * 	src,
size_t 	count,
enum cudaMemcpyKind 	kind
)

	*/
	/*
	cudaStatus = cudaMemcpy(dev_c, c, arraySize * sizeof(float), cudaMemcpyHostToDevice);		//nie wiem czy �adowanie warto�ci poprzedniego elementu tablicy C ma sens
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}
	*/
	cudaStatus = cudaMemcpy(dev_tab, tab, *arraySize * sizeof(float), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_alpha, alpha, sizeof(float), cudaMemcpyHostToDevice);		//(void**)&dev_alpha  ????
	//ale alpha to nazwa po stronie hosta
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}




	// Launch a kernel on the GPU with one thread for each element.
	addKernel << <1, 7 >> > (c, tab, alpha);															//   <<<ile blok�w , ile w�tk�w w bloku>>> ?

	// Check for any errors launching the kernel
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
		goto Error;
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(c, dev_c, dev_arraySize * sizeof(int), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

Error:
	cudaFree(dev_c);
	cudaFree(dev_tab);
	cudaFree(dev_alpha);
	//cudaFree(dev_arraySize);
	return cudaStatus;
}
