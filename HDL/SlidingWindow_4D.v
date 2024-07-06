module SlidingWindow #(
    parameter integer KERNEL_WIDTH = 3,
    parameter integer KERNEL_HEIGHT = 3,
    parameter integer DEPTH = 3,
    parameter integer NUM_FILTER = 3,
    parameter integer DATA_WIDTH = 16
) (
    input wire clk,
    input wire reset,
    input wire signed [(DATA_WIDTH*KERNEL_HEIGHT*DEPTH*NUM_FILTER)-1:0] data_in,
    output reg signed [(DATA_WIDTH*KERNEL_WIDTH*KERNEL_HEIGHT*DEPTH*NUM_FILTER)-1:0] window_out
);

    reg signed [DATA_WIDTH-1:0] window[0:KERNEL_WIDTH-1][0:KERNEL_HEIGHT-1][0:DEPTH-1][0:NUM_FILTER-1];

    integer i, j, k, n, idx;

    // Flatten input arrays into internal multi-dimensional arrays
    always @(*) begin
        for (n = 0; n < NUM_FILTER; n = n + 1) begin
            for (k = 0; k < DEPTH; k = k + 1) begin
                for (j = 0; j < KERNEL_HEIGHT; j = j + 1) begin
                    idx = n * (KERNEL_HEIGHT * DEPTH) + k * (KERNEL_HEIGHT) + j;
                    window[0][j][k][n] = data_in[idx*DATA_WIDTH +: DATA_WIDTH];
                end
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    for (j = 0; j < KERNEL_HEIGHT; j = j + 1) begin
                        for (i = 0; i < KERNEL_WIDTH; i = i + 1) begin
                            window[i][j][k][n] <= {DATA_WIDTH{1'b0}};
                        end
                    end
                end
            end
        end else begin
            // Shift the window contents
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    for (j = 0; j < KERNEL_HEIGHT; j = j + 1) begin
                        for (i = KERNEL_WIDTH-1; i > 0; i = i - 1) begin
                            window[i][j][k][n] <= window[i-1][j][k][n];
                        end
                    end
                end
            end

            // Load new data into the window
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    for (j = 0; j < KERNEL_HEIGHT; j = j + 1) begin
                        idx = n * (KERNEL_HEIGHT * DEPTH) + k * (KERNEL_HEIGHT) + j;
                        window[0][j][k][n] <= data_in[idx*DATA_WIDTH +: DATA_WIDTH];
                    end
                end
            end
        end
    end

    // Flatten the internal multi-dimensional output array to the output port
    always @(*) begin
        for (n = 0; n < NUM_FILTER; n = n + 1) begin
            for (k = 0; k < DEPTH; k = k + 1) begin
                for (j = 0; j < KERNEL_HEIGHT; j = j + 1) begin
                    for (i = 0; i < KERNEL_WIDTH; i = i + 1) begin
                        idx = n * (KERNEL_WIDTH * KERNEL_HEIGHT * DEPTH) + k * (KERNEL_WIDTH * KERNEL_HEIGHT) + j * KERNEL_WIDTH + i;
                        window_out[idx*DATA_WIDTH +: DATA_WIDTH] = window[i][j][k][n];
                    end
                end
            end
        end
    end

endmodule
