`timescale 1ns / 1ps

module read_image_file_axis #(
    parameter C_S_AXIS_TDATA_WIDTH = 24,
    parameter FILENAME = "image_with_header.txt"
)(
    input wire                      clk,
    input wire                      reset_n,
    output reg                      s_axis_tvalid,
    output reg [C_S_AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
    output reg                      s_axis_tlast,
    output reg                      s_axis_tuser,
    input wire                      s_axis_tready
);

    typedef struct packed {
        int rows;
        int cols;
        int channels;
    } image_header_t;

    image_header_t header;
    byte image_data[]; // Declare dynamic array of bytes

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        READ_HEADER = 2'b01,
        READ_DATA = 2'b10,
        SEND_DATA = 2'b11
    } state_t;

    state_t state;
    integer file, num_pixels, idx;
    integer r;
    byte value;

    // Function to read image file
    function int read_image_file(input string filename);
        integer file, i, j, k;
        string line;
        file = $fopen(filename, "r");
        if (file == 0) begin
            $display("Error: could not open file %s", filename);
            return 0;
        end

        // Read header
        r = $fscanf(file, "%d ", header.rows);
        if (r == 0) begin
            $display("Error: could not read rows from file %s", filename);
            $fclose(file);
            return 0;
        end
        r = $fscanf(file, "%d ", header.cols);
        if (r == 0) begin
            $display("Error: could not read cols from file %s", filename);
            $fclose(file);
            return 0;
        end
        r = $fscanf(file, "%d ", header.channels);
        if (r == 0) begin
            $display("Error: could not read channels from file %s", filename);
            $fclose(file);
            return 0;
        end
        // $display("Header: rows = %d, cols = %d, channels = %d", header.rows, header.cols, header.channels);

        num_pixels = header.rows * header.cols * header.channels;
        image_data = new[3 * num_pixels]; // Allocate space for 3 bytes per pixel

        // Read image data
        for (i = 0; i < header.rows; i = i + 1) begin
            for (j = 0; j < header.cols; j = j + 1) begin
                for (k = 0; k < header.channels; k = k + 1) begin
                    r = $fscanf(file, "%h ", value);
                    if (r == 0) begin
                        $display("Error: could not read pixel data from file %s", filename);
                        $fclose(file);
                        return 0;
                    end
                    image_data[(i * header.cols + j) * header.channels + k] = value;
                end
            end
            r = $fgets(line, file); // Move to the next line
        end
        $fclose(file);
        // $display("Image data read successfully, num_pixels = %d", num_pixels);
        return 1;
    endfunction

    // State machine
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            s_axis_tvalid <= 0;
            s_axis_tdata <= 0;
            s_axis_tlast <= 0;
            s_axis_tuser <= 0;
            idx <= 0;
            num_pixels <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (read_image_file(FILENAME)) begin
                        state <= SEND_DATA;
                    end else begin
                        state <= IDLE; // Loop in IDLE on error
                    end
                end
                SEND_DATA: begin
                    if (idx < num_pixels * header.channels) begin
                        if (s_axis_tready) begin
                            s_axis_tvalid <= 1;
                            s_axis_tdata <= {image_data[idx], image_data[idx+1], image_data[idx+2]}; // Pack 3 bytes into 32 bits
                            s_axis_tlast <= ((idx + 3) % (header.cols * header.channels) == 0);
                            s_axis_tuser <= (idx == 0);
                            idx <= idx + 3;
                            if (idx >= num_pixels * header.channels) begin
                                state <= IDLE; // Transition to IDLE after sending data
                            end
                        end else begin
                            s_axis_tvalid <= 0;
                        end
                    end else begin
                        state <= IDLE;
                    end
                end
                default: begin
                    s_axis_tvalid <= 0;
                    s_axis_tdata <= 0;
                    s_axis_tlast <= 0;
                    s_axis_tuser <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
