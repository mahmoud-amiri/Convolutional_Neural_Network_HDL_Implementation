module ProductCalculation #(
    parameter integer WIDTH = 3,
    parameter integer HEIGHT = 3,
    parameter integer DEPTH = 3,
    parameter integer NUM_FILTER = 3,
    parameter integer WINDOW_DATA_WIDTH = 16,
    parameter integer KERNEL_DATA_WIDTH = 8,
    parameter integer PRODUCT_WIDTH = 16,
    parameter integer UP_TRUNC = 0,
    parameter integer DOWN_TRUNC = 0
)(
    input wire clk,
    input wire rst,
    input signed [(KERNEL_DATA_WIDTH*WIDTH*HEIGHT*DEPTH*NUM_FILTER)-1:0] kernel,
    input signed [(WINDOW_DATA_WIDTH*WIDTH*HEIGHT*DEPTH*NUM_FILTER)-1:0] window,
    output reg signed [(PRODUCT_WIDTH*WIDTH*HEIGHT*DEPTH*NUM_FILTER)-1:0] products_out
);

    reg signed [WINDOW_DATA_WIDTH-1:0] window_3d[0:WIDTH-1][0:HEIGHT-1][0:DEPTH-1][0:NUM_FILTER-1];
    reg signed [KERNEL_DATA_WIDTH-1:0] kernel_3d[0:WIDTH-1][0:HEIGHT-1][0:DEPTH-1][0:NUM_FILTER-1];
    reg signed [PRODUCT_WIDTH-1:0] products_out_3d[0:WIDTH-1][0:HEIGHT-1][0:DEPTH-1][0:NUM_FILTER-1];

    reg signed [WINDOW_DATA_WIDTH + KERNEL_DATA_WIDTH - 1:0] full_product;
    reg signed [PRODUCT_WIDTH-1:0] truncated_product;

    integer b, i, j, k, n;

    // Flattening inputs into 3D arrays
    always @(*) begin
        for (n = 0; n < NUM_FILTER; n = n + 1) begin
            for (k = 0; k < DEPTH; k = k + 1) begin
                for (j = 0; j < HEIGHT; j = j + 1) begin
                    for (i = 0; i < WIDTH; i = i + 1) begin
                        b = n * (WIDTH * HEIGHT * DEPTH) + k * (WIDTH * HEIGHT) + j * WIDTH + i;
                        window_3d[i][j][k][n] = window[b*WINDOW_DATA_WIDTH +: WINDOW_DATA_WIDTH];
                        kernel_3d[i][j][k][n] = kernel[b*KERNEL_DATA_WIDTH +: KERNEL_DATA_WIDTH];
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            // Reset all products to zero
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    for (j = 0; j < HEIGHT; j = j + 1) begin
                        for (i = 0; i < WIDTH; i = i + 1) begin
                            products_out_3d[i][j][k][n] <= 0;
                        end
                    end
                end
            end
        end else begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    for (j = 0; j < HEIGHT; j = j + 1) begin
                        for (i = 0; i < WIDTH; i = i + 1) begin
                            // Calculate the full product
                            full_product = window_3d[i][j][k][n] * kernel_3d[i][j][k][n];

                            // Apply truncation
                            if (UP_TRUNC + DOWN_TRUNC < WINDOW_DATA_WIDTH + KERNEL_DATA_WIDTH) begin
                                truncated_product = full_product[(WINDOW_DATA_WIDTH + KERNEL_DATA_WIDTH - 1) - UP_TRUNC -: PRODUCT_WIDTH];
                            end else begin
                                truncated_product = 0;  // Handle cases where truncation exceeds product size
                            end

                            // Assign the truncated product to the output array
                            products_out_3d[i][j][k][n] <= truncated_product;
                        end
                    end
                end
            end
        end
    end

    // Flattening outputs from 3D array
    always @(*) begin
        for (n = 0; n < NUM_FILTER; n = n + 1) begin
            for (k = 0; k < DEPTH; k = k + 1) begin
                for (j = 0; j < HEIGHT; j = j + 1) begin
                    for (i = 0; i < WIDTH; i = i + 1) begin
                        b = n * (WIDTH * HEIGHT * DEPTH) + k * (WIDTH * HEIGHT) + j * WIDTH + i;
                        products_out[b*PRODUCT_WIDTH +: PRODUCT_WIDTH] = products_out_3d[i][j][k][n];
                    end
                end
            end
        end
    end

endmodule
