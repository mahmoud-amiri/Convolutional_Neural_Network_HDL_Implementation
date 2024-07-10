module PingPongController #(
    parameter NUM_LINES = 3,   // Number of lines for the line buffer
    parameter DATA_WIDTH = 16  // Data width
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

    // LineBuffer module definition
    module LineBuffer #(
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
        // Implement LineBuffer functionality here
    endmodule

    reg buffer_select = 0; // Ping-pong buffer selector
    wire [NUM_LINES*DATA_WIDTH-1:0] data_out_buffer0, data_out_buffer1;
    reg [31:0] line_counter = 0; // Line counter for toggling buffer_select

    wire we_buff0, we_buff1;

    always @(posedge clk or posedge reset) begin
        // if (reset) begin
        //     line_counter <= 0;
        //     buffer_select <= 0;
        // end else begin
            if (eol) begin
                line_counter <= line_counter + 1;
                if (line_counter == NUM_LINES-1) begin
                    line_counter <= 0;
                    buffer_select <= ~buffer_select;
                end
            end
        // end
    end

    assign we_buff0 = we && (~buffer_select);
    assign we_buff1 = we && buffer_select;

    // Instantiating the LineBuffer components
    LineBuffer #(
        .NUM_LINES(NUM_LINES),
        .DATA_WIDTH(DATA_WIDTH)
    ) buffer0 (
        .clk(clk),
        .reset(reset),
        .eol(eol),
        .we(we_buff0),
        .ready(ready),
        .wr_addr(wr_addr),
        .data_in(data_in),
        .data_out(data_out_buffer0)
    );

    LineBuffer #(
        .NUM_LINES(NUM_LINES),
        .DATA_WIDTH(DATA_WIDTH)
    ) buffer1 (
        .clk(clk),
        .reset(reset),
        .eol(eol),
        .we(we_buff1),
        .ready(ready),
        .wr_addr(wr_addr),
        .data_in(data_in),
        .data_out(data_out_buffer1)
    );

    // Output data based on the current buffer select
    assign data_out = (buffer_select == 0) ? data_out_buffer0 : data_out_buffer1;

endmodule
