`timescale 1ns / 1ps

interface fifo_if #(parameter DATA = 8)
    (
    input  logic        wr_clk,
    input  logic        rd_clk
    );

    logic        wr_rst_n;
    logic        rd_rst_n;
    logic        wr_en;
    logic        rd_en;
    logic [DATA-1:0]  din;
    logic [DATA-1:0]  dout;
    logic        full;
    logic        empt;    

    // -------------------------
    // WR domain (posedge wr_clk)
    // -------------------------
    clocking wr_monitor @(posedge wr_clk);
        default input #1step output #1step;
    endclocking
    clocking wr_driver @(posedge wr_clk);
        default input #1step output #1step;
    endclocking

    // -------------------------
    // RD domain (posedge rd_clk)
    // -------------------------
    clocking rd_monitor @(posedge rd_clk);
        default input #1step output #1step;
    endclocking
    clocking rd_driver @(posedge rd_clk);
        default input #1step output #1step;
    endclocking

endinterface