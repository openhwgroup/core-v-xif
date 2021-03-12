// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Noam Gallmann <gnoam@live.com>
//
// Implements one hierarchy level of the accelerator interconnnect.

`include "acc_interface/assign.svh"

module acc_interconnect #(
    // ISA bit width.
    parameter int unsigned DataWidth     = 32,
    // Hierarchy Address Portion
    parameter int unsigned HierAddrWidth = -1,
    // Accelerator Address Portion
    parameter int unsigned AccAddrWidth  = -1,
    // Hierarchy level
    parameter int unsigned HierLevel     = -1,
    // The number of requesters.
    parameter int          NumReq        = -1,
    // The number of rsponders.
    parameter int          NumRsp        = -1,
    // Support for ternary operations (use rs3)
    parameter bit          TernaryOps    = 0,
    // Support for dual-writeback instructions
    parameter bit          DualWriteback = 0,
    // Insert Pipeline register into request path
    parameter bit          RegisterReq   = 0,
    // Insert Pipeline register into response path
    parameter bit          RegisterRsp   = 0,

    // C Request Type
    parameter type acc_c_req_t          = logic,
    // C Request Payload Type
    parameter type acc_c_req_chan_t     = logic,
    // C Response Type.
    parameter type acc_c_rsp_t          = logic,
    // C Response Payload Type.
    parameter type acc_c_rsp_chan_t     = logic
) (
    input clk_i,
    input rst_ni,

    // From / To requesting entity
    input  acc_c_req_t [NumReq-1:0] acc_c_slv_req_i,
    output acc_c_rsp_t [NumReq-1:0] acc_c_slv_rsp_o,

    // From / To next cluster level
    output acc_c_req_t [NumReq-1:0] acc_c_mst_next_req_o,
    input  acc_c_rsp_t [NumReq-1:0] acc_c_mst_next_rsp_i,

    // From / To responding entity
    output acc_c_req_t [NumRsp-1:0] acc_c_mst_req_o,
    input  acc_c_rsp_t [NumRsp-1:0] acc_c_mst_rsp_i
);

  localparam int unsigned IdxWidth = cf_math_pkg::idx_width(NumReq);
  localparam int unsigned AddrWidth = HierAddrWidth + AccAddrWidth;

  // Local xbar select signal width
  localparam int unsigned OfflAddrWidth = cf_math_pkg::idx_width(NumRsp);

  typedef logic [AddrWidth-1:0] addr_t;

  // Master request: cross-bar in
  acc_c_req_chan_t [NumReq-1:0]         mst_req_q_chan;
  logic [NumReq-1:0][OfflAddrWidth-1:0] mst_req_q_addr;
  logic [NumReq-1:0]                    mst_req_q_valid;
  logic [NumReq-1:0]                    mst_req_p_ready;
  // Hierarchy level address
  logic [NumReq-1:0][HierAddrWidth-1:0] mst_req_q_level;

  // Slave rerequest: cross-bar out
  // this is mst_req_t, bc the payload does not change through the cross-bar.
  acc_c_req_chan_t [NumRsp-1:0] slv_req_q_chan;
  logic [NumRsp-1:0]            slv_req_q_valid;
  logic [NumRsp-1:0]            slv_req_p_ready;

  // Slave response: cross-bar in
  acc_c_rsp_chan_t [NumRsp-1:0] slv_rsp_p_chan;
  logic [NumRsp-1:0]            slv_rsp_p_valid;
  logic [NumRsp-1:0]            slv_rsp_q_ready;
  // Master response: cross-bar out
  acc_c_rsp_chan_t [NumReq-1:0] mst_rsp_p_chan;
  logic [NumReq-1:0]            mst_rsp_p_valid;
  logic [NumReq-1:0]            mst_rsp_q_ready;

  logic [NumRsp-1:0][IdxWidth-1:0] rsp_idx;

  // Generate request routing signals
  for (genvar i = 0; i < NumReq; i++) begin : gen_mst_req_assignment
    assign mst_req_q_chan[i]  = acc_c_slv_req_i[i].q;
    // Xbar Address
    assign mst_req_q_addr[i]  = acc_c_slv_req_i[i].q.addr[OfflAddrWidth-1:0];
    // Hierarchy level address
    assign mst_req_q_level[i] = acc_c_slv_req_i[i].q.addr[AddrWidth-1:AccAddrWidth];
  end

  for (genvar i = 0; i < NumRsp; i++) begin : gen_slv_req_assignment
    `ACC_C_ASSIGN_Q_SIGNALS(assign, acc_c_mst_req_o[i].q, slv_req_q_chan[i])
    assign acc_c_mst_req_o[i].q_valid = slv_req_q_valid[i];
    assign acc_c_mst_req_o[i].p_ready = slv_req_p_ready[i];
  end

  for (genvar i = 0; i < NumRsp; i++) begin : gen_mst_rsp_assignment
    // Discard upper bits of ID signal after xbar traversal.
    `ACC_C_ASSIGN_P_SIGNALS(assign, slv_rsp_p_chan[i], acc_c_mst_rsp_i[i].p)
    // Generate response routing signal
    // Hart_id signals are generally hard wired at synthesis time. This
    // logic reduces to a simple lookup table.
    always_comb begin
      rsp_idx[i] = '0;
      for (int j = 0; j < NumReq; j++) begin
        rsp_idx[i] |= (acc_c_mst_rsp_i[i].p.hart_id == acc_c_slv_req_i[j].q.hart_id) ?
          IdxWidth'(unsigned'(j)) : '0;
      end
    end
    assign slv_rsp_p_valid[i] = acc_c_mst_rsp_i[i].p_valid;
    assign slv_rsp_q_ready[i] = acc_c_mst_rsp_i[i].q_ready;
  end

  // Bypass this hierarchy level
  for (genvar i = 0; i < NumReq; i++) begin : gen_bypass_path
    // Offload path
    assign acc_c_mst_next_req_o[i].q = acc_c_slv_req_i[i].q;
    stream_demux #(
        .N_OUP ( 2 )
    ) offload_bypass_demux_i (
        .inp_valid_i ( acc_c_slv_req_i[i].q_valid                            ),
        .inp_ready_o ( acc_c_slv_rsp_o[i].q_ready                            ),
        .oup_sel_i   ( mst_req_q_level[i] != HierLevel                       ),
        .oup_valid_o ( {acc_c_mst_next_req_o[i].q_valid, mst_req_q_valid[i]} ),
        .oup_ready_i ( {acc_c_mst_next_rsp_i[i].q_ready, mst_rsp_q_ready[i]} )
    );

    // Response Path
    stream_arbiter #(
        .DATA_T  ( acc_c_rsp_chan_t ),
        .N_INP   ( 2                ),
        .ARBITER ( "rr"             )
    ) response_bypass_arbiter_i (
        .clk_i       ( clk_i                                                 ),
        .rst_ni      ( rst_ni                                                ),
        .inp_data_i  ( {acc_c_mst_next_rsp_i[i].p, mst_rsp_p_chan[i]}        ),
        .inp_valid_i ( {acc_c_mst_next_rsp_i[i].p_valid, mst_rsp_p_valid[i]} ),
        .inp_ready_o ( {acc_c_mst_next_req_o[i].p_ready, mst_req_p_ready[i]} ),
        .oup_data_o  ( acc_c_slv_rsp_o[i].p                                  ),
        .oup_valid_o ( acc_c_slv_rsp_o[i].p_valid                            ),
        .oup_ready_i ( acc_c_slv_req_i[i].p_ready                            )
    );
  end

  // offload path Xbar
  stream_xbar #(
      .NumInp      ( NumReq           ),
      .NumOut      ( NumRsp           ),
      .DataWidth   ( DataWidth        ),
      .payload_t   ( acc_c_req_chan_t ),
      .OutSpillReg ( RegisterReq      )
  ) offload_xbar_i (
      .clk_i   ( clk_i           ),
      .rst_ni  ( rst_ni          ),
      .flush_i ( 1'b0            ),
      .rr_i    ( '0              ),
      .data_i  ( mst_req_q_chan  ),
      .sel_i   ( mst_req_q_addr  ),
      .valid_i ( mst_req_q_valid ),
      .ready_o ( mst_rsp_q_ready ),
      .data_o  ( slv_req_q_chan  ),
      .idx_o   ( /* unused */    ),
      .valid_o ( slv_req_q_valid ),
      .ready_i ( slv_rsp_q_ready )
  );

  // response path Xbar
  stream_xbar #(
      .NumInp      ( NumRsp           ),
      .NumOut      ( NumReq           ),
      .DataWidth   ( DataWidth        ),
      .payload_t   ( acc_c_rsp_chan_t ),
      .OutSpillReg ( RegisterRsp      )
  ) response_xbar_i (
      .clk_i   ( clk_i           ),
      .rst_ni  ( rst_ni          ),
      .flush_i ( 1'b0            ),
      .rr_i    ( '0              ),
      .data_i  ( slv_rsp_p_chan  ),
      .sel_i   ( rsp_idx         ),
      .valid_i ( slv_rsp_p_valid ),
      .ready_o ( slv_req_p_ready ),
      .data_o  ( mst_rsp_p_chan  ),
      .idx_o   ( /* unused */    ),
      .valid_o ( mst_rsp_p_valid ),
      .ready_i ( mst_req_p_ready )
  );

  // Sanity Checks
  // pragma translate_off
`ifndef VERILATOR
  for (genvar i = 0; i < NumReq; i++) begin : gen_req_fwd_asserts
    assert property (@(posedge clk_i)
        (acc_c_mst_next_req_o[i].q_valid)
            |-> acc_c_mst_next_req_o[i].q.addr[AddrWidth-1:AccAddrWidth] > HierLevel)
    else
      $error("Accelerator C request to level %0d bypassed interconnect level %0d.",
             acc_c_mst_next_req_o[i].q.addr[AddrWidth-1:AccAddrWidth], HierLevel);
  end

  for (genvar i = 0; i < NumRsp; i++) begin : gen_req_asserts
    assert property (@(posedge clk_i)
        (acc_c_mst_req_o[i].q_valid)
            |-> acc_c_mst_req_o[i].q.addr[AddrWidth-1:AccAddrWidth] == HierLevel)
    else
      $error("Accelerator C request to level %0d routed to interconnect level %0d.",
             acc_c_mst_req_o[i].q.addr[AddrWidth-1:AccAddrWidth], HierLevel);
  end
