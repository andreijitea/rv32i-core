# Verilog source files
SRC_DIR = src
SIM_DIR = sim
TOP_MODULE = soc_multicycle

SRC_FILES = $(SRC_DIR)/soc_multicycle.v \
			$(SRC_DIR)/cpu_multicycle.v \
			$(SRC_DIR)/program_counter.v \
			$(SRC_DIR)/instruction_reg.v \
			$(SRC_DIR)/imem_sync.v \
			$(SRC_DIR)/dmem_sync.v \
			$(SRC_DIR)/register_file.v \
			$(SRC_DIR)/extender.v \
			$(SRC_DIR)/alu.v \
			$(SRC_DIR)/data_reg.v \
			$(SRC_DIR)/reg32b.v \
			$(SRC_DIR)/controller_multicycle.v \
			$(SRC_DIR)/adder.v \
			$(SRC_DIR)/mux2.v \
			$(SRC_DIR)/mux4.v

TB_CPP = $(SIM_DIR)/soc_tb.cpp
OBJ_DIR = $(SIM_DIR)/obj_dir
VCD = $(SIM_DIR)/soc_tb.vcd

# Absolute paths
SRCS_ABS := $(abspath $(SRC_FILES))
TB_ABS   := $(abspath $(TB_CPP))

# Default target
all: simulate

# Verilate and build
$(OBJ_DIR)/V$(TOP_MODULE): $(SRC_FILES) $(TB_CPP)
	verilator --cc --exe --build -j $(shell nproc) \
		--top-module $(TOP_MODULE) \
		--Mdir $(OBJ_DIR) \
		--trace \
		-I$(abspath $(SRC_DIR)) \
		$(SRCS_ABS) $(TB_ABS)

# Compile and simulate
simulate: $(OBJ_DIR)/V$(TOP_MODULE)
	cd $(SIM_DIR) && ./obj_dir/V$(TOP_MODULE)

# Open waveform viewer (requires GTKWave)
wave: $(VCD)
	gtkwave $(VCD) &

# Clean
clean:
	rm -rf $(OBJ_DIR) $(VCD)

.PHONY: all simulate wave clean