//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineer: Enrique Fayos Gimeno
//
// Create Date: 04.03.2026
// Design Name: Asynchronous FIFO Testbench
// Module Name: tb_async_fifo
// Project Name: Async FIFO in SystemVerilog
// Target Devices: Simulation only
// Tool Versions: Tested with Xilinx Vivado 2022.2
//
// Description:
//   Top-level testbench used to verify the async_fifo design.
//
//   The testbench instantiates:
//     - fifo_if     : SystemVerilog interface encapsulating FIFO signals
//     - fifo_wrap   : DUT wrapper connecting the interface to the async_fifo
//     - estimulos   : program block responsible for stimulus generation
//
//   Independent write and read clocks are generated and passed to the
//   interface, enabling verification of the asynchronous FIFO behaviour.
//
// Dependencies:
//   - async_fifo.sv
//   - fifo_if.sv
//   - fifo_wrap.sv
//   - estimulos.sv
//
// Revision:
// Revision 0.01 - Initial testbench structure with interface and wrapper
//
// Additional Comments:
//   This module serves as the simulation top and connects the verification
//   environment to the DUT through the fifo_if abstraction.
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module tb_async_fifo();

    localparam T = 10; // Clock period (10ns => 100MHz)

    logic wr_clk;
    initial wr_clk = 1'b0;
    always #(T/2) wr_clk = ~wr_clk;

    logic rd_clk;
    initial rd_clk = 1'b0;
    always #(T/2) rd_clk = ~rd_clk;

    fifo_if #(.DATA(8)) vif (.wr_clk(wr_clk), .rd_clk(rd_clk));

    fifo_wrap #(.DATA(8),.DEPTH(16)) dut (vif);

    estimulos tb (.vif(vif));

endmodule
