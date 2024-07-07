`timescale 1 ns / 1 ps

module passthrough_axis #(
    parameter C_AXIS_TDATA_WIDTH = 32,
    parameter C_AXIS_FIFO_DEPTH = 16
)(
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line

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
    wire [C_AXIS_TDATA_WIDTH-1 : 0] data_in; // Changed to wire
    wire user_in; // Changed to wire
    wire last_in; // Changed to wire
    wire empty; // Changed to wire
    reg read_en;
    reg [C_AXIS_TDATA_WIDTH-1 : 0] data_out;
    reg user_out;
    reg last_out;
    reg wr_en;
    wire full; // Changed to wire

    // Instantiation of Axi Bus Interface S00_AXIS
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

    // Instantiation of Axi Bus Interface M00_AXIS
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

    always @(posedge clk) begin
        if (!resetn) begin
            read_en <= 0;
            data_out <= 0;
            last_out <= 0;
            user_out <= 0;
            wr_en <= 0;
        end else begin
            if (!empty && !full) begin
                read_en <= 1;
                data_out <= data_in;
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
