// Copyright 2024 OpenHW Group
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

module test;

  // eXtension Interface
  /* verilator lint_off UNUSED */
  core_v_xif core_v_xif_bus ();

  initial begin
   $display("Instantiating CORE-V-XIF reference model");
   $finish;
  end

endmodule
