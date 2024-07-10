    // Dual-Port Memory Module Definition
    module dual_port_mem #(
        parameter DATA_WIDTH = 24  // Number of BRAM blocks (lines)
    )(
        input clk,
        input reset,
        input we,
        input [13:0] wr_addr,
        input [DATA_WIDTH-1:0] din,
        input [13:0] rd_addr,
        output reg [DATA_WIDTH-1:0] dout
    );
        reg [DATA_WIDTH-1:0] mem [0:16383];  // Memory array for 16K depth
        
        always @(posedge clk) begin
            if (we) begin
                mem[wr_addr] <= din;
            end
            dout <= mem[rd_addr];
        end
    endmodule