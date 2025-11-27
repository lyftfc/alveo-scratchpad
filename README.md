Alveo Scratchpad
================

Minimal boilerplate for e.g. timing closure validation on Xilinx/AMD Alveo FPGA cards.

------

This repository contains scripts for generating a minimal project targetting Xilinx/AMD
Alveo series FPGA cards, that is synthesizable and implementable.

The primary goal of this is to serve as a scratchpad for rapid iteration of timing closure
work on a user HDL/IP design block.
While the user design block cannot be synthesized onto an FPGA target standalone, this
project uses a CMAC core (free license available) to provide a pair of 512-bit AXI
Stream interfaces.
These interfaces are CDC'ed to an user-adjustable clock domain.
Connecting user design to this pair of interface avoids any necessary logic in the provided
user design to be optimized out, as the CMAC IP core bridges them to the network port.

This shell trades workflow time with functionality.
We chose the CMAC IP core as it (after trimming in IP configuration) is small, and running
at a high clock frequency.
Other IPs such as DMA and DDRs are not included due to their size.

Tested on Vivado versions 2021 to 2023.

Usage
-----

In the repo directory, do

```bash
make PROJ=<your-project-name>
```

Requires the desired version of Vivado available in PATH.

A template project will be generated under `build/<your-project-name>/`.
Open the project and add your own sources/IPs in the block design.

Features
--------

* Shell itself is lightweight and can be rapidly synth/implemented. On a modern computer:
    - Project creation: ~2 minutes
    - Synth/Implementation: less than 10 mins
* Provided in the form of block design so user design block can be added via Vivado GUI
* CMAC cores and AXI-Stream facilities easily reaches > 300 MHz so not bottlenecking timing
* 512b Tx/Rx signals can wire to user logic without width extension, avoiding unwanted optimization

Limitations
-----------

While the implemented design of the bare project passes DRC for bitstream generation, it is
*NOT designed to be functional* on a real FPGA using the network interface, as the CMAC IP
setup logic is omitted.
It worths noting that, without generating a bitstream, the CMAC free license may not be necessary.
