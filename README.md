# Getting Started

This example utilize the following toolsets:
* Multi Instance GPUs (Ampere+) [User Guide](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html)
* NVIDIA Management Library (NVML) [User Guide](https://docs.nvidia.com/deploy/nvml-api/index.html)

## Description
The purpose of this example is to provide a better understanding of how to launch applications to MIG instance using a bash script.

## Files
1. `single_mig.sh`
- This script creates a single slice from each MIG mode (i.e. 0, 5, 9, 14, 19)

2. `multi_mig.sh`
- This script creates maximum number of slice for MIG modes with number of slices greater than 1 (i.e. 9, 14, 19)

3. `mig.cu`
- This file extract MIG information using the NVML API.

## Usage
```bash
bash single_mig.sh 0 300
```
or
```bash
bash multi_mig.sh 0 300
```

### Arguments
1. Argument (1) is the device ID which to launch the bash script and executable
2. Argument (2) is the desired power limit of the device

### Other Notes
1. Max clock rates for A100 are set with the following, where `${GID}` is the device ID.
```bash
sudo nvidia-smi -ac 1215,1410 -i ${GID}
```

2. NVIDIA-SMI is queried to monitor device metrics and stored in the background
```bash
nvidia-smi -i ${GID} --query-gpu=timestamp,gpu_name,uuid,persistence_mode,pstate,temperature.gpu,temperature.memory,utilization.gpu,utilization.memory,clocks_throttle_reasons.gpu_idle,clocks_throttle_reasons.sw_power_cap,clocks_throttle_reasons.hw_slowdown,clocks_throttle_reasons.hw_thermal_slowdown,clocks_throttle_reasons.hw_power_brake_slowdown,clocks_throttle_reasons.sw_thermal_slowdown,clocks_throttle_reasons.sync_boost,memory.total,memory.free,memory.used,power.draw,power.limit,clocks.current.graphics,clocks.current.sm,clocks.current.memory,clocks.max.graphics,clocks.max.sm,clocks.max.memory,mig.mode.current --format=csv -f metrics_multi_${POWER}.csv --loop-ms=100 &
```

3. The executable is launched serially to allow for better stdout readibility.
```bash
CUDA_VISIBLE_DEVICES=${MIG_ID}/${j}/0 ./mig_example ${MIG_MODE[${m}]} ${COUNT} ${MIG_ID}/${j}/0
```
This call can be launched in background using `&`, but care must be taken to wait for all child processes to finish.

Replace
```bash
PIDS=()
	for i in "${GI_IDS[${m}]}"
	do
		declare COUNT=(0)
		ID=(`echo $i | sed 's/,/\n/g'`)
		for j in "${ID[@]}"
		do
			CUDA_VISIBLE_DEVICES=${MIG_ID}/${j}/0 ./mig_example ${MIG_MODE[${m}]} ${COUNT} ${MIG_ID}/${j}/0
			((COUNT=COUNT+1))
		done
	done
```
with
```bash
PIDS=()
	for i in "${GI_IDS[${m}]}"
	do
		declare COUNT=(0)
		ID=(`echo $i | sed 's/,/\n/g'`)
		for j in "${ID[@]}"
		do
			CUDA_VISIBLE_DEVICES=${MIG_ID}/${j}/0 ./mig_example ${MIG_MODE[${m}]} ${COUNT} ${MIG_ID}/${j}/0 &
      PIDS+=" $!"
			((COUNT=COUNT+1))
		done
	done
  wait ${PIDS}
```
