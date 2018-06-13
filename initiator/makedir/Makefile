compile_sv:
	cd ../bin && echo ${PWD} "<COMPLE_SV PLACEHOLDER ${SHUNT_HOME}/utils/dpi/src/shunt_dpi_pkg.sv ../src/Initiator.sv>"
compile_verilator_sv:
	cd ../bin && ${VERILATOR}  -Wall  --trace  -I../../rtl  -I../../include $(SHUNT_VERILATOR_FLAGS)  -f ../../include/$(MANIFEST_INC) -f ../../rtl/top.f +define+initiator --exe ../../makedir/sim_main.cpp
	cd ../bin && make -C obj_dir -j -f Vshunt_verilator_dpi.mk Vshunt_verilator_dpi
.PHONY: clean
clean:	
	cd ../bin && rm -rf *
all: compile_sv
