module SlidingWindow_tb;

  // Parameters
  parameter KERNEL_WIDTH = 3;
  parameter KERNEL_HEIGHT = 3;
  parameter DATA_WIDTH = 16;
  parameter KERNEL_COEF = 288'h000100020003000400050006000700080009000A000B000C000D000E000F001000110012;

  // Inputs
  reg clk;
  reg reset;
  reg [KERNEL_WIDTH*DATA_WIDTH-1:0] data_in;

  // Outputs
  wire [DATA_WIDTH-1:0] data_out;

  // Instantiate the Unit Under Test (UUT)
  SlidingWindow #(
    .KERNEL_WIDTH(KERNEL_WIDTH),
    .KERNEL_HEIGHT(KERNEL_HEIGHT),
    .DATA_WIDTH(DATA_WIDTH),
    .KERNEL_COEF(KERNEL_COEF)
  ) uut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
  );

  integer i, j;
  reg [DATA_WIDTH-1:0] rand_data[KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0];

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 0;
    data_in = 0;

    // Apply reset
    reset = 1;
    #10;
    reset = 0;

    // Test sequence with 100 random inputs
    for (i = 0; i < 100; i = i + 1) begin
      // Generate random data for the sliding window
      for (j = 0; j < KERNEL_HEIGHT; j = j + 1) begin
        rand_data[j][0] = $random;
        rand_data[j][1] = $random;
        rand_data[j][2] = $random;
      end

      data_in = {rand_data[2][2], rand_data[2][1], rand_data[2][0], 
                rand_data[1][2], rand_data[1][1], rand_data[1][0], 
                rand_data[0][2], rand_data[0][1], rand_data[0][0]};
      #10;
    end

    // Finish the simulation
    $finish;
  end

  // Clock generation
  always #5 clk = ~clk;

  // Monitor
  initial begin
    $monitor("Time = %0t, clk = %b, reset = %b, data_in = %h, data_out = %h", 
              $time, clk, reset, data_in, data_out);
  end

  // Add the 2D array to the waveform
  initial begin
    $dumpfile("SlidingWindow_tb.vcd");
    $dumpvars(0, SlidingWindow_tb);
    for (i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
      for (j = 0; j < KERNEL_WIDTH; j = j + 1) begin
        $dumpvars(0, rand_data[i][j]);
      end
    end
  end

endmodule
