`timescale 1 ns / 1 ps

module conv_layer_axis #(
    parameter DATA_WIDTH = 16,
    parameter NUM_LINES = 3,
    parameter KERNEL_WIDTH = 3,
    parameter KERNEL_HEIGHT = 3,
    parameter KERNEL_COEF = 32 * KERNEL_WIDTH * KERNEL_HEIGHT,
    parameter C_AXIS_TDATA_WIDTH = 32,
    parameter C_AXIS_FIFO_DEPTH = 16,
    parameter NUM_DIMENSIONS = 3  // Number of dimensions for the convolution
)(
    // Ports of Axi Slave Bus Interface S00_AXIS
    input wire clk,
    input wire resetn,
    output wire s00_axis_tready,
    input wire [C_AXIS_TDATA_WIDTH*NUM_DIMENSIONS-1 : 0] s00_axis_tdata,
    input wire [(C_AXIS_TDATA_WIDTH/8)*NUM_DIMENSIONS-1 : 0] s00_axis_tstrb,
    input wire s00_axis_tlast,
    input wire s00_axis_tvalid,
    input wire [NUM_DIMENSIONS-1:0] s00_axis_tuser,

    // Ports of Axi Master Bus Interface M00_AXIS
    output wire m00_axis_tvalid,
    output wire [C_AXIS_TDATA_WIDTH*NUM_DIMENSIONS-1 : 0] m00_axis_tdata,
    output wire [(C_AXIS_TDATA_WIDTH/8)*NUM_DIMENSIONS-1 : 0] m00_axis_tstrb,
    output wire m00_axis_tlast,
    output wire [NUM_DIMENSIONS-1:0] m00_axis_tuser,
    input wire m00_axis_tready
);

    // Internal signals
    wire [C_AXIS_TDATA_WIDTH-1 : 0] data_in [0:NUM_DIMENSIONS-1];
    wire user_in;
    wire last_in;
    wire empty;
    reg read_en;
    reg [C_AXIS_TDATA_WIDTH-1 : 0] data_out [0:NUM_DIMENSIONS-1];
    reg user_out [0:NUM_DIMENSIONS-1];
    reg last_out;
    reg wr_en;
    wire full;

    // Intermediate signals for convolution processing
    wire [DATA_WIDTH-1:0] conv_result [0:NUM_DIMENSIONS-1];
    wire [13:0] wr_addr;

    // AXI Stream Slave Interface (Input)
    S00_AXIS # ( 
        .C_S_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
        .C_S_AXIS_FIFO_DEPTH(C_AXIS_FIFO_DEPTH)
    ) S00_AXIS_inst (
        .S_AXIS_ACLK(clk),
        .S_AXIS_ARESETN(resetn),
        .S_AXIS_TREADY(s00_axis_tready),
        .S_AXIS_TDATA(s00_axis_tdata[0 +: C_AXIS_TDATA_WIDTH]),  // Only one dimension of data is used for address extraction
        .S_AXIS_TSTRB(s00_axis_tstrb[0 +: (C_AXIS_TDATA_WIDTH/8)]),
        .S_AXIS_TLAST(s00_axis_tlast),
        .S_AXIS_TVALID(s00_axis_tvalid),
        .S_AXIS_TUSER(s00_axis_tuser[0]),
        .data_out(data_in[0]),
        .user_out(user_in),
        .last_out(last_in),
        .empty(empty),
        .rd_en(read_en)
    );

    // Extract the write address from s00_axis_tdata or use a predefined method
    assign wr_addr = s00_axis_tdata[13:0];  // Adjust this assignment as necessary

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
                .reset(~resetn),
                .eol(last_in),
                .we(s00_axis_tvalid && s00_axis_tready),
                .ready(m00_axis_tready),
                .wr_addr(wr_addr),
                .data_in(data_in[i]),
                .conv_result(conv_result[i])
            );
        end
    endgenerate

    // Concatenate all conv_result signals
    wire [DATA_WIDTH*NUM_DIMENSIONS-1:0] concatenated_conv_result;
    generate
        for (i = 0; i < NUM_DIMENSIONS; i = i + 1) begin : gen_concat
            assign concatenated_conv_result[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = conv_result[i];
        end
    endgenerate

    // AXI Stream Master Interface (Output)
    M00_AXIS # ( 
        .C_M_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH * NUM_DIMENSIONS),
        .C_M_AXIS_FIFO_DEPTH(C_AXIS_FIFO_DEPTH)
    ) M00_AXIS_inst (
        .M_AXIS_ACLK(clk),
        .M_AXIS_ARESETN(resetn),
        .M_AXIS_TVALID(m00_axis_tvalid),
        .M_AXIS_TDATA(m00_axis_tdata),
        .M_AXIS_TSTRB(m00_axis_tstrb),
        .M_AXIS_TLAST(m00_axis_tlast),
        .M_AXIS_TREADY(m00_axis_tready),
        .M_AXIS_TUSER(m00_axis_tuser),
        .data_in(concatenated_conv_result),
        .user_in(user_out[0]),  // Assuming user_out[0] is representative
        .last_in(last_out),
        .wr_en(wr_en),
        .full(full)
    );

    // Logic to drive the read enable and write enable signals
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            read_en <= 0;
            last_out <= 0;
            user_out <= 0;
            wr_en <= 0;
        end else begin
            if (!empty && !full) begin
                read_en <= 1;
                last_out <= last_in;
                user_out[0] <= user_in;
                wr_en <= 1;
            end else begin
                read_en <= 0;
                wr_en <= 0;
            end
        end
    end

endmodule
