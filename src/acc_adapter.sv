// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Noam Gallmann <gnoam@live.com>

// Adapter between acc-agnostic offloading X-interface and accelerator
// C-interface

`include "acc_interface/assign.svh"
`include "acc_interface/typedef.svh"

module acc_adapter #(
    // ISA bit width.
    parameter int unsigned DataWidth        = 32,
    // Number of Hierarchy Levels
    parameter int          NumHier          = 3,
    // Number of Respondesr per hierarchy level
    parameter int          NumRsp [NumHier] = '{4, 2, 2},
    // Support for ternary operations (use rs3)
    parameter bit          TernaryOps       = 0,
    // Support for dual-writeback instructions
    parameter bit          DualWriteback    = 0,
    // C Request Type
    parameter type         acc_c_req_t      = logic,
    // C Request Payload Type
    parameter type         acc_c_req_chan_t = logic,
    // C Response Type
    parameter type         acc_c_rsp_t      = logic,
    // X Request Type
    parameter type         acc_x_req_t      = logic,
    // X Response Type
    parameter type         acc_x_rsp_t      = logic,
    // CMEM Request Type
    parameter type acc_cmem_req_t       = logic,
    // CMEM Response Type
    parameter type acc_cmem_rsp_t       = logic,
    // XMEM Request Type
    parameter type acc_xmem_req_t       = logic,
    // XMEM Response Type
    parameter type acc_xmem_rsp_t       = logic,

    // Dependent parameter DO NOT OVERRIDE
    parameter int          NumRspTot                 = acc_pkg::sumn(NumRsp, NumHier)
) (
    input clk_i,
    input rst_ni,

    input logic [DataWidth-1:0] hart_id_i,

    input  acc_x_req_t acc_x_req_i,
    output acc_x_rsp_t acc_x_rsp_o,

    output acc_c_req_t acc_c_req_o,
    input  acc_c_rsp_t acc_c_rsp_i,

    output acc_xmem_req_t acc_xmem_req_o,
    input  acc_xmem_rsp_t acc_xmem_rsp_i,

    input  acc_cmem_req_t acc_cmem_req_i,
    output acc_cmem_rsp_t acc_cmem_rsp_o,

    output acc_pkg::acc_prd_req_t [NumRspTot-1:0] acc_prd_req_o,
    input  acc_pkg::acc_prd_rsp_t [NumRspTot-1:0] acc_prd_rsp_i

    /*
    // To compressed predecoders: -- integrate into predecoders
    // TODO
    input  logic [31:0] instr_rdata_if_i,
    output logic [31:0] instr_if_exp_o,
    output logic        instr_if_exp_valid_o,
    */
);

  /*
  // TODO: Compressed Decoders
  logic [31:0] unused_instr_rdata_if_i;
  assign unused_instr_rdata_if_i = instr_rdata_if_i;
  assign instr_if_exp_valid_o = 1'b0;
  assign instr_if_exp_o = '0;
  */

  import acc_pkg::*;
  localparam int unsigned MaxNumRsp = maxn(NumRsp, NumHier);
  localparam int unsigned HierAddrWidth = cf_math_pkg::idx_width(NumHier);
  localparam int unsigned AccAddrWidth = cf_math_pkg::idx_width(MaxNumRsp);
  localparam int unsigned AddrWidth = HierAddrWidth + AccAddrWidth;
  localparam int unsigned NumRs = TernaryOps ? 3 : 2;
  localparam int unsigned NumWb = DualWriteback ? 2 : 1;

  logic [NumRspTot-1:0][NumRs-1:0][31:0] acc_op;

  // Instruction data
  logic [31:0] instr_rdata_id;
  logic [ 4:0] instr_rd;
  logic [ 2:0] use_rs;

  // Core status signals
  logic sources_valid;
  logic rd_clean;

  // Address encoding signals
  logic [HierAddrWidth-1:0]                   hier_addr;
  logic [      NumHier-1:0][AccAddrWidth-1:0] acc_addr;
  logic [      NumHier-1:0]                   hier_onehot;
  logic [    NumRspTot-1:0]                   predecoder_accept_onehot;
  logic [      NumHier-1:0][   MaxNumRsp-1:0] predecoder_accept_lvl;

  logic            acc_c_req_fifo_ready;
  logic            acc_c_req_fifo_valid;
  acc_c_req_chan_t acc_c_req_fifo_req;

  ///////////////////////////////
  // Memory Request Forwarding //
  ///////////////////////////////

  logic acc_cmem_addr_reg_in_ready;
  logic acc_cmem_addr_reg_in_valid;
  logic acc_cmem_addr_reg_out_valid;
  logic acc_cmem_addr_reg_out_ready;

  // CMem to XMem Request
  assign acc_xmem_req_o.q.laddr            = acc_cmem_req_i.q.laddr;
  assign acc_xmem_req_o.q.wdata            = acc_cmem_req_i.q.wdata;
  assign acc_xmem_req_o.q.width            = acc_cmem_req_i.q.width;
  assign acc_xmem_req_o.q.req_type         = acc_cmem_req_i.q.req_type;
  assign acc_xmem_req_o.q.mode             = acc_cmem_req_i.q.mode;
  assign acc_xmem_req_o.q.endoftransaction = acc_cmem_req_i.q.endoftransaction;
  assign acc_xmem_req_o.q.spec             = acc_cmem_req_i.q.spec;
  assign acc_xmem_req_o.q_valid            = acc_cmem_req_i.q_valid && acc_cmem_addr_reg_in_ready;
  assign acc_cmem_rsp_o.q_ready            = acc_xmem_rsp_i.q_ready && acc_cmem_addr_reg_in_ready;

  // XMem to CMem Response
  assign acc_cmem_rsp_o.p.rdata  = acc_xmem_rsp_i.p.rdata;
  assign acc_cmem_rsp_o.p.range  = acc_xmem_rsp_i.p.range;
  assign acc_cmem_rsp_o.p.status = acc_xmem_rsp_i.p.status;
  assign acc_cmem_rsp_o.p_valid  = acc_xmem_rsp_i.p_valid && acc_cmem_addr_reg_out_valid;
  assign acc_xmem_req_o.p_ready  = acc_cmem_req_i.p_ready;

  // Routing signals
  assign acc_cmem_rsp_o.p.hart_id = hart_id_i;

  // Address register
  assign acc_cmem_addr_reg_in_valid  = acc_cmem_req_i.q_valid && acc_xmem_rsp_i.q_ready;
  assign acc_cmem_addr_reg_out_ready = acc_cmem_req_i.p_ready && acc_xmem_rsp_i.p_valid;

  stream_register #(
      .T ( logic[AddrWidth-1:0] )
  ) acc_cmem_addr_reg_i (
      .clk_i      ( clk_i                       ),
      .rst_ni     ( rst_ni                      ),
      .clr_i      ( 1'b0                        ),
      .testmode_i ( 1'b0                        ),
      .valid_i    ( acc_cmem_addr_reg_in_valid  ),
      .ready_o    ( acc_cmem_addr_reg_in_ready  ),
      .data_i     ( acc_cmem_req_i.q.addr       ),
      .valid_o    ( acc_cmem_addr_reg_out_valid ),
      .ready_i    ( acc_cmem_addr_reg_out_ready ),
      .data_o     ( acc_cmem_rsp_o.p.addr       )
  );

  ////////////////////////
  // Instruction Parser //
  ////////////////////////

  // Instruction data
  assign instr_rdata_id = acc_x_req_i.q.instr_data;

  // Destination register
  assign instr_rd = instr_rdata_id[11:7];

  // operand muxes
  for (genvar i = 0; i < NumRspTot; i++) begin : gen_op_mux
    always_comb begin
      acc_op[i] = '0;
      if (predecoder_accept_onehot[i]) begin
        for (int unsigned j = 0; j < NumRs; j++) begin
          acc_op[i][j] = acc_prd_rsp_i[i].p_use_rs[j] ? acc_x_req_i.q.rs[j] : '0;
        end
      end
    end
  end

  /////////////////////
  // Address Encoder //
  /////////////////////

  // Predecoder signals to onehot array
  for (genvar i = 0; i < NumRspTot; i++) begin : gen_acc_predecoder_sig_assign
    assign predecoder_accept_onehot[i]   = acc_prd_rsp_i[i].p_accept;
    assign acc_prd_req_o[i].q_instr_data = acc_x_req_i.q.instr_data;
  end

  // The first NumRsp[0] requests go to level 0
  // The next NumRsp[1] requests go to level 1
  // ...
  //
  for (genvar i = 0; i < NumHier; i++) begin : gen_acc_addr
    localparam int unsigned SumNumRsp = sumn(NumRsp, i);
    logic [NumRspTot-1:0] shift_predecoder_accept;

    assign shift_predecoder_accept = predecoder_accept_onehot >> SumNumRsp;
    assign predecoder_accept_lvl[i] = {
      {MaxNumRsp - NumRsp[i]{1'b0}}, shift_predecoder_accept[NumRsp[i]-1:0]
    };

    // Accelerator address encoder
    onehot_to_bin #(
        .ONEHOT_WIDTH ( MaxNumRsp )
    ) acc_addr_enc_i (
        .onehot ( predecoder_accept_lvl[i] ),
        .bin    ( acc_addr[i]              )
    );
    // Hierarchy level selsect
    assign hier_onehot[i] = |predecoder_accept_lvl[i][NumRsp[i]-1:0];
  end

  // Hierarchy level encoder
  onehot_to_bin #(
      .ONEHOT_WIDTH ( NumHier )
  ) hier_addr_enc_i (
      .onehot ( hier_onehot ),
      .bin    ( hier_addr   )
  );

  /////////////////////////////
  // Assemble Request Struct //
  /////////////////////////////

  // Address
  logic [AccAddrWidth-1:0] addr_lsb;
  always_comb begin
    addr_lsb = '0;
    for (int i = 0; i < NumHier; i++) begin
      addr_lsb |= acc_addr[i];
    end
  end

  assign acc_c_req_fifo_req.addr    = {hier_addr, addr_lsb};
  assign acc_c_req_fifo_req.hart_id = hart_id_i;

  // Operands
  always_comb begin
    acc_c_req_fifo_req.rs   = '0;
    use_rs                  = '0;
    acc_x_rsp_o.k.writeback = '0;
    for (int unsigned i = 0; i < NumRspTot; i++) begin
      for (int unsigned j = 0; j < NumRs; j++) begin
        acc_c_req_fifo_req.rs[j] |= predecoder_accept_onehot[i] ? acc_op[i][j] : '0;
      end
      use_rs |= predecoder_accept_onehot[i] ? acc_prd_rsp_i[i].p_use_rs : '0;
      acc_x_rsp_o.k.writeback |=
          predecoder_accept_onehot[i] ? acc_prd_rsp_i[i].p_writeback[NumWb-1:0] : '0;
      acc_x_rsp_o.k.is_mem_op |=
          predecoder_accept_onehot[i] ? acc_prd_rsp_i[i].p_is_mem_op : '0;
    end
  end

  if (!TernaryOps) begin : gen_no_ternaryops
    logic unused_use_rs3;
    assign unused_use_rs3 = use_rs[2];
  end

  if (!DualWriteback) begin : gen_no_dualwb
    for (genvar i = 0; i < NumRspTot; i++) begin : gen_no_dualwb_tieoff
      logic unused_writeback;
      assign unused_writeback = acc_prd_rsp_i[i].p_writeback[1];
    end
  end

  // Instruction Data
  assign acc_c_req_fifo_req.instr_data = instr_rdata_id;

  //////////////////
  // Flow Control //
  //////////////////

  // All source registers are ready if use_rs[i] == rs_valid[i] or ~use_rs[i];
  assign sources_valid = ((use_rs ~^ acc_x_req_i.q.rs_valid) | ~use_rs) == '1;
  // Destination registers are clean, if writeback expeted. (WAW-hazard)
  assign rd_clean =
      ((acc_x_rsp_o.k.writeback ~^ acc_x_req_i.q.rd_clean) | ~acc_x_rsp_o.k.writeback) == '1;

  assign acc_x_rsp_o.k.accept = |predecoder_accept_onehot;
  assign acc_c_req_fifo_valid =
    acc_x_req_i.q_valid && sources_valid  && rd_clean && |predecoder_accept_onehot;
  assign acc_x_rsp_o.q_ready  =
    ~acc_x_rsp_o.k.accept || (sources_valid  && rd_clean && acc_c_req_fifo_ready);

  // Forward accelerator response
  assign acc_x_rsp_o.p.data   = acc_c_rsp_i.p.data;
  assign acc_x_rsp_o.p.error  = acc_c_rsp_i.p.error;
  assign acc_x_rsp_o.p.rd     = acc_c_rsp_i.p.rd;
  assign acc_x_rsp_o.p.dualwb = acc_c_rsp_i.p.dualwb;
  assign acc_x_rsp_o.p_valid  = acc_c_rsp_i.p_valid;
  assign acc_c_req_o.p_ready  = acc_x_req_i.p_ready;


  ///////////////////////////
  // C Request Output Fifo //
  ///////////////////////////

  // To acc interconnect.
  stream_fifo #(
      .FALL_THROUGH ( 1'b1             ),
      .DEPTH        ( 1                ),
      .T            ( acc_c_req_chan_t )
  ) acc_c_req_out_reg (
      .clk_i      ( clk_i                ),
      .rst_ni     ( rst_ni               ),
      .flush_i    ( 1'b0                 ),
      .testmode_i ( 1'b0                 ),
      .valid_i    ( acc_c_req_fifo_valid ),
      .ready_o    ( acc_c_req_fifo_ready ),
      .data_i     ( acc_c_req_fifo_req   ),
      .valid_o    ( acc_c_req_o.q_valid  ),
      .ready_i    ( acc_c_rsp_i.q_ready  ),
      .data_o     ( acc_c_req_o.q        ),
      .usage_o    ( /* unused */         )
  );

  // Sanity Checks
  // pragma translate_off
`ifndef VERILATOR
  assert property (@(posedge clk_i) $onehot0(predecoder_accept_onehot)) else
      $error("Multiple accelerators accepeting request");
  assert property (@(posedge clk_i) (acc_x_req_i.q_valid && !acc_x_rsp_o.q_ready)
                                    |=> $stable(instr_rdata_id)) else
      $error ("instr_rdata_id is unstable");
  assert property (@(posedge clk_i) (acc_x_req_i.q_valid && !acc_x_rsp_o.q_ready)
                                    |=> acc_x_req_i.q_valid) else
      $error("acc_x_req_i.q_valid has been taken away without a ready");
  assert property (@(posedge clk_i)
      (acc_x_req_i.q_valid && acc_x_rsp_o.q_ready && acc_x_rsp_o.k.accept) |-> sources_valid) else
      $error("accepted offload request with invalid source registers");
  assert property (@(posedge clk_i) (acc_c_rsp_i.p_valid && acc_c_req_o.p_ready)
                                    |-> acc_c_rsp_i.p.hart_id == hart_id_i ) else
      $error("Response routing error");
  if (!TernaryOps) begin : gen_no_ternaryops_assert
    assert property (@(posedge clk_i) (acc_c_rsp_i.p_valid && acc_c_req_o.p_ready)
                                     |-> (use_rs[2] == 1'b0)) else
        $error("Unsupported ternary instruction encountered. Set TernaryOps = 1");
  end
  if (!DualWriteback) begin : gen_no_dualwb_assert
    for (genvar i = 0; i < NumRspTot; i++) begin : gen_no_dualwb_prd_assert
      assert property (@(posedge clk_i) (acc_c_rsp_i.p_valid && acc_c_req_o.p_ready)
                                       |-> (acc_prd_rsp_i[i].p_writeback[1] == 1'b0)) else
          $error("Unsupported dual-writeback instruction encountered (Predecoder %0d).", i,
                 "Set DualWriteback = 1");
    end
  end
`endif
  // pragma translate_on

endmodule

module acc_adapter_intf #(
    parameter int DataWidth          = 32,
    parameter int NumHier            = 3,
    parameter int NumRsp   [NumHier] = '{4, 2, 2},
    parameter bit TernaryOps         = 0,
    parameter bit DualWriteback      = 0,
    // Dependent parameter DO NOT OVERRIDE
    parameter int NumRspTot          = acc_pkg::sumn(NumRsp, NumHier)
) (
    input clk_i,
    input rst_ni,

    input logic [DataWidth-1:0] hart_id_i,

    ACC_X_BUS    acc_x_mst,
    ACC_C_BUS    acc_c_slv,
    ACC_XMEM_BUS acc_xmem_slv,
    ACC_CMEM_BUS acc_cmem_mst,
    ACC_PRD_BUS  acc_prd_mst[NumRspTot]
);
  import acc_pkg::*;

  localparam int unsigned MaxNumRsp = maxn(NumRsp, NumHier);
  localparam int unsigned HierAddrWidth = cf_math_pkg::idx_width(NumHier);
  localparam int unsigned AccAddrWidth = cf_math_pkg::idx_width(MaxNumRsp);
  localparam int unsigned AddrWidth = HierAddrWidth + AccAddrWidth;
  localparam int unsigned NumRs = TernaryOps ? 3 : 2;
  localparam int unsigned NumWb = DualWriteback ? 2 : 1;

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;

  `ACC_X_TYPEDEF_ALL(acc_x, data_t, NumRs, NumWb)
  `ACC_C_TYPEDEF_ALL(acc_c, addr_t, data_t, NumRs, NumWb)
  `ACC_CMEM_TYPEDEF_ALL(acc_cmem, addr_t, data_t)
  `ACC_XMEM_TYPEDEF_ALL(acc_xmem, data_t)

  acc_prd_req_t [NumRspTot-1:0] acc_prd_req;
  acc_prd_rsp_t [NumRspTot-1:0] acc_prd_rsp;

  acc_x_req_t acc_x_req;
  acc_x_rsp_t acc_x_rsp;
  acc_c_req_t acc_c_req;
  acc_c_rsp_t acc_c_rsp;

  acc_xmem_req_t acc_xmem_req;
  acc_xmem_rsp_t acc_xmem_rsp;
  acc_cmem_req_t acc_cmem_req;
  acc_cmem_rsp_t acc_cmem_rsp;

  acc_adapter #(
      .DataWidth        ( DataWidth        ),
      .NumHier          ( NumHier          ),
      .NumRsp           ( NumRsp           ),
      .TernaryOps       ( TernaryOps       ),
      .DualWriteback    ( DualWriteback    ),
      .acc_c_req_t      ( acc_c_req_t      ),
      .acc_c_req_chan_t ( acc_c_req_chan_t ),
      .acc_c_rsp_t      ( acc_c_rsp_t      ),
      .acc_x_req_t      ( acc_x_req_t      ),
      .acc_x_rsp_t      ( acc_x_rsp_t      ),
      .acc_cmem_req_t   ( acc_cmem_req_t   ),
      .acc_cmem_rsp_t   ( acc_cmem_rsp_t   ),
      .acc_xmem_req_t   ( acc_xmem_req_t   ),
      .acc_xmem_rsp_t   ( acc_xmem_rsp_t   )
  ) acc_adapter_i (
      .clk_i          ( clk_i        ),
      .rst_ni         ( rst_ni       ),
      .hart_id_i      ( hart_id_i    ),
      .acc_x_req_i    ( acc_x_req    ),
      .acc_x_rsp_o    ( acc_x_rsp    ),
      .acc_c_req_o    ( acc_c_req    ),
      .acc_c_rsp_i    ( acc_c_rsp    ),
      .acc_xmem_req_o ( acc_xmem_req ),
      .acc_xmem_rsp_i ( acc_xmem_rsp ),
      .acc_cmem_req_i ( acc_cmem_req ),
      .acc_cmem_rsp_o ( acc_cmem_rsp ),
      .acc_prd_req_o  ( acc_prd_req  ),
      .acc_prd_rsp_i  ( acc_prd_rsp  )
  );

  `ACC_C_ASSIGN_FROM_REQ(acc_c_slv, acc_c_req)
  `ACC_C_ASSIGN_TO_RESP(acc_c_rsp, acc_c_slv)

  `ACC_X_ASSIGN_TO_REQ(acc_x_req, acc_x_mst)
  `ACC_X_ASSIGN_FROM_RESP(acc_x_mst, acc_x_rsp)

  `ACC_CMEM_ASSIGN_TO_REQ(acc_cmem_req, acc_cmem_mst)
  `ACC_CMEM_ASSIGN_FROM_RESP(acc_cmem_mst, acc_cmem_rsp)

  `ACC_XMEM_ASSIGN_FROM_REQ(acc_xmem_slv, acc_xmem_req)
  `ACC_XMEM_ASSIGN_TO_RESP(acc_xmem_rsp, acc_xmem_slv)

  for (genvar i = 0; i < NumRspTot; i++) begin : gen_acc_predecoder_intf_assign
    `ACC_PRD_ASSIGN_FROM_REQ(acc_prd_mst[i], acc_prd_req[i])
    `ACC_PRD_ASSIGN_TO_RESP(acc_prd_rsp[i], acc_prd_mst[i])
  end

endmodule
