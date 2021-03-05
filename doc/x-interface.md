# Offloading Interface (X-Interface)
The X-Interface implements accelerator-agnostic instruction offloading and translation to the accelerator interconnect C-Interface.

## Interface Definition
The X-Interface features two independent decoupled channels for offloading requests and accelerator writeback.

### Parameterization
The interface is parameterized using the following parameter

| Name               | Type / Range        | Description                                      |
| ------------------ | ------------------- | ------------------------------------------------ |
| `DataWidth`        | `int` (32, 64, 128) | ISA Bit-width                                    |

### Request Channel

The request channel signals are:
| Signal Name    | Range                      | Direction      | Description                                                 |
| -------------  | -------------------------- | ---------      | -----------------------------------                         |
| `q_instr_data` | `31:0`                     | Core > Adapter | Instruction data (ID stage)                                 |
| `q_rs1`        | `DataWidth-1:0`            | Core > Adapter | Source register contents (rs1)                              |
| `q_rs2`        | `DataWidth-1:0`            | Core > Adapter | Source register contents (rs2)                              |
| `q_rs3`        | `DataWidth-1:0`            | Core > Adapter | Source register contents (rs3)                              |
| `q_rs_valid`   | `2:0`                      | Core > Adapter | Source register valid indicator                             |
| `q_rd_clean` | `1:0`                        | Core > Adapter | Scoreboard status of destination register. (NEW) |
| `k_accept`     | `0:0`                      | Adapter > Core | Offload request acceptance indicator.                       |
| `k_writeback`  | `1:0`                      | Adapter > Core | Mark outstanding accelerator writeback to`rd` (and `rd+1`). |

Additionally, the handshake signals `q_ready` and `q_valid` are implemented.

#### Request Transaction
The instruction offloading process takes place according to the following scheme:
- The offloading core asserts `q_valid` upon encountering an unknown instruction in the instruction decode stage, initiating a transaction.
- Once `q_valid` has been asserted, `q_instr_data` must remain stable.
- The signals `q_rs_valid[i]` indicate the status of the source registers `q_rs[i]`.
  `q_rs_valid[i]` may initially be 0 and change to 1 during the transaction.
  While `q_rs_valid[i]` is low, `q_rs[i]` may change.
  Once `q_valid` and `q_rs_valid[i]` have been asserted, `q_rs_valid[i]` and `q_rs[i]` must remain stable.
- `q_rd_clean` indicates the scoreboard entry of the destination register.
  It may initially be 0 and change to 1 during the transaction.
  Once `q_rd_clean` is asserted, it must remain stable.
- The accelerator adapter asserts `q_ready`, if
    - The instruction is accepted by any of the connected predecoders, the required source registers are marked valid by the offloading core and the destination register is clean (if writeback is expected).
      The adapter asserts `k_accept` and `k_writeback` accordingly.
    - The instruction is not accepted by any of the connected predecoders.
      The adapter de-asserts `k_accept` and `k_writeback` to indicate an illegal instruction has been encountered.
- When both `q_valid` and `q_ready` are high, the transaction is successful

### Response channel
The response channel signals are:

| Signal Name   | Range                   | Description                          |
| ------------- | ----------------------- | ------------------------------------ |
| `p_rd`        | `4:0`                   | Destination Register Address         |
| `p_data0`     | `DataWidth-1:0`         | Primary Writeback Data               |
| `p_data1`     | `DataWidth-1:0`         | Secondary Writeback Data             |
| `p_dualwb`    | `0:0`                   | Dual-Writeback Response              |
| `p_error`     | `0:0`                   | Error Flag                           |

Additionally, the handshake signals `q_ready` and `q_valid` are implemented.

Notes:
  - `p_data0` and `p_data1` carry the response data resulting from offloaded instructions.
    `p_data0` carries the default write-back data and is written to the destination register identified by `p_rd_id`.
    `p_data1` is used only for dual-writeback instructions.
  - Dual write-back instructions are marked by the accelerator sub-system by setting `p_dualwb`.
  - The error flag included in the response channel indicates processing errors encountered by the accelerator.
    The actions to be taken by a core to recover from accelerator errors are not yet defined.

#### Response Transaction
The response channel is handshaked according to the following scheme:
- The initiator asserts `p_valid`. The assertion of `p_valid` must not depend on `p_ready`. The assertion of ready may depend on `p_valid`.
- Once `p_valid` has been asserted all data must remain stable.
- The receiver asserts `p_ready` whenever it is ready to receive the transaction. Asserting `p_ready` by default is allowed. While `p_valid` is low, `p_ready` may be retracted at any time.
- When both `p_valid` and `p_ready` are high the transaction is successful.

## Operand Origin
The operands forwarded to the accelerator interconnect are determined in the same way as any regular RISC-V instructions.
Any source registers from the integer register file of the offloading core as defined in the [RISC-V User-Level ISA specification](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf#page=24) are allowed.
If source registers are used, operand A, B and C contain `rs1`, `rs2` and `rs3` respectively.
For ternary instructions, the instruction format R4-type instruction format is to be used, defining the `rs3` register address by bits `instr_data[31:27]`.

## Write-back Destination
The default writeback destination for offloaded instruction is the RISC-V destination register specified by `instr_data[11:7]`.

## Dual-Writeback Instructions
Custom ISA extensions may mandate dual register writebacks.
In order to accomodate that need we provision the possibility to reserve multiple destination registers for a single offloaded instruction.
For even destination registers other than `X0`,  `Xn` and `Xn+1` are reserved for write-back upon offloading a dual write-back instruction, where `Xn` denotes the destination register addresss extracted from `instr_data[11:7]`.

For responses resulting from dual-writeback instructions, the accelerator asserts `p_dualwb`.
Upon accepting the accelerator response, the offloading core writes back data contained in `p_data0` to register `p_id[4:0]`.
`p_data1` is written back to `p_id[4:0]` + 1.


In order to maximize benefits from dual-writeback instructions, the interconnect response path must accomodate simultaneous transfer of two operation results (`p_data0` and `p_data1`).
If none of the connected accelerators implement dual write-back instructions, the according signal paths will be removed by synthesis tools.

In order to support accelerators implementing dual write-back instructions, the offloading core must include provisions to reserve two destination registers upon offloading an instruction.
Also, the core should include provisions for simultaneous writeback, implying dual write-ports to the internal register file.

## Write-after-Write Hazards (NEW)
The accelerator interconnect does not provide any guarantees regarding response ordering of offloaded instructions.
To prevent potential write-after-write hazards upon multiple offloaded instructions of different latencies targeting the same destination register, the accelerator adapter must wait for the destination register's scoreboard entry to be clean.


