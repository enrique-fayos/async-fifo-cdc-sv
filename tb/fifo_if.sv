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
    logic        empty;    

    // -------------------------
    // WR domain (posedge wr_clk)
    // -------------------------
    clocking wr_monitor @(posedge wr_clk);
        default input #1step output #1step;
        input wr_en;
        input wr_rst_n;
        input din;
        input full;
    endclocking
    clocking wr_driver @(posedge wr_clk);
        default input #1step output #1step;
        output wr_en;
        output wr_rst_n;
        output din;      
        input  full;
    endclocking
    // -------------------------
    // RD domain (posedge rd_clk)
    // -------------------------
    clocking rd_monitor @(posedge rd_clk);
        default input #1step output #1step;
        input rd_en;
        input rd_rst_n;
        input dout;
        input empty;
    endclocking
    clocking rd_driver @(posedge rd_clk);
        default input #1step output #1step;
        output rd_en;
        output rd_rst_n;
        input  dout;
        input  empty;
    endclocking

    // -------------------------
    // MODPORT DUT
    // -------------------------    
    modport DUT (
        input wr_clk, rd_clk,
        input wr_rst_n, rd_rst_n,
        input wr_en, rd_en,
        input din,
        output dout,
        output full,
        output empty
    );

    // -------------------------
    // MODPORT TB
    // -------------------------  
    modport TB(
        clocking wr_driver,
        clocking wr_monitor,
        clocking rd_driver,
        clocking rd_monitor
    );

endinterface