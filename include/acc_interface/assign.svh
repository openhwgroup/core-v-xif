// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Noam Gallmann <gnoam@live.com>

// Macros to assign accelerator interfaces and structs

/////////////////////
// ACC_C Interface //
/////////////////////

`ifndef ACC_ASSIGN_SVH_
`define ACC_ASSIGN_SVH_

// Assign handshake.
`define ACC_ASSIGN_VALID(__opt_as, __dst, __src, __chan) \
  __opt_as ``__dst``.``__chan``_valid   = ``__src``.``__chan``_valid;

`define ACC_ASSIGN_READY(__opt_as, __dst, __src, __chan) \
  __opt_as ``__dst``.``__chan``_ready   = ``__src``.``__chan``_ready;

`define ACC_ASSIGN_HANDSHAKE(__opt_as, __dst, __src, __chan) \
  `ACC_ASSIGN_VALID(__opt_as, __dst, __src, __chan)          \
  `ACC_ASSIGN_READY(__opt_as, __src, __dst, __chan)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one C interface to another, as if you would do `assign slv =
// mst;`
//
// The channel assignments `ACC_C_ASSIGN_XX(dst, src)` assign all payload and
// the valid signal of the `XX` channel from the `src` to the `dst` interface
// and they assign the ready signal from the `src` to the `dst` interface. The
// interface assignment `ACC_C_ASSIGN(dst, src)` assigns all channels including
// handshakes as if `src` was the master of `dst`.
//
// Usage Example: `ACC_C_C_ASSIGN(slv, mst) `ACC_C_C_ASSIGN_Q(dst, src, aw)
// `ACC_C_ASSIGN_P(dst, src)
`define ACC_C_ASSIGN_Q_CHAN(__opt_as, dst, src, __sep_dst, __sep_src)   \
  __opt_as dst.q``__sep_dst``addr       = src.q``__sep_src``addr;       \
  __opt_as dst.q``__sep_dst``instr_data = src.q``__sep_src``instr_data; \
  __opt_as dst.q``__sep_dst``rs         = src.q``__sep_src``rs;         \
  __opt_as dst.q``__sep_dst``hart_id    = src.q``__sep_src``hart_id;

`define ACC_C_ASSIGN_P_CHAN(__opt_as, dst, src, __sep_dst, __sep_src) \
  __opt_as dst.p``__sep_dst``data    = src.p``__sep_src``data;        \
  __opt_as dst.p``__sep_dst``error   = src.p``__sep_src``error;       \
  __opt_as dst.p``__sep_dst``dualwb  = src.p``__sep_src``dualwb;      \
  __opt_as dst.p``__sep_dst``hart_id = src.p``__sep_src``hart_id;     \
  __opt_as dst.p``__sep_dst``rd      = src.p``__sep_src``rd;

