# Verilog source files
SRC_DIR = src
SIM_DIR = sim
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

TB_FILE = $(SIM_DIR)/soc_tb.v
OUT = $(SIM_DIR)/soc_tb
VCD = $(SIM_DIR)/soc_tb.vcd

# Default target
all: simulate

# Compile and simulate
simulate: $(SRC_FILES) $(TB_FILE)
	iverilog -g2012 -o $(OUT) $(SRC_FILES) $(TB_FILE) -I$(SRC_DIR)
	cd $(SIM_DIR) && vvp soc_tb

# Open waveform viewer (requires GTKWave)
wave: $(VCD)
	gtkwave $(VCD) &

# Clean
clean:
	rm -f $(OUT) $(VCD)

.PHONY: all simulate wave clean