// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Noam Gallmann <gnoam@live.com>
//
// Simulates one hierarchy level of the accelerator interconnect.

`include "acc_interface/assign.svh"
`include "acc_interface/typedef.svh"

module acc_interconnect_tb  #(
  parameter int NumHier         = 3,
  parameter int NumReq          = 8,
  parameter int NumRsp[NumHier] = '{3,5,9},
  parameter int HierLevel       = 1, // 0, .., NumHier-1
  parameter int DataWidth       = 32,
  parameter bit RegisterReq     = 1,
  parameter bit RegisterRsp     = 1,
  // TB params
  parameter int unsigned NrRandomTransactions = 1000
);

  // dependent parameters
  localparam int unsigned MaxNumRsp     = acc_pkg::maxn(NumRsp, NumHier);
  localparam int unsigned AccAddrWidth  = cf_math_pkg::idx_width(MaxNumRsp);
  localparam int unsigned HierAddrWidth = cf_math_pkg::idx_width(NumHier);
  localparam int unsigned AddrWidth     = AccAddrWidth + HierAddrWidth;


  typedef acc_test::c_req_t #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth )
  ) tb_mst_c_req_t;

  typedef acc_test::c_rsp_t #(
    .DataWidth ( DataWidth )
  ) tb_mst_c_rsp_t;

  typedef acc_test::c_req_t #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth )
  ) tb_slv_c_req_t;

  typedef acc_test::c_rsp_t #(
    .DataWidth ( DataWidth )
  ) tb_slv_c_rsp_t;

  // Timing params
  localparam time ClkPeriod = 10ns;
  localparam time ApplTime =  2ns;
  localparam time TestTime =  8ns;

  logic clk, rst_n;

  ACC_C_BUS #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth )
  ) master[NumReq] ();

  ACC_C_BUS_DV #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth )
  ) master_dv[NumReq] (
    clk
  );

  ACC_C_BUS #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth )
  ) slave_next[NumReq] ();

  ACC_C_BUS_DV #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth )
  ) slave_next_dv[NumReq] (
    clk
  );

  ACC_C_BUS #(
    .AddrWidth ( AddrWidth  ),
    .DataWidth ( DataWidth  )
  ) slave[NumRsp[HierLevel]] ();

  ACC_C_BUS_DV #(
    .AddrWidth ( AddrWidth  ),
    .DataWidth ( DataWidth  )
  ) slave_dv[NumRsp[HierLevel]](
    clk
  );

  for (genvar i = 0; i < NumReq; i++) begin : gen_mst_if_assignement
    `ACC_C_ASSIGN(master[i], master_dv[i])
  end

  for (genvar i = 0; i < NumReq; i++) begin : gen_mst_next_if_assignement
    `ACC_C_ASSIGN(slave_next_dv[i], slave_next[i])
  end

  for (genvar i = 0; i < NumRsp[HierLevel]; i++) begin : gen_slv_if_assignement
    `ACC_C_ASSIGN(slave_dv[i], slave[i])
  end

  // ----------------
  // Clock generation
  // ----------------
  initial begin
    rst_n = 0;
    repeat (3) begin
      #(ClkPeriod / 2) clk = 0;
      #(ClkPeriod / 2) clk = 1;
    end
    rst_n = 1;
    forever begin
      #(ClkPeriod / 2) clk = 0;
      #(ClkPeriod / 2) clk = 1;
    end
  end

  // -------
  // Monitor
  // -------
  typedef acc_test::acc_c_slv_monitor #(
    .DataWidth ( DataWidth ),
    .AddrWidth ( AddrWidth ),
    .NumReq    ( NumReq    ),
    .TA        ( ApplTime  ),
    .TT        ( TestTime  )
  ) acc_c_slv_monitor_t;

  typedef acc_test::acc_c_mst_monitor #(
    .DataWidth    ( DataWidth    ),
    .AddrWidth    ( AddrWidth    ),
    .AccAddrWidth ( AccAddrWidth ),
    .HierLevel    ( HierLevel    ),
    .TA           ( ApplTime     ),
    .TT           ( TestTime     )
  ) acc_c_mst_monitor_t;

  acc_c_mst_monitor_t acc_c_mst_monitor[NumReq];
  for (genvar i = 0; i < NumReq; i++) begin : gen_mst_mon
    initial begin
      acc_c_mst_monitor[i] = new(master_dv[i]);
      @(posedge rst_n);
      acc_c_mst_monitor[i].monitor();
    end
  end

  acc_c_slv_monitor_t acc_c_slv_monitor[NumRsp[HierLevel]];
  for (genvar i = 0; i < NumRsp[HierLevel]; i++) begin : gen_slv_mon
    initial begin
      acc_c_slv_monitor[i] = new(slave_dv[i]);
      @(posedge rst_n);
      acc_c_slv_monitor[i].monitor();
    end
  end

  acc_c_slv_monitor_t acc_c_fwd_slv_monitor[NumReq];
  for (genvar i = 0; i < NumReq; i++) begin : gen_fwd_slv_mon
    initial begin
      acc_c_fwd_slv_monitor[i] = new(slave_next_dv[i]);
      @(posedge rst_n);
      acc_c_fwd_slv_monitor[i].monitor();
    end
  end

  // ------
  // Driver
  // ------
  typedef acc_test::rand_c_slave #(
    .DataWidth ( DataWidth ),
    .AddrWidth ( AddrWidth ),
    .NumReq    ( NumReq    ),
    .TA        ( ApplTime  ),
    .TT        ( TestTime  )
  ) rand_c_slave_t;

  // Slaves connected to this interconnect level
  rand_c_slave_t rand_c_slave[NumRsp[HierLevel]];
  for (genvar i = 0; i < NumRsp[HierLevel]; i++) begin : gen_slv_driver
    initial begin
      rand_c_slave[i] = new(slave_dv[i]);
      rand_c_slave[i].reset();
      @(posedge rst_n);
      rand_c_slave[i].run();
    end
  end

  // Slaves conected to higher interconnect levels
  rand_c_slave_t rand_c_fwd_slave[NumReq];
  for (genvar i = 0; i < NumReq; i++) begin : gen_c_slv_fwd_driver
    initial begin
      rand_c_fwd_slave[i] = new(slave_next_dv[i]);
      rand_c_fwd_slave[i].reset();
      @(posedge rst_n);
      rand_c_fwd_slave[i].run();
    end
  end

  typedef acc_test::rand_c_master #(
    .DataWidth    ( DataWidth    ),
    .AccAddrWidth ( AccAddrWidth ),
    .AddrWidth    ( AddrWidth    ),
    .NumRsp       ( NumRsp       ),
    .NumHier      ( NumHier      ),
    .HierLevel    ( HierLevel    ),
    .TA           ( ApplTime     ),
    .TT           ( TestTime     )
  ) rand_c_master_t;

  rand_c_master_t rand_c_master[NumReq];

  for (genvar i = 0; i < NumReq; i++) begin : gen_c_master
    initial begin
      automatic acc_test::rand_hart_id hid = new;
      assert(hid.randomize());
      rand_c_master[i] = new(master_dv[i], hid.hart_id);
      rand_c_master[i].reset();
      @(posedge rst_n);
      rand_c_master[i].run(NrRandomTransactions);
    end
  end

  // ----------
  // Scoreboard
  // ----------
  //
  // Request Path
  // ------------
  // Try to map each request observed at the output to a request generated at
  // an input port.
  initial begin
    automatic int nr_requests = 0;
    @(posedge rst_n);
    for (int kk = 0; kk < NumReq; kk++) begin  // masters k
      automatic int k = kk;
      fork
        // Check requests to same-level slaves
        for (int ii = 0; ii < NumRsp[HierLevel]; ii++) begin  // slaves i
          fork
            automatic int i = ii;
            forever begin : check_req_path
              automatic tb_mst_c_req_t req_mst;
              automatic tb_slv_c_req_t req_slv;
              automatic tb_slv_c_req_t req_slv_all[NumReq];
              automatic int sender_id = -1;
              acc_c_slv_monitor[i].req_mbx_cnt.get_direct(req_slv, k);
              for (int l = 0; l < NumReq; l++) begin
                if (rand_c_master[l].drv.hart_id == req_slv.hart_id) begin
                  sender_id = l;
                  acc_c_mst_monitor[l].req_mbx[i].get(req_mst);
                end
              end
              assert (sender_id >= 0) else
                $error("Request Routing Error: C Slave %0d", i,
                    "Could not determine origin of C request");
              assert(req_mst.do_compare(req_slv)) else
                $error("Request Mismatch: C master %0d to C slave %0d", k, i);
              // check that request was intended for slave i
              assert(req_mst.addr[AccAddrWidth-1:0] == i) else
                $error("Request Routing Error: C Master %0d", sender_id);
              nr_requests++;
            end  // -- forever
          join_none
        end  // -- for (int i=0; i<NumRsp[HierLevel]; i++)

        // Check forwarded requests
        fork
          forever begin : check_req_path
            automatic tb_mst_c_req_t req_mst;
            automatic tb_mst_c_req_t req_slv_fwd;
            // Master k has sent interconnect forward port k
            // Check that slave k has received.
            acc_c_fwd_slv_monitor[k].req_mbx_cnt.get_direct(req_slv_fwd, 0);
            acc_c_mst_monitor[k].req_mbx_fwd.get(req_mst);
            assert(req_mst.do_compare(req_slv_fwd)) else
              $error("Forwarded Request Mismatch: C Master %0d", k);
            nr_requests++;
          end  // -- forever
        join_none
      join_none
    end
  end

  // Map each reponse observed at the output to a response generated at the input port.
  initial begin
    automatic int unsigned nr_responses = 0;
    @(posedge rst_n);
    for (int jj = 0; jj < NumReq; jj++) begin
      fork
        automatic int j = jj;
        forever begin
          automatic tb_mst_c_rsp_t rsp_mst;
          automatic tb_mst_c_rsp_t rsp_slv_fwd;
          automatic bit rsp_sender_found = 0;
          acc_c_mst_monitor[j].rsp_mbx.get(rsp_mst);
          nr_responses++;
          // Check this interconnect level
          for (int l = 0; l < NumRsp[HierLevel]; l++) begin
            if (acc_c_slv_monitor[l].rsp_mbx_cnt.num(rsp_mst.hart_id) != 0) begin
              automatic tb_slv_c_rsp_t rsp_slv;
              acc_c_slv_monitor[l].rsp_mbx_cnt.peek(rsp_slv, rsp_mst.hart_id);
              if (rsp_mst.do_compare(rsp_slv)) begin
                acc_c_slv_monitor[l].rsp_mbx_cnt.get(rsp_slv, rsp_mst.hart_id);
                rsp_sender_found |= 1;
                break;
              end
            end
          end
          // Check forwarded responses from upper interconnect levels.
          if (acc_c_fwd_slv_monitor[j].rsp_mbx_cnt.num(rsp_mst.hart_id) != 0) begin
            acc_c_fwd_slv_monitor[j].rsp_mbx_cnt.peek(rsp_slv_fwd, rsp_mst.hart_id);
            if (rsp_mst.do_compare(rsp_slv_fwd)) begin
              acc_c_fwd_slv_monitor[j].rsp_mbx_cnt.get(rsp_slv_fwd, rsp_mst.hart_id);
              rsp_sender_found |= 1;
            end
          end

          assert(rsp_sender_found) else
            $error("Master %0d: Received response but no Sender found", j);
          if (nr_responses == NumReq * NrRandomTransactions) $finish;
        end
      join_none
    end
  end


  final begin
    for (int i = 0; i < NumReq; i++) begin
      assert(acc_c_mst_monitor[i].rsp_mbx.num() == 0);
      assert(acc_c_mst_monitor[i].req_mbx_fwd.num() == 0);
      assert(acc_c_fwd_slv_monitor[i].req_mbx_cnt.empty());
      assert(acc_c_fwd_slv_monitor[i].rsp_mbx_cnt.empty());
      for (int j = 0; j < NumRsp[HierLevel]; j++) begin
        assert(acc_c_mst_monitor[i].req_mbx[j].num() == 0);
        assert(acc_c_slv_monitor[j].req_mbx_cnt.empty());
        assert(acc_c_slv_monitor[j].rsp_mbx_cnt.empty());
      end
    end
    $display("Checked for non-empty mailboxes.");
  end

  acc_interconnect_intf #(
    .DataWidth     ( DataWidth         ),
    .HierAddrWidth ( HierAddrWidth     ),
    .AccAddrWidth  ( AccAddrWidth      ),
    .HierLevel     ( HierLevel         ),
    .NumReq        ( NumReq            ),
    .NumRsp        ( NumRsp[HierLevel] ),
    .RegisterReq   ( RegisterReq       ),
    .RegisterRsp   ( RegisterRsp       )
  ) dut (
    .clk_i          ( clk        ),
    .rst_ni         ( rst_n      ),
    .acc_c_mst_next ( slave_next ),
    .acc_c_mst      ( slave      ),
    .acc_c_slv      ( master     )
  );

endmodule
