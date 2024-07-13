`timescale 1 ns / 1 ps

module ConvProcessingMultiDim #(
    parameter NUM_DIMENSIONS = 3,
    parameter NUM_LINES = 3,
    parameter DATA_WIDTH = 16,
    parameter KERNEL_WIDTH = 3,
    parameter KERNEL_HEIGHT = 3,
    parameter KERNEL_COEF = 32 * KERNEL_WIDTH * KERNEL_HEIGHT,
    parameter C_AXIS_TDATA_WIDTH = 32
)(
    input wire clk,
    input wire resetn,
    input wire eol,
    input wire we,
    input wire ready,
    input wire [13:0] wr_addr,
    input wire [C_AXIS_TDATA_WIDTH*NUM_DIMENSIONS-1 : 0] s00_axis_tdata,
    output wire [DATA_WIDTH*NUM_DIMENSIONS-1:0] concatenated_conv_result
);

    // Internal signals
    wire [DATA_WIDTH-1:0] conv_result [0:NUM_DIMENSIONS-1];
    wire [C_AXIS_TDATA_WIDTH-1 : 0] data_in [0:NUM_DIMENSIONS-1];

    // Convert input data to a multidimensional array
    genvar i;
    generate
        for (i = 0; i < NUM_DIMENSIONS; i = i + 1) begin : gen_data_split
            assign data_in[i] = s00_axis_tdata[(i+1)*C_AXIS_TDATA_WIDTH-1:i*C_AXIS_TDATA_WIDTH];
        end
    endgenerate

    // Generate blocks for each dimension
    generate
        for (i = 0; i < NUM_DIMENSIONS; i = i + 1) begin : gen_conv_processing
            // Instantiate the ConvProcessing module
            ConvProcessing #(
                .NUM_LINES(NUM_LINES),
                .DATA_WIDTH(DATA_WIDTH),
                .KERNEL_WIDTH(KERNEL_WIDTH),
                .KERNEL_HEIGHT(KERNEL_HEIGHT),
                .KERNEL_COEF(KERNEL_COEF)
            ) conv_processing (
                .clk(clk),
                .reset(resetn),
                .eol(eol),
                .we(we),
                .ready(ready),
                .wr_addr(wr_addr),
                .data_in(data_in[i]),
                .conv_result(conv_result[i])
            );
        end
    endgenerate

    // Concatenate all conv_result signals
    generate
        for (i = 0; i < NUM_DIMENSIONS; i = i + 1) begin : gen_concat
            assign concatenated_conv_result[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = conv_result[i];
        end
    endgenerate

endmodule
