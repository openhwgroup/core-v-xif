# Accelerator Adapter Module Specification
The [accelerator adapter module](../src/acc_adapter.sv) implements accelerator-agnostic instruction offloading from the CPU core to the accelerator interconnect.
It implements an X-interface slave port for connection with the offloading CPU core, and a C-interface master port to be connected to the accelerator interconnect.
The adapter module operates in conjunction with an array of accelerator-specific [predecoder modules](accelerator-predecoder.md).



## Parameterization
The accelerator adapter module is parameterized as follows

| Name               | Type / Range        | Description                                        |
| ------------------ | ------------------- | ------------------------------------------------   |
| `DataWidth`        | `int` (32, 64, 128) | ISA Bit-width                                      |
| `NumHier`          | `int` (32, 64, 128) | Number of interconnect hierarchy levels            |
| `NumRsp[NumHier]`  | `int[NumHier]`      | Number of responding entities per hierarchy level. |

### Derived Parameters
The expression `idx(num_idx)` is denotes the index width required to represent up to `num_idx` indices as a binary encoded signal.
```
idx(num_idx) = (num_idx > 1) ? $clog2(num_idx) : 1;
```

| Name               | Value                          | Description                                         |
| ------------------ | ------------------------------ | --------------------------------------------------- |
| `TotNumRsp`        | `sum(NumRsp)`                  | Total number of responding entities                 |
| `MaxNumRsp`        | `max(NumRsp)`                  | Maximum number of responding entities per level
| `AccAddrWidth`     | `idx(MaxNumRsp)`               | Accelerator address width                           |
| `HierAddrWidth`    | `idx(NumHier)`                 | Hierarchy level address width                       |
| `AddrWidth`        | `AccAddrWidth + HierAddrWidth` | Overall address width                               |


## Port Map
The accelerator adapter module featuresthe following ports:
| Port Name            | Component         | Description                                                |
| ---------            | ---------         | -----------                                                |
| `acc_x_slv`          | `acc_x_slv_req_i` | X-interface request channel from offloading CPU            |
|                      | `acc_x_slv_rsp_o` | X-interface response channel to offloading CPU             |
| `acc_c_mst`          | `acc_c_mst_req_o` | C-interface request channel to accelerator interconnect    |
|                      | `acc_c_mst_rsp_i` | C-interface response channel from accelerator interconnect |
| `acc_prd[NumRspTot]` | `acc_prd_req_o`   | Predecoder request channel                                 |
|                      | `acc_prd_rsp_o`   | Predecoder response channel                                |


