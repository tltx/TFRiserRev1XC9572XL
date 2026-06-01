# TFRiserRev1XC9572XL

> **Fork notice**: This is Tore Lundqvist's fork of
> [arkadiuszmakarenko/TFRiserRev1XC9572XL](https://github.com/arkadiuszmakarenko/TFRiserRev1XC9572XL).
> Changes here are being submitted upstream as pull requests; this fork
> exists so users can have the changes today. Bug reports about
> behaviour added in this fork belong on this repo, not on upstream.

CPLD logic (Xilinx XC9572XL, Verilog + Xilinx ISE project files) for the
Terrible Fire CD32 Riser, Rev 1. The CPLD acts as the external address
decoder on the Amiga bus, raising an interrupt line on the STM32
whenever the CPU accesses one of the riser's address windows.

Pair with the matching firmware in
[TFRiserRev1F722](https://github.com/tltx/TFRiserRev1F722). A pre-built
`main_top.jed` matching the latest source is included in
[TerribleFireCD32Riser_binaries](https://github.com/tltx/TerribleFireCD32Riser_binaries).

## Build

Open the project in Xilinx ISE 14.7 and synthesise. Output is
`main_top.jed`, ready to flash via JTAG.
