module ConvolutionWrapper #(
    parameter KERNEL_WIDTH = 3,  // Width of the convolution kernel
    parameter KERNEL_HEIGHT = 3,  // Height of the convolution kernel
    parameter KERNEL_DEPTH = 3,  // Depth of the convolution kernel
    parameter DATA_WIDTH = 16   // Data width (8 to 32 bits)
)(
    input clk,
    input reset,
    input eol,
    input we,
    input ready,
    input [13:0] wr_addr,
    input [DATA_WIDTH-1:0] data_in,
    input [KERNEL_DEPTH*KERNEL_HEIGHT*KERNEL_WIDTH*DATA_WIDTH-1:0] kernel,
    output [DATA_WIDTH-1:0] data_out
);

    // PingPongController module definition
    module PingPongController #(
        parameter NUM_LINES = 3,
        parameter DATA_WIDTH = 16
    )(
        input clk,
        input reset,
        input eol,
        input we,
        input ready,
        input [13:0] wr_addr,
        input [DATA_WIDTH-1:0] data_in,
        output [NUM_LINES*DATA_WIDTH-1:0] data_out
    );
        // Implement PingPongController functionality here
    endmodule

    // conv module definition
    module conv #(
        parameter KERNEL_WIDTH = 3,
        parameter KERNEL_HEIGHT = 3,
        parameter DATA_WIDTH = 16
    )(
        input clk,
        input reset,
        input ready,
        input [KERNEL_WIDTH*DATA_WIDTH-1:0] data_out_buffer,
        input [KERNEL_HEIGHT*KERNEL_WIDTH*DATA_WIDTH-1:0] kernel,
        output [DATA_WIDTH*2-1:0] data_out  // Wider output to handle intermediate sum
    );
        // Implement conv functionality here
    endmodule

    wire [KERNEL_WIDTH*DATA_WIDTH-1:0] data_out_buffer;
    wire [DATA_WIDTH*2-1:0] conv_outputs [0:KERNEL_DEPTH-1]; // Outputs from each conv instance
    reg [DATA_WIDTH*2-1:0] result;

    // Instantiating the PingPongController component
    PingPongController #(
        .NUM_LINES(KERNEL_HEIGHT),
        .DATA_WIDTH(DATA_WIDTH)
    ) ping_pong_ctrl (
        .clk(clk),
        .reset(reset),
        .eol(eol),
        .we(we),
        .ready(ready),
        .wr_addr(wr_addr),
        .data_in(data_in),
        .data_out(data_out_buffer)
    );

    // Instantiating the conv components
    genvar i;
    generate
        for (i = 0; i < KERNEL_DEPTH; i = i + 1) begin : gen_convs
            conv #(
                .KERNEL_WIDTH(KERNEL_WIDTH),
                .KERNEL_HEIGHT(KERNEL_HEIGHT),
                .DATA_WIDTH(DATA_WIDTH)
            ) conv_inst (
                .clk(clk),
                .reset(reset),
                .ready(ready),
                .data_out_buffer(data_out_buffer),
                .kernel(kernel[(i+1)*KERNEL_HEIGHT*KERNEL_WIDTH*DATA_WIDTH-1 -: KERNEL_HEIGHT*KERNEL_WIDTH*DATA_WIDTH]),
                .data_out(conv_outputs[i])
            );
        end
    endgenerate

    // Summing the outputs of all conv instances
    always @(*) begin
        result = {DATA_WIDTH*2{1'b0}};
        for (i = 0; i < KERNEL_DEPTH; i = i + 1) begin
            result = result + conv_outputs[i];
        end
    end

    assign data_out = result[DATA_WIDTH+13:14]; // Adjust for fractional part

endmodule
