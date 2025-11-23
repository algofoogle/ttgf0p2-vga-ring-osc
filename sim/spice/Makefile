SRC_RAW ?= full_spice_sim.raw
OUT_PPM ?= ~/HOST_Documents/fss.ppm
PROJECT_NAME ?= tt_um_algofoogle_vgaringosc

cleanmixed: clean mixed render

cleanfull: clean full render

# Parasitic EXtraction:
# Generate a SPICE netlist with PEX from a GDS layout. For example:
#   make pex
# ...expects the GDS to be in the runs/wokwi/final/gds/ directory,
# and writes to: tt_um_algofoogle_vgaringosc.from_gds.sim.spice
pex: ../../runs/wokwi/final/gds/$(PROJECT_NAME).gds
	magic -rcfile magicrc -noconsole -dnull tcl/extract_from_gds_for_sim.tcl $(PROJECT_NAME)
	echo "========= Resulting PEX SPICE netlist: ========="
	ls -al *.sim.spice
	ls -alh *.sim.spice

render:
	python3 ../../xschem/render.py $(SRC_RAW) $(OUT_PPM)
	ls -alh $(OUT_PPM)

full: full_spice_sim.cir
	ngspice $<

clean:
	rm -rf *_obj_dir *~ .*~ *.so inputs.h outputs.h inouts.h
