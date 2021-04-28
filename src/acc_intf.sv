// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Noam Gallmann <gnoam@live.com>

// Accelerator Interface
//
// This interface provides two channels, one for requests and one for
// responses. Both channels have a valid/ready handshake. The sender sets the
// channel signals and pulls valid high. Once pulled high, valid must remain
// high and none of the signals may change. The transaction completes when both
// valid and ready are high. Valid must not depend on ready.
// The requester can offload any RISC-V instruction together with its operands
// and destination register address.
// Not all offloaded instructions necessarily result in a response. The
// offloading entity must be aware if a write-back is to be expected.
// For further details see docs/index.md.
/* verilator lint_off DECLFILENAME */

interface ACC_C_BUS #(
    // ISA bit width
    parameter int unsigned DataWidth = 32,
    // Address width
    parameter int          AddrWidth = -1,
    // Support for dual-writeback instructions
    parameter bit          DualWriteback = 0,
    // Support for ternary operations (use rs3)
    parameter bit          TernaryOps = 0
);

  typedef logic [DataWidth-1:0] data_t;
  typedef logic [AddrWidth-1:0] addr_t;

  localparam int unsigned NumRs = TernaryOps ? 3 : 2;
  localparam int unsigned NumWb = DualWriteback ? 2 : 1;

  // Request channel (Q).
  addr_t             q_addr;
  logic  [31:0]      q_instr_data;
  data_t [NumRs-1:0] q_rs;
  data_t             q_hart_id;
  logic              q_valid;
  logic              q_ready;

  // Response Channel (P).
  data_t [NumWb-1:0] p_data;
  logic              p_dualwb;
  data_t             p_hart_id;
  logic  [ 4:0]      p_rd;
  logic              p_error;
  logic              p_valid;
  logic              p_ready;

  modport in(
      input q_addr, q_instr_data, q_rs, q_hart_id, q_valid, p_ready,
      output q_ready, p_data, p_dualwb, p_hart_id, p_rd, p_error, p_valid
  );

  modport out(
      output q_addr, q_instr_data, q_rs, q_hart_id, q_valid, p_ready,
      input q_ready, p_data, p_dualwb, p_hart_id, p_rd, p_error, p_valid
  );

endinterface

interface ACC_C_BUS_DV #(
    // ISA bit width
    parameter int unsigned DataWidth = 32,
    // Address width
    parameter int          AddrWidth = -1,
    // Support for dual-writeback instructions
    parameter bit          DualWriteback = 0,
    // Support for ternary operations (use rs3)
    parameter bit          TernaryOps = 0
) (
  input clk_i
);

  typedef logic [DataWidth-1:0] data_t;
  typedef logic [AddrWidth-1:0] addr_t;

  localparam int unsigned NumRs = TernaryOps ? 3 : 2;
  localparam int unsigned NumWb = DualWriteback ? 2 : 1;

  // Request channel (Q).
  addr_t             q_addr;
  logic  [31:0]      q_instr_data;
  data_t [NumRs-1:0] q_rs;
  data_t             q_hart_id;
  logic              q_valid;
  logic              q_ready;

  // Response Channel (P).
  data_t [NumWb-1:0] p_data;
  logic              p_dualwb;
  data_t             p_hart_id;
  logic  [ 4:0]      p_rd;
  logic              p_error;
  logic              p_valid;
  logic              p_ready;

  modport in(
      input q_addr, q_instr_data, q_rs, q_hart_id, q_valid, p_ready,
      output q_ready, p_data, p_dualwb, p_hart_id, p_rd, p_error, p_valid
  );

  modport out(
      output q_addr, q_instr_data, q_rs, q_hart_id, q_valid, p_ready,
      input q_ready, p_data, p_dualwb, p_hart_id, p_rd, p_error, p_valid
  );

  modport monitor(
      input q_addr, q_instr_data, q_rs, q_hart_id, q_valid, p_ready,
      input q_ready, p_data, p_dualwb, p_hart_id, p_rd, p_error, p_valid
  );

  // pragma translate_off
