# Copyright 2024 OpenHW Group
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

VERILATOR ?= verilator


lint: test.sv test.vlt ../core_v_xif.sv
	$(VERILATOR) -lint-only -Wall ../core_v_xif.sv test.sv test.vlt --top-module test