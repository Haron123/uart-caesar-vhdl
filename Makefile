all:
  # analyze vhdl
	make analyze
	
  # Synthesize
	yosys -m ghdl -p 'ghdl --std=08 -frelaxed caesar_top; synth_ice40 -json synth.json'

  # P&R
	nextpnr-ice40 --package hx1k --pcf constraint.pcf --asc result.asc --json synth.json --pcf-allow-unconstrained

  # Generate Bitstream
	icepack result.asc result.bin

analyze:
	ghdl -a --std=08 -frelaxed sources/caesar_tb.vhd sources/BRAM.vhd sources/uart.vhd sources/fsm.vhd sources/caesar_top.vhd sources/datapath.vhd

# Programm the chip
burn:
	iceprog result.bin
	make clean

clean:
	rm -rf result.asc result.bin synth.json *.o *.cf

elaborate:
	ghdl -e --std=08 -frelaxed caesar_tb

run:
	ghdl -r --std=08 -frelaxed caesar_tb --wave=waveform.ghw --vcd=waveform.vcd

sim:
	make analyze
	make elaborate
	make run
	make clean