`timescale 1 ns / 1 ps

module axi_stream_video_size #(
    parameter C_AXIS_TDATA_WIDTH = 32
)(
    // AXI Stream Slave Interface
    input wire clk,
    input wire resetn,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [C_AXIS_TDATA_WIDTH-1 : 0] s_axis_tdata,
    input wire [(C_AXIS_TDATA_WIDTH/8)-1 : 0] s_axis_tstrb,
    input wire s_axis_tlast,
    input wire s_axis_tuser,

    // Video size output
    output reg [31:0] video_width,
    output reg [31:0] video_height,
    output reg video_size_valid
);

    // Internal signals
    reg [31:0] pixel_count;
    reg [31:0] line_count;
    reg valid_size;
    reg frame_started;

    // State machine states
    localparam IDLE = 2'b00, COUNT_PIXELS = 2'b01, COUNT_LINES = 2'b10;
    reg [1:0] state;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            pixel_count <= 0;
            line_count <= 0;
            video_width <= 0;
            video_height <= 0;
            video_size_valid <= 0;
            state <= IDLE;
            frame_started <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tuser) begin
                        frame_started <= 1;
                        state <= COUNT_PIXELS;
                    end
                end
                COUNT_PIXELS: begin
                    if (s_axis_tvalid) begin
                        pixel_count <= pixel_count + 1;
                        if (s_axis_tlast) begin
                            video_width <= pixel_count + 1;
                            pixel_count <= 0;
                            state <= COUNT_LINES;
                            line_count <= line_count + 1;
                        end
                    end
                end
                COUNT_LINES: begin
                    if (s_axis_tvalid) begin
                        if (s_axis_tuser) begin
                            video_height <= line_count;
                            video_size_valid <= 1;
                            line_count <= 0;
                            frame_started <= 1;
                        end
                        if (s_axis_tlast) begin
                            line_count <= line_count + 1;
                        end
                    end
                end
            endcase

            if (frame_started && !s_axis_tvalid) begin
                state <= IDLE;
                frame_started <= 0;
            end
        end
    end

    assign s_axis_tready = 1'b1;

endmodule
