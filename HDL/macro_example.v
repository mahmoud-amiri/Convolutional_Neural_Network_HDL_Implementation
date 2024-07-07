`include "flatten_macros.vh"

module main_module;

  // Parameters for array dimensions and data size
  parameter WIDTH = 4;
  parameter HEIGHT = 8;
  parameter DEPTH = 4;
  parameter TIME = 5;
  parameter CHANNEL = 3;
  parameter DATA_SIZE = 16;  // Example data size

  // Declare the arrays
  reg [DATA_SIZE-1:0] array_1d [0:WIDTH-1];
  reg [DATA_SIZE-1:0] array_2d [0:WIDTH-1][0:HEIGHT-1];
  reg [DATA_SIZE-1:0] array_3d [0:WIDTH-1][0:HEIGHT-1][0:DEPTH-1];
  reg [DATA_SIZE-1:0] array_4d [0:WIDTH-1][0:HEIGHT-1][0:DEPTH-1][0:TIME-1];
  reg [DATA_SIZE-1:0] array_5d [0:WIDTH-1][0:HEIGHT-1][0:DEPTH-1][0:TIME-1][0:CHANNEL-1];

  // Flattened arrays
  wire [(WIDTH*DATA_SIZE)-1:0] flat_1d;
  wire [(WIDTH*HEIGHT*DATA_SIZE)-1:0] flat_2d;
  wire [(WIDTH*HEIGHT*DEPTH*DATA_SIZE)-1:0] flat_3d;
  wire [(WIDTH*HEIGHT*DEPTH*TIME*DATA_SIZE)-1:0] flat_4d;
  wire [(WIDTH*HEIGHT*DEPTH*TIME*CHANNEL*DATA_SIZE)-1:0] flat_5d;

  // Use macros to define the flatten functions
  `FLATTEN_1D(array_1d, WIDTH, DATA_SIZE)
  `FLATTEN_2D(array_2d, WIDTH, HEIGHT, DATA_SIZE)
  `FLATTEN_3D(array_3d, WIDTH, HEIGHT, DEPTH, DATA_SIZE)
  `FLATTEN_4D(array_4d, WIDTH, HEIGHT, DEPTH, TIME, DATA_SIZE)
  `FLATTEN_5D(array_5d, WIDTH, HEIGHT, DEPTH, TIME, CHANNEL, DATA_SIZE)

  // Assign the flattened arrays
  assign flat_1d = flatten_1d(array_1d);
  assign flat_2d = flatten_2d(array_2d);
  assign flat_3d = flatten_3d(array_3d);
  assign flat_4d = flatten_4d(array_4d);
  assign flat_5d = flatten_5d(array_5d);

  initial begin
    // Initialize the arrays with some values (example)
    integer i, j, k, l, m;
    for (i = 0; i < WIDTH; i = i + 1) begin
      array_1d[i] = i * DATA_SIZE;
      for (j = 0; j < HEIGHT; j = j + 1) begin
        array_2d[i][j] = (i * HEIGHT + j) * DATA_SIZE;
        for