`ifndef VERILATOR
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_addr)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_instr_data)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_rs)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_hart_id)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> q_valid));

  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_data)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_dualwb)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_hart_id)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_rd)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_error)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> p_valid));
`endif
  // pragma translate_on

endinterface

interface ACC_CMEM_BUS #(
    // ISA bit width
    parameter int unsigned DataWidth = 32,
    // Accelerator Address width
    parameter int          AddrWidth = -1
);

  typedef logic [DataWidth-1:0] data_t;
  typedef logic [AddrWidth-1:0] addr_t;

  // Request channel (Q).
  data_t      q_laddr;
  data_t      q_wdata;
  logic [2:0] q_width;
  logic [1:0] q_req_type;
  logic       q_mode;
  logic       q_spec;
  logic       q_endoftransaction;
  data_t      q_hart_id;
  addr_t      q_addr;
  logic       q_valid;
  logic       q_ready;

  // Response Channel (P).
  data_t                        p_rdata;
  logic [$clog2(DataWidth)-1:0] p_range;
  logic                         p_status;
  addr_t                        p_addr;
  data_t                        p_hart_id;
  logic                         p_valid;
  logic                         p_ready;

  modport in(
    input q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction, q_hart_id,
        q_addr, q_valid, p_ready,
    output p_rdata, p_range, p_status, p_addr, p_hart_id, p_valid, q_ready
  );

  modport out(
    output q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction, q_hart_id,
        q_addr, q_valid, p_ready,
    input p_rdata, p_range, p_status, p_addr, p_hart_id, p_valid, q_ready
  );

endinterface

interface ACC_CMEM_BUS_DV #(
    // ISA bit width
    parameter int unsigned DataWidth = 32,
    // Accelerator Address width
    parameter int          AddrWidth = -1
) (
  input clk_i
);

  typedef logic [DataWidth-1:0] data_t;
  typedef logic [AddrWidth-1:0] addr_t;

  // Request channel (Q).
  data_t      q_laddr;
  data_t      q_wdata;
  logic [2:0] q_width;
  logic [1:0] q_req_type;
  logic       q_mode;
  logic       q_spec;
  logic       q_endoftransaction;
  data_t      q_hart_id;
  addr_t      q_addr;
  logic       q_valid;
  logic       q_ready;

  // Response Channel (P).
  data_t                        p_rdata;
  logic [$clog2(DataWidth)-1:0] p_range;
  logic                         p_status;
  addr_t                        p_addr;
  data_t                        p_hart_id;
  logic                         p_valid;
  logic                         p_ready;

  modport in(
    input q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction, q_hart_id,
        q_addr, q_valid, p_ready,
    output p_rdata, p_range, p_status, p_addr, p_hart_id, p_valid, q_ready
  );

  modport out(
    output q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction, q_hart_id,
        q_addr, q_valid, p_ready,
    input p_rdata, p_range, p_status, p_addr, p_hart_id, p_valid, q_ready
  );

  modport monitor(
    input q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction, q_hart_id,
        q_addr, q_valid, p_ready,
    input p_rdata, p_range, p_status, p_addr, p_hart_id, p_valid, q_ready
  );

  // pragma translate_off
`ifndef VERILATOR
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_laddr)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_wdata)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_width)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_req_type)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_mode)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_spec)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_endoftransaction)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_hart_id)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_addr)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> q_valid));

  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_rdata)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_range)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_status)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_addr)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_hart_id)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> p_valid));
`endif
  // pragma translate_on
endinterface


