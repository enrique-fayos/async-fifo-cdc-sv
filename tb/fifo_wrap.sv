module fifo_wrap (
    input  wire        wr_clk,
    input  wire        rd_clk,
    input  wire        wr_rst_n,
    input  wire        rd_rst_n,
    input  wire        wr_en,
    input  wire        rd_en,
    input  wire [7:0]  din,
    output wire [7:0]  dout,
    output wire        full,
    output wire        empty
);

localparam int DATA  = 8;
localparam int DEPTH = 16;

async_fifo #(
    .DATA (DATA),
    .DEPTH(DEPTH)
) u_async_fifo (
    .wr_clk   (wr_clk),
    .rd_clk   (rd_clk),
    .wr_rst_n (wr_rst_n),
    .rd_rst_n (rd_rst_n),
    .wr_en    (wr_en),
    .rd_en    (rd_en),
    .din      (din),
    .dout     (dout),
    .full     (full),
    .empty    (empty)
);

endmodule