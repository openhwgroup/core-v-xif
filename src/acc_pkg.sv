// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Noam Gallmann <gnoam@live.com>

package acc_pkg;
  // TODO: define common cluster parameters in package (Total number of
  // responders / requesters per level)


  // Helper Functions for *constant* localparam definitions.
  // array functions (e.g.  'arr.sum()') return queue type which is not
  // considered constant for use as synthesis-time parameter.

  // TODO: put in cf_math_pkg or something? Is there a SV-function that does
  // this?
  //
  function automatic int max(int a, int b);
    return a > b ? a : b;
  endfunction

  // Max value in array arr, up to element n-1
  function automatic int maxn(int arr[], int n);
    return n == 0 ? 0 : (n == 1 ? arr[0] : max(arr[n-1], maxn(arr, n - 1)));
  endfunction

  function automatic int sum(int a, int b);
    return a + b;
  endfunction

  // Sum of array entries up to element n-1.
  function automatic int sumn(int arr[], int n);
    return n == 0 ? 0 : (n == 1 ? arr[0] : sum(arr[n-1], sumn(arr, n - 1)));
  endfunction

  /////////////////////////
  // Predecoder Typedefs //
  /////////////////////////

  // Response type
  typedef struct packed {
    logic       p_accept;
    logic       p_is_mem_op;
    logic [1:0] p_writeback;
    logic [2:0] p_use_rs;
  } acc_prd_rsp_t;

  // Request type
  typedef struct packed {
    logic [31:0] q_instr_data;
  } acc_prd_req_t;

  // Internal instruction metadata
  typedef struct packed {
    logic [31:0]  instr_data;
    logic [31:0]  instr_mask;
    acc_prd_rsp_t prd_rsp;
  } offload_instr_t;

endpackage
