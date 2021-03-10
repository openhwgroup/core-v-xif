// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Noam Gallmann <gnoam@live.com>

// Accelerator Interconnect Typedefs
`ifndef ACC_C_TYPEDEF_SVH_
`define ACC_C_TYPEDEF_SVH_

`define ACC_C_TYPEDEF_REQ_CHAN_T(__req_chan_t, __addr_t, __data_t) \
  typedef struct packed {                                          \
    __addr_t     addr;                                             \
    __data_t     data_arga;                                        \
    __data_t     data_argb;                                        \
    __data_t     data_argc;                                        \
    logic [31:0] data_op;                                          \
    logic [31:0] hart_id;                                          \
  } __req_chan_t;

`define ACC_C_TYPEDEF_REQ_T(__req_t, __req_chan_t) \
  typedef struct packed {                          \
    __req_chan_t q;                                \
    logic        q_valid;                          \
    logic        p_ready;                          \
  } __req_t;

`define ACC_C_TYPEDEF_RSP_CHAN_T(__rsp_chan_t, __data_t) \
  typedef struct packed {                                \
    __data_t     data0;                                  \
    __data_t     data1;                                  \
    logic        error;                                  \
    logic        dual_writeback;                         \
    logic [31:0] hart_id;                                \
    logic [4:0]  rd;                                     \
  } __rsp_chan_t;

`define ACC_C_TYPEDEF_RSP_T(__rsp_t, __rsp_chan_t) \
  typedef struct packed {                          \
    __rsp_chan_t p;                                \
    logic        p_valid;                          \
    logic        q_ready;                          \
  } __rsp_t;

`define ACC_C_TYPEDEF_ALL(__name, __addr_t, __data_t)                \
  `ACC_C_TYPEDEF_REQ_CHAN_T(__name``_req_chan_t, __addr_t, __data_t) \
  `ACC_C_TYPEDEF_RSP_CHAN_T(__name``_rsp_chan_t, __data_t)           \
  `ACC_C_TYPEDEF_REQ_T(__name``_req_t, __name``_req_chan_t )         \
  `ACC_C_TYPEDEF_RSP_T(__name``_rsp_t,  __name``_rsp_chan_t )

`endif // ACC_C_TYPEDEF_SVH_


`ifndef ACC_X_TYPEDEF_SVH_
`define ACC_X_TYPEDEF_SVH_

`define ACC_X_TYPEDEF_REQ_T(__req_t, __req_chan_t) \
  typedef struct packed {                          \
    __req_chan_t q;                                \
    logic        q_valid;                          \
    logic        p_ready;                          \
  } __req_t;

`define ACC_X_TYPEDEF_REQ_CHAN_T(__req_chan_t, __data_t) \
  typedef struct packed {                                \
    logic [31:0] instr_data;                             \
    __data_t     rs1;                                    \
    __data_t     rs2;                                    \
    __data_t     rs3;                                    \
    logic [2:0]  rs_valid;                               \
    logic [2:0]  rd_clean;                               \
  } __req_chan_t;

`define ACC_X_TYPEDEF_RSP_T(__ack_t, __ack_chan_t, __rsp_chan_t) \
  typedef struct packed {                                        \
    logic        q_ready;                                        \
    logic        p_valid;                                        \
    __ack_chan_t k;                                              \
    __rsp_chan_t p;                                              \
  } __ack_t;

`define ACC_X_TYPEDEF_ACK_CHAN_T(__ack_chan_t) \
  typedef struct packed {                      \
    logic       accept;                        \
    logic [1:0] writeback;                     \
  } __ack_chan_t;

`define ACC_X_TYPEDEF_RSP_CHAN_T(__rsp_chan_t, __data_t) \
  typedef struct packed {                                        \
    __data_t    data0;                                           \
    __data_t    data1;                                           \
    logic       error;                                           \
    logic       dual_writeback;                                  \
    logic [4:0] rd;                                              \
  } __rsp_chan_t;

`define ACC_X_TYPEDEF_ALL(__name, __data_t)                 \
  `ACC_X_TYPEDEF_REQ_CHAN_T(__name``_req_chan_t, __data_t)  \
  `ACC_X_TYPEDEF_ACK_CHAN_T(__name``_ack_chan_t)            \
  `ACC_X_TYPEDEF_RSP_CHAN_T(__name``_rsp_chan_t, __data_t)  \
  `ACC_X_TYPEDEF_REQ_T(__name``_req_t, __name``_req_chan_t) \
  `ACC_X_TYPEDEF_RSP_T( __name``_rsp_t, __name``_ack_chan_t, __name``_rsp_chan_t)

`endif // ACC_X_TYPEDEF_SVH_
