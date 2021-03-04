# RISC-V Extension Interface

The RISC-V extension interface provides a generalized framework suitable to implement custom co-processors and ISA extensions for existing RISC-V CPU cores.
It features independent channels for accelerator-agnostic offloading of instructions and write-back of the result, pseudo dual-issue behaviour and configurable sharing granularity of external functional units.
A more thourough documentation can be found in the [doc](doc/index.md) folder.

## List of Modules

| Name               | Description                                                        | Status         |
| ------------------ | ------------------------------------------------------------------ | ----------------- |
| `acc_intf`         | Systemverilog interface definition of the `X-` and `C-Interface`.  | in development |
| `acc_interconnect` | Instruction offload and response interconnect.                     | in development |
| `acc_adapter`      | Accelerator-agnostic offloading adapter.                           | in development |
| `acc_predecoder`   | Accelerator-specific instruction predecoder.                       | in development |