interface ACC_X_BUS #(
    // ISA bit Width
    parameter int unsigned DataWidth = 32,
    // Support for dual-writeback instructions
    parameter bit          DualWriteback = 0,
    // Support for ternary operations (use rs3)
    parameter bit          TernaryOps = 0
);

  typedef logic [DataWidth-1:0] data_t;
  localparam int unsigned NumRs = TernaryOps ? 3 : 2;
  localparam int unsigned NumWb = DualWriteback ? 2 : 1;

  // Request Channel (Q)
  logic  [     31:0] q_instr_data;
  data_t [NumRs-1:0] q_rs;
  logic  [NumRs-1:0] q_rs_valid;
  logic  [NumWb-1:0] q_rd_clean;
  logic              q_valid;

  // Acknowledge Channel (K)
  logic         k_accept;
  logic  [ 1:0] k_writeback;
  logic         k_is_mem_op;
  logic         q_ready;

  // Response Channel (P)
  data_t [NumWb-1:0] p_data;
  logic              p_error;
  logic  [ 4:0]      p_rd;
  logic              p_dualwb;
  logic              p_valid;
  logic              p_ready;

  modport in(
      input q_instr_data, q_rs, q_rs_valid, q_rd_clean, q_valid, p_ready,
      output k_accept, k_writeback, k_is_mem_op, q_ready,
      output p_data, p_dualwb, p_rd, p_error, p_valid
  );

  modport out(
      output q_instr_data, q_rs, q_rs_valid, q_rd_clean, q_valid, p_ready,
      input k_accept, k_writeback, k_is_mem_op, q_ready,
      input p_data, p_dualwb, p_rd, p_error, p_valid
  );

endinterface

interface ACC_X_BUS_DV #(
    // ISA bit Width
    parameter int unsigned DataWidth = 32,
    // Support for dual-writeback instructions
    parameter bit          DualWriteback = 0,
    // Support for ternary operations (use rs3)
    parameter bit          TernaryOps = 0

) (
    input clk_i
);

  typedef logic [DataWidth-1:0] data_t;
  localparam int unsigned NumRs = TernaryOps ? 3 : 2;
  localparam int unsigned NumWb = DualWriteback ? 2 : 1;

  // Request Channel (Q)
  logic  [     31:0] q_instr_data;
  data_t [NumRs-1:0] q_rs;
  logic  [NumRs-1:0] q_rs_valid;
  logic  [NumWb-1:0] q_rd_clean;
  logic              q_valid;

  // Acknowledge Channel (K)
  logic         k_accept;
  logic  [ 1:0] k_writeback;
  logic         k_is_mem_op;
  logic         q_ready;

  // Response Channel (P)
  data_t [NumWb-1:0] p_data;
  logic              p_error;
  logic  [ 4:0]      p_rd;
  logic              p_dualwb;
  logic              p_valid;
  logic              p_ready;

  modport in(
      input q_instr_data, q_rs, q_rs_valid, q_rd_clean, q_valid, p_ready,
      output k_accept, k_writeback, k_is_mem_op, q_ready,
      output p_data, p_dualwb, p_rd, p_error, p_valid
  );

  modport out(
      output q_instr_data, q_rs, q_rs_valid, q_rd_clean, q_valid, p_ready,
      input k_accept, k_writeback, k_is_mem_op, q_ready,
      input p_data, p_dualwb, p_rd, p_error, p_valid
  );

  modport monitor(
      input q_instr_data, q_rs, q_rs_valid, q_rd_clean, q_valid, p_ready,
      input k_accept, k_writeback, k_is_mem_op, q_ready,
      input p_data, p_dualwb, p_rd, p_error, p_valid
  );

  // pragma translate_off
`ifndef VERILATOR
  // q channel
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> q_valid));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_instr_data)));
  for (genvar i = 0; i < NumRs; i++) begin : gen_rs_valid_assert
    assert property (@(posedge clk_i) (q_valid && q_rs_valid[i] && !q_ready |=> q_rs_valid[i]));
    assert property (@(posedge clk_i) (q_valid && q_rs_valid[i] && !q_ready |=> $stable(q_rs[i])));
  end
  assert property (@(posedge clk_i)
      (q_valid && q_ready |-> ((k_writeback ~^ q_rd_clean) | ~k_writeback) == '1));

  // p channel
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_data)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_dualwb)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_rd)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_error)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> p_valid));
`endif
  // pragma translate_on
