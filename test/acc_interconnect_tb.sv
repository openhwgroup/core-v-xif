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
  parameter bit RegisterReq     = 0,
  parameter bit RegisterRsp     = 0,
  // TB params
  parameter int unsigned NrRandomTransactions = 10
);

  // dependent parameters
  localparam int unsigned MaxNumRsp     = acc_pkg::maxn(NumRsp, NumHier);
  localparam int unsigned AccAddrWidth  = cf_math_pkg::idx_width(MaxNumRsp);
  localparam int unsigned HierAddrWidth = cf_math_pkg::idx_width(NumHier);
  localparam int unsigned AddrWidth     = AccAddrWidth + HierAddrWidth;
  localparam int unsigned ExtIdWidth    = 1+ cf_math_pkg::idx_width(NumReq);


  typedef acc_test::c_req_t # (
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth ),
    .IdWidth   ( 1         )
  ) tb_mst_c_req_t;

  typedef acc_test::c_rsp_t # (
    .DataWidth ( DataWidth ),
    .IdWidth   ( 1         )
  ) tb_mst_c_rsp_t;

  typedef acc_test::c_req_t # (
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth ),
    .IdWidth   ( ExtIdWidth  )
  ) tb_slv_c_req_t;

  typedef acc_test::c_rsp_t # (
    .DataWidth    ( DataWidth  ),
    .IdWidth      ( ExtIdWidth )
  ) tb_slv_c_rsp_t;

  // Timing params
  localparam time ClkPeriod = 10ns;
  localparam time ApplTime =  2ns;
  localparam time TestTime =  8ns;

  logic clk, rst_n;

  ACC_C_BUS #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth ),
    .IdWidth   ( 1         )
  ) master [NumReq] ();

  ACC_C_BUS_DV #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth ),
    .IdWidth   ( 1         )
  ) master_dv [NumReq] (clk);

  ACC_C_BUS #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth ),
    .IdWidth   ( 1         )
  ) slave_next [NumReq] ();

  ACC_C_BUS_DV #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth ),
    .IdWidth   ( 1         )
  ) slave_next_dv [NumReq] (clk);

  ACC_C_BUS #(
    .AddrWidth ( AddrWidth  ),
    .DataWidth ( DataWidth  ),
    .IdWidth   ( ExtIdWidth )
  ) slave [NumRsp[HierLevel]] ();

  ACC_C_BUS_DV #(
    .AddrWidth ( AddrWidth  ),
    .DataWidth ( DataWidth  ),
    .IdWidth   ( ExtIdWidth )
  ) slave_dv [NumRsp[HierLevel]] (clk);

  for (genvar i=0; i<NumReq; i++) begin : gen_mst_if_assignement
    `ACC_C_ASSIGN(master[i], master_dv[i])
  end

  for (genvar i=0; i<NumReq; i++) begin : gen_mst_next_if_assignement
    `ACC_C_ASSIGN(slave_next_dv[i], slave_next[i])
  end

  for (genvar i=0; i<NumRsp[HierLevel]; i++) begin : gen_slv_if_assignement
    `ACC_C_ASSIGN(slave_dv[i], slave[i])
  end

  // ----------------
  // Clock generation
  // ----------------
  initial begin
    rst_n = 0;
    repeat (3) begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
    rst_n = 1;
    forever begin
      #(ClkPeriod/2) clk = 0;
      #(ClkPeriod/2) clk = 1;
    end
  end

  // -------
  // Monitor
  // -------
  typedef acc_test::acc_c_slv_monitor #(
    // Acc bus interface paramaters;
    .DataWidth ( DataWidth  ),
    .AddrWidth ( AddrWidth  ),
    .IdWidth   ( ExtIdWidth ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) acc_c_slv_monitor_t;

  typedef acc_test::acc_c_slv_monitor #(
    // Acc bus interface paramaters;
    .DataWidth ( DataWidth  ),
    .AddrWidth ( AddrWidth  ),
    .IdWidth   ( 1          ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) acc_c_fwd_slv_monitor_t;

  typedef acc_test::acc_c_mst_monitor #(
    // Acc bus interface paramaters;
    .DataWidth    ( DataWidth    ),
    .AddrWidth    ( AddrWidth    ),
    .AccAddrWidth ( AccAddrWidth ),
    .IdWidth      ( 1            ),
    .HierLevel    ( HierLevel    ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) acc_c_mst_monitor_t;

  acc_c_mst_monitor_t acc_c_mst_monitor [NumReq];
  for (genvar i=0; i<NumReq; i++) begin : gen_mst_mon
    initial begin
      acc_c_mst_monitor[i] = new(master_dv[i]);
      @(posedge rst_n);
      acc_c_mst_monitor[i].monitor();
    end
  end

  acc_c_slv_monitor_t acc_c_slv_monitor [NumRsp[HierLevel]];
  for (genvar i=0; i<NumRsp[HierLevel]; i++) begin : gen_slv_mon
    initial begin
      acc_c_slv_monitor[i] = new(slave_dv[i]);
      @(posedge rst_n);
      acc_c_slv_monitor[i].monitor();
    end
  end

  acc_c_fwd_slv_monitor_t acc_c_fwd_slv_monitor [NumReq];
  for (genvar i=0; i<NumReq; i++) begin : gen_fwd_slv_mon
    initial begin
      acc_c_fwd_slv_monitor[i] = new(slave_next_dv[i]);
      @(posedge rst_n);
      acc_c_fwd_slv_monitor[i].monitor();
    end
  end

  // ------
  // Driver
  // ------
  // Slaves on same interconnect HierLevel
  typedef acc_test::rand_c_slave #(
    // Acc bus interface paramaters;
    .DataWidth ( DataWidth  ),
    .AddrWidth ( AddrWidth  ),
    .IdWidth   ( ExtIdWidth ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) rand_c_slave_t;

  rand_c_slave_t rand_c_slave [NumRsp[HierLevel]];
  for (genvar i=0; i<NumRsp[HierLevel]; i++) begin : gen_slv_driver
    initial begin
      rand_c_slave[i] = new (slave_dv[i]);
      rand_c_slave[i].reset();
      @(posedge rst_n);
      rand_c_slave[i].run();
    end
  end

  // Slaves on higher interconnect level.
  typedef acc_test::rand_c_slave #(
    // Acc bus interface paramaters;
    .DataWidth ( DataWidth ),
    .AddrWidth ( AddrWidth ),
    .IdWidth   ( 1         ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) rand_c_fwd_slave_t;


  // Requests / responses originating from higher interconnect levels
  // have already been sorted to the appropriate requester port.
  rand_c_fwd_slave_t rand_c_fwd_slave[NumReq];
  for (genvar i=0; i<NumReq; i++) begin : gen_c_slv_fwd_driver
    initial begin
      rand_c_fwd_slave[i] = new (slave_next_dv[i]);
      rand_c_fwd_slave[i].reset();
      @(posedge rst_n);
      rand_c_fwd_slave[i].run();
    end
  end


  typedef acc_test::rand_c_master #(
    // Acc bus interface paramaters;
    .DataWidth    ( DataWidth    ),
    .AccAddrWidth ( AccAddrWidth ),
    .AddrWidth    ( AddrWidth    ),
    .IdWidth      ( 1            ),
    .NumRsp       ( NumRsp       ),
    .NumHier      ( NumHier      ),
    .HierLevel    ( HierLevel    ),
    // Stimuli application and test time
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) acc_rand_master_t;

  acc_rand_master_t rand_c_master [NumReq];

  for (genvar i = 0; i < NumReq; i++) begin : gen_c_master
    initial begin
      rand_c_master[i] = new (master_dv[i]);
      rand_c_master[i].reset();
      @(posedge rst_n);
      rand_c_master[i].run(NrRandomTransactions);
    end
  end

  // Compare reqs of different parameterizations
  let mstslv_c_reqcompare(req_mst, req_slv) =
    acc_test::compare_c_req#(
      .mst_c_req_t ( tb_mst_c_req_t ),
      .slv_c_req_t ( tb_slv_c_req_t )
    )::do_compare(req_mst, req_slv);

  // Compare rsps of different parameterizations
  let mstslv_c_rspcompare(rsp_mst, rsp_slv) =
    acc_test::compare_c_rsp#(
      .mst_c_rsp_t ( tb_mst_c_rsp_t ),
      .slv_c_rsp_t ( tb_slv_c_rsp_t )
    )::do_compare(rsp_mst, rsp_slv);

  // ----------
  // Scoreboard
  // ----------
  // For each master check that each request sent has been received by
  // the correct slave.
  // For each slave, check that each response sent has been received by
  // the correct master.
  // Stop when all responses have been received.
  //
  // TODO: Add possibility for no-response requests.
  //       For check if interconnect is correct, this is fine.

  // Request Path
  // ------------
  initial begin
    automatic int nr_requests = 0;
    @(posedge rst_n);
    for (int kk=0; kk<NumReq; kk++) begin // masters k
      automatic int k=kk;
      fork
        // Check requests to same-level slaves
        for (int ii=0; ii<NumRsp[HierLevel]; ii++) begin // slaves i
          fork
            automatic int i=ii;
            forever begin : check_req_path
              automatic tb_mst_c_req_t req_mst;
              automatic tb_slv_c_req_t req_slv;
              automatic tb_slv_c_req_t req_slv_all[NumReq];
              // Master k has sent request to slave i.
              // Check that slave i has received.
              acc_c_slv_monitor[i].req_mbx[k<<1].get(req_slv);
              acc_c_mst_monitor[k].req_mbx[i].get(req_mst);
              assert(mstslv_c_reqcompare(req_mst, req_slv)) else
                $error("Request Mismatch: C master %0d to C slave %0d", k, i);
              // check that request was intended for slave i
              assert(req_mst.addr[AccAddrWidth-1:0] == i) else
                $error("Request Routing Error: C Master %0d", k);
              nr_requests++;
            end // -- forever
          join_none
        end // -- for (int i=0; i<NumRsp[HierLevel]; i++)

        // Check forwarded requests
        fork
          forever begin : check_req_path
            automatic tb_mst_c_req_t req_mst;
            automatic tb_mst_c_req_t req_slv_fwd;
            // Master k has sent interconnect forward port k
            // Check that slave k has received.
            acc_c_fwd_slv_monitor[k].req_mbx[0].get(req_slv_fwd);
            acc_c_mst_monitor[k].req_mbx_fwd.get(req_mst);
            assert(req_mst.do_compare(req_slv_fwd)) else
              $error("Forwarded Request Mismatch: C Master %0d", k);
            nr_requests++;
          end // -- forever
        join_none
      join_none
    end
  end

  // For each response received by a master, check that request has been issued.
  initial begin
    automatic int unsigned nr_responses = 0;
    @(posedge rst_n);
    for (int jj=0; jj<NumReq; jj++) begin
      fork
        automatic int j=jj;
        forever begin
          automatic tb_mst_c_rsp_t rsp_mst;
          automatic tb_mst_c_rsp_t rsp_slv_fwd;
          automatic bit rsp_sender_found = 0;
          acc_c_mst_monitor[j].rsp_mbx.get(rsp_mst);
          nr_responses++;
          // Check this interconnect level
          for (int l=0; l<NumRsp[HierLevel]; l++) begin
            //$display("Slave monitor %0x, rsp_mbx[%0x], mbox!=0: ",l, j<<1, acc_c_slv_monitor[l].rsp_mbx[j<<1].num() != 0);
            if (acc_c_slv_monitor[l].rsp_mbx[j<<1].num() != 0) begin
              automatic tb_slv_c_rsp_t rsp_slv;
              acc_c_slv_monitor[l].rsp_mbx[j<<1].peek(rsp_slv);
              if (mstslv_c_rspcompare(rsp_mst, rsp_slv)) begin
                acc_c_slv_monitor[l].rsp_mbx[j<<1].get(rsp_slv);
                rsp_sender_found |= 1;
                break;
              end
            end
          end
          // Check upper interconnect level (can only have originated
          // from corresponding forward connection)
          if (acc_c_fwd_slv_monitor[j].rsp_mbx[0].num() !=0 ) begin
            acc_c_fwd_slv_monitor[j].rsp_mbx[0].peek(rsp_slv_fwd);
            if (rsp_mst.do_compare(rsp_slv_fwd)) begin
              acc_c_fwd_slv_monitor[j].rsp_mbx[0].get(rsp_slv_fwd);
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
    for (int i=0; i<NumReq; i++) begin
      assert(acc_c_mst_monitor[i].rsp_mbx.num() == 0);
      assert(acc_c_mst_monitor[i].req_mbx_fwd.num() ==0);
      assert(acc_c_fwd_slv_monitor[i].req_mbx[0].num()==0);
      assert(acc_c_fwd_slv_monitor[i].rsp_mbx[0].num()==0);
      for (int j=0; j<NumRsp[HierLevel]; j++) begin
        assert(acc_c_mst_monitor[i].req_mbx[j].num() == 0);
        assert(acc_c_slv_monitor[j].req_mbx[i].num() == 0);
        assert(acc_c_slv_monitor[j].rsp_mbx[i].num() == 0);
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
