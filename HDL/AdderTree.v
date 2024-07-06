module AdderTree #(
    parameter integer WIDTH = 3,
    parameter integer HEIGHT = 3,
    parameter integer DEPTH = 3,
    parameter integer NUM_FILTER = 3,
    parameter integer PRODUCT_WIDTH = 16,
    parameter integer SUM_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input signed [(PRODUCT_WIDTH*WIDTH*HEIGHT*DEPTH*NUM_FILTER)-1:0] products,
    output reg signed [(SUM_WIDTH*DEPTH*NUM_FILTER)-1:0] sums_out
);

    // Intermediate registers
    reg signed [PRODUCT_WIDTH-1:0] products_3d[0:WIDTH-1][0:HEIGHT-1][0:DEPTH-1][0:NUM_FILTER-1];
    reg signed [SUM_WIDTH-1:0] sum_stage1[0:WIDTH-1][0:HEIGHT-1][0:DEPTH-1][0:NUM_FILTER-1];
    reg signed [SUM_WIDTH-1:0] sum_stage2[0:HEIGHT-1][0:DEPTH-1][0:NUM_FILTER-1];
    reg signed [SUM_WIDTH-1:0] sum_stage3[0:DEPTH-1][0:NUM_FILTER-1];
    reg signed [SUM_WIDTH-1:0] sum_final[0:DEPTH-1][0:NUM_FILTER-1];

    integer b, i, j, k, n;

    // Flattening input products into 3D arrays
    always @(*) begin
        for (n = 0; n < NUM_FILTER; n = n + 1) begin
            for (k = 0; k < DEPTH; k = k + 1) begin
                for (j = 0; j < HEIGHT; j = j + 1) begin
                    for (i = 0; i < WIDTH; i = i + 1) begin
                        b = n * (WIDTH * HEIGHT * DEPTH) + k * (WIDTH * HEIGHT) + j * WIDTH + i;
                        products_3d[i][j][k][n] = products[b*PRODUCT_WIDTH +: PRODUCT_WIDTH];
                    end
                end
            end
        end
    end

    // Stage 1: Summing pairs of elements in the WIDTH dimension
    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    for (j = 0; j < HEIGHT; j = j + 1) begin
                        for (i = 0; i < WIDTH-1; i = i + 2) begin
                            sum_stage1[i/2][j][k][n] <= 0;
                        end
                    end
                end
            end
        end else begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    for (j = 0; j < HEIGHT; j = j + 1) begin
                        for (i = 0; i < WIDTH-1; i = i + 2) begin
                            sum_stage1[i/2][j][k][n] <= products_3d[i][j][k][n] + products_3d[i+1][j][k][n];
                        end
                        if (WIDTH % 2 != 0) begin
                            sum_stage1[WIDTH/2][j][k][n] <= products_3d[WIDTH-1][j][k][n];
                        end
                    end
                end
            end
        end
    end

    // Stage 2: Summing partial sums from Stage 1 in the HEIGHT dimension
    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    for (i = 0; i < (WIDTH+1)/2; i = i + 1) begin
                        sum_stage2[i][k][n] <= 0;
                    end
                end
            end
        end else begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    for (i = 0; i < (WIDTH+1)/2; i = i + 1) begin
                        sum_stage2[i][k][n] <= sum_stage1[i][0][k][n] + sum_stage1[i][1][k][n] + sum_stage1[i][2][k][n];
                    end
                end
            end
        end
    end

    // Stage 3: Summing partial sums from Stage 2 across remaining elements
    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    sum_stage3[k][n] <= 0;
                end
            end
        end else begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    sum_stage3[k][n] <= 0;
                    for (i = 0; i < (WIDTH+1)/2; i = i + 1) begin
                        sum_stage3[k][n] <= sum_stage3[k][n] + sum_stage2[i][k][n];
                    end
                end
            end
        end
    end

    // Stage 4: Transferring intermediate sums to final sums
    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    sum_final[k][n] <= 0;
                end
            end
        end else begin
            for (n = 0; n < NUM_FILTER; n = n + 1) begin
                for (k = 0; k < DEPTH; k = k + 1) begin
                    sum_final[k][n] <= sum_stage3[k][n];
                end
            end
        end
    end

    // Flattening final sums into output vector
    always @(*) begin
        for (n = 0; n < NUM_FILTER; n = n + 1) begin
            for (k = 0; k < DEPTH; k = k + 1) begin
                b = n * DEPTH + k;
                sums_out[b*SUM_WIDTH +: SUM_WIDTH] = sum_final[k][n];
            end
        end
    end

endmodule
