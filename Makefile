NVCC    :=nvcc --cudart=static -ccbin g++
CFLAGS  :=-O3 -std=c++11
ARCHES  :=-gencode arch=compute_80,code=\"compute_80,sm_80\"
INC_DIR :=
LIB_DIR :=
LIBS    :=-lnvidia-ml

SOURCES := mig_example \

all: $(SOURCES)
.PHONY: all

mig_example: mig.cu
        $(NVCC) $(CFLAGS) $(INC_DIR) $(LIB_DIR) ${ARCHES} $^ -o $@ $(LIBS)
        
clean:
        rm -f $(SOURCES)
