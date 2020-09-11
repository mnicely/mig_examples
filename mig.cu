// Redistribution and use in source and binary forms, with or without modification, are permitted
// provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright notice, this list of
//       conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright notice, this list of
//       conditions and the following disclaimer in the documentation and/or other materials
//       provided with the distribution.
//     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
//       to endorse or promote products derived from this software without specific prior written
//       permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include <iostream>
#include <map>
#include <stdexcept>
#include <string>

#include <nvml.h>

const int max_slices = 7;

std::map<unsigned int, unsigned int> id_slice = {
    { 0, 4 },
    { 5, 3 },
    { 9, 2 },
    { 14, 1 },
    { 19, 0 }
};

template<typename T>
void check( T const &err_code, std::string const &file, int const &line ) {
    if ( err_code ) {
        cudaDeviceReset( );
        std::string str = nvmlErrorString( err_code );
        throw std::runtime_error( str + " in " + file + " at line " +
                                  std::to_string( line ) );
    }
}

#define checkNVMLErrors( errCode ) check( errCode, __FILE__, __LINE__ )

int main( int argc, char **argv ) {

	unsigned int mig_mode { static_cast<unsigned int>(std::stoi(argv[1])) };
	unsigned int count { static_cast<unsigned int>(std::stoi(argv[2])) };

	// Initialize NVML library
	checkNVMLErrors( nvmlInit( ) );

	// Query device handle
	nvmlDevice_t       device_ {};
	checkNVMLErrors( nvmlDeviceGetHandleByIndex( 0, &device_ ) );

	// Query device name
	char name[NVML_DEVICE_NAME_BUFFER_SIZE];
	checkNVMLErrors( nvmlDeviceGetName( device_, name, NVML_DEVICE_NAME_BUFFER_SIZE ) );

	// Query compute capability
	int major {};
	int minor {};
	checkNVMLErrors( nvmlDeviceGetCudaComputeCapability( device_, &major, &minor ) );

	// Query MIG mode
	unsigned int currentMode {};
	unsigned int pendingMode {};
	checkNVMLErrors( nvmlDeviceGetMigMode( device_, &currentMode, &pendingMode ) );

	// Query GPU Instances used
	nvmlGpuInstanceProfileInfo_t gid_profile {};
	checkNVMLErrors( nvmlDeviceGetGpuInstanceProfileInfo( device_, id_slice.at(mig_mode), &gid_profile ) );

	// Query GPU Instances used
	nvmlGpuInstance_t gids[max_slices];
	unsigned int g_used {};
	checkNVMLErrors( nvmlDeviceGetGpuInstances( device_, gid_profile.id, gids, &g_used ) );

	// Query GPU Instance Info
	nvmlGpuInstanceInfo_t gid_info {};
	checkNVMLErrors( nvmlGpuInstanceGetInfo( gids[count], &gid_info ) );

	// Query remaining capacity
	unsigned int g_avail {};
	checkNVMLErrors( nvmlDeviceGetGpuInstanceRemainingCapacity( device_, gid_profile.id, &g_avail ) );

	// Get Compute Instance Info
	nvmlComputeInstanceProfileInfo_t cid_profile {};
	checkNVMLErrors( nvmlGpuInstanceGetComputeInstanceProfileInfo( gids[count], id_slice.at(mig_mode), 0, &cid_profile) );

	// Query Compute Instances used
	nvmlComputeInstance_t cids {};
	unsigned int c_used {};
	checkNVMLErrors( nvmlGpuInstanceGetComputeInstances( gids[count], cid_profile.id, &cids, &c_used ) );

	// Query Compute Info
	nvmlComputeInstanceInfo_t cid_info {};
	checkNVMLErrors( nvmlComputeInstanceGetInfo( cids, &cid_info ) );

	// Query remaining capacity
	unsigned int c_avail {};
	checkNVMLErrors( nvmlGpuInstanceGetComputeInstanceRemainingCapacity( gids[count], 0, &c_avail ) );

	printf("\n");
	printf("Name: %s\n", name);
	printf("Compute Capability: %d%d\n", major, minor);
	printf("MIG Enabled: %s\n", (currentMode ? "True" : "False"));
	printf("GPU Profile Id: %d\n", gid_info.profileId);
	printf("GPU Instance Id: %d\n", gid_info.id);
	printf("GPU Instances Used: %d\n", g_used);
	printf("GPU Instances Avail: %d\n", g_avail);
	printf("Compute Profile Id: %d\n", cid_profile.id);
	printf("Compute Instance Id: %d\n", cid_info.id);
	printf("Compute Instances Used: %d\n", g_used);
	printf("Compute Instances Avail: %d\n", g_avail);
	printf("\n");
	
	// Shutdown NVML
	checkNVMLErrors( nvmlShutdown( ) );

	return ( EXIT_SUCCESS );
}
