module read_image_file_axis #(
    parameter C_S_AXIS_TDATA_WIDTH = 32,
    parameter FILENAME = "image_with_header.bin"
)(
    input wire                      clk,
    input wire                      reset_n,
    output reg                      s_axis_tvalid,
    output reg [C_S_AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
    output reg                      s_axis_tlast,
    output reg                      s_axis_tuser,
    input wire                      s_axis_tready
);

    import "DPI-C" context function int dpi_fopen (input string filename, input string mode);
    import "DPI-C" context function int dpi_fclose (input int file);
    import "DPI-C" context function int dpi_fread (output byte data, input int file);

    int file;
    byte data_byte;
    int idx;
    int num_pixels;

    typedef struct packed {
        int rows;
        int cols;
        int channels;
    } image_header_t;

    image_header_t header;
    byte image_data[]; // Declare dynamic array

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        READ_HEADER = 2'b01,
        READ_DATA = 2'b10,
        SEND_DATA = 2'b11
    } state_t;

    state_t state;

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
                    file = dpi_fopen(FILENAME, "rb");
                    if (file != 0) begin
                        state <= READ_HEADER;
                    end else begin
                        $display("Error opening file: %s", FILENAME);
                        state <= IDLE; // Loop in IDLE on error
                    end
                end
                READ_HEADER: begin
                    if (dpi_fread(data_byte, file) == 1) begin
                        header.rows[7:0] = data_byte;
                        if (dpi_fread(data_byte, file) == 1) header.rows[15:8] = data_byte;
                        if (dpi_fread(data_byte, file) == 1) header.rows[23:16] = data_byte;
                        if (dpi_fread(data_byte, file) == 1) header.rows[31:24] = data_byte;

                        if (dpi_fread(data_byte, file) == 1) header.cols[7:0] = data_byte;
                        if (dpi_fread(data_byte, file) == 1) header.cols[15:8] = data_byte;
                        if (dpi_fread(data_byte, file) == 1) header.cols[23:16] = data_byte;
                        if (dpi_fread(data_byte, file) == 1) header.cols[31:24] = data_byte;

                        if (dpi_fread(data_byte, file) == 1) header.channels[7:0] = data_byte;
                        if (dpi_fread(data_byte, file) == 1) header.channels[15:8] = data_byte;
                        if (dpi_fread(data_byte, file) == 1) header.channels[23:16] = data_byte;
                        if (dpi_fread(data_byte, file) == 1) header.channels[31:24] = data_byte;

                        num_pixels <= header.rows * header.cols * header.channels;
                        image_data = new[byte[num_pixels]]; // Correctly allocate dynamic array
                        state <= READ_DATA;
                    end else begin
                        $display("Error reading header from file.");
                        state <= IDLE; // Loop in IDLE on error
                    end
                end
                READ_DATA: begin
                    for (int i = 0; i < num_pixels; i++) begin
                        if (dpi_fread(data_byte, file) == 1) begin
                            image_data[i] = data_byte; // Blocking assignment
                        end else begin
                            $display("Error reading image data from file.");
                            state <= IDLE; // Loop in IDLE on error
                            break;
                        end
                    end
                    state <= SEND_DATA;
                end
                SEND_DATA: begin
                    if (idx < num_pixels) begin
                        if (s_axis_tready) begin
                            s_axis_tvalid <= 1;
                            s_axis_tdata <= {24'b0, image_data[idx]}; // Extend byte to 32 bits
                            s_axis_tlast <= ((idx + 1) % (header.cols * header.channels) == 0);
                            s_axis_tuser <= (idx == 0);

                            idx <= idx + 1;

                            if (idx == num_pixels) begin
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
                    void'(dpi_fclose(file)); // Explicit void cast
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
