`ifndef FLATTEN_MACROS_VH
`define FLATTEN_MACROS_VH

// Macro for 1D array flattening
`define FLATTEN_1D(ARRAY, D1, DATA_SIZE) \
function [(D1*DATA_SIZE)-1:0] flatten_1d; \
  input [DATA_SIZE-1:0] ARRAY [0:D1-1]; \
  integer i; \
  reg [(D1*DATA_SIZE)-1:0] flat_array; \
  begin \
    flat_array = 0; \
    for (i = 0; i < D1; i = i + 1) begin \
      flat_array[(i*DATA_SIZE) +: DATA_SIZE] = ARRAY[i]; \
    end \
    flatten_1d = flat_array; \
  end \
endfunction

// Macro for 2D array flattening
`define FLATTEN_2D(ARRAY, D1, D2, DATA_SIZE) \
function [(D1*D2*DATA_SIZE)-1:0] flatten_2d; \
  input [DATA_SIZE-1:0] ARRAY [0:D1-1][0:D2-1]; \
  integer i, j; \
  reg [(D1*D2*DATA_SIZE)-1:0] flat_array; \
  begin \
    flat_array = 0; \
    for (i = 0; i < D1; i = i + 1) begin \
      for (j = 0; j < D2; j = j + 1) begin \
        flat_array[(i*D2 + j)*DATA_SIZE +: DATA_SIZE] = ARRAY[i][j]; \
      end \
    end \
    flatten_2d = flat_array; \
  end \
endfunction

// Macro for 3D array flattening
`define FLATTEN_3D(ARRAY, D1, D2, D3, DATA_SIZE) \
function [(D1*D2*D3*DATA_SIZE)-1:0] flatten_3d; \
  input [DATA_SIZE-1:0] ARRAY [0:D1-1][0:D2-1][0:D3-1]; \
  integer i, j, k; \
  reg [(D1*D2*D3*DATA_SIZE)-1:0] flat_array; \
  begin \
    flat_array = 0; \
    for (i = 0; i < D1; i = i + 1) begin \
      for (j = 0; j < D2; j = j + 1) begin \
        for (k = 0; k < D3; k = k + 1) begin \
          flat_array[((i*D2 + j)*D3 + k)*DATA_SIZE +: DATA_SIZE] = ARRAY[i][j][k]; \
        end \
      end \
    end \
    flatten_3d = flat_array; \
  end \
endfunction

// Macro for 4D array flattening
`define FLATTEN_4D(ARRAY, D1, D2, D3, D4, DATA_SIZE) \
function [(D1*D2*D3*D4*DATA_SIZE)-1:0] flatten_4d; \
  input [DATA_SIZE-1:0] ARRAY [0:D1-1][0:D2-1][0:D3-1][0:D4-1]; \
  integer i, j, k, l; \
  reg [(D1*D2*D3*D4*DATA_SIZE)-1:0] flat_array; \
  begin \
    flat_array = 0; \
    for (i = 0; i < D1; i = i + 1) begin \
      for (j = 0; j < D2; j = j + 1) begin \
        for (k = 0; k < D3; k = k + 1) begin \
          for (l = 0; l < D4; l = l + 1) begin \
            flat_array[(((i*D2 + j)*D3 + k)*D4 + l)*DATA_SIZE +: DATA_SIZE] = ARRAY[i][j][k][l]; \
          end \
        end \
      end \
    end \
    flatten_4d = flat_array; \
  end \
endfunction

// Macro for 5D array flattening
`define FLATTEN_5D(ARRAY, D1, D2, D3, D4, D5, DATA_SIZE) \
function [(D1*D2*D3*D4*D5*DATA_SIZE)-1:0] flatten_5d; \
  input [DATA_SIZE-1:0] ARRAY [0:D1-1][0:D2-1][0:D3-1][0:D4-1][0:D5-1]; \
  integer i, j, k, l, m; \
  reg [(D1*D2*D3*D4*D5*DATA_SIZE)-1:0] flat_array; \
  begin \
    flat_array = 0; \
    for (i = 0; i < D1; i = i + 1) begin \
      for (j = 0; j < D2; j = j + 1) begin \
        for (k = 0; k < D3; k = k + 1) begin \
          for (l = 0; l < D4; l = l + 1) begin \
            for (m = 0; m < D5; m = m + 1) begin \
              flat_array[((((i*D2 + j)*D3 + k)*D4 + l)*D5 + m)*DATA_SIZE +: DATA_SIZE] = ARRAY[i][j][k][l][m]; \
            end \
          end \
        end \
      end \
    end \
    flatten_5d = flat_array; \
  end \
endfunction

`endif