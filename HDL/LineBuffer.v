module LineBuffer #(
    parameter NUM_LINES = 4,  // Number of BRAM blocks (lines)
    parameter DATA_WIDTH = 16  // Data width (8 to 32 bits)
)(
    input clk,
    input reset,  // Reset signal
    input eol,
    input we,
    input ready,
    input [13:0] wr_addr,  // 14-bit address for 16K depth
    input [DATA_WIDTH-1:0] data_in,  // 16-bit data width
    output [NUM_LINES*DATA_WIDTH-1:0] data_out
);

    // module dual_port_mem #(
    //     parameter DATA_WIDTH = 16  // Number of BRAM blocks (lines)
    // )(
    //     input clk,
    //     input reset,
    //     input we,
    //     input [13:0] wr_addr,
    //     input [DATA_WIDTH-1:0] din,
    //     input [13:0] rd_addr,
    //     output reg [DATA_WIDTH-1:0] dout
    // );
    // endmodule

    reg [NUM_LINES-1:0] we_int;
    wire [13:0] addr_split;
    wire [DATA_WIDTH-1:0] data_in_split;
    wire [DATA_WIDTH-1:0] data_out_split [NUM_LINES-1:0];
    reg [NUM_LINES*DATA_WIDTH-1:0] combined_data_out;

    reg [31:0] current_line = 0;
    reg [13:0] read_addr = 14'b0;

    always @(posedge clk) begin
         if (eol) begin
            if (current_line == NUM_LINES-1) begin
                current_line <= 0;
            end else begin
                current_line <= current_line + 1;
            end
        end
    end

    always @(posedge clk) begin
         if (eol) begin
            read_addr <= 14'b0;
        end else if (ready) begin
            read_addr <= read_addr + 1;
        end
    end

    integer j;
    always @(*) begin
        for (j = 0; j < NUM_LINES; j = j + 1) begin
            we_int[j] = (we && (current_line == j)) ? 1'b1 : 1'b0;
        end
    end

    genvar i;
    generate
        for (i = 0; i < NUM_LINES; i = i + 1) begin : gen_mem
            assign addr_split = wr_addr;
            assign data_in_split = data_in;

            dual_port_mem #(
                .DATA_WIDTH(DATA_WIDTH)
            ) U ( 
                .clk(clk),
                .reset(reset),
                .we(we_int[i]),
                .wr_addr(addr_split),
                .din(data_in_split),
                .rd_addr(read_addr),
                .dout(data_out_split[i])
            );

            always @(*) begin
                combined_data_out[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i] = data_out_split[i];
            end
        end
    endgenerate

    assign data_out = combined_data_out;

endmodule
