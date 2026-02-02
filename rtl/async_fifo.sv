`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineer: Enrique Fayos Gimeno
// 
// Create Date: 29.01.2026 21:53:40
// Design Name: Asynchronous FIFO (CDC-safe)
// Module Name: async_fifo
// Project Name: Async FIFO in SystemVerilog 
// Target Devices: Generic FPGA/ASIC, tested in Digilent Basys 3 (Xilinx Artix-7 XC7A35T)
// Tool Versions: Xilinx Vivado 2022.2
//
// Description: 
//   - Parameterizable DATA width and DEPTH (DEPTH must be power-of-two and >= 4)
//   - CDC-safe pointer crossing using Gray code + 2FF sync (*ASYNC_REG*)
//   - Full detection via inverted MSBs method (classic async FIFO technique)
//   - Empty detection via pointer equality (read-next vs synced write pointer)
//
// Dependencies: 
//   - None (pure SystemVerilog). 
//
// Revision:
// Revision 0.01 - Initial implementation: basic async FIFO with Gray pointers
// Revision 0.02 - Added parameter checks, improved flag logic and CDC annotations
// Revision 0.03 - Validation on Basys 3 and timing cleanup for Vivado 2022.2
//
// Additional Comments:
// Academic/portfolio project focused on digital design and CDC best practices.
//
//////////////////////////////////////////////////////////////////////////////////

module async_fifo #(
    parameter int DATA  = 8,
    parameter int DEPTH = 16
)(
    input logic wr_clk,
    input logic rd_clk,
    input logic wr_rst_n,
    input logic rd_rst_n,
    input logic wr_en,
    input logic rd_en,
    input logic  [DATA-1:0] din,
    output logic [DATA-1:0] dout,
    output logic full,
    output logic empty
);
// ------------------------------------------------------------
// Local parameters
//   ADDR_W: address width for DEPTH entries
//   PTR_W : pointer width with extra MSB for wrap tracking
// ------------------------------------------------------------
localparam int ADDR_W = $clog2(DEPTH);
localparam int PTR_W  = ADDR_W + 1;

// ------------------------------------------------------------
// Parameter checks (elaboration-time)
//   This implementation assumes DEPTH is a power of two and >= 4.
// ------------------------------------------------------------
initial begin
    if ((DEPTH & (DEPTH - 1)) != 0) begin
        $fatal(1, "async_fifo: DEPTH (%0d) must be a power of 2", DEPTH);
    end
    if (DEPTH < 4) begin
        $fatal(1, "async_fifo: DEPTH (%0d) must be >= 4", DEPTH);
    end
    if (DATA < 1) begin
        $fatal(1, "async_fifo: DATA (%0d) must be >= 1", DATA);
    end
end

// ------------------------------------------------------------
// Control signals
//   wr_inc/rd_inc: internal qualified "fire" signals (handshake)
//   full_next/empty_next: next-state flags computed combinationally
// ------------------------------------------------------------
logic wr_inc, rd_inc;
logic empty_next, full_next;

// ------------------------------------------------------------
// Binary + Gray pointers
//   - Binary pointers are used for addressing/increment.
//   - Gray pointers are used for CDC synchronization and comparisons.
//   - PTR_W includes an extra MSB for wrap-around tracking.
// ------------------------------------------------------------
logic [PTR_W-1:0] wr_ptr_bin,  wr_ptr_bin_next;
logic [PTR_W-1:0] wr_ptr_gray, wr_ptr_gray_next;

logic [PTR_W-1:0] rd_ptr_bin,  rd_ptr_bin_next;
logic [PTR_W-1:0] rd_ptr_gray, rd_ptr_gray_next;

// ------------------------------------------------------------
// CDC synchronizers (2-FF) for Gray pointers
//   - wr_ptr_gray crosses into rd_clk domain (wr_ptr_gray_ff1/ff2)
//   - rd_ptr_gray crosses into wr_clk domain (rd_ptr_gray_ff1/ff2)
//   ASYNC_REG attribute helps Vivado treat these FFs as CDC sync regs.
// ------------------------------------------------------------
(* ASYNC_REG = "TRUE" *) logic [PTR_W-1:0] wr_ptr_gray_ff1, wr_ptr_gray_ff2;
(* ASYNC_REG = "TRUE" *) logic [PTR_W-1:0] rd_ptr_gray_ff1, rd_ptr_gray_ff2;

// Synchronized (safe) versions of the remote Gray pointers in each domain
logic [PTR_W-1:0] wr_ptr_gray_sync; // safe in rd_clk domain
logic [PTR_W-1:0] rd_ptr_gray_sync; // safe in wr_clk domain
assign wr_ptr_gray_sync = wr_ptr_gray_ff2;
assign rd_ptr_gray_sync = rd_ptr_gray_ff2;

// ------------------------------------------------------------
// Function: binary to Gray conversion
//   Gray code ensures only one bit toggles per increment, reducing CDC risk.
// ------------------------------------------------------------
function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] bin);
    return (bin >> 1) ^ bin;
endfunction

// ------------------------------------------------------------
// DATA PATH
//   FIFO memory access
//   - Write port (wr_clk domain): writes 'din' when wr_inc is asserted
//   - Read  port (rd_clk domain): reads data into 'dout' when rd_inc is asserted
//   Addressing uses the binary pointers (ADDR_W LSBs only).
// ------------------------------------------------------------
logic [DATA-1:0] mem [0:DEPTH-1];
// write data path
always_ff @(posedge wr_clk) begin
    if (wr_inc) begin
        mem[wr_ptr_bin[ADDR_W-1:0]] <= din;
    end
end
// read data path
always_ff @(posedge rd_clk) begin
    if (!rd_rst_n) begin
        dout <= '0;
    end else if (rd_inc) begin
        dout <= mem[rd_ptr_bin[ADDR_W-1:0]];
    end
end

// ------------------------------------------------------------
// Combinational logic - WRITE domain (wr_clk)
//   Computes:
//     - wr_inc (qualified write)
//     - next write pointers (bin/gray)
//     - full_next using synchronized read pointer (Gray)
// ------------------------------------------------------------
always_comb begin
    // defaults (avoid latches / ease maintenance)
    wr_inc          = 1'b0;
    wr_ptr_bin_next = wr_ptr_bin;
    wr_ptr_gray_next= wr_ptr_gray;
    full_next       = full;
    // Accept write if enabled and not full
    wr_inc          = wr_en && !full;
    // Update pointers (binary increment + Gray conversion)
    wr_ptr_bin_next  = wr_ptr_bin + wr_inc;
    wr_ptr_gray_next = bin2gray(wr_ptr_bin_next);
    // Full detection (classic async FIFO condition)
    // full when next write pointer equals synchronized read pointer
    // with inverted two MSBs (wrap indication in Gray domain).
    full_next = (wr_ptr_gray_next == {~rd_ptr_gray_sync[PTR_W-1:PTR_W-2],rd_ptr_gray_sync[PTR_W-3:0]});
end

// ------------------------------------------------------------
// Combinational logic - READ domain (rd_clk)
//   Computes:
//     - rd_inc (qualified read)
//     - next read pointers (bin/gray)
//     - empty_next using synchronized write pointer (Gray)
// ------------------------------------------------------------
always_comb begin
    // Defaults
    rd_inc           = 1'b0;
    rd_ptr_bin_next  = rd_ptr_bin;
    rd_ptr_gray_next = rd_ptr_gray;
    empty_next       = empty;
    // Accept read if enabled and not empty
    rd_inc = rd_en && !empty;
    // Update pointers
    rd_ptr_bin_next  = rd_ptr_bin + rd_inc;
    rd_ptr_gray_next = bin2gray(rd_ptr_bin_next);
    // Empty detection: empty when next read pointer reaches synced write pointer
    empty_next = (rd_ptr_gray_next == wr_ptr_gray_sync);
end

// ------------------------------------------------------------
// Sequential logic - flags
//   Register full in wr_clk domain, empty in rd_clk domain.
// ------------------------------------------------------------
always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        full <= 1'b0;
    end else begin
        full <= full_next;
    end
end
always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        empty <= 1'b1;
    end else begin
        empty <= empty_next;
    end
end

// ------------------------------------------------------------
// Sequential logic - pointers
//   Register pointers locally in their corresponding clock domain.
// ------------------------------------------------------------
always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        wr_ptr_bin  <= '0;
        wr_ptr_gray <= '0;
    end else begin
        wr_ptr_bin <= wr_ptr_bin_next;
        wr_ptr_gray <= wr_ptr_gray_next;
    end
end
always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        rd_ptr_bin  <= '0;
        rd_ptr_gray <= '0;
    end else begin
        rd_ptr_bin <= rd_ptr_bin_next;
        rd_ptr_gray <= rd_ptr_gray_next;
    end
end

// ------------------------------------------------------------
// CDC synchronizers - 2FF chains
//   Synchronize Gray pointers across domains.
// ------------------------------------------------------------
always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        wr_ptr_gray_ff1 <= '0;
        wr_ptr_gray_ff2 <= '0;
    end else begin
        wr_ptr_gray_ff1 <= wr_ptr_gray;
        wr_ptr_gray_ff2 <= wr_ptr_gray_ff1;
    end
end
always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        rd_ptr_gray_ff1 <= '0;
        rd_ptr_gray_ff2 <= '0;
    end else begin
        rd_ptr_gray_ff1 <= rd_ptr_gray;
        rd_ptr_gray_ff2 <= rd_ptr_gray_ff1;
    end
end

endmodule
