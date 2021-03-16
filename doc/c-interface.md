# Accelerator Interconnect Interface (C-Interface)
The C-Interface implements signal routing from and to the accelerator units.

## Interface Definition

The C-Interface features two independent decoupled channels for offloading requests and accelerator writeback.
The request and response channels are handshaked according to the following scheme (AXI-style):
- The initiator asserts `valid`. The assertion of `valid` must not depend on `ready`. The assertion of ready may depend on `valid`.
- Once `valid` has been asserted all data must remain stable.
- The receiver asserts `ready` whenever it is ready to receive the transaction. Asserting `ready` by default is allowed. While `valid` is low, `ready` may be retracted at any time.
- When both `valid` and `ready` are high the transaction is successful.

### Interface Parameters
The interface is parameterized using the following set of parameters.

| Name              | Type / Range        | Description                                        |
| ----              | ------------        | -----------                                        |
| `DataWidth`       | `int` (32, 64, 128) | ISA Bit-width                                      |
| `NumReq`          | `int` (>=1)         | Number of requesting entities                      |
| `NumHier`         | `int` (>=1)         | Number of hierarchical interconnect levels         |
| `NumRsp[NumHier]` | `int[NumHier]`      | Number of responding entities per hierarchy level. |
| `DualWriteback`   | `bit`               | Support for dual-writeback instructions            |
| `TernaryOps`      | `bit`               | Support for ternary operations (use `rs3`)         |

#### Derived Parameters
| Name            | Value                          | Description                                               |
| ----            | -----                          | -----------                                               |
| `MaxNumRsp`     | `max(NumRsp)`                  | Maximum number of responding entities per hierarchy level |
| `HierAddrWidth` | `clog2(NumHier)`               | Hierarchy level address width                             |
| `AccAddrWidth`  | `clog2(MaxNumRsp)`             | Accelerator address width                                 |
| `AddrWidth`     | `HierAddrWidth + AccAddrWidth` | Overall address width                                     |
| `NumRs`         | `TernaryOps ? 3 : 2`           | Supported number of source registers                      |
| `NumWb`         | `DualWriteback ? 2 : 1`        | Supported number of simultaneous writebacks               |

### Request Channel (`q`)
An offload request comprises the entire 32-bit RISC-V instruction three operands and a request ID tag specifying requesting entity.
The nature of the offloaded instructions is not of importance to the accelerator interconnect.
The request channel interface signals are:

| Signal Name       | Range                      | Description                  |
| -----------       | -----                      | -----------                  |
| `q_instr_data`    | `31:0`                     | RISC-V instruction data      |
| `q_addr`          | `AddrWidth-1:AccAddrWidth` | Accelerator hierarchy level. |
|                   | `AccAddrWidth-1:0`         | Accelerator address.         |
| `q_hart_id`       | `DataWidth-1:0`            | Hart ID.                     |
| `q_rs[NumRs-1:0]` | `DataWidth`                | Source register contents.    |

Notes:
  - The accelerator address `q_addr` is partitioned into the MSB Range identifying the interconnect hierarchy level of the target accelerator and the LSB Range denoting the accelerator address within a given hierarchy level.
  - The `q_hart_id` signal uniquely identifies the response target of any request.
    The signal is latched by the accelerator subsystem and used for eventual route-back of the instruction writeback data.

### Response Channel (`p`)
*Not* every operation which was offloaded must ultimately return a response.
If a response is returned, the response channel carries the following signals:

| Signal Name       | Range           | Description                                                                    |
| -----------       | -----           | -----------                                                                    |
| `p_hart_id`       | `DataWidth-1:0` | Hart ID                                                                        |
| `p_rd`            | `4:0`           | Destination Register Address                                                   |
| `p_data[NumWb:0]` | `DataWidth-1:0` | Writeback Data for `NumWb` multi-register writeback.                           |
| `p_dualwb`        | `0:0`           | Dual-Writeback Response (constant `1'b0`, if dual-writeback is not supported). |
| `p_error`         | `0:0`           | Error Flag                                                                     |

Notes:
  - The `p_hart_id` signal identifies the target core for writeback of the offloaded instruction.
  - `p_data[NumWb-1:0]` carries the writeback data resulting from offloaded instructions.
    `p_data[0]` carries the default writeback data and is written to the destination regiser identified by `p_rd`.
    If dual-writeback instructions are supported, `p_data[1]` may carry the secondary writeback data written to `p_rd+1`.
    For dual-writeback instructions, `p_rd` must specify an even destination register other than `X0`.
  - Dual writeback instructions are marked by the accelerator sub-system by setting `p_dualwb`.
    If dual-writeback instructions are not supported (`DualWriteback == 0`), `the signal must be constantly tied to 0.
  - The error flag included in the response channel indicates processing errors encountered by the accelerator.
    The actions to be taken by a core to recover from accelerator errors are not yet fully defined.

## Master/Slave Interface Ports
A C-interface master port is defined to source C-request signals and sink C-response signals
A C-interface slave port is defined to sink C-request signals and source C-response signals.