`define ACC_C_ASSIGN(slv, mst)                 \
  `ACC_C_ASSIGN_Q_CHAN(assign, slv, mst, _, _) \
  `ACC_ASSIGN_HANDSHAKE(assign, slv, mst, q)   \
  `ACC_C_ASSIGN_P_CHAN(assign, mst, slv, _, _) \
  `ACC_ASSIGN_HANDSHAKE(assign, mst, slv, p)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assign channel signals from one set of request/response struct to another,
// substituting one signal with custom defined override signal
//
// Usage example: `ACC_C_ASSIGN_Q_SIGNALS(assign, slv_req_o.q, slv_req_q_chan, "id", sender_id);
`define ACC_C_ASSIGN_Q_SIGNALS(__opt_as, dst, src,  ovr_name = "none", ovr_sig = '0) \
  __opt_as dst.addr       = ``ovr_name`` == "addr"       ? ovr_sig : src.addr;       \
  __opt_as dst.instr_data = ``ovr_name`` == "instr_data" ? ovr_sig : src.instr_data; \
  __opt_as dst.rs         = ``ovr_name`` == "rs"         ? ovr_sig : src.rs;         \
  __opt_as dst.hart_id    = ``ovr_name`` == "hart_id"    ? ovr_sig : src.hart_id;

  // Assign P_channel signals with override.
`define ACC_C_ASSIGN_P_SIGNALS(__opt_as, dst, src,  ovr_name="none", ovr_sig='0) \
  __opt_as dst.data    = ``ovr_name`` == "data"    ? ovr_sig : src.data;         \
  __opt_as dst.dualwb  = ``ovr_name`` == "dualwb"  ? ovr_sig : src.dualwb;       \
  __opt_as dst.error   = ``ovr_name`` == "error"   ? ovr_sig : src.error;        \
  __opt_as dst.hart_id = ``ovr_name`` == "hart_id" ? ovr_sig : src.hart_id;      \
  __opt_as dst.rd      = ``ovr_name`` == "rd"      ? ovr_sig : src.rd;

////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning an interface from channel or request/response structs outside a
// process.
//
// The request macro `ACC_C_ASSIGN_FROM_REQ(acc_if, req_struct)` assigns the
// request channel and the request-side handshake signals of the `acc_if`
// interface from the signals in `req_struct`. The response macro
// `ACC_C_ASSIGN_FROM_RESP(acc_if, resp_struct)` assigns the response
// channel and the response-side handshake signals of the `acc_if` interface
// from the signals in `resp_struct`.
//
// Usage Example:
// `ACC_C_ASSIGN_FROM_REQ(my_if, my_req_struct)
`define ACC_C_ASSIGN_FROM_REQ(acc_if, req_struct)        \
  `ACC_ASSIGN_VALID(assign, acc_if, req_struct, q)       \
  `ACC_C_ASSIGN_Q_CHAN(assign, acc_if, req_struct, _, .) \
  `ACC_ASSIGN_READY(assign, acc_if, req_struct, p)

`define ACC_C_ASSIGN_FROM_RESP(acc_if, resp_struct)       \
  `ACC_ASSIGN_READY(assign, acc_if, resp_struct, q)       \
  `ACC_C_ASSIGN_P_CHAN(assign, acc_if, resp_struct, _, .) \
  `ACC_ASSIGN_VALID(assign, acc_if, resp_struct, p)

////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a
// process.
//
// The request macro `ACC_C_ASSIGN_TO_REQ(acc_if, req_struct)` assigns all
// signals of `req_struct` payload and request-side handshake signals to the
// signals in the `acc_if` interface. The response macro
// `ACC_C_ASSIGN_TO_RESP(acc_if, resp_struct)` assigns all signals of
// `resp_struct` payload and response-side handshake signals to the signals in
// the `acc_if` interface.
//
// Usage Example:
// `ACC_C_ASSIGN_TO_REQ(my_req_struct, my_if)
`define ACC_C_ASSIGN_TO_REQ(req_struct, acc_if)          \
  `ACC_ASSIGN_VALID(assign, req_struct, acc_if, q)       \
  `ACC_C_ASSIGN_Q_CHAN(assign, req_struct, acc_if, ., _) \
  `ACC_ASSIGN_READY(assign, req_struct, acc_if, p)

`define ACC_C_ASSIGN_TO_RESP(resp_struct, acc_if)         \
  `ACC_ASSIGN_READY(assign, resp_struct, acc_if, q)       \
  `ACC_C_ASSIGN_P_CHAN(assign, resp_struct, acc_if, ., _) \
  `ACC_ASSIGN_VALID(assign, resp_struct, acc_if, p)

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////
// ACC_CMEM Interface //
////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one ACC_CMEM interface to another, as if you would do `assign slv =
// mst;`

`define ACC_CMEM_ASSIGN_Q_CHAN(__opt_as, dst, src, __sep_dst, __sep_src)            \
  __opt_as dst.q``__sep_dst``laddr            = src.q``__sep_src``laddr;            \
  __opt_as dst.q``__sep_dst``wdata            = src.q``__sep_src``wdata;            \
  __opt_as dst.q``__sep_dst``width            = src.q``__sep_src``width;            \
  __opt_as dst.q``__sep_dst``req_type         = src.q``__sep_src``req_type;         \
  __opt_as dst.q``__sep_dst``mode             = src.q``__sep_src``mode;             \
  __opt_as dst.q``__sep_dst``spec             = src.q``__sep_src``spec;             \
  __opt_as dst.q``__sep_dst``endoftransaction = src.q``__sep_src``endoftransaction; \
  __opt_as dst.q``__sep_dst``hart_id          = src.q``__sep_src``hart_id;          \
  __opt_as dst.q``__sep_dst``addr             = src.q``__sep_src``addr;

`define ACC_CMEM_ASSIGN_P_CHAN(__opt_as, dst, src, __sep_dst, __sep_src) \
  __opt_as dst.p``__sep_dst``rdata   = src.p``__sep_src``rdata;          \
  __opt_as dst.p``__sep_dst``range   = src.p``__sep_src``range;          \
  __opt_as dst.p``__sep_dst``status  = src.p``__sep_src``status;         \
  __opt_as dst.p``__sep_dst``addr    = src.p``__sep_src``addr;           \
  __opt_as dst.p``__sep_dst``hart_id = src.p``__sep_src``hart_id;

  // Assign P_channel signals with override.
`define ACC_CMEM_ASSIGN_Q_SIGNALS(__opt_as, dst, src,  ovr_name="none", ovr_sig='0)                    \
  __opt_as dst.laddr            = ``ovr_name`` == "laddr"            ? ovr_sig : src.laddr;            \
  __opt_as dst.wdata            = ``ovr_name`` == "wdata"            ? ovr_sig : src.wdata;            \
  __opt_as dst.width            = ``ovr_name`` == "width"            ? ovr_sig : src.width;            \
  __opt_as dst.req_type         = ``ovr_name`` == "req_type"         ? ovr_sig : src.req_type;         \
  __opt_as dst.mode             = ``ovr_name`` == "mode"             ? ovr_sig : src.mode;             \
  __opt_as dst.spec             = ``ovr_name`` == "spec"             ? ovr_sig : src.spec;             \
  __opt_as dst.endoftransaction = ``ovr_name`` == "endoftransaction" ? ovr_sig : src.endoftransaction; \
  __opt_as dst.hart_id          = ``ovr_name`` == "hart_id"          ? ovr_sig : src.hart_id;          \
  __opt_as dst.addr             = ``ovr_name`` == "addr"             ? ovr_sig : src.addr;

`define ACC_CMEM_ASSIGN_P_SIGNALS(__opt_as, dst, src,  ovr_name="none", ovr_sig='0) \
  __opt_as dst.rdata   = ``ovr_name`` == "rdata"   ? ovr_sig : src.rdata;           \
  __opt_as dst.range   = ``ovr_name`` == "range"   ? ovr_sig : src.range;           \
  __opt_as dst.status  = ``ovr_name`` == "status"  ? ovr_sig : src.status;          \
  __opt_as dst.addr    = ``ovr_name`` == "addr"    ? ovr_sig : src.addr;            \
  __opt_as dst.hart_id = ``ovr_name`` == "hart_id" ? ovr_sig : src.hart_id;

`define ACC_CMEM_ASSIGN(slv, mst)                 \
  `ACC_CMEM_ASSIGN_Q_CHAN(assign, slv, mst, _, _) \
  `ACC_ASSIGN_HANDSHAKE(assign, slv, mst, q)      \
  `ACC_CMEM_ASSIGN_P_CHAN(assign, mst, slv, _, _) \
  `ACC_ASSIGN_HANDSHAKE(assign, mst, slv, p)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning an interface from channel or request/response structs outside a
// process.

`define ACC_CMEM_ASSIGN_FROM_REQ(acc_if, req_struct)        \
  `ACC_ASSIGN_VALID(assign, acc_if, req_struct, q)          \
  `ACC_CMEM_ASSIGN_Q_CHAN(assign, acc_if, req_struct, _, .) \
  `ACC_ASSIGN_READY(assign, acc_if, req_struct, p)

`define ACC_CMEM_ASSIGN_FROM_RESP(acc_if, resp_struct)       \
  `ACC_ASSIGN_READY(assign, acc_if, resp_struct, q)          \
  `ACC_CMEM_ASSIGN_P_CHAN(assign, acc_if, resp_struct, _, .) \
  `ACC_ASSIGN_VALID(assign, acc_if, resp_struct, p)

////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a
// process.
`define ACC_CMEM_ASSIGN_TO_REQ(req_struct, acc_if)          \
  `ACC_ASSIGN_VALID(assign, req_struct, acc_if, q)          \
  `ACC_CMEM_ASSIGN_Q_CHAN(assign, req_struct, acc_if, ., _) \
  `ACC_ASSIGN_READY(assign, req_struct, acc_if, p)

`define ACC_CMEM_ASSIGN_TO_RESP(resp_struct, acc_if)         \
  `ACC_ASSIGN_READY(assign, resp_struct, acc_if, q)          \
  `ACC_CMEM_ASSIGN_P_CHAN(assign, resp_struct, acc_if, ., _) \
  `ACC_ASSIGN_VALID(assign, resp_struct, acc_if, p)


////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////
// ACC_X Interface //
/////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one ACC_Xinterface to another, as if you would do `assign slv =
// mst;`

`define ACC_X_ASSIGN_Q_CHAN(__opt_as, dst, src, __sep_dst, __sep_src)   \
  __opt_as dst.q``__sep_dst``instr_data = src.q``__sep_src``instr_data; \
  __opt_as dst.q``__sep_dst``rs         = src.q``__sep_src``rs;         \
  __opt_as dst.q``__sep_dst``rs_valid   = src.q``__sep_src``rs_valid;   \
  __opt_as dst.q``__sep_dst``rd_clean   = src.q``__sep_src``rd_clean;

`define ACC_X_ASSIGN_K_CHAN(__opt_as, dst, src, __sep_dst, __sep_src) \
  __opt_as dst.k``__sep_dst``accept    = src.k``__sep_src``accept;    \
  __opt_as dst.k``__sep_dst``writeback = src.k``__sep_src``writeback;

`define ACC_X_ASSIGN_P_CHAN(__opt_as, dst, src, __sep_dst, __sep_src) \
  __opt_as dst.p``__sep_dst``data   = src.p``__sep_src``data;         \
  __opt_as dst.p``__sep_dst``error  = src.p``__sep_src``error;        \
  __opt_as dst.p``__sep_dst``dualwb = src.p``__sep_src``dualwb;       \
  __opt_as dst.p``__sep_dst``rd     = src.p``__sep_src``rd;

  // Assign P_channel signals with override.
`define ACC_X_ASSIGN_P_SIGNALS(__opt_as, dst, src,  ovr_name="none", ovr_sig='0) \
  __opt_as dst.data   = ``ovr_name`` == "data"   ? ovr_sig : src.data;           \
  __opt_as dst.dualwb = ``ovr_name`` == "dualwb" ? ovr_sig : src.dualwb;         \
  __opt_as dst.error  = ``ovr_name`` == "error"  ? ovr_sig : src.error;          \
  __opt_as dst.rd     = ``ovr_name`` == "rd"     ? ovr_sig : src.rd;

`define ACC_X_ASSIGN(slv, mst)                 \
  `ACC_X_ASSIGN_Q_CHAN(assign, slv, mst, _, _) \
  `ACC_ASSIGN_HANDSHAKE(assign, slv, mst, q)   \
  `ACC_X_ASSIGN_K_CHAN(assign, mst, slv, _, _) \
  `ACC_X_ASSIGN_P_CHAN(assign, mst, slv, _, _) \
  `ACC_ASSIGN_HANDSHAKE(assign, mst, slv, p)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning an interface from channel or request/response structs outside a
// process.

`define ACC_X_ASSIGN_FROM_REQ(acc_if, req_struct)        \
  `ACC_ASSIGN_VALID(assign, acc_if, req_struct, q)       \
  `ACC_X_ASSIGN_Q_CHAN(assign, acc_if, req_struct, _, .) \
  `ACC_ASSIGN_READY(assign, acc_if, req_struct, p)

`define ACC_X_ASSIGN_FROM_RESP(acc_if, resp_struct)       \
  `ACC_ASSIGN_READY(assign, acc_if, resp_struct, q)       \
  `ACC_X_ASSIGN_P_CHAN(assign, acc_if, resp_struct, _, .) \
  `ACC_X_ASSIGN_K_CHAN(assign, acc_if, resp_struct, _, .) \
  `ACC_ASSIGN_VALID(assign, acc_if, resp_struct, p)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a
// process.
`define ACC_X_ASSIGN_TO_REQ(req_struct, acc_if)          \
  `ACC_ASSIGN_VALID(assign, req_struct, acc_if, q)       \
  `ACC_X_ASSIGN_Q_CHAN(assign, req_struct, acc_if, ., _) \
  `ACC_ASSIGN_READY(assign, req_struct, acc_if, p)

`define ACC_X_ASSIGN_TO_RESP(resp_struct, acc_if)         \
  `ACC_ASSIGN_READY(assign, resp_struct, acc_if, q)       \
  `ACC_X_ASSIGN_P_CHAN(assign, resp_struct, acc_if, ., _) \
  `ACC_X_ASSIGN_K_CHAN(assign, resp_struct, acc_if, ., _) \
  `ACC_ASSIGN_VALID(assign, resp_struct, acc_if, p)

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////
// ACC_XMEM Interface //
////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one ACC_XMEM interface to another, as if you would do `assign slv =
// mst;`

`define ACC_XMEM_ASSIGN_Q_CHAN(__opt_as, dst, src, __sep_dst, __sep_src)    \
  __opt_as dst.q``__sep_dst``laddr            = src.q``__sep_src``laddr;    \
  __opt_as dst.q``__sep_dst``wdata            = src.q``__sep_src``wdata;    \
  __opt_as dst.q``__sep_dst``width            = src.q``__sep_src``width;    \
  __opt_as dst.q``__sep_dst``req_type         = src.q``__sep_src``req_type; \
  __opt_as dst.q``__sep_dst``mode             = src.q``__sep_src``mode;     \
  __opt_as dst.q``__sep_dst``spec             = src.q``__sep_src``spec;     \
  __opt_as dst.q``__sep_dst``endoftransaction = src.q``__sep_src``endoftransaction;

`define ACC_XMEM_ASSIGN_P_CHAN(__opt_as, dst, src, __sep_dst, __sep_src) \
  __opt_as dst.p``__sep_dst``rdata   = src.p``__sep_src``rdata;          \
  __opt_as dst.p``__sep_dst``range   = src.p``__sep_src``range;          \
  __opt_as dst.p``__sep_dst``status  = src.p``__sep_src``status;

  // Assign P_channel signals with override.
`define ACC_XMEM_ASSIGN_Q_SIGNALS(__opt_as, dst, src,  ovr_name="none", ovr_sig='0) \
  __opt_as dst.data = ``ovr_name`` == "laddr"            ? ovr_sig : src.laddr;     \
  __opt_as dst.data = ``ovr_name`` == "wdata"            ? ovr_sig : src.wdata;     \
  __opt_as dst.data = ``ovr_name`` == "width"            ? ovr_sig : src.width;     \
  __opt_as dst.data = ``ovr_name`` == "req_type"         ? ovr_sig : src.req_type;  \
  __opt_as dst.data = ``ovr_name`` == "mode"             ? ovr_sig : src.mode;      \
  __opt_as dst.data = ``ovr_name`` == "spec"             ? ovr_sig : src.spec;      \
  __opt_as dst.data = ``ovr_name`` == "endoftransaction" ? ovr_sig : src.endoftransaction;

`define ACC_XMEM_ASSIGN_P_SIGNALS(__opt_as, dst, src,  ovr_name="none", ovr_sig='0) \
  __opt_as dst.data = ``ovr_name`` == "rdata"   ? ovr_sig : src.rdata;              \
  __opt_as dst.data = ``ovr_name`` == "range"   ? ovr_sig : src.range;              \
  __opt_as dst.data = ``ovr_name`` == "status"  ? ovr_sig : src.status;

`define ACC_XMEM_ASSIGN(slv, mst)                 \
  `ACC_XMEM_ASSIGN_Q_CHAN(assign, slv, mst, _, _) \
  `ACC_ASSIGN_HANDSHAKE(assign, slv, mst, q)      \
  `ACC_XMEM_ASSIGN_P_CHAN(assign, mst, slv, _, _) \
  `ACC_ASSIGN_HANDSHAKE(assign, mst, slv, p)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning an interface from channel or request/response structs outside a
// process.

`define ACC_XMEM_ASSIGN_FROM_REQ(acc_if, req_struct)        \
  `ACC_ASSIGN_VALID(assign, acc_if, req_struct, q)          \
  `ACC_XMEM_ASSIGN_Q_CHAN(assign, acc_if, req_struct, _, .) \
  `ACC_ASSIGN_READY(assign, acc_if, req_struct, p)

`define ACC_XMEM_ASSIGN_FROM_RESP(acc_if, resp_struct)       \
  `ACC_ASSIGN_READY(assign, acc_if, resp_struct, q)          \
  `ACC_XMEM_ASSIGN_P_CHAN(assign, acc_if, resp_struct, _, .) \
  `ACC_ASSIGN_VALID(assign, acc_if, resp_struct, p)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a
// process.
`define ACC_XMEM_ASSIGN_TO_REQ(req_struct, acc_if)          \
  `ACC_ASSIGN_VALID(assign, req_struct, acc_if, q)          \
  `ACC_XMEM_ASSIGN_Q_CHAN(assign, req_struct, acc_if, ., _) \
  `ACC_ASSIGN_READY(assign, req_struct, acc_if, p)

`define ACC_XMEM_ASSIGN_TO_RESP(resp_struct, acc_if)         \
  `ACC_ASSIGN_READY(assign, resp_struct, acc_if, q)          \
  `ACC_XMEM_ASSIGN_P_CHAN(assign, resp_struct, acc_if, ., _) \
  `ACC_ASSIGN_VALID(assign, resp_struct, acc_if, p)


////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////
// Predecoder Interface //
//////////////////////////

`define ACC_PRD_ASSIGN_P_CHAN(__opt_as, dst, src, __sep_dst, __sep_src) \
  __opt_as dst.p``__sep_dst``writeback = src.p``__sep_src``writeback;   \
  __opt_as dst.p``__sep_dst``use_rs    = src.p``__sep_src``use_rs;      \
  __opt_as dst.p``__sep_dst``accept    = src.p``__sep_src``accept;


`define ACC_PRD_ASSIGN_Q_CHAN(__opt_as, dst, src, __sep_dst, __sep_src) \
  __opt_as dst.q``__sep_dst``instr_data    = src.q``__sep_src``instr_data;

`define ACC_PRD_ASSIGN(slv, mst)                 \
  `ACC_PRD_ASSIGN_Q_CHAN(assign, slv, mst, _, _) \
  `ACC_PRD_ASSIGN_P_CHAN(assign, mst, slv, _, _)

`define ACC_PRD_ASSIGN_FROM_REQ(acc_if, req_struct) \
  `ACC_PRD_ASSIGN_Q_CHAN(assign, acc_if, req_struct, _, _)

`define ACC_PRD_ASSIGN_FROM_RESP(acc_if, resp_struct) \
  `ACC_PRD_ASSIGN_P_CHAN(assign, acc_if, resp_struct, _, _)

`define ACC_PRD_ASSIGN_TO_REQ(req_struct, acc_if) \
  `ACC_PRD_ASSIGN_Q_CHAN(assign, req_struct, acc_if, _, _)

`define ACC_PRD_ASSIGN_TO_RESP(resp_struct, acc_if) \
  `ACC_PRD_ASSIGN_P_CHAN(assign, resp_struct, acc_if, _, _)

`endif // ACC_ASSIGN_SVH_
