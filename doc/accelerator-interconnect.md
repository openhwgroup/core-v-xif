# Accelerator Interconnect Module Specification
The [accelerator interconnect module](../src/acc_interconnect.sv) implements signal routing from the offloading accelerator adapter to connected accelerator units on the corresponding interconnect level and forwards requests to higher levels in the hierarchy.

## Parameterization
The accelerator interconnect module is parameterized as follows.
The expression `idx(num_idx)` is denotes the index width required to represent up to `num_idx` indices as a binary encoded signal.
```
idx(num_idx) = (num_idx > 1) ? $clog2(num_idx) : 1;
```

| Name               | Type / Range        | Description                                           |
| ------------------ | ------------------- | ------------------------------------------------      |
| `DataWidth`        | `int` (32, 64, 128) | ISA Bit-width                                         |
| `HierLevel`        | `int` (>=0)         | Hierarchy level                                       |
| `HierAddrWidth`    | `int` (>=1)         | Hierarchy address portion                             |
| `AccAddrWidth`     | `int` (>=1)         | Level-specific accelerator address portion            |
| `NumReq`           | `int` (>=1)         | Number of requesting entities                         |
| `NumRsp`           | `int` (>=1)         | Number of responding entities on this hierarchy level |
| `RegisterReq`      | `int` (0,1)         | Instert pipeline register into request path           |
| `RegisterRsp`      | `int` (0,1)         | Instert pipeline register into response path          |

## Port Map
The accelerator interconnect module features the following [C-interface](c-interface.md) ports:

| Port Name          | Component       | Description                                                               |
| ---------          | ---------       | -----------                                                               |
| `acc_c_slv[NumReq]`      | `acc_c_slv_req_i` | Request channel input from accelerator adapter / lower-level interconnect |
|                    | `acc_c_slv_rsp_o` | Response channel output to accelerator adapter / lower level interconnect |
| `acc_c_mst_next[NumReq]` | `acc_c_mst_req_o` | Request channel output to higher-level interconnect                       |
|                    | `acc_c_mst_rsp_i` | Response channel input from higher level interconnect                     |
| `acc_c_mst[NumRsp]`      | `acc_c_mst_req_o` | Request channel to directly connected accelerators                  |
|                    | `acc_c_mst_rsp_i` | Response channel from directly connected accelerators               |


