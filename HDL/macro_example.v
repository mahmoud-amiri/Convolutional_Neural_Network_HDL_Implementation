``include "flatten_macros.vh"
`include "unflatten_macros.vh"

module flatten_unflatten_module #(parameter WIDTH = 4, HEIGHT = 8, DEPTH = 4, TIME = 5, CHANNEL = 3, DATA_SIZE = 16) (
    input [(WIDTH*HEIGHT*DEPTH*TIME*CHANNEL*DATA_SIZE)-1:0] flat_input,
    output [(WIDTH*HEIGHT*DEPTH*TIME*CHANNEL*DATA_SIZE)-1:0] flat_output
);
  // Declare the multi-dimensional array
  reg [DATA_SIZE-1:0] multi_dim_array [0:WIDTH-1][0:HEIGHT-1][0:DEPTH-1][0:TIME-1][0:CHANNEL-1];
  wire [(WIDTH*HEIGHT*DEPTH*TIME*CHANNEL*DATA_SIZE)-1:0] flat_temp;

  // Use macros to define the unflatten and flatten functions
  `UNFLATTEN_5D(flat_input, multi_dim_array, WIDTH, HEIGHT, DEPTH, TIME, CHANNEL, DATA_SIZE)
  `FLATTEN_5D(multi_dim_array, WIDTH, HEIGHT, DEPTH, TIME, CHANNEL, DATA_SIZE)

  // Unflatten the input and flatten the multi-dimensional array
  initial begin
    unflatten_5d(flat_input, multi_dim_array);
  end

  assign flat_temp = flatten_5d(multi_dim_array);

  // Assign the result to the output
  assign flat_output = flat_temp;

endmodule