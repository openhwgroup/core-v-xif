// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Noam Gallmann <gnoam@live.com>

// Accelerator Interconnect Typedefs
`ifndef ACC_TYPEDEF_SVH_
`define ACC_TYPEDEF_SVH_

////////////////////
// ACC_C Typedefs //
////////////////////


`define ACC_C_TYPEDEF_REQ_CHAN_T(__req_chan_t, __addr_t, __data_t, __NumRs) \
  typedef struct packed {                                                   \
    __addr_t               addr;                                            \
    __data_t [__NumRs-1:0] rs;                                              \
    logic    [       31:0] instr_data;                                      \
    __data_t               hart_id;                                         \
  } __req_chan_t;

`define ACC_C_TYPEDEF_REQ_T(__req_t, __req_chan_t) \
  typedef struct packed {                          \
    __req_chan_t q;                                \
    logic        q_valid;                          \
    logic        p_ready;                          \
  } __req_t;

`define ACC_C_TYPEDEF_RSP_CHAN_T(__rsp_chan_t, __data_t, __NumWb) \
  typedef struct packed {                                         \
    __data_t [__NumWb-1:0] data;                                  \
    logic                  error;                                 \
    logic                  dualwb;                                \
    __data_t               hart_id;                               \
    logic [4:0]            rd;                                    \
  } __rsp_chan_t;

`define ACC_C_TYPEDEF_RSP_T(__rsp_t, __rsp_chan_t) \
  typedef struct packed {                          \
    __rsp_chan_t p;                                \
    logic        p_valid;                          \
    logic        q_ready;                          \
  } __rsp_t;

`define ACC_C_TYPEDEF_ALL(__name, __addr_t, __data_t, __NumRs, __NumWb)       \
  `ACC_C_TYPEDEF_REQ_CHAN_T(__name``_req_chan_t, __addr_t, __data_t, __NumRs) \
  `ACC_C_TYPEDEF_RSP_CHAN_T(__name``_rsp_chan_t, __data_t, __NumWb)           \
  `ACC_C_TYPEDEF_REQ_T(__name``_req_t, __name``_req_chan_t )                  \
  `ACC_C_TYPEDEF_RSP_T(__name``_rsp_t,  __name``_rsp_chan_t )


///////////////////////
// ACC_CMEM Typedefs //
///////////////////////

`define ACC_CMEM_TYPEDEF_REQ_CHAN_T(__req_chan_t, __addr_t, __data_t, __mem_req_type_e) \
  typedef struct packed {                                                               \
    __data_t         laddr;                                                             \
    __data_t         wdata;                                                             \
    logic [2:0]      width;                                                             \
    __mem_req_type_e req_type;                                                          \
    logic            mode;                                                              \
    logic            spec;                                                              \
    logic            endoftransaction;                                                  \
    __data_t         hart_id;                                                           \
    __addr_t         addr;                                                              \
  } __req_chan_t;

`define ACC_CMEM_TYPEDEF_REQ_T(__req_t, __req_chan_t) \
  typedef struct packed {                             \
    __req_chan_t q;                                   \
    logic        q_valid;                             \
    logic        p_ready;                             \
  } __req_t;

`define ACC_CMEM_TYPEDEF_RSP_CHAN_T(__rsp_chan_t, __addr_t, __data_t) \
  typedef struct packed {                                             \
    __data_t                      rdata;                              \
    logic [$clog2(DataWidth)-1:0] range;                              \
    logic                         status;                             \
    __addr_t                      addr;                               \
    __data_t                      hart_id;                            \
  }                               __rsp_chan_t;

`define ACC_CMEM_TYPEDEF_RSP_T(__rsp_t, __rsp_chan_t) \
  typedef struct packed {                             \
    __rsp_chan_t p;                                   \
    logic        p_valid;                             \
    logic        q_ready;                             \
  } __rsp_t;

`define ACC_CMEM_TYPEDEF_ALL(__name, __addr_t, __data_t, __mem_req_type_e)                \
  `ACC_CMEM_TYPEDEF_REQ_CHAN_T(__name``_req_chan_t, __addr_t, __data_t, __mem_req_type_e) \
  `ACC_CMEM_TYPEDEF_RSP_CHAN_T(__name``_rsp_chan_t, __addr_t, __data_t)                   \
  `ACC_CMEM_TYPEDEF_REQ_T(__name``_req_t, __name``_req_chan_t )                           \
  `ACC_CMEM_TYPEDEF_RSP_T(__name``_rsp_t,  __name``_rsp_chan_t )

////////////////////
// ACC_X Typedefs //
////////////////////

`define ACC_X_TYPEDEF_REQ_T(__req_t, __req_chan_t) \
  typedef struct packed {                          \
    __req_chan_t q;                                \
    logic        q_valid;                          \
    logic        p_ready;                          \
  } __req_t;

`define ACC_X_TYPEDEF_REQ_CHAN_T(__req_chan_t, __data_t, __NumRs, __NumWb) \
  typedef struct packed {                                                  \
    logic    [       31:0] instr_data;                                     \
    __data_t [__NumRs-1:0] rs;                                             \
    logic    [__NumRs-1:0] rs_valid;                                       \
    logic    [__NumWb-1:0] rd_clean;                                       \
  } __req_chan_t;

`define ACC_X_TYPEDEF_RSP_T(__ack_t, __ack_chan_t, __rsp_chan_t) \
  typedef struct packed {                                        \
    logic        q_ready;                                        \
    logic        p_valid;                                        \
    __ack_chan_t k;                                              \
    __rsp_chan_t p;                                              \
  } __ack_t;

`define ACC_X_TYPEDEF_ACK_CHAN_T(__ack_chan_t, __NumWb) \
  typedef struct packed {                               \
    logic               accept;                         \
    logic [__NumWb-1:0] writeback;                      \
    logic               is_mem_op;                      \
  } __ack_chan_t;

`define ACC_X_TYPEDEF_RSP_CHAN_T(__rsp_chan_t, __data_t, __NumWb) \
  typedef struct packed {                                         \
    __data_t [__NumWb-1:0] data;                                  \
    logic                  error;                                 \
    logic                  dualwb;                                \
    logic [4:0]            rd;                                    \
  } __rsp_chan_t;

`define ACC_X_TYPEDEF_ALL(__name, __data_t, __NumRs, __NumWb)                \
  `ACC_X_TYPEDEF_REQ_CHAN_T(__name``_req_chan_t, __data_t, __NumRs, __NumWb) \
  `ACC_X_TYPEDEF_ACK_CHAN_T(__name``_ack_chan_t, __NumWb)                    \
  `ACC_X_TYPEDEF_RSP_CHAN_T(__name``_rsp_chan_t, __data_t, __NumWb)          \
  `ACC_X_TYPEDEF_REQ_T(__name``_req_t, __name``_req_chan_t)                  \
  `ACC_X_TYPEDEF_RSP_T( __name``_rsp_t, __name``_ack_chan_t, __name``_rsp_chan_t)

`endif // ACC_TYPEDEF_SVH_

///////////////////////
// ACC_XMEM Typedefs //
///////////////////////

`define ACC_XMEM_TYPEDEF_REQ_CHAN_T(__req_chan_t,  __data_t, __mem_req_type_e) \
  typedef struct packed {                                                      \
    __data_t         laddr;                                                    \
    __data_t         wdata;                                                    \
    logic [2:0]      width;                                                    \
    __mem_req_type_e req_type;                                                 \
    logic            mode;                                                     \
    logic            spec;                                                     \
    logic            endoftransaction;                                         \
  } __req_chan_t;

`define ACC_XMEM_TYPEDEF_REQ_T(__req_t, __req_chan_t) \
  typedef struct packed {                             \
    __req_chan_t q;                                   \
    logic        q_valid;                             \
    logic        p_ready;                             \
  } __req_t;

`define ACC_XMEM_TYPEDEF_RSP_CHAN_T(__rsp_chan_t, __data_t) \
  typedef struct packed {                                   \
    __data_t                      rdata;                    \
    logic [$clog2(DataWidth)-1:0] range;                    \
    logic                         status;                   \
  }                               __rsp_chan_t;

`define ACC_XMEM_TYPEDEF_RSP_T(__rsp_t, __rsp_chan_t) \
  typedef struct packed {                             \
    __rsp_chan_t p;                                   \
    logic        p_valid;                             \
    logic        q_ready;                             \
  } __rsp_t;

`define ACC_XMEM_TYPEDEF_ALL(__name,  __data_t, __mem_req_type_e)                \
  `ACC_XMEM_TYPEDEF_REQ_CHAN_T(__name``_req_chan_t,  __data_t, __mem_req_type_e) \
  `ACC_XMEM_TYPEDEF_RSP_CHAN_T(__name``_rsp_chan_t, __data_t)                    \
  `ACC_XMEM_TYPEDEF_REQ_T(__name``_req_t, __name``_req_chan_t)                   \
  `ACC_XMEM_TYPEDEF_RSP_T(__name``_rsp_t,  __name``_rsp_chan_t)