`endif
  // pragma translate_on

endmodule

`include "acc_interface/typedef.svh"
`include "acc_interface/assign.svh"

module acc_interconnect_intf #(
    // ISA bit width.
    parameter int unsigned DataWidth     = 32,
    // Hierarchy Address Portion
    parameter int unsigned HierAddrWidth = -1,
    // Accelerator Address Portion
    parameter int unsigned AccAddrWidth  = -1,
    // Hierarchy level
    parameter int unsigned HierLevel     = -1,
    // The number of requesters
    parameter int          NumReq        = -1,
    // The number of rsponders.
    parameter int          NumRsp        = -1,
    // Support for ternary operations (use rs3)
    parameter bit          TernaryOps    = 0,
    // Support for dual-writeback instructions
    parameter bit          DualWriteback = 0,
    // Insert Pipeline register into request path
    parameter bit          RegisterReq   = 0,
    // Insert Pipeline register into response path
    parameter bit          RegisterRsp   = 0
) (
    input clk_i,
    input rst_ni,

    ACC_C_BUS acc_c_slv     [NumReq],
    ACC_C_BUS acc_c_mst_next[NumReq],
    ACC_C_BUS acc_c_mst     [NumRsp]
);

  localparam int unsigned AddrWidth = HierAddrWidth + AccAddrWidth;
  localparam int unsigned NumRs = TernaryOps ? 3 : 2;
  localparam int unsigned NumWb = DualWriteback ? 2 : 1;

  typedef logic [DataWidth-1:0]  data_t;
  typedef logic [AddrWidth-1:0]  addr_t;

  // This generates some unused typedefs. still cleaner than invoking macros
  // separately.
  `ACC_C_TYPEDEF_ALL(acc_c, addr_t, data_t, NumRs, NumWb)

  acc_c_req_t [NumReq-1:0] acc_c_slv_req;
  acc_c_rsp_t [NumReq-1:0] acc_c_slv_rsp;

  acc_c_req_t [NumReq-1:0] acc_c_mst_next_req;
  acc_c_rsp_t [NumReq-1:0] acc_c_mst_next_rsp;

  acc_c_req_t [NumRsp-1:0] acc_c_mst_req;
  acc_c_rsp_t [NumRsp-1:0] acc_c_mst_rsp;

  acc_interconnect #(
      .DataWidth        ( DataWidth        ),
      .HierAddrWidth    ( HierAddrWidth    ),
      .AccAddrWidth     ( AccAddrWidth     ),
      .HierLevel        ( HierLevel        ),
      .NumReq           ( NumReq           ),
      .NumRsp           ( NumRsp           ),
      .TernaryOps       ( TernaryOps       ),
      .DualWriteback    ( DualWriteback    ),
      .RegisterReq      ( RegisterReq      ),
      .RegisterRsp      ( RegisterRsp      ),
      .acc_c_req_t      ( acc_c_req_t      ),
      .acc_c_req_chan_t ( acc_c_req_chan_t ),
      .acc_c_rsp_t      ( acc_c_rsp_t      ),
      .acc_c_rsp_chan_t ( acc_c_rsp_chan_t )
  ) acc_interconnect_i (
      .clk_i                ( clk_i              ),
      .rst_ni               ( rst_ni             ),
      .acc_c_slv_req_i      ( acc_c_slv_req      ),
      .acc_c_slv_rsp_o      ( acc_c_slv_rsp      ),
      .acc_c_mst_next_req_o ( acc_c_mst_next_req ),
      .acc_c_mst_next_rsp_i ( acc_c_mst_next_rsp ),
      .acc_c_mst_req_o      ( acc_c_mst_req      ),
      .acc_c_mst_rsp_i      ( acc_c_mst_rsp      )
  );

  for (genvar i = 0; i < NumReq; i++) begin : gen_slv_interface_assignement
    `ACC_C_ASSIGN_TO_REQ(acc_c_slv_req[i], acc_c_slv[i])
    `ACC_C_ASSIGN_FROM_RESP(acc_c_slv[i], acc_c_slv_rsp[i])
  end
  for (genvar i = 0; i < NumRsp; i++) begin : gen_mst_interface_assignement
    `ACC_C_ASSIGN_FROM_REQ(acc_c_mst[i], acc_c_mst_req[i])
    `ACC_C_ASSIGN_TO_RESP(acc_c_mst_rsp[i], acc_c_mst[i])
  end
  for (genvar i = 0; i < NumReq; i++) begin : gen_mst_next_interface_assignement
    `ACC_C_ASSIGN_FROM_REQ(acc_c_mst_next[i], acc_c_mst_next_req[i])
    `ACC_C_ASSIGN_TO_RESP(acc_c_mst_next_rsp[i], acc_c_mst_next[i])
  end

endmodule