endinterface

interface ACC_XMEM_BUS #(
    // ISA bit width
    parameter int unsigned DataWidth = 32
);

  typedef logic [DataWidth-1:0] data_t;

  // Request channel (Q).
  data_t      q_laddr;
  data_t      q_wdata;
  logic [2:0] q_width;
  logic [1:0] q_req_type;
  logic       q_mode;
  logic       q_spec;
  logic       q_endoftransaction;
  logic       q_valid;
  logic       q_ready;

  // Response Channel (P).
  data_t                        p_rdata;
  logic [$clog2(DataWidth)-1:0] p_range;
  logic                         p_status;
  logic                         p_valid;
  logic                         p_ready;

  modport in(
    input q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction,
        q_valid, p_ready,
    output p_rdata, p_range, p_status, p_valid, q_ready
  );

  modport out(
    output q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction,
        q_valid, p_ready,
    input p_rdata, p_range, p_status, p_valid, q_ready
  );

endinterface

interface ACC_XMEM_BUS_DV #(
    // ISA bit width
    parameter int unsigned DataWidth = 32
) (
  input clk_i
);

  typedef logic [DataWidth-1:0] data_t;

  // Request channel (Q).
  data_t      q_laddr;
  data_t      q_wdata;
  logic [2:0] q_width;
  logic [1:0] q_req_type;
  logic       q_mode;
  logic       q_spec;
  logic       q_endoftransaction;
  logic       q_valid;
  logic       q_ready;

  // Response Channel (P).
  data_t                        p_rdata;
  logic [$clog2(DataWidth)-1:0] p_range;
  logic                         p_status;
  logic                         p_valid;
  logic                         p_ready;

  modport in(
    input q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction,
        q_valid, p_ready,
    output p_rdata, p_range, p_status, p_valid, q_ready
  );

  modport out(
    output q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction,
        q_valid, p_ready,
    input p_rdata, p_range, p_status, p_valid, q_ready
  );

  modport monitor(
    input q_laddr, q_wdata, q_width, q_req_type, q_mode, q_spec, q_endoftransaction,
        q_valid, p_ready,
    input p_rdata, p_range, p_status, p_valid, q_ready
  );

  // pragma translate_off
`ifndef VERILATOR
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_laddr)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_wdata)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_width)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_req_type)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_mode)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_spec)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> $stable(q_endoftransaction)));
  assert property (@(posedge clk_i) (q_valid && !q_ready |=> q_valid));

  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_rdata)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_range)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> $stable(p_status)));
  assert property (@(posedge clk_i) (p_valid && !p_ready |=> p_valid));
`endif
  // pragma translate_on
endinterface

interface ACC_PRD_BUS;

  logic [31:0] q_instr_data;
  logic [ 1:0] p_writeback;
  logic        p_is_mem_op;
  logic [ 2:0] p_use_rs;
  logic        p_accept;

  modport in (
    input  q_instr_data,
    output p_writeback, p_is_mem_op, p_use_rs, p_accept
  );

  modport out (
    output q_instr_data,
    input p_writeback, p_is_mem_op, p_use_rs, p_accept
  );

endinterface

interface ACC_PRD_BUS_DV (
    input clk_i
);

  logic [31:0] q_instr_data;
  logic [ 1:0] p_writeback;
  logic        p_is_mem_op;
  logic [ 2:0] p_use_rs;
  logic        p_accept;

  modport in (
    input  q_instr_data,
    output p_writeback, p_is_mem_op, p_use_rs, p_accept
  );

  modport out (
    output q_instr_data,
    input  p_writeback, p_is_mem_op, p_use_rs, p_accept
  );

  modport monitor (
    input  q_instr_data,
    input  p_writeback, p_is_mem_op, p_use_rs, p_accept
  );

  // No asserts. This interface is completely combinational
endinterface
