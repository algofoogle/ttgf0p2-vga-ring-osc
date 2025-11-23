# This borrows from extract_for_sim.tcl to generate an extraction from a .gds source rather than .mag file.
# It is expected this will be called by mag/Makefile, which will change to the ../gds/
# directory, but write the resulting SPICE to ../sim/spice/
set project [lindex $argv $argc-1]
gds read ../../runs/wokwi/final/gds/$project.gds
flatten tt_um_flat
load tt_um_flat
select top cell
cellname delete $project
cellname rename tt_um_flat ${project}_parax
extract all
ext2sim labels on
ext2sim
# extresist simplify on
# extresist lumped on
# extresist tolerance 0.05 ; # 1 is default. <1 means fewer resistors. >1 means more.
# extresist tolerance 0.001 ; # 1 is default. <1 means fewer resistors. >1 means more.
extresist tolerance 10
extresist
ext2spice lvs
# ext2spice cthresh 0.01 ; # Ignore caps below 1e-17 (normally 0, all caps are extracted)
ext2spice cthresh 0.001 ; # Ignore caps below this many fF
# ext2spice rthresh 5
# ext2spice merge aggressive
# ext2spice short resistor
ext2spice extresist on
ext2spice -o $project.from_gds.sim.spice
quit -noprompt
