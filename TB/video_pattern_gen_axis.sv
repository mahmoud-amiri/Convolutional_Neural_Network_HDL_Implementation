module video_pattern_gen_axis #(
    parameter C_S_AXIS_TDATA_WIDTH = 32,
    parameter FRAME_WIDTH = 1920,
    parameter FRAME_HEIGHT = 1080,
    parameter PATTERN_TYPE = 2,  // 0: SOLID_COLOR, 1: CHECKERBOARD, 2: GRADIENT, 3: COUNTER
    parameter SOLID_COLOR = 32'hFF00FF00
)(
    input wire                      clk,
    input wire                      reset_n,
    output reg                      s_axis_tvalid,
    output reg [C_S_AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
    output reg                      s_axis_tlast,
    output reg                      s_axis_tuser,
    input wire                      s_axis_tready
);

    typedef enum {SOLID, CHECKER, GRAD, COUNT} pattern_t;
    pattern_t pattern_type = pattern_t'(PATTERN_TYPE);

    integer x, y;
    reg [31:0] color;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            s_axis_tvalid <= 0;
            s_axis_tdata <= 0;
            s_axis_tlast <= 0;
            s_axis_tuser <= 0;
            x <= 0;
            y <= 0;
        end else begin
            if (s_axis_tready) begin
                s_axis_tvalid <= 1;
                s_axis_tlast <= (x == FRAME_WIDTH - 1);
                s_axis_tuser <= (x == 0 && y == 0);

                case (pattern_type)
                    SOLID: s_axis_tdata <= SOLID_COLOR;
                    CHECKER: s_axis_tdata <= ((x % 2) ^ (y % 2)) ? 32'hFFFFFFFF : 32'h00000000;
                    GRAD: s_axis_tdata <= (x + y) & 32'hFFFFFFFF;
                    COUNT: s_axis_tdata <= x & 32'hFFFFFFFF;
                endcase

                if (x == FRAME_WIDTH - 1) begin
                    x <= 0;
                    if (y == FRAME_HEIGHT - 1) begin
                        y <= 0;
                    end else begin
                        y <= y + 1;
                    end
                end else begin
                    x <= x + 1;
                end
            end
        end
    end
endmodule
