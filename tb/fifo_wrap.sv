//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineer: Enrique Fayos Gimeno
//
// Create Date: 04.03.2026
// Design Name: Asynchronous FIFO Verification Wrapper
// Module Name: fifo_wrap
// Project Name: Async FIFO in SystemVerilog
// Target Devices: Generic FPGA/ASIC simulation environment
// Tool Versions: Tested with Xilinx Vivado 2022.2
//
// Description:
//   Lightweight wrapper used in the verification environment to connect the
//   async_fifo DUT with the SystemVerilog interface (fifo_if).
//
//   The module simply maps interface signals to the DUT ports, allowing the
//   testbench to interact with the FIFO through the interface abstraction.
//
//   Parameters:
//     - DATA  : Data width of the FIFO
//     - DEPTH : Number of FIFO entries (must match DUT configuration)
//
// Dependencies:
//   - async_fifo.sv
//   - fifo_if.sv
//
// Revision:
// Revision 0.01 - Initial wrapper implementation for DUT/interface connection
//
// Additional Comments:
//   This module is intended for verification purposes only and does not add
//   functional logic. It provides a clean connection point between the DUT
//   and the testbench interface.
//
//////////////////////////////////////////////////////////////////////////////////

module fifo_wrap #(
    parameter int DATA  = 8,
    parameter int DEPTH = 16
) (fifo_if.DUT vif);

async_fifo #(
    .DATA (DATA),
    .DEPTH(DEPTH)
) u_async_fifo (
    .wr_clk   (vif.wr_clk),
    .rd_clk   (vif.rd_clk),
    .wr_rst_n (vif.wr_rst_n),
    .rd_rst_n (vif.rd_rst_n),
    .wr_en    (vif.wr_en),
    .rd_en    (vif.rd_en),
    .din      (vif.din),
    .dout     (vif.dout),
    .full     (vif.full),
    .empty    (vif.empty)
);

endmodule