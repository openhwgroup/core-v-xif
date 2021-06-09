// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Noam Gallmann <gnoam@live.com>

`include "acc_interface/typedef.svh"

package acc_pkg;
  /////////////////////////////////
  // Global Interface Parameters //
  /////////////////////////////////

  // ISA bit width.
  parameter int DataWidth             = 32;
  // Number of interconnect hierarchy levels
  parameter int NumHier               = 3;
  // Number of responders per hierarchy level
  parameter int NumRsp[NumHier]       = '{4,2,2};
  // Support for ternary operations
  parameter bit TernaryOps            = 1'b1;
  // Support for dual writeback instructions
  parameter bit DualWriteback         = 1'b0;
  // Insert pipeline stage at hierarchy level X, request path
  parameter bit RegisterReq [NumHier] = '{0,0,0};
  // Insert pipeline stage at hierarchy level X, response path
  parameter bit RegisterRsp [NumHier] = '{0,0,0};

  //////////////////////
  // Helper Functions //
  //////////////////////

  // Helper Functions for dependent parameter definitions.
  // build-tin array functions (e.g.  'arr.sum()') return queue type which
  // is not considered constant for use as synthesis-time parameter.

  // Dynamic Arrays currently unsupported by Verilator. (verilator/#2846)
  // General definition `function automatic int maxn (int arr[], int n );`
  // not possible.
  //
  // TODO: put in cf_math_pkg or something? Is there a SV-function that does
  // this?

  // Max value in array arr, up to element n-1
  function automatic int  maxn(int arr[NumHier], int n);
    automatic int res = 0;
    if (n > 0) begin
      for (int i = 0; i < n; i++) begin
        if (i == 0) res = arr[0];
        if (res < arr[i]) res = arr[i];
      end
    end
    return res;
  endfunction

  // Sum of array entries up to element n-1.
  function automatic int sumn(int arr[NumHier], int n);
    automatic int res = 0;
    if (n > 0) begin
      for (int i = 0; i < n; i++) begin
        res = res + arr[i];
      end
    end
    return res;
  endfunction

  ////////////////////////////////////
  // Dependent Interface Parameters //
  ////////////////////////////////////

  // Total number of connected accelerators
  parameter int unsigned NumRspTot = sumn(NumRsp, NumHier);
  // Maximum number of accelerators per sharing level
  parameter int unsigned MaxNumRsp = maxn(NumRsp, NumHier);
  // Hierarchy address width
  parameter int unsigned HierAddrWidth = cf_math_pkg::idx_width(NumHier);
  // Per-level accelerator addresss width
  parameter int unsigned AccAddrWidth = cf_math_pkg::idx_width(MaxNumRsp);
  // Total Address Width
  parameter int unsigned AddrWidth = HierAddrWidth + AccAddrWidth;
  // Number of source regs
  parameter int unsigned NumRs = TernaryOps ? 3 : 2;
  // Number of simultaneous writebacks.
  parameter int unsigned NumWb = DualWriteback ? 2 : 1;

  ////////////////////////
  // Interface Typedefs //
  ////////////////////////

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [         31:0] data_t;

  typedef enum logic [1:0] {
  READ     = 2'b00,
  WRITE    = 2'b01,
  EXECUTE  = 2'b10
  } mem_req_type_e;

  // Interface Typedefs
  `ACC_C_TYPEDEF_ALL(acc_c, addr_t, data_t, NumRs, NumWb)
  `ACC_X_TYPEDEF_ALL(acc_x, data_t, NumRs, NumWb)
  `ACC_CMEM_TYPEDEF_ALL(acc_cmem, addr_t, data_t, mem_req_type_e)
  `ACC_XMEM_TYPEDEF_ALL(acc_xmem, data_t, mem_req_type_e)

  // Predecoder response type
  typedef struct packed {
    logic       p_accept;
    logic       p_is_mem_op;
    logic [1:0] p_writeback;
    logic [2:0] p_use_rs;
  } acc_prd_rsp_t;

  // Predecoder request type
  typedef struct packed {
    logic [31:0] q_instr_data;
  } acc_prd_req_t;

  // Predecoder internal instruction metadata
  typedef struct packed {
    logic [31:0]  instr_data;
    logic [31:0]  instr_mask;
    acc_prd_rsp_t prd_rsp;
  } offload_instr_t;

endpackage
