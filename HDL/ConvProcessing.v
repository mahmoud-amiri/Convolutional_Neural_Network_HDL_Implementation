module ConvProcessing #(
    parameter NUM_LINES = 3,
    parameter DATA_WIDTH = 16,
    parameter KERNEL_WIDTH = 3,
    parameter KERNEL_HEIGHT = 3,
    parameter KERNEL_COEF = 32 * KERNEL_WIDTH * KERNEL_HEIGHT
)(
    input wire clk,
    input wire reset,
    input wire eol,
    input wire we,
    input wire ready,
    input wire [13:0] wr_addr,
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] conv_result
);

    // Intermediate signals
    wire [NUM_LINES*DATA_WIDTH-1:0] line_buffer_out;

    // Instantiate the PingPongController module
    PingPongController #(
        .NUM_LINES(NUM_LINES),
        .DATA_WIDTH(DATA_WIDTH)
    ) ping_pong_controller (
        .clk(clk),
        .reset(reset),
        .eol(eol),
        .we(we),
        .ready(ready),
        .wr_addr(wr_addr),
        .data_in(data_in),
        .data_out(line_buffer_out)
    );

    // Instantiate the SlidingWindow module
    SlidingWindow #(
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .DATA_WIDTH(DATA_WIDTH),
        .KERNEL_COEF(KERNEL_COEF)
    ) sliding_window (
        .clk(clk),
        .reset(reset),
        .data_in(line_buffer_out),
        .data_out(conv_result)
    );

endmodule
