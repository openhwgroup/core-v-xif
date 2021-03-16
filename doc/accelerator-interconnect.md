# Accelerator Interconnect Module Specification
The [accelerator interconnect module](../src/acc_interconnect.sv) implements signal routing from the offloading accelerator adapter to connected accelerator units on the corresponding interconnect level and forwards requests to higher levels in the hierarchy.

## Module Variations
- The module `acc_interconnect_intf` features port connections using the SystemVerilog `ACC_C_BUS` interface defined [here](../src/acc_intf.sv).
- The module `acc_interconnect` features port connections using packed structs typedefs for request and response channels.


## Parameterization
The accelerator interconnect module (`acc_interconnect`) is parameterized as follows.

| Name            | Type / Range        | Description                                           |
| ----            | ------------        | -----------                                           |
| `DataWidth`     | `int` (32, 64, 128) | ISA bit-width                                         |
| `HierLevel`     | `int` (>=0)         | Hierarchy level                                       |
| `HierAddrWidth` | `int` (>=1)         | Hierarchy address portion                             |
| `AccAddrWidth`  | `int` (>=1)         | Level-specific accelerator address portion            |
| `NumReq`        | `int` (>=1)         | Number of requesting entities                         |
| `NumRsp`        | `int` (>=1)         | Number of responding entities on this hierarchy level |
| `RegisterReq`   | `bit`               | Instert pipeline register into request path           |
| `RegisterRsp`   | `bit`               | Instert pipeline register into response path          |

- The `acc_interconnect_intf` module variation additionally requires the following parameters for internal definition of the request/response structs:
  | Name            | Type  | Description                                |
  | ----            | ----  | -----------                                |
  | `DualWriteback` | `bit` | Support for dual-writeback instructions    |
  | `TernaryOps`    | `bit` | Support for ternary operations (use `rs3`) |

- The `acc_interconnect` module variation additionally requires the accordingly generated request/response struct types:
  | Name          | Description                 |
  | ----          | -----------                 |
  | `acc_c_req_t` | C-interface request struct  |
  | `acc_c_rsp_t` | C-interface response struct |

  The typedefs are automatically declared using the typedef macros defined [here](../include/acc_interface/typedef.svh) as demonstrated in the following snippet.

  ```
  localparam int unsigned NumRs = TernaryOps ? 3 : 2;
  localparam int unsigned NumWb = DualWriteback ? 2 : 1;

  typedef logic [AddrWidth-1:0] addr_t; // AddrWidth parameter as defined in doc/c-interface.md.
  typedef logic [DataWidth-1:0] data_t;

  `ACC_C_TYPEDEF_ALL(acc_c, addr_t, data_t, NumRs, NumWb)
  ```

## Port Map
The accelerator interconnect module features the following [C-interface](c-interface.md) ports:

| Port Name (`acc_interconnect_intf`) | Port Name (`acc_interconnect`) | Type (`acc_interconnect`) | Description                                                                           |
| ---------                           | ----------                     | ---------                 | -----------                                                                           |
| `acc_c_slv[NumReq]`                 | `acc_c_slv_req_i[NumReq-1:0]`  | `acc_c_req_t`             | C-interface request channel input from accelerator adapter / lower-level interconnect |
|                                     | `acc_c_slv_rsp_o[NumReq-1:0]`  | `acc_c_rsp_t`             | C-interface response channel output to accelerator adapter / lower level interconnect |
| `acc_c_mst_next[NumReq]`            | `acc_c_mst_req_o[NumReq-1:0]`  | `acc_c_req_t`             | C-interface request channel output to higher-level interconnect                       |
|                                     | `acc_c_mst_rsp_i[NumReq-1:0]`  | `acc_c_rsp_t`             | C-interface response channel input from higher level interconnect                     |
| `acc_c_mst[NumRsp]`                 | `acc_c_mst_req_o[NumRsp-1:0]`  | `acc_c_req_t`             | C-interface request channel to directly connected accelerators                        |
|                                     | `acc_c_mst_rsp_i[NumRsp-1:0]`  | `acc_c_rsp_t`             | C-interface response channel from directly connected accelerators                     |
