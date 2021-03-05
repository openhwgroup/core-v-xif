# Accelerator Predecoder Module Specification
The accelerator predecoder module implements the actual identification of offloadable instructions for a specific connected accelerator unit.

## Context
The accelerator predecoders are instantiated in a flat array of modules to the accelerator adapter.
The first `NumRsp[0]` predecoders correspond to the accelerator units in the accelerator interconnect hierarchy 0.
Predecoders `NumRsp[0]+1 ... NumRsp[1]` correspond to the accelerator units in the hierarchy level 1 [...].
The connection order of the accelerator units to the accelerator interconnect in each level must correspond to the the connection order of the predecoders to the adapter module.

![Accelerator Adapter Detail](img/acc-adapter-detail.svg)

## Interface

The accelerator predecoder modules contain entirely combinational logic to identify all data needed for the offloading core to correctly offload an instruction.
The accelerator predecoder signals are:


### Request Channel
| Signal Name    | Range  | Direction            | Description                          |
| -------------  | ------ | ----------           | ------------------------------------ |
| `q_instr_data` | `31:0` | Adapter > Predecoder | RISC-V Instruction Data.             |

### Response Channel
The response channel signals are summarized in the systemverilog struct `prd_rsp_t`.

| Signal Name   | Range  | Direction            | Description                                                                       |
| ------------- | ------ | ----------           | ------------------------------------                                              |
| `p_accept`    | `0:0`  | Predecoder > Adapter | The accelerator represented by this predecoder can process the instruction        |
| `p_use_rs`    | `2:0`  | Predecoder > Adapter | Asserting `p_use_rs[i]` implies the instruction requires source register `rs{i}`. |
| `p_writeback` | `1:0`  | Predecoder > Adapter | The instruction mandates writeback / dual-writeback.                              |

## Parameterization
To support decoding arbitrary offload instructions, the following systemverilog struct `offl_instr_t` is defined.
| Signal name | Range / Type | Description |
| `instr_data` | `logic[31:0]` | Instruction data matching the offloaded instruction |
| `instr_mask` | `logic[31:0]` | Bitmask, masking off decode-irrelevant bits of the instruction data|
| `prd_rsp`    | `prd_rsp_t`   | Predefined predecoder response |

The accelerator predecoder module is parameterized as follows:
| Name                  | Type / Range             | Description                              |
| ------------------    | -----------              | ---------------------------------------- |
| `NumInstr`            | `int` (>=1)              | Total number of offloadable instructions |
| `OfflInstr[NumInstr]` | `offl_instr_t[NumInstr]` | Offload instruction metadata             |





