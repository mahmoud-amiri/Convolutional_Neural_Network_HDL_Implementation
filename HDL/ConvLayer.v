`timescale 1 ns / 1 ps

module conv_layer_axis #(
    parameter DATA_WIDTH = 16,
    parameter NUM_LINES = 3,
    parameter KERNEL_WIDTH = 3,
    parameter KERNEL_HEIGHT = 3,
    parameter KERNEL_COEF = 32 * KERNEL_WIDTH * KERNEL_HEIGHT,
    parameter C_AXIS_TDATA_WIDTH = 32,
    parameter C_AXIS_FIFO_DEPTH = 16
)(
    // Ports of Axi Slave Bus Interface S00_AXIS
    input wire clk,
    input wire resetn,
    output wire s00_axis_tready,
    input wire [C_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
    input wire [(C_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
    input wire s00_axis_tlast,
    input wire s00_axis_tvalid,
    input wire s00_axis_tuser,

    // Ports of Axi Master Bus Interface M00_AXIS
    output wire m00_axis_tvalid,
    output wire [C_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
    output wire [(C_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
    output wire m00_axis_tlast,
    output wire m00_axis_tuser,
    input wire m00_axis_tready
);

    // Internal signals
    wire [C_AXIS_TDATA_WIDTH-1 : 0] data_in;
    wire user_in;
    wire last_in;
    wire empty;
    reg read_en;
    reg [C_AXIS_TDATA_WIDTH-1 : 0] data_out;
    reg user_out;
    reg last_out;
    reg wr_en;
    wire full;

    // Intermediate signals for convolution processing
    wire [NUM_LINES*DATA_WIDTH-1:0] line_buffer_out;
    wire [DATA_WIDTH-1:0] conv_result;
    wire [13:0] wr_addr;

    // AXI Stream Slave Interface (Input)
    S00_AXIS # ( 
        .C_S_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
        .C_S_AXIS_FIFO_DEPTH(C_AXIS_FIFO_DEPTH)
    ) S00_AXIS_inst (
        .S_AXIS_ACLK(clk),
        .S_AXIS_ARESETN(resetn),
        .S_AXIS_TREADY(s00_axis_tready),
        .S_AXIS_TDATA(s00_axis_tdata),
        .S_AXIS_TSTRB(s00_axis_tstrb),
        .S_AXIS_TLAST(s00_axis_tlast),
        .S_AXIS_TVALID(s00_axis_tvalid),
        .S_AXIS_TUSER(s00_axis_tuser),
        .data_out(data_in),
        .user_out(user_in),
        .last_out(last_in),
        .empty(empty),
        .rd_en(read_en)
    );

    // AXI Stream Master Interface (Output)
    M00_AXIS # ( 
        .C_M_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
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
        .data_in(data_out),
        .user_in(user_out),
        .last_in(last_out),
        .wr_en(wr_en),
        .full(full)
    );

    // Extract the write address from s00_axis_tdata or use a predefined method
    assign wr_addr = s00_axis_tdata[13:0];  // Adjust this assignment as necessary

    // Instantiate the PingPongController module
    PingPongController #(
        .NUM_LINES(NUM_LINES),
        .DATA_WIDTH(DATA_WIDTH)
    ) ping_pong_controller (
        .clk(clk),
        .reset(~resetn),
        .eol(last_in),
        .we(s00_axis_tvalid && s00_axis_tready),
        .ready(m00_axis_tready),
        .wr_addr(wr_addr),
        .data_in(s00_axis_tdata[DATA_WIDTH-1:0]),
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
        .reset(~resetn),
        .data_in(line_buffer_out),
        .data_out(conv_result)
    );

    // Logic to drive the read enable and write enable signals
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            read_en <= 0;
            data_out <= 0;
            last_out <= 0;
            user_out <= 0;
            wr_en <= 0;
        end else begin
            if (!empty && !full) begin
                read_en <= 1;
                data_out <= {16'b0, conv_result};  // Assuming data_out should match C_AXIS_TDATA_WIDTH
                last_out <= last_in;
                user_out <= user_in;
                wr_en <= 1;
            end else begin
                read_en <= 0;
                wr_en <= 0;
            end
        end
    end

endmodule
