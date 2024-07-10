module PingPongController_tb;

    // Parameters
    parameter NUM_LINES = 3;
    parameter DATA_WIDTH = 16;

    // Signals
    reg clk;
    reg reset;
    reg eol;
    reg we;
    reg ready;
    reg [13:0] wr_addr;
    reg [DATA_WIDTH-1:0] data_in;
    wire [NUM_LINES*DATA_WIDTH-1:0] data_out;

    // Instantiate the PingPongController
    PingPongController #(
        .NUM_LINES(NUM_LINES),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .eol(eol),
        .we(we),
        .ready(ready),
        .wr_addr(wr_addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end

    // Image parameters
    parameter NUM_ROWS = 20;
    parameter NUM_COLS = 100;

    // Image data (20x100 array of 16-bit values)
    reg [DATA_WIDTH-1:0] image_data [NUM_ROWS-1:0][NUM_COLS-1:0];
    integer row, col;

    // Initialize image data with some pattern (e.g., random values)
    initial begin
        integer i, j;
        for (i = 0; i < NUM_ROWS; i = i + 1) begin
            for (j = 0; j < NUM_COLS; j = i + 1) begin
                image_data[i][j] = i; // $random;
            end
        end
    end

    // Test procedure
    initial begin
        // Initialize signals
        eol = 0;
        we = 0;
        ready = 0;
        wr_addr = 14'd0;
        data_in = 16'd0;
        reset = 1;

        // Reset sequence
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        reset = 1;
        ready = 1;

        // Write image data to PingPongController
        for (row = 0; row < NUM_ROWS; row = row + 1) begin
            for (col = 0; col < NUM_COLS; col = col + 1) begin
                @(posedge clk);
                we = 1;
                wr_addr = col;
                data_in = image_data[row][col];
            end
            @(posedge clk);
            we = 0;
            eol = 1;
            @(posedge clk);
            eol = 0;
        end

        // Ready to read data
        #2000;
        ready = 0;

        // Check output data
        $display("Data Out: %h", data_out);

        // Finish simulation
        #100;
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time: %0t | reset: %b | eol: %b | we: %b | ready: %b | wr_addr: %0d | data_in: %h | data_out: %h",
                $time, reset, eol, we, ready, wr_addr, data_in, data_out);
    end

endmodule
