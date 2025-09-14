BOARD ?= au50
RUN   ?= 0
NTHRD ?= 16
PROJ  ?= $(BOARD)_scratchpad

ifeq ($(RUN),0)
    NTHRD := 0
endif

VPRJ_DIR := build/$(PROJ)
VPRJ := $(VPRJ_DIR)/$(PROJ).xpr

default: $(VPRJ)

$(VPRJ):
	@mkdir -p build/$(PROJ)
	vivado -mode batch -nojournal -notrace -log $(VPRJ_DIR)/prj_create.log \
		-source build.tcl -tclargs --board $(BOARD) --prjname $(PROJ) --runjobs $(NTHRD)

.PHONY: default
