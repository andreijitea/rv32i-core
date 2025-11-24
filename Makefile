# Verilog source files
SRC_DIR = src
SIM_DIR = sim
SRC_FILES = $(SRC_DIR)/cpu.v \
			$(SRC_DIR)/program_counter.v \
			$(SRC_DIR)/instruction_memory.v \
			$(SRC_DIR)/register_file.v \
			$(SRC_DIR)/extender.v \
			$(SRC_DIR)/alu.v \
			$(SRC_DIR)/data_memory.v \
			$(SRC_DIR)/controller.v \
			$(SRC_DIR)/adder.v \
			$(SRC_DIR)/mux2.v \
			$(SRC_DIR)/mux4.v \
			$(SRC_DIR)/memory_controller.v

TB_FILE = $(SIM_DIR)/cpu_tb.v
OUT = $(SIM_DIR)/cpu_tb

# Default target
all: simulate

# Compile and simulate
simulate: $(SRC_FILES) $(TB_FILE)
	iverilog -g2012 -o $(OUT) $(SRC_FILES) $(TB_FILE) -I$(SRC_DIR)
	cd $(SIM_DIR) && vvp cpu_tb

# Clean
clean:
	rm -f $(OUT)

.PHONY: all simulate clean