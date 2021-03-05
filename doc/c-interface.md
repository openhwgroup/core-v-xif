# Accelerator Interconnect Interface (C-Interface)
The C-Interface implements signal routing from and to the accelerator units.

## Interface Definition

The C-Interface features two independent decoupled channels for offloading requests and accelerator write-back.
The request and response channels are handshaked according to the following scheme:
- The initiator asserts `valid`. The assertion of `valid` must not depend on `ready`. The assertion of ready may depend on `valid`.
- Once `valid` has been asserted all data must remain stable.
- The receiver asserts `ready` whenever it is ready to receive the transaction. Asserting `ready` by default is allowed. While `valid` is low, `ready` may be retracted at any time.
- When both `valid` and `ready` are high the transaction is successful.

### Interface parameters
The interface is parameterized using the following set of parameters.

| Name               | Type / Range        | Description                                      |
| ------------------ | ------------------- | ------------------------------------------------ |
| `NumReq`           | `int` (>=1)         | Number of requesting entities                    |
| `TotNumRsp`           | `int` (>=1)         | Total Number of responding entities                    |
| `NumHier`          | `int` (>=1)         | Number of hierarchical interconnect levels       |
| `DataWidth`        | `int` (32, 64, 128) | ISA Bit-width                                    |

#### Derived Parameters
The expression `idx(num_idx)` is denotes the index width required to represent up to `num_idx` indices as a binary encoded signal.
```
idx(num_idx) = (num_idx > 1) ? $clog2(num_idx) : 1;
```

| Name               | Value                          | Description                                         |
| ------------------ | ------------------------------ | --------------------------------------------------- |
| `HierAddrWidth`    | `idx(NumHier)`                 | Hierarchy level address width                       |
| `AccAddrWidth`     | `idx(NumRsp)`                  | Accelerator address width            |
| `AddrWidth`        | `HierAddrWidth + AccAddrWidth` | Overall address width                               |
| `ExtIdWidth`       | `idx(NumReq) + 1`              | ID Tag width at accelerator-end of the interconnect |

### Request Channel (`q`)
An offload request comprises the entire 32-bit RISC-V instruction three operands and a request ID tag specifying requesting entity.
The nature of the offloaded instructions is not of importance to the accelerator interconnect.
The request channel interface signals are:

| Signal Name   | Range                      | Description                                     |
| ------------- | -------------------------- | ----------------------------------------------- |
| `q_addr`      | `AddrWidth-1:AccAddrWidth` | Accelerator hierarchy level.                    |
|               | `AccAddrWidth-1:0`         | Accelerator address.                            |
| `q_id`        | `ExtIdWidth-1:1`           | Requester ID                                    |
|               | `0:0`                      | `1'b0`                                           |
| `q_data_op`   | `31:0`                     | RISC-V instruction data                         |
| `q_data_arga` | `DataWidth`                | Operand A (source register `rs1`)               |
| `q_data_argb` | `DataWidth`                | Operand B (source register `rs2`)               |
| `q_data_argc` | `DataWidth`                | Operand C (source register `rs3`)               |

Notes:
  - The accelerator address `q_addr` is partitioned into the MSB Range identifying the interconnect hierarchy level of the target accelerator and the LSB Range denoting the accelerator address within a given hierarchy level.
  - The `q_id` signal uniquely identifies the response target of any request.
    On the core-private level, the signal is assigned a single bit constantly tied to zero.
    During traversal of the accelerator interconnect, the signal is extended with an additional `idx(NumReq)` bits at the MSB end, to identify the originating port.
    The width of the signal at the offloading master port of the interconnect is 1 bit.
    The width at the accelerator request output port of the interconnect is `ExtIdWidth` bits.
    The least significant bit of the `q_id` signal is constantly tied to 0.
    `NumReq` denotes the number of requesting entities in the target interconnect hierarchy level.
    The signal is latched by the accelerator subsystem and used for eventual route-back of the instruction write-back data.

### Response Channel (`p`)
*Not* every operation which was offloaded must ultimately return a response.
If a response is returned, the response channel carries the following signals:

| Signal Name   | Range                   | Description                          |
| ------------- | ----------------------- | ------------------------------------ |
| `p_id`        | `0:0 / ExtIdWidth-1:0`  | Requester ID                         |
| `p_rd`        | `4:0`                   | Destination Register Address         |
| `p_data0`     | `DataWidth-1:0`         | Primary Writeback Data               |
| `p_data1`     | `DataWidth-1:0`         | Secondary Writeback Data             |
| `p_dualwb`    | `0:0`                   | Dual-Writeback Response              |
| `p_error`     | `0:0`                   | Error Flag                           |

Notes:
  - `p_data0` and `p_data1` carry the response data resulting from offloaded instructions.
    `p_data0` carries the default write-back data and is written to the destination register identified by `p_rd_id`.
    `p_data1` is used only for dual-writeback instructions.
  - The `p_id` signal identifies the target core for writeback of an offloaded instruction.
    The width of the signal at the responding accelerator interconnect input is `ExtWidth`.
    The width of the signal at the target core is 1 bit.
    The least significant bit of the `p_id` signal is constantly tied to 0.
  - Dual write-back instructions are marked by the accelerator sub-system by setting `p_dualwb`.
  - The error flag included in the response channel indicates processing errors encountered by the accelerator.
    The actions to be taken by a core to recover from accelerator errors are not yet fully defined.

## Master/Slave Interface ports
A C-interface master port is defined to source C-request signals and sink C-response signals
A C-interface slave port is defined to sink C-request signals and source C-response signals.

### Variation of the ID Field Width
The requester ID field (`{p/q}_id`)  is generated by the accelerator interconnect module during routing of a request packet from the offloading core to the addressed accelerator unit.
At the offloading accelerator adapter's C-interface master port, the ID field is of width 1 bit and constantly assigned to `1'b0`.
At the C-interface slave port of the accelerator interconnect facing the connected accelerator units, the Id field has width `ExtIdWidth = idx(NumReq) + 1`.


