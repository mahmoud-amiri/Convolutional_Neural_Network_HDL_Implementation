module SlidingWindow #(
    parameter KERNEL_WIDTH = 3,        // Width of the kernel
    parameter KERNEL_HEIGHT = 3,       // Height of the kernel
    parameter DATA_WIDTH = 16,         // Data width
    parameter KERNEL_COEF = 32 * KERNEL_WIDTH * KERNEL_HEIGHT // Concatenated kernel coefficients
)(
    input clk,
    input reset,
    input [KERNEL_WIDTH*DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    localparam KERNEL_SIZE = KERNEL_WIDTH * KERNEL_HEIGHT;

    reg [DATA_WIDTH-1:0] window[KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0]; // Sliding window
    reg [31:0] kernel[KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0]; // Kernel coefficients

    // Pipeline registers for intermediate sums
    reg signed [31:0] partial_sum[KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0];
    reg signed [31:0] sum_stage1[KERNEL_HEIGHT-1:0];
    reg signed [31:0] sum_stage2;

    // Shift register logic to create the sliding window
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i, j;
            // Split the concatenated KERNEL_COEF into a 2D array
            for (i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
                for (j = 0; j < KERNEL_WIDTH; j = j + 1) begin
                    kernel[i][j] <= KERNEL_COEF[32 * (i * KERNEL_WIDTH + j) +: 32];
                end
            end

            // Initialize the sliding window to zeros
            for (i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
                for (j = 0; j < KERNEL_WIDTH; j = j + 1) begin
                    window[i][j] <= 0;
                end
            end

            // Initialize pipeline registers to zero
            for (i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
                for (j = 0; j < KERNEL_WIDTH; j = j + 1) begin
                    partial_sum[i][j] <= 0;
                end
                sum_stage1[i] <= 0;
            end
            sum_stage2 <= 0;
        end else begin
            integer i, j;
            // Shift the window left
            for (i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
                for (j = 1; j < KERNEL_WIDTH; j = j + 1) begin
                    window[i][j-1] <= window[i][j];
                end
            end
            // Load new data into the rightmost column
            for (i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
                window[i][KERNEL_WIDTH-1] <= data_in[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
            end

            // Compute partial products in parallel
            for (i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
                for (j = 0; j < KERNEL_WIDTH; j = j + 1) begin
                    partial_sum[i][j] <= window[i][j] * kernel[i][j];
                end
            end

            // Sum the partial products for each row (first pipeline stage)
            for (i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
                sum_stage1[i] <= 0;
                for (j = 0; j < KERNEL_WIDTH; j = j + 1) begin
                    sum_stage1[i] <= sum_stage1[i] + partial_sum[i][j];
                end
            end

            // Sum the row sums to get the final result (second pipeline stage)
            sum_stage2 <= 0;
            for (i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
                sum_stage2 <= sum_stage2 + sum_stage1[i];
            end
        end
    end

    // Output the final sum, truncated to DATA_WIDTH bits
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 0;
        end else begin
            data_out <= sum_stage2[DATA_WIDTH-1:0];
        end
    end

endmodule
