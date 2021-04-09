# RISC-V Extension Interface

The RISC-V extension interface provides a generalized framework suitable to implement custom co-processors and ISA extensions for existing RISC-V CPU cores.
It features independent channels for accelerator-agnostic offloading of instructions and writeback of the result, pseudo dual-issue behaviour and configurable sharing granularity of external functional units.
A more thourough documentation can be found in the [doc](doc/index.md) folder.

## List of Modules

| Name               | Description                                                                 | Status        |
| ----               | -----------                                                                 | ------        |
| `acc_intf`         | Systemverilog interface definition of the `X/C-` and `XMem/CMem-Interface`. | active (v0.1) |
| `acc_interconnect` | Instruction offload and response interconnect.                              | active (v0.1) |
| `acc_adapter`      | Accelerator-agnostic offloading adapter.                                    | active (v0.1) |
| `acc_predecoder`   | Accelerator-specific instruction predecoder.                                | active (v0.1) |
