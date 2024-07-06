module LineBuffer #(
    parameter NUM_LINES = 4,  // Number of BRAM blocks (lines)
    parameter DATA_WIDTH = 16  // Data width (8 to 32 bits)
)(
    input clk,
    input eol,
    input we,
    input ready,
    input [13:0] wr_addr,  // 14-bit address for 16K depth
    input [DATA_WIDTH-1:0] data_in,  // 16-bit data width
    output [NUM_LINES*DATA_WIDTH-1:0] data_out
);

    // blk_mem_gen_0 module definition
    module blk_mem_gen_0 (
        input clka,
        input [0:0] wea,
        input [13:0] addra,
        input [DATA_WIDTH-1:0] dina,
        output [DATA_WIDTH-1:0] douta,
        input clkb,
        input [0:0] web,
        input [13:0] addrb,
        input [DATA_WIDTH-1:0] dinb,
        output [DATA_WIDTH-1:0] doutb
    );
        // Implement blk_mem_gen_0 functionality here
    endmodule

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

    genvar i;
    generate
        for (i = 0; i < NUM_LINES; i = i + 1) begin : gen_bram
            assign we_int[i] = (we && (current_line == i)) ? 1'b1 : 1'b0;
            assign addr_split = wr_addr;
            assign data_in_split = data_in;

            blk_mem_gen_0 U (
                .clka(clk),
                .wea(we_int[i]),
                .addra(addr_split),
                .dina(data_in_split),
                .douta(),  // douta is not used in this configuration
                .clkb(clk),
                .web(1'b0),
                .addrb(read_addr),
                .dinb({DATA_WIDTH{1'b0}}),
                .doutb(data_out_split[i])
            );

            always @(*) begin
                combined_data_out[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i] = data_out_split[i];
            end
        end
    endgenerate

    assign data_out = combined_data_out;

endmodule